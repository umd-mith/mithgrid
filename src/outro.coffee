
)(jQuery, MITHGrid)

fluid.defaults "MITHGrid.Data.initStore",
    events:
        onModelChange: null
        onBeforeLoading: null
        onAfterLoading: null
        onBeforeUpdating: null
        onAfterUpdating: null

fluid.defaults "MITHGrid.Data.initView",
    events:
        onModelChange: null
        onFilterItem: "preventable"