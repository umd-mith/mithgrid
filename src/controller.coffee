# # MITHGrid Controllers
#
# Controllers translate UI events into MITHGrid events. The goal is to create programs that only need a different set of
# controllers to allow a different manner of user interaction.
#
MITHGrid.namespace 'Controller', (Controller) ->
	# ## Controller.initInstance
	#
	# Controllers do not have any display component, so they only need a class name and the configuration object.
	# Controller objects use the #bind() method to bind a controller to a UI element. The returned object is used to
	# manage that particular binding.
	#
	# Parameters:
	#
	# * klass - the controller type name as a string
	#
	# * options - object holding configuration options
	#
	# Returns:
	#
	# An initialized controller object.
	#
	# Options:
	#
	# * **bind** - configuration options passed to the binding object constructor
	#
	# * **selectors** - a map of strings to CSS selectors for finding children of a UI element when binding
	#
	Controller.initInstance = (args...) ->
		MITHGrid.initInstance "MITHGrid.Controller", args..., (that) ->
			options = that.options
			options.selectors or= {}
	
			#
			# We need something that can have functions bindable to an element
			# this isn't that object, but can produce that object, so this is a kind of controller factory
			# that can be used by lenses
			#
			# ### #initBind
			#
			# Initialize the binding for the given element. If the element is a string or an object without
			# a .node property, then the element is assumed to be a DOM element. Otherwise, it is assumed to be
			# a Raphaël node.
			#
			# FIXME: This overloading should be two different classes. We should move the Raphaël code out of here
			# since this is the only piece of MITHGrid that understands anything about Raphaël. It's reasonable that
			# a developer know if they're dealing with a regular DOM element or a Raphaël node.
			#
			# Parameters:
			#
			# * element - the DOM element being bound
			#
			# Returns:
			#
			# The initialized binding object.
			#
			that.initBind = (element) ->
				MITHGrid.initInstance options.bind, (binding) ->
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
		
			# ### #bind
			#
			# Binds the controller to the given UI element and returns an object that can be used to manage the
			# binding. This is the method that will be used most outside the controller definition.
			#
			# Bindings can have events associated with them depending on how the controller is configured.
			#
			# Parameters:
			#
			# * element - the DOM element (or Raphaël node) to which the controller should bind
			#
			# * args... - optional arguments to be passed to the #applyBindings() method
			#
			# Returns:
			#
			# The binding object used to manage the binding.
			#
			that.bind = (element, args...) ->
				binding = that.initBind element
		
				that.applyBindings binding, args...
				
				binding.unbind = ->
					that.removeBindings binding, args...
		
				binding
	
			# ### #applyBindings
			#
			# This method should be overridden in any subclass. The #bind() method will call this with the
			# new binding object and any arguments passed to the #bind() method.
			#
			# Parameters:
			#
			# * binding - the new binding object
			#
			# * args... - any additional arguments passed to the #bind() method after the element being bound
			#
			# Returns: Nothing.
			#
			that.applyBindings = (binding, args...) ->
			
			# ### #removeBindings
			#
			# This method should be overridden in any subclass. The #unbind() method on the binding object
			# will call this with the binding object and any arguments passed to the #bind() method.
			#
			# Parameters:
			#
			# * binding - the binding object
			#
			# * args... - any additional aguments passed to the #bind() method that returned the binding object
			#
			# Returns: Nothing.
			#
			that.removeBindings = (binding, args...) ->

	Controller.namespace "Raphael", (Raphael) ->
		Raphael.initInstance = (args...) ->
			MITHGrid.Controller.initInstance "MITHGrid.Controller.Raphael", args..., (that) ->
				initDOMBinding = that.initBind
				that.initBind = (raphaelDrawing) ->
					binding = initDOMBinding raphaelDrawing.node

					superLocate = binding.locate
					superFastLocate = binding.fastLocate
					superRefresh = binding.refresh
					superBind = binding.bind

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