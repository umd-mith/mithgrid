MITHGrid
========

MITHGrid is a JavaScript framework for building browser-based applications composed of a small core and a set of plugins.

What you need to use MITHGrid
-----------------------------

MITHGrid depends on jQuery and Fluid Infusion.  

The following libraries and versions are included in the lib/ directory.  These are the versions with which MITHGrid is developed.

* jQuery 1.6.1
* Fluid Infusion 1.3.1 (which includes the following)
	* jQuery UI 1.8
	* jQuery UI Widget 1.8
	* jQuery UI Mouse 1.8
* Raphaël.js 1.5.2 (for the examples)

What you need to build your own MITHGrid
----------------------------------------

In order to build MITHGrid, you need to have GNU make 3.81 or later, Node.js 0.5 or later, and git 1.7 or later.  Earlier versions might work, but they have not been tested.

Mac OS users should install Xcode, either from the Mac OS install DVD or from the Apple Mac OS App Store.  Node.js can be installed by one of the UNIX package managers available for the Mac OS.

Linux/BSD users should use their appropriate package managers to install make, git, and node.

How to build your own MITHGrid
------------------------------

First, clone a copy of the MITHGrid git repo by running `git clone git://github.com/umd_mith/mithgrid.git`.

Then, to get a complete, minified, jslinted version of MITHGrid, simple `cd` to the `mithgrid` directory and type `make`.  If you don't have Node installed and/or want to make a basic, uncompressed, unlinted version of MITHGrid, use `make mithgrid` instead of `make`.

The built version of MITHGrid will be in the `dist/` subdirectory.

To remove all built files, run `make clean`.

How to test MITHGrid
--------------------

Once you have built MITHGrid, you can browse to the `text/` subdirectory and view the `index.html` file.  This file loads the minified version of MITHGrid by default.