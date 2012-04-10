$(document).ready ->
	module "Application"

	test "Check namespace", ->
		expect 2
		ok MITHGrid.Application?, "MITHGrid.Application exists"
		ok $.isFunction(MITHGrid.Application.initApp), "MITHGrid.Application.initApp is a function"