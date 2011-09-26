(function() {
  var Application;
  Application = MITHGrid.namespace('Application');
  Application.initApp = function(klass, container, options) {
    var config, onReady, prop, propOptions, store, storeName, that, type, typeInfo, view, viewConfig, viewName, viewOptions, _ref, _ref2, _ref3;
    that = fluid.initView(klass, container, options);
    onReady = [];
    that.presentation = {};
    that.dataStore = {};
    that.dataView = {};
    options = that.options;
    that.ready = onReady.push;
    if ((options != null ? options.dataStores : void 0) != null) {
      for (storeName in dataStores) {
        config = dataStores[storeName];
        if (!(that.dataStore[storeName] != null)) {
          store = MITHGrid.Data.initStore();
          that.dataStore[storeName] = store;
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
        } else {
          store = that.dataStore[storeName];
        }
        if ((config != null ? config.types : void 0) != null) {
          _ref = config.types;
          for (type in _ref) {
            typeInfo = _ref[type];
            store.addType(type);
          }
        }
        if ((config != null ? config.properties : void 0) != null) {
          _ref2 = config.properties;
          for (prop in _ref2) {
            propOptions = _ref2[prop];
            store.addProperty(prop, propOptions);
          }
        }
      }
    }
    if ((options != null ? options.dataViews : void 0) != null) {
      _ref3 = options.dataViews;
      for (viewName in _ref3) {
        viewConfig = _ref3[viewName];
        viewOptions = {
          dataStore: that.dataStore[viewConfig.dataStore],
          label: viewName
        };
        if (!(that.dataView[viewName] != null)) {
          if (viewConfig.collection != null) {
            viewOptions.collection = viewConfig.collection;
          }
          if (viewConfig.types != null) {
            viewOptions.types = viewConfig.types;
          }
          if (viewConfig.filters != null) {
            viewOptions.filters = viewConfig.filters;
          }
          view = MITHGrid.Data.initView(viewOptions);
          that.dataView[viewName] = view;
        }
      }
    }
    if ((options != null ? options.viewSetup : void 0) != null) {
      if ($.isFunction(options.viewSetup)) {
        that.ready(function() {
          return options.viewSetup($(container));
        });
      } else {
        that.ready(function() {
          return $(container).append(options.viewSetup);
        });
      }
    }
    if ((options != null ? options.presentations : void 0) != null) {
      that.ready(function() {
        var pName, pconfig, pcontainer, poptions, presentation, _ref4, _results;
        _ref4 = options.presentations;
        _results = [];
        for (pName in _ref4) {
          pconfig = _ref4[pName];
          poptions = $.extend(true, {}, pconfig);
          pcontainer = $('#' + $(container).attr('id') + ' > ' + config.container);
          if ($.isArray(container)) {
            pcontainer = pcontainer[0];
          }
          poptions.dataView = that.dataView[pconfig.dataView];
          poptions.application = that;
          presentation = config.type.initPresentation(pcontainer, poptions);
          that.presentation[pName] = presentation;
          _results.push(presentation.selfRender());
        }
        return _results;
      });
    }
    if ((options != null ? options.plugins : void 0) != null) {
      that.ready(function() {
        var pconfig, pcontainer, plugin, pname, prconfig, presentation, prop, propOptions, proptions, type, typeInfo, _i, _len, _ref4, _results;
        _ref4 = options.plugins;
        _results = [];
        for (_i = 0, _len = _ref4.length; _i < _len; _i++) {
          pconfig = _ref4[_i];
          plugin = pconfig.type.initPlugin(pconfig);
          _results.push((function() {
            var _ref5, _ref6, _ref7, _results2;
            if (plugin != null) {
              if ((pconfig != null ? pconfig.dataView : void 0) != null) {
                plugin.dataView = that.dataView[pconfig.dataView];
                _ref5 = plugin.getTypes();
                for (type in _ref5) {
                  typeInfo = _ref5[type];
                  plugin.dataView.addType(type);
                }
                _ref6 = plugin.getProperties();
                for (prop in _ref6) {
                  propOptions = _ref6[prop];
                  plugin.dataView.addProperty(prop, propOptions);
                }
              }
              _ref7 = plugin.getPresentations();
              _results2 = [];
              for (pname in _ref7) {
                prconfig = _ref7[pname];
                proptions = $.extend(true, {}, prconfig.options);
                pcontainer = $("#" + $(container).attr('id') + ' > ' + prconfig.container);
                if ((prconfig != null ? prconfig.lenses : void 0) != null) {
                  proptions.lenses = prconfig.lenses;
                }
                if ($.isArray(pcontainer)) {
                  pcontainer = pcontainer[0];
                }
                if (prconfig.dataView != null) {
                  proptions.dataView = that.dataView[prconfig.dataView];
                } else if (pconfig.dataView != null) {
                  proptions.dataView = that.dataView[pconfig.dataView];
                }
                options.application = that;
                presentation = config.type.initPresentation(pcontainer, options);
                plugin.presentation[pname] = presentation;
                _results2.push(presentation.selfRender());
              }
              return _results2;
            }
          })());
        }
        return _results;
      });
    }
    that.run = function() {
      return $(document).ready(function() {
        var fn, _i, _len;
        for (_i = 0, _len = onReady.length; _i < _len; _i++) {
          fn = onReady[_i];
          fn();
        }
        onReady = [];
        return that.ready = function(fn) {
          return setTimeout(fn, 0);
        };
      });
    };
    return that;
  };
}).call(this);
