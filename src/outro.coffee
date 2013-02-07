
  # Here, we have our deprecated ways of referring to initializers
  # **These aliases will be removed in the first public release.**
  MITHgrid.initView = MITHgrid.deprecated "MITHgrid.initView", MITHgrid.initInstance
  MITHgrid.Data.initSet = MITHgrid.deprecated "MITHgrid.Data.initSet", MITHgrid.Data.Set.initInstance
  MITHgrid.Data.initType = MITHgrid.deprecated "MITHgrid.Data.initType", MITHgrid.Data.Type.initInstance
  MITHgrid.Data.initProperty = MITHgrid.deprecated "MITHgrid.Data.initProperty", MITHgrid.Data.Property.initInstance
  MITHgrid.Data.initStore = MITHgrid.deprecated "MITHgrid.Data.initStore", MITHgrid.Data.Store.initInstance
  MITHgrid.Data.initView = MITHgrid.deprecated "MITHgrid.Data.initView", MITHgrid.Data.View.initInstance
  MITHgrid.Presentation.initPresentation = MITHgrid.deprecated "MITHgrid.Presentation.initPresentation", MITHgrid.Presentation.initInstance
  MITHgrid.Presentation.SimpleText.initPresentation = MITHgrid.deprecated "MITHgrid.Presentation.SimpleText.initPresentation", MITHgrid.Presentation.SimpleText.initInstance
  MITHgrid.Application.initApp = MITHgrid.deprecated "MITHgrid.Application.initApp", MITHgrid.Application.initInstance
  
)(jQuery, MITHgrid)

MITHgrid.defaults "MITHgrid.Data.Store",
    events:
        onModelChange: null
        onBeforeLoading: null
        onAfterLoading: null
        onBeforeUpdating: null
        onAfterUpdating: null

MITHgrid.defaults "MITHgrid.Data.View",
    events:
        onModelChange: null
        onFilterItem: "preventable"

MITHgrid.defaults "MITHgrid.Data.SubSet",
    events:
        onModelChange: null

MITHgrid.defaults "MITHgrid.Data.Pager",
    events:
        onModelChange: null

MITHgrid.defaults "MITHgrid.Data.RangePager",
    events:
        onModelChange: null

MITHgrid.defaults "MITHgrid.Data.ListPager",
    events:
        onModelChange: null

MITHgrid.defaults "MITHgrid.Facet",
  events:
    onFilterChange: null

MITHgrid.defaults "MITHgrid.Facet.TextSearch",
  facetLabel: "Search"
  expressions: [ ".label" ]
