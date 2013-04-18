# # Expression Parser
#
# Everything here is private except for a few exported objects and functions.
#
#
# ## Expressions
#
# Expressions describe a path through the data graph held in a data store.
#
# Expressions hop from node to node in one of two directions: forward or backward. Forward goes from an item ID through a property
# to arrive at a new value. Backward goes from a value through a property to arrive at a new item ID.
#
# For example, if we have a data store with items holding information about books, such as the following:
#
#     [{
#        id: "book1",
#        author: "author1",
#        title: "A Tale of Two Cities",
#        pages: 254
#      }, {
#        id: "author1",
#        name: "Charles Dickens"
#      }]
#
# Then .name would return "Charles Dickens" if we started with the item ID "author1". But .author.name would return the same
# value if we started with the item ID "book1".
#
# If we start with "Charles Dickens" (the value), we can find the number of pages in the books with the following expression:
# !name!author.pages (or <-name<-author->pages using the longer notation).
#
# . and -> use a forward index and must have an item ID on the left side
#
# ! and <- use a reverse index and will result in an item ID on the right side
#
# .foo* means to follow the foo property until you can't any more, returning
# the ids along the way
# !foo* means to follow the foo property backward until you can't any more,
# returning the ids along the way
# (...)* means to apply the subgraph-traversal as many times as possible
#
MITHgrid.namespace "Expression.Basic", (exports) ->
  Expression = {}
  _operators =
    "+":
      argumentType: "number"
      valueType: "number"
      f: (a, b) -> a + b
    "-":
      argumentType: "number"
      valueType: "number"
      f: (a, b) -> a - b
    "*":
      argumentType: "number"
      valueType: "number"
      f: (a, b) -> a * b
    "/":
      argumentType: "number"
      valueType: "number"
      f: (a, b) -> a / b
    "=":
      valueType: "boolean"
      f: (a, b) -> a == b
    "<>":
      valueType: "boolean"
      f: (a, b) -> a != b
    "><":
      valueType: "boolean"
      f: (a, b) -> a != b
    "<":
      valueType: "boolean"
      f: (a, b) -> a < b
    ">":
      valueType: "boolean"
      f: (a, b) -> a > b
    "<=":
      valueType: "boolean"
      f: (a, b) -> a <= b
    ">=":
      valueType: "boolean"
      f: (a, b) -> a >= b

  # ## MITHgrid.Expression.Basic.controls
  #
  # Control functions may be defined for use in expressions. See the existing control functions for examples of
  # how to write them.
  #
  # All control functions take the following parameters:
  #
  # * args
  # * roots
  # * rootValueTypes
  # * defaultRootName
  # * database
  #
  # All control functions should return a collection of items (using MITHgrid.Expression.initCollection collections)
  #
  Expression.controls = exports.controls =
    # ### if
    #
    "if":
      f: (args, roots, rootValueTypes, defaultRootName, database) ->
        conditionCollection = args[0].evaluate roots, rootValueTypes, defaultRootName, database
        condition = false
        conditionCollection.forEachValue (v) ->
          if v
            condition = true
            return true
          else
            return undefined
      
        if condition
          args[1].evaluate roots, rootValueTypes, defaultRootName, database
        else
          args[2].evaluate roots, rootValueTypes, defaultRootName, database
    # ### foreach
    #
    "foreach":
      f: (args, roots, rootValueTypes, defaultRootName, database) ->
        collection = args[0].evaluate roots, rootValueTypes, defaultRootName, database
        oldValue = roots.value
        oldValueType = rootValueTypes.value
        results = []
        valueType = "text"

        rootValueTypes.value = collection.valueType

        collection.forEachValue (element) ->
          roots.value = element
          collection2 = args[1].evaluate roots, rootValueTypes, defaultRootName, database
          valueType = collection2.valueType

          collection2.forEachValue (result) ->
            results.push result

        roots.value = oldValue
        rootValueTypes.value = oldValueType

        Expression.initCollection results, valueType
    "default":
      f: (args, roots, rootValueTypes, defaultRootName, database) ->
        for arg in args
          collection = arg.evaluate roots, rootValueTypes, defaultRootName, database
          if collection.size() > 0
            return collection
        Expression.initCollection [], "text"

  Expression.initExpression = (rootNode) ->
    that = {}

    that.evaluate = (roots, rootValueTypes, defaultRootName, database) ->
      collection = rootNode.evaluate roots, rootValueTypes, defaultRootName, database
      return {
        values: collection.getSet()
        valueType: collection.valueType
        size: collection.size
      }
    
    that.evaluateOnItem = (itemID, database) ->
      that.evaluate({
        "value": itemID
      }, {
        "value": "item"
      },
      "value",
      database
      )

    that.evaluateSingle = (roots, rootValueTypes, defaultRootName, database) ->
      collection = rootNode.evaluate roots, rootValueTypes, defaultRootName, database
      result =
        value: null
        valueType: collection.valueType

      collection.forEachValue (v) ->
        result.value = v
        true

      result;

    that.isPath = rootNode.isPath

    if that.isPath
      that.getPath = () -> rootNode 
      that.testExists = (roots, rootValueTypes, defaultRootName, database) ->
        rootNode.testExists roots, rootValueTypes, defaultRootName, database
    else
      that.getPath = () -> null
      that.testExists = (roots, rootValueTypes, defaultRootName, database) ->
        that.evaluate(roots, rootValueTypes, defaultRootName, database).values.size() > 0
  
    that.evaluateBackward = (value, valueType, filter, database) ->
      rootNode.walkBackward [value], valueType, filter, database

    that.walkForward = (values, valueType, database) ->
      rootNode.walkForward values, valueType, database

    that.walkBackward = (values, valueType, filter, database) ->
      rootNode.walkBackward values, valueType, filter, database

    that

  Expression.initCollection = exports.initCollection = (values, valueType) ->
    that =
      valueType: valueType

    if values instanceof Array

      that.forEachValue = (f) ->
        for v in values
          if f(v) == true
            break;

      that.getSet = () -> MITHgrid.Data.Set.initInstance values

      that.contains = (v) -> v in values

      that.size = () -> values.length
    else
      that.forEachValue = values.visit
      that.size = values.size
      that.getSet = () -> values
      that.contains = values.contains

    that.isPath = false;

    that

  Expression.initConstant = (value, valueType) ->
    that = {}

    that.evaluate = (roots, rootValueTypes, defaultRootName, database) -> Expression.initCollection [value], valueType

    that.isPath = false;

    that

  Expression.initOperator = (operator, args) ->
    that = {}
    _operator = operator
    _args = args

    that.evaluate = (roots, rootValueTypes, defaultRootName, database) ->
      values = []
      args = []

      args.push(a.evaluate roots, rootValueTypes, defaultRootName, database) for a in _args

      operator = _operators[_operator]
      f = operator.f
      if  operator.argumentType == "number"
        args[0].forEachValue (v1) ->
          if typeof(v1) != "number"
            v1 = parseFloat v1

          args[1].forEachValue (v2) ->
            if typeof(v2) != "number"
              v2 = parseFloat v2

            values.push f(v1, v2)
      else
        args[0].forEachValue (v1) ->
          args[1].forEachValue (v2) -> values.push f(v1, v2)

      Expression.initCollection values, operator.valueType

    that.isPath = false

    that

  Expression.initFunctionCall = (name, args) ->
    that = {}
    _args = args

    that.evaluate = (roots, rootValueTypes, defaultRootName, database) ->
      args = []

      args.push(a.evaluate roots, rootValueTypes, defaultRootName, database ) for a in _args

      if Expression.functions[name]?.f?
        return Expression.functions[name].f args
      else
        throw new Error "No such function named #{_name}"

    that.isPath = false

    that

  Expression.initControlCall = (name, args) ->
    that = {}

    that.evaluate = (roots, rootValueTypes, defaultRootName, database) ->
      Expression.controls[name].f args, roots, rootValueTypes, defaultRootName, database

    that.isPath = false

    that

  Expression.initPath = (property, forward) ->
    that = {}
    _rootName = null
    _segments = []
  
    #
    # If isMultiple == true (.@ or !@ instead of . or !), then we
    # collect all matching values regardless of multiplicity. Otherwise,
    # we only return one instance of each matching value.
    #
    walkForward = (collection, database) ->
      forwardArraySegmentFn = (segment) ->
        a = []
        collection.forEachValue (v) ->
          database.getObjects(v, segment.property).visit (v2) -> a.push v2
        a

      backwardArraySegmentFn = (segment) ->
        a = []
        collection.forEachValue (v) ->
          database.getSubjects(v, segment.property).visit (v2) -> a.push v2
        a

      for i in [ 0 ... _segments.length ]
        segment = _segments[i]
        if segment.expression?
          if segment.forward
            # simply evaluate the expressions and report the results
            collection = segment.expression.evaluateOnItem(collection.getSet().items(), database)
          else
            # walk backward
        else if segment.isMultiple
          a = []
          if segment.forward
            a = forwardArraySegmentFn segment
            property = database.getProperty segment.property
            valueType = if property? then property.getValueType() else "text"
          else
            a = backwardArraySegmentFn segment
            valueType = "item"
          collection = Expression.initCollection a, valueType
        else
          if segment.forward
            values = database.getObjectsUnion collection.getSet(), segment.property
            property = database.getProperty segment.property
            valueType = if property? then property.getValueType() else "text"
            collection = Expression.initCollection values, valueType
          else
            values = database.getSubjectsUnion collection.getSet(), segment.property
            collection = Expression.initCollection values, "item"

      collection

    walkBackward = (collection, filter, database) ->
      forwardArraySegmentFn = (segment) ->
        a = []
        collection.forEachValue (v) ->
          database.getSubjects(v, segment.property).visit (v2) ->
            a.push v2 if i > 0 or !filter? or filter.contains v2
        a

      backwardArraySegmentFn = (segment) ->
        a = []
        collection.forEachValue (v) ->
          database.getObjects(v, segment.property).visit (v2) ->
            a.push v2 if i > 0 or !filter? or filter.contains v2
        a

      if filter instanceof Array
        filter = MITHgrid.Data.Set.initInstance filter

      for i in [ _segments.length-1 .. 0 ]
        segment = _segments[i];
        if segment.isMultiple
          a = []
          if segment.forward
            a = forwardArraySegmentFn segment
            property = database.getProperty segment.property
            valueType = if property? then property.getValueType() else "text"
          else
            a = backwardArraySegmentFn segment
            valueType = "item"
          collection = Expression.initCollection a, valueType
        else if segment.forward
          values = database.getSubjectsUnion(collection.getSet(), segment.property, null, if i == 0 then filter else null)
          collection = Expression.initCollection values, "item"
        else
          values = database.getObjectsUnion(collection.getSet(), segment.property, null, if i == 0 then filter else null)
          property = database.getProperty segment.property
          valueType = if property? then property.getValueType() else "text"
          collection = Expression.initCollection values, valueType

      collection

    if property?
      _segments.push
        property: property
        forward: forward
        isMultiple: false

    that.isPath = true

    that.setRootName = (rootName) -> _rootName = rootName

    that.appendSegment = (property, hopOperator) ->
      _segments.push
        property: property
        forward: hopOperator[0] == "."
        isMultiple: hopOperator.length > 1

    that.getSegment = (index) ->
      if index < _segments.length
        segment = _segments[index]
        return {
          property: segment.property
          forward: segment.forward
          isMultiple: segment.isMultiple
        }
      else
        return null

    that.appendSubPath = (expression) ->
      _segments.push
        expression: expression
        forward: true
        isMultiple: true

    that.getLastSegment = () -> that.getSegment _segments.length - 1

    that.getSegmentCount = () -> _segments.length

    that.rangeBackward = (from, to, filter, database) ->
      set = MITHgrid.Data.Set.initInstance()
      valueType = "item"

      if _segments.length > 0
        segment = _segments[_segments.length - 1]
        if segment.forward
          database.getSubjectsInRange(segment.property, from, to, false, set, if _segments.length == 1 then filter else null)
        else
          throw new Error "Last path of segment must be forward"

        for i in [ _segments.length - 2 .. 0 ]
          segment = _segments[i]
          if segment.forward
            set = database.getSubjectsUnion(set, segment.property, null, if i == 0 then filter else null)
            valueType = "item"
          else
            set = database.getObjectsUnion(set, segment.property, null, if i == 0 then filter else null)
            property = database.getPropertysegment.property
            valueType = if property? then property.getValueType() else "text"

      return {
        valueType: valueType
        values: set
        count: set.size()
      }

    that.evaluate = (roots, rootValueTypes, defaultRootName, database) ->
      rootName = if _rootName? then _rootName else defaultRootName
      valueType = if rootValueTypes[rootName]? then rootValueTypes[rootName] else "text"
      collection = null

      if roots[rootName]?
        root = roots[rootName]

        if $.isPlainObject(root) or root instanceof Array
          collection = Expression.initCollection root, valueType
        else
          collection = Expression.initCollection [root], valueType

        return walkForward collection, database
      else
        throw new Error "No such variable called " + rootName

    that.testExists = (roots, rootValueTypes, defaultRootName, database) ->
      that.evaluate(roots, rootValueTypes, defaultRootName, database).size() > 0

    that.evaluateBackward = (value, valueType, filter, database) ->
      collection = Expression.initCollection [value], valueType
      walkBackward collection, filter, database

    that.walkForward = (values, valueType, database) ->
      walkForward Expression.initCollection(values, valueType), database

    that.walkBackward = (values, valueType, filter, database) ->
      walkBackward Expression.initCollection(values, valueType), filter, database

    that

  # This allows us to do the following:
  # .foo(.bar.baz)*.bat and follow any number of .bar.baz segments
  # .foo(.bar,.baz)*.bat follows any number of .bar or .baz segments
  Expression.initClosure = (expressions) ->
    that = {}
    that.isPath = false

    expressions = [ expressions ] unless $.isArray expressions

    that.evaluateOnItem = (roots, database) ->
      finalSet = MITHGrid.Data.Set.initInstance()
      valueType = null
      for ex in expressions
        set = ex.evaluate({ "value": roots }, { "value": "item" }, "value", database)
        set.getSet().visit finalSet.add
        valueType ?= set.valueType
      nextRoots = finalSet.items()
      while nextRoots.length > 0
        nextSet = MITHGrid.Data.Set.initInstance()
        for ex in expressions
          set = ex.evaluate({ "value": nextRoots }, { "value": "item" }, "value", database)
          set.getSet().visit (v) ->
            if !finalSet.contains(v)
              nextSet.add(v)
              finalSet.add(v)
        nextRoots = nextSet.items()

      return {
        values: finalSet
        getSet: -> finalSet
        valueType: valueType || "text"
        size: finalSet.size()
      }
    that

  Expression.initExpressionSet = (expressions) ->
    that = {}
    that.isPath = false

    expressions = [ expressions ] unless $.isArray expressions

    that.evaluateOnItem = (root, database) ->
      finaleSet = MITHGrid.Data.Set.initInstance()
      valueType = null
      for ex in expressions
        set = ex.evaluate({ "value": roots }, { "value": "item" }, "value", database)
        set.getSet().visit finalSet.add
        valueType ?= set.valueType
      return {
        values: finalSet
        getSet: -> finalSet
        valueType: valueType || "text"
        size: finalSet.size()
      }

  Expression.initParser = exports.initInstance = ->
    that = {}
  
    internalParse = (scanner, several) ->
      token = scanner.token()
      Scanner = Expression.initScanner
    
      next = () ->
        scanner.next()
        token = scanner.token()

      parseExpressionList = () ->
        expressions = [parseExpression()]
        while token? and token.type == Scanner.DELIMITER and token.value == ","
          next()
          expressions.push parseExpression()
        expressions

      makePosition = () -> if token? then token.start else scanner.index()

      parsePath = () ->
        path = Expression.initPath()

        while token? && !(token.type == Scanner.DELIMITER && token.value == ')')
          if token.type == Scanner.PATH_OPERATOR
            hopOperator = token.value
            next()
        
            if token? and token.type == Scanner.IDENTIFIER
              path.appendSegment token.value, hopOperator
              next()
            else
              throw new Error "Missing property ID at position " + makePosition()
          else if token.type == Scanner.DELIMITER and token.value == '('
            next()
            expressions = parseExpressionList()
            if token && token.type == Scanner.DELIMITER
              if token.value == ')'
                next()
                if token && token.type == Scanner.OPERATOR and token.value == '*'
                  next()
                  path.appendSubPath Expression.initClosure expressions
                else
                  path.appendSubPath Expression.initExpressionSet expressions
              else
                throw new Error "Mismatched ')' at position " + makePosition()
            else
              throw new Error "Mismatched ')' at position " + makePosition()
        path

      parseExpression = () ->
        result = null
        args = []

        if !token?
          throw new Error "Missing factor at end of expression"

        switch token.type
          when Scanner.NUMBER
            result = Expression.initConstant token.value, "number"
            next()
          when Scanner.STRING
            result = Expression.initConstant(token.value, "text");
            next();
          when Scanner.PATH_OPERATOR then result = parsePath()
          when Scanner.IDENTIFIER
            identifier = token.value
            next()

            if Expression.controls[identifier]?
              if token? and token.type == Scanner.DELIMITER and token.value == "("
                next()

                if token? and token.type == Scanner.DELIMITER and token.value == ")" 
                  args = []
                else
                  args = parseExpressionList()
                result = Expression.initControlCall identifier, args

                if token? and token.type == Scanner.DELIMITER and token.value == ")"
                  next()
                else
                  throw new Error "Missing ) to end " + identifier + " at position " + makePosition()
              else
                throw new Error "Missing ( to start " + identifier + " at position " + makePosition()
            else
              if token? and token.type == Scanner.DELIMITER and token.value == "("
                next()
              
                if token? and token.type == Scanner.DELIMITER and token.value == ")"
                  args = []
                else
                  args = parseExpressionList()
                result = Expression.initFunctionCall identifier, args

                if token? and token.type == Scanner.DELIMITER and token.value == ")"
                  next()
                else
                  throw new Error "Missing ) after function call " + identifier + " at position " + makePosition()
              else
                result = parsePath()
                result.setRootName identifier
          when Scanner.DELIMITER
            if token.value == "("
              next()

              result = parseExpression()
              if token? and token.type == Scanner.DELIMITER and token.value == ")"
                next()
              else
                throw new Error "Missing ) at position " + makePosition()
            else
              throw new Error "Unexpected text " + token.value + " at position " + makePosition()
          else
            throw new Error "Unexpected text " + token.value + " at position " + makePosition()
        result

      if several
        roots = parseExpressionList()
        expressions = []
        expressions.push Expression.initExpression(r) for r in roots
        return expressions
      else
        return [Expression.initExpression(parseExpression())]

    that.parse = (s, startIndex, results) ->
      startIndex ?= 0
      results ?= {}

      scanner = Expression.initScanner s, startIndex
      try
        return internalParse(scanner, false)[0]
      finally
        results.index = if scanner.token()? then scanner.token().start else scanner.index()

    that

  Expression.initScanner = (text, startIndex) ->
    that = {}
    _text = text + " "
    _maxIndex = text.length
    _index = startIndex
    _token = null

    isDigit = (c) -> "0123456789".indexOf(c) >= 0

    that.token = () -> _token

    that.index = () -> _index

    that.next = () ->
      _token = null

      _index += 1 while _index < _maxIndex and " \t\r\n".indexOf(_text.charAt _index) >= 0

      if _index < _maxIndex
        c1 = _text.charAt _index
        c2 = _text.charAt _index + 1
        c3 = _text.charAt _index + 2

        if ".!".indexOf(c1) >= 0
          if c2 == "@"
            _token =
              type: Expression.initScanner.PATH_OPERATOR
              value: c1 + c2
              start: _index
              end: _index + 2
            _index += 2
          else
            _token =
              type: Expression.initScanner.PATH_OPERATOR
              value: c1
              start: _index
              end: _index + 1
            _index += 1
        else if c1 == "<" and c2 == "-"
          if c3 == "@"
            _token =
              type: Expression.initScanner.PATH_OPERATOR
              value: "!@"
              start: _index
              end: _index + 3
            _index += 3
          else
            _token =
              type: Expression.initScanner.PATH_OPERATOR
              value: "!"
              start: _index
              end: _index + 2
            _index += 2
        else if c1 == "-" and c2 == ">"
          if c3 == "@"
            _token =
              type: Expression.initScanner.PATH_OPERATOR
              value: ".@"
              start: _index
              end: _index + 3
            _index += 3
          else
            _token =
              type: Expression.initScanner.PATH_OPERATOR
              value: "."
              start: _index
              end: _index + 2
            _index += 2
        else if "<>".indexOf(c1) >= 0
          if (c2 == "=") or ("<>".indexOf(c2) >= 0 and c1 != c2)
            _token =
              type: Expression.initScanner.OPERATOR
              value: c1 + c2
              start: _index
              end: _index + 2
            _index += 2
          else
            _token =
              type: Expression.initScanner.OPERATOR
              value: c1
              start: _index
              end: _index + 1
            _index += 1
        else if "+-*/=".indexOf(c1) >= 0
          _token =
            type: Expression.initScanner.OPERATOR
            value: c1
            start: _index
            end: _index + 1
          _index += 1
        else if "()".indexOf(c1) >= 0
          _token =
            type: Expression.initScanner.DELIMITER
            value: c1
            start: _index
            end: _index + 1
          _index += 1
        else if "\"'".indexOf(c1) >= 0
          # quoted strings
          i = _index + 1
          while i < _maxIndex
            break if _text.charAt(i) == c1 and _text.charAt(i - 1) != "\\"
            i += 1

          if i < _maxIndex
            _token =
              type: Expression.initScanner.STRING
              value: _text.substring(_index + 1, i).replace(/\\'/g, "'").replace(/\\"/g, '"')
              start: _index
              end: i + 1
            _index = i + 1
          else
            throw new Error "Unterminated string starting at " + String(_index)
        else if isDigit c1
          # number
          i = _index
          i += 1 while i < _maxIndex and isDigit(_text.charAt i)

          if i < _maxIndex and _text.charAt(i) == "."
            i += 1
            i += 1 while i < _maxIndex and isDigit(_text.charAt i)

          _token =
            type: Expression.initScanner.NUMBER
            value: parseFloat(_text.substring(_index, i))
            start: _index
            end: i
          _index = i;
        else
          # identifier
          i = _index

          while i < _maxIndex
            c = _text.charAt i
            break unless "(),.!@ \t".indexOf(c) < 0
            i += 1

          _token =
            type: Expression.initScanner.IDENTIFIER
            value: _text.substring(_index, i)
            start: _index
            end: i
          _index = i

    that.next()

    that

  Expression.initScanner.DELIMITER = 0
  Expression.initScanner.NUMBER = 1
  Expression.initScanner.STRING = 2
  Expression.initScanner.IDENTIFIER = 3
  Expression.initScanner.OPERATOR = 4
  Expression.initScanner.PATH_OPERATOR = 5

  Expression.functions = { }
  Expression.FunctionUtilities = { }

  exports.registerSimpleMappingFunction = (name, f, valueType) ->
    Expression.functions[name] =
      f: (args) ->
        set = MITHgrid.Data.Set.initInstance()
        evalArg = (arg) ->
          arg.forEachValue (v) ->
            v2 = f(v)
            set.add v2 if v2?

        evalArg arg for arg in args

        Expression.initCollection set, valueType
