(function($, MITHGrid) {
	MITHGrid.Plugin.namespace("StateMachineEditor");
    MITHGrid.Plugin.StateMachineEditor.initPlugin = function(options) {
        var that,
		types = $.extend({
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
		typeOptions = {},
		propOptions = {
			"position-x": {
				valueType: "numeric"
			},
			"position-y": {
				valueType: "numeric"
			},
			"height": {
				valueType: "numeric"
			},
			"width": {
				valueType: "numeric"
			}
		};
		
		typeOptions[types.StateMachine] = {}
		typeOptions[types.State] = {}
		typeOptions[types.Transition] = {}
		
		propOptions[properties.state] = {
			valueType: "item"
		};
		
		propOptions[properties.state + "-from"] = {
			valueType: "item"
		};
		propOptions[properties.state + "-to"] = {
			valueType: "item"
		};

        that = MITHGrid.Plugin.initPlugin("StateMachineEditor", {
			types: typeOptions,
			properties: propOptions,
            presentations: {
				sheet: {
	                type: MITHGrid.Presentation.Flow,
	                container: options.container,
	                label: 'sheet',
	                options: {
	                    margins: options.margins
	                }
            	}
			}
        });

        return that;
    };
})(jQuery, MITHGrid);