(function($, MITHGrid) {
	MITHGrid.Application.Example = function(container, options) {
		var that = MITHGrid.Application.initApp("MITHGrid.Application.Example", container, {
	        dataStores: [{
	            label: 'internal'
			}],
			dataViews: [{
	            label: 'internal',
	            dataStore: 'internal',
				types: ["View", "Transition"]
	        }],
			plugins: [{
				type: MITHGrid.Plugin.StateMachineEditor,
				dataView: 'internal',
				types: {
					StateMachine: 'Application',
					State: 'View',
					Transition: 'Transition'
				},
				properties: {
					state: 'view'
				},
				container: '#edit-canvas',
				margins: {
					right: 0,
					left: 0,
					top: function() {
						return $('#header').outerHeight()
					},
					bottom: 0
				}
			}]
	    });

	    that.ready(function() {
	        var views_counter = 0;
	        var create_view = function(label, x, y) {
	            var id = 'view-' + views_counter;
	            views_counter += 1;
	            that.dataStore.internal.loadItems([{
	                label: label,
	                id: id,
	                "position-x": x,
	                "position-y": y,
	                type: 'View'
	            }]);
	            return id;
	        };
	        var create_transition = function(from, to) {
	            var id = 'transition-' + views_counter;
	            views_counter += 1;
	            that.dataStore.internal.loadItems([{
	                label: 'transition from ' + from + ' to ' + to,
	                id: id,
	                "transition-from": from,
	                "transition-to": to,
	                type: "Transition"
	            }]);
	            return id;
	        };
	        var view0 = create_view('start', 10, 20);
	        var view1 = create_view('done', 220, 120);
	        var view2 = create_view('more', 10, 120);
	        var view3 = create_view('most', 200, 400);
	        create_transition(view0, view1);
	        create_transition(view2, view0);
	        create_transition(view1, view2);
	        create_transition(view0, view3);
	    });
	
		return that;
	};
	
//	MITHGrid.Application.Example().run();
})(jQuery, MITHGrid);