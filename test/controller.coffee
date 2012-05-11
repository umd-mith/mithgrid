$(document).ready ->
	module "Controller"

	test "Check namespace", ->
		expect 3
		ok MITHGrid.Controller?, "MITHGrid.Controller exists"
		ok $.isFunction(MITHGrid.Controller.namespace), "MITHGrid.Controller.namespace is a function"
		ok $.isFunction(MITHGrid.Controller.debug), "MITHGrid.Controller.debug is a function"

	module "Controller.initInstance"

	test "Check interface", ->
		expect 2
		
		MITHGrid.defaults "Test.Controller",
			bind:
				events:
					onFocus: null
			events:
				onFoo: null
		
		ctrl = MITHGrid.Controller.initInstance("Test.Controller")
		ok ctrl?.options?.bind?.events?.hasOwnProperty('onFocus'), "options has bind.events.onFocus"
		ok ctrl?.options?.events?.hasOwnProperty('onFoo'), "options has events.onFoo"
		
	test "Check Raphael controller interface", ->
		expect 2

		MITHGrid.defaults "Test.Controller",
			bind:
				events:
					onFocus: null
			events:
				onFoo: null

		ctrl = MITHGrid.Controller.Raphael.initInstance("Test.Controller")
		ok ctrl?.options?.bind?.events?.hasOwnProperty('onFocus'), "options has bind.events.onFocus"
		ok ctrl?.options?.events?.hasOwnProperty('onFoo'), "options has events.onFoo"