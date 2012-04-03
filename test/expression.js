$(document).ready(function() {
	module("Expression");

	test("Check namespace", function() {
		expect(3);
		ok( MITHGrid.Expression !== undefined, "MITHGrid.Expression exists" );
		ok( $.isFunction(MITHGrid.Expression.namespace), "MITHGrid.Expression.namespace is a function" );
		ok( $.isFunction(MITHGrid.Expression.debug), "MITHGrid.Expression.debug is a function" );
	});

	module("Expression.initCollection");
	
	
	test("Check collection constructor", function() {
		var col, list;
		
		expect(2);
		ok( MITHGrid.Expression.initCollection !== undefined, "Collection exists" );
		ok( $.isFunction(MITHGrid.Expression.initCollection), "Collection is a function" );
	});
	
	// make sure we run the same tests for each style of collection construction
	var checkCollection = function(col) {
		var list = [];
		
		ok( col !== undefined, "collection object is not undefined" );
		equals( 4, col.size(), ".size returns right number of values" );
		col.forEachValue(function(x) {
			list.push(x);
			return false;
		});
		equals( 4, list.length, ".forEachValue visits each element");
	};
	
	test("Check collection construction (array)", function() {
		var col, list = [];

		expect(3);
		col = MITHGrid.Expression.initCollection(['a', 'bc', 'def', 4]);
		checkCollection(col);
	});
	
	test("Check collection construction (set)", function() {
		var col, set, list = [];
		
		set = MITHGrid.Data.initSet([ 'a', 'bc', 'def', 4 ]);
		
		expect(3);
		col = MITHGrid.Expression.initCollection(set);
		checkCollection(col);
	});
});