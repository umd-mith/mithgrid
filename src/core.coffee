# # namespace management
#
# These functions are available as properties of the global MITHGrid object. The debug() and namespace()
# functions are properties of all namespaces created using MITHGrid.
#

# ## MITHGrid.debug
#
# If you don't know if the console.log is available, use MITHGrid.debug. If console.log is available, it's the same
# function. Otherwise, it's a NOP.
#
if window?.console?.log?
	MITHGrid.debug = window.console.log
else 
	MITHGrid.debug = () ->

# ## MITHGrid.error
#
# MITHGrid.error will be like MITHGrid.debug except that it will return the arguments in an object that can be thrown as
# an error. It is used in the data store loadItems() function.
#
MITHGrid.error = () ->
	MITHGrid.debug.call {}, arguments
	{ 'arguments': arguments }

# ## MITHGrid.namespace
#
# Ensures the namespace exists as a property of the MITHGrid global.
# Any namespace created will have the debug() and namespace()
# functions available.
#
# Parameters:
#
# * nom - the name of the namespace
# * fn  - optional callback to be called with the new namespace
#
# Returns:
#
# The object corresponding to the namespace.
#

MITHGrid.namespace = (nom, fn) ->
	genericNamespacer MITHGrid, nom, fn
	
#
# We need a general way to handle namespace creation. We do this so we can use closures when creating the
# namespace.
genericNamespacer = (base, nom, fn) ->
	# TODO: check for '.' in nom
	bits = nom.split('.')
	while bits.length > 1
		if !base[bits[0]]
			base = genericNamespacer base, bits[0]
			bits.shift()
	if !base[bits[0]]?
		newbase =
			namespace: (nom2, fn2) ->
				genericNamespacer newbase, nom2, fn2
			debug: MITHGrid.debug
	base[bits[0]] = newbase
	if fn?
		fn base[bits[0]]
	base[bits[0]]

# ## MITHGrid.globalNamespace
#
# Ensures the namespace exists in the global space.
# Any namespace created will have the debug() and namespace() functions available.
#
# Parameters:
#
# * nom - the name of the namespace
# * fn  - optional callback to be called with the new namespace
#
# Returns:
#
# The object corresponding to the namespace.
#
MITHGrid.globalNamespace = (nom, fn) ->
	globals = window
	globals[nom] or= {}
	
	globals[nom]["debug"] or= MITHGrid.debug
	globals[nom]["namespace"] or= (n, f) ->
		genericNamespacer globals[nom], n, f
	if fn?
		fn globals[nom]
	globals[nom]

# # that-ism helper functions
#
# These functions are available as properties of the global MITHGrid object.	

# ## MITHGrid.normalizeArgs
#
# Accepts the arguments passed in from the constructor and sorts out the various pieces.
#
# Parameters:
#
# * type - the namespace of the object initializer
# * types - an optional array of super namespaces
# * container - an optional DOM object managed by the object being initialized
# * options - an optional object holding configuration information for the object initializer
#
# Returns:
#
# An array of three elements: a list of namespaces, the DOM container, and the options object.
#
MITHGrid.normalizeArgs = (args...) ->
	# String
	# optional String/Array
	# optional DOM/String
	# optional Object
	# optional Function
	
	callbacks = []
	t = args.pop()
	while $.isFunction t
		callbacks.push t
		t = args.pop()
	
	if callbacks.length == 0
		cb = (t...) ->
	else if callbacks.length == 1
		cb = callbacks[0]
	else
		cb = (t...) ->
			for c in callbacks
				c(t...)
	
	if $.isPlainObject t
		options = t
	else
		args.push t
		options = {}
	
	# while the front of args is a string, we shift into the type array
	types = []
	while typeof args[0] == "string"
		if args[0].substr(0,1) in ["#", "."]
			break
		types.push args.shift()
	
	types = types.reverse()
	
	if $.isArray args[0]
		types = types.concat args.shift()
	
	if args.length > 0
		container = args.pop()
	else
		container = null
			
	[ types, container, options, cb ]
	

MITHGridDefaults = {}

# ## MITHGrid.defaults
#
# Allows default configuration values to be set for a given namespace.
#
# Parameters:
#
# * namespace - the namespace for which the defaults should be set
# * defaults - object containing default configuration information
#
# Returns: Nothing.
#
MITHGrid.defaults = (namespace, defaults) ->
	MITHGridDefaults[namespace] or= {}
	MITHGridDefaults[namespace] = $.extend(true, MITHGridDefaults[namespace], defaults)
	
# # Synchonizer
#
# ## MITHGrid.initSynchronizer
#
# Parameters:
#
# * callbacks - an object with an optional "done" property providing a function to call when the counter is zero and
# the done() method has been called.
#
# Returns:
#
# The synchronizer object.
#
MITHGrid.initSynchronizer = (callbacks) ->
	that = {}
	counter = 1
	done = false
	fired = false
	if !callbacks.done?
		that.increment = () ->
		that.decrement = that.increment
		that.done = that.increment
		that.add = (v) ->
	else
		# ### #increment
		#
		# Increments the synchronizer counter by one.
		#
		# Returns:
		#
		# The new value of the synchronizer counter.
		#
		that.increment = () -> counter += 1
		# ### #add
		#
		# Adds the indicated number to the synchronizer.
		#
		# Parameters:
		#
		# * n - how much to add to the synchronizer counter
		#
		# Returns:
		#
		# The new value of the synchronizer counter.
		#
		that.add = (n) -> counter += n
		# ### #decrement
		#
		# Decrements the synchronizer counter by one.
		#
		# Returns:
		#
		# The new value of the synchronizer counter.
		#
		that.decrement = () ->
			counter -= 1
			if counter <= 0 and done and !fired
				fired = true
				callbacks.done
			counter
		# ### #done
		#
		# Marks the synchronizer as done. The counter should monotonically decrease after this. Once it is zero, the
		# "done" callback will run.
		#
		# Returns:
		#
		# The new value of the synchronizer counter. If it is zero, then the "done" callback should be scheduled to run.
		#
		that.done = () ->
			done = true
			that.decrement()

	that
       
# # EventFirer
#
# ## MITHGrid.initEventFirer
#
# Parameters:
#
# * isPreventable - true if a listener can prevent further listeners from receiving the event
# * isUnicast - true if only one listener receives the event
#
# Returns:
#
# The EventFirer object.
#
MITHGrid.initEventFirer = (isPreventable, isUnicast) ->
	that = {}
	that.isPreventable = isPreventable
	that.isUnicast = isUnicast
	listeners = []
	
	# ### #addListener
	#
	# Adds a listener to an event.
	#
	# Parameters:
	#
	# * listener - function to call when event fires
	# * namespace - optional namespace parameter that can be used to remove listeners
	#
	# Returns: Nothing.
	#
	that.addListener = (listener, namespace) ->
		listeners.push [listener, namespace]
	
	# ### #removeListener
	#
	# Removes a listener (or set of listeners) from an event firer.
	#
	# Parameters:
	#
	# * listener - function or string to remove from list of listeners
	#
	# Returns: Nothing.
	#
	that.removeListener = (listener) ->
		if typeof listener == "string"
			listeners = (l for l in listeners when l[1] != listener)
		else
			listeners = (l for l in listeners when l[0] != listener)

	# ### #fire
	#
	# Fire's behavior depends on the type of event that is firing.
	#
	# If a unicast event, then fire() will call the first listener. All other listeners will be ignored.
	#
	# If the event is preventable, then fire() will call each listener in turn until either it runs out of
	# listeners or a listener returns the "false" value.
	#
	# If the event is neither unicast nor preventable, then fire() will call each listener in turn. After all listeners
	# are called, it will return the "true" value.
	#
	# Parameters:
	#
	# * args... - all arguments are passed to the listener without modification
	#
	# Returns:
	#
	# Fire's behavior depends on the type of event that is firing.
	#
	# A unicast event will always return the value returned by the listener. If there are no listeners, it will return
	# the "true" value.
	#
	# If the event is preventable, then fire() will return the "false" value if a listener returns "false". Otherwise,
	# it will return "true".
	#
	# If neither unicast nor preventabe, then fire() will return "true" regardless of how many listeners are called.
	#
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
	

# # Object Instances
#
# We use a local global to track how many objects we've initialized so we can assign a unique number
# to each. This is useful when debugging to see if you are creating the right number of objects or too many.
#
initViewCounter = 0

# ## MITHGrid.initInstance
#
# Initialize an object based on that-ism principles.
#
# Parameters:
#
# * namespace - the name of the object type being initialized
# * container - optional DOM object in which this object can place content
# * config - object containing configuration information for this object
#
# Returns:
#
# The instantiated and initialized object.
#
MITHGrid.initInstance = (args...) ->
	[namespace, container, config, cb] = MITHGrid.normalizeArgs args...
	that = {}
	optionsArray = [ ]
	if namespace? 
		if typeof namespace == "string"
			namespace = [ namespace ]
		namespace.reverse()
		for ns in namespace
			bits = ns.split('.')
			ns = bits.shift()
			if MITHGridDefaults[ns]?
				optionsArray.push MITHGridDefaults[ns]
			while bits.length > 0
				ns = ns + "." + bits.shift()
				if MITHGridDefaults[ns]?
					optionsArray.push MITHGridDefaults[ns]
	if config?
		optionsArray.push config

	options = $.extend(true, {}, optionsArray...)
	
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
	if cb?
		cb that, container
	that