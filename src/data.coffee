
	Data = MITHGrid.namespace('Data')

	Data.initSet = (values) ->
		that = {}
		items = {}
		count = 0
		recalc_items = true
		items_list = []

		that.isSet = true

		that.items = () ->
			if recalc_items
				items_list = []
				for i of items
					items_list.push i if typeof(i) == "string" and items[i] == true
			items_list

		that.add = (item) ->
			if !items[item]?
				items[item] = true
				recalc_items = true
				count += 1

		that.remove = (item) ->
			if items[item]?
				delete items[item]
				recalc_items = true
				count -= 1
				
		that.empty = () ->
			items = {}
			count = 0
			recalc_items = false
			items_list = []
			undefined

		that.visit = (fn) ->
			for o of items
				break if fn(o) == true

		that.contains = (o) ->
			items[o]?

		that.size = () ->
			if recalc_items
				that.items().length
			else
				items_list.length

		if values instanceof Array
			that.add i for i in values

		that

	Data.initType = (t) ->
		that =
			name: t
			custom: {}

	Data.initProperty = (p) ->
		that =
			name: p
			getValueType: () ->
				that.valueType ? 'text'

	Data.initStore = (options) ->
		quiesc_events = false
		set = Data.initSet()
		types = {}
		properties = {}
		spo = {}
		ops = {}

		indexPut = (index, x, y, z) ->
			hash = index[x]

			if !hash?
				hash =
					values: {}
					counts: {}
				index[x] = hash

			array = hash.values[y]
			counts = hash.counts[y]

			if !array?
				array = []
				hash.values[y] = array
			if !counts?
				counts = {}
				hash.counts[y] = counts
			else if z in array
				counts[z] += 1
				return
			array.push z
			counts[z] = 1

		indexFillSet = (index, x, y, set, filter) ->
			hash = index[x]

			if hash?
				array = hash.values[y]
				if array?
					if filter?
						for z in array
							set.add z if filter.contains z
					else
						set.add z for z in array

		getUnion = (index, xSet, y, set, filter) ->
			if !set?
				set = Data.initSet()

			xSet.visit (x) -> indexFillSet index, x, y, set, filter
			set

		options ?= {}

		that = MITHGrid.initView "MITHGrid.Data.initStore", options

		that.items = set.items
		that.contains = set.contains
		that.visit = set.visit

		that.addProperty = (nom, options) ->
			prop = Data.initProperty nom
			if options?.valueType?
				prop.valueType = options.valueType
				properties[nom] = prop
			prop

		that.getProperty = (nom) -> properties[nom] ? Data.initProperty(nom)

		that.addType = (nom, options) ->
			type = Data.initType(nom)
			types[nom] = type
			type

		that.getType = (nom) -> types[nom] ? Data.initType(nom)

		that.getItem = (id) -> spo[id]?.values ? {}

		that.getItems = (ids) ->
			return [that.getItem ids] if !$.isArray ids
			$.map ids, (id, idx) -> that.getItem id


		that.fetchData = (uri) ->
			$.ajax
				url: uri
				dataType: "json"
				success: (data, textStatus) -> that.loadData data
		
		that.removeItems = (ids, fn) ->
			id_list = []
			
			indexRemove = (index, x, y, z) ->
				hash = index[x]
				return if !hash?

				array = hash.values[y];
				counts = hash.counts[y];

				return if !array? or !counts?
				# we need to remove the old z values
				counts[z] -= 1
				if counts[z] < 1
					i = $.inArray z, array
					if i == 0
						array = array[1...array.length]
					else if i == array.length - 1
						array = array[0 ... i]
					else if i > 0
						array = array[0 ... i].concat array[i + 1 ... array.length]
					if array.length > 0
						hash.values[y] = array
					else
						delete hash.values[y]
					delete counts[z]
					# TODO: if counts empty, then we need to bubble up the deletion
					sum = 0
					for k, v of counts
						sum += v
					if sum == 0
						# we have nothing here
						delete index[x]

			indexRemoveFn = (s, p, o) ->
				indexRemove spo, s, p, o
				indexRemove ops, o, p, s
			
			removeValues = (id, p, list) -> indexRemoveFn(id, p, o) for o in list
			
			removeItem = (id, indexRemoveFn) ->
				entry = that.getItem id
				type = entry.type
				type = type[0] if $.isArray(type)
				
				for p, items of entry
					continue if typeof(p) != "string" or p in ["id", "type"]
					removeValues id, p, items
				
				removeValues id, 'type', [ type ]
				
			
			for id in ids
				removeItem id, indexRemoveFn
				id_list.push id
				set.remove id
				
			that.events.onModelChange.fire that, id_list
			if fn?
				fn()

		that.updateItems = (items, fn) ->
			id_list = []

			indexRemove = (index, x, y, z) ->
				hash = index[x]
				return if !hash?

				array = hash.values[y];
				counts = hash.counts[y];

				return if !array? or !counts?
				# we need to remove the old z values
				counts[z] -= 1
				if counts[z] < 1
					i = $.inArray z, array
					if i == 0
						array = array[1...array.length]
					else if i == array.length - 1
						array = array[0 ... i]
					else if i > 0
						array = array[0 ... i].concat array[i + 1 ... array.length]
					if array.length > 0
						hash.values[y] = array
					else
						delete hash.values[y]
					delete counts[z]
						
			indexPutFn = (s, p, o) ->
				indexPut spo, s, p, o
				indexPut ops, o, p, s

			indexRemoveFn = (s, p, o) ->
				indexRemove spo, s, p, o
				indexRemove ops, o, p, s

			updateItem = (entry, indexPutFn, indexRemoveFn) ->
				# we only update things that are different from the old_item
				# we also only update properties that are in the new item
				# if anything is changed, we return true
				#	otherwise, we return false
				id = entry.id
				type = entry.type
				changed = false

				itemListIdentical = (to, from) ->
					items_same = true
					return false if to.length != from.length
					for i in [0...to.length]
						if to[i] != from[i]
							items_same = false
					items_same

				removeValues = (id, p, list) -> indexRemoveFn(id, p, o) for o in list
				putValues = (id, p, list) -> indexPutFn(id, p, o) for o in list
				
				id = id[0] if $.isArray(id)
				type = type[0] if $.isArray(type)

				old_item = that.getItem id

				for p, items of entry
					continue if typeof(p) != "string" or p in ["id", "type"]

					# if entry[p] and old_item[p] have the same members in the same order, then
					# we do nothing

					items = [items] if !$.isArray(items)
					s = items.length;
					if !old_item[p]?
						putValues id, p, items
						changed = true
					else if !itemListIdentical items, old_item[p]
						changed = true
						removeValues id, p, old_item[p]
						putValues id, p, items
				changed

			that.events.onBeforeUpdating.fire that

			n = items.length
			chunk_size = parseInt(n / 100, 10)
			chunk_size = 200 if chunk_size > 200
			chunk_size = 1 if chunk_size < 1

			f = (start) ->
				end = start + chunk_size;
				end = n if end > n

				for i in [start ... end]
					entry = items[i]
					if typeof(entry) == "object" and updateItem entry, indexPutFn, indexRemoveFn
						id_list.push entry.id

				if end < n
					setTimeout () ->
						f end
					,
					0
				else
					that.events.onAfterUpdating.fire that
					that.events.onModelChange.fire that, id_list
					if fn?
						fn()
			f 0

		that.loadItems = (items, endFn) ->
			id_list = []

			indexFn = (s, p, o) ->
				indexPut spo, s, p, o
				indexPut ops, o, p, s

			loadItem = (item, indexFN) ->
				if !item.id?
					throw MITHGrid.error "Item entry has no id: ", item
				if !item.type?
					throw MITHGrid.error "Item entry has no type: ", item

				id = item.id
				type = item.type

				id = id[0] if $.isArray id
				type = type[0] if $.isArray type

				set.add id
				id_list.push id

				indexFn id, "type", type
				indexFn id, "id", id
				
				for p, v of item
					if typeof(p) != "string"
						continue
						
					if p not in ["id", "type"]
						if $.isArray(v)
							indexFn id, p, vv for vv in v
						else if v?
							indexFn id, p, v
			that.events.onBeforeLoading.fire that
			
			n = items.length
			if endFn?
				chunk_size = parseInt(n / 100, 10)
				chunk_size = 200 if chunk_size > 200
			else
				chunk_size = n
			chunk_size = 1 if chunk_size < 1
			
			f = (start) ->
				end = start + chunk_size
				end = n if end > n

				for i in [ start ... end ]
					entry = items[i]
					loadItem entry if typeof(entry) == "object"

				if end < n
					setTimeout () ->
						f(end)
					, 0
				else
					that.events.onAfterLoading.fire that
					that.events.onModelChange.fire that, id_list
					setTimeout endFn, 0 if endFn?
			f 0

		that.prepare = (expressions) ->
			parser = MITHGrid.Expression.initParser()
			parsed = (parser.parse(ex) for ex in expressions)
			valueType = undefined
			evaluate: (id) ->
				values = []
				valueType = undefined
				for ex in parsed
					do (ex) ->
						items = ex.evaluateOnItem id, that
						valueType or= items.valueType
						values = values.concat items.values.items()
				values
			valueType: () -> valueType

		that.getObjectsUnion = (subjects, p, set, filter) -> getUnion spo, subjects, p, set, filter
		that.getSubjectsUnion = (objects, p, set, filter) -> getUnion ops, objects,	 p, set, filter

		that

	Data.initView = (options) ->
		that = MITHGrid.initView "MITHGrid.Data.initView", options
		
		set = Data.initSet()
		
		filterItem = (id) ->
			false != that.events.onFilterItem.fire that.dataStore, id

		filterItems = (endFn) ->
			ids = that.dataStore.items()
			n = ids.length
			if n == 0
				endFn()
				return

			if n > 200
				chunk_size = parseInt(n / 100, 10)
				chunk_size = 200 if chunk_size > 200
			else
				chunk_size = n
			chunk_size = 1 if chunk_size < 1

			f = (start) ->
				end = start + chunk_size
				end = n if end > n

				for i in [ start ... end ]
					id = ids[i]
					if filterItem id
						set.add id
					else
						set.remove id
				if end < n
					setTimeout () ->
						f end
					, 0
				else
					that.items = set.items
					that.size = set.size
					that.contains = set.contains
					that.visit = set.visit
					if endFn?
						setTimeout endFn, 0
			f 0


		that.registerFilter = (ob) ->
			that.events.onFilterItem.addListener (x, y) -> ob.eventFilterItem x, y
			that.events.onModelChange.addListener (m, i) -> ob.eventModelChange m, i
			ob.events.onFilterChange.addListener that.eventFilterChange

		that.registerPresentation = (ob) ->
			that.events.onModelChange.addListener (m, i) -> ob.eventModelChange m, i
			filterItems () -> ob.eventModelChange that, that.items()

		that.items = set.items
		that.size = set.size
		that.contains = set.contains
		that.visit = set.visit
		
		that.eventFilterChange = () ->
			current_set = Data.initSet that.items()
			filterItems () ->
				changed_set = Data.initSet()
				for i in current_set.items()
					if !that.contains i
						changed_set.add i
				for i in that.items()
					if !current_set.contains i
						changed_set.add i
				if changed_set.size() > 0
					that.events.onModelChange.fire that, changed_set.items()
				
		that.eventModelChange = (model, items) ->
			changed_set = Data.initSet()
				
			for id in items
				if model.contains id
					if filterItem id
						set.add id
						changed_set.add id
					else
						if set.contains id
							changed_set.add id
							set.remove id
				else
					changed_set.add id
					set.remove id

			if changed_set.size() > 0
				that.events.onModelChange.fire that, changed_set.items()

		if options?.types?.length > 0
			((types) ->
				that.registerFilter
					eventFilterItem: (model, id) ->
						item = model.getItem id
						return false if !item.type?
						for t in types
							return if t in item.type
						return false
					eventModelChange: (x, y) ->
					events:
						onFilterChange:
							addListener: (x) ->
			)(options.types)

		if options?.filters?.length > 0
			((filters) ->
				parser = MITHGrid.Expression.initParser()
				parsedFilters = (parser.parse(ex) for ex in filters)
				that.registerFilter
					eventFilterItem: (model, id) ->
						for ex in parsedFilters
							values = ex.evaluateOnItem(id, model)
							values = values.values.items()
							for v in values
								return if v != "false"
						return false
					eventModelChange: (x, y) ->
					events:
						onFilterChange:
							addListener: (x) ->
			)(options.filters)

		if options?.collection?
			that.registerFilter
				eventFilterItem: options.collection
				eventModelChange: (x, y) ->
				events:
					onFilterChange:
						addListener: (x) ->

		if options?.expressions?
			# we want a way to make our set of items depend on running expressions on the items
			# passed to us from the parent dataView/dataStore
			# it needs to be quick, similar to the current propagation of changes
			# N.B.: these are not event-based expressions
			# the expressions must result in itemIds that are contained in the parent dataStore
			expressions = options.dataStore.prepare(options.expressions)
			prevEventModelChange = that.eventModelChange
			intermediateDataStore = MITHGrid.Data.initStore({})
			subjectSet = MITHGrid.Data.initSet()
			that.eventModelChange = (model, items) ->
				itemList = []
				removedItems = []
				intermediateSet = MITHGrid.Data.initSet()
				intermediateSet = intermediateDataStore.getObjectsUnion subjectSet, "mapsTo", intermediateSet
				for id in items
					if intermediateSet.contains(id)
						itemList.push id
						if !model.contains(id)
							# we need to find everything that maps to id
							idSet = MITHGrid.Data.initSet()
							intermediateDataStore.getSubjectsUnion MITHGrid.Data.initSet([id]), "mapsTo", idSet
							idSet.visit (x) ->
								item = intermediateDataStore.getItem x
								mapsTo = item.mapsTo
								if mapsTo?
									i = mapsTo.indexOf(id)
									if i == 0
										mapsTo = mapsTo[1 ... mapsTo.length]
									else if i == mapsTo.length-1
										mapsTo = mapsTo[0 ... mapsTo.length-1]
									else if i > -1
										mapsTo = mapsTo[0 ... i].concat mapsTo[i+1 ... mapsTo.length]
									intermediateDataStore.updateItems [
										id: x
										mapsTo: mapsTo
									]			
					else if model.contains(id)
						itemSet = MITHGrid.Data.initSet()
						for v in expressions.evaluate([id])
							itemSet.add(v)
						if intermediateDataStore.contains(id)
							intermediateDataStore.updateItems [
								id: id
								mapsTo: itemSet.items()
							]
						else
							intermediateDataStore.loadItems [
								id: id
								mapsTo: itemSet.items()
							]
					else
						# push onto itemList the items mapped to by this id
						itemList = itemList.concat(intermediateDataStore.getItem(id).mapsTo)
						removedItems.push id

				if removedItems.length > 0
					intermediateDataStore.removeItems(removedItems)

				intermediateSet = MITHGrid.Data.initSet()
				intermediateDataStore.getObjectsUnion subjectSet, "mapsTo", intermediateSet
				itemList = (item for item in itemList when item in items)
				prevEventModelChange intermediateSet, itemList

		that.dataStore = options.dataStore

		# these mappings allow a data View to stand in for a data Store
		that.getItems = that.dataStore.getItems
		that.getItem = that.dataStore.getItem
		that.removeItems = that.dataStore.removeItems
		that.fetchData = that.dataStore.fetchData
		that.updateItems = that.dataStore.updateItems
		that.loadItems = that.dataStore.loadItems
		that.prepare = that.dataStore.prepare
		that.addType = that.dataStore.addType
		that.getType = that.dataStore.getType
		that.addProperty = that.dataStore.addProperty
		that.getProperty = that.dataStore.getProperty
		that.getObjectsUnion = that.dataStore.getObjectsUnion
		that.getSubjectsUnion = that.dataStore.getSubjectsUnion
		
		that.dataStore.events.onModelChange.addListener that.eventModelChange

		that
		
	Data.initPager = (options) ->
		that = MITHGrid.initView "MITHGrid.Data.initPager", options
		options = that.options

		itemList = []
		itemListStart = -1
		itemListStop = -1
		leftKey = undefined
		rightKey = undefined
		
		# returns the first index that has a key greater than or equal to the given key
		findLeftPoint = (key) ->
			left = 0
			right = itemList.length - 1
			while left < right
				mid = ~~((left + right) / 2)
				
				if itemList[mid][0] < key
					left = mid + 1
				else if itemList[mid][0] == key
					right = mid
				else
					right = mid - 1
			left
			
		# returns the last index that has a key less than or equal to the given key
		findRightPoint = (key) ->
			left = 0
			right = itemList.length - 1
			while left < right
				mid = ~~((left + right) / 2)
				if itemList[mid][0] <= key
					left = mid + 1
				else
					right = mid - 1
			right
			
		findItemPosition = (itemId) ->
			for i in [0 ... itemList.length]
				return i if itemList[i][1] == itemId
			return -1
			

		set = Data.initSet()
		
		that.items = set.items
		that.size = set.size
		that.contains = set.contains
		that.visit = set.visit
		
		that.dataStore = options.dataStore
		# these mappings allow a data pager to stand in for a data Store
		that.getItems = that.dataStore.getItems
		that.getItem = that.dataStore.getItem
		that.removeItems = that.dataStore.removeItems
		that.fetchData = that.dataStore.fetchData
		that.updateItems = that.dataStore.updateItems
		that.loadItems = that.dataStore.loadItems
		that.prepare = that.dataStore.prepare
		that.addType = that.dataStore.addType
		that.getType = that.dataStore.getType
		that.addProperty = that.dataStore.addProperty
		that.getProperty = that.dataStore.getProperty
		that.getObjectsUnion = that.dataStore.getObjectsUnion
		that.getSubjectsUnion = that.dataStore.getSubjectsUnion
		
		expressions = that.prepare(options.expressions)
			
		that.eventModelChange = (model, items) ->
			# we're modifying the items we're tracking, possibly expanding or decreasing the set
			changedItems = [] # to propogate on to the next level
			for itemId in items
				if model.contains(itemId)
					keys = expressions.evaluate(itemId)
					if keys.length > 0
						if expressions.valueType() == "numeric"
							key = parseFloat(keys[0])
						else
							key = keys[0]
						if set.contains(itemId)
							i = findItemPosition itemId
							if i == -1
								itemList.push [ key, itemId ]
							else
								itemList[i][0] = key
							changedItems.push itemId
							if key < leftKey or key > rightKey
								set.remove(itemId)
						else
							itemList.push [ key, itemId ]
							if key >= leftKey and key <= rightKey
								set.add(itemId)
								changedItems.push itemId							
					else
						if set.contains(itemId)
							i = findItemPosition itemId
							if i == 0
								itemList = itemList[1...itemList.length]
							else if i == itemList.length-1
								itemList = itemList[0...itemList.length-1]
							else if i != -1
								itemList = itemList[0...i].concat itemList[i+1...itemList.length]
							set.remove(itemId)
							changedItems.push itemId
			# now sort itemList
			# and redo left and right positions
			# and double check set and changedItems list?
			itemList.sort (a,b) ->
				return -1 if a[0] < b[0]
				return  1 if a[0] > b[0]
				return  0
			itemListStart = findLeftPoint leftKey
			itemListStop  = findRightPoint rightKey

			if changedItems.length > 0
				that.events.onModelChange.fire that, changedItems

		that.setKeyRange = (l, r) ->
			if l < r
				leftKey = l
				rightKey = r
			else
				leftKey = r
				rightKey = l
				
			itemListStart = findLeftPoint leftKey
			itemListStop  = findRightPoint rightKey
			changedItems = Data.initSet()
			oldSet = set
			
			set = Data.initSet()
			that.items = set.items
			that.size = set.size
			that.contains = set.contains
			that.visit = set.visit
			
			if itemListStart < itemListStop
				for i in [itemListStart..itemListStop]
					itemId = itemList[i][1]
					if !oldSet.contains(itemId)
						changedItems.add itemId
					set.add(itemId)
			oldSet.visit (x) ->
				if !set.contains(x)
					changedItems.add x
			if changedItems.size() > 0
				that.events.onModelChange.fire that, changedItems.items()

		
		that.dataStore.events.onModelChange.addListener that.eventModelChange

		that