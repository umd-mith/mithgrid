(function($, MITHGrid) {
    var Application = MITHGrid.namespace('Application');
    Application.initApp = function(klass, container, options) {
        var that = {
            presentation: {},
            dataSource: {},
            dataView: {}
        },
        onReady = [];

        that.ready = function(fn) {
            onReady.push(fn);
        };


        if (options.dataSources !== undefined) {
            $.each(options.dataSources,
            function(idx, config) {
                var store = MITHGrid.Data.Source({
                    source: config.label
                });
                that.dataSource[config.label] = store;
                store.addType('Item');
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
                    function(idx, type) {
                        store.addType(type.label);
                    });
                }
                if (config.properties !== undefined) {
                    $.each(config.properties,
                    function(idx, property) {
                        store.addProperty(property.label, property);
                    });
                }
            });
        }

        if (options.dataViews !== undefined) {
            $.each(options.dataViews,
            function(idx, config) {
				var view = {},
				viewOptions = {
					source: config.dataSource,
					label: config.label
				};
				
				if(config.collection !== undefined) {
					viewOptions.collection = config.collection;
				}
                view = MITHGrid.Data.View(viewOptions);
                that.dataView[config.label] = view;
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
                function(idx, config) {
                    var options = $.extend(true, {},
                    config.options),
                    container = $(config.container),
                    presentation;

                    if ($.isArray(container)) {
                        container = container[0];
                    }
                    options.source = that.dataView[config.dataView];
					options.application = that;
					
                    presentation = config.type(container, options);
                    that.presentation[config.label] = presentation;
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
                            container = $(config.container),
                            presentation;

                            if ($.isArray(container)) {
                                container = container[0];
                            }
                            if (config.dataView !== undefined) {
                                options.source = that.dataView[config.dataView];
                            }
                            else if (pconfig.dataView !== undefined) {
                                options.source = that.dataView[pconfig.dataView];
                            }
							options.application = that;
                            presentation = config.type(container, options);
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
