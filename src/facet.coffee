# # Facets
#
MITHGrid.namespace 'Facet', (Facet) ->
	# ## Facet.initInstance
	#
	Facet.initInstance = (args...) ->
		MITHGrid.initInstance "MITHGrid.Facet", args..., (that, container) ->
	
			options = that.options
	
			# ### #selfRender
			#
			# Renders the facet UI elements. This **must** be implemented in any subclass.
			#
			that.selfRender = () ->
	
			# ### #eventFilterItem
			#
			# The default event listener for filtering items
			#
			# Parameters:
			#
			# * model - the data store or data view holding data associated with the item
			# * itemId - the item ID of the item being filtered
			#
			# Returns:
			#
			# If the item should not be included in the data view's list of items, then this
			# should return the "false" value. The default implementation returns "false" for
			# all items.
			#
			that.eventFilterItem = (model, itemId) ->
				return false
		
			# ### #eventModelChange
			#
			# The default event listener for model changes
			#
			# Parameters:
			#
			# * model - the data store or data view holding data associated with the items
			# * itemList - list of item IDs for items which have changed (added, modified, or deleted)
			#
			# Returns: Nothing.
			#
			that.eventModelChange = (model, itemList) ->
			
			# ### #constructFacetFrame
			#
			# Builds a standard HTML scaffold for facets.
			#
			# Parameters:
			#
			# * container - the DOM element in which to build the scaffolding
			# * options - an object holding the configuration options
			#
			# Returns:
			#
			# An object holding various elements making up the scaffold:
			#
			# * .header
			# * .title
			# * .controls
			# * .counter
			# * .bodyFrame
			# * .body
			# * .setSelectionCount(count)
			#
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
	
			options.dataView.registerFilter that
		
	Facet.namespace 'TextSearch', (TextSearch) ->
		# ## TextSearch Facet
		#
		# 
		TextSearch.initInstance = (args...) ->
			Facet.initInstance "MITHGrid.Facet.TextSearch", args..., (that) ->
	
				options = that.options
	
				if options.expressions?
					if !$.isArray(options.expressions)
						options.expressions = [ options.expressions ]
					parser = MITHGrid.Expression.Basic.initInstance()
					parsed = (parser.parse(ex) for ex in options.expressions)
	
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
	
	Facet.namespace 'List', (List) ->
		List.initInstance = (args...) ->
			Facet.initInstance "MITHGrid.Facet.List", args..., (that) ->
	
				options = that.options
	
				that.selections = []
	
				if options.expressions?
					if !$.isArray(options.expressions)
						options.expressions = [ options.expressions ]
					parser = MITHGrid.Expression.Basic.initInstance()
					parsed = (parser.parse(ex) for ex in options.expressions)
	
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
	
	Facet.namespace 'Range', (Range) ->
		Range.initInstance = (args...) ->
			Facet.initInstance "MITHGrid.Facet.Range", args..., (that) ->
	
				options = that.options
				options.min ?= 0
				options.max ?= 100
				options.step ?= 1.0 / 30.0

				that.selfRender = () ->
					dom = that.constructFacetFrame container, null,
						facetLabel: options.facetLabel
						resizable: false

					inputElement = $("<input type='range'>")
					inputElement.attr
						min: options.min
						max: options.max
						step: options.step
					dom.body.append(inputElement)
					inputElement.event () ->
						that.value = inputElement.val()
						that.events.onFilterChange.fire()