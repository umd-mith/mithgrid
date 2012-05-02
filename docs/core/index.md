---
layout: docs
title: MITHgrid Core
---

* TOC
{:toc}

## Event Management

Generally, event handlers are created when objects are instantiated. However, you can add an event handler to any
object by creating the event handler using the `MITHgrid.initEventFirer` function.

### Creating an Event Manager

`MITHgrid.initEventFirer(isPreventable, isUnicast)`

Parameters:

* isPreventable - true if a listener can prevent further listeners from receiving the event
* isUnicast - true if only one listener receives the event

Returns: the event management object.

### Methods

The following methods are available for any event management object.

#### `#addListener(listener, namespace)`

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

## Synchronization

## That-ism Helpers
