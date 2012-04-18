$(document).ready ->
	module "Plugin"

	test "Check namespace", ->
		expect 4
		ok  MITHGrid.Plugin?, "MITHGrid.Plugin exists"
		ok $.isFunction(MITHGrid.Plugin.namespace), "MITHGrid.Plugin.namespace is a function"
		ok $.isFunction(MITHGrid.Plugin.debug), "MITHGrid.Plugin.debug is a function"
		ok $.isFunction(MITHGrid.Plugin.initPlugin), "MITHGrid.Plugin.initPlugin is a function"