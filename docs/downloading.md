---
layout: docs
title: Downloading MITHgrid
---
# Downloading MITHgrid

* auto-generated TOC:
{:toc}

## About the Code

MITHgrid is written in [CoffeeScript](http://coffeescript.org/) to make it more readable.
Each part of MITHgrid is a separate source file. These files are combined into a single
CoffeeScript file before being compiled into JavaScript.

The compiled MITHgrid libraries are available in two formats:

* Minified, which provides the same functionality in a smaller file size, and
* Unminified, which is good for debugging.

MITHgrid is provided under the [3-clause BSD license](http://opensource.org/licenses/BSD-3-Clause).

## Hosted MITHgrid

You may link to the current version of MITHgrid using the following URL:

* Minified: http://umd-mith.github.com/mithgrid/dist/mithgrid.min.js
* Unminified: http://umd-mith.github.com/mithgrid/dist/mithgrid.js

## Download MITHgrid

We recommend that you download and host MITHgrid for your own use. 
This ensures that the version of MITHgrid you use only changes when you download a new version.

The minified versions are generally the best versions to use on production deployments.

## Build from Git

In order to build MITHgrid, you need to have GNU make 3.81 or later, CoffeeScript 1.1.1 or later, Node.js 0.5 or later, and git 1.7 or later.  Earlier versions might work, but they have not been tested.

Mac OS users should install Xcode, either from the Mac OS install DVD or from the Apple Mac OS App Store.  Node.js can be installed by one of the UNIX package managers available for the Mac OS.

Linux/BSD users should use their appropriate package managers to install make, git, and node.

### How to build your own MITHgrid

First, clone a copy of the MITHgrid git repo by running `git clone git://github.com/umd_mith/mithgrid.git`.

Then, to get a complete, minified, jslinted version of MITHgrid, simple `cd` to the `mithgrid` directory and type `make`.  If you don't have Node installed and/or want to make a basic, uncompressed, unlinted version of MITHgrid, use `make mithgrid` instead of `make`.

The built version of MITHgrid will be in the `dist/` subdirectory.

To remove all built files, run `make clean`.

### How to test MITHgrid

Once you have built MITHgrid, you can browse to the `test/` subdirectory and view the `index.html` file.  This file loads the minified version of MITHgrid by default.