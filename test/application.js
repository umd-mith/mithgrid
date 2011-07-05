$(document).ready(function() {
	module("Application");

	test("Check namespace", function() {
		expect(2);
		ok( MITHGrid.Application !== undefined, "MITHGrid.Application exists" );
		ok( $.isFunction(MITHGrid.Application), "MITHGrid.Application is a function" );
	});
});