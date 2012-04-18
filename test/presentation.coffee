$(document).ready ->
	module "Presentation"

	test "Check namespace", ->
		expect 3
		ok MITHGrid.Presentation?, "MITHGrid.Presentation exists"
		ok $.isFunction(MITHGrid.Presentation.namespace), "MITHGrid.Presentation.namespace is a function"
		ok $.isFunction(MITHGrid.Presentation.debug), "MITHGrid.Presentation.debug is a function"

	module "Presentation.SimpleText"
	test "Simple Text presentation", ->
		expect 7
		ds = MITHGrid.Data.initStore()
		ok ds?, "Data store is created"
		renderings = []
		updates = []
		removals = []
		p = MITHGrid.Presentation.SimpleText.initPresentation $("#presentation-simple-text-p"),
			dataView: MITHGrid.Data.initView
				dataStore: ds 
			lenses:
				'Item': (container, view, model, id) ->
					renderings.push id
					that = {}
					that.update = (item) -> updates.push id
					that.remove = (item) -> removals.push id
					that
	
			
		ok p?, "Presentation object is returned"
		stop()
		
		ds.loadItems [
			id: "foo"
			content: "Foo!"
			type: "Item"
			label: "foo"
		], ->
			start()
			deepEqual renderings, [ 'foo' ], "Right item is rendered"
			ok p.renderingFor('foo')?, "Rendering exists for 'foo'"
			stop()
			ds.updateItems [
				id: "foo"
				content: "FoO!"
			], ->
				start()
				deepEqual updates, [ 'foo' ], "Right item is updated"
				stop()
				ds.removeItems ['foo'], ->
					start()
					deepEqual removals, [ 'foo' ], "Right item is removed"
					ok !p.renderingFor('foo')?, "No rendering for 'foo'"