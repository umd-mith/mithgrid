$(document).ready ->
	test "Check requirements", ->
		expect 2
		ok jQuery?, "jQuery"
		ok $?, "$"
	
	test "Check core MITHGrid object", ->
		expect 3
		ok MITHGrid?, "MITHGrid global object is defined"
		ok $.isFunction(MITHGrid.debug), "MITHGrid.debug is a function"
		ok $.isFunction(MITHGrid.namespace), "MITHGrid.namespace is a function"