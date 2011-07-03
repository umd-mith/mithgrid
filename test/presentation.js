$(document).ready(function() {
	module("Presentation");

	test("Check namespace", function() {
		expect(3);
		ok( MITHGrid.Presentation !== undefined, "MITHGrid.Presentation exists" );
		ok( $.isFunction(MITHGrid.Presentation.namespace), "MITHGrid.Presentation.namespace is a function" );
		ok( $.isFunction(MITHGrid.Presentation.debug), "MITHGrid.Presentation.debug is a function" );
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