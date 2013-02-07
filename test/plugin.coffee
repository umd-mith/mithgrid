$(document).ready ->
  module "Plugin"

  test "Check namespace", ->
    expect 4
    ok  MITHgrid.Plugin?, "MITHgrid.Plugin exists"
    ok $.isFunction(MITHgrid.Plugin.namespace), "MITHgrid.Plugin.namespace is a function"
    ok $.isFunction(MITHgrid.Plugin.debug), "MITHgrid.Plugin.debug is a function"
    ok $.isFunction(MITHgrid.Plugin.initInstance), "MITHgrid.Plugin.initPlugin is a function"
