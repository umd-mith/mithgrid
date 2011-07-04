(function($, MITHGrid) {
    MITHGrid.Application = function(options) {
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
                var view = MITHGrid.Data.View({
                    source: config.dataSource,
                    label: config.label
                });
                that.dataView[config.label] = view;
            });
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
						if(pconfig.dataView !== undefined) {
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
								config.options),
							container = $(config.container),
							presentation;
							
							if ($.isArray(container)) {
								container = container[0];
							}
							if(config.dataView !== undefined) {
								options.source = that.dataView[config.dataView];
							}
							else if(pconfig.dataView !== undefined) {
								options.source = that.dataView[pconfig.dataView];
							}
							
							presentation = config.type(container, options);
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
