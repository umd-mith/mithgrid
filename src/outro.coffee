
	# Here, we have our deprecated ways of referring to initializers
	# **These aliases will be removed in the first public release.**
	MITHGrid.initView = MITHGrid.initInstance
	MITHGrid.Data.initSet = MITHGrid.Data.Set.initInstance
	MITHGrid.Data.initType = MITHGrid.Data.Type.initInstance
	MITHGrid.Data.initProperty = MITHGrid.Data.Property.initInstance
	MITHGrid.Data.initStore = MITHGrid.Data.Store.initInstance
	MITHGrid.Data.initView = MITHGrid.Data.View.initInstance
	MITHGrid.Controller.initController = MITHGrid.Controller.initInstance
	MITHGrid.Controller.initRaphaelController = MITHGrid.Controller.initController
	MITHGrid.Presentation.initPresentation = MITHGrid.Presentation.initInstance
	MITHGrid.Presentation.SimpleText.initPresentation = MITHGrid.Presentation.SimpleText.initInstance
	MITHGrid.Application.initApp = MITHGrid.Application.initInstance
	
)(jQuery, MITHGrid)

MITHGrid.defaults "MITHGrid.Data.Store",
    events:
        onModelChange: null
        onBeforeLoading: null
        onAfterLoading: null
        onBeforeUpdating: null
        onAfterUpdating: null

MITHGrid.defaults "MITHGrid.Data.View",
    events:
        onModelChange: null
        onFilterItem: "preventable"

MITHGrid.defaults "MITHGrid.Data.SubSet",
    events:
        onModelChange: null

MITHGrid.defaults "MITHGrid.Data.Pager",
    events:
        onModelChange: null

MITHGrid.defaults "MITHGrid.Data.RangePager",
    events:
        onModelChange: null

MITHGrid.defaults "MITHGrid.Data.ListPager",
    events:
        onModelChange: null

MITHGrid.defaults "MITHGrid.Facet",
	events:
		onFilterChange: null

MITHGrid.defaults "MITHGrid.Facet.TextSearch",
	facetLabel: "Search"
	expressions: [ ".label" ]