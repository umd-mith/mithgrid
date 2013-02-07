$(document).ready ->
  module "Controller"

  test "Check namespace", ->
    expect 3
    ok MITHgrid.Controller?, "MITHgrid.Controller exists"
    ok $.isFunction(MITHgrid.Controller.namespace), "MITHgrid.Controller.namespace is a function"
    ok $.isFunction(MITHgrid.Controller.debug), "MITHgrid.Controller.debug is a function"

  module "Controller.initInstance"

  test "Check interface", ->
    expect 2
    
    MITHgrid.defaults "Test.Controller",
      bind:
        events:
          onFocus: null
      events:
        onFoo: null
    
    ctrl = MITHgrid.Controller.initInstance("Test.Controller")
    ok ctrl?.options?.bind?.events?.hasOwnProperty('onFocus'), "options has bind.events.onFocus"
    ok ctrl?.options?.events?.hasOwnProperty('onFoo'), "options has events.onFoo"
    
  test "Check Raphael controller interface", ->
    expect 2

    MITHgrid.defaults "Test.Controller",
      bind:
        events:
          onFocus: null
      events:
        onFoo: null

    ctrl = MITHgrid.Controller.Raphael.initInstance("Test.Controller")
    ok ctrl?.options?.bind?.events?.hasOwnProperty('onFocus'), "options has bind.events.onFocus"
    ok ctrl?.options?.events?.hasOwnProperty('onFoo'), "options has events.onFoo"
