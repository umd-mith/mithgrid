$(document).ready(function() {
	module("Data");

	test("Check namespace", function() {
		expect(3);
		ok( MITHGrid.Data !== undefined, "MITHGrid.Data exists" );
		ok( $.isFunction(MITHGrid.Data.namespace), "MITHGrid.Data.namespace is a function" );
		ok( $.isFunction(MITHGrid.Data.debug), "MITHGrid.Data.debug is a function" );
	});
	
	module("Data.Set");
	
	test("Check set construction", function() {
		var set, list;
		
		expect(5);
		ok( MITHGrid.Data.Set !== undefined, "Set exists" );
		ok( $.isFunction(MITHGrid.Data.Set), "Set is a function" );
		set = MITHGrid.Data.Set(['a', 'bc', 'def', 4]);
		ok( set !== undefined, "set object is not undefined" );
		ok( set.isSet, "set object has .isSet as true" );
		list = set.items();
		equals( 4, list.length, ".items returns right number of values" );

	});

    module("Data.Type");

	test("Check type construction", function() {
		var type;
		
		expect(2);
		ok( MITHGrid.Data.Type !== undefined, "Type exists" );
		ok( $.isFunction(MITHGrid.Data.Type), "Type is a function" );
	});
	
	module("Data.Property");
	
	test("Check property construction", function() {
		var prop;
		
		expect(2);
		ok( MITHGrid.Data.Property !== undefined, "Property exists" );
		ok( $.isFunction(MITHGrid.Data.Property), "Property is a function" );
	});
	
	module("Data.Source");
	
	test("Check data source construction", function() {
		var ds;
		
		expect(2);
		ok( MITHGrid.Data.Source !== undefined, "Data.Source exists" );
		ok( $.isFunction(MITHGrid.Data.Source), "Data.Source is a function" );
	});
	
	module("Data.View");
	
	test("Check data view construction", function() {
		var dv;
		
		expect(2);
		ok( MITHGrid.Data.View !== undefined, "Data.View exists" );
		ok( $.isFunction(MITHGrid.Data.View), "Data.View is a function" );
	});
});