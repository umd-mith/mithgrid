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
		
		expect(13);
		ok( MITHGrid.Data.Set !== undefined, "Set exists" );
		ok( $.isFunction(MITHGrid.Data.Set), "Set is a function" );
		
		set = MITHGrid.Data.Set(['a', 'bc', 'def', 4]);
		ok( set !== undefined, "set object is not undefined" );
		ok( set.isSet, "set object has .isSet as true" );
		
		list = set.items();
		equals( 4, list.length, ".items returns right number of values" );
		equals( 4, set.size(), ".size returns the right number of values" );
		
		set.add('foo');
		equals( 5, set.size(), ".add adds a value" );
		
		set.add('foo');
		equals( 5, set.size(), ".add adds a value only if unique" );
		
		set.remove('foo');
		equals( 4, set.size(), ".add removes a value" );
		
		ok( !set.contains('foo'), "confirm 'foo' is no longer in set" );
		ok( set.contains('def'), "confirm 'def' is in set" );
		
		// 4 and '4' are the same in a set since we're using a JS object behind the scenes
		// since we use sets to contains lists of item ids (implicitely strings), this is okay
		ok( set.contains(4), "confirm 4 is in set" );
		ok( set.contains('4'), "confirm '4' is in set" );
	});

    module("Data.Type");

	test("Check type construction", function() {
		var type;
		
		expect(4);
		ok( MITHGrid.Data.Type !== undefined, "Type exists" );
		ok( $.isFunction(MITHGrid.Data.Type), "Type is a function" );
		
		type = MITHGrid.Data.Type('Foo');
		equals( "object", typeof type, "Type constructor returns an object" );
		equals( 'Foo', type.name, "Type .name returns correct name" );
	});
	
	module("Data.Property");
	
	test("Check property construction", function() {
		var prop;
		
		expect(6);
		ok( MITHGrid.Data.Property !== undefined, "Property exists" );
		ok( $.isFunction(MITHGrid.Data.Property), "Property is a function" );
		
		prop = MITHGrid.Data.Property('foo');
		equals( "object", typeof prop, "Property constructor returns an object" );
		equals( "foo", prop.name, "Property .name returns correct name" );
		equals( "text", prop.getValueType(), "Property .getValueType returns correct default type" );
		
		prop.valueType = "item";
		equals( "item", prop.getValueType(), "Property .getValueType returns correct type" );
	});
	
	module("Data.Source");
	
	test("Check data source construction", function() {
		var ds, ds2;
		
		expect(5);
		ok( MITHGrid.Data.Source !== undefined, "Data.Source exists" );
		ok( $.isFunction(MITHGrid.Data.Source), "Data.Source is a function" );
		
		ds = MITHGrid.Data.Source({
			source: "test"
		});
		equals( "object", typeof ds, "Source constructor returns an object" );
		
		ds2 = MITHGrid.Data.Source({
			source: "test"
		});
		equals( ds.id, ds2.id, "Source constructor returns the same object for the same source name" );
		
		ds2 = MITHGrid.Data.Source({
			source: "test2"
		});
		notEqual( ds2.id, ds.id, "Source constructor returns different objects for different source names" );
	});
	
	module("Data.View");
	
	test("Check data view construction", function() {
		var dv;
		
		expect(2);
		ok( MITHGrid.Data.View !== undefined, "Data.View exists" );
		ok( $.isFunction(MITHGrid.Data.View), "Data.View is a function" );
	});
});