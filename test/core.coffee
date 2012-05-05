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
	
	test "Check normalizeArgs", ->
		expect 4
		res = MITHGrid.normalizeArgs "Foo", { bar: true }
		equal res.length, 4, "Right number of things returned"
		res = MITHGrid.normalizeArgs "Foo", "Bar", ".baz", { bar: true }
		equal res.length, 4, "Right number of things returned"
		deepEqual res[0], ["Bar", "Foo"], "Right order of types"
		equal res[1], ".baz", "container in the right place"
		
		
	test "Check instance initialization", ->
		expect 4
		MITHGrid.defaults "Foo.Bar",
			events:
				onHit: null
		
		thing = MITHGrid.initInstance "Foo.Bar"
		
		ok thing?, "thing returned"
		ok thing?.events?, "thing has events"
		ok thing?.events?.onHit?, "thing has onHit event"
		ok thing?.events?.onHit?.fire?, "thing has onHint firer"
	
	test "Check instance initialization with only a container", ->
		expect 1
		
		MITHGrid.initInstance $("body"), (that, container) ->
			ok container?, "container is defined"
			