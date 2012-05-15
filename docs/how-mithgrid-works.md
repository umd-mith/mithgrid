---
layout: docs
title: How MITHgrid Works
---
# How MITHgrid Works

* auto-generated TOC:
{:toc}

## MITHgrid: The Basics

MITHgrid is a data-centric, event-driven, responsibility-based library. It is designed to ensure
consistent views of the information at the heart of an application.

### Data-centric

MITHgrid expects the core information in an application to reside in a data store. Components may
watch this data store through the use of data views that filter the events based on some criteria.
For example, if you create a game that lets the player have inventory, then the inventory list may
only care about changes to items that impact the player's inventory. A data view would allow the
inventory list to receive only those events that are associated with changes in the player's
inventory.

By holding the information in a central location, any component can be added to the application
without having to hook into various other pieces beyond the standard interface of the data store.
If the new component is properly configurable, then it can work with a wide range of data
schemas.

### Event-driven

MITHgrid is designed to make it easy to tie components together in a way that ensures consistent
views of the same information. Changes in information result in events firing. No component has to
keep an eye on anything as long as they register event handlers in the right places.

### Responsibility-based

Each component type in MITHgrid has its own area of responsibility. Data stores house data.
Data views filter data-related events. Presentations manage renderings of data. Controllers
translate user interface events into MITHgrid events. MITHgrid is designed to minimize the overlap
in responsibilities so you don't have to spend as much time wondering where to put a piece of code.

## That-ism

Instead of the typical prototype-based object creation used in most JavaScript programming, MITHgrid
uses [That-ism](http://fluidproject.org/blog/2008/07/21/about-this-and-that/). As a result, you don't use
the `new` keyword in JavaScript to create a new object instance. Instead, you call the `initInstance` method
of the namespace representing the object type. For example, if you want to create a new
MITHgrid application, you might use the following CoffeeScript code:

{% highlight coffeescript %}
Foo.initInstance = (args...) ->
  MITHgrid.Application.initInstance "Foo", args..., (that, container) ->
      # add methods to the `that` object
{% endhighlight %}

Here, we are creating the initializer for the `Foo` application object type. It inherits from
`MITHgrid.Application` by calling the `initInstance` function in that namespace, passing its own
namespace, `Foo`, as the first argument along with any arguments passed in through its own initializer.
The last argument to the `MITHgrid.Application.initInstance` call is a callback function that accepts
two arguments: the new object instance, and the DOM element that should be used for application content.

By adding methods in the callback function, you don't have to worry about returning the new object at the
end of the instantiation function.

This pattern is a little more complex in JavaScript but still easy to do once you understand the boilerplate:

{% highlight js %}
Foo.initInstance = function() {
  return MITHGrid.Application.initInstance.apply({}, ["Foo"].concat(arguments).concat([function(that, container) {
    // add methods to the `that` object
  }]));
};
{% endhighlight %}

This method of creating objects allows for private data and methods that are tied to the object instance. Instance
methods can also be used as callbacks for event handlers without having to worry about tying the callback to the
proper JavaScript object. 

Objects can expose methods from contained objects without having to create wrapping functions
to switch the `this` object. The data views use this extensively to expose the data manipulation functions from the
underlying data stores.