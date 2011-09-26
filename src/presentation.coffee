(function() {
  MITHGrid.namespace('Presentation');
  MITHGrid.Presentation.initPresentation = function(type, container, options) {
    var lenses, renderings, that;
    that = fluid.initView("MITHGrid.Presentation." + type, container, options);
    renderings = {};
    lenses = that.options.lenses;
    options = that.options;
    $(container).empty();
    that.getLens = function(item) {
      if ((item.type != null) && (item.type[0] != null) && (lenses[item.type[0]] != null)) {
        return {
          render: lenses[item.type[0]]
        };
      }
    };
    that.renderingFor = function(id) {
      return renderings[id];
    };
    that.renderItems = function(model, items) {
      var f, n;
      n = items.length;
      f = function(start) {
        var end, hasItem, i, id, lens;
        if (start < n) {
          end = n;
          if (n > 200) {
            end = start + parseInt(Math.sqrt(n), 10) + 1;
            if (end > n) {
              end = n;
            }
          }
          for (i = start; start <= end ? i < end : i > end; start <= end ? i++ : i--) {
            id = items[i];
            hasItem = model.contains(id);
            if (!hasItem) {
              if (renderings[id] != null) {
                renderings[id].remove();
                delete renderings[id];
              }
            } else if (renderings[id] != null) {
              renderings[id].update(model.getItem(id));
            } else {
              lens = that.getLens(model.getItem(id));
              if (lens != null) {
                renderings[id] = lens.render(container, that, model, items[i]);
              }
            }
          }
          return setTimeout(function() {
            return f(end);
          }, 0);
        } else {
          return that.finishDisplayUpdate();
        }
      };
      that.startDisplayUpdate();
      return f(0);
    };
    that.eventModelChange = that.renderItems;
    that.startDisplayUpdate = function() {};
    that.finishDisplayUpdate = function() {};
    that.selfRender = function() {};
    that.renderItems(that.dataView, that.dataView.items());
    that.dataView = that.options.dataView;
    that.dataView.registerPresentation(that);
    return that;
  };
}).call(this);
