
	if window?.console?.log?
		MITHGrid.debug = window.console.log
	else 
		MITHGrid.debug = () ->

	MITHGrid.error = () ->
		MITHGrid.debug.call {}, arguments
		{ 'arguments': arguments }

	genericNamespacer = (base, nom) ->
		if !base[nom]?
			newbase =
				namespace: (nom2) ->
					genericNamespacer newbase, nom2
				debug: MITHGrid.debug
		base[nom] = newbase

	MITHGrid.namespace = (nom) ->
		genericNamespacer MITHGrid, nom