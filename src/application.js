(function($, MITHGrid) {
    MITHGrid.Application = function(options) {
        var that = {
            presentation: {},
            dataSource: {},
            dataView: {}
        };

        var onReady = [];

        that.ready = function(fn) {
            onReady.push(fn);
        };


        if ('dataSources' in options) {
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
                if ('types' in config) {
                    $.each(config.types,
                    function(idx, type) {
                        store.addType(type.label);
                    });
                }
                if ('properties' in config) {
                    $.each(config.properties,
                    function(idx, property) {
                        store.addProperty(property.label, property);
                    });
                }
            });
        }

        if ('dataViews' in options) {
            $.each(options.dataViews,
            function(idx, config) {
                var view = MITHGrid.Data.View({
                    source: config.dataSource,
                    label: config.label
                });
                that.dataView[config.label] = view;
            });
        }

        if ('presentations' in options) {
            that.ready(function() {
                $.each(options.presentations,
                function(idx, config) {
                    var options = $.extend(true, {},
                    config.options);
                    var container = $(config.container);
                    if ($.isArray(container)) {
                        container = container[0];
                    }
                    options.source = that.dataView[config.dataView];

                    var presentation = config.type(container, options);
                    that.presentation[config.label] = presentation;
                    presentation.selfRender();
                });
            });
        }

        if ('plugins' in options) {
            that.ready(function() {
                $.each(options.plugins,
                function(idx, pconfig) {
                    var plugin = pconfig.type(pconfig);
                    if (plugin !== undefined) {
						if('dataView' in pconfig) {
							// hook plugin up with dataView requested by app configuration
							plugin.dataView = that.dataView[pconfig.dataView];
							// add 
							$.each(plugin.types(), function(idx, t) {
								plugin.dataView.addType(t);
							});
							$.each(plugin.properties(), function(idx, p) {
								plugin.dataView.addProperty(p.label, p);
							});
						}
						$.each(plugin.presentations(),
						function(idx, config) {
							var options = $.extend(true, {},
								config.options);
							var container = $(config.container);
							if ($.isArray(container)) {
								container = container[0];
							}
							if("dataView" in config) {
								options.source = that.dataView[config.dataView];
							}
							else if("dataView" in pconfig) {
								options.source = that.dataView[pconfig.dataView];
							}
							
							var presentation = config.type(container, options);
							plugin.presentation[config.label] = presentation;
							presentation.selfRender();
						});
					}
                });
            });
        }

        $(document).ready(function() {
            $.each(onReady,
            function(idx, fn) {
                fn();
            });
            that.ready = function(fn) {
                setTimeout(fn, 0);
            };
        });

        return that;
    };
}(jQuery, MITHGrid));
