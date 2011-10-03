
	if window?.console?.log?
		MITHGrid.debug = window.console.log
	else 
		MITHGrid.debug = () ->

	MITHGrid.error = () ->
		MITHGrid.debug.call {}, arguments
		{ 'arguments': arguments }

	genericNamespacer = (base, nom) ->
		if !base[nom]?
			newbase =
				namespace: (nom2) ->
					genericNamespacer newbase, nom2
				debug: MITHGrid.debug
		base[nom] = newbase

	MITHGrid.namespace = (nom) ->
		genericNamespacer MITHGrid, nom
	
	MITHGridDefaults = {}
	
	MITHGrid.defaults = (namespace, defaults) ->
		MITHGridDefaults[namespace] or= {}
		MITHGridDefaults[namespace] = $.extend(true, MITHGridDefaults[namespace], defaults)
		
	MITHGrid.initEventFirer = (isPreventable, isUnicast) ->
		that = {}
		that.isPreventable = isPreventable
		that.isUnicast = isUnicast
		listeners = []
		
		
		that.addListener = (listener, namespace) ->
			listeners.push [listener, namespace]
		
		that.removeListener = (listener) ->
			if typeof listener == "string"
				# remove namespace
				listeners = (listener for listener in listeners when listener[1] != listener)
			else
				listeners = (listener for listener in listeners when listener[0] != listener)

		if isUnicast
			that.fire = (args...) ->
				if listeners.length > 0
					try
						listeners[0][0](args...)
					catch e
						console.log e
				else
					true
		else if isPreventable
			that.fire = (args...) ->
				r = true
				for listener in listeners
					l = listener[0]
					try
						r = l(args...)
					catch e
						console.log e
					if r == false
						return false
				true
		else
			that.fire = (args...) ->
				for listener in listeners
					try
						listener[0](args...)
					catch e
						console.log e
				true
		that
		
	initViewCounter = 0
	MITHGrid.initView = (namespace, container, config) ->
		if !config?
			config = container
			container = undefined
		
		that = {}
		options = {}
		bits = namespace.split('.')
		ns = bits.shift()
		options = $.extend(true, {}, MITHGridDefaults[ns]||{})
		while bits.length > 0
			ns = ns + "." + bits.shift()
			options = $.extend(true, options, MITHGridDefaults[ns]||{})
		options = $.extend(true, options, config||{})

		initViewCounter += 1
		that.id = initViewCounter
		that.options = options
		that.container = container
		that.events = {}
		
		if that.options.events?
			for k, c of that.options.events
				if c?
					if typeof c == "string"
						c = [ c ]
				else
					c = []
				that.events[k] = MITHGrid.initEventFirer( ("preventable" in c), ("unicast" in c))
		that