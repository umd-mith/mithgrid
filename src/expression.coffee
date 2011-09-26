(function() {
  var Expression, _operators;
  var __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  };
  Expression = MITHGrid.namespace("Expression");
  _operators = {
    "+": {
      argumentType: "number",
      valueType: "number",
      f: function(a, b) {
        return a + b;
      }
    },
    "-": {
      argumentType: "number",
      valueType: "number",
      f: function(a, b) {
        return a - b;
      }
    },
    "*": {
      argumentType: "number",
      valueType: "number",
      f: function(a, b) {
        return a * b;
      }
    },
    "/": {
      argumentType: "number",
      valueType: "number",
      f: function(a, b) {
        return a / b;
      }
    },
    "=": {
      valueType: "boolean",
      f: function(a, b) {
        return a === b;
      }
    },
    "<>": {
      valueType: "boolean",
      f: function(a, b) {
        return a !== b;
      }
    },
    "><": {
      valueType: "boolean",
      f: function(a, b) {
        return a !== b;
      }
    },
    "<": {
      valueType: "boolean",
      f: function(a, b) {
        return a < b;
      }
    },
    ">": {
      valueType: "boolean",
      f: function(a, b) {
        return a > b;
      }
    },
    "<=": {
      valueType: "boolean",
      f: function(a, b) {
        return a <= b;
      }
    },
    ">=": {
      valueType: "boolean",
      f: function(a, b) {
        return a >= b;
      }
    }
  };
  Expression.controls = {
    "if": {
      f: function(args, roots, rootValueTypes, defaultRootName, database) {
        var condition, conditionCollection;
        conditionCollection = args[0].evaluate(roots, rootValueTypes, defaultRootName, database);
        condition = false;
        conditionCollection.forEachValue(function(v) {
          if (v) {
            condition = true;
            return true;
          } else {
            ;
          }
        });
        if (condition) {
          return args[1].evaluate(roots, rootValueTypes, defaultRootName, database);
        } else {
          return args[2].evaluate(roots, rootValueTypes, defaultRootName);
        }
      }
    },
    "foreach": {
      f: function(args, roots, rootValueTypes, defaultRootName, database) {
        var collection, oldValue, oldValueType, results, valueType;
        collection = args[0].evaluate(roots, rootValueTypes, defaultRootName, database);
        oldValue = roots.value;
        oldValueType = rootValueTypes.value;
        results = [];
        valueType = "text";
        rootValueTypes.value = collection.valueType;
        collection.forEachValue(function(element) {
          var collection2;
          roots.value = element;
          collection2 = args[1].evaluate(roots, rootValueTypes, defaultRootName, database);
          valueType = collection2.valueType;
          return collection2.forEachValue(function(result) {
            return results.push(result);
          });
        });
        roots.value = oldValue;
        rootValueTypes.value = oldValueType;
        return Expression.initCollection(results, valueType);
      }
    },
    "default": {
      f: function(args, roots, rootValueTypes, defaultRootName, database) {
        var arg, collection, _i, _len;
        for (_i = 0, _len = args.length; _i < _len; _i++) {
          arg = args[_i];
          collection = arg.evaluate(roots, rootValueTypes, defaultRootName, database);
          if (collection.size() > 0) {
            return collection;
          }
        }
        return Expression.initCollection([], "text");
      }
    }
  };
  Expression.initExpression = function(rootNode) {
    var that;
    that = {};
    that.evaluate = function(roots, rootValueTypes, defaultRootName, database) {
      var collection;
      collection = rootNode.evaluate(roots, rootValueTypes, defaultRootName, database);
      return {
        values: collection.getSet(),
        valueType: collection.valueType,
        size: collection.size
      };
    };
    that.evaluateOnItem = function(itemID, database) {
      return this.evaluate({
        "value": itemID
      }, {
        "value": "item"
      }, "value", database);
    };
    that.evaluateSingle = function(roots, rootValueTypes, defaultRootName, database) {
      var collection, result;
      collection = rootNode.evaluate(roots, rootValueTypes, defaultRootName, database);
      result = {
        value: null,
        valueType: collection.valueType
      };
      collection.forEachValue(function(v) {
        result.value = v;
        return true;
      });
      return result;
    };
    that.isPath = rootNode.isPath;
    if (that.isPath) {
      that.getPath = function() {
        return rootNode;
      };
      that.testExists = function(roots, rootValueTypes, defaultRootName, database) {
        return rootNode.testExists(roots, rootValueTypes, defaultRootName, database);
      };
    } else {
      that.getPath = function() {
        return null;
      };
      that.testExists = function(roots, rootValueTypes, defaultRootName, database) {
        return that.evaluate(roots, rootValueTypes, defaultRootName, database).values.size() > 0;
      };
    }
    that.evaluateBackward = function(value, valueType, filter, database) {
      return rootNode.walkBackward([value], valueType, filter, database);
    };
    that.walkForward = function(values, valueType, database) {
      return rootNode.walkForward(values, valueType, database);
    };
    that.walkBackward = function(values, valueType, filter, database) {
      return rootNode.walkBackward(values, valueType, filter, database);
    };
    return that;
  };
  Expression.initCollection = function(values, valueType) {
    var that;
    that = {
      valueType: valueType
    };
    if (values instanceof Array) {
      that.forEachValue = function(f) {
        var v, _i, _len, _results;
        _results = [];
        for (_i = 0, _len = values.length; _i < _len; _i++) {
          v = values[_i];
          if (f(v) === true) {
            break;
          }
        }
        return _results;
      };
      that.getSet = function() {
        return MITHGrid.Data.initSet(values);
      };
      that.contains = function(v) {
        return __indexOf.call(values, v) >= 0;
      };
      that.size = function() {
        return values.length;
      };
    } else {
      that.forEachValue = values.visit;
      that.size = values.size;
      that.getSet = function() {
        return values;
      };
      that.contains = values.contains;
    }
    that.isPath = false;
    return that;
  };
  Expression.initConstant = function(value, valueType) {
    var that;
    that = {};
    that.evaluate = function(roots, rootValueTypes, defaultRootName, database) {
      return Expression.initCollection([value], valueType);
    };
    that.isPath = false;
    return that;
  };
  Expression.initOperator = function(operator, args) {
    var that, _args, _operator;
    that = {};
    _operator = operator;
    _args = args;
    that.evaluate = function(roots, rootValueTypes, defaultRootName, database) {
      var a, f, values, _i, _len;
      values = [];
      args = [];
      for (_i = 0, _len = _args.length; _i < _len; _i++) {
        a = _args[_i];
        args.push(a.evaluate(roots, rootValueTypes, defaultRootName, database));
      }
      operator = _operators[_operator];
      f = operator.f;
      if (operator.argumentType === "number") {
        args[0].forEachValue(function(v1) {
          if (typeof v1 !== "number") {
            v1 = parseFloat(v1);
          }
          return args[1].forEachValue(function(v2) {
            if (typeof v2 !== "number") {
              v2 = parseFloat(v2);
            }
            return values.push(f(v1, v2));
          });
        });
      } else {
        args[0].forEachValue(function(v1) {
          return args[1].forEachValue(function(v2) {
            return values.push(f(v1, v2));
          });
        });
      }
      return Expression.initCollection(values, operator.valueType);
    };
    that.isPath = false;
    return that;
  };
  Expression.initFunctionCall = function(name, args) {
    var that, _args;
    that = {};
    _args = args;
    that.evaluate = function(roots, rootValueTypes, defaultRootName, database) {
      var a, _i, _len, _ref;
      args = [];
      for (_i = 0, _len = _args.length; _i < _len; _i++) {
        a = _args[_i];
        args.push(a.evaluate(roots, rootValueTypes, defaultRootName, database));
      }
      if (((_ref = Expression.functions[name]) != null ? _ref.f : void 0) != null) {
        return Expression.functions[name].f(args);
      } else {
        throw new Error("No such function named " + _name);
      }
    };
    that.isPath = false;
    return that;
  };
  Expression.initControlCall = function(name, args) {
    var that;
    that = {};
    that.evaluate = function(roots, rootValueTypes, defaultRootName, database) {
      return Expression.controls[name].f(args, roots, rootValueTypes, defaultRootName, database);
    };
    that.isPath = false;
    return that;
  };
  Expression.initPath = function(property, forward) {
    var that, walkBackward, walkForward, _rootName, _segments;
    that = {};
    _rootName = null;
    _segments = [];
    walkForward = function(collection, database) {
      var a, backwardArraySegmentFn, forwardArraySegmentFn, i, segment, valueType, values, _ref;
      forwardArraySegmentFn = function(segment) {
        var a;
        a = [];
        collection.forEachValue(function(v) {
          return database.getObjects(v, segment.property).visit(function(v2) {
            return a.push(v2);
          });
        });
        return a;
      };
      backwardArraySegmentFn = function(segment) {
        var a;
        a = [];
        collection.forEachValue(function(v) {
          return database.getSubjects(v, segment.property).visit(function(v2) {
            return a.push(v2);
          });
        });
        return a;
      };
      for (i = 0, _ref = _segments.length; 0 <= _ref ? i < _ref : i > _ref; 0 <= _ref ? i++ : i--) {
        segment = _segments[i];
        if (segment.isMultiple) {
          a = [];
          if (segment.forward) {
            a = forwardArraySegmentFn(segment);
            property = database.getProperty(segment.property);
            valueType = property != null ? property.getValueType() : "text";
          } else {
            a = backwardArraySegmentFn(segment);
            valueType = "item";
          }
          collection = Expression.initCollection(a, valueType);
        } else {
          if (segment.forward) {
            values = database.getObjectsUnion(collection.getSet(), segment.property);
            property = database.getProperty(segment.property);
            valueType = property != null ? property.getValueType() : ("text", collection = Expression.initCollection(values, valueType));
          } else {
            values = database.getSubjectsUnion(collection.getSet(), segment.property);
            collection = Expression.initCollection(values, "item");
          }
        }
      }
      return collection;
    };
    walkBackward = function(collection, filter, database) {
      var a, backwardArraySegmentFn, forwardArraySegmentFn, i, segment, valueType, values, _ref;
      forwardArraySegmentFn = function(segment) {
        var a;
        a = [];
        collection.forEachValue(function(v) {
          return database.getSubjects(v, segment.property).visit(function(v2) {
            if (i > 0 || !(filter != null) || filter.contains(v2)) {
              return a.push(v2);
            }
          });
        });
        return a;
      };
      backwardArraySegmentFn = function(segment) {
        var a;
        a = [];
        collection.forEachValue(function(v) {
          return database.getObjects(v, segment.property).visit(function(v2) {
            if (i > 0 || !(filter != null) || filter.contains(v2)) {
              return a.push(v2);
            }
          });
        });
        return a;
      };
      if (filter instanceof Array) {
        filter = MITHGrid.Data.initSet(filter);
      }
      for (i = _ref = _segments.length - 1; _ref <= 0 ? i <= 0 : i >= 0; _ref <= 0 ? i++ : i--) {
        segment = _segments[i];
        if (segment.isMultiple) {
          a = [];
          if (segment.forward) {
            a = forwardArraySegmentFn(segment);
            property = database.getProperty(segment.property);
            valueType = property != null ? property.getValueType() : "text";
          } else {
            a = backwardArraySegmentFn(segment);
            valueType = "item";
          }
          collection = Expression.initCollection(a, valueType);
        } else if (segment.forward) {
          values = database.getSubjectsUnion(collection.getSet(), segment.property, null, i === 0 ? filter : null);
          collection = Expression.initCollection(values, "item");
        } else {
          values = database.getObjectsUnion(collection.getSet(), segment.property, null, i === 0 ? filter : null);
          property = database.getProperty(segment.property);
          valueType = property != null ? property.getValueType() : "text";
          collection = Expression.initCollection(values, valueType);
        }
      }
      return collection;
    };
    if (property != null) {
      _segments.push({
        property: property,
        forward: forward,
        isMultiple: false
      });
    }
    that.isPath = true;
    that.setRootName = function(rootName) {
      return _rootName = rootName;
    };
    that.appendSegment = function(property, hopOperator) {
      return _segments.push({
        property: property,
        forward: hopOperator[0] === ".",
        isMultiple: hopOperator.length > 1
      });
    };
    that.getSegment = function(index) {
      var segment;
      if (index < _segments.length) {
        segment = _segments[index];
        return {
          property: segment.property,
          forward: segment.forward,
          isMultiple: segment.isMultiple
        };
      } else {
        return null;
      }
    };
    that.getLastSegment = function() {
      return that.getSegment(_segments.length - 1);
    };
    that.getSegmentCount = function() {
      return _segments.length;
    };
    that.rangeBackward = function(from, to, filter, database) {
      var i, segment, set, valueType, _ref;
      set = MITHGrid.Data.initSet();
      valueType = "item";
      if (_segments.length > 0) {
        segment = _segments[_segments.length - 1];
        if (segment.forward) {
          database.getSubjectsInRange(segment.property, from, to, false, set, _segments.length === 1 ? filter : null);
        } else {
          throw new Error("Last path of segment must be forward");
        }
        for (i = _ref = _segments.length - 2; _ref <= 0 ? i <= 0 : i >= 0; _ref <= 0 ? i++ : i--) {
          segment = _segments[i];
          if (segment.forward) {
            set = database.getSubjectsUnion(set, segment.property, null, i === 0 ? filter : null);
            valueType = "item";
          } else {
            set = database.getObjectsUnion(set, segment.property, null, i === 0 ? filter : null);
            property = database.getPropertysegment.property;
            valueType = property != null ? property.getValueType() : "text";
          }
        }
      }
      return {
        valueType: valueType,
        values: set,
        count: set.size()
      };
    };
    that.evaluate = function(roots, rootValueTypes, defaultRootName, database) {
      var collection, root, rootName, valueType;
      rootName = _rootName != null ? _rootName : defaultRootName;
      valueType = rootValueTypes[rootName] != null ? rootValueTypes[rootName] : "text";
      collection = null;
      if (roots[rootName] != null) {
        root = roots[rootName];
        if (root.isSet || root instanceof Array) {
          collection = Expression.initCollection(root, valueType);
        } else {
          collection = Expression.initCollection([root], valueType);
        }
        return walkForward(collection, database);
      } else {
        throw new Error("No such variable called " + rootName);
      }
    };
    that.testExists = function(roots, rootValueTypes, defaultRootName, database) {
      return that.evaluate(roots, rootValueTypes, defaultRootName, database).size() > 0;
    };
    that.evaluateBackward = function(value, valueType, filter, database) {
      var collection;
      collection = Expression.initCollection([value], valueType);
      return walkBackward(collection, filter, database);
    };
    that.walkForward = function(values, valueType, database) {
      return walkForward(Expression.initCollection(values, valueType), database);
    };
    that.walkBackward = function(values, valueType, filter, database) {
      return walkBackward(Expression.initCollection(values, valueType), filter, database);
    };
    return that;
  };
  Expression.initParser = function() {
    var internalParse, that;
    that = {};
    internalParse = function(scanner, several) {
      var Scanner, expressions, makePosition, next, parseExpression, parseExpressionList, parseFactor, parsePath, parseSubExpression, parseTerm, r, roots, token, _i, _len;
      token = scanner.token();
      Scanner = Expression.initScanner;
      next = function() {
        scanner.next();
        return token = scanner.token();
      };
      parseFactor = function() {};
      parseTerm = function() {
        var operator, term, _ref;
        term = parseFactor();
        while ((token != null) && token.type === Scanner.OPERATOR && ((_ref = token.value) === "*" || _ref === "/")) {
          operator = token.value;
          next();
          term = Expression.initOperator(operator, [term, parseFactor()]);
        }
        return term;
      };
      parseSubExpression = function() {
        var operator, subExpression, _ref;
        subExpression = parseTerm();
        while ((token != null) && token.type === Scanner.OPERATOR && ((_ref = token.value) === "+" || _ref === "-")) {
          operator = token.value;
          next();
          subExpression = Expression.initOperator(operator, [subExpression, parseTerm()]);
        }
        return subExpression;
      };
      parseExpression = function() {
        var expression, operator, _ref;
        expression = parseSubExpression();
        while ((token != null) && token.type === Scanner.OPERATOR && ((_ref = token.value) === "=" || _ref === "<>" || _ref === "<" || _ref === ">" || _ref === "<=" || _ref === ">=")) {
          operator = token.value;
          next();
          expression = Expression.initOperator(operator, [expression, parseSubExpression()]);
        }
        return expression;
      };
      parseExpressionList = function() {
        var expressions;
        expressions = [parseExpression()];
        while ((token != null) && token.type === Scanner.DELIMITER && token.value === ",") {
          next();
          expressions.push(parseExpression());
        }
        return expressions;
      };
      makePosition = function() {
        if (token != null) {
          return token.start;
        } else {
          return scanner.index();
        }
      };
      parsePath = function() {
        var hopOperator, path;
        path = Expression.initPath();
        while ((token != null) && token.type === Scanner.PATH_OPERATOR) {
          hopOperator = token.value;
          next();
          if ((token != null) && token.type === Scanner.IDENTIFIER) {
            path.appendSegment(token.value, hopOperator);
            next();
          } else {
            throw new Error("Missing property ID at position " + makePosition());
          }
        }
        return path;
      };
      parseFactor = function() {
        var args, identifier, result;
        result = null;
        args = [];
        if (!(token != null)) {
          throw new Error("Missing factor at end of expression");
        }
        switch (token.type) {
          case Scanner.NUMBER:
            result = Expression.initConstant(token.value, "number");
            next();
            break;
          case Scanner.STRING:
            result = Expression.initConstant(token.value, "text");
            next();
            break;
          case Scanner.PATH_OPERATOR:
            result = parsePath();
            break;
          case Scanner.IDENTIFIER:
            identifier = token.value;
            next();
            if (Expression.controls[identifier] != null) {
              if ((token != null) && token.type === Scanner.DELIMITER && token.value === "(") {
                next();
                if ((token != null) && token.type === Scanner.DELIMITER && token.value === ")") {
                  args = [];
                } else {
                  args = parseExpressionList();
                }
                result = Expression.initControlCall(identifier, args);
                if ((token != null) && token.type === Scanner.DELIMITER && token.value === ")") {
                  next();
                } else {
                  throw new Error("Missing ) to end " + identifier + " at position " + makePosition());
                }
              } else {
                throw new Error("Missing ( to start " + identifier + " at position " + makePosition());
              }
            } else {
              if ((token != null) && token.type === Scanner.DELIMITER && token.value === "(") {
                next();
                if ((token != null) && token.type === Scanner.DELIMITER && token.value === ")") {
                  args = [];
                } else {
                  args = parseExpressionList();
                }
                result = Expression.initFunctionCall(identifier, args);
                if ((token != null) && token.type === Scanner.DELIMITER && token.value === ")") {
                  next();
                } else {
                  throw new Error("Missing ) after function call " + identifier + " at position " + makePosition());
                }
              } else {
                result = parsePath();
                result.setRootName(identifier);
              }
            }
            break;
          case Scanner.DELIMITER:
            if (token.value === "(") {
              next();
              result = parseExpression();
              if ((token != null) && token.type === Scanner.DELIMITER && token.value === ")") {
                next();
              } else {
                throw new Error("Missing ) at position " + makePosition());
              }
            } else {
              throw new Error("Unexpected text " + token.value + " at position " + makePosition());
            }
            break;
          default:
            throw new Error("Unexpected text " + token.value + " at position " + makePosition());
        }
        return result;
      };
      if (several) {
        roots = parseExpressionList();
        expressions = [];
        for (_i = 0, _len = roots.length; _i < _len; _i++) {
          r = roots[_i];
          expressions.push(Expression.initExpression(r));
        }
        return expressions;
      } else {
        return [Expression.initExpression(parseExpression())];
      }
    };
    that.parse = function(s, startIndex, results) {
      var scanner;
            if (startIndex != null) {
        startIndex;
      } else {
        startIndex = 0;
      };
            if (results != null) {
        results;
      } else {
        results = {};
      };
      scanner = Expression.initScanner(s, startIndex);
      try {
        return internalParse(scanner, false)[0];
      } finally {
        results.index = scanner.token() != null ? scanner.token().start : scanner.index();
      }
    };
    return that;
  };
  Expression.initScanner = function(text, startIndex) {
    var isDigit, that, _index, _maxIndex, _text, _token;
    that = {};
    _text = text + " ";
    _maxIndex = text.length;
    _index = startIndex;
    _token = null;
    isDigit = function(c) {
      return "0123456789".indexOf(c) >= 0;
    };
    that.token = function() {
      return _token;
    };
    that.index = function() {
      return _index;
    };
    that.next = function() {
      var c, c1, c2, i;
      _token = null;
      while (_index < _maxIndex && " \t\r\n".indexOf(_text.charAt(_index)) >= 0) {
        _index += 1;
      }
      if (_index < _maxIndex) {
        c1 = _text.charAt(_index);
        c2 = _text.charAt(_index + 1);
        if (".!".indexOf(c1) >= 0) {
          if (c2 === "@") {
            _token = {
              type: Expression.initScanner.PATH_OPERATOR,
              value: c1 + c2,
              start: _index,
              end: _index + 2
            };
            return _index += 2;
          } else {
            _token = {
              type: Expression.initScanner.PATH_OPERATOR,
              value: c1,
              start: _index,
              end: _index + 1
            };
            return _index += 1;
          }
        } else if ("<>".indexOf(c1) >= 0) {
          if ((c2 === "=") || ("<>".indexOf(c2) >= 0 && c1 !== c2)) {
            _token = {
              type: Expression.initScanner.OPERATOR,
              value: c1 + c2,
              start: _index,
              end: _index + 2
            };
            return _index += 2;
          } else {
            _token = {
              type: Expression.initScanner.OPERATOR,
              value: c1,
              start: _index,
              end: _index + 1
            };
            return _index += 1;
          }
        } else if ("+-*/=".indexOf(c1) >= 0) {
          _token = {
            type: Expression.initScanner.OPERATOR,
            value: c1,
            start: _index,
            end: _index + 1
          };
          return _index += 1;
        } else if ("()".indexOf(c1) >= 0) {
          _token = {
            type: Expression.initScanner.DELIMITER,
            value: c1,
            start: _index,
            end: _index + 1
          };
          return _index += 1;
        } else if ("\"'".indexOf(c1) >= 0) {
          i = _index + 1;
          while (i < _maxIndex) {
            if (_text.charAt(i) === c1 && _text.charAt(i - 1) !== "\\") {
              break;
            }
            i += 1;
          }
          if (i < _maxIndex) {
            _token = {
              type: Expression.initScanner.STRING,
              value: _text.substring(_index + 1, i).replace(/\\'/g, "'").replace(/\\"/g, '"'),
              start: _index,
              end: i + 1
            };
            return _index = i + 1;
          } else {
            throw new Error("Unterminated string starting at " + String(_index));
          }
        } else if (isDigit(c1)) {
          i = _index;
          while (i < _maxIndex && isDigit(_text.charAt(i))) {
            i += 1;
          }
          if (i < _maxIndex && _text.charAt(i) === ".") {
            i += 1;
            while (i < _maxIndex && isDigit(_text.charAt(i))) {
              i += 1;
            }
          }
          _token = {
            type: Expression.initScanner.NUMBER,
            value: parseFloat(_text.substring(_index, i)),
            start: _index,
            end: i
          };
          return _index = i;
        } else {
          i = _index;
          while (i < _maxIndex) {
            c = _text.charAt(i);
            if (!("(),.!@ \t".indexOf(c) < 0)) {
              break;
            }
            i += 1;
          }
          _token = {
            type: Expression.initScanner.IDENTIFIER,
            value: _text.substring(_index, i),
            start: _index,
            end: i
          };
          return _index = i;
        }
      }
    };
    that.next();
    return that;
  };
  Expression.initScanner.DELIMITER = 0;
  Expression.initScanner.NUMBER = 1;
  Expression.initScanner.STRING = 2;
  Expression.initScanner.IDENTIFIER = 3;
  Expression.initScanner.OPERATOR = 4;
  Expression.initScanner.PATH_OPERATOR = 5;
  Expression.functions = {};
  Expression.FunctionUtilities = {};
  Expression.FunctionUtilities.registerSimpleMappingFunction = function(name, f, valueType) {
    return Expression.functions[name] = {
      f: function(args) {
        var arg, evalArg, set, _i, _len;
        set = MITHGrid.Data.initSet();
        evalArg = function(arg) {
          return arg.forEachValue(function(v) {
            var v2;
            v2 = f(v);
            if (v2 != null) {
              return set.add(v2);
            }
          });
        };
        for (_i = 0, _len = args.length; _i < _len; _i++) {
          arg = args[_i];
          evalArg(arg);
        }
        return Expression.initCollection(set, valueType);
      }
    };
  };
}).call(this);
