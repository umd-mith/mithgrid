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
		equals( list.length, 4, ".items returns right number of values" );
		equals( set.size(), 4, ".size returns the right number of values" );
		
		set.add('foo');
		equals( set.size(), 5, ".add adds a value" );
		
		set.add('foo');
		equals( set.size(), 5, ".add adds a value only if unique" );
		
		set.remove('foo');
		equals( set.size(), 4, ".add removes a value" );
		
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
		equals( typeof type, "object", "Type constructor returns an object" );
		equals( type.name, "Foo", "Type .name returns correct name" );
	});
	
	module("Data.Property");
	
	test("Check property construction", function() {
		var prop;
		
		expect(6);
		ok( MITHGrid.Data.Property !== undefined, "Property exists" );
		ok( $.isFunction(MITHGrid.Data.Property), "Property is a function" );
		
		prop = MITHGrid.Data.Property('foo');
		equals( typeof prop, "object", "Property constructor returns an object" );
		equals( prop.name, "foo", "Property .name returns correct name" );
		equals( prop.getValueType(), "text", "Property .getValueType returns correct default type" );
		
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
			source: "Data.Source.test"
		});
		equals( typeof ds, "object", "Source constructor returns an object" );
		
		ds2 = MITHGrid.Data.Source({
			source: "Data.Source.test"
		});
		equals( ds.id, ds2.id, "Source constructor returns the same object for the same source name" );
		
		ds2 = MITHGrid.Data.Source({
			source: "Data.Source.test2"
		});
		notEqual( ds2.id, ds.id, "Source constructor returns different objects for different source names" );
	});
	
	test("Check data source types and properties", function() {
		var ds;
		
		expect(9);
		ds = MITHGrid.Data.Source({
			source: "Data.Source.test3"
		});
		equals( "object", typeof ds, "Source constructed" );
		
		ds.addType("Item");
		ds.addType("Foo");
		
		notEqual( ds.types.Item, undefined, "Item type is available" );
		notEqual( ds.types.Foo, undefined, "Foo type is available" );
		equals( ds.types.Item.name, "Item", "Item type name is correct" );
		equals( ds.types.Foo.name, "Foo", "Foo type name is correct" );

		ds.addProperty("foo", {
			valueType: "numeric"
		});
		ds.addProperty("bar");
		notEqual(ds.properties.foo, undefined, "foo property is available" );
		notEqual(ds.properties.bar, undefined, "bar property is available" );
		equals(ds.properties.foo.getValueType(), "numeric", "foo is numeric" );
		equals(ds.properties.bar.getValueType(), "text", "bar is numeric" );
	});
	
	test("Check data source data loading", function() {
		var ds, item;
		
		expect(17);
		ds = MITHGrid.Data.Source({
			source: "Data.Source.test4"
		});
		equals(ds.items().length, 0, "Data source begins empty");
		
		// items require an id and a type
		raises(function() {
			ds.loadItems([{
				foo: 'bar',
				bar: 'baz',
				ptr: 'item-2',
				type: 'Item'
			}]);
		}, "Items loaded must have an id");
		
		// we only expect the item that caused the error and subsequent items not to be loaded
		equals(ds.items().length, 0, "Data source is still empty after an error in loading");
		
		raises(function() {
			ds.loadItems([{
				id: 'item-0',
				foo: 'bar',
				bar: 'baz',
				ptr: 'item-2'
			}]);
		}, "Items loaded must have a type");
		
		equals(ds.items().length, 0, "Data source is still empty after an error in loading");
		
		ds.loadItems([{
			id: 'item-0',
			foo: 'bar',
			bar: ['baz', 'bat' ],
			ptr: 'item-2',
			type: "Item"
		}]);
		
		equals(ds.items().length, 1, "One item has been loaded");
		equals(ds.items()[0], 'item-0', "ID is 'item-0'");
		
		ds.addProperty('ptr', {
			valueType: 'item'
		});
		
		item = ds.getItem('item-0');
		
		notEqual(item.id, undefined, "ID is defined");
		notEqual(item.foo, undefined, "foo is defined");
		notEqual(item.bar, undefined, "bar is defined");
		notEqual(item.ptr, undefined, "ptr is defined");
		notEqual(item.type, undefined, "type is defined");
		
		equals(item.id.length, 1, "Only one ID");
		equals(item.foo.length, 1, "One foo");
		equals(item.bar.length, 2, "Two bars");
		equals(item.ptr.length, 1, "One ptr");
		equals(item.type.length, 1, "One type");
		
	});
	
	module("Data.View");
	
	test("Check data view construction", function() {
		var dv;
		
		expect(2);
		ok( MITHGrid.Data.View !== undefined, "Data.View exists" );
		ok( $.isFunction(MITHGrid.Data.View), "Data.View is a function" );
	});
});