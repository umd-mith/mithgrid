
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

MITHGrid.defaults "MITHGrid.Data.Pager",
    events:
        onModelChange: null

MITHGrid.defaults "MITHGrid.Data.RangePager",
    events:
        onModelChange: null

MITHGrid.defaults "MITHGrid.Facet", {}

MITHGrid.defaults "MITHGrid.Facet.TextSearch",
	facetLabel: "Search"
	expressions: [ ".label" ]