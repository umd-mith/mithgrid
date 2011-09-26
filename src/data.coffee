(function() {
  var Data;
  var __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  };
  Data = MITHGrid.namespace('Data');
  Data.initSet = function(values) {
    var count, i, items, items_list, recalc_items, that, _i, _len;
    that = {};
    items = {};
    count = 0;
    recalc_items = true;
    items_list = [];
    that.isSet = true;
    that.items = function() {
      var i;
      if (recalc_items) {
        items_list = [];
        for (i in items) {
          if (typeof i === "string" && items[i] === true) {
            items_list.push(i);
          }
        }
      }
      return items_list;
    };
    that.add = function(item) {
      if (!(items[item] != null)) {
        items[item] = true;
        recalc_items = true;
        return count += 1;
      }
    };
    that.remove = function(item) {
      if (items[item] != null) {
        delete items[item];
        recalc_items = true;
        return count -= 1;
      }
    };
    that.visit = function(fn) {
      var o, _results;
      _results = [];
      for (o in items) {
        if (fn(o) === true) {
          break;
        }
      }
      return _results;
    };
    that.contains = function(o) {
      return items[o] != null;
    };
    that.size = function() {
      if (recalc_items) {
        return that.items().length;
      } else {
        return items_list.length;
      }
    };
    if (values instanceof Array) {
      for (_i = 0, _len = values.length; _i < _len; _i++) {
        i = values[_i];
        that.add(i);
      }
    }
    return that;
  };
  Data.initType = function(t) {
    var that;
    return that = {
      name: t,
      custom: {}
    };
  };
  Data.initProperty = function(p) {
    var that;
    return that = {
      name: p,
      getValueType: function() {
        var _ref;
        return (_ref = that.valueType) != null ? _ref : 'text';
      }
    };
  };
  Data.initStore = function(options) {
    var getUnion, indexFillSet, indexPut, ops, properties, quiesc_events, set, spo, that, types;
    quiesc_events = false;
    set = Data.initSet();
    types = {};
    properties = {};
    spo = {};
    ops = {};
    indexPut = function(index, x, y, z) {
      var array, counts, hash;
      hash = index[x];
      if (!(hash != null)) {
        hash = {
          values: {},
          counts: {}
        };
        index[x] = hash;
      }
      array = hash.values[y];
      counts = hash.counts[y];
      if (!(array != null)) {
        array = [];
        hash.values[y] = array;
      }
      if (!(counts != null)) {
        counts = {};
        hash.counts[y] = counts;
      } else {
        if (__indexOf.call(array, z) >= 0) {
          counts[z] += 1;
          return;
        }
      }
      array.push(z);
      return counts[z] = 1;
    };
    indexFillSet = function(index, x, y, set, filter) {
      var array, hash, z, _i, _j, _len, _len2, _results, _results2;
      hash = index[x];
      if (hash != null) {
        array = hash.values[y];
        if (array != null) {
          if (filter != null) {
            _results = [];
            for (_i = 0, _len = array.length; _i < _len; _i++) {
              z = array[_i];
              _results.push(filter.contains(z) ? set.add(z) : void 0);
            }
            return _results;
          } else {
            _results2 = [];
            for (_j = 0, _len2 = array.length; _j < _len2; _j++) {
              z = array[_j];
              _results2.push(set.add(z));
            }
            return _results2;
          }
        }
      }
    };
    getUnion = function(index, xSet, y, set, filter) {
      if (!(set != null)) {
        set = Data.initSet();
      }
      xSet.visit(function(x) {
        return indexFillSet(index, x, y, set, filter);
      });
      return set;
    };
        if (options != null) {
      options;
    } else {
      options = {};
    };
    that = fluid.initView("MITHGrid.Data.initStore", $(window), options);
    that.items = set.items;
    that.contains = set.contains;
    that.addProperty = function(nom, options) {
      var prop;
      prop = Data.initProperty(nom);
      if ((options != null ? options.valueType : void 0) != null) {
        prop.valueType = options.valueType;
        properties[nom] = prop;
      }
      return prop;
    };
    that.getProperty = function(nom) {
      var _ref;
      return (_ref = properties[nom]) != null ? _ref : Data.initProperty(nom);
    };
    that.addType = function(nom, options) {
      var type;
      type = Data.initType(nom);
      types[nom] = type;
      return type;
    };
    that.getType = function(nom) {
      var _ref;
      return (_ref = types[nom]) != null ? _ref : Data.initType(nom);
    };
    that.getItem = function(id) {
      var _ref, _ref2;
      return (_ref = (_ref2 = spo[id]) != null ? _ref2.values : void 0) != null ? _ref : {};
    };
    that.getItems = function(ids) {
      if (!$.isArray(ids)) {
        return [that.getItem(ids)];
      }
      return $.map(ids, function(id, idx) {
        return tht.getItem(id);
      });
    };
    that.fetchData = function(uri) {
      return $.ajax({
        url: uri,
        dataType: "json",
        success: function(data, textStatus) {
          return that.loadData(data);
        }
      });
    };
    that.updateItems = function(items) {
      var chunk_size, f, id_list, indexPutFn, indexRemove, indexRemoveFn, n, updateItem;
      id_list = [];
      indexRemove = function(index, x, y, z) {
        var array, counts, hash, i;
        hash = index[x];
        if (!(hash != null)) {
          return;
        }
        array = hash.values[y];
        counts = hash.counts[y];
        if (!(array != null) || !(counts != null)) {
          return;
        }
        counts[z] -= 1;
        if (counts[z] < 1) {
          i = $.inArray(z, array);
          if (i === 0) {
            array = array.slice(1, array.length);
          } else if (i === array.length - 1) {
            array = array.slice(0, i);
          } else if (i > 0) {
            array = array.slice(0, i).concat(array.slice(i + 1, array.length));
          }
          return hash.values[y] = array;
        }
      };
      indexPutFn = function(s, p, o) {
        indexPut(spo, s, p, o);
        return indexPut(ops, o, p, s);
      };
      indexRemoveFn = function(s, p, o) {
        indexRemove(spo, s, p, o);
        return indexRemove(ops, o, p, s);
      };
      updateItem = function(entry, indexPutFn, indexRemoveFn) {
        var changed, id, itemListIdentical, items, old_item, p, putValues, removeValues, s, type;
        id = entry.id;
        type = entry.type;
        changed = false;
        itemListIdentical = function(to, from) {
          var i, items_same, _ref;
          items_same = true;
          if (to.length !== from.length) {
            return false;
          }
          for (i = 0, _ref = to.length; 0 <= _ref ? i < _ref : i > _ref; 0 <= _ref ? i++ : i--) {
            if (to[i] !== from[i]) {
              items_same = false;
            }
          }
          return items_same;
        };
        removeValues = function(id, p, list) {
          var o, _i, _len, _results;
          _results = [];
          for (_i = 0, _len = list.length; _i < _len; _i++) {
            o = list[_i];
            _results.push(indexRemoveFn(id, p, o));
          }
          return _results;
        };
        putValues = function(id, p, list) {
          var o, _i, _len, _results;
          _results = [];
          for (_i = 0, _len = list.length; _i < _len; _i++) {
            o = list[_i];
            _results.push(indexPutFn(id, p, o));
          }
          return _results;
        };
        if ($.isArray(id)) {
          id = id[0];
        }
        if ($.isArray(type)) {
          type = type[0];
        }
        old_item = that.getItem(id);
        for (p in entry) {
          items = entry[p];
          if (typeof p !== "string" || (p === "id" || p === "type")) {
            continue;
          }
          if (!$.isArray(items)) {
            items = [items];
          }
          s = items.length;
          if (!(old_item[p] != null)) {
            putValues(id, p, items);
            changed = true;
          } else if (!itemListIdentical(items, old_item[p])) {
            changed = true;
            removeValues(id, p, old_item[p]);
            putValues(id, p, items);
          }
        }
        return changed;
      };
      that.events.onBeforeUpdating.fire(that);
      n = items.length;
      chunk_size = parseInt(n / 100, 10);
      if (chunk_size > 200) {
        chunk_size = 200;
      }
      if (chunk_size < 1) {
        chunk_size = 1;
      }
      f = function(start) {
        var end, entry, i;
        end = start + chunk_size;
        if (end > n) {
          end = n;
        }
        for (i = start; start <= end ? i < end : i > end; start <= end ? i++ : i--) {
          entry = items[i];
          if (typeof entry === "object" && updateItem(entry, indexPutFn, indexRemoveFn)) {
            id_list.push(entry.id);
          }
        }
        if (end < n) {
          return setTimeout(function() {
            return f(end);
          }, 0);
        } else {
          that.events.onAfterUpdating.fire(that);
          return that.events.onModelChange.fire(that, id_list);
        }
      };
      return f(0);
    };
    return that.loadItems = function(items, endFn) {
      var id_list, indexFn, loadItem;
      id_list = [];
      indexFn = function(s, p, o) {
        indexPut(spo, s, p, o);
        return indexPut(ops, o, p, s);
      };
      return loadItem = function(item, indexFN) {
        var id, type;
        if (!(item.id != null)) {
          throw MITHGrid.error("Item entry has no id: ", item);
        }
        if (!(item.type != null)) {
          throw MITHGrid.error("Item entry has no type: ", item);
        }
        id = item.id;
        type = item.type;
        if ($.isArray(id)) {
          id = id[0];
        }
        if ($.isArray(type)) {
          type = type[0];
        }
        set.add(id);
        id_list.push(id);
        indexFn(id, "type", type);
        return indexFn(id, "id", id);
      };
    };
  };
}).call(this);
