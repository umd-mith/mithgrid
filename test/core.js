$(document).ready(function() {
	test("Check core MITHGrid object", function() {
		ok( MITHGrid !== undefined, "MITHGrid global object is defined" );
		ok( $.isFunction(MITHGrid.debug), "MITHGrid.debug is a function" );
		ok( $.isFunction(MITHGrid.namespace), "MITHGrid.namespace is a function" );
	});
});	