---
layout: docs
title: MITHgrid Core
---
# MITHgrid Core

* auto-gen TOC:
{:toc}

## Event Management

Generally, event handlers are created when objects are instantiated. However, you can add an event handler to any
object by creating the event handler using the `MITHgrid.initEventFirer` function.

### Creating an Event Manager

`MITHgrid.initEventFirer(isPreventable, isUnicast, hasMemory)`

Parameters:

* isPreventable - true if a listener can prevent further listeners from receiving the event
* isUnicast - true if only one listener receives the event
* hasMemory - true if the event manager should keep track of previous values and fire immediately with past values when a new listener is added

Returns: the event management object.

### Methods

The following methods are available for any event management object.

#### `#addListener(listener)`

Adds the given function as a callback that is called when the event is fired. A function is returned that, when called, will remove the listener from the list of callbacks.

#### `#removeListener(listener)`

#### `#fire(args...)`

## Global Behaviors

## Namespace Management

MITHgrid provides some basic namespace management. Any namespace created through these functions will
have the following functions available.

MITHgrid provides two ways to create namespaces: global namespaces and scoped namespaces.
Global namespaces will start with the `window` object, resulting in a possible addition of a global
variable at the top-level of the namespace. Scoped namespaces are namespaces that are added to
existing namespaces. Scoped namespaces do not result in any additional global variables.

### Global Namespaces

`MITHgrid.globalNamespace(name, callback)`

Parameters:

* name - the name of the namespace
* callback - optional callback to be called with the new namespace

Returns: The object corresponding to the namespace.

The namespace name can be a string consisting of names separated by periods (.). For example, the
"foo.bar" namespace would result in a global variable named `foo` with the property `bar` mapping
to an object.

### Scoped Namespaces

`Foo.namespace(name, callback)`

Parameters:

* name - the name of the namespace
* callback - optional callback to be called with the new namespace

Returns: The object corresponding to the namespace.

The namespace name can be a string consisting of names separated by periods (.). For example, the
"baz.bar" namespace would result in the `Foo` global variable having a property `baz` mapping to
an object having a property `bar` mapping to another object (i.e., `Foo.baz.bar` would be the
object returned by the call to the `namespace` function).

### Namespace Static Methods

Each namespace, whether global or scoped, has the following functions defined.

#### `debug(args...)`

This function will map to `console.log` if it is available. Otherwise, it will map to a non-operation.
Use this if you would usually use `console.log` and need to include the debug statements in a
distribution that might run in a browser that doesn't provide `console.log`.

#### `error(args...)`

This function uses `debug()` to output the arguments, but then returns an object with the property
`arguments` mapping to the list of arguments. This is used in the data store when throwing an error
so the error is logged to console and thrown. In the future, this function may do more.

#### `namespace(name, callback)`

This will ensure that the indicated namespace exists under the parent namespace. If a callback
function is provided, then it will be called with the namespace as the only argument. This is
useful for scoping to a given namespace.

## Object Instance Management

MITHgrid object instances are plain JavaScript objects. All of the methods are simple functions that have been added
as properties. These methods have access to the object instance through the JavaScript closure process, so there is no
need to worry about calling the method with the correct instance.

### Creating Object Instances

Creating a new instance is simple:

    newInstance = MyApp.Component.Foo.initInstance(_el_, { _options_ });

When simple instantiating an instance as a user of an object type, you simply need to call the initInstance function in the proper namespace. In the above example, this would be the "MyApp.Component.Foo" namespace.

If you are creating a new object type, then the invocation is a little more complex, but not by much:

    MITHgrid.globalNamespace("MyApp.Component.Foo", function(Foo) {
      Foo.initInstance = function() {
        return MITHgrid.initInstance(["MyApp.Component.Foo"].concat(arguments).concat([function(container, that) {
	      var options = that.options;
          
          that.doSomething = function() {
	        // we have access to the _that_ object
          };
        }]))
      }
    });

This is much simpler in CoffeeScript:

    MITHgrid.globalNamespace "MyApp.Component.Foo", (Foo) ->
      Foo.initInstance = (args...) ->
        MITHgrid.initInstance "MyApp.Component.Foo", args..., (container, that) ->
          options = that.options
          
          that.doSomething = ->
            # we have access to the _that_ object

In either case, MITHgrid sorts out the parameters passed in to initInstance and provides all of the configuration information in the `that.options` object, the DOM element into which the instance can render content, and the instance itself in the call to the object configuration callback provided as the last parameter to the `MITHgrid.initInstance` call.

If your object class inherits from another class, then replace the `MITHgrid.initInstance` call with a call to the appropriate `initInstance` function for the class from which your class inherits. For example, if our Foo component inherits from a Bar component, then we would use the following CoffeeScript:

    MITHgrid.globalNamespace "MyApp", (MyApp) ->
      MyApp.namespace "Component", (Component) ->
        Component.namespace "Bar", (Bar) ->
          # definition of MyApp.Component.Bar
        
        Component.namespace "Foo", (Foo) ->
          Foo.initInstance = (args...) ->
            Component.Bar.initInstance "MyApp.Component.Foo", args..., (container, that) ->
              options = that.options
              that.doSomething = ->
                # we have access to the _that_ object

In general, if you follow the boilerplate above, you'll be well on your way to creating new MITHgrid objects and instances.

### Common Methods

All MITHgrid instances have the following methods.

#### `#_destroy()`

This method calls any callbacks registered to help cleanup memory references. This helps JavaScript's garbage collection by removing references to objects that are no longer needed. This also removes all properties from the object so that any methods can be collected, thus reducing the reference count for the object being `_destroy`ed.

#### `#onDestroy(callback)`

Registers a function to be called when the object is `_destroy`ed. 

A useful pattern when registering event listeners is:

    foo.onDestroy bar.events.onSomething.addListener foo.method

Since the `addListener` method returns a function that can be called to remove the added listener, we can pass this function to the `onDestroy` method so that the listener is removed when the `foo` object is `_destroy`ed.

### Default Configurations

## Synchronization

MITHgrid provides a synchronization facility that helps manage asynchronous processes.

### Creating a Synchronizer

`MITHgrid.initSynchronizer(callback)`

Parameters:

* callback: The optional callback will be called when the synchronizer enters the completed or done state.

### Methods

#### add(n)

Adds _n_, either positive or negative, to the current count. This will not check for completion since the synchronizer expects _n_ to be positive. This is most useful when you know you have a number of items to run through and you don't want to call `increment` for each one.

#### decrement

Subtracts one from the count. If the count reaches zero and `done` has been called and the callback has not been called yet, then the appropriate callback will be called.

#### done(callback)

Notifies the synchronizer that no more calls to `increment`, `add`, or `process` are expected. Once sufficient calls to `decrement` have been made and current `process` calls are finished, the synchronizer will call the provided callback or the callback with which the synchronizer object was initialized.

#### increment

Increases the count by one. This does not check for completion since we don't expect to approach zero from the negative side.

#### process(list, callback)

Calls the _callback_ for each item in the list. Manages the synchronizer count by calling `add` with the number of items and `decrement` after each invocation of the callback. If the list is long, then `setTimeout` will be used to stage the processing so that browser UI events can run.

## That-ism Helpers
