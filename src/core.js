(function($, MITHGrid) {

    if (window.console !== undefined && window.console.log !== undefined) {
        MITHGrid.debug = function() {
	        //console.log.call(arguments);
    
            console.log(Array.prototype.slice.call(arguments));
        };
    }
    else {
        MITHGrid.debug = function() {};
    }

    var genericNamespacer = function(base, nom) {
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
})(jQuery, MITHGrid);