$(document).ready ->
	module "Data"

	test "Check namespace", ->
		expect 3
		ok MITHGrid.Data?, "MITHGrid.Data exists"
		ok $.isFunction(MITHGrid.Data.namespace), "MITHGrid.Data.namespace is a function"
		ok $.isFunction(MITHGrid.Data.debug), "MITHGrid.Data.debug is a function"

	module "Data.Set.initInstance"

	test "Check interface", ->		
		expect 6
		set = MITHGrid.Data.Set.initInstance([])
		for prop in ["items", "add", "remove", "visit", "contains", "size"]
			ok $.isFunction(set[prop]), ".#{prop} is a function"

	test "Check set construction", ->
		expect 13
		ok MITHGrid.Data.Set?.initInstance?, "Set exists"
		ok $.isFunction(MITHGrid.Data.Set.initInstance), "Set.initInstance is a function"

		set = MITHGrid.Data.Set.initInstance ['a', 'bc', 'def', 4]
		ok set?, "set object is not undefined"
		equal set.isSet, true, "set object has .isSet as true"

		list = set.items()
		equals list.length, 4, ".items returns right number of values"
		equals set.size(), 4, ".size returns the right number of values"

		set.add 'foo'
		equals set.size(), 5, ".add adds a value"

		set.add 'foo'
		equals set.size(), 5, ".add adds a value only if unique"

		set.remove 'foo'
		equals set.size(), 4, ".add removes a value"

		ok !set.contains('foo'), "confirm 'foo' is no longer in set"
		ok set.contains('def'), "confirm 'def' is in set"

		# 4 and '4' are the same in a set since we're using a JS object behind the scenes
		# since we use sets to contains lists of item ids (implicitely strings), this is okay
		ok set.contains(4), "confirm 4 is in set"
		ok set.contains('4'), "confirm '4' is in set"

	module "Data.initType"

	test "Check type construction", ->
		expect 4
		ok MITHGrid.Data.Type?.initInstance?, "Type exists"
		ok $.isFunction(MITHGrid.Data.Type.initInstance), "Type is a function"

		type = MITHGrid.Data.Type.initInstance 'Foo'
		equals typeof(type), "object", "Type constructor returns an object"
		equals type.name, "Foo", "Type .name returns correct name"

	module "Data.Property.initInstance"

	test "Check property construction", ->
		expect 6
		ok MITHGrid.Data.Property?.initInstance?, "Property.initInstance exists"
		ok $.isFunction(MITHGrid.Data.Property.initInstance), "Property is a function"

		prop = MITHGrid.Data.Property.initInstance 'foo'
		equals typeof(prop), "object", "Property constructor returns an object"
		equals prop.name, "foo", "Property .name returns correct name"
		equals prop.getValueType(), "text", "Property .getValueType returns correct default type"

		prop.valueType = "item"
		equals "item", prop.getValueType(), "Property .getValueType returns correct type"

	module "Data.Store.initInstance"

	test "Check interface", ->
		props = [ "items", "addProperty", "getProperty", "addType", "getType", "getItem", "getItems",
				  "updateItems", "loadItems", "prepare", "getObjectsUnion", "getSubjectsUnion" ]
		
		expect props.length
		ds = MITHGrid.Data.Store.initInstance
			source: "Data.Store.initInstance.interface_test"
		for prop in props
			ok $.isFunction(ds[prop]), ".#{prop} is a function"
	
	test "Check data source construction", ->
		expect 5
		ok MITHGrid.Data.Store.initInstance?, "Data.Store.initInstance exists"
		ok $.isFunction(MITHGrid.Data.Store.initInstance), "Data.Store.initInstance is a function"

		ds = MITHGrid.Data.Store.initInstance
			source: "Data.Store.initInstance.test"

		equals typeof(ds), "object", "Source constructor returns an object"

		ds2 = MITHGrid.Data.Store.initInstance
			source: "Data.Store.initInstance.test"

		notEqual ds.id, ds2.id, "Source constructor returns a different object for the same source name"

		ds2 = MITHGrid.Data.Store.initInstance
			source: "Data.Store.initInstance.test2"

		notEqual ds2.id, ds.id, "Source constructor returns different objects for different source names"

	test "Check data source types and properties", ->
		expect 9
		ds = MITHGrid.Data.Store.initInstance
			source: "Data.Store.initInstance.test3"

		equals typeof(ds), "object", "Source constructed"

		ds.addType "Item"
		ds.addType "Foo"

		t = ds.getType "Item"
		ok t?, "Item type is available"
		equals t.name, "Item", "Item type name is correct"

		t = ds.getType "Foo"
		ok t?, "Foo type is available"
		equals t.name, "Foo", "Foo type name is correct"

		ds.addProperty "foo",
			valueType: "numeric"

		ds.addProperty "bar"

		t = ds.getProperty "foo"
		ok t?, "foo property is available"
		equals t.getValueType(), "numeric", "foo is numeric"

		t = ds.getProperty("bar");
		ok t?, "bar property is available"
		equals t.getValueType(), "text", "bar is text"

	test "Check data source data loading", ->
		expect 22
		ds = MITHGrid.Data.Store.initInstance({})
		equals ds.items().length, 0, "Data source begins empty"

		# items require an id and a type
		raises ->
			ds.loadItems [
				foo: 'bar'
				bar: 'baz'
				ptr: 'item-2'
				type: 'Item'
			]
		, "Items loaded must have an id"

		# we only expect the item that caused the error and subsequent items not to be loaded
		equals ds.items().length, 0, "Data source is still empty after an error in loading"

		raises ->
			ds.loadItems [
				id: 'item-0'
				foo: 'bar'
				bar: 'baz'
				ptr: 'item-2'
			]
		, "Items loaded must have a type"

		equals ds.items().length, 0, "Data source is still empty after an error in loading"

		ds.loadItems [
			id: 'item-0'
			foo: 'bar'
			bar: ['baz', 'bat']
			ptr: 'item-2'
			type: "Item"
		]

		equals ds.items().length, 1, "One item has been loaded"
		equals ds.items()[0], 'item-0', "ID is 'item-0'"

		# test loading multiple items
		ds.loadItems [
			id: "item-1"
			foo: "rab"
			ptr: "item-2"
			type: "Item"
		,
			id: "item-2"
			foo: "rba"
			ptr: "item-0"
			type: "Item"
		]

		equals ds.items().length, 3, "Two more items have been loaded"

		item = ds.getItem 'item-0'
		ok item.id?, "ID is defined"
		ok item.foo?, "foo is defined"
		ok item.bar?, "bar is defined"
		ok item.ptr?, "ptr is defined"
		ok item.type?, "type is defined"

		equals item.id.length, 1, "Only one ID"
		equals item.foo.length, 1, "One foo"
		equals item.bar.length, 2, "Two bars"
		equals item.ptr.length, 1, "One ptr"
		equals item.type.length, 1, "One type"

		deepEqual item,
			id: ["item-0"]
			foo: ["bar"]
			bar: ["baz", "bat"]
			ptr: ["item-2"]
			type: ["Item"]
		, "returned item matches loaded item"

		ds.loadItems [
			id: "item-3"
			foo: "baz"
			type: "Item"
		]

		equals ds.items().length, 4, "Data source has two items now"

		ds.removeItems ["item-3"]

		equals ds.items().length, 3, "One less item now"
		item = ds.getItem 'item-3'
		deepEqual item, {}, "Nothing in the deleted item"

	# we aren't doing extensive tests of expressions until later
	# here, we are only testing that we can move from one item to another
	# using . and !
	test "Check path traversal", ->
		expect 14
		ds = MITHGrid.Data.Store.initInstance
			source: "Data.Store.initInstance.test5"

		equals ds.items().length, 0, "Data source begins empty"

		ds.loadItems [
			id: "item-0"
			foo: "bar"
			ptr: "item-1"
			type: "Item"
		,
			id: "item-1"
			foo: "rab"
			ptr: "item-2"
			type: "Item"
		,
			id: "item-2"
			foo: "rba"
			ptr: "item-0"
			type: "Item"
		]

		equals ds.items().length, 3, "All three items are loaded"

		ds.addProperty "ptr",
			valueType: "item"

		# .ptr should return the item pointed to by item-0's ptr property
		stmt = ds.prepare [".ptr"]
		ok stmt?, ".prepare returns something"
		ok $.isPlainObject(stmt), ".prepare returns a plain object"
		ok $.isFunction(stmt.evaluate), ".prepare returns something with a .evaluate property as a function"

		ids = stmt.evaluate "item-0"
		ok $.isArray(ids), ".evaluate returns an array"
		equals ids.length, 1, "There's a single item"
		equals ids[0], "item-1", "It's the correct item"

		# !ptr should return the item pointing to item-0 through the ptr property
		stmt = ds.prepare ["!ptr"]
		ok stmt?, ".prepare returns something"
		ok $.isPlainObject(stmt), ".prepare returns a plain object"
		ok $.isFunction(stmt.evaluate), ".prepare returns something with a .evaluate property as a function"

		ids = stmt.evaluate "item-0"
		ok $.isArray(ids), ".evaluate returns an array"
		equals ids.length, 1, "There's a single item"
		equals ids[0], "item-2", "It's the correct item"

	module "Data.View.initInstance"

	test "Check interface", ->
		props = [ "items", "addProperty", "getProperty", "addType", "getType", "getItem", "getItems",
				  "updateItems", "loadItems", "prepare", "getObjectsUnion", "getSubjectsUnion" ]
		
		expect props.length
		dv = MITHGrid.Data.View.initInstance
			dataStore: MITHGrid.Data.Store.initInstance()

		for prop in props
			ok $.isFunction(dv[prop]), ".#{prop} is a function"

	test "Check data view construction", ->
		expect 2
		ok MITHGrid.Data.View.initInstance?, "Data.View.initInstance exists"
		ok $.isFunction(MITHGrid.Data.View.initInstance), "Data.View.initInstance is a function"


	module "Data.Pager"
	
	test "Check data pager construction", ->
		expect 2
		ok MITHGrid.Data.Pager.initInstance?, "Data.Pager.initInstance exists"
		ok $.isFunction(MITHGrid.Data.Pager.initInstance), "Data.Pager.initInstance is a function"
	
	test "Check data pager returns something", ->
		expect 2
		try
			dp = MITHGrid.Data.Pager.initInstance
				dataStore: MITHGrid.Data.View.initInstance
					dataStore: MITHGrid.Data.Store.initInstance {}
				expressions: [ '.position' ]
			ok true, "initPager called without throwing an error"
		catch e
			ok false, "initPager called without throwing an error: " + e

		ok dp?, "initPager returns something that isn't undefined"

	test "Check data pager interface", ->
		props = [ "items", "addProperty", "getProperty", "addType", "getType", "getItem", "getItems",
				  "updateItems", "loadItems", "prepare", "getObjectsUnion", "getSubjectsUnion",
				  "eventModelChange", "setKeyRange" ]
		expect props.length
		dp = MITHGrid.Data.Pager.initInstance
			dataStore: MITHGrid.Data.Store.initInstance()
			expressions: [ '.position' ]

		for prop in props
			ok $.isFunction(dp[prop]), ".#{prop} is a function"
	
	test "Check data pager loading and range function", ->
		loadPair = (a,b) ->
			dp.loadItems [
				id: a,
				label: a,
				position: b,
				type: 'Text'
			]
		
		expect 19
		dp = MITHGrid.Data.Pager.initInstance
			dataStore: MITHGrid.Data.View.initInstance
				dataStore: MITHGrid.Data.Store.initInstance()
			expressions: [ '.position' ]

		dp.addProperty "position",
			valueType: "numeric"
		
		dp.setKeyRange 0, 2
		loadPair 'a', -10
		loadPair 'e', 1
		loadPair 'c', -1
		loadPair 'd', 0
		loadPair 'g', 3
		loadPair 'b', -5
		loadPair 'f', 2
		loadPair 'h', 4
		loadPair 'i', 5
		loadPair 'j', 10
		
		ok !dp.contains('c'), "!contains <c,-1>"
		ok dp.contains('d'), "contains <d,0>"
		ok dp.contains('e'), "contains <e,1>"
		ok !dp.contains('f'), "!contains <f,2>"
		ok !dp.contains('g'), "!contains <g,3>"
	
		dp.setKeyRange 0, 3
		ok !dp.contains('c'), "!contains <c,-1>"
		ok dp.contains('d'), "contains <d,0>"
		ok dp.contains('e'), "contains <e,1>"
		ok dp.contains('f'), "contains <f,2>"
		ok !dp.contains('g'), "!contains <g,3>"
		ok !dp.contains('h'), "!contains <h,4>"
		
		dp.setKeyRange -5, 1
		ok !dp.contains('a'), "!contains <a,-10>"
		ok dp.contains('b'), "contains <b,-5>"	
		ok dp.contains('c'), "contains <c,-1>"
		ok dp.contains('d'), "contains <d,0>"
		ok !dp.contains('e'), "!contains <e,1>"
		ok !dp.contains('f'), "!contains <f,2>"
		ok !dp.contains('g'), "!contains <g,3>"
		ok !dp.contains('h'), "!contains <h,4>"
	
	module "Data.RangePager"
	
	test "Check data range pager loading and range function", ->
		loadPair = (a,b,c) ->
			c ?= b*b
			dp.loadItems [
				id: a,
				label: a,
				start: b,
				end: c,
				type: 'Text'
			]
		
		expect 33
		dp = MITHGrid.Data.RangePager.initInstance
			dataStore: MITHGrid.Data.View.initInstance
				dataStore: MITHGrid.Data.Store.initInstance()
			leftExpressions: [ '.start' ]
			rightExpressions: [ '.end' ]

		dp.addProperty "start",
			valueType: "numeric"

		dp.addProperty "end",
			valueType: "numeric"
		
		dp.setKeyRange 0, 2
		loadPair 'a', -10 # -10 .. 100
		loadPair 'e', 1   # 1 .. 1
		loadPair 'c', -1  # -1 .. 1
		loadPair 'd', 0   # 0 .. 0
		loadPair 'g', 3   # 3 .. 9
		loadPair 'b', -5  # -5 .. 25
		loadPair 'f', 2   # 2 .. 4
		loadPair 'h', 4   # 4 .. 16
		loadPair 'i', 5   # 5 .. 25
		loadPair 'j', 10  # 10 .. 100
		equal dp.dataStore.items().length, 10, "Right number of items in dataStore"

		ok dp.contains('c'), "contains <c,-1>"
		ok dp.contains('d'), "contains <d,0>"
		ok dp.contains('e'), "contains <e,1>"
		ok !dp.contains('f'), "!contains <f,2>"
		ok !dp.contains('g'), "!contains <g,3>"
		equal dp.items().length, 5, "Right number of items in dataView for (0,2)"
	
		dp.setKeyRange 0, 3
		ok dp.contains('c'), "!contains <c,-1>"
		ok dp.contains('d'), "contains <d,0>"
		ok dp.contains('e'), "contains <e,1>"
		ok dp.contains('f'), "contains <f,2>"
		ok !dp.contains('g'), "!contains <g,3>"
		ok !dp.contains('h'), "!contains <h,4>"
		equal dp.items().length, 6, "Right number of items in dataView for (0,3)"
		
		dp.setKeyRange -5, 1
		ok dp.contains('a'), "!contains <a,-10>"
		ok dp.contains('b'), "contains <b,-5>"	
		ok dp.contains('c'), "contains <c,-1>"
		ok dp.contains('d'), "contains <d,0>"
		ok !dp.contains('e'), "!contains <e,1>"
		ok !dp.contains('f'), "!contains <f,2>"
		ok !dp.contains('g'), "!contains <g,3>"
		ok !dp.contains('h'), "!contains <h,4>"
		equal dp.items().length, 4, "Right number of items in dataView for (-5,1)"
		
		loadPair 'k', -10, -6
		ok !dp.contains('k'), "!contains <k,-10,-6>"
		equal dp.dataStore.items().length, 11, "Right number of items in dataStore"
		equal dp.items().length, 4, "Right number of items in dataView for (-5,1)"
		
		loadPair 'l', -4 # -4 .. 16
		ok dp.contains('l'), "contains <l,-4>"
		equal dp.dataStore.items().length, 12, "Right number of items in dataStore"
		equal dp.items().length, 5, "Right number of items in dataView for (-5,1)"
		
		loadPair 'm', 1 # 1 .. 1
		ok !dp.contains('m'), "!contains <m, 1>"
		equal dp.dataStore.items().length, 13, "Right number of items in dataStore"
		equal dp.items().length, 5, "Right number of items in dataView for (-5,1)"
		
		dp.setKeyRange 200, 300
		equal dp.items().length, 0, "Nothing in the dataView for (200,300)"
	
	test "Check OAC video annotator behavior", ->
		expect 10
		
		dp = MITHGrid.Data.RangePager.initInstance
			dataStore: MITHGrid.Data.Store.initInstance()
			leftExpressions: [ '.start' ]
			rightExpressions: [ '.end' ]
		
		dp.setKeyRange 0, 5
		equal dp.dataStore.items().length, 0, "No items in data store at beginning of test"
		equal dp.items().length, 0, "No items in data view at beginning of test"
		
		dp.loadItems [
			id: "a"
			type: "Annotation"
			start: 0
			end: 5
		]
		
		equal dp.dataStore.items().length, 1, "One item in data store"
		equal dp.items().length, 1, "One item in data view"
		
		dp.setKeyRange 15, 25
		equal dp.dataStore.items().length, 1, "One item in data store after keyrange change"
		equal dp.items().length, 0, "No items in data view after keyrange change"
		
		dp.setKeyRange 0, 5
		equal dp.dataStore.items().length, 1, "One item in data store after keyrange change"
		equal dp.items().length, 1, "One item in data view after keyrange change"
		
		dp.loadItems [
			id: "b"
			type: "Annotation"
			start: 0
			end: 5
		]
		
		equal dp.dataStore.items().length, 2, "Two items in data store after keyrange change"
		equal dp.items().length, 2, "Two items in data view after keyrange change"
		