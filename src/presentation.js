(function($, MITHGrid) {
    MITHGrid.namespace('Presentation');

    MITHGrid.Presentation.initView = function(type, container, options) {
        var that = fluid.initView("MITHGrid.Presentation." + type, container, options),
        renderings = {};
        options = that.options;

        $(container).empty();

        //		$("<div id='" + my_id + "-body'></div>").appendTo($(container));
        //		that.body_container = $('#' + my_id + '-body');


        that.renderingFor = function(id) {
            return renderings[id];
        };

        that.renderItems = function(model, items) {
            var n = items.length,
            f;

			f = function(start) {
                var end,
                i,
				id,
				hasItem,
                lens;

                if (start < n) {
                    end = n;
                    if (n > 200) {
                        end = start + parseInt(Math.sqrt(n), 10) + 1;
                        if (end > n) {
                            end = n;
                        }
                    }
                    for (i = start; i < end; i += 1) {
                        id = items[i];
                        hasItem = model.contains(id);
                        if (!hasItem) {
                            // item was removed
                            if (renderings[id]) {
                                // we need to remove it from the display
                                // .remove() should not make changes in the model
                                renderings[id].remove();
								delete renderings[id];
                            }
                        }
                        else if (renderings[id]) {
                            renderings[id].update(model.getItem(id));
                        }
                        else {
                            lens = that.getLens(model.getItem(id));
                            if (lens) {
                                renderings[id] = lens.render(container, that, model, items[i]);
                            }
                        }
                    }

                    that.finishDisplayUpdate();
                    setTimeout(function() {
                        f(end);
                    },
                    0);
                }
            };
            that.startDisplayUpdate();
            f(0);
        };

        that.eventModelChange = that.renderItems;

        that.startDisplayUpdate = function() {
            $(container).empty();
        };

        that.finishDisplayUpdate = function() {
            $("<div class='clear'></div>").appendTo($(container));
        };

        that.selfRender = function() {
            /* do nothing -- needs to be implemented in subclass */
            that.renderItems(that.options.source, that.options.source.items());
        };

        that.dataView = that.options.source;
        that.options.source.registerView(that);
        return that;
    };
} (jQuery, MITHGrid));