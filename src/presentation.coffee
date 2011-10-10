
	MITHGrid.namespace 'Presentation'

	MITHGrid.Presentation.initPresentation = (type, container, options) ->
		that = {}
		that = MITHGrid.initView "MITHGrid.Presentation.#{type}", container, options

			
		renderings = {}
		lenses = that.options.lenses
		options = that.options
		
		$(container).empty()

		that.getLens = (item) ->
			if item.type? and item.type[0]? and lenses[item.type[0]]?
				return { render: lenses[item.type[0]] }

		that.renderingFor = (id) -> renderings[id]

		that.renderItems = (model, items) ->
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
							lens = that.getLens model.getItem(id)
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