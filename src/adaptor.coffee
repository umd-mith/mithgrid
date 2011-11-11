
	Adaptor = MITHGrid.namespace 'Adaptor'

	Adaptor.initAdaptor = (type, options) ->
		[ type, c, options ] = MITHGrid.normalizeArgs "MITHGrid.Adaptor", type, undefined, options
		that = MITHGrid.initView type, options
		options = that.options
		lenses = options.lenses

		that.dataStore = options.dataStore

		that.import = (data) ->
			parser = that.parser()
			parser.push data
			parser.finish()
			
		that.export = () ->
			ret = ''
			that.dataStore.visit (id) ->
				item = that.dataStore.getItem id
				ret += that.render item
			ret
			
		that.parser = () ->
			parser = {}
			stack = []
			
			parser.push = (data) ->
			
			parser.finish = () ->
				
			parser.start = (type, data) ->
				
			parser.end = (type, data, startRet) ->
			
			parser.stack = (n) ->
				if n?
					if n < stack.length
						return stack[n]
					else
						return {}
				else
					return stack[stack.length-1]
					
				
			parser
		
		

		that.render = (item) ->
			if item.type?
				lens = lenses[item.type]
				if lens?
					lens.render(that, item)

		that
		
	RDF = Adaptor.namespace 'RDF'
	
	RDF.initAdaptor = (type, options) ->
		[ type, c, options ] = MITHGrid.normalizeArgs "MITHGrid.Adaptor.RDF", type, undefined, options
		that = Adaptor.initAdaptor type, options
		options = that.options
		
		superParser = that.parser
		
		that.parser = () ->
			parser = superParser()
			rdfDatabank = $.rdf.databank().base(options.base)
			if options.prefix?
				for ns, href of options.prefix
					rdfDatabank.prefix ns, href
			
			parser.base = (b) ->
				rdfDatabank.base b
				parser
				
			parser.prefix = (ns, href) ->
				rdfDatabank.prefix ns, href
				parser

			parser.push = (data) ->
				if typeof data == "string"
					# assume XML
					rdfDatabank.load data, {}
				else
					# assume an array of turtle
					for line in data
						rdfDatabank.add line
				
			parser.finish = () ->
				# now we walk the databank looking for things we can use to create events that lead to
				# info in the data store
				
			
			parser.start = (type, data) ->
				
			parser.end = (type, data, startRet) ->
			
			parser
			
		
		that
	
	OAC = RDF.namespace 'OAC'
	
	OAC.initAdaptor = (type, options) ->
		[ type, c, options ] = MITHGrid.normalizeArgs "MITHGrid.Adaptor.RDF.OAC", type, undefined, options
		that = Adaptor.initAdaptor type, options
		options = that.options
		
		that.parser = () ->
			
		
		that