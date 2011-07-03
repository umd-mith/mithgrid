$(document).ready(function() {
	module("Plugin");

	test("Check namespace", function() {
		expect(4);
		ok( MITHGrid.Plugin !== undefined, "MITHGrid.Plugin exists" );
		ok( $.isFunction(MITHGrid.Plugin.namespace), "MITHGrid.Plugin.namespace is a function" );
		ok( $.isFunction(MITHGrid.Plugin.debug), "MITHGrid.Plugin.debug is a function" );
		ok( $.isFunction(MITHGrid.Plugin.initPlugin), "MITHGrid.Plugin.initPlugin is a function" );
	});
/*	
	module("Expression.Collection");
	
	test("Check collection construction", function() {
		var col, list;
		
		ok( MITHGrid.Expression.Collection !== undefined, "Collection exists" );
		ok( $.isFunction(MITHGrid.Expression.Collection), "Collection is a function" );
		col = MITHGrid.Expression.Collection(['a', 'bc', 'def', 4]);
		ok( col !== undefined, "collection object is not undefined" );
		equals( 4, col.size(), ".size returns right number of values" );

	});
	*/
});