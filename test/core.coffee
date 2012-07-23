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
	
	test "Check instance initialization with no container, multiple options", ->
		expect 2
		MITHGrid.initInstance { foo: "bar", bar: "boo" }, { bar: "baz" }, (that) ->
			options = that.options
			equal options.foo, "bar", "foo == bar"
			equal options.bar, "baz", "bar == baz"
	
	test "Check event firers", ->
		expect 5
		e = MITHGrid.initEventFirer()
		ok !e.isPreventable, "Not preventable"
		ok !e.isUnicase, "Not unicast"
		ok !e.hasMemory, "Doesn't remember past arguments"
		
		foo = null
		
		fooHandler = (n) ->
			start()
			equal n, foo, "event fired"
			fooHandler = (n) ->
				start()
				equal n, foo, "event fired"
			stop()
			foo = "baz"
			e.fire "baz"
		
		e.addListener (n) -> fooHandler n
			
		stop()
		foo = "bar"
		e.fire "bar"
	
	test "Check memory event firers", ->
		expect 5
		e = MITHGrid.initEventFirer(false, false, true)
		ok !e.isPreventable, "Not preventable"
		ok !e.isUnicase, "Not unicast"
		ok e.hasMemory, "Does remember past arguments"
		
		e.fire("foo")
		e.fire("Baz")
		args = []
		stop()
		e.addListener (f) ->
			args.push f
			if args.length > 1
				start()
				equal args.length, 2, "Args right length"
				deepEqual args, ["foo", "Baz"], "Fired in right order"