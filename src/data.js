(function($, MITHGrid) {
	var Data = MITHGrid.namespace('Data'),
	sources = { },
	views = { };
	
    Data.initSet = function(values) {
        var that = {},
        items = {},
        count = 0,
        recalc_items = true,
        items_list = [];

        that.isSet = true;

        that.items = function() {
			var i;
            if (recalc_items) {
                items_list = [];
                for (i in items) {
                    if (typeof(i) === "string" && items[i] === true) {
                        items_list.push(i);
                    }
                }
            }
            return items_list;
        };

        that.add = function(item) {
            if (items[item] === undefined) {
                items[item] = true;
                recalc_items = true;
                count += 1;
            }
        };

        that.remove = function(item) {
            if (items[item] !== undefined) {
                delete items[item];
                recalc_items = true;
                count -= 1;
            }
        };

        that.visit = function(fn) {
            var o;
            for (o in items) {
                if (fn(o) === true) {
                    break;
                }
            }
        };

        that.contains = function(o) {
            return (items[o] !== undefined);
        };

        that.size = function() {
            if (recalc_items) {
                return that.items().length;
            }
            else {
                return items_list.length;
            }
        };

        if (values instanceof Array) {
            $(values).each(function(idx, i) {
                that.add(i);
            });
        }

        return that;
    };

    Data.Type = function(t) {
        var that = {};

        that.name = t;
        that.custom = {};

        return that;
    };

    Data.Property = function(p) {
        var that = {};

        that.name = p;

        that.getValueType = function() {
            return that.valueType || 'text';
        };

        return that;
    };

    Data.Source = function(options) {
        var that,
        prop,
        quiesc_events = false,
        set = Data.initSet(),
        types = {},
        properties = {},
        spo = {},
        ops = {},
		indexPut = function(index, x, y, z) {
            var hash = index[x],
            array,
            counts,
            i,
            n;

            if (!hash) {
                hash = {
                    values: {},
                    counts: {}
                };
                index[x] = hash;
            }

            array = hash.values[y];
            counts = hash.counts[y];

            if (!array) {
                array = [];
                hash.values[y] = array;
            }
            if (!counts) {
                counts = {};
                hash.counts[y] = counts;
            }
            else {
                if ($.inArray(z, array) !== -1) {
                    counts[z] += 1;
                    return;
                }
            }
            array.push(z);
            counts[z] = 1;
        },
		indexFillSet = function(index, x, y, set, filter) {
            var hash = index[x],
            array,
            i,
            n,
            z;
            if (hash) {
                array = hash.values[y];
                if (array) {
                    if (filter) {
                        for (i = 0, n = array.length; i < n; i += 1) {
                            z = array[i];
                            if (filter.contains(z)) {
                                set.add(z);
                            }
                        }
                    }
                    else {
                        for (i = 0, n = array.length; i < n; i += 1) {
                            set.add(array[i]);
                        }
                    }
                }
            }
        },
		getUnion = function(index, xSet, y, set, filter) {
            if (!set) {
                set = Data.initSet();
            }

            xSet.visit(function(x) {
                indexFillSet(index, x, y, set, filter);
            });
            return set;
        };

        if (sources[options.source] !== undefined) {
            return sources[options.source];
        }
        that = fluid.initView("MITHGrid.Data.Source", $(window), options);
        sources[options.source] = that;

        that.source = options.source;

        that.items = set.items;

		that.contains = set.contains;

        that.addProperty = function(nom, options) {
            var prop = Data.Property(nom);
			if( options !== undefined && options.valueType !== undefined ) {
				prop.valueType = options.valueType;
			}
            properties[nom] = prop;
        };

		that.getProperty = function(nom) {
			if(properties[nom] === undefined) {
				return Data.Property(nom);
			}
			else {
				return properties[nom];
			}
		};

        that.addType = function(nom, options) {
            var type = Data.Type(nom);
            types[nom] = type;
        };

		that.getType = function(nom) {
			if(types[nom] === undefined) {
				return Data.Type(nom);
			}
			else {
				return types[nom];
			}
		};

        /* In MITHGrid, the app and plugins would populate the types and properties based on what they need */
        /* For us, we have:
		 * View
		 * Transition
		 * TansitionCondition (params, param, ...)
		 * GeneralAction
		 * GeneralStructural
		 */

        /*
		*** Application
		* id:
		* view: list of item ids pointing to View items
		* initialization-action: list of item ids pointing to GeneralAction items
		*
		*** View type has the following properties
		* id: unique id in the system
		* transition: list of item ids
		* label: (unique name for the application)
		* initialization-action: list of item ids pointing to GeneralAction items
		* position-x:, position-y: - points on drawing board
		*
		*** Transition type
		* id
		* transitions-to: item id pointing to target view
		* condition: list of parameters expected
		* action: list of item ids pointing to GeneralAction items
		* path: info on path between views
		*
		***
		*/



        that.getItem = function(id) {
            if (spo[id] !== undefined) { //id in that.spo) {
                return spo[id].values;
            }
            return {};
        };

        that.getItems = function(ids) {
            if (!$.isArray(ids)) {
                return [that.getItem(ids)];
            }

            return $.map(ids,
            function(id, idx) {
                return that.getItem(id);
            });
        };

        that.fetchData = function(uri) {
            $.ajax({
                url: uri,
                dataType: "json",
                success: function(data, textStatus) {
                    that.loadData(data);
                }
            });
        };

        that.updateItems = function(items) {
            var indexTriple,
            n,
            chunk_size,
            f,
            id_list = [],
            entry,
			indexRemove = function(index, x, y, z) {
                var hash = index[x],
                array,
                counts,
                i,
                n;

                if (!hash) {
                    return;
                    // nothing to remove
                    //hash = { values: { }, counts: { }};
                    //index[x] = hash;
                }

                array = hash.values[y];
                counts = hash.counts[y];
                if (!array) {
                    return;
                    // nothing to remove
                    //		array = new Array();
                    //		hash.values[y] = array;
                }
                if (!counts) {
                    return;
                    // nothing to remove
                    //		counts = { };
                    //		hash.counts[y] = counts;
                }
                // we need to remove the old z values
                counts[z] -= 1;
                if (counts[z] < 1) {
                    i = $.inArray(z, array);
                    if (i === 0) {
                        array = array.slice(1);
                    }
                    else if (i === array.length - 1) {
                        array = array.slice(0, i);
                    }
                    else if ( i > 0 ) {
                        array = array.slice(0, i).concat(array.slice(i + 1));
                    }
                    hash.values[y] = array;
                }
            },
			indexPutFn = function(s, p, o) {
                indexPut(spo, s, p, o);
                indexPut(ops, o, p, s);
            },
            indexRemoveFn = function(s, p, o) {
                indexRemove(spo, s, p, o);
                indexRemove(ops, o, p, s);
            },
            updateItem = function(entry, indexPutFn, indexRemoveFn) {
                // we only update things that are different from the old_item
                // we also only update properties that are in the new item
                // if anything is changed, we return true
                //   otherwise, we return false
                var old_item,
				p,
				items,
				s,
                id = entry.id,
                type = entry.type,
                changed = false,
				itemListIdentical = function(to, from) {
				    var items_same = true;
				    if (to.length !== from.length) {
				        return false;
				    }
				    $.each(to,
				    function(idx, i) {
				        if (i !== from[idx]) {
				            items_same = false;
				        }
				    });
				    return items_same;
				},
				removeValues = function(id, p, list) {
					$.each(list, function(idx, o) {
						indexRemoveFn(id, p, o);
					});
				},
				putValues = function(id, p, list) {
					$.each(list, function(idx, o) {
						indexPutFn(id, p, o);
					});
				};
				
				if ($.isArray(id)) { id = id[0]; }
                if ($.isArray(type)) { type = type[0]; }

                old_item = that.getItem(id);

                for (p in entry) {
                    if (typeof(p) !== "string" || p === "id" || p === "type") {
                        continue;
                    }
                    // if entry[p] and old_item[p] have the same members in the same order, then
                    // we do nothing
                    items = entry[p];
                    if (!$.isArray(items)) {
                        items = [items];
                    }
                    s = items.length;
                    if (old_item[p] !== undefined) {
						if(itemListIdentical(items, old_item[p])) {
							continue;
						}
						changed = true;
						removeValues(id, p, old_item[p]);
                    }
					putValues(id, p, items);
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
			    var end,
			    i;

			    end = start + chunk_size;
			    if (end > n) {
			        end = n;
			    }

			    for (i = start; i < end; i += 1) {
			        entry = items[i];
			        if (typeof(entry) === "object") {
			            if (updateItem(entry, indexPutFn, indexRemoveFn)) {
			                id_list.push(entry.id);
			            }
			        }
			    }

			    if (end < n) {
			        setTimeout(function() {
			            f(end);
			        },
			        0);
			    }
			    else {
			        setTimeout(function() {
			            that.events.onAfterUpdating.fire(that);
			            setTimeout(function() {
			                that.events.onModelChange.fire(that, id_list);
			            },
			            0);
			        },
			        0);
			    }
			};
			f(0);
        };

        that.loadItems = function(items, endFn) {
            var indexTriple,
            entry,
            n,
			chunk_size,
            id_list = [],
            f,
			indexFn = function(s, p, o) {
                indexPut(spo, s, p, o);
                indexPut(ops, o, p, s);
            },
            loadItem = function(item, indexFN) {
                var id,
                type,
                p,
                i,
				v,
                n;

                if (item.id === undefined) {
                    throw MITHGrid.error("Item entry has no id: ", item);
                }
                if (item.type === undefined) {
                    throw MITHGrid.error("Item entry has no type: ", item);
                }

                id = item.id;
                type = item.type;

                if ($.isArray(id)) { id = id[0]; }
                if ($.isArray(type)) { type = type[0]; }

                set.add(id);
                id_list.push(id);

                indexFn(id, "type", type);
                indexFn(id, "id", id);

                for (p in item) {
                    if (typeof(p) !== "string") {
                        continue;
                    }

                    if (p !== "id" && p !== "type") {
                        v = item[p];
                        if ($.isArray(v)) {
                            for (i = 0, n = v.length; i < n; i += 1) {
                                indexFn(id, p, v[i]);
                            }
                        }
                        else if (v !== undefined && v !== null) {
                            indexFn(id, p, v);
                        }
                    }
                }
            };

            that.events.onBeforeLoading.fire(that);
			n = items.length;
			if ($.isFunction(endFn)) {
			    chunk_size = parseInt(n / 100, 10);
			    if (chunk_size > 200) {
			        chunk_size = 200;
			    }
			    if (chunk_size < 1) {
			        chunk_size = 1;
			    }
			}
			 else {
			    chunk_size = n;
			}
			f = function(start) {
			    var end,
			    i;

			    end = start + chunk_size;
			    if (end > n) {
			        end = n;
			    }

			    for (i = start; i < end; i += 1) {
			        entry = items[i];
			        if (typeof(entry) === "object") {
			            loadItem(entry);
			        }
			    }

			    if (end < n) {
			        setTimeout(function() {
			            f(end);
			        },
			        0);
			    }
			    else {
			        setTimeout(function() {
			            that.events.onAfterLoading.fire(that);
			            setTimeout(function() {
			                that.events.onModelChange.fire(that, id_list);
			                if ($.isFunction(endFn)) {
			                    endFn();
			                }
			            },
			            0);
			        },
			        0);
			    }
			};
			f(0);
        };

		that.prepare = function(expressions) {
		    var parsed = $.map(expressions,
		    function(ex) {
		        return MITHGrid.Expression.Parser().parse(ex);
		    });

			return {
			    evaluate: function(id) {
					var values = [];
					$.each(parsed,
					function(idx, ex) {
						var items = ex.evaluateOnItem(id, that);
						values = values.concat(items.values.items());
					});
			        return values;
			    }
			};
		};

        that.getObjectsUnion = function(subjects, p, set, filter) {
            return getUnion(spo, subjects, p, set, filter);
        };

        that.getSubjectsUnion = function(objects, p, set, filter) {
            return getUnion(ops, objects, p, set, filter);
        };

        return that;
    };

    Data.View = function(options) {
        var that,
        set = Data.initSet(),
		filterItems = function(endFn) {
            var id,
            fres,
            ids,
            n,
            chunk_size,
            f;

            set = Data.initSet();

            that.items = set.items;
            that.size = set.size;
			that.contains = set.contains;
            ids = that.dataSource.items();
            n = ids.length;
            if (n === 0) {
                endFn();
                return;
            }
            chunk_size = parseInt(n / 100, 10);
            if (chunk_size > 200) {
                chunk_size = 200;
            }
            if (chunk_size < 1) {
                chunk_size = 1;
            }

            f = function(start) {
                var i,
				free,
                end;
                end = start + chunk_size;
                if (end > n) {
                    end = n;
                }
                for (i = start; i < end; i += 1) {
                    id = ids[i];
                    free = that.events.onFilterItem.fire(that.dataSource, id);
                    if (free !== false) {
                        set.add(id);
                    }
                }
                if (end < n) {
                    setTimeout(function() {
                        f(end);
                    },
                    0);
                }
                else {
                    if (endFn) {
                        setTimeout(endFn, 0);
                    }
                }
            };
            f(0);
        };

        if(views[options.label] !== undefined) {
            return views[options.label];
        }

        that = fluid.initView("MITHGrid.Data.View", $(window), options);

        that.registerFilter = function(ob) {
            that.events.onFilterItem.addListener(function(x, y) {
                return ob.eventFilterItem(x, y);
            });
            that.events.onModelChange.addListener(function(m, i) {
                ob.eventModelChange(m, i);
            });
            ob.events.onFilterChange.addListener(that.eventFilterChange);
        };

        that.registerView = function(ob) {
            that.events.onModelChange.addListener(function(m, i) {
                ob.eventModelChange(m, i);
            });
            filterItems(function() {
                ob.eventModelChange(that, that.items());
            });
        };

        that.items = set.items;
        that.size = set.size;
		that.contains = set.contains;

		if(options.collection !== undefined) {
			that.registerFilter({
				eventFilterItem: options.collection,
				eventModelChange: function(x, y) { },
				events: {
					onFilterChange: {
						addListener: function(x) { }
					}
				}
			});
		}

        that.eventModelChange = function(model, items) {
			var allowed_set = Data.initSet(that.items());
            filterItems(function() {
				var changed_set = Data.initSet(),
				i, n;
				$.each(that.items(), function(idx, id) { allowed_set.add(id); });
				n = items.length;
				for(i = 0; i < n; i += 1) {
					if(allowed_set.contains(items[i])) {
						changed_set.add(items[i]);
					}
				}
				if(changed_set.size() > 0) {
                    that.events.onModelChange.fire(that, changed_set.items());
				}
            });
        };

        that.eventFilterChange = that.eventModelChange;

        that.dataSource = Data.Source({
            source: options.source
        });

		// these mappings allow a data View to stand in for a data Source
        that.getItems = that.dataSource.getItems;
        that.getItem = that.dataSource.getItem;
		that.fetchData = that.dataSource.fetchData;
        that.updateItems = that.dataSource.updateItems;
		that.loadItems = that.dataSource.loadItems;
        that.prepare = that.dataSource.prepare;
		that.addType = that.dataSource.addType;
		that.getType = that.dataSource.getType;
		that.addProperty = that.dataSource.addProperty;
		that.getProperty = that.dataSource.getProperty;
		that.getObjectsUnion = that.dataSource.getObjectsUnion;
		that.getSubjectsUnion = that.dataSource.getSubjectsUnion;
		
        that.dataSource.events.onModelChange.addListener(that.eventModelChange);

        return that;
    };
}(jQuery, MITHGrid));