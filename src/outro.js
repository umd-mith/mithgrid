})(jQuery, MITHGrid);

fluid.defaults("MITHGrid.DataSource", {
    events: {
        onModelChange: null,
        onBeforeLoading: null,
        onAfterLoading: null,
        onBeforeUpdating: null,
        onAfterUpdating: null
    }
});

fluid.defaults("MITHGrid.DataView", {
    events: {
        onModelChange: null,
        onFilterItem: "preventable"
    }
});
