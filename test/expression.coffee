$(document).ready ->
  module "Expression"

  test "Check namespace", ->
    expect 3
    ok MITHgrid.Expression?.Basic?, "MITHgrid.Expression.Basic exists"
    ok $.isFunction(MITHgrid.Expression.Basic.namespace), "MITHgrid.Expression.Basic.namespace is a function"
    ok $.isFunction(MITHgrid.Expression.Basic.debug), "MITHgrid.Expression.Basic.debug is a function"

  module "Expression.Basic.initCollection"
  
  test "Check collection constructor", ->    
    expect 2
    ok MITHgrid.Expression.Basic.initCollection?, "Collection exists"
    ok $.isFunction(MITHgrid.Expression.Basic.initCollection), "initCollection is a function"
  
  # make sure we run the same tests for each style of collection construction
  checkCollection = (col) ->
    list = [];
    
    ok col?, "collection object is not undefined"
    equal 4, col.size(), ".size returns right number of values"
    col.forEachValue (x) ->
      list.push x
      false

    equal 4, list.length, ".forEachValue visits each element"
  
  test "Check collection construction (array)", ->
    list = []

    expect 3
    col = MITHgrid.Expression.Basic.initCollection ['a', 'bc', 'def', 4]
    checkCollection col
  
  test "Check collection construction (set)", ->
    list = []
    
    set = MITHgrid.Data.Set.initInstance [ 'a', 'bc', 'def', 4 ]
    
    expect 3
    col = MITHgrid.Expression.Basic.initCollection set
    checkCollection col

  test "Compile equiality expression", ->
    expect 1
    parser = MITHgrid.Expression.Basic.initInstance()
    ex = parser.parse(".foo = 'bar'")
    ok ex, "We have a parse"

  test "Compile path alternations", ->
    expect 1
    parser = MITHgrid.Expression.Basic.initInstance()
    ex = parser.parse("!ptr(!ptr)*")
    ok ex, "We have a parse"

  test "Check expression path alternations", ->
    list = []

    db = MITHgrid.Data.Store.initInstance()
    db.addProperty 'ptr',
      valueType: 'item'

    db.loadItems [ {
      id: "foo"
      type: "Item"
      ptr: "bar"
    }, {
      id: "bar"
      type: "Item"
      ptr: "baz"
    }, {
      id: "baz"
      type: "Item"
      ptr: "foo"
    } ]

    expect 15
    equal 3, db.size(), "Three items in the test database"

    ex = db.prepare(['.ptr(.ptr)*'])
    ok ex, "We have something back from prepare"
    ok ex.evaluate, "We have an evaluate property for the prepared statement"
    ok $.isFunction(ex.evaluate), "Evaluate property is a function"

    result = ex.evaluate(["foo"])
    ok 3, result.length, "We have three items in the result"
    ok ("foo" in result), "Foo is in result"
    ok ("bar" in result), "Bar is in result"
    ok ("baz" in result), "Baz is in result"

    ex = db.prepare(['!ptr(!ptr)*'])
    ok ex, "We have something back from prepare"
    ok ex.evaluate, "We have an evaluate property for the prepared statement"
    ok $.isFunction(ex.evaluate), "Evaluate property is a function"

    result = ex.evaluate(["foo"])
    ok 3, result.length, "We have three items in the result"
    ok ("foo" in result), "Foo is in result"
    ok ("bar" in result), "Bar is in result"
    ok ("baz" in result), "Baz is in result"
