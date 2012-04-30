---
layout: docs
title: Using MITHgrid with Other Libraries
---
## General

MITHgrid keeps everything in within the MITHgrid namespace. No other "global" objects are created when the
MITHgrid library is loaded. Applications or other libraries that use MITHgrid might use a different namespace,
so check their documentation to see where they put things.

As a general rule, MITHgrid components are generic across applications and will be in the MITHgrid namespace.
Components that are specific to a particular application or library likely will be in that application's or library's
namespace.

Libraries that depend on MITHgrid will not conflict with MITHgrid. 
Any conflicts are bugs in the libraries depending on MITHgrid.

MITHgrid is known to work with the following libraries that are not dependent on MITHgrid:

* jQuery
* Raphaël.js