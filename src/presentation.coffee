
	MITHGrid.namespace 'Presentation'

	MITHGrid.Presentation.initPresentation = (type, container, options) ->
		that = fluid.initView "MITHGrid.Presentation.#{type}", container, options
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
			f = (start) ->
				if start < n
					end = n
					if n > 200
						end = start + parseInt(Math.sqrt(n), 10) + 1
						end = n if end > n

					for i in [start ... end] #i = start; i < end; i += 1)
						id = items[i]
						hasItem = model.contains(id)
						if !hasItem
							# item was removed
							if renderings[id]?
							# we need to remove it from the display
							# .remove() should not make changes in the model
								renderings[id].remove()
								delete renderings[id]
						else if renderings[id]?
							renderings[id].update model.getItem(id)
						else
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