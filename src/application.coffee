# # Applications
#
# ## MITHgrid.Application
#
# Initializes an application instance.
#
# 
MITHgrid.namespace 'Application', (Application) ->
  Application.initInstance = (args...) ->   
    MITHgrid.initInstance "MITHgrid.Application", args..., (that, container) ->
      onReady = []
      
      thatFn = -> that
  
      that.presentation = {}
      that.facet = {}
      that.component = {}
      that.dataStore = {}
      that.dataView = {}
      that.controller = {}
  
      options = that.options
      
      that.ready = (fn) -> onReady.push fn
      
      # ### #run
      #
      # Finishes configuring the application by running all queued or pending functions registered through
      # the #ready() method. The #ready() method will be redefined to run functions after the current thread
      # finishes.
      that.run = () ->
        $(document).ready () ->
          that.ready = (fn) -> fn()
          fn() for fn in onReady            
          onReady = []
      
      # ### #addDataStore
      #
      # Adds a data store to the application.
      #
      # Parameters:
      #
      # * storeName - name for the data store
      #
      # * config - object holding configuration options
      #
      # Returns: Nothing.
      #

      that.addDataStore = (storeName, config) ->
        #
        # The data store automatically has an "Item" type and the "type" and "id" properties.
        #
        if !that.dataStore[storeName]?
          store = MITHgrid.Data.Store.initInstance()
          that.dataStore[storeName] = store
          store.addType 'Item'
          store.addProperty 'type',
            valueType: 'text'
          store.addProperty 'id',
            valueType: 'text'
        else
          store = that.dataStore[storeName]

        # Configuration:
        #

        # * **types** - object having the types as keys. Types do not have configurations yet.
        #
        if config?.types?
          store.addType type for type, typeInfo of config.types

        # * **properties** - object having the properties as keys. Properties have the following options:
        #    * valueType - the type of value associated with the property. Value types should be one of the following:
        #        * text - plain text strings (default)
        #        * item - the id of an item in the data store
        #        * numeric - an integer or floating point number
        #        * date -
        #        * url -
        if config?.properties?
          store.addProperty prop, propOptions for prop, propOptions of config.properties
  
      # ### #addDataView
      #
      # Adds a data view to the application.
      #
      # Parameters:
      #
      # * viewName - name for the data view
      #
      # * viewConfig - object holding configuration options
      #
      # Returns: Nothing.
      #
      # Configuration:
      #
      # * type - the namespace holding the #initInstance function for the particular data view type for this data view.
      #          Defaults to MITHgrid.Data.View.
      #
      # * dataStore - the name of the already configured data store.
      #
      # See the documentation for the particular data view type for other configuration options.
      #
      that.addDataView = (viewName, viewConfig) ->
        if viewConfig.type? and viewConfig.type.initInstance?
          initFn = viewConfig.type.initInstance
        else
          initFn = MITHgrid.Data.View.initInstance
        viewOptions =
          dataStore: that.dataStore[viewConfig.dataStore] || that.dataView[viewConfig.dataStore]
  
        if !that.dataView[viewName]?
          for k,v of viewConfig
            if k != "type" && !viewOptions[k]
              viewOptions[k] = v
      
          view = initFn viewOptions
          that.dataView[viewName] = view
  
      # ### #addController
      #
      # Adds a controller to the application.
      #
      # Parameters:
      #
      # * cName - name for the controller
      #
      # * cconfig - object holding configuration options
      #
      # Returns: Nothing.
      #
      that.addController = (cName, cconfig) ->
        coptions = $.extend(true, {}, cconfig)

        coptions.application = thatFn
        controller = cconfig.type.initInstance coptions
        that.controller[cName] = controller
  
      # ### #addFacet
      #
      # Adds a facet to the application.
      #
      # Parameters:
      #
      # * fName - name of the facet
      #
      # * fconfig - object holding configuration options
      #
      # Returns: Nothing.
      #
      that.addFacet = (fName, fconfig) ->
        foptions = $.extend(true, {}, fconfig)
        that.ready () ->
          fcontainer = $(container).find(fconfig.container)
          fcontainer = fcontainer[0] if $.isArray(fcontainer)
      
          foptions.dataView = that.dataView[fconfig.dataView]
          foptions.application = thatFn
      
          facet = fconfig.type.initInstance fcontainer, foptions
          that.facet[fName] = facet
          facet.selfRender()
  
      # ### #addComponent
      #
      # Adds a component to the application. Components tie together renderings with controllers, but do not base
      # their DOM content on data. Components are good for things like bounding boxes used by a presentation, menus,
      # or other UI elements that might be considered chrome.
      #
      # Parameters:
      #
      # * cName - name of the component
      #
      # * cconfig - object holding configuration options
      #
      # Returns: Nothing.
      #
      that.addComponent = (cName, cconfig) ->
        coptions = $.extend(true, {}, cconfig)
        that.ready () ->
          ccontainer = $(container).find(coptions.container)
          ccontainer = ccontainer[0] if $.isArray(ccontainer)
          coptions.application = thatFn
          if cconfig.components?
            coptions.components = {}
            for ccName, cconfig of cconfig.components
              if typeof cconfig == "string"
                coptions.components[ccName] = that.component[ccName]
              else
                ccoptions = $.extend(true, {}, ccconfig)
                ccoptions.application = thatFn
                coptions.components[ccName] = cconfig.type.initInstance ccoptions
          if cconfig.controllers?
            coptions.controllers = {}
            for ccName, cconfig of pconfig.controllers
              if typeof cconfig == "string"
                coptions.controllers[ccName] = that.controller[ccName]
              else
                ccoptions = $.extend(true, {}, ccconfig)
                ccoptions.application = thatFn
                coptions.controllers[ccName] = cconfig.type.initInstance ccoptions

          that.component[cName] = cconfig.type.initInstance ccontainer, coptions
        
      # ### #addPresentation
      #
      # Adds a presentation to the application.
      #
      # Parameters:
      #
      # * pName - name of the presentation
      #
      # * pconfig - object holding configuration options
      #
      # Returns: Nothing.
      #
      that.addPresentation = (pName, pconfig) ->
        poptions = $.extend(true, {}, pconfig)
        that.ready () ->
          pcontainer = $(container).find(poptions.container)
          pcontainer = pcontainer[0] if $.isArray(pcontainer)
          poptions.dataView = that.dataView[pconfig.dataView]
          poptions.application = thatFn
          if pconfig.components?
            poptions.components = {}
            for ccName, cconfig of pconfig.components
              if typeof cconfig == "string"
                poptions.components[ccName] = that.component[ccName]
              else
                ccoptions = $.extend(true, {}, ccconfig)
                ccoptions.application = thatFn
                poptions.components[ccName] = cconfig.type.initInstance ccoptions
          if pconfig.controllers?
            poptions.controllers = {}
            for cName, cconfig of pconfig.controllers
              if typeof cconfig == "string"
                poptions.controllers[cName] = that.controller[cName]
              else
                coptions = $.extend(true, {}, cconfig)
                coptions.application = thatFn
                poptions.controllers[cName] = cconfig.type.initInstance coptions
    
          presentation = pconfig.type.initInstance pcontainer, poptions
          that.presentation[pName] = presentation
          presentation.selfRender()
      
      # ### #addPlugin
      #
      # Adds a plugin to the application.
      #
      # Parameters:
      #
      # * pconf - object holding configuration options
      #
      # Returns: Nothing.
      #
      that.addPlugin = (pconf) ->
        pconfig = $.extend(true, {}, pconf)
        pconfig.application = thatFn

        plugin = pconfig.type.initInstance(pconfig)
        if plugin?
          if pconfig?.dataView?

            plugin.dataView = that.dataView[pconfig.dataView]

            plugin.dataView.addType type for type, typeInfo of plugin.getTypes()

            plugin.dataView.addProperty prop, propOptions for prop, propOptions of plugin.getProperties()

          for pname, prconfig of plugin.getPresentations()
            (pname, prconfig) ->
              that.ready ->
                proptions = $.extend(true, {}, prconfig.options)
                pcontainer = $(container).find(prconfig.container)
                pcontainer = pcontainer[0] if $.isArray(pcontainer)

                proptions.lenses = prconfig.lenses if prconfig?.lenses?
                if prconfig.dataView?
                  proptions.dataView = that.dataView[prconfig.dataView] 
                else if pconfig.dataView?
                  proptions.dataView = that.dataView[pconfig.dataView]
                proptions.application = thatFn
                presentation = prconfig.type.initInstance pcontainer, proptions
                plugin.presentation[pname] = presentation
                presentation.selfRender()
  
  

      # In addition to the configuration options for generic MITHgrid object instances,
      # the following configuration options are available:
      #

      # ### dataStores
      #
      # See the section on #addDataStore.
      #
      if options?.dataStores?
        for storeName, config of options.dataStores
          that.addDataStore storeName, config

      # ### dataViews
      #
      # See the section on #addDataView.
      #
      if options?.dataViews?
        for viewName, viewConfig of options.dataViews
          that.addDataView viewName, viewConfig

      # ### controllers
      #
      # See the section on #addController.
      #
      if options?.controllers?
        for cName, cconfig of options.controllers
          that.addController cName, cconfig

      # ### facets
      #
      # See the section on #addFacet.
      #
      if options?.facets?
        for fName, fconfig of options.facets
          that.addFacet fName, fconfig
      
      # ### components
      #
      # See the section on #addComponent
      #
      if options?.components?
        for cName, cconfig of options.components
          that.addComponent cName, cconfig
        
      # ### presentations
      #
      # See the section on #addPresentation.
      #
      if options?.presentations?
        for pName, pconfig of options.presentations
          that.addPresentation pName, pconfig

      # ### plugins
      #
      # See the section on #addPlugin.
      #
      if options?.plugins?
        for pconfig in options.plugins
          that.addPlugin pconfig

