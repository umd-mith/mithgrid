
	Controller = MITHGrid.namespace 'Controller'
	Controller.initController = (klass, options) ->
		[ klass, options ] = MITHGrid.normalizeArgs "MITHGrid.Controller", klass, options
		that = MITHGrid.initView klass, options
		options = that.options
		options.selectors or= {}
		
		###
		# We need something that can have functions bindable to an element
		# this isn't that object, but can produce that object, so this is a kind of controller factory
		# that can be used by lenses
		###
		
		that.initBind = (element) ->
			binding = MITHGrid.initView options.bind
			bindingsCache = { '': $(element) }
			
			binding.locate = (internalSelector) ->
				selector = options.selectors[internalSelector]
				if selector?
					if selector == ''
						el = $(element)
					else
						el = $(element).find(selector)
					bindingsCache[selector] = el
					return el
				return undefined
			
			binding.fastLocate = (internalSelector) ->
				selector = options.selectors[internalSelector]
				if selector?
					if bindingsCache[selector]?
						return bindingsCache[selector]
					return binding.locate internalSelector
				return undefined
				
			binding.refresh = (listOfSelectors) ->
				for internalSelector in listOfSelectors
					selector = options.selectors[internalSelector]
					if selector?
						if selector == ''
							bindingsCache[''] = $(element)
						else
							bindingsCache[selector] = $(element).find(selector)
				return undefined
			
			binding.clearCache = () ->
				bindingsCache = { '': $(element) }
			
			binding
			
		that.bind = (element, args...) ->
			binding = that.initBind element
			
			that.applyBindings binding, args...
			
			binding
		
		that.applyBindings = (binding, args...) ->
			
		that
		
	Controller.initRaphaelController = (klass, options) ->
		that = MITHGrid.Controller.initController klass, options
		
		superInitBind = that.initBind
		
		that.initBind = (raphaelDrawing) ->
			binding = superInitBind raphaelDrawing.node
			
			superLocate = binding.locate
			superFastLocate = binding.fastLocate
			superRefresh = binding.refresh
			
			binding.locate = (internalSelector) ->
				if internalSelector == 'raphael'
					raphaelDrawing
				else
					superLocate internalSelector
			
			binding.fastLocate = (internalSelector) ->
				if internalSelector == 'raphael'
					raphaelDrawing
				else
					superFastLocate internalSelector
					
			binding.refresh = (listOfSelectors) ->
				listOfSelectors = (s for s in listOfSelectors when s != 'raphael')
				superRefresh listOfSelectors
		
			binding

		that