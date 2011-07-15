$(document).ready(function() {
	module("Application");

	test("Check namespace", function() {
		expect(2);
		ok( MITHGrid.Application !== undefined, "MITHGrid.Application exists" );
		ok( $.isFunction(MITHGrid.Application.initApp), "MITHGrid.Application.initApp is a function" );
	});
});