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
	Presentation.initInstance = (type, container, options) ->
		[ type, container, options ] = MITHGrid.normalizeArgs "MITHGrid.Presentation", type, container, options
		that = MITHGrid.initInstance type, container, options

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
						hasItem = model.contains(id)
						if renderings[id]?
							if !hasItem
							# item was removed
							# we need to remove it from the display
							# .remove() should not make changes in the model
								renderings[id].eventUnfocus() if activeRenderingId == id and renderings[id].eventUnfocus?
								renderings[id].remove() if renderings[id].remove?
								delete renderings[id]
							else
								renderings[id].update model.getItem(id)
						else if hasItem
							rendering = that.render container, model, id
							#lens = that.getLens id
							if rendering? #lens?
								renderings[id] = rendering #lens.render container, that, model, id
								if activeRenderingId == id and rendering.eventFocus?
									rendering.eventFocus()

					setTimeout () -> 
						f(end)
					, 0
				else
					that.finishDisplayUpdate()
			
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
		
		that

	Presentation.namespace "SimpleText", (SimpleText) ->
		SimpleText.initInstance = (klass, container, options) ->
			[ klass, container, options ] = MITHGrid.normalizeArgs "MITHGrid.Presentation.SimpleText", klass, container, options
			that = MITHGrid.Presentation.initInstance klass, container, options

			that