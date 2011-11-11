
	MITHGrid.namespace 'Presentation'

	MITHGrid.Presentation.initPresentation = (type, container, options) ->
		[ type, container, options ] = MITHGrid.normalizeArgs "MITHGrid.Presentation", type, container, options
		that = MITHGrid.initView type, container, options

			
		renderings = {}
		lenses = that.options.lenses
		options = that.options
		
		$(container).empty()

		lensKeyExpression = undefined
		options.lensKey ||= [ '.type' ]

		that.getLens = (id) ->
			if lensKeyExpression?
				keys = lensKeyExpression.evaluate [id]
				key = keys[0]
			if key? and lenses[key]?
				return { render: lenses[key] }

		that.renderingFor = (id) -> renderings[id]

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
								renderings[id].remove() if renderings[id].remove?
								delete renderings[id]
							else
								renderings[id].update model.getItem(id)
						else if hasItem
							lens = that.getLens id
							if lens?
								renderings[id] = lens.render container, that, model, id

					setTimeout () -> 
						f(end)
					, 0
				else
					that.finishDisplayUpdate()
				
			that.startDisplayUpdate()
			f 0

		that.eventModelChange = that.renderItems

		that.startDisplayUpdate = () ->
		that.finishDisplayUpdate = () ->

		that.selfRender = () -> 
			that.renderItems that.dataView, that.dataView.items()
		
		that.dataView = that.options.dataView
		that.dataView.registerPresentation(that)
		that

	MITHGrid.Presentation.namespace "SimpleText"
	MITHGrid.Presentation.SimpleText.initPresentation = (klass, container, options) ->
		[ klass, container, options ] = MITHGrid.normalizeArgs "MITHGrid.Presentation.SimpleText", klass, container, options
		that = MITHGrid.Presentation.initPresentation klass, container, options

		that