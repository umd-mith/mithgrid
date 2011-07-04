fluid.defaults("MITHGrid.Data.Source", {
    events: {
        onModelChange: null,
        onBeforeLoading: null,
        onAfterLoading: null,
        onBeforeUpdating: null,
        onAfterUpdating: null
    }
});

fluid.defaults("MITHGrid.Data.View", {
    events: {
        onModelChange: null,
        onFilterItem: "preventable"
    }
});
