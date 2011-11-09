
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
	
	MITHGrid.globalNamespace = (nom) ->
		globals = window
		globals[nom] or= {}
		
		globals[nom]["debug"] or= MITHGrid.debug
		globals[nom]["namespace"] or= (n) ->
			genericNamespacer globals[nom], n
		globals[nom]
		
	MITHGrid.normalizeArgs = (type, types, container, options) ->
		if !options? && $.isPlainObject(container)
			options = container
			container = undefined
		if !container?
			if typeof types != "string"
				if !$.isArray(types)
					container = types
					types = []

		if !options?
			if typeof types == "string"
				types = [ types, type ]
				options = {}
			else if $.isArray types
				types.push type
				options = {}
			else
				options = types
				types = type
		else
			if typeof types == "string"
				types = [ types, type ]
			else if $.isArray types
				types.push type
			else
				types = type
				
		[ types, container, options ]
		
	
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
				listeners = (l for l in listeners when l[1] != listener)
			else
				listeners = (l for l in listeners when l[0] != listener)

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
						console.log listener[0], args, e
				true
		that
		

	initViewCounter = 0
	
	MITHGrid.initView = (namespace, container, config) ->
		if !config?
			config = container
			container = undefined
		if !config? and !(typeof namespace == "string" || $.isArray(namespace))
			config = namespace
			namespace = null
		that = {}
		options = {}
		if namespace? 
			if typeof namespace == "string"
				namespace = [ namespace ]
			namespace.reverse()
			for ns in namespace
				bits = ns.split('.')
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