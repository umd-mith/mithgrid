###

This set of components translates between RDF/JSON and the data store.

###
  

MITHgrid.Data.namespace 'Importer', (I) ->
  I.namespace 'JSON_LD', (LD) ->
    LD.initInstance = (dataStore, NS, types) ->
      that = {}
      
      # check for JSON-LD library - throw an error if we don't have it loaded
      # jsonld is our JSON-LD normalizer object
      if not window.jsonld?.expand?
        throw "Unable to find JSON-LD expand function"
      
      types ?= {}
      types["http://www.w3.org/1999/02/22-rdf-syntax-ns#type"] = "item"
        
      NS ?=
        "http://www.w3.org/2000/01/rdf-schema#": "rdfs"
        "http://www.w3.org/1999/02/22-rdf-syntax-ns#": "rdf"
        "http://www.w3.org/2003/12/exif/ns#": "exif"
        "http://purl.org/dc/elements/1.1/": "dc"
        "http://purl.org/dc/dcmitype/": "dctypes"
        
      that.import = (jsonIn, cb) ->
        jsonld.expand jsonIn, {
          keepFreeFloatingNodes: true
        }, (err, json) ->
          #console.log json
          if err?
            cb([])
            return
          jsonld.flatten json, null, {
            
          }, (err, json) ->
            items = []
            ids = []
            syncer = MITHGrid.initSynchronizer()
            # we allow for nested documents and lists -- we expand these
            # as needed instead of requiring conversion to RDF/JSON first
            syncer.process json, (predicates) ->
              item =
                id: predicates['@id']

              for p, os of predicates

                values = []
                if types[p] == "item"
                  for o in os
                    if o["@id"]?
                      v = o["@id"]
                      for ns, prefix of NS
                        if v[0...ns.length] == ns
                          v = prefix + v[ns.length..]
                      values.push v
                else
                  for o in os
                    if o["@value"]?
                      values.push o["@value"]
                    else if o["@id"]?
                      if o["@id"][0...1] == "(" and o["@id"][-1..] == ")"
                        values.push "_:" + o["@id"][1...-1]
                      else
                        values.push o["@id"]
                if values.length > 0
                  pname = p
                  for ns, prefix of NS
                    if p[0...ns.length] == ns
                      pname = prefix + p[ns.length..]
                  item[pname] = values
                  if p == "http://www.w3.org/1999/02/22-rdf-syntax-ns#type"
                    item.type = values
              if !item.type? or item.type.length == 0
                item.type = 'Blank'
              items.push item
              ids.push item.id
            syncer.done ->
              #console.log items
              setTimeout ->
                for item in items
                  if dataStore.contains(item.id)
                    dataStore.updateItems [ item ]
                  else
                    dataStore.loadItems [ item ]
                cb(ids) if cb?
              , 0
      that
        
  I.namespace 'RDF_JSON', (RDF) ->
    #
    # ## MITHgrid.Data.Importer.RDF_JSON
    #
    # Manages importing triples from RDF/JSON to a MITHgrid data store.
    #
    # ### initInstance
    #
    # Parameters:
    #
    # * dataStore - the data store into which triples should be imported
    # * NS - mapping of namespaces to prefixes
    # * types - mapping of URIs to MITHgrid data store types
    #
    # #### import
    #
    # Parameters:
    #
    # * json - RDF/JSON to import
    # * cb - optional callback when import is finished
    #
    RDF.initInstance = (dataStore, NS, types) ->
      that = {}
      
      types ?= {}
      types["http://www.w3.org/1999/02/22-rdf-syntax-ns#type"] ?= "item"
        
      NS ?=
        "http://www.w3.org/2000/01/rdf-schema#": "rdfs"
        "http://www.w3.org/1999/02/22-rdf-syntax-ns#": "rdf"
        "http://www.w3.org/2003/12/exif/ns#": "exif"
        "http://purl.org/dc/elements/1.1/": "dc"
        "http://purl.org/dc/dcmitype/": "dctypes"
        
      that.import = (json, cb) ->
        items = []
        ids = []
        syncer = MITHGrid.initSynchronizer()
        subjects = (s for s of json)
        syncer.process subjects, (s) ->
          predicates = json[s]
          item =
            id: s
          for p, os of predicates
            values = []
            if types[p] == "item"
              for o in os
                if o.type == "uri"
                  v = o.value
                  for ns, prefix of NS
                    if o.value[0...ns.length] == ns
                      v = prefix + o.value.substr(ns.length)
                  values.push v
            else
              for o in os
                switch o.type
                  when "literal"
                    values.push o.value
                  when "uri", "bnode"
                    if o.value.substr(0,1) == "(" and o.value.subtr(-1) == ")"
                      values.push "_:" + o.value.substr(1,o.value.length-2)
                    else
                      values.push o.value
            if values.length > 0
              pname = p
              for ns, prefix of NS
                if p.substr(0, ns.length) == ns
                  pname = prefix + p.substr(ns.length)
              item[pname] = values
              if p == "http://www.w3.org/1999/02/22-rdf-syntax-ns#type"
                item.type = values
          if !item.type? or item.type.length == 0
            item.type = 'Blank'
          items.push item
          ids.push item.id
        syncer.done ->
          setTimeout ->
            for item in items
              if dataStore.contains(item.id)
                dataStore.updateItems [ item ]
              else
                dataStore.loadItems [ item ]
            cb(ids) if cb?
          , 0
      that