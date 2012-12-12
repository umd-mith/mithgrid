# # Presentations
#
MITHGrid.namespace 'Presentation', (Presentation) ->
	# ## Presentation.initInstance
	#
	# Initializes a presentation instance.
	#
	# Parameters:
	#
	# * type - 
	#
	# * container -
	#
	# * options -
	#
	Presentation.initInstance = (args...) ->
		MITHGrid.initInstance "MITHGrid.Presentation", args..., (that, container) ->
			activeRenderingId = null				
			renderings = {}
			lenses = that.options.lenses || {}
			options = that.options
				
			$(container).empty()

			lensKeyExpression = undefined
			options.lensKey ||= [ '.type' ]

			# ### #getLens
			#
			# Finds the lens constructor for the given item ID
			#
			# Parameters:
			#
			# * id - item ID
			#
			# Returns:
			#
			# The lens constructor.
			#
			that.getLens = (id) ->
				if lensKeyExpression?
					keys = lensKeyExpression.evaluate [id]
					key = keys[0]
				if key? and lenses[key]?
					return { render: lenses[key] }
	
			# ### #addLens
			#
			# Adds the renderer for the given key value.
			#
			# Parameters:
			#
			# * key - the key value for which the renderer should be used
			#
			# * lens - a function to render the item
			#
			# Returns: Nothing.
			#
			# A rendering function takes four parameters:
			#
			# * container -
			# * presentation -
			# * model -
			# * id -
			#
			# The rendering function should return an object that can be used to manage the rendering.
			#
			that.addLens = (key, lens) ->
				lenses[key] = lens
				that.selfRender()
		
			# ### #removeLens
			#
			# Removes the renderer for the given key value.
			#
			# Parameters:
			#
			# * key - the key value for which the renderer should be removed
			#
			# Returns: Nothing.
			#
			that.removeLens = (key) ->
				delete lenses[key]
	
			# ### #hasLens
			#
			# Returns true if a renderer exists for the given key value.
			#
			# Parameter:
			#
			# * key -
			#
			# Returns:
			#
			# True or false according to the existance of a renderer for the key value.
			#
			that.hasLens = (key) -> lenses[key]?
	
			# ### #visitRenderings
			#
			# Walks the list of renderings and calls the callback function on each one until the list is exhausted
			# or the callback function returns the "false" value.
			#
			# Parameters:
			#
			# cb - callback function taking two arguments: the item id and its rendering object
			#
			# Returns: Nothing.
			#
			that.visitRenderings = (cb) ->
				for id, r of renderings
					if false == cb(id, r)
						return

			# ### #renderingFor
			#
			# Returns the rendering object associated with the item ID if such an object exists.
			#
			# Parameters:
			#
			# * id - the item ID
			#
			# Returns:
			#
			# The rendering object if it exists.
			#
			that.renderingFor = (id) -> renderings[id]
	
			# ### #renderItems
			#
			# Renders the list of items in the model using the available lenses.
			#
			# Parameters:
			#
			# * model - data store or data view providing information for each item
			# * items - list of item IDs
			#
			# Returns: Nothing.
			#
			that.renderItems = (model, items) ->
				if !lensKeyExpression?
					lensKeyExpression = model.prepare options.lensKey
		
				n = items.length
				step = n
				if step > 200
					step = parseInt(Math.sqrt(step), 10) + 1
				step = 1 if step < 1
		
				f = (start) ->
					if start < n
						end = start + step
						end = n if end > n

						for i in [start ... end]
							id = items[i]
							hasItem = model.contains(id) and that.hasLensFor(id)
							if renderings[id]?
								if !hasItem
								# item or its lens was removed
								# we need to remove it from the display
								# .remove() should not make changes in the model
									renderings[id].eventUnfocus() if activeRenderingId == id and renderings[id].eventUnfocus?
									renderings[id].remove() if renderings[id].remove?
									delete renderings[id]
								else
									renderings[id].update model.getItem(id)
							else if hasItem
								rendering = that.render container, model, id
								if rendering?
									renderings[id] = rendering
									if activeRenderingId == id and rendering.eventFocus?
										rendering.eventFocus()

						setTimeout () -> 
							f(end)
						, 0
					else
						that.finishDisplayUpdate() if that.finishDisplayUpdate?
			
				that.startDisplayUpdate()
				f 0

			# ### #render
			#
			# Renders the given item using the appropriate lens.
			#
			# Parameters:
			#
			# c - DOM container into which the item should be rendered
			# m - data store or data view providing information for the item
			# i - the item ID
			#
			# Returns:
			#
			# The rendering object if an appropriate lens is found.
			#
			that.render = (c, m, i) ->
				lens = that.getLens i
				if lens?
					lens.render c, that, m, i
			
			that.hasLensFor = (id) ->
				lens = that.getLens id
				lens?

			# ### #eventModelChange
			#
			# By default, a presentation renders items as needed when the underlying data store or data view sees changes in
			# its data.
			that.eventModelChange = that.renderItems

			# ### #startDisplayUpdate
			#
			# Called before updating the renderings managed by the presentation.
			#
			that.startDisplayUpdate = () ->
		
			# ### #finishDisplayUpdate
			#
			# Called after updating the renderings managed by the presentation.
			#
			that.finishDisplayUpdate = () ->

			# ### #selfRender
			#
			# Renders all of the items in the data view attached to the presentation.
			#
			that.selfRender = () -> 
				that.renderItems that.dataView, that.dataView.items()
		
			# ### #eventFocusChange
			#
			# Changes focus to the rendering for the given item.
			#
			# Parameters:
			#
			# * id - the item ID to which focus should shift
			#
			# Returns: Nothing.
			#
			that.eventFocusChange = (id) ->
				if activeRenderingId?
					rendering = that.renderingFor activeRenderingId
				if activeRenderingId != id
					if rendering? and rendering.eventUnfocus?
						rendering.eventUnfocus()
					if id?
						rendering = that.renderingFor id
						if rendering? and rendering.eventFocus?
							rendering.eventFocus()
					activeRenderingId = id
				activeRenderingId
		
			# ### #getFocusedRendering
			#
			# Returns the rendering that has focus.
			#
			that.getFocusedRendering = () ->
				if activeRenderingId?
					that.renderingFor activeRenderingId
				else
					null

			# We do a little housekeeping to tie the presentation to the data view.
			that.dataView = that.options.dataView
			that.dataView.registerPresentation(that)

	Presentation.namespace "SimpleText", (SimpleText) ->
		SimpleText.initInstance = (args...) ->
			MITHGrid.Presentation.initInstance "MITHGrid.Presentation.SimpleText", args..., (that, container) ->

	# ## Table
	#
	# A table presentation provides a tabular view of the data. Lenses are not used for item types. Instead,
	# the data is presented based on the property type.
	#
	# Options:
	# 
	# * columns: list of columns (in the order to show)
	# * columnLabels
	#
	# **N.B.:** This presentation is a work in progress.
	#
	Presentation.namespace "Table", (Table) ->
		Table.initInstance = (args...) ->
			MITHGrid.Presentation.initInstance "MITHGrid.Presentation.Table", args..., (that, container) ->
				options = that.options
				
				tableEl = $("<table></table>")
				headerEl = $("<tr></tr>")
				tableEl.append(headerEl)
				
				for c in options.columns
					headerEl.append("<th>#{options.columnLabels[c]}</th>")
				
				$(container).append(tableEl)
				
				that.hasLensFor = -> true
				
				stringify_list = (list) ->
					if list?
						list = [].concat list
						if list.length > 1
							lastV = list.pop()
							text = list.join(", ")
							if list.length > 1
								text = text + ", and " + lastV
							else
								text = text " and " + lastV
						else
							text = list[0]
					else
						text = ""
					text
				
				that.render = (container, model, id) ->
					columns = {}
					rendering = {}
					el = $("<tr></tr>")
					rendering.el = el
					item = model.getItem id
					#
					# The `isEmpty` variable is a fix for a bug in the data store/view code that allows
					# an id to report as present even when the id has been deleted. 
					#
					isEmpty = true
					for c in options.columns
						cel = $("<td></td>")
						if item[c]?
							cel.text stringify_list item[c]
							isEmpty = false
						
							columns[c] = cel
						el.append(cel)
					if not isEmpty
						tableEl.append(el)
					
						rendering.update = (item) ->
							for c in options.columns
								if item[c]?
									columns[c].text stringify_list item[c]
					
						rendering.remove = ->
							el.hide()
							el.remove()
					
						rendering
					else
						el.remove()
						null