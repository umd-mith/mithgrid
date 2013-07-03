# # namespace management
#
# These functions are available as properties of the global MITHgrid object. The debug() and namespace()
# functions are properties of all namespaces created using MITHgrid.
#

# ## MITHgrid.debug
#
# If you don't know if the console.log is available, use MITHgrid.debug. If console.log is available, it's the same
# function. Otherwise, it's a NOP.
#
if console?.log?
  MITHgrid.debug = console.log
else 
  MITHgrid.debug = ->

# ## MITHgrid.error
#
# MITHgrid.error will be like MITHgrid.debug except that it will return the arguments in an object that can be thrown as
# an error. It is used in the data store loadItems() function.
#
MITHgrid.error = ->
  MITHgrid.debug.call {}, arguments
  { 'arguments': arguments }

# ## MITHgrid.depracated
#
# Produces an augmented function that outputs a warning through MITHgrid.debug 
# about the call to the function.
# We need to make it produce a context for the call so we know where to look.
#
MITHgrid.deprecated = (fname, cb) ->
  (args...) ->
    console.log "Call to deprecated function #{fname}."
    cb args...
  
# ## MITHgrid.namespace
#
# Ensures the namespace exists as a property of the MITHgrid global.
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

MITHgrid.namespace = (nom, fn) ->
  genericNamespacer MITHgrid, nom, fn
  
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
      debug: MITHgrid.debug
    base[bits[0]] = newbase
  if fn?
    fn base[bits[0]]
  base[bits[0]]

# ## MITHgrid.globalNamespace
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
MITHgrid.globalNamespace = (nom, fn) ->
  globals = window
  globals[nom] or= {}
  
  globals[nom]["debug"] or= MITHgrid.debug
  globals[nom]["namespace"] or= (n, f) ->
    genericNamespacer globals[nom], n, f
  if fn?
    fn globals[nom]
  globals[nom]

# # that-ism helper functions
#
# These functions are available as properties of the global MITHgrid object.  

# ## MITHgrid.normalizeArgs
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
MITHgrid.normalizeArgs = (args...) ->
  # String
  # optional String/Array
  # optional DOM/String
  # optional Object
  # optional Function
  
  callbacks = []
  options = []
  
  t = args.pop()
  while $.isFunction(t) or $.isPlainObject(t)
    if $.isFunction t
      callbacks.push t
    else
      options.push t
    t = args.pop()

  args.push t
  
  
  if callbacks.length == 0
    cb = (t...) ->
  else if callbacks.length == 1
    cb = callbacks[0]
  else
    cb = (t...) ->
      for c in callbacks
        c(t...)
  
  if options.length == 0
    opts = {}
  else if options.length == 1
    opts = options[0]
  else
    options = options.reverse()
    opts = $.extend true, {}, options...
  
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
      
  [ types, container, opts, cb ]
  

MITHgridDefaults = {}

# ## MITHgrid.defaults
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
MITHgrid.defaults = (namespace, defaults) ->
  MITHgridDefaults[namespace] or= {}
  MITHgridDefaults[namespace] = $.extend(true, MITHgridDefaults[namespace], defaults)
  
# # Synchonizer
#
# ## MITHgrid.initSynchronizer
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
MITHgrid.initSynchronizer = (callback) ->
  that = {}
  counter = 1
  done = false
  fired = false
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
      callback() if callback?
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
  that.done = (cb) ->
    done = true
    callback = cb if cb?
    that.decrement()

  that.process = (items, cb) ->
    n = items.length
    if n > 0
      that.add n
      processItems = (start) ->
        end = start + 100
        end = n if end > n
        for i in [start ... end]
          cb(items[i])
          that.decrement()
        if end < n
          setTimeout ->
            processItems end
          , 0
      setTimeout ->
        processItems 0
      , 0

  that
       
# # EventFirer
#
# ## MITHgrid.initEventFirer
#
# Parameters:
#
# * isPreventable - true if a listener can prevent further listeners from receiving the event
# * isUnicast - true if only one listener receives the event
# * hasMemory - true if the event firer fires for each value it has been fired for when a new listener is added
#
# Returns:
#
# The EventFirer object.
#
MITHgrid.initEventFirer = (isPreventable, isUnicast, hasMemory) ->
  that =
    isPreventable: !!isPreventable
    isUnicast: !!isUnicast
    hasMemory: !!hasMemory
  
  callbackFlags = []
  
  if that.isPreventable
    callbackFlags.push "stopOnFalse"

  callbacks = $.Callbacks(callbackFlags.join(" "))
  
  destroyer = ->
    callbacks.empty()

  # ### #removeListener
  #
  # Removes a listener (or set of listeners) from an event firer.
  #
  # Parameters:
  #
  # * listener - function to remove from list of listeners
  #
  # Returns: Nothing.
  #
  remover = (listener) -> callbacks.remove listener
  
  # ### #addListener
  #
  # Adds a listener to an event.
  #
  # Parameters:
  #
  # * listener - function to call when event fires
  #
  # Returns: Callback to remove listener.
  #
  adder = (listener) -> 
    callbacks.add listener
    -> remover listener
  
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
  firer = (args...) -> callbacks.fire args...
      
  if that.isUnicast or that.isPreventable
    callbackFns = []
    
    remover = (listener) ->
      callbackFns = (fn for fn in callbackFns when fn != listener)
    adder = (listener) ->
      callbackFns.push listener
      -> remover listener
    
    if that.isUnicast
      callbacks.add (args...) ->
        if callbackFns.length > 0
          callbackFns[0](args...)

    if that.isPreventable
      firer = (args...) ->
        for fn in callbackFns
          r = fn(args...)
          if r == false
            return false
        return true
        
    destroyer = ->
      callbackFns = []
      callbacks.empty()
  
  else if that.hasMemory
    memory = []
    
    oldAdder = adder
    adder = (listener) ->
      for m in memory
        listener(m...)
      oldAdder listener
    
    oldFirer = firer
    firer = (args...) ->
      memory.push args
      oldFirer args...
    
    destroyer = ->
      memory = []
      callbacks.empty()
  
  that.addListener = adder
  
  that.removeListener = remover

  that.fire = firer
  
  that._destroy = destroyer
  
  that
  

# # Object Instances
#
# We use a local global to track how many objects we've initialized so we can assign a unique number
# to each. This is useful when debugging to see if you are creating the right number of objects or too many.
#
initViewCounter = 0

# ## MITHgrid.initInstance
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
MITHgrid.initInstance = (args...) ->
  [namespace, container, config, cb] = MITHgrid.normalizeArgs args...
  that =
    _mithgrid_type: "MITHgrid"
  
  onDestroyFns = []
  that.onDestroy = (cb) ->
    onDestroyFns.push cb
      
  that._destroy = ->
    for cb in onDestroyFns.reverse()
      cb()
    onDestroyFns = []
    for e, obj of that.events
      obj._destroy()
    for k, v of that
      delete that[k]

  optionsArray = [ ]
  if namespace? 
    if typeof namespace == "string"
      namespace = [ namespace ]
    
    that._mithgrid_type = namespace[0]
      
    namespace.reverse()
    for ns in namespace
      bits = ns.split('.')
      ns = bits.shift()
      if MITHgridDefaults[ns]?
        optionsArray.push MITHgridDefaults[ns]
      while bits.length > 0
        ns = ns + "." + bits.shift()
        if MITHgridDefaults[ns]?
          optionsArray.push MITHgridDefaults[ns]
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
      that.events[k] = MITHgrid.initEventFirer( ("preventable" in c), ("unicast" in c), ("memory" in c) )
  
  # ### #addVariable
  #
  # Adds a managed variable to the instance object.
  #
  # Parameters:
  #
  # * varName - the name of the variable
  #
  # * config - object holding configuration options
  #
  # Returns: Nothing.
  #
  # Configuration:
  #
  # * **is** - the mutability of the variable is one of the following:
  #   * 'rw' for read-write
  #   * 'r' for read-only
  #   * 'w' for write-only.
  #
  # * **isa** - the type of the variable is one of the following:
  # * 'numeric' for numeric data
  # * 'text' for non-numeric data
  #
  # * **event** - the name of the event associated with this variable. This event will fire when the value of the variable changes.
  #           This defaults to 'on' + varName + 'Change'.
  #
  # * **setter** - the name of the method that will be used to set the variable. This defaults to 'set' + varName.
  #
  # * **getter** - the name of the method that will be used to retrieve the variable. This defaults to 'get' + varName.
  #
  # * **adder** - the name of the method that will be used to add a numeric value to the current value. This defaults to 'add' + varName and is only available for numeric variables.
  #
  # * **validate** - a function that will be called to validate the value the variable is being set to. This function
  #              should expect the new value and return "true" or "false".
  #
  # * **filter** - a function that will be called to filter the value the variable is being set to. This function
  #            should expect the new value and return the filtered value. If both the filter and validate
  #            options are set, the filter will be run before the validate function.
  #
  that.addVariable = (varName, config) ->
    value = config.default
    config.is or= 'rw'
    if 'w' in config.is
      filter = config.filter
      validate = config.validate
      eventName = config.event || ('on' + varName + 'Change')
      setName = config.setter || ('set' + varName)
      adderName = config.adder || ('add' + varName)
      lockName = config.locker || ('lock' + varName)
      unlockName = config.unlocker || ('unlock' + varName)
      that.events[eventName] = event = MITHgrid.initEventFirer()
      if filter?
        if validate?
          setter = (v) ->
            v = validate filter v
            if value != v
              value = v
              event.fire(value)
        else
          setter = (v) ->
            v = filter v
            if value != v
              value = v
              event.fire(value)
      else
        if validate?
          setter = (v) ->
            v = validate v
            if value != v
              value = v
              event.fire(value)
        else
          setter = (v) ->
            if value != v
              value = v
              event.fire(value)
      if 'l' in config.is 
        locked = 0
        that[lockName] = -> locked += 1
        that[unlockName] = -> locked -= 1
        oldSetter = setter
        setter = (v) ->
          if locked == 0
            oldSetter(v)
      that[setName] = setter

      if config.isa == "numeric"
        that[adderName] = (n) -> setter(n + value)

    if 'r' in config.is
      getName = config.getter || ('get' + varName)
      that[getName] = () -> value
    
  if that.options?.variables?
    for varName, config of options.variables
      that.addVariable varName, config

  # ### viewSetup
  if options?.viewSetup? and container?
    vs = options.viewSetup
    if $.isFunction(vs)
      $(document).ready -> vs $(container)
    else
      $(document).ready -> $(container).append vs
      
  if cb?
    cb that, container
  that

# # Global Behaviors
#
# Sometimes, we need to do things on a global basis without having to create an object for each application, component,
# or plugin.
#
# ## Window Resize Handler
#
# Use MITHgrid.events.onWindowResize.addListener( fn() { } ) to receive notifications when the browser window is resized.
#
MITHgrid.namespace 'events', (events) ->
  events.onWindowResize = MITHgrid.initEventFirer( false, false )
  
  $(document).ready ->
    $(window).resize ->
      setTimeout MITHgrid.events.onWindowResize.fire, 0

# ## Mouse capture
#
# To receive notices of mouse movement and mouse button up events regardless of where they are in the document,
# register appropriate functions.
#
MITHgrid.namespace 'mouse', (mouse) ->
  mouseCaptureCallbacks = []
    
  mouse.capture = (cb) ->
    oldCB = mouseCaptureCallbacks[0]
    mouseCaptureCallbacks.unshift cb
    if mouseCaptureCallbacks.length == 1
      # it was zero before, so no bindings
      $(document).mousemove (e) ->
        e.preventDefault()
        mouseCaptureCallbacks[0].call e, "mousemove"
      $(document).mouseup (e) ->
        e.preventDefault()
        mouseCaptureCallbacks[0].call e, "mouseup"
    oldCB
  
  mouse.uncapture = ->
    oldCB = mouseCaptureCallbacks.shift()
    if mouseCaptureCallbacks.length == 0
      $(document).unbind "mousemove"
      $(document).unbind "mouseup"
    oldCB
