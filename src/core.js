(function($, MITHGrid) {
	if (window.console !== undefined && window.console.log !== undefined) {
        MITHGrid.debug = window.console.log;
    }
    else {
        MITHGrid.debug = function() {};
    }

	MITHGrid.error = function() {
		MITHGrid.debug.call({}, arguments);
		return { 'arguments': arguments };
	};

    var genericNamespacer;

	genericNamespacer = function(base, nom) {
        if (base[nom] === undefined) {
            base[nom] = {
				namespace: function(nom2) {
					return genericNamespacer(base[nom], nom2);
				},
				debug: MITHGrid.debug
			};
        }
        return base[nom];
    };

    MITHGrid.namespace = function(nom) {
        return genericNamespacer(MITHGrid, nom);
    };
}(jQuery, MITHGrid));