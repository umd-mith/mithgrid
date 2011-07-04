(function($, MITHGrid) {
    MITHGrid.Plugin.StateMachineEditor = function(options) {
        var types = $.extend({
            StateMachine: "StateMachine",
            State: "State",
            Transition: "Transition"
        },
        options.types),
        properties = $.extend({
            state: "state",
            transtion: "transition",
            statemachine: "statemachine"
        },
        options.properties),
        that = MITHGrid.Plugin.initPlugin("StateMachineEditor", {
            types: [{
                label: types.StateMachine
            },
            {
                label: types.State
            },
            {
                label: types.Transition
            }],
            properties: [{
                label: properties.state,
                valueType: "item"
            },
            {
                label: properties.transition + "-from",
                valueType: "item"
            },
            {
                label: properties.transition + "-to",
                valueType: "item"
            },
            {
                label: "position-x",
                valueType: "numeric"
            },
            {
                label: "position-y",
                valueType: "numeric"
            }],
            presentations: [{
                type: MITHGrid.Presentation.Flow,
                container: options.container,
                label: 'sheet',
                options: {
                    margins: options.margins
                }
            }]
        });

        return that;
    };
})(jQuery, MITHGrid);