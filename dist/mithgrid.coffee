#
# **MITHgrid** is a data-centric JavaScript library that provides event-driven application building blocks.
# The library is based loosely on the MIT Simile Exhibit library and the Fluid Infusion project.
#

###
# mithgrid JavaScript Library v0.13.3061
#
# Date: Tue Oct 29 12:16:35 2013 -0400
#
# (c) Copyright University of Maryland 2011-2013.  All rights reserved.
#
# (c) Copyright Texas A&M University 2010.  All rights reserved.
#
# Portions of this code are copied from The SIMILE Project:
#  (c) Copyright The SIMILE Project 2006. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# 3. The name of the author may not be used to endorse or promote products
#    derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###

MITHgrid = this.MITHgrid ?= {}
MITHGrid = MITHgrid
mithgrid = MITHgrid
jQuery = this.jQuery ?= {}

(($, MITHgrid) ->
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
  
  # ## MITHgrid.config
  #
  # Various behaviors of MITHgrid can be modified by settings in this object.
  
  MITHgrid.config = {}
  
  # ### MITHgrid.config.noTimeouts
  #
  # If true, setTimeout will not be used unless absolutely necessary. This reduces the number of asynchronous
  # processes and can help applications run better when browsers such as FireFox modify the setTimeout timing.
  
  MITHgrid.config.noTimeouts = false
  
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
          end = n if MITHgrid.config.noTimeouts
          for i in [start ... end]
            cb(items[i])
            that.decrement()
          if end < n
            setTimeout ->
              processItems end
            , 0
        if MITHgrid.config.noTimeouts
          processItems 0
        else
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
        if MITHgrid.config.noTimeouts
          MITHgrid.events.onWindowResize.fire()
        else
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

  #
  # We place most of the data-centric pieces in the MITHgrid.Data namespace.
  #
  MITHgrid.namespace 'Data', (Data) ->
    Data.namespace 'Set', (Set) ->
      # # Data Sets
      #
      # Sets track membership of string item IDs.
      # Sets are basic objects that do not participate in the MITHgrid.initInstance scheme.
      #
      # ## Set.initInstance
      #
      # Initializes a set.
      #
      # Parameters:
      #
      # * values - optional array of values that are initial members of the set
      #
      # Returns:
      #
      # The set object.
      #
      Set.initInstance = (values) ->
        that = {}
        items = {}
        count = 0
        recalc_items = true
        items_list = []
  
        # ### #items
        #
        # Returns a list of item IDs in the set.
        #
        # Parameters: None.
        #
        # Returns:
        #
        # An array of item IDs.
        #
        that.items = () ->
          if recalc_items
            items_list = []
            for i of items
              items_list.push i if typeof(i) == "string" and items[i] == true
          items_list
  
        # ### #add
        #
        # Adds an item ID to the set.
        #
        # Parameters:
        #
        # * item - item ID to be added to the set
        #
        # Returns:
        #
        # Returns nothing.
        #
        that.add = (item) ->
          if !items[item]?
            items[item] = true
            recalc_items = true
            count += 1
  
        # ### #remove
        #
        # Removes the item ID from the set.
        #
        # Parameters:
        #
        # * item - item ID to be removed from the set
        #
        # Returns:
        #
        # Returns nothing.
        #
        that.remove = (item) ->
          if items[item]?
            delete items[item]
            recalc_items = true
            count -= 1
        
        # ### #empty
        #
        # Removes all items from the set.
        #
        # Parameters: None.
        #
        # Returns:
        #
        # Returns nothing.
        #
        that.empty = () ->
          items = {}
          count = 0
          recalc_items = false
          items_list = []
          false
  
        # ### #visit
        #
        # Calls a function with each item ID in the set. This will terminate if the called function returns the
        # "true" value.
        #
        # Parameters:
        #
        # * fn - function taking one argument (the item ID being visited)
        #
        # Returns:
        #
        # Returns nothing.
        #
        that.visit = (fn) ->
          for o of items
            break if fn(o) == true
          false
  
        # ### #contains
        #
        # Returns true if the item ID is in the set.
        #
        # Parameters:
        #
        # * o - item ID to be tested
        #
        # Returns:
        #
        # True or false depending on the presence of the item ID in the set.
        #
        that.contains = (o) ->
          items[o]?
  
        # ### #size
        #
        # Returns the number of item IDs in the set.
        #
        # Parameters: None.
        #
        # Returns:
        #
        # The number of item IDs in the set.
        #
        that.size = () ->
          if recalc_items
            that.items().length
          else
            items_list.length
  
        if values instanceof Array
          that.add i for i in values
  
        that
      
  
    
    # # Data Types
    #
    # This object type is used to encapsulate information about item types. Used within data store objects and parsed
    # expressions.
    #
    Data.namespace 'Type', (Type) ->
      Type.initInstance = (t) ->
        that =
          name: t
          custom: {}
    
    # # Data Properties
    #
    # This object type is used to encapsulate information about item properties. Used within data store objects and
    # parsed expressions.
    #
    Data.namespace 'Property', (Property) ->
      Property.initInstance = (p) ->
        that =
          name: p
          getValueType: () ->
            that.valueType ? 'text'
    
    # # Data Store
    #
    # MITHgrid.Data.Store is a basic triple store that allows updating and deletion of triples.
    # Data stores are usually used as sources for data views.
    # The data store supports export and import of JSON-LD data.
    #
    Data.namespace 'Store', (Store) ->
      # ## Store.initInstance
      #
      # Initializes a data store instance.
      #
      # Parameters:
      #
      # * options - object containing configuration options
      #
      # Returns:
      #
      # The configured data store instance.
      #
      Store.initInstance = (args...) ->
        MITHgrid.initInstance "MITHgrid.Data.Store", args..., (that) -> # we don't use container
          quiesc_events = false
          set = Data.Set.initInstance()
          types = {}
          properties = {}
          spo = {}
          ops = {}
    
          options = that.options
  
          # ### #items (see Set#items)
          that.items = set.items
        
          # ### #contains (see Set#contains)
          that.contains = set.contains
        
          # ### #visit (see Set#visit)
          that.visit = set.visit
        
          # ### #size (see Set#size)
          that.size = set.size
  
          # ### indexPut (private)
          #
          # Puts a triple into an index. This manages reference counting.
          #
          # Parameters:
          #
          # * index - the index to which the triple is added
          # * x, y, z - the triple to insert into the index (s,p,o or o,p,s)
          #
          # Returns: Nothing.
          #
          indexPut = (index, x, y, z) ->
            hash = index[x]
  
            if !hash?
              hash =
                values: {}
                counts: {}
              index[x] = hash
              hash.values[y] = [ z ]
              hash.counts[y] = { }
              hash.counts[y][z] = 1
            else
              values = hash.values
              counts = hash.counts
  
              if !values[y]?
                values[y] = [ z ]
                counts[y] = {}
                counts[y][z] = 1
              else
                values[y].push z
                if counts[y][z]?
                  counts[y][z] += 1
                else
                  counts[y][z] = 1
  
          # ### indexFillSet (private)
          #
          # Parameters:
          #
          # * index
          # * x, y
          # * set
          # * filter
          #
          # Returns: Nothing.
          #
          indexFillSet = (index, x, y, set, filter) ->
            hash = index[x]
  
            if hash?
              array = hash.values[y]
              if array?
                if filter?
                  for z in array
                    set.add z if filter.contains z
                else
                  set.add z for z in array
            false
  
          # ### getUnion (private)
          #
          # Parameters:
          #
          # * index
          # * xSet
          # * y
          # * set
          # * filter
          #
          # Returns:
          #
          # If set is not defined, then a new set is created and returned. Otherwise, the set passed in is returned
          # with the additional items added.
          #
          getUnion = (index, xSet, y, set, filter) ->
            if !set?
              set = Data.Set.initInstance()
  
            xSet.visit (x) -> indexFillSet index, x, y, set, filter
            set
  
          # ### #addProperty
          #
          # Adds metadata about a property.
          #
          # Parameters:
          #
          # * nom - property name
          # * options - object holding metadata about the property
          #
          # Returns:
          #
          # The property object holding the information.
          #
          that.addProperty = (nom, options) ->
            prop = Data.Property.initInstance nom
            if options?.valueType?
              prop.valueType = options.valueType
              properties[nom] = prop
            prop
  
          # ### #getProperty
          #
          # Returns the property object holding the related metadata.
          #
          # Parameters:
          #
          # * nom - property name
          #
          # Returns:
          #
          # Object holding the property metadata.
          #
          that.getProperty = (nom) -> properties[nom] ? Data.Property.initInstance(nom)
  
          # ### #addType
          #
          # Adds metadata about a type.
          #
          # Parameters:
          #
          # * nom - type name
          # * options - object holding metadata about the type
          #
          # Returns:
          #
          # The type object holding the information.
          #
          that.addType = (nom, options) ->
            type = Data.Type.initInstance(nom)
            types[nom] = type
            type
  
          # ### #getType
          #
          # Returns the type object holding the related metadata.
          #
          # Parameters:
          #
          # * nom - type name
          #
          # Returns:
          #
          # Object holding the type metadata.
          #
          that.getType = (nom) -> types[nom] ? Data.Type.initInstance(nom)
  
          # ### #getItem
          #
          # Returns the triples related to an item ID
          #
          # Parameters:
          #
          # * id - item ID
          # * cb - optional callback to receive the item
          #
          # Returns:
          #
          # An object containing the triples related to the item ID. If the item ID is not in the data store, then
          # and empty object is returned.
          #
          that.getItem = (id, cb) -> 
            result = spo[id]?.values ? {}
            if cb
              cb null, result
            else
              result
  
          # ### #getItems
          #
          # Returns an array of objects holding the triples associated with an array of item IDs.
          #
          # Parameters:
          #
          # * ids - array of item IDs
          # * cb - optional callback to receive results
          #
          # Returns:
          #
          # An array of objects containing the triples related to the item IDs.
          # If you provide a callback function, then the results will be passed to the callback
          # one at a time, ending with null.
          #
          # The callback function has the signature (err, doc):
          #
          #     dataStore.getItems([id list...], function(err, item) { ... });
          #
          that.getItems = (ids, cb) ->
            if cb?
              sync = MITHgrid.initSyncronizer cb
              if ids.length?
                for id in ids
                  sync.increment()
                  that.getItem id, (err, res) ->
                    cb err, res
                    sync.decrement()
              else
                sync.increment()
                that.getItem ids, (err, res) ->
                  cb err, res
                  sync.decrement()
              sync.done()
            else
              if ids.length
                (that.getItem id for id in ids)
              else
                [ that.getItem ids ]
          
          # ### #removeItems
          #
          # Removes triples associated with the item IDs.
          #
          # Parameters:
          #
          # * ids - list of item IDs
          # * fn - callback function
          #
          # Returns: Nothing
          #
          # Events:
          #
          # * onModelChange
          #
          that.removeItems = (ids, fn) ->
            id_list = []
      
            # #### indexRemove (private to #removeItems)
            #
            # Removes a triple from an index if the reference count is zero.
            #
            # Parameters:
            #
            # * index
            # * x, y, z
            #
            # Returns: Nothing.
            #
            indexRemove = (index, x, y, z) ->
              hash = index[x]
              return if !hash?
  
              array = hash.values[y];
              counts = hash.counts[y];
  
              return if !array? or !counts?
  
              counts[z] -= 1
              if counts[z] < 1
                i = $.inArray z, array
                if i == 0
                  array = array[1...array.length]
                else if i == array.length - 1
                  array = array[0 ... i]
                else if i > 0
                  array = array[0 ... i].concat array[i + 1 ... array.length]
                if array.length > 0
                  hash.values[y] = array
                else
                  delete hash.values[y]
                delete counts[z]
                # TODO: if counts empty, then we need to bubble up the deletion
                sum = 0
                for k, v of counts
                  sum += v
                if sum == 0
                  delete index[x]
              false
  
            # #### indexRemoveFn (private to #removeItems)
            #
            # Removes the triple from the forward and backward indices.
            #
            # Parameters:
            #
            # * s - subject (item ID)
            # * p - predicate (property)
            # * o - object (value)
            #
            # Returns: Nothing.
            #
            indexRemoveFn = (s, p, o) ->
              indexRemove spo, s, p, o
              indexRemove ops, o, p, s
      
            # #### removeValues (private to #removeItems)
            #
            # Removes the listed values for the property associated with the item ID.
            #
            # Parameters:
            #
            # * id - item ID
            # * p - property name
            # * list - list of values associated with the property
            #
            # Returns: Nothing
            #
            removeValues = (id, p, list) -> indexRemoveFn(id, p, o) for o in list
      
            # #### removeItem (private to #removeItems)
            #
            # Removes the item from the data store.
            #
            # Parameters:
            #
            # * id - item ID
            #
            # Returns: Nothing.
            # 
            removeItem = (id) ->
              entry = that.getItem id
        
              for p, items of entry
                continue if typeof(p) != "string" or p in ["id"]
                removeValues id, p, items
        
              removeValues id, 'id', [ id ]
        
          
            for id in ids
              removeItem id
              id_list.push id
              set.remove id
        
            that.events.onModelChange.fire that, id_list
            if fn?
              fn()
            
          # ### #updateItems
          #
          that.updateItems = (items, fn) ->
            id_list = []
  
            # #### indexRemove (private to #updateItems)
            indexRemove = (index, x, y, z) ->
              hash = index[x]
              return if !hash?
  
              array = hash.values[y]
              counts = hash.counts[y]
  
              return if !array? or !counts?
              # we need to remove the old z values
              counts[z] -= 1
              if counts[z] < 1
                i = $.inArray z, array
                if i == 0
                  array = array[1...array.length]
                else if i == array.length - 1
                  array = array[0 ... i]
                else if i > 0
                  array = array[0 ... i].concat array[i + 1 ... array.length]
                if array.length > 0
                  hash.values[y] = array
                else
                  delete hash.values[y]
                delete counts[z]
            
            # #### indexPutFn (private to #updateItems)
            indexPutFn = (s, p, o) ->
              indexPut spo, s, p, o
              indexPut ops, o, p, s
  
            # #### indexRemoveFn (private to #updateItems)
            indexRemoveFn = (s, p, o) ->
              indexRemove spo, s, p, o
              indexRemove ops, o, p, s
  
            # #### updateItem (private to #updateItems)
            updateItem = (entry) ->
              # we only update things that are different from the old_item
              # we also only update properties that are in the new item
              # if anything is changed, we return true
              # otherwise, we return false
              id = entry.id
              changed = false
  
              itemListIdentical = (to, from) ->
                items_same = true
                return false if to.length != from.length
                for i in [0...to.length]
                  if to[i] != from[i]
                    items_same = false
                items_same
  
              removeValues = (id, p, list) -> indexRemoveFn(id, p, o) for o in list
              putValues = (id, p, list) -> indexPutFn(id, p, o) for o in list
        
              id = id[0] if $.isArray(id)
  
              old_item = that.getItem id
  
              for p, items of entry
                continue if typeof(p) != "string" or p in ["id"]
  
                # if entry[p] and old_item[p] have the same members in the same order, then
                # we do nothing
  
                items = [items] if !$.isArray(items)
                s = items.length;
                if !old_item[p]?
                  putValues id, p, items
                  changed = true
                else if !itemListIdentical items, old_item[p]
                  changed = true
                  removeValues id, p, old_item[p]
                  putValues id, p, items
              changed
  
            that.events.onBeforeUpdating.fire that
  
            n = items.length
            chunk_size = parseInt(n / 100, 10)
            chunk_size = 500 if chunk_size > 500
            chunk_size = 100 if chunk_size < 100
  
            f = (start) ->
              end = start + chunk_size;
              end = n if end > n or MITHgrid.config.noTimeouts
  
              for i in [start ... end]
                entry = items[i]
                if typeof(entry) == "object" and updateItem entry
                  id_list.push entry.id
  
              if end < n
                setTimeout () ->
                  f end
                ,
                0
              else
                that.events.onAfterUpdating.fire that
                that.events.onModelChange.fire that, id_list
                if fn?
                  fn()
            f 0
  
          # ### #loadItems
          that.loadItems = (items, endFn) ->
            id_list = []
  
            # #### indexFn (private to #loadItems)
            indexFn = (s, p, o) ->
              indexPut spo, s, p, o
              indexPut ops, o, p, s
  
            # #### loadItem (private to #loadItems)
            loadItem = (item) ->
              if !item.id?
                throw MITHgrid.error "Item entry has no id: ", item
              if !item.type?
                throw MITHgrid.error "Item entry has no type: ", item
  
              id = item.id
  
              id = id[0] if $.isArray id
  
              set.add id
              id_list.push id
  
              indexFn id, "id", id
        
              for p, v of item
                if typeof(p) != "string"
                  continue
            
                if p not in ["id"]
                  if $.isArray(v)
                    indexFn id, p, vv for vv in v
                  else if v?
                    indexFn id, p, v
            that.events.onBeforeLoading.fire that
      
            n = items.length
            if endFn?
              chunk_size = parseInt(n / 100, 10)
              chunk_size = 500 if chunk_size > 500
            else
              chunk_size = n
            chunk_size = 100 if chunk_size < 100
      
            f = (start) ->
              end = start + chunk_size
              end = n if end > n or MITHgrid.config.noTimeouts
  
              for i in [ start ... end ]
                entry = items[i]
                loadItem entry if typeof(entry) == "object"
  
              if end < n
                setTimeout () ->
                  f(end)
                , 0
              else
                that.events.onAfterLoading.fire that
                that.events.onModelChange.fire that, id_list
                endFn() if endFn?
            f 0
  
          # ### #prepare
          #
          that.prepare = (expressions) ->
            parser = MITHgrid.Expression.Basic.initInstance()
            parsed = (parser.parse(ex) for ex in expressions)
            valueType = undefined
            evaluate: (id) ->
              values = []
              valueType = undefined
              for ex in parsed
                do (ex) ->
                  items = ex.evaluateOnItem id, that
                  valueType or= items.valueType
                  values = values.concat items.values.items()
              values
            valueType: () -> valueType
  
          # ### #getObjectsUnion
          #
          that.getObjectsUnion = (subjects, p, set, filter) -> getUnion spo, subjects, p, set, filter
        
          # ### #getSubjectsUnion
          #
          that.getSubjectsUnion = (objects, p, set, filter) -> getUnion ops, objects,  p, set, filter
  
          # ### #registerPresentation
          #
          that.registerPresentation = (ob) ->
            ob.onDestroy that.events.onModelChange.addListener (m, i) -> ob.eventModelChange m, i
            ob.eventModelChange that, that.items()
  
    # # Data View
    #
    # Provides a filtered view of a data store based on configured filters (e.g., facets). The filtered view can
    # also be constrained based on item types or other simple property value expectations.
    #
    Data.namespace 'View', (View) ->
      # ## View.initInstance
      #
      View.initInstance = (args...) ->
        MITHgrid.initInstance "MITHgrid.Data.View", args..., (that) ->
    
          set = Data.Set.initInstance()
          options = that.options
    
          # ### filterItem (private)
          filterItem = (id) ->
            false != that.events.onFilterItem.fire that.dataStore, id
  
          # ### filterItems (private)
          filterItems = (endFn) ->
            ids = that.dataStore.items()
            n = ids.length
            if n == 0
              endFn()
              return
  
            if n > 200
              chunk_size = parseInt(n / 100, 10)
              chunk_size = 500 if chunk_size > 500
            else
              chunk_size = n
            chunk_size = 100 if chunk_size < 100
  
            f = (start) ->
              end = start + chunk_size
              end = n if end > n or MITHgrid.config.noTimeouts
  
              for i in [ start ... end ]
                id = ids[i]
                if filterItem id
                  set.add id
                else
                  set.remove id
              if end < n
                setTimeout () ->
                  f end
                , 0
              else
                that.items = set.items
                that.size = set.size
                that.contains = set.contains
                that.visit = set.visit
                endFn() if endFn?
            f 0
  
          # ### #registerFilter
          #
          that.registerFilter = (ob) ->
            that.events.onFilterItem.addListener (x, y) -> ob.eventFilterItem x, y
            that.events.onModelChange.addListener (m, i) -> ob.eventModelChange m, i
            ob.events.onFilterChange.addListener that.eventFilterChange
  
          # ### #registerPresentation
          #
          that.registerPresentation = (ob) ->
            ob.onDestroy that.events.onModelChange.addListener (m, i) -> ob.eventModelChange m, i
            filterItems -> ob.eventModelChange that, that.items()
  
        
          # ### #items (see Set#items)
          that.items = set.items
  
          # ### #contains (see Set#contains)
          that.contains = set.contains
  
          # ### #visit (see Set#visit)
          that.visit = set.visit
  
          # ### #size (see Set#size)
          that.size = set.size
    
          that.eventFilterChange = () ->
            current_set = Data.Set.initInstance that.items()
            filterItems () ->
              changed_set = Data.Set.initInstance()
              for i in current_set.items()
                if !that.contains i
                  changed_set.add i
              for i in that.items()
                if !current_set.contains i
                  changed_set.add i
              if changed_set.size() > 0
                that.events.onModelChange.fire that, changed_set.items()
        
          that.eventModelChange = (model, items) ->
            changed_set = Data.Set.initInstance()
        
            for id in items
              if model.contains id
                if filterItem id
                  set.add id
                  changed_set.add id
                else
                  if set.contains id
                    changed_set.add id
                    set.remove id
              else
                changed_set.add id
                set.remove id
  
            that.events.onModelChange.fire that, changed_set.items()
  
          if options?.types?.length > 0
            ((types) ->
              that.registerFilter
                eventFilterItem: (model, id) ->
                  item = model.getItem id
                  return false if !item.type?
                  for t in types
                    return if t in item.type
                  return false
                eventModelChange: (x, y) ->
                events:
                  onFilterChange:
                    addListener: (x) ->
            )(options.types)
  
          if options?.filters?.length > 0
            ((filters) ->
              parser = MITHgrid.Expression.Basic.initInstance()
              parsedFilters = (parser.parse(ex) for ex in filters)
              that.registerFilter
                eventFilterItem: (model, id) ->
                  for ex in parsedFilters
                    values = ex.evaluateOnItem(id, model)
                    values = values.values.items()
                    for v in values
                      return if v != "false"
                  return false
                eventModelChange: (x, y) ->
                events:
                  onFilterChange:
                    addListener: (x) ->
            )(options.filters)
  
          if options?.collection?
            that.registerFilter
              eventFilterItem: options.collection
              eventModelChange: (x, y) ->
              events:
                onFilterChange:
                  addListener: (x) ->
  
          if options?.expressions?
            # We want a way to make our set of items depend on running expressions on the items
            # passed to us from the parent dataView/dataStore.
            # It needs to be quick, similar to the current propagation of changes.
            # **N.B.:** These are not event-based expressions.
            # The expressions must result in itemIds that are contained in the parent dataStore.
            expressions = options.dataStore.prepare(options.expressions)
            prevEventModelChange = that.eventModelChange
            intermediateDataStore = MITHgrid.Data.Store.initInstance({})
            subjectSet = MITHgrid.Data.Set.initInstance()
            that.eventModelChange = (model, items) ->
              itemList = []
              removedItems = []
              intermediateSet = MITHgrid.Data.Set.initInstance()
              intermediateSet = intermediateDataStore.getObjectsUnion subjectSet, "mapsTo", intermediateSet
              for id in items
                if intermediateSet.contains(id)
                  itemList.push id
                  if !model.contains(id)
                    # we need to find everything that maps to id
                    idSet = MITHgrid.Data.Set.initInstance()
                    intermediateDataStore.getSubjectsUnion MITHgrid.Data.Set.initInstance([id]), "mapsTo", idSet
                    idSet.visit (x) ->
                      item = intermediateDataStore.getItem x
                      mapsTo = item.mapsTo
                      if mapsTo?
                        i = mapsTo.indexOf(id)
                        if i == 0
                          mapsTo = mapsTo[1 ... mapsTo.length]
                        else if i == mapsTo.length-1
                          mapsTo = mapsTo[0 ... mapsTo.length-1]
                        else if i > -1
                          mapsTo = mapsTo[0 ... i].concat mapsTo[i+1 ... mapsTo.length]
                        intermediateDataStore.updateItems [
                          id: x
                          mapsTo: mapsTo
                        ]     
                else if model.contains(id)
                  itemSet = MITHgrid.Data.Set.initInstance()
                  for v in expressions.evaluate([id])
                    itemSet.add(v)
                  if intermediateDataStore.contains(id)
                    intermediateDataStore.updateItems [
                      id: id
                      mapsTo: itemSet.items()
                    ]
                  else
                    intermediateDataStore.loadItems [
                      id: id
                      mapsTo: itemSet.items()
                    ]
                else
                  # push onto itemList the items mapped to by this id
                  itemList = itemList.concat(intermediateDataStore.getItem(id).mapsTo)
                  removedItems.push id
  
              if removedItems.length > 0
                intermediateDataStore.removeItems(removedItems)
  
              intermediateSet = MITHgrid.Data.Set.initInstance()
              intermediateDataStore.getObjectsUnion subjectSet, "mapsTo", intermediateSet
              itemList = (item for item in itemList when item in items)
              prevEventModelChange intermediateSet, itemList
  
          that.dataStore = options.dataStore
  
          # ### #getItems (see Data Store #getItems)
          that.getItems = that.dataStore.getItems
        
          # ### #getItem (see Data Store #getItem)
          that.getItem = that.dataStore.getItem
        
          # ### #removeItems (see Data Store #removeItems)
          that.removeItems = that.dataStore.removeItems
        
          # ### #updateItems (see Data Store #updateItems)
          that.updateItems = that.dataStore.updateItems
        
          # ### #loadItems (see Data Store #loadItems)
          that.loadItems = that.dataStore.loadItems
        
          # ### #prepare (see Data Store #prepare)
          that.prepare = that.dataStore.prepare
        
          # ### #addType (see Data Store #addType)
          that.addType = that.dataStore.addType
        
          # ### #getType (see Data Store #getType)
          that.getType = that.dataStore.getType
        
          # ### #addProperty (see Data Store #addProperty)
          that.addProperty = that.dataStore.addProperty
        
          # ### #getProperty (see Data Store #getProperty)
          that.getProperty = that.dataStore.getProperty
        
          # ### #getObjectsUnion (see Data Store #getObjectsUnion)
          that.getObjectsUnion = that.dataStore.getObjectsUnion
        
          # ### #getSubjectsUnion (see Data Store #getSubjectsUnion)
          that.getSubjectsUnion = that.dataStore.getSubjectsUnion
    
          that.dataStore.events.onModelChange.addListener that.eventModelChange
  
          that.eventModelChange that.dataStore, that.dataStore.items()
    
    # # Data Subset View
    #
    Data.namespace 'SubSet', (SubSet) ->
      # ## SubSet.initInstance
      #
      # Given a set of expressions and a key value, the resulting set of items will consist of all items which
      # satisfy the expressions by producing the key value.
      #
      # Note that this is a fragile data view. Expressions that hop through other items may result in inconsistent
      # lists of items.
      #
      SubSet.initInstance = (args...) ->
        MITHgrid.initInstance "MITHgrid.Data.SubSet", args..., (that) ->
          options = that.options
    
          set = Data.Set.initInstance()
  
          # ### #items (see Set#items)
          that.items = set.items
  
          # ### #contains (see Set#contains)
          that.contains = set.contains
  
          # ### #visit (see Set#visit)
          that.visit = set.visit
  
          # ### #size (see Set#size)
          that.size = set.size
    
          # ### #setKey
          #
          that.setKey = (k) ->
            key = k
  
            newItems = Data.Set.initInstance(expressions.evaluate([key]))
            changed = []
            
            set.visit (i) ->
              if !newItems.contains i
                set.remove i
                changed.push i
                
            newItems.visit (i) ->
              if !set.contains i
                set.add i
                changed.push i
  
            if changed.length > 0
              that.events.onModelChange.fire that, changed
  
          expressions = options.dataStore.prepare(options.expressions)
        
          # ### #eventModelChange
          #
          that.eventModelChange = (model, items) ->
            if key?
              newItems = Data.Set.initInstance(expressions.evaluate([key]))
            else
              newItems = Data.Set.initInstance()
        
            changed = []
      
            for i in items
              if set.contains i
                changed.push i
                if !newItems.contains i
                  set.remove i
              else if newItems.contains i
                set.add i
                changed.push i
            if changed.length > 0
              that.events.onModelChange.fire that, changed
          
          that.dataStore = options.dataStore
  
          # these mappings allow a data View to stand in for a data Store
          that.getItems = that.dataStore.getItems
          that.getItem = that.dataStore.getItem
          that.removeItems = that.dataStore.removeItems
          that.fetchData = that.dataStore.fetchData
          that.updateItems = that.dataStore.updateItems
          that.loadItems = that.dataStore.loadItems
          that.prepare = that.dataStore.prepare
          that.addType = that.dataStore.addType
          that.getType = that.dataStore.getType
          that.addProperty = that.dataStore.addProperty
          that.getProperty = that.dataStore.getProperty
          that.getObjectsUnion = that.dataStore.getObjectsUnion
          that.getSubjectsUnion = that.dataStore.getSubjectsUnion
    
          that.dataStore.events.onModelChange.addListener that.eventModelChange
  
          that.eventModelChange that.dataStore, that.dataStore.items()
    
          that.registerPresentation = (ob) ->
            ob.onDestroy that.events.onModelChange.addListener (m, i) -> ob.eventModelChange m, i
            ob.eventModelChange that, that.items()
  
          that.setKey options.key
      
    # # Data List Pager
    #
    # 
    Data.namespace 'ListPager', (ListPager) ->
      ListPager.initInstance = (args...) ->
        MITHgrid.initInstance "MITHgrid.Data.ListPager", args..., (that) ->
          options = that.options
  
          itemList = []
          itemListStart = 0
          itemListStop = -1
          leftKey = undefined
          rightKey = undefined
      
          findItemPosition = (itemId) -> itemList.indexOf itemId
      
          set = Data.Set.initInstance()
  
          that.items = set.items
          that.size = set.size
          that.contains = set.contains
          that.visit = set.visit
  
          that.dataStore = options.dataStore
          # these mappings allow a data pager to stand in for a data Store
          that.getItems = that.dataStore.getItems
          that.getItem = that.dataStore.getItem
          that.removeItems = that.dataStore.removeItems
          that.fetchData = that.dataStore.fetchData
          that.updateItems = that.dataStore.updateItems
          that.loadItems = that.dataStore.loadItems
          that.prepare = that.dataStore.prepare
          that.addType = that.dataStore.addType
          that.getType = that.dataStore.getType
          that.addProperty = that.dataStore.addProperty
          that.getProperty = that.dataStore.getProperty
          that.getObjectsUnion = that.dataStore.getObjectsUnion
          that.getSubjectsUnion = that.dataStore.getSubjectsUnion
    
          that.setList = (idList) ->
            itemList = idList
            changedItems = []
            for id in itemList
              if that.dataStore.contains(id) and !set.contains(id)
                if itemListStart <= itemList.indexOf(id) < itemListStop
                  changedItems.push id
                  set.add id
              else if set.contains(id) and !that.dataStore.contains(id)
                changedItems.push id
                set.remove id
            for id in set.items()
              if !id in itemList or !that.dataStore.contains id
                changedItems.push id
                set.remove id
            if changedItems.length > 0
              that.events.onModelChange.fire that, changedItems
  
          that.eventModelChange = (model, items) ->
            # we're modifying the items we're tracking, possibly expanding or decreasing the set
            changedItems = [] # to propogate on to the next level
            for itemId in items
              if model.contains(itemId)
                key = findItemPosition itemId
                if set.contains(itemId)
                  changedItems.push itemId
                  if !(itemListStart <= key < itemListStop)
                    set.remove itemId
                else
                  if itemListStart <= key < itemListStop
                    set.add itemId
                    changedItems.push itemId
              else
                set.remove itemId
                changedItems.push itemId
  
            if changedItems.length > 0
              that.events.onModelChange.fire that, changedItems
  
          that.setKeyRange = (l, r) ->
            if l < r
              itemListStart = l
              itemListStop = r
            else
              itemListStart = r
              itemListStop = l
      
            oldSet = set
            changedItems = Data.Set.initInstance()
            set = Data.Set.initInstance()
            that.items = set.items
            that.size = set.size
            that.contains = set.contains
            that.visit = set.visit
      
            if itemListStart < itemListStop
              for i in [itemListStart..itemListStop]
                itemId = itemList[i]
                if !oldSet.contains(itemId)
                  changedItems.add itemId
                set.add(itemId)
            oldSet.visit (x) ->
              if !set.contains(x)
                changedItems.add x
            if changedItems.size() > 0
              that.events.onModelChange.fire that, changedItems.items()
  
    
          that.dataStore.registerPresentation that
  
          that.registerPresentation = (ob) ->
            ob.onDestroy that.events.onModelChange.addListener (m, i) -> ob.eventModelChange m, i
            ob.eventModelChange that, that.items()
  
    # # Data Pager
    #
    Data.namespace 'Pager', (Pager) ->
      Pager.initInstance = (args...) ->
        MITHgrid.initInstance "MITHgrid.Data.Pager", args..., (that) ->
          options = that.options
  
          itemList = []
          itemListStart = -1
          itemListStop = -1
          leftKey = undefined
          rightKey = undefined
    
          # returns the first index that has a key greater than or equal to the given key
          findLeftPoint = (key) ->
            if !key?
              return 0
            left = 0
            right = itemList.length - 1
            while left < right
              mid = ~~((left + right) / 2)
      
              if itemList[mid][0] < key
                left = mid + 1
              else if itemList[mid][0] == key
                right = mid
              else
                right = mid - 1
            while itemList[left]? and itemList[left][0] < key
              left += 1
            left
      
          # returns the last index that has a key less than or equal to the given key
          findRightPoint = (key) ->
            if !key?
              return itemList.length - 1
            left = 0
            right = itemList.length - 1
            while left < right
              mid = ~~((left + right) / 2)
              if itemList[mid][0] < key
                left = mid + 1
              else
                right = mid - 1
            while right >= 0 and itemList[right][0] >= key
              right -= 1
            right
      
          findItemPosition = (itemId) ->
            for i in [0 ... itemList.length]
              return i if itemList[i][1] == itemId
            return -1
      
  
          set = Data.Set.initInstance()
    
          that.items = set.items
          that.size = set.size
          that.contains = set.contains
          that.visit = set.visit
    
          that.dataStore = options.dataStore
          # these mappings allow a data pager to stand in for a data Store
          that.getItems = that.dataStore.getItems
          that.getItem = that.dataStore.getItem
          that.removeItems = that.dataStore.removeItems
          that.fetchData = that.dataStore.fetchData
          that.updateItems = that.dataStore.updateItems
          that.loadItems = that.dataStore.loadItems
          that.prepare = that.dataStore.prepare
          that.addType = that.dataStore.addType
          that.getType = that.dataStore.getType
          that.addProperty = that.dataStore.addProperty
          that.getProperty = that.dataStore.getProperty
          that.getObjectsUnion = that.dataStore.getObjectsUnion
          that.getSubjectsUnion = that.dataStore.getSubjectsUnion
    
          expressions = that.prepare(options.expressions)
      
          that.eventModelChange = (model, items) ->
            # we're modifying the items we're tracking, possibly expanding or decreasing the set
            changedItems = [] # to propogate on to the next level
            for itemId in items
              if model.contains(itemId)
                keys = expressions.evaluate(itemId)
                if keys.length > 0
                  if expressions.valueType() == "numeric"
                    key = parseFloat(keys[0])
                  else
                    key = keys[0]
                  if set.contains(itemId)
                    i = findItemPosition itemId
                    if i == -1
                      itemList.push [ key, itemId ]
                    else
                      itemList[i][0] = key
                    changedItems.push itemId
                    if leftKey? and key < leftKey or rightKey? and key >= rightKey
                      set.remove(itemId)
                  else
                    itemList.push [ key, itemId ]
                    if (!leftKey? or key >= leftKey) and (!rightKey? or key < rightKey)
                      set.add(itemId)
                      changedItems.push itemId              
                else
                  if set.contains(itemId)
                    i = findItemPosition itemId
                    if i == 0
                      itemList = itemList[1...itemList.length]
                    else if i == itemList.length-1
                      itemList = itemList[0...itemList.length-1]
                    else if i != -1
                      itemList = itemList[0...i].concat itemList[i+1...itemList.length]
                    set.remove(itemId)
                    changedItems.push itemId
              else
                set.remove itemId
                changedItems.push itemId
            # now sort itemList
            # and redo left and right positions
            # and double check set and changedItems list?
            itemList.sort (a,b) ->
              return -1 if a[0] < b[0]
              return  1 if a[0] > b[0]
              return  0
            itemListStart = findLeftPoint leftKey
            itemListStop  = findRightPoint rightKey
  
            if changedItems.length > 0
              that.events.onModelChange.fire that, changedItems
  
          that.setKeyRange = (l, r) ->
            if l? and r?
              if l < r
                leftKey = l
                rightKey = r
              else
                leftKey = r
                rightKey = l
            else
              leftKey = l
              rightKey = r
        
            
            itemListStart = findLeftPoint leftKey
            itemListStop  = findRightPoint rightKey
  
            changedItems = Data.Set.initInstance()
            oldSet = set
      
            set = Data.Set.initInstance()
            that.items = set.items
            that.size = set.size
            that.contains = set.contains
            that.visit = set.visit
      
            if itemListStart <= itemListStop
              for i in [itemListStart..itemListStop]
                itemId = itemList[i][1]
                if !oldSet.contains(itemId)
                  changedItems.add itemId
                set.add(itemId)
            oldSet.visit (x) ->
              if !set.contains(x)
                changedItems.add x
            if changedItems.size() > 0
              that.events.onModelChange.fire that, changedItems.items()
    
          that.dataStore.registerPresentation that
  
          that.registerPresentation = (ob) ->
            ob.onDestroy that.events.onModelChange.addListener (m, i) -> ob.eventModelChange m, i
            ob.eventModelChange that, that.items()
  
    # # Data Range Pager
    #
    Data.namespace 'RangePager', (RangePager) ->
      RangePager.initInstance = (args...) ->
        MITHgrid.initInstance "MITHgrid.Data.RangePager", args..., (that) ->
          options = that.options
  
          leftPager = Data.Pager.initInstance
            dataStore: options.dataStore
            expressions: options.leftExpressions
          rightPager = Data.Pager.initInstance
            dataStore: options.dataStore
            expressions: options.rightExpressions
    
          set = Data.Set.initInstance()
          that.items = set.items
          that.size = set.size
          that.contains = set.contains
          that.visit = set.visit
    
          that.dataStore = options.dataStore
          # these mappings allow a data pager to stand in for a data Store
          that.getItems = that.dataStore.getItems
          that.getItem = that.dataStore.getItem
          that.removeItems = that.dataStore.removeItems
          that.fetchData = that.dataStore.fetchData
          that.updateItems = that.dataStore.updateItems
          that.loadItems = that.dataStore.loadItems
          that.prepare = that.dataStore.prepare
          that.addType = that.dataStore.addType
          that.getType = that.dataStore.getType
          that.addProperty = that.dataStore.addProperty
          that.getProperty = that.dataStore.getProperty
          that.getObjectsUnion = that.dataStore.getObjectsUnion
          that.getSubjectsUnion = that.dataStore.getSubjectsUnion
      
          that.eventModelChange = (model, itemIds) ->
            changedIds = []
            for id in itemIds
              if leftPager.contains(id) and rightPager.contains(id)
                changedIds.push id
                set.add id
              else if set.contains id
                changedIds.push id
                set.remove id
            that.events.onModelChange.fire that, changedIds 
  
          that.setKeyRange = (l, r) ->
            if l? and r? and l > r
              [l, r] = [r, l]
      
            leftPager.setKeyRange  undefined, r
            rightPager.setKeyRange l, undefined
  
          leftPager.registerPresentation that
          rightPager.registerPresentation that
          
          that.setKeyRange undefined, undefined
          
          that.registerPresentation = (ob) ->
            ob.onDestroy that.events.onModelChange.addListener (m, i) -> ob.eventModelChange m, i
            ob.eventModelChange that, that.items()

  ###
  
  This set of components translates between RDF/JSON and the data store.
  
  ###
    
  
  MITHgrid.Data.namespace 'Importer', (I) ->
    I.namespace 'JSON_LD', (LD) ->
      LD.initInstance = (dataStore, NS, types) ->
        that = {}
        
        # check for JSON-LD library - throw an error if we don't have it loaded
        # jsonld is our JSON-LD normalizer object
        if not window.jsonld?.expand?
          throw "Unable to find JSON-LD expand function"
        
        types ?= {}
        types["http://www.w3.org/1999/02/22-rdf-syntax-ns#type"] = "item"
          
        NS ?=
          "http://www.w3.org/2000/01/rdf-schema#": "rdfs"
          "http://www.w3.org/1999/02/22-rdf-syntax-ns#": "rdf"
          "http://www.w3.org/2003/12/exif/ns#": "exif"
          "http://purl.org/dc/elements/1.1/": "dc"
          "http://purl.org/dc/dcmitype/": "dctypes"
          
        that.import = (jsonIn, cb) ->
          jsonld.expand jsonIn, {
            keepFreeFloatingNodes: true
          }, (err, json) ->
            #console.log json
            if err?
              cb([])
              return
            jsonld.flatten json, null, {
              
            }, (err, json) ->
              items = []
              ids = []
              syncer = MITHGrid.initSynchronizer()
              # we allow for nested documents and lists -- we expand these
              # as needed instead of requiring conversion to RDF/JSON first
              syncer.process json, (predicates) ->
                item =
                  id: predicates['@id']
  
                for p, os of predicates
  
                  values = []
                  if types[p] == "item"
                    for o in os
                      if o["@id"]?
                        v = o["@id"]
                        for ns, prefix of NS
                          if v[0...ns.length] == ns
                            v = prefix + v[ns.length..]
                        values.push v
                  else
                    for o in os
                      if o["@value"]?
                        values.push o["@value"]
                      else if o["@id"]?
                        if o["@id"][0...1] == "(" and o["@id"][-1..] == ")"
                          values.push "_:" + o["@id"][1...-1]
                        else
                          values.push o["@id"]
                  if values.length > 0
                    pname = p
                    for ns, prefix of NS
                      if p[0...ns.length] == ns
                        pname = prefix + p[ns.length..]
                    item[pname] = values
                    if p == "http://www.w3.org/1999/02/22-rdf-syntax-ns#type"
                      item.type = values
                if !item.type? or item.type.length == 0
                  item.type = 'Blank'
                items.push item
                ids.push item.id
              syncer.done ->
                #console.log items
                f = ->
                  for item in items
                    if dataStore.contains(item.id)
                      dataStore.updateItems [ item ]
                    else
                      dataStore.loadItems [ item ]
                  cb(ids) if cb?
                if MITHgrid.config.noTimeouts
                  f()
                else
                  setTimeout f, 0
        that
          
    I.namespace 'RDF_JSON', (RDF) ->
      #
      # ## MITHgrid.Data.Importer.RDF_JSON
      #
      # Manages importing triples from RDF/JSON to a MITHgrid data store.
      #
      # ### initInstance
      #
      # Parameters:
      #
      # * dataStore - the data store into which triples should be imported
      # * NS - mapping of namespaces to prefixes
      # * types - mapping of URIs to MITHgrid data store types
      #
      # #### import
      #
      # Parameters:
      #
      # * json - RDF/JSON to import
      # * cb - optional callback when import is finished
      #
      RDF.initInstance = (dataStore, NS, types) ->
        that = {}
        
        types ?= {}
        types["http://www.w3.org/1999/02/22-rdf-syntax-ns#type"] ?= "item"
          
        NS ?=
          "http://www.w3.org/2000/01/rdf-schema#": "rdfs"
          "http://www.w3.org/1999/02/22-rdf-syntax-ns#": "rdf"
          "http://www.w3.org/2003/12/exif/ns#": "exif"
          "http://purl.org/dc/elements/1.1/": "dc"
          "http://purl.org/dc/dcmitype/": "dctypes"
          
        that.import = (json, cb) ->
          items = []
          ids = []
          syncer = MITHGrid.initSynchronizer()
          subjects = (s for s of json)
          syncer.process subjects, (s) ->
            predicates = json[s]
            item =
              id: s
            for p, os of predicates
              values = []
              if types[p] == "item"
                for o in os
                  if o.type == "uri"
                    v = o.value
                    for ns, prefix of NS
                      if o.value[0...ns.length] == ns
                        v = prefix + o.value.substr(ns.length)
                    values.push v
              else
                for o in os
                  switch o.type
                    when "literal"
                      values.push o.value
                    when "uri", "bnode"
                      if o.value.substr(0,1) == "(" and o.value.subtr(-1) == ")"
                        values.push "_:" + o.value.substr(1,o.value.length-2)
                      else
                        values.push o.value
              if values.length > 0
                pname = p
                for ns, prefix of NS
                  if p.substr(0, ns.length) == ns
                    pname = prefix + p.substr(ns.length)
                item[pname] = values
                if p == "http://www.w3.org/1999/02/22-rdf-syntax-ns#type"
                  item.type = values
            if !item.type? or item.type.length == 0
              item.type = 'Blank'
            items.push item
            ids.push item.id
          syncer.done ->
            f = ->
              for item in items
                if dataStore.contains(item.id)
                  dataStore.updateItems [ item ]
                else
                  dataStore.loadItems [ item ]
              cb(ids) if cb?
            if MITHgrid.config.noTimeouts
              f()
            else
              setTimeout f, 0
        that

  # # Expression Parser
  #
  # Everything here is private except for a few exported objects and functions.
  #
  #
  # ## Expressions
  #
  # Expressions describe a path through the data graph held in a data store.
  #
  # Expressions hop from node to node in one of two directions: forward or backward. Forward goes from an item ID through a property
  # to arrive at a new value. Backward goes from a value through a property to arrive at a new item ID.
  #
  # For example, if we have a data store with items holding information about books, such as the following:
  #
  #     [{
  #        id: "book1",
  #        author: "author1",
  #        title: "A Tale of Two Cities",
  #        pages: 254
  #      }, {
  #        id: "author1",
  #        name: "Charles Dickens"
  #      }]
  #
  # Then .name would return "Charles Dickens" if we started with the item ID "author1". But .author.name would return the same
  # value if we started with the item ID "book1".
  #
  # If we start with "Charles Dickens" (the value), we can find the number of pages in the books with the following expression:
  # !name!author.pages (or <-name<-author->pages using the longer notation).
  #
  # . and -> use a forward index and must have an item ID on the left side
  #
  # ! and <- use a reverse index and will result in an item ID on the right side
  #
  # .foo* means to follow the foo property until you can't any more, returning
  # the ids along the way
  # !foo* means to follow the foo property backward until you can't any more,
  # returning the ids along the way
  # (...)* means to apply the subgraph-traversal as many times as possible
  #
  MITHgrid.namespace "Expression.Basic", (exports) ->
    Expression = {}
    _operators =
      "+":
        argumentType: "number"
        valueType: "number"
        f: (a, b) -> a + b
      "-":
        argumentType: "number"
        valueType: "number"
        f: (a, b) -> a - b
      "*":
        argumentType: "number"
        valueType: "number"
        f: (a, b) -> a * b
      "/":
        argumentType: "number"
        valueType: "number"
        f: (a, b) -> a / b
      "=":
        valueType: "boolean"
        f: (a, b) -> a == b
      "<>":
        valueType: "boolean"
        f: (a, b) -> a != b
      "><":
        valueType: "boolean"
        f: (a, b) -> a != b
      "<":
        valueType: "boolean"
        f: (a, b) -> a < b
      ">":
        valueType: "boolean"
        f: (a, b) -> a > b
      "<=":
        valueType: "boolean"
        f: (a, b) -> a <= b
      ">=":
        valueType: "boolean"
        f: (a, b) -> a >= b
  
    # ## MITHgrid.Expression.Basic.controls
    #
    # Control functions may be defined for use in expressions. See the existing control functions for examples of
    # how to write them.
    #
    # All control functions take the following parameters:
    #
    # * args
    # * roots
    # * rootValueTypes
    # * defaultRootName
    # * database
    #
    # All control functions should return a collection of items (using MITHgrid.Expression.initCollection collections)
    #
    Expression.controls = exports.controls =
      # ### if
      #
      "if":
        f: (args, roots, rootValueTypes, defaultRootName, database) ->
          conditionCollection = args[0].evaluate roots, rootValueTypes, defaultRootName, database
          condition = false
          conditionCollection.forEachValue (v) ->
            if v
              condition = true
              return true
            else
              return undefined
        
          if condition
            args[1].evaluate roots, rootValueTypes, defaultRootName, database
          else
            args[2].evaluate roots, rootValueTypes, defaultRootName, database
      # ### foreach
      #
      "foreach":
        f: (args, roots, rootValueTypes, defaultRootName, database) ->
          collection = args[0].evaluate roots, rootValueTypes, defaultRootName, database
          oldValue = roots.value
          oldValueType = rootValueTypes.value
          results = []
          valueType = "text"
  
          rootValueTypes.value = collection.valueType
  
          collection.forEachValue (element) ->
            roots.value = element
            collection2 = args[1].evaluate roots, rootValueTypes, defaultRootName, database
            valueType = collection2.valueType
  
            collection2.forEachValue (result) ->
              results.push result
  
          roots.value = oldValue
          rootValueTypes.value = oldValueType
  
          Expression.initCollection results, valueType
      "default":
        f: (args, roots, rootValueTypes, defaultRootName, database) ->
          for arg in args
            collection = arg.evaluate roots, rootValueTypes, defaultRootName, database
            if collection.size() > 0
              return collection
          Expression.initCollection [], "text"
  
    Expression.initExpression = (rootNode) ->
      that = {}
  
      that.evaluate = (roots, rootValueTypes, defaultRootName, database) ->
        collection = rootNode.evaluate roots, rootValueTypes, defaultRootName, database
        return {
          values: collection.getSet()
          valueType: collection.valueType
          size: collection.size
        }
      
      that.evaluateOnItem = (itemID, database) ->
        that.evaluate({
          "value": itemID
        }, {
          "value": "item"
        },
        "value",
        database
        )
  
      that.evaluateSingle = (roots, rootValueTypes, defaultRootName, database) ->
        collection = rootNode.evaluate roots, rootValueTypes, defaultRootName, database
        result =
          value: null
          valueType: collection.valueType
  
        collection.forEachValue (v) ->
          result.value = v
          true
  
        result;
  
      that.isPath = rootNode.isPath
  
      if that.isPath
        that.getPath = -> rootNode 
        that.testExists = (roots, rootValueTypes, defaultRootName, database) ->
          rootNode.testExists roots, rootValueTypes, defaultRootName, database
      else
        that.getPath = -> null
        that.testExists = (roots, rootValueTypes, defaultRootName, database) ->
          that.evaluate(roots, rootValueTypes, defaultRootName, database).values.size() > 0
    
      that.evaluateBackward = (value, valueType, filter, database) ->
        rootNode.walkBackward [value], valueType, filter, database
  
      that.walkForward = (values, valueType, database) ->
        rootNode.walkForward values, valueType, database
  
      that.walkBackward = (values, valueType, filter, database) ->
        rootNode.walkBackward values, valueType, filter, database
  
      that
  
    Expression.initCollection = exports.initCollection = (values, valueType) ->
      that =
        valueType: valueType
  
      if values instanceof Array
  
        that.forEachValue = (f) ->
          for v in values
            if f(v) == true
              break;
  
        that.getSet = -> MITHgrid.Data.Set.initInstance values
  
        that.contains = (v) -> v in values
  
        that.size = -> values.length
      else
        that.forEachValue = values.visit
        that.size = values.size
        that.getSet = -> values
        that.contains = values.contains
  
      that.isPath = false;
  
      that
  
    Expression.initConstant = (value, valueType) ->
      that = {}
  
      that.evaluate = (roots, rootValueTypes, defaultRootName, database) -> Expression.initCollection [value], valueType
  
      that.isPath = false;
  
      that
  
    Expression.initOperator = (operator, args) ->
      that = {}
      _operator = operator
      _args = args
  
      that.evaluate = (roots, rootValueTypes, defaultRootName, database) ->
        values = []
        args = []
  
        args.push(a.evaluate roots, rootValueTypes, defaultRootName, database) for a in _args
  
        operator = _operators[_operator]
        f = operator.f
        if  operator.argumentType == "number"
          args[0].forEachValue (v1) ->
            if typeof(v1) != "number"
              v1 = parseFloat v1
  
            args[1].forEachValue (v2) ->
              if typeof(v2) != "number"
                v2 = parseFloat v2
  
              values.push f(v1, v2)
        else
          args[0].forEachValue (v1) ->
            args[1].forEachValue (v2) -> values.push f(v1, v2)
  
        Expression.initCollection values, operator.valueType
  
      that.isPath = false
  
      that
  
    Expression.initFunctionCall = (name, args) ->
      that = {}
      _args = args
  
      that.evaluate = (roots, rootValueTypes, defaultRootName, database) ->
        args = []
  
        args.push(a.evaluate roots, rootValueTypes, defaultRootName, database ) for a in _args
  
        if Expression.functions[name]?.f?
          return Expression.functions[name].f args
        else
          throw new Error "No such function named #{_name}"
  
      that.isPath = false
  
      that
  
    Expression.initControlCall = (name, args) ->
      that = {}
  
      that.evaluate = (roots, rootValueTypes, defaultRootName, database) ->
        Expression.controls[name].f args, roots, rootValueTypes, defaultRootName, database
  
      that.isPath = false
  
      that
  
    Expression.initPath = (property, forward) ->
      that = {}
      _rootName = null
      _segments = []
    
      #
      # If isMultiple == true (.@ or !@ instead of . or !), then we
      # collect all matching values regardless of multiplicity. Otherwise,
      # we only return one instance of each matching value.
      #
      walkForward = (collection, database) ->
        forwardArraySegmentFn = (segment) ->
          a = []
          collection.forEachValue (v) ->
            database.getObjects(v, segment.property).visit (v2) -> a.push v2
          a
  
        backwardArraySegmentFn = (segment) ->
          a = []
          collection.forEachValue (v) ->
            database.getSubjects(v, segment.property).visit (v2) -> a.push v2
          a
  
        for i in [ 0 ... _segments.length ]
          segment = _segments[i]
          if segment.expression?
            if segment.forward
              # simply evaluate the expressions and report the results
              collection = segment.expression.evaluateOnItem(collection.getSet().items(), database)
            else
              # walk backward
          else if segment.isMultiple
            a = []
            if segment.forward
              a = forwardArraySegmentFn segment
              property = database.getProperty segment.property
              valueType = if property? then property.getValueType() else "text"
            else
              a = backwardArraySegmentFn segment
              valueType = "item"
            collection = Expression.initCollection a, valueType
          else
            if segment.forward
              values = database.getObjectsUnion collection.getSet(), segment.property
              property = database.getProperty segment.property
              valueType = if property? then property.getValueType() else "text"
              collection = Expression.initCollection values, valueType
            else
              values = database.getSubjectsUnion collection.getSet(), segment.property
              collection = Expression.initCollection values, "item"
  
        collection
  
      walkBackward = (collection, filter, database) ->
        forwardArraySegmentFn = (segment) ->
          a = []
          collection.forEachValue (v) ->
            database.getSubjects(v, segment.property).visit (v2) ->
              a.push v2 if i > 0 or !filter? or filter.contains v2
          a
  
        backwardArraySegmentFn = (segment) ->
          a = []
          collection.forEachValue (v) ->
            database.getObjects(v, segment.property).visit (v2) ->
              a.push v2 if i > 0 or !filter? or filter.contains v2
          a
  
        if filter instanceof Array
          filter = MITHgrid.Data.Set.initInstance filter
  
        for i in [ _segments.length-1 .. 0 ]
          segment = _segments[i];
          if segment.isMultiple
            a = []
            if segment.forward
              a = forwardArraySegmentFn segment
              property = database.getProperty segment.property
              valueType = if property? then property.getValueType() else "text"
            else
              a = backwardArraySegmentFn segment
              valueType = "item"
            collection = Expression.initCollection a, valueType
          else if segment.forward
            values = database.getSubjectsUnion(collection.getSet(), segment.property, null, if i == 0 then filter else null)
            collection = Expression.initCollection values, "item"
          else
            values = database.getObjectsUnion(collection.getSet(), segment.property, null, if i == 0 then filter else null)
            property = database.getProperty segment.property
            valueType = if property? then property.getValueType() else "text"
            collection = Expression.initCollection values, valueType
  
        collection
  
      if property?
        _segments.push
          property: property
          forward: forward
          isMultiple: false
  
      that.isPath = true
  
      that.setRootName = (rootName) -> _rootName = rootName
  
      that.appendSegment = (property, hopOperator) ->
        _segments.push
          property: property
          forward: hopOperator[0] == "."
          isMultiple: hopOperator.length > 1
  
      that.getSegment = (index) ->
        if index < _segments.length
          segment = _segments[index]
          return {
            property: segment.property
            forward: segment.forward
            isMultiple: segment.isMultiple
          }
        else
          return null
  
      that.appendSubPath = (expression) ->
        _segments.push
          expression: expression
          forward: true
          isMultiple: true
  
      that.getLastSegment = -> that.getSegment _segments.length - 1
  
      that.getSegmentCount = -> _segments.length
  
      that.rangeBackward = (from, to, filter, database) ->
        set = MITHgrid.Data.Set.initInstance()
        valueType = "item"
  
        if _segments.length > 0
          segment = _segments[_segments.length - 1]
          if segment.forward
            database.getSubjectsInRange(segment.property, from, to, false, set, if _segments.length == 1 then filter else null)
          else
            throw new Error "Last path of segment must be forward"
  
          for i in [ _segments.length - 2 .. 0 ]
            segment = _segments[i]
            if segment.forward
              set = database.getSubjectsUnion(set, segment.property, null, if i == 0 then filter else null)
              valueType = "item"
            else
              set = database.getObjectsUnion(set, segment.property, null, if i == 0 then filter else null)
              property = database.getPropertysegment.property
              valueType = if property? then property.getValueType() else "text"
  
        return {
          valueType: valueType
          values: set
          count: set.size()
        }
  
      that.evaluate = (roots, rootValueTypes, defaultRootName, database) ->
        rootName = if _rootName? then _rootName else defaultRootName
        valueType = if rootValueTypes[rootName]? then rootValueTypes[rootName] else "text"
        collection = null
  
        if roots[rootName]?
          root = roots[rootName]
  
          if $.isPlainObject(root) or root instanceof Array
            collection = Expression.initCollection root, valueType
          else
            collection = Expression.initCollection [root], valueType
  
          return walkForward collection, database
        else
          throw new Error "No such variable called " + rootName
  
      that.testExists = (roots, rootValueTypes, defaultRootName, database) ->
        that.evaluate(roots, rootValueTypes, defaultRootName, database).size() > 0
  
      that.evaluateBackward = (value, valueType, filter, database) ->
        collection = Expression.initCollection [value], valueType
        walkBackward collection, filter, database
  
      that.walkForward = (values, valueType, database) ->
        walkForward Expression.initCollection(values, valueType), database
  
      that.walkBackward = (values, valueType, filter, database) ->
        walkBackward Expression.initCollection(values, valueType), filter, database
  
      that
  
    # This allows us to do the following:
    # .foo(.bar.baz)*.bat and follow any number of .bar.baz segments
    # .foo(.bar,.baz)*.bat follows any number of .bar or .baz segments
    Expression.initClosure = (expressions) ->
      that = {}
      that.isPath = false
  
      expressions = [ expressions ] unless $.isArray expressions
  
      that.evaluateOnItem = (roots, database) ->
        finalSet = MITHGrid.Data.Set.initInstance()
        valueType = null
        for ex in expressions
          set = ex.evaluate({ "value": roots }, { "value": "item" }, "value", database)
          set.getSet().visit finalSet.add
          valueType ?= set.valueType
        nextRoots = finalSet.items()
        while nextRoots.length > 0
          nextSet = MITHGrid.Data.Set.initInstance()
          for ex in expressions
            set = ex.evaluate({ "value": nextRoots }, { "value": "item" }, "value", database)
            set.getSet().visit (v) ->
              if !finalSet.contains(v)
                nextSet.add(v)
                finalSet.add(v)
          nextRoots = nextSet.items()
  
        return {
          values: finalSet
          getSet: -> finalSet
          valueType: valueType || "text"
          size: finalSet.size()
        }
      that
  
    Expression.initExpressionSet = (expressions) ->
      that = {}
      that.isPath = false
  
      expressions = [ expressions ] unless $.isArray expressions
  
      that.evaluateOnItem = (root, database) ->
        finaleSet = MITHGrid.Data.Set.initInstance()
        valueType = null
        for ex in expressions
          set = ex.evaluate({ "value": roots }, { "value": "item" }, "value", database)
          set.getSet().visit finalSet.add
          valueType ?= set.valueType
        return {
          values: finalSet
          getSet: -> finalSet
          valueType: valueType || "text"
          size: finalSet.size()
        }
  
    Expression.initParser = exports.initInstance = ->
      that = {}
    
      internalParse = (scanner, several) ->
        token = scanner.token()
        Scanner = Expression.initScanner
      
        next = ->
          scanner.next()
          token = scanner.token()
  
        parseExpressionList = ->
          expressions = [parseExpression()]
          while token? and token.type == Scanner.DELIMITER and token.value == ","
            next()
            expressions.push parseExpression()
          expressions
  
        makePosition = -> if token? then token.start else scanner.index()
  
        parsePath = ->
          path = Expression.initPath()
  
          while token? && !(token.type == Scanner.OPERATOR || token.type == Scanner.DELIMITER && token.value == ')')
            if token.type == Scanner.PATH_OPERATOR
              hopOperator = token.value
              next()
          
              if token? and token.type == Scanner.IDENTIFIER
                path.appendSegment token.value, hopOperator
                next()
              else
                throw new Error "Missing property ID at position " + makePosition()
            else if token.type == Scanner.DELIMITER and token.value == '('
              next()
              expressions = parseExpressionList()
              if token && token.type == Scanner.DELIMITER
                if token.value == ')'
                  next()
                  if token && token.type == Scanner.OPERATOR and token.value == '*'
                    next()
                    path.appendSubPath Expression.initClosure expressions
                  else
                    path.appendSubPath Expression.initExpressionSet expressions
                else
                  throw new Error "Mismatched ')' at position " + makePosition()
              else
                throw new Error "Mismatched ')' at position " + makePosition()
          path
  
        parseSubExpression = ->
          result = null
          args = []
  
          if !token?
            throw new Error "Missing factor at end of expression"
          switch token.type
            when Scanner.OPERATOR
              return result
            when Scanner.NUMBER
              result = Expression.initConstant token.value, "number"
              next()
            when Scanner.STRING
              result = Expression.initConstant(token.value, "text");
              next();
            when Scanner.PATH_OPERATOR then result = parsePath()
            when Scanner.IDENTIFIER
              identifier = token.value
              next()
  
              if Expression.controls[identifier]?
                if token? and token.type == Scanner.DELIMITER and token.value == "("
                  next()
  
                  if token? and token.type == Scanner.DELIMITER and token.value == ")" 
                    args = []
                  else
                    args = parseExpressionList()
                  result = Expression.initControlCall identifier, args
  
                  if token? and token.type == Scanner.DELIMITER and token.value == ")"
                    next()
                  else
                    throw new Error "Missing ) to end " + identifier + " at position " + makePosition()
                else
                  throw new Error "Missing ( to start " + identifier + " at position " + makePosition()
              else
                if token? and token.type == Scanner.DELIMITER and token.value == "("
                  next()
                
                  if token? and token.type == Scanner.DELIMITER and token.value == ")"
                    args = []
                  else
                    args = parseExpressionList()
                  result = Expression.initFunctionCall identifier, args
  
                  if token? and token.type == Scanner.DELIMITER and token.value == ")"
                    next()
                  else
                    throw new Error "Missing ) after function call " + identifier + " at position " + makePosition()
                else
                  result = parsePath()
                  result.setRootName identifier
            when Scanner.DELIMITER
              if token.value == "("
                next()
  
                result = parseExpression()
                if token? and token.type == Scanner.DELIMITER and token.value == ")"
                  next()
                else
                  throw new Error "Missing ) at position " + makePosition()
              else
                throw new Error "Unexpected text " + token.value + " at position " + makePosition()
            else
              throw new Error "Unexpected text " + token.value + " at position " + makePosition()
          result
  
        parseExpression = ->
          expression = parseSubExpression()
          while token?.type == Scanner.OPERATOR && token.value in [ "=", "<", ">", "<>", "<=", ">=" ]
            operator = token.value
            next()
            expression =  Expression.initOperator operator, [ expression, parseSubExpression() ]
          expression
  
        if several
          roots = parseExpressionList()
          expressions = []
          expressions.push Expression.initExpression(r) for r in roots
          return expressions
        else
          return [Expression.initExpression(parseExpression())]
  
      that.parse = (s, startIndex, results) ->
        startIndex ?= 0
        results ?= {}
  
        scanner = Expression.initScanner s, startIndex
        try
          return internalParse(scanner, false)[0]
        finally
          results.index = if scanner.token()? then scanner.token().start else scanner.index()
  
      that
  
    Expression.initScanner = (text, startIndex) ->
      that = {}
      _text = text + " "
      _maxIndex = text.length
      _index = startIndex
      _token = null
  
      isDigit = (c) -> "0123456789".indexOf(c) >= 0
  
      that.token = -> _token
  
      that.index = -> _index
  
      that.next = ->
        _token = null
  
        _index += 1 while _index < _maxIndex and " \t\r\n".indexOf(_text[_index]) >= 0
  
        if _index < _maxIndex
          c1 = _text.charAt _index
          c2 = _text.charAt _index + 1
          c3 = _text.charAt _index + 2
          if ".!".indexOf(c1) >= 0
            if c2 == "@"
              _token =
                type: Expression.initScanner.PATH_OPERATOR
                value: c1 + c2
                start: _index
                end: _index + 2
              _index += 2
            else
              _token =
                type: Expression.initScanner.PATH_OPERATOR
                value: c1
                start: _index
                end: _index + 1
              _index += 1
          else if c1 == "<" and c2 == "-"
            if c3 == "@"
              _token =
                type: Expression.initScanner.PATH_OPERATOR
                value: "!@"
                start: _index
                end: _index + 3
              _index += 3
            else
              _token =
                type: Expression.initScanner.PATH_OPERATOR
                value: "!"
                start: _index
                end: _index + 2
              _index += 2
          else if c1 == "-" and c2 == ">"
            if c3 == "@"
              _token =
                type: Expression.initScanner.PATH_OPERATOR
                value: ".@"
                start: _index
                end: _index + 3
              _index += 3
            else
              _token =
                type: Expression.initScanner.PATH_OPERATOR
                value: "."
                start: _index
                end: _index + 2
              _index += 2
          else if "<>".indexOf(c1) >= 0
            if (c2 == "=") or ("<>".indexOf(c2) >= 0 and c1 != c2)
              _token =
                type: Expression.initScanner.OPERATOR
                value: c1 + c2
                start: _index
                end: _index + 2
              _index += 2
            else
              _token =
                type: Expression.initScanner.OPERATOR
                value: c1
                start: _index
                end: _index + 1
              _index += 1
          else if "+-*/=".indexOf(c1) >= 0
            _token =
              type: Expression.initScanner.OPERATOR
              value: c1
              start: _index
              end: _index + 1
            _index += 1
          else if "()".indexOf(c1) >= 0
            _token =
              type: Expression.initScanner.DELIMITER
              value: c1
              start: _index
              end: _index + 1
            _index += 1
          else if "\"'".indexOf(c1) >= 0
            # quoted strings
            i = _index + 1
            while i < _maxIndex
              break if _text.charAt(i) == c1 and _text.charAt(i - 1) != "\\"
              i += 1
  
            if i < _maxIndex
              _token =
                type: Expression.initScanner.STRING
                value: _text.substring(_index + 1, i).replace(/\\'/g, "'").replace(/\\"/g, '"')
                start: _index
                end: i + 1
              _index = i + 1
            else
              throw new Error "Unterminated string starting at " + String(_index)
          else if isDigit c1
            # number
            i = _index
            i += 1 while i < _maxIndex and isDigit(_text.charAt i)
  
            if i < _maxIndex and _text.charAt(i) == "."
              i += 1
              i += 1 while i < _maxIndex and isDigit(_text.charAt i)
  
            _token =
              type: Expression.initScanner.NUMBER
              value: parseFloat(_text.substring(_index, i))
              start: _index
              end: i
            _index = i;
          else
            # identifier
            i = _index
  
            while i < _maxIndex
              c = _text.charAt i
              break unless "(),.!@ \t".indexOf(c) < 0
              i += 1
  
            _token =
              type: Expression.initScanner.IDENTIFIER
              value: _text.substring(_index, i)
              start: _index
              end: i
            _index = i
  
      that.next()
  
      that
  
    Expression.initScanner.DELIMITER = 0
    Expression.initScanner.NUMBER = 1
    Expression.initScanner.STRING = 2
    Expression.initScanner.IDENTIFIER = 3
    Expression.initScanner.OPERATOR = 4
    Expression.initScanner.PATH_OPERATOR = 5
  
    Expression.functions = { }
    Expression.FunctionUtilities = { }
  
    exports.registerSimpleMappingFunction = (name, f, valueType) ->
      Expression.functions[name] =
        f: (args) ->
          set = MITHgrid.Data.Set.initInstance()
          evalArg = (arg) ->
            arg.forEachValue (v) ->
              v2 = f(v)
              set.add v2 if v2?
  
          evalArg arg for arg in args
  
          Expression.initCollection set, valueType

  # # Presentations
  #
  MITHgrid.namespace 'Presentation', (Presentation) ->
    # ## Presentation.initInstance
    #
    # Initializes a presentation instance.
    #
    # Parameters:
    #
    # * type - 
    #
    # * container -
    #
    # * options -
    #
    Presentation.initInstance = (args...) ->
      MITHgrid.initInstance "MITHgrid.Presentation", args..., (that, container) ->
        activeRenderingId = null        
        renderings = {}
        lenses = that.options.lenses || {}
        options = that.options
          
        $(container).empty()
  
        lensKeyExpression = undefined
        options.lensKey ||= [ '.type' ]
  
        # ### #getLens
        #
        # Finds the lens constructor for the given item ID
        #
        # Parameters:
        #
        # * id - item ID
        #
        # Returns:
        #
        # The lens constructor.
        #
        that.getLens = (id) ->
          if lensKeyExpression?
            keys = lensKeyExpression.evaluate [id]
            key = keys[0]
          if key? and lenses[key]?
            return { render: lenses[key] }
    
        # ### #addLens
        #
        # Adds the renderer for the given key value.
        #
        # Parameters:
        #
        # * key - the key value for which the renderer should be used
        #
        # * lens - a function to render the item
        #
        # Returns: Nothing.
        #
        # A rendering function takes four parameters:
        #
        # * container -
        # * presentation -
        # * model -
        # * id -
        #
        # The rendering function should return an object that can be used to manage the rendering.
        #
        that.addLens = (key, lens) ->
          lenses[key] = lens
          that.selfRender()
      
        # ### #removeLens
        #
        # Removes the renderer for the given key value.
        #
        # Parameters:
        #
        # * key - the key value for which the renderer should be removed
        #
        # Returns: Nothing.
        #
        that.removeLens = (key) ->
          delete lenses[key]
    
        # ### #hasLens
        #
        # Returns true if a renderer exists for the given key value.
        #
        # Parameter:
        #
        # * key -
        #
        # Returns:
        #
        # True or false according to the existance of a renderer for the key value.
        #
        that.hasLens = (key) -> lenses[key]?
    
        # ### #visitRenderings
        #
        # Walks the list of renderings and calls the callback function on each one until the list is exhausted
        # or the callback function returns the "false" value.
        #
        # Parameters:
        #
        # cb - callback function taking two arguments: the item id and its rendering object
        #
        # Returns: Nothing.
        #
        that.visitRenderings = (cb) ->
          for id, r of renderings
            if false == cb(id, r)
              return
  
        # ### #renderingFor
        #
        # Returns the rendering object associated with the item ID if such an object exists.
        #
        # Parameters:
        #
        # * id - the item ID
        #
        # Returns:
        #
        # The rendering object if it exists.
        #
        that.renderingFor = (id) -> renderings[id]
    
        # ### #renderItems
        #
        # Renders the list of items in the model using the available lenses.
        #
        # Parameters:
        #
        # * model - data store or data view providing information for each item
        # * items - list of item IDs
        #
        # Returns: Nothing.
        #
        that.renderItems = (model, items) ->
          if !lensKeyExpression?
            lensKeyExpression = model.prepare options.lensKey
      
          n = items.length
          step = n
          if step > 200
            step = parseInt(Math.sqrt(step), 10) + 1
          step = 1 if step < 1
      
          f = (start) ->
            if start < n
              end = start + step
              end = n if end > n or MITHgrid.config.noTimeouts
  
              for i in [start ... end]
                id = items[i]
                hasItem = model.contains(id) and that.hasLensFor(id)
                if renderings[id]?
                  if !hasItem
                  # item or its lens was removed
                  # we need to remove it from the display
                  # .remove() should not make changes in the model
                    renderings[id].eventUnfocus() if activeRenderingId == id and renderings[id].eventUnfocus?
                    renderings[id].remove() if renderings[id].remove?
                    delete renderings[id]
                  else
                    renderings[id].update model.getItem(id)
                else if hasItem
                  rendering = that.render container, model, id
                  if rendering?
                    renderings[id] = rendering
                    if activeRenderingId == id and rendering.eventFocus?
                      rendering.eventFocus()
  
              setTimeout () -> 
                f(end)
              , 0
            else
              that.finishDisplayUpdate() if that.finishDisplayUpdate?
        
          that.startDisplayUpdate()
          f 0
  
        # ### #render
        #
        # Renders the given item using the appropriate lens.
        #
        # Parameters:
        #
        # c - DOM container into which the item should be rendered
        # m - data store or data view providing information for the item
        # i - the item ID
        #
        # Returns:
        #
        # The rendering object if an appropriate lens is found.
        #
        that.render = (c, m, i) ->
          lens = that.getLens i
          if lens?
            lens.render c, that, m, i
        
        that.hasLensFor = (id) ->
          lens = that.getLens id
          lens?
  
        # ### #eventModelChange
        #
        # By default, a presentation renders items as needed when the underlying data store or data view sees changes in
        # its data.
        that.eventModelChange = that.renderItems
  
        # ### #startDisplayUpdate
        #
        # Called before updating the renderings managed by the presentation.
        #
        that.startDisplayUpdate = () ->
      
        # ### #finishDisplayUpdate
        #
        # Called after updating the renderings managed by the presentation.
        #
        that.finishDisplayUpdate = () ->
  
        # ### #selfRender
        #
        # Renders all of the items in the data view attached to the presentation.
        #
        that.selfRender = () -> 
          that.renderItems that.dataView, that.dataView.items()
      
        # ### #eventFocusChange
        #
        # Changes focus to the rendering for the given item.
        #
        # Parameters:
        #
        # * id - the item ID to which focus should shift
        #
        # Returns: Nothing.
        #
        that.eventFocusChange = (id) ->
          if activeRenderingId?
            rendering = that.renderingFor activeRenderingId
          if activeRenderingId != id
            if rendering? and rendering.eventUnfocus?
              rendering.eventUnfocus()
            if id?
              rendering = that.renderingFor id
              if rendering? and rendering.eventFocus?
                rendering.eventFocus()
            activeRenderingId = id
          activeRenderingId
      
        # ### #getFocusedRendering
        #
        # Returns the rendering that has focus.
        #
        that.getFocusedRendering = () ->
          if activeRenderingId?
            that.renderingFor activeRenderingId
          else
            null
  
        # We do a little housekeeping to tie the presentation to the data view.
        that.dataView = that.options.dataView
        that.dataView.registerPresentation(that)
  
    Presentation.namespace "SimpleText", (SimpleText) ->
      SimpleText.initInstance = (args...) ->
        MITHgrid.Presentation.initInstance "MITHgrid.Presentation.SimpleText", args..., (that, container) ->
  
    # ## Table
    #
    # A table presentation provides a tabular view of the data. Lenses are not used for item types. Instead,
    # the data is presented based on the property type.
    #
    # Options:
    # 
    # * columns: list of columns (in the order to show)
    # * columnLabels
    #
    # **N.B.:** This presentation is a work in progress.
    #
    Presentation.namespace "Table", (Table) ->
      Table.initInstance = (args...) ->
        MITHgrid.Presentation.initInstance "MITHgrid.Presentation.Table", args..., (that, container) ->
          options = that.options
          
          tableEl = $("<table></table>")
          headerEl = $("<tr></tr>")
          tableEl.append(headerEl)
          
          for c in options.columns
            headerEl.append("<th>#{options.columnLabels[c]}</th>")
          
          $(container).append(tableEl)
          
          that.hasLensFor = -> true
          
          stringify_list = (list) ->
            if list?
              list = [].concat list
              if list.length > 1
                lastV = list.pop()
                text = list.join(", ")
                if list.length > 1
                  text = text + ", and " + lastV
                else
                  text = text " and " + lastV
              else
                text = list[0]
            else
              text = ""
            text
          
          that.render = (container, model, id) ->
            columns = {}
            rendering = {}
            el = $("<tr></tr>")
            rendering.el = el
            item = model.getItem id
            #
            # The `isEmpty` variable is a fix for a bug in the data store/view code that allows
            # an id to report as present even when the id has been deleted. 
            #
            isEmpty = true
            for c in options.columns
              cel = $("<td></td>")
              if item[c]?
                cel.text stringify_list item[c]
                isEmpty = false
              
                columns[c] = cel
              el.append(cel)
            if not isEmpty
              tableEl.append(el)
            
              rendering.update = (item) ->
                for c in options.columns
                  if item[c]?
                    columns[c].text stringify_list item[c]
            
              rendering.remove = ->
                el.hide()
                el.remove()
            
              rendering
            else
              el.remove()
              null

  # # Facets
  #
  MITHgrid.namespace 'Facet', (Facet) ->
    # ## Facet.initInstance
    #
    Facet.initInstance = (args...) ->
      MITHgrid.initInstance "MITHgrid.Facet", args..., (that, container) ->
    
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
        Facet.initInstance "MITHgrid.Facet.TextSearch", args..., (that) ->
    
          options = that.options
    
          if options.expressions?
            if !$.isArray(options.expressions)
              options.expressions = [ options.expressions ]
            parser = MITHgrid.Expression.Basic.initInstance()
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
        Facet.initInstance "MITHgrid.Facet.List", args..., (that) ->
    
          options = that.options
    
          that.selections = []
    
          if options.expressions?
            if !$.isArray(options.expressions)
              options.expressions = [ options.expressions ]
            parser = MITHgrid.Expression.Basic.initInstance()
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
        Facet.initInstance "MITHgrid.Facet.Range", args..., (that) ->
    
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

  # # MITHgrid Controllers
  #
  # Controllers translate UI events into MITHgrid events. The goal is to create programs that only need a different set of
  # controllers to allow a different manner of user interaction.
  #
  MITHgrid.namespace 'Controller', (Controller) ->
    # ## Controller
    #
    # Controllers do not have any display component, so they only need a class name and the configuration object.
    # Controller objects use the #bind() method to bind a controller to a UI element. The returned object is used to
    # manage that particular binding.
    #
    # Options:
    #
    # * **bind** - configuration options passed to the binding object constructor
    #
    # * **selectors** - a map of strings to CSS selectors for finding children of a UI element when binding
    #
    Controller.initInstance = (args...) ->
      MITHgrid.initInstance "MITHgrid.Controller", args..., (that) ->
        options = that.options
        options.selectors ?= {}
        options.selectors[''] ?= ''
    
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
        # since this is the only piece of MITHgrid that understands anything about Raphaël. It's reasonable that
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
          MITHgrid.initInstance options.bind, (binding) ->
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
        MITHgrid.Controller.initInstance "MITHgrid.Controller.Raphael", args..., (that) ->
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

  # # Applications
  #
  # ## MITHgrid.Application
  #
  # Initializes an application instance.
  #
  # 
  MITHgrid.namespace 'Application', (Application) ->
    Application.initInstance = (args...) ->   
      MITHgrid.initInstance "MITHgrid.Application", args..., (that, container) ->
        onReady = []
        
        thatFn = -> that
    
        that.presentation = {}
        that.facet = {}
        that.component = {}
        that.dataStore = {}
        that.dataView = {}
        that.controller = {}
    
        options = that.options
        
        that.ready = (fn) -> onReady.push fn
        
        # ### #run
        #
        # Finishes configuring the application by running all queued or pending functions registered through
        # the #ready() method. The #ready() method will be redefined to run functions after the current thread
        # finishes.
        that.run = () ->
          $(document).ready () ->
            that.ready = (fn) -> fn()
            fn() for fn in onReady            
            onReady = []
        
        # ### #addDataStore
        #
        # Adds a data store to the application.
        #
        # Parameters:
        #
        # * storeName - name for the data store
        #
        # * config - object holding configuration options
        #
        # Returns: Nothing.
        #
  
        that.addDataStore = (storeName, config) ->
          #
          # The data store automatically has an "Item" type and the "type" and "id" properties.
          #
          if !that.dataStore[storeName]?
            store = MITHgrid.Data.Store.initInstance()
            that.dataStore[storeName] = store
            store.addType 'Item'
            store.addProperty 'type',
              valueType: 'text'
            store.addProperty 'id',
              valueType: 'text'
          else
            store = that.dataStore[storeName]
  
          # Configuration:
          #
  
          # * **types** - object having the types as keys. Types do not have configurations yet.
          #
          if config?.types?
            store.addType type for type, typeInfo of config.types
  
          # * **properties** - object having the properties as keys. Properties have the following options:
          #    * valueType - the type of value associated with the property. Value types should be one of the following:
          #        * text - plain text strings (default)
          #        * item - the id of an item in the data store
          #        * numeric - an integer or floating point number
          #        * date -
          #        * url -
          if config?.properties?
            store.addProperty prop, propOptions for prop, propOptions of config.properties
    
        # ### #addDataView
        #
        # Adds a data view to the application.
        #
        # Parameters:
        #
        # * viewName - name for the data view
        #
        # * viewConfig - object holding configuration options
        #
        # Returns: Nothing.
        #
        # Configuration:
        #
        # * type - the namespace holding the #initInstance function for the particular data view type for this data view.
        #          Defaults to MITHgrid.Data.View.
        #
        # * dataStore - the name of the already configured data store.
        #
        # See the documentation for the particular data view type for other configuration options.
        #
        that.addDataView = (viewName, viewConfig) ->
          if viewConfig.type? and viewConfig.type.initInstance?
            initFn = viewConfig.type.initInstance
          else
            initFn = MITHgrid.Data.View.initInstance
          viewOptions =
            dataStore: that.dataStore[viewConfig.dataStore] || that.dataView[viewConfig.dataStore]
    
          if !that.dataView[viewName]?
            for k,v of viewConfig
              if k != "type" && !viewOptions[k]
                viewOptions[k] = v
        
            view = initFn viewOptions
            that.dataView[viewName] = view
    
        # ### #addController
        #
        # Adds a controller to the application.
        #
        # Parameters:
        #
        # * cName - name for the controller
        #
        # * cconfig - object holding configuration options
        #
        # Returns: Nothing.
        #
        that.addController = (cName, cconfig) ->
          coptions = $.extend(true, {}, cconfig)
  
          coptions.application = thatFn
          controller = cconfig.type.initInstance coptions
          that.controller[cName] = controller
    
        # ### #addFacet
        #
        # Adds a facet to the application.
        #
        # Parameters:
        #
        # * fName - name of the facet
        #
        # * fconfig - object holding configuration options
        #
        # Returns: Nothing.
        #
        that.addFacet = (fName, fconfig) ->
          foptions = $.extend(true, {}, fconfig)
          that.ready () ->
            fcontainer = $(container).find(fconfig.container)
            fcontainer = fcontainer[0] if $.isArray(fcontainer)
        
            foptions.dataView = that.dataView[fconfig.dataView]
            foptions.application = thatFn
        
            facet = fconfig.type.initInstance fcontainer, foptions
            that.facet[fName] = facet
            facet.selfRender()
    
        # ### #addComponent
        #
        # Adds a component to the application. Components tie together renderings with controllers, but do not base
        # their DOM content on data. Components are good for things like bounding boxes used by a presentation, menus,
        # or other UI elements that might be considered chrome.
        #
        # Parameters:
        #
        # * cName - name of the component
        #
        # * cconfig - object holding configuration options
        #
        # Returns: Nothing.
        #
        that.addComponent = (cName, cconfig) ->
          coptions = $.extend(true, {}, cconfig)
          that.ready () ->
            ccontainer = $(container).find(coptions.container)
            ccontainer = ccontainer[0] if $.isArray(ccontainer)
            coptions.application = thatFn
            if cconfig.components?
              coptions.components = {}
              for ccName, cconfig of cconfig.components
                if typeof cconfig == "string"
                  coptions.components[ccName] = that.component[ccName]
                else
                  ccoptions = $.extend(true, {}, ccconfig)
                  ccoptions.application = thatFn
                  coptions.components[ccName] = cconfig.type.initInstance ccoptions
            if cconfig.controllers?
              coptions.controllers = {}
              for ccName, cconfig of pconfig.controllers
                if typeof cconfig == "string"
                  coptions.controllers[ccName] = that.controller[ccName]
                else
                  ccoptions = $.extend(true, {}, ccconfig)
                  ccoptions.application = thatFn
                  coptions.controllers[ccName] = cconfig.type.initInstance ccoptions
  
            that.component[cName] = cconfig.type.initInstance ccontainer, coptions
          
        # ### #addPresentation
        #
        # Adds a presentation to the application.
        #
        # Parameters:
        #
        # * pName - name of the presentation
        #
        # * pconfig - object holding configuration options
        #
        # Returns: Nothing.
        #
        that.addPresentation = (pName, pconfig) ->
          poptions = $.extend(true, {}, pconfig)
          that.ready () ->
            pcontainer = $(container).find(poptions.container)
            pcontainer = pcontainer[0] if $.isArray(pcontainer)
            poptions.dataView = that.dataView[pconfig.dataView]
            poptions.application = thatFn
            if pconfig.components?
              poptions.components = {}
              for ccName, cconfig of pconfig.components
                if typeof cconfig == "string"
                  poptions.components[ccName] = that.component[ccName]
                else
                  ccoptions = $.extend(true, {}, ccconfig)
                  ccoptions.application = thatFn
                  poptions.components[ccName] = cconfig.type.initInstance ccoptions
            if pconfig.controllers?
              poptions.controllers = {}
              for cName, cconfig of pconfig.controllers
                if typeof cconfig == "string"
                  poptions.controllers[cName] = that.controller[cName]
                else
                  coptions = $.extend(true, {}, cconfig)
                  coptions.application = thatFn
                  poptions.controllers[cName] = cconfig.type.initInstance coptions
      
            presentation = pconfig.type.initInstance pcontainer, poptions
            that.presentation[pName] = presentation
            presentation.selfRender()
        
        # ### #addPlugin
        #
        # Adds a plugin to the application.
        #
        # Parameters:
        #
        # * pconf - object holding configuration options
        #
        # Returns: Nothing.
        #
        that.addPlugin = (pconf) ->
          pconfig = $.extend(true, {}, pconf)
          pconfig.application = thatFn
  
          plugin = pconfig.type.initInstance(pconfig)
          if plugin?
            if pconfig?.dataView?
  
              plugin.dataView = that.dataView[pconfig.dataView]
  
              plugin.dataView.addType type for type, typeInfo of plugin.getTypes()
  
              plugin.dataView.addProperty prop, propOptions for prop, propOptions of plugin.getProperties()
  
            for pname, prconfig of plugin.getPresentations()
              (pname, prconfig) ->
                that.ready ->
                  proptions = $.extend(true, {}, prconfig.options)
                  pcontainer = $(container).find(prconfig.container)
                  pcontainer = pcontainer[0] if $.isArray(pcontainer)
  
                  proptions.lenses = prconfig.lenses if prconfig?.lenses?
                  if prconfig.dataView?
                    proptions.dataView = that.dataView[prconfig.dataView] 
                  else if pconfig.dataView?
                    proptions.dataView = that.dataView[pconfig.dataView]
                  proptions.application = thatFn
                  presentation = prconfig.type.initInstance pcontainer, proptions
                  plugin.presentation[pname] = presentation
                  presentation.selfRender()
    
    
  
        # In addition to the configuration options for generic MITHgrid object instances,
        # the following configuration options are available:
        #
  
        # ### dataStores
        #
        # See the section on #addDataStore.
        #
        if options?.dataStores?
          for storeName, config of options.dataStores
            that.addDataStore storeName, config
  
        # ### dataViews
        #
        # See the section on #addDataView.
        #
        if options?.dataViews?
          for viewName, viewConfig of options.dataViews
            that.addDataView viewName, viewConfig
  
        # ### controllers
        #
        # See the section on #addController.
        #
        if options?.controllers?
          for cName, cconfig of options.controllers
            that.addController cName, cconfig
  
        # ### facets
        #
        # See the section on #addFacet.
        #
        if options?.facets?
          for fName, fconfig of options.facets
            that.addFacet fName, fconfig
        
        # ### components
        #
        # See the section on #addComponent
        #
        if options?.components?
          for cName, cconfig of options.components
            that.addComponent cName, cconfig
          
        # ### presentations
        #
        # See the section on #addPresentation.
        #
        if options?.presentations?
          for pName, pconfig of options.presentations
            that.addPresentation pName, pconfig
  
        # ### plugins
        #
        # See the section on #addPlugin.
        #
        if options?.plugins?
          for pconfig in options.plugins
            that.addPlugin pconfig
  

  # # Plugins
  #
  MITHgrid.namespace "Plugin", (exports) ->
    #
    # This is the base of a plugin, which can package together various things that augment
    # an application.
    #
      #
      #  MITHgrid.Plugin.MyPlugin.initInstance = function(options) {
      #    var that = MITHgrid.Plugin.initInstance('MyPlugin', options, { ... })
      #  };
      #
      #  var myApp = MITHgrid.Application({
      #    plugins: [ { name: 'MyPlugin', ... } ]
      #  });
    #
    
    exports.initInstance = (klass, options) ->
      that = { options: options, presentation: { } }
      readyFns = [ ]
    
      that.getTypes = () ->
        if options?.types?
          options.types
        else
          [ ]
    
      that.getProperties = () ->
        if options?.properties?
          options.properties
        else
          [ ]
          
      that.getComponents = () ->
        if options?.components?
          options.components
        else
          [ ]
    
      that.getPresentations = () ->
        if options?.presentations?
          options.presentations
        else
          [ ]
    
      that.ready = readyFns.push
    
      that.eventReady = (app) ->
        for fn in readyFns
          fn app
        readyFns = []
        that.ready = (fn) ->
          fn app
    
      that


  # Here, we have our deprecated ways of referring to initializers
  # **These aliases will be removed in the first public release.**
  MITHgrid.initView = MITHgrid.deprecated "MITHgrid.initView", MITHgrid.initInstance
  MITHgrid.Data.initSet = MITHgrid.deprecated "MITHgrid.Data.initSet", MITHgrid.Data.Set.initInstance
  MITHgrid.Data.initType = MITHgrid.deprecated "MITHgrid.Data.initType", MITHgrid.Data.Type.initInstance
  MITHgrid.Data.initProperty = MITHgrid.deprecated "MITHgrid.Data.initProperty", MITHgrid.Data.Property.initInstance
  MITHgrid.Data.initStore = MITHgrid.deprecated "MITHgrid.Data.initStore", MITHgrid.Data.Store.initInstance
  MITHgrid.Data.initView = MITHgrid.deprecated "MITHgrid.Data.initView", MITHgrid.Data.View.initInstance
  MITHgrid.Presentation.initPresentation = MITHgrid.deprecated "MITHgrid.Presentation.initPresentation", MITHgrid.Presentation.initInstance
  MITHgrid.Presentation.SimpleText.initPresentation = MITHgrid.deprecated "MITHgrid.Presentation.SimpleText.initPresentation", MITHgrid.Presentation.SimpleText.initInstance
  MITHgrid.Application.initApp = MITHgrid.deprecated "MITHgrid.Application.initApp", MITHgrid.Application.initInstance
  
)(jQuery, MITHgrid)

MITHgrid.defaults "MITHgrid.Data.Store",
    events:
        onModelChange: null
        onBeforeLoading: null
        onAfterLoading: null
        onBeforeUpdating: null
        onAfterUpdating: null

MITHgrid.defaults "MITHgrid.Data.View",
    events:
        onModelChange: null
        onFilterItem: "preventable"

MITHgrid.defaults "MITHgrid.Data.SubSet",
    events:
        onModelChange: null

MITHgrid.defaults "MITHgrid.Data.Pager",
    events:
        onModelChange: null

MITHgrid.defaults "MITHgrid.Data.RangePager",
    events:
        onModelChange: null

MITHgrid.defaults "MITHgrid.Data.ListPager",
    events:
        onModelChange: null

MITHgrid.defaults "MITHgrid.Facet",
  events:
    onFilterChange: null

MITHgrid.defaults "MITHgrid.Facet.TextSearch",
  facetLabel: "Search"
  expressions: [ ".label" ]
