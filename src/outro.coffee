
)(jQuery, MITHGrid)

MITHGrid.defaults "MITHGrid.Data.initStore",
    events:
        onModelChange: null
        onBeforeLoading: null
        onAfterLoading: null
        onBeforeUpdating: null
        onAfterUpdating: null

MITHGrid.defaults "MITHGrid.Data.initView",
    events:
        onModelChange: null
        onFilterItem: "preventable"

MITHGrid.defaults "MITHGrid.Facet", {}

MITHGrid.defaults "MITHGrid.Facet.TextSearch",
	facetLabel: "Search"
	expressions: [ ".label" ]