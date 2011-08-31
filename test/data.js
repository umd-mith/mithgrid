$(document).ready(function() {
    module("Data");

    test("Check namespace",
    function() {
        expect(3);
        ok(MITHGrid.Data !== undefined, "MITHGrid.Data exists");
        ok($.isFunction(MITHGrid.Data.namespace), "MITHGrid.Data.namespace is a function");
        ok($.isFunction(MITHGrid.Data.debug), "MITHGrid.Data.debug is a function");
    });

    module("Data.initSet");

	test("Check interface",
	function() {
		var set;
		
		expect(6);
		set = MITHGrid.Data.initSet([]);
		$.each(["items", "add", "remove", "visit", "contains", "size"], function(idx, prop) {
			ok($.isFunction(set[prop]), "."+prop+" is a function");
		});
	});

    test("Check set construction",
    function() {
        var set,
        list;

        expect(13);
        ok(MITHGrid.Data.initSet !== undefined, "Set exists");
        ok($.isFunction(MITHGrid.Data.initSet), "Set is a function");

        set = MITHGrid.Data.initSet(['a', 'bc', 'def', 4]);
        ok(set !== undefined, "set object is not undefined");
        ok(set.isSet, "set object has .isSet as true");

        list = set.items();
        equals(list.length, 4, ".items returns right number of values");
        equals(set.size(), 4, ".size returns the right number of values");

        set.add('foo');
        equals(set.size(), 5, ".add adds a value");

        set.add('foo');
        equals(set.size(), 5, ".add adds a value only if unique");

        set.remove('foo');
        equals(set.size(), 4, ".add removes a value");

        ok(!set.contains('foo'), "confirm 'foo' is no longer in set");
        ok(set.contains('def'), "confirm 'def' is in set");

        // 4 and '4' are the same in a set since we're using a JS object behind the scenes
        // since we use sets to contains lists of item ids (implicitely strings), this is okay
        ok(set.contains(4), "confirm 4 is in set");
        ok(set.contains('4'), "confirm '4' is in set");
    });

    module("Data.initType");

    test("Check type construction",
    function() {
        var type;

        expect(4);
        ok(MITHGrid.Data.initType !== undefined, "Type exists");
        ok($.isFunction(MITHGrid.Data.initType), "Type is a function");

        type = MITHGrid.Data.initType('Foo');
        equals(typeof type, "object", "Type constructor returns an object");
        equals(type.name, "Foo", "Type .name returns correct name");
    });

    module("Data.initProperty");

    test("Check property construction",
    function() {
        var prop;

        expect(6);
        ok(MITHGrid.Data.initProperty !== undefined, "Property exists");
        ok($.isFunction(MITHGrid.Data.initProperty), "Property is a function");

        prop = MITHGrid.Data.initProperty('foo');
        equals(typeof prop, "object", "Property constructor returns an object");
        equals(prop.name, "foo", "Property .name returns correct name");
        equals(prop.getValueType(), "text", "Property .getValueType returns correct default type");

        prop.valueType = "item";
        equals("item", prop.getValueType(), "Property .getValueType returns correct type");
    });

    module("Data.initStore");

	test("Check interface",
	function() {
		var ds,
		props = [ "items", "addProperty", "getProperty", "addType", "getType", "getItem", "getItems",
		          "fetchData", "updateItems", "loadItems", "prepare", "getObjectsUnion", "getSubjectsUnion" ];
		
		expect(props.length);
		ds = MITHGrid.Data.initStore({
			source: "Data.initStore.interface_test"
		});
		$.each(props, function(idx, prop) {
			ok($.isFunction(ds[prop]), "."+prop+" is a function");
		});
	});
	
    test("Check data source construction",
    function() {
        var ds,
        ds2;

        expect(5);
        ok(MITHGrid.Data.initStore !== undefined, "Data.initStore exists");
        ok($.isFunction(MITHGrid.Data.initStore), "Data.initStore is a function");

        ds = MITHGrid.Data.initStore({
            source: "Data.initStore.test"
        });
        equals(typeof ds, "object", "Source constructor returns an object");

        ds2 = MITHGrid.Data.initStore({
            source: "Data.initStore.test"
        });
        equals(ds.id, ds2.id, "Source constructor returns the same object for the same source name");

        ds2 = MITHGrid.Data.initStore({
            source: "Data.initStore.test2"
        });
        notEqual(ds2.id, ds.id, "Source constructor returns different objects for different source names");
    });

    test("Check data source types and properties",
    function() {
        var ds, t;

        expect(9);
        ds = MITHGrid.Data.initStore({
            source: "Data.initStore.test3"
        });
        equals("object", typeof ds, "Source constructed");

        ds.addType("Item");
        ds.addType("Foo");

		t = ds.getType("Item");
        notEqual(t, undefined, "Item type is available");
        equals(t.name, "Item", "Item type name is correct");

		t = ds.getType("Foo");
        notEqual(t, undefined, "Foo type is available");
        equals(t.name, "Foo", "Foo type name is correct");

        ds.addProperty("foo", {
            valueType: "numeric"
        });
        ds.addProperty("bar");

		t = ds.getProperty("foo");
        notEqual(t, undefined, "foo property is available");
        equals(t.getValueType(), "numeric", "foo is numeric");

		t = ds.getProperty("bar");
        notEqual(t, undefined, "bar property is available");
        equals(t.getValueType(), "text", "bar is text");
    });

    test("Check data source data loading",
    function() {
        var ds,
        item;

        expect(20);
        ds = MITHGrid.Data.initStore({
            source: "Data.initStore.test4"
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
        },
        "Items loaded must have an id");

        // we only expect the item that caused the error and subsequent items not to be loaded
        equals(ds.items().length, 0, "Data source is still empty after an error in loading");

        raises(function() {
            ds.loadItems([{
                id: 'item-0',
                foo: 'bar',
                bar: 'baz',
                ptr: 'item-2'
            }]);
        },
        "Items loaded must have a type");

        equals(ds.items().length, 0, "Data source is still empty after an error in loading");

        ds.loadItems([{
            id: 'item-0',
            foo: 'bar',
            bar: ['baz', 'bat'],
            ptr: 'item-2',
            type: "Item"
        }]);

        equals(ds.items().length, 1, "One item has been loaded");
        equals(ds.items()[0], 'item-0', "ID is 'item-0'");

        // test loading multiple items
        ds.loadItems([{
            id: "item-1",
            foo: "rab",
            ptr: "item-2",
            type: "Item"
        },
        {
            id: "item-2",
            foo: "rba",
            ptr: "item-0",
            type: "Item"
        }]);

        equals(ds.items().length, 3, "Two more items have been loaded");

        //		ds.addProperty('ptr', {
        //			valueType: 'item'
        //		});
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

        deepEqual(item, {
            id: ["item-0"],
            foo: ["bar"],
            bar: ["baz", "bat"],
            ptr: ["item-2"],
            type: ["Item"]
        },
        "returned item matches loaded item");

        ds.loadItems([{
            id: "item-3",
            foo: "baz",
            type: "Item"
        }]);

        equals(ds.items().length, 4, "Data source has two items now");
    });

    // we aren't doing extensive tests of expressions until later
    // here, we are only testing that we can move from one item to another
    // using . and !
    test("Check path traversal",
    function() {
        var ds,
        stmt,
        ids;

        expect(14);
        ds = MITHGrid.Data.initStore({
            source: "Data.initStore.test5"
        });
        equals(ds.items().length, 0, "Data source begins empty");

        ds.loadItems([{
            id: "item-0",
            foo: "bar",
            ptr: "item-1",
            type: "Item"
        },
        {
            id: "item-1",
            foo: "rab",
            ptr: "item-2",
            type: "Item"
        },
        {
            id: "item-2",
            foo: "rba",
            ptr: "item-0",
            type: "Item"
        }]);

        equals(ds.items().length, 3, "All three items are loaded");

        ds.addProperty("ptr", {
            valueType: "item"
        });

		// .ptr should return the item pointed to by item-0's ptr property
        stmt = ds.prepare([".ptr"]);
        notEqual(stmt, undefined, ".prepare returns something");
        ok($.isPlainObject(stmt), ".prepare returns a plain object");
        ok($.isFunction(stmt.evaluate), ".prepare returns something with a .evaluate property as a function");

        ids = stmt.evaluate("item-0");
        ok($.isArray(ids), ".evaluate returns an array");
        equals(ids.length, 1, "There's a single item");
        equals(ids[0], "item-1", "It's the correct item");

		// !ptr should return the item pointing to item-0 through the ptr property
        stmt = ds.prepare(["!ptr"]);
        notEqual(stmt, undefined, ".prepare returns something");
        ok($.isPlainObject(stmt), ".prepare returns a plain object");
        ok($.isFunction(stmt.evaluate), ".prepare returns something with a .evaluate property as a function");

        ids = stmt.evaluate("item-0");
        ok($.isArray(ids), ".evaluate returns an array");
        equals(ids.length, 1, "There's a single item");
        equals(ids[0], "item-2", "It's the correct item");
    });

    module("Data.initView");

	test("Check interface",
	function() {
		var dv,
		props = [ "items", "addProperty", "getProperty", "addType", "getType", "getItem", "getItems",
		          "fetchData", "updateItems", "loadItems", "prepare", "getObjectsUnion", "getSubjectsUnion" ];
		
		expect(props.length);
		dv = MITHGrid.Data.initView({
			source: "Data.initStore.interface_test"
		});
		$.each(props, function(idx, prop) {
			ok($.isFunction(dv[prop]), "."+prop+" is a function");
		});
	});

    test("Check data view construction",
    function() {
        var dv;

        expect(2);
        ok(MITHGrid.Data.initView !== undefined, "Data.initView exists");
        ok($.isFunction(MITHGrid.Data.initView), "Data.initView is a function");
    });
});