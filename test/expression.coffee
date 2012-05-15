$(document).ready ->
	module "Expression"

	test "Check namespace", ->
		expect 3
		ok MITHGrid.Expression?.Basic?, "MITHGrid.Expression.Basic exists"
		ok $.isFunction(MITHGrid.Expression.Basic.namespace), "MITHGrid.Expression.Basic.namespace is a function"
		ok $.isFunction(MITHGrid.Expression.Basic.debug), "MITHGrid.Expression.Basic.debug is a function"

	module "Expression.Basic.initCollection"
	
	test "Check collection constructor", ->		
		expect 2
		ok MITHGrid.Expression.Basic.initCollection?, "Collection exists"
		ok $.isFunction(MITHGrid.Expression.Basic.initCollection), "initCollection is a function"
	
	# make sure we run the same tests for each style of collection construction
	checkCollection = (col) ->
		list = [];
		
		ok col?, "collection object is not undefined"
		equals 4, col.size(), ".size returns right number of values"
		col.forEachValue (x) ->
			list.push x
			false

		equals 4, list.length, ".forEachValue visits each element"
	
	test "Check collection construction (array)", ->
		list = []

		expect 3
		col = MITHGrid.Expression.Basic.initCollection ['a', 'bc', 'def', 4]
		checkCollection col
	
	test "Check collection construction (set)", ->
		list = []
		
		set = MITHGrid.Data.Set.initInstance [ 'a', 'bc', 'def', 4 ]
		
		expect 3
		col = MITHGrid.Expression.Basic.initCollection set
		checkCollection col