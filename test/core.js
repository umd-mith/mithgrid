$(document).ready(function() {
	test("Check requirements", function() {
		expect(2);
		ok( jQuery, "jQuery" );
		ok( $, "$" );
	});
	
	test("Check core MITHGrid object", function() {
		expect(3);
		ok( MITHGrid !== undefined, "MITHGrid global object is defined" );
		ok( $.isFunction(MITHGrid.debug), "MITHGrid.debug is a function" );
		ok( $.isFunction(MITHGrid.namespace), "MITHGrid.namespace is a function" );
	});
});	