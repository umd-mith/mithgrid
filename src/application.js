(function($, MITHGrid) {
    var Application = MITHGrid.namespace('Application');
    Application.initApp = function(klass, container, options) {
        var that = {
            presentation: {},
            dataStore: {},
            dataView: {}
        },
        onReady = [];

        that.ready = function(fn) {
            onReady.push(fn);
        };


        if (options.dataStores !== undefined) {
            $.each(options.dataStores,
            function(storeName, config) {
                var store;
				if(that.dataStore[storeName] === undefined) {
					store = MITHGrid.Data.initStore();
	                that.dataStore[storeName] = store;
	                store.addType('Item');
				}
				else {
					store = that.dataStore[storeName];
				}
                store.addProperty('label', {
                    valueType: 'text'
                });
                store.addProperty('type', {
                    valueType: 'text'
                });
                store.addProperty('id', {
                    valueType: 'text'
                });
                if (config.types !== undefined) {
                    $.each(config.types,
                    function(type, typeInfo) {
                        store.addType(type);
                    });
                }
                if (config.properties !== undefined) {
                    $.each(config.properties,
                    function(prop, propOptions) {
                        store.addProperty(prop, propOptions);
                    });
                }
            });
        }

        if (options.dataViews !== undefined) {
            $.each(options.dataViews,
            function(viewName, config) {
				var view = {},
				viewOptions = {
					dataStore: that.dataStore[config.dataStore],
					label: viewName
				};
				
				if(that.dataView[viewName] === undefined) {				
					if(config.collection !== undefined) {
						viewOptions.collection = config.collection;
					}
					if(config.types !== undefined) {
						viewOptions.types = config.types;
					}
					if(config.filters !== undefined) {
						viewOptions.filters = config.filters;
					}
	                view = MITHGrid.Data.initView(viewOptions);
	                that.dataView[viewName] = view;
				}
				else {
					view = that.dataView[viewName];
				}
            });
        }

		if (options.viewSetup !== undefined) {
			if($.isFunction(options.viewSetup)) {
				that.ready(function() { options.viewSetup($(container)); });
			}
			else {
				that.ready(function() { $(container).append(options.viewSetup); });
			}
		}

        if (options.presentations !== undefined) {
            that.ready(function() {
                $.each(options.presentations,
                function(pName, config) {
                    var poptions = $.extend(true, {}, config),
                    pcontainer = $('#' + $(container).attr('id') + ' > ' + config.container),
                    presentation;
                    if ($.isArray(container)) {
                        pcontainer = pcontainer[0];
                    }
                    poptions.dataView = that.dataView[config.dataView];
					poptions.application = that;
					
                    presentation = config.type(pcontainer, poptions);
                    that.presentation[pName] = presentation;
                    presentation.selfRender();
                });
            });
        }

        if (options.plugins !== undefined) {
            that.ready(function() {
                $.each(options.plugins,
                function(idx, pconfig) {
                    var plugin = pconfig.type(pconfig);
                    if (plugin !== undefined) {
                        if (pconfig.dataView !== undefined) {
                            // hook plugin up with dataView requested by app configuration
                            plugin.dataView = that.dataView[pconfig.dataView];
                            // add
                            $.each(plugin.getTypes(),
                            function(idx, t) {
                                plugin.dataView.addType(t);
                            });
                            $.each(plugin.getProperties(),
                            function(idx, p) {
                                plugin.dataView.addProperty(p.label, p);
                            });
                        }
                        $.each(plugin.getPresentations(),
                        function(idx, config) {
                            var options = $.extend(true, {},
                            config.options),
                            pcontainer = $("#" + $(container).attr('id') + ' > ' + config.container),
                            presentation;

                            if ($.isArray(container)) {
                                pcontainer = pcontainer[0];
                            }
                            if (config.dataView !== undefined) {
                                options.store = that.dataView[config.dataView];
                            }
                            else if (pconfig.dataView !== undefined) {
                                options.store = that.dataView[pconfig.dataView];
                            }
							options.application = that;
                            presentation = config.type(pcontainer, options);
                            plugin.presentation[config.label] = presentation;
                            presentation.selfRender();
                        });
                    }
                });
            });
        }

        that.run = function() {
            $(document).ready(function() {
                $.each(onReady,
                function(idx, fn) {
                    fn();
                });
                that.ready = function(fn) {
                    setTimeout(fn, 0);
                };
            });
        };

        return that;
    };
} (jQuery, MITHGrid));
