
	Facet = MITHGrid.namespace 'Facet'
	Facet.initFacet = (klass, container, options) ->
		that = MITHGrid.initView(klass, container, options)
		
		options = that.options
		
		that.selfRender = () ->
			# do nothing - needs to be implemented in the subclass
		
		that.eventFilterItem = (model, itemId) ->
			return false # we don't accept anything by default
			
		that.eventModelChange = (model, itemList) ->
			# we don't do anything by default
				
		that.constructFacetFrame = (container, options) ->
			dom = {}
			
			$(container).addClass "mithgrid-facet"
			dom.header = $("<div class='header' />")
			if options.onClearAllSelections?
				dom.controls = $("<div class='control' title='Clear Selection'>")
				dom.counter = $("<span class='counter'></span>")
				dom.controls.append(dom.counter)
				dom.header.append(dom.controls)
			dom.title = $("<span class='title'></span>")
			dom.title.text(options.facetLabel or "")
			dom.header.append(dom.title)
			dom.bodyFrame = $("<div class='body-frame'></div>")
			dom.body = $("<div class='body'></div>")
			dom.bodyFrame.append(dom.body)
			
			$(container).append(dom.header)
			$(container).append(dom.bodyFrame)
			
			if options.onClearAllSelections?
				dom.controls.bind "click", options.onClearAllSelections
			
			dom.setSelectionCount = (count) ->
				dom.counter.innerHTML = count
				if count > 0
					dom.counter.show()
				else
					dom.counter.hide()
			
			dom
		
		that.events or= {}
		that.events.onFilterChange = fluid.event.getEventFirer()
		
		options.dataView.registerFilter that
		
		that
		
	Facet.namespace 'TextSearch'
	Facet.TextSearch.initFacet = (container, options) ->
		that = Facet.initFacet("MITHGrid.Facet.TextSearch", container, options)
		
		options = that.options
		
		if options.expressions?
			if !$.isArray(options.expressions)
				options.expressions = [ options.expressions ]
				parsed = (MITHGrid.Expression.initParser().parse(ex) for ex in options.expressions)
		
		that.eventFilterItem = (dataSource, id) ->
			if that.text? and options.expressions?
				for ex in parsed
					items = ex.evaluateOnItem id, dataSource
					for v in items.values.items()
						if v.toLowerCase().indexOf(that.text) >= 0
							return
			
			return false
			
		that.eventModelChange = (dataView, itemList) ->
		
		that.selfRender = () ->
			dom = that.constructFacetFrame container, null,
				facetLabel: options.facetLabel
			$(container).addClass "mithgrid-facet-textsearch"
			inputElement = $("<input type='text'>")
			dom.body.append(inputElement)
			inputElement.keyup () ->
				that.text = $.trim(inputElement.val().toLowerCase())
				that.events.onFilterChange.fire()
		
		that
	
	Facet.namespace 'List'
	Facet.List.initFacet = (container, options) ->
		that = Facet.initFacet("MITHGrid.Facet.List", container, options)
		
		options = that.options
		
		that.selections = []
		
		if options.expressions?
			if !$.isArray(options.expressions)
				options.expressions = [ options.expressions ]
				parsed = (MITHGrid.Expression.initParser().parse(ex) for ex in options.expressions)
		
		that.eventFilterItem = (dataSource, id) ->
			if that.text? and options.expressions?
				for ex in parsed
					items = ex.evaluateOnItem id, dataSource
					for v in items.values.items()
						if v in that.selections
							return
							
		that.selfRender = () ->
			dom = that.constructFacetFrame container, null,
				facetLabel: options.facetLabel
				resizable: true
		
		that
		
	Facet.namespace 'Range'
	Facet.Range.initFacet = (container, options) ->
		that = Facet.initFacet("MITHGrid.Facet.Range", container, options)
		
		options = that.options
		options.min or= 0
		options.max or= 100
		options.step or= 1.0 / 30.0

		that.selfRender = () ->
			dom = that.constructFacetFrame container, null,
				facetLabel: options.facetLabel
				resizable: false
				
			# now add range input element
			# <input type="range" min="0" max="length of video" step="0.033333333333" value="0" />
			inputElement = $("<input type='range'>")
			inputElement.attr
				min: options.min
				max: options.max
				step: options.step
			dom.body.append(inputElement)
			inputElement.event () ->
				that.value = inputElement.val()
				that.events.onFilterChange.fire()

		that