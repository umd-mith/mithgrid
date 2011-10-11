
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
				chunk_size = 1 if chunk_size < 1
			else
				chunk_size = n
				
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
					setTimeout () ->
						that.events.onAfterLoading.fire that
						setTimeout () ->
							that.events.onModelChange.fire that, id_list
							setTimeout endFn, 0 if endFn?
						, 0
					, 0
			f 0

		that.prepare = (expressions) ->
			parsed = (MITHGrid.Expression.initParser().parse(ex) for ex in expressions)

			evaluate: (id) ->
				values = []
				for ex in parsed
					do (ex) ->
						items = ex.evaluateOnItem id, that
						values = values.concat items.values.items()
				values

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