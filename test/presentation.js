$(document).ready(function() {
	module("Presentation");

	test("Check namespace", function() {
		expect(3);
		ok( MITHGrid.Presentation !== undefined, "MITHGrid.Presentation exists" );
		ok( $.isFunction(MITHGrid.Presentation.namespace), "MITHGrid.Presentation.namespace is a function" );
		ok( $.isFunction(MITHGrid.Presentation.debug), "MITHGrid.Presentation.debug is a function" );
	});

	module("Presentation.SimpleText");
	test("Simple Text presentation", function() {
		expect(7);
		var ds = MITHGrid.Data.initStore(),
			renderings = [],
			updates = [],
			removals = [];
		try {
			p = MITHGrid.Presentation.SimpleText.initPresentation($("#presentation-simple-text-p"), {
				dataView: MITHGrid.Data.initView({
					dataStore: ds 
				}),
				lenses: {
					'Item': function(container, view, model, id) {
						renderings.push(id);
						var that = {};
						that.update = function(item) {
							updates.push(id);
						};
						that.remove = function(item) {
							removals.push(id);
						};
						return that;
					}
				}
			});
			ok(true, "Presentation created without error");
		}
		catch(e) {
			ok(!e, "Uh oh... errors: " + e);
		}
		ok( p !== undefined, "Presentation object is returned" );
		stop();
		ds.loadItems([
			{ id: "foo", content: "Foo!", type: "Item", label: "foo" }
		], function() {
			start();
			deepEqual(renderings, [ 'foo' ], "Right item is rendered");
			notEqual(p.renderingFor('foo'), undefined, "Rendering exists for 'foo'");
			stop();
			ds.updateItems([
				{ id: "foo", content: "FoO!" }
			], function() {
				start();
				deepEqual(updates, [ 'foo' ], "Right item is updated");
				stop();
				ds.removeItems(['foo'], function() {
					start();
					deepEqual(removals, [ 'foo' ], "Right item is removed");
					equal(p.renderingFor('foo'), undefined, "No rendering for 'foo'");
				});
			});

		});

	});
});