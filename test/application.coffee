$(document).ready ->
	module "Application"

	test "Check namespace", ->
		expect 2
		ok MITHGrid.Application?, "MITHGrid.Application exists"
		ok $.isFunction(MITHGrid.Application.initInstance), "MITHGrid.Application.initInstance is a function"
	
	test "Check variables", ->
		expect 3
		app = MITHGrid.Application.initInstance {
			variables:
				Foo:
					is: 'rw'
		}
		
		eventFooChange = ->
		
		app.events.onFooChange.addListener (f) ->
			eventFooChange f
		

		checkValue = (t, cb) ->
			eventFooChange = (f) ->
				start()
				equal f, t, "Foo set to #{t}"
				setTimeout cb, 0
			stop()
			app.setFoo t
				
		checkValue 1, ->
			checkValue 2, ->
				checkValue 3, ->