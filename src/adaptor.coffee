
	Adaptor = MITHGrid.namespace 'Adaptor'

	Adaptor.initAdaptor = (type, options) ->
		[ type, c, options ] = MITHGrid.normalizeArgs "MITHGrid.Adaptor", type, undefined, options
		that = MITHGrid.initView type, options
		options = that.options
		lenses = options.lenses
		
		that.export = (dataView) ->
			exporter = that.exporter()
			idList = {}
			me = {}
			
			exportProperty = (name, values) ->
				prop = that.getProperty name
				propType = prop.getValueType()
			
				exporter.beginProperty name,
					type: propType
			
				if propType == "item"
					exportItem id for id in values
				else
					exporter.value v for v in values
		
	    	exportItem = (id) ->
				if idList[id]
					exporter.itemReference id
				else
					idList[id] = true
					item = that.getItem id
					exporter.beginItem id,
						type: item.type[0]
					
					for prop, values of item
						continue if prop in [ "id", "type" ]
						exportProperty prop, values
					
					exporter.endItem id
			
			exporter.beginExport()
			dataView.visit exportItem
			exporter.endExport()
			exporter.export

		that.parse = (data) ->
			parser = that.parser()
			parser.push data
			parser.finish()
			parser.data
			
		that.exporter = () ->
			exporter = {}
			dataStack = []
			
			exporter.push = (ob) -> dataStack.push ob
			
			exporter.pop = () -> dataStack.pop()
				
			exporter.peek = (x = 0) -> 
				l = dataStack.length
				return {} if l >= x
				dataStack[dataStack.length-1-x]
			
			exporter.beginExport = () ->
				dataStack = []
				
			exporter.endExport = () ->
				
			exporter.beginItem = (id, metadata) ->
				
			exporter.endItem = () ->
				
			exporter.beginProperty = (name, metadata) ->
			
			exporter.endProperty = () ->
			
			exporter.itemReference = (id) ->
			
			exporter.value = (value) ->
				
			exporter
			
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
		
		superExporter = that.exporter
		
		that.exporter = () ->
			exporter = superExporter()
			superMethods = {}
			rdfDatabank = {}
			
			for p, v of exporter
				superMethods[p] = v
			
			exporter.add = (s, p, o, type) ->
				if options.properties[p]?
					p_uri = options.properties[p].uri
				else
					p_uri = p
				
				if type == "text"
					o = '"' + o.split('\\').join('\\\\').split('"').join('\\"') + '"'
				else if type == "date"
					o = '"' + o.split('\\').join('\\\\').split('"').join('\\"') + '"'
					o = o + "^^xsd:date"
				
				rdfDatabank.add(s + " " + p + " " + o + " .")
				exporter

			exporter.prefix = (ns, href) ->
				rdfDatabank.prefix ns, href
				exporter
			
			exporter.beginExport = () ->
				superMethods.beginExport()
				rdfDatabank = $.rdf.databank().base(options.base)
				if options.prefix?
					for ns, href of options.prefix
						rdfDatabank.prefix ns, href
				rdfDatabank.prefix 'xsd', 'http://www.w3.org/2001/XMLSchema#'
				rdfDatabank.prefix 'dc', 'http://purl.org/dc/elements/1.1/'
				
			exporter.endExport = () ->
				exporter.export = rdfDatabank.dump
					format: 'application/rdf+xml'
					serialize: true
			
			exporter.beginItem = (id, metadata) ->
				type_uri = options.types[metadata.type].uri
				exporter.add(id, 'a', type_uri, 'item')
				info = exporter.peek()
				if info.currentPropertyValues?
					info.currentPropertyValues.push id

				exporter.push { id: id, type: metadata.type }
				options.types[metadata.type].begin id, metadata
				
			exporter.endItem = () ->
				info = exporter.pop
				options.types[info.type].end info.id
				
			exporter.beginProperty = (name, metadata) ->
				info = exporter.peek()
				info.currentProperty = name
				info.currentPropertyType = metadata.type
				info.currentPropertyValues = []
			
			exporter.endProperty = () ->
				# now we can process the values for the property
				
			
			exporter.itemReference = (id) ->
				info = exporter.peek()
				if info.currentPropertyValues?
					info.currentPropertyValues.push id
			
			exporter.value = (value) ->
				info = exporter.peek()
				info.currentPropertyValues.push value
				
			exporter
		
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
				items = []
				# now we walk the databank looking for things we can use to create events that lead to
				# info in the data store
				#
				# ?annotation a oac:annotation
				# ?annotation oac:hasTarget ?target
				# ?target a oac:ConstrainedTarget
				# ?target oac:Constrains ?mediaURL
				# ?target oac:ConstrainedBy ?svg
				# ?svg a oac:SVGConstraint
				# ?svg a cnt:ContentAsText
				# ?svg cnt:chars ?svgBox
				# ?svg cnt:characterEncoding "utf-8"
				# ?annotation oac:hasBody ?body
				# ?body a oac:Body
				# ?body a cnt:ContentAsText
				# ?body cnt:chars ?bodyText
				# ?annotation dcterms:created ?createdAt
				# ?annotation dcterms:creator ?createdBy
				# ?annotation dc:title ?title
				
				annotation = ''
				mediaURL = ''
				svgBox = ''
				bodyText = ''
				createdAt = ''
				createdBy = ''
				title = ''
				
				svgBoxItem = that.SVGBoundingBoxToItem(svgBox)
				svgBoxItem.id = annotation + '-svg-constraint'
				
				bodyItem =
					id: annotation + '-body-text'
					type: 'TextContent'
					content: bodyText
			
				items.push svgBoxItem
				items.push bodyItem
				
				items.push
					id: annotation
					mediaURL: mediaURL
					svgConstraint: svgBoxItem.id
					body: bodyItem.id
					createdAt: createdAt
					createdBy: createdBy
					title: title
				
				that.dataStore.loadItems items
					
				
			
			parser.start = (type, data) ->
				
			parser.end = (type, data, startRet) ->
			
			parser
			
		
		that
	
	OAC = RDF.namespace 'OAC'
	
	OAC.initAdaptor = (type, options) ->
		[ type, c, options ] = MITHGrid.normalizeArgs "MITHGrid.Adaptor.RDF.OAC", type, undefined, options
		that = RDF.initAdaptor type, options
		options = that.options
		
		superExporter = that.exporter
		
		that.exporter = () ->
			exporter = superExporter()
			superMethods = {}
			lastIds = {}
			
			for p, v of exporter
				superMethods[p] = v
			
			exporter.beginExport = () ->
				superMethods.beginExport()
				exporter.prefix 'oac', 'http://www.openannotation.org/ns/'
				options.types['Annotation'] = 'oac:Annotation'
			
			exporter.beginItem = (id, metadata) ->
				superExporter.beginItem id, metadata
				lastIds.annotation = id
				
			exporter.addTarget = (target, id) ->
				id ?= lastIds.annotation
				lastIds.target = target
				exporter.add id, 'oac:hasTarget', target
				exporter
				
			exporter.addBody = (body, id) ->
				id ?= lastIds.annotation
				lastIds.body = body
				exporter.add id, 'oac:hasBody', body
				exporter
						
			exporter.endProperty = () ->
				info = exporter.peek();
				
				superExporter.endProperty()
			
		that.parser = () ->
			
		
		that