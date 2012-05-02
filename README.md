MITHgrid
========

MITHgrid is a JavaScript framework for building browser-based applications composed of a small core and a set of plugins.

What you need to use MITHgrid
-----------------------------

MITHgrid depends on jQuery.  

The following libraries and versions are included in the lib/ directory.  These are the versions with which MITHgrid is developed.

* jQuery 1.6.1
* Raphaël.js 1.5.2 (for the examples)

What you need to build your own MITHgrid
----------------------------------------

In order to build MITHgrid, you need to have GNU make 3.81 or later, CoffeeScript 1.1.1 or later, Node.js 0.5 or later, and git 1.7 or later.  Earlier versions might work, but they have not been tested.

Mac OS users should install Xcode, either from the Mac OS install DVD or from the Apple Mac OS App Store.  Node.js can be installed by one of the UNIX package managers available for the Mac OS.

Linux/BSD users should use their appropriate package managers to install make, git, and node.

How to build your own MITHgrid
------------------------------

First, clone a copy of the MITHgrid git repo by running `git clone git://github.com/umd_mith/mithgrid.git`.

Then, to get a complete, minified, jslinted version of MITHgrid, simple `cd` to the `mithgrid` directory and type `make`.  If you don't have Node installed and/or want to make a basic, uncompressed, unlinted version of MITHgrid, use `make mithgrid` instead of `make`.

The built version of MITHgrid will be in the `dist/` subdirectory.

To remove all built files, run `make clean`.

How to test MITHgrid
--------------------

Once you have built MITHgrid, you can browse to the `test/` subdirectory and view the `index.html` file.  This file loads the minified version of MITHgrid by default.

License
-------

MITHgrid is licensed under the [3-clause BSD license](http://opensource.org/licenses/BSD-3-Clause) because large parts of the data management code are based on the SIMILE Exhibit project, which is licensed under the 3-clause BSD license.
