/*
 * This version of Adventure is based on the literate programming version available at
 * http://www.literateprogramming.com/adventure.pdf
 *
 * This illustrates the use of data views providing different filtered versions of the core
 * data store.
 */

 (function($, MITHGrid) {
	/*
	 * Since MITHGrid doesn't have any predefined presentations right now, we define a few for the game.
	 *
	 * The first is a list of text items.
	 *
	 * The itemLens is an object that can render the item, adding content to the container as well as
	 * returning an object that can be used to update or remove the content.
	 * 
	 * The lens for the text list renders the item name as a list element.  The item name is a property
	 * of objects in the Adventure game.
	 */
    MITHGrid.Presentation.TextList = function(container, options) {
        var that = MITHGrid.Presentation.initView("TextList", container, options),
        itemLens = {
            render: function(container, view, model, itemId) {
                var that = {},
                el,
                item = model.getItem(itemId);

                el = $('<li>' + item.name[0] + '</li>');
                $(container).append(el);

                that.update = function(item) {};

                that.remove = function() {
                    $(el).remove();
                };

                return that;
            }
        };

        that.startDisplayUpdate = function() {};
        that.finishDisplayUpdate = function() {};

        that.getLens = function(item) {
            if (item.type[0] === "Object") {
                return itemLens;
            }
        };

        return that;
    };

    /*
     * The room description presentation pulls together a description of the room, the allowed actions in
     * the room, and a list of objects present in the room.
     *
     * This information is appended to the container instead of replacing the previous results.
     *
     * The 'render' function in the roomLens is called when the game starts.  After that, the
     * update function on the object that render() returns is called when the player's object is updated.
     *
     */
    MITHGrid.Presentation.RoomDescription = function(container, options) {
        var that = MITHGrid.Presentation.initView("RoomDescription", container, options),
		game = that.options.application,
        roomLens = {
            render: function(container, view, model, itemId) {
                var that = {},
                el, el2,
				thingsInEnvExpr = model.prepare(["!environment.id"]),
                room = model.getItem(model.getItem('player').environment[0]);

				/* thingsInEnvExpr is a prepared expression that will find all of the things in the game database
				 * that share the same environment as the provided object id - in this case, it will be the id
				 * of the room that the player is in
				 */
				var doRender = function() {
					var things = { "Word": [], "Object": [] },
					thingIds = thingsInEnvExpr.evaluate([room.id[0]]);
					
					//console.log(thingIds);
                    el = $('<p class="desc">' + room.description[0] + '</p>');
                    $(container).append(el);
	                // look for items with the same environment -- append them to $(container)
					$.each(thingIds, function(idx, thing) {
						var item = model.getItem(thing);
						if(item.type !== undefined) {
							things[item.type[0]] = things[item.type[0]] || [];
							things[item.type[0]].push(item);
						}
					});
					
					/* available items have a type of 'Object' */
					if (things.Object.length > 0) {
					    el = $('<ul class="objects"></ul>');
					    $.each(things.Object,
					    function(idx, object) {
					        var objEl;

					        objEl = $('<li>' + object.name[0] + '</li>');
					        $(el).append(objEl);

					        // we allow the player to pick up the item by clicking on the item name
					        objEl.click(function() {
					            if (model.getItem("player").environment[0] === object.environment[0]) {
					                model.updateItems([{
					                    id: object.id[0],
					                    environment: "player"
					                }]);
					            }
					        });
					    });
					    el2 = $('<div>Objects: </div>');
					    el2.append(el);
					    $(container).append(el2);
					}
					
					/* available actions have a type of 'Word' */
					if(things.Word.length > 0) {
						things.WordHash = { };
						things.WordList = [ ];
						$.each(things.Word, function(idx, word) {
							if(things.WordHash[word.word[0]] === undefined) {
								things.WordHash[word.word[0]] = true;
								things.WordList.push(word.word[0]);
							}
						});
						$.each(["N", "E", "S", "W", "U", "D"], function(idx, w) {
							var words = things.WordHash[w],
							cmdEl = $(".compass > ." + w.toLowerCase());
							if(words === undefined) {
								cmdEl.addClass("unavailable");
							}
							else {
								cmdEl.removeClass("unavailable");
							}
						});
					}

					$(container).parent().animate({
						scrollTop: $(el).offset().top - $(container).parent().offset().top + $(container).parent().scrollTop()
					});
				};
				
				/*
				 * an update just updates the room if the player's environment is different than the
				 * previously rendered room
				 */
                that.update = function(item) {
					if(room.id[0] !== item.environment[0]) {
						room = model.getItem(item.environment[0]);
						doRender();
					}
				};

				doRender();
				
                return that;
            }
        };

        that.startDisplayUpdate = function() {};
        that.finishDisplayUpdate = function() {};

        that.getLens = function(item) {
            if (item.type[0] === "Player") {
                return roomLens;
            }
        };

        return that;
    }

	/*
	 * This is the main application configuration, providing information about the game database, the
	 * various filtered data views, and the DOM content inside the container.
	 */
    MITHGrid.Application.Adventure = function(container, options) {
		// the initApp call sets up the basic data sources, views, and presentations we want to use
        var that = MITHGrid.Application.initApp("MITHGrid.Application.Adventure", container, {
            dataSources: [{
                label: 'adventure',
				// let the database know what kinds of items we expect to have
				types: [{
					label: "Player"
				}, {
					label: "Room"
				}, {
					label: "Object"
				}, {
					label: "Word"
				}, {
					label: "Note"
				}],
				// let the database know that the 'environment' property points to other items
				properties: [{
					label: "environment",
					valueType: "Item"
				}]
            }],
            dataViews: [{
                label: 'inventory',
                dataSource: 'adventure',
                collection: function(model, id) {
	
					// only allow items that have the 'player' as their environment
                    var item = model.getItem(id);
                    if (item.environment === undefined || item.type === undefined) {
                        return false;
                    }
                    if (item.environment[0] === "player" && item.type[0] === "Object") {
                        return;
                    }
                    else {
                        return false;
                    }
                },
            },
            {
                label: 'player',
                dataSource: 'adventure',
                collection: function(model, id) {
	
					// only allow the 'player' object in this -- useful for listening for changes to
					// the player object
					if(id === "player") {
						return;
					}
					else {
						return false;
					}
                }
            }],
			/*
			 * This is the DOM content we want within our configured container, but we need to wait
			 * until the DOM is ready before we try to add this
			 */
            viewSetup: "<div class='room'><div class='description'></div><div class='objects'></div></div>" +
            "<div class='directions'></div>" +
            "<div class='inventory-holder'><h2>Inventory</h2><ul class='inventory'></ul></div>"+
			"<div class='compass'><span class='n'>N</span><span class='e'>E</span><span class='w'>W</span>" +
			"<span class='s'>S</span><span class='u'>U</span><span class='d'>D</span></div>" +
			"<div class='cli'><input class='cli-input' type='text' name='command'></input></div>",
			/*
			 * here, we tie the presentation definitions from above to the DOM elements that will house the presentation
			 * we also point the presentation at the appropriate filtered data view
			 */
            presentations: [{
                type: MITHGrid.Presentation.TextList,
                container: "#" + $(container).attr('id') + " > .inventory-holder > .inventory",
                dataView: 'inventory'
            },
            {
                type: MITHGrid.Presentation.RoomDescription,
                container: "#" + $(container).attr('id') + " > .room > .description",
                dataView: 'player'
            }]
        }),
        selector = {},
        words = {},
		commands = {},
		lastCmd = "",
        ids = {
            inst: 0,
            note: 0
        },
        lastLoc = "",
        lastInst = {},
        lastObj = {},
		newLoc = "",
		thingsInEnvExpr = {},
        // location creation functions
        makeLoc = function(location, longDesc, shortDesc, flags) {
            var room = {
                id: 'room:' + location,
                label: location,
                description: longDesc,
                brief: shortDesc,
                flags: flags,
                type: 'Room'
            };
            // travels: each entry has 'command', 'condition', 'destination'
            lastLoc = room.id;
			that.dataSource.adventure.loadItems([room]);
        },
		remarkStr = "",
		remark = function(str) {
			remarkStr = str;
		},
		conditions = [],
		// creates an action word for the most recent location created
        makeInst = function(word, condition, destination) {
            var inst = {
                id: 'inst:' + ids.inst,
                environment: lastLoc,
                //destination: "room:" + destination,
                //condition: condition,
                word: word,
                type: 'Word'
            };
			if($.isFunction(condition)) {
				conditions.push(condition);
				inst.functionCondition = conditions.length-1;
			}
			else {
				inst.condition = condition;
			}
			if(destination === "sayit") {
				inst.remark = remarkStr;
			}
			else {
				inst.destination = "room:" + destination;
			}
            lastInst = inst;
            ids.inst += 1;
			that.dataSource.adventure.loadItems([inst]);
        },
		// creates an action synonym for the most recently created action word
        ditto = function(word) {
			lastInst = $.extend(true, {}, lastInst);
            lastInst.id = "inst:" + ids.inst;
            ids.inst += 1;
            lastInst.word = word;
			that.dataSource.adventure.loadItems([lastInst]);
        },
        // item creation functions
        newObj = function(label, name, base, location) {
            var obj = {
                id: "obj:" + label,
                label: label,
                name: name,
                environment: "room:" + location,
                type: 'Object'
            }
            lastObj = obj;
			that.dataSource.adventure.loadItems([obj]);
        },
		// attaches a note to the last item created
        newNote = function(note) {
            var n = {
                id: "note:" + ids.note,
                content: note,
                object: lastObj.id,
                type: 'Note'
            };
            ids.note += 1;
			that.dataSource.adventure.loadItems([n]);
        },
        player = function() {
            return that.dataSource.adventure.getItem('player');
        },
        getInstInfo = function(word) {
            return that.dataSource.actions.getItems();

        }
        isAtLocation = function(treasure, location) {
            var t = that.dataSource.adventure.getItem(treasure);
            return $.inArray("room:" + location, t.environment);
        },
        toting = function(treasure) {
            // is the player carrying this treasure?
			if(treasure.substr(0,4) !== "obj:") {
				treasure = "obj:" + treasure;
			}
            var t = that.dataSource.adventure.getItem(treasure);
            return t.environment[0] === "player";
        },
        move = function(treasure, location) {
			if(treasure.substring(0,4) !== "obj:") {
				treasure = "obj:" + treasure;
			}
            that.dataSource.adventure.updateItems([{
                id: treasure,
                environment: location
            }]);
        },
        drop = function(treasure) {
            if (toting(treasure)) {
                move(treasure, player().environment[0]);
            }
        },
        carry = function(treasure) {
            if (isAtLocation(treasure, player().environment[0])) {
                move(treasure, "player");
            }
        },
        destroy = function(treasure) {
            move(treasure, "room:limbo");
        },
        holding = function() {
            // returns how many items the player is carrying
            return that.dataView.inventory.items().length;
        },
		here = function(treasure) {
			var t = that.dataSource.adventure.getItem("obj:" + treasure);
			return t.environment[0] === "player" || t.environment[0] == player().environment[0];
		},
		oilHere = function() {
			var here = that.dataSource.adventure.getItem(player().environment[0]);
			return $.inArray("liquid", here.flags) >= 0 && $.inArray("oil", here.flags) >= 0;
		},
		noLiquidHere = function() {
			var here = that.dataSource.adventure.getItem(player().environment[0]);
			return $.inArray("liquid", here.flags) === -1;
		},
		waterHere = function() {
			var here = that.dataSource.adventure.getItem(player().environment[0]);
			return $.inArray("liquid", here.flags) >= 0 && $.inArray("oil", here.flags) === -1;
		},
		holds = function(treasure) {
			return function() { return toting(treasure); }
		},
		sees = function(treasure) {
			return function() { return isAtLocation(treasure, player().environment[0]); }
		},
		gameProps = {
			grate: 0
		},
		notValue = function(key, value) {
			return function() { 
				return gameProps[key] !== undefined && gameProps[key] !== value; 
			};
		},
		setGameProp = function(key, value) {
			gameProps[key] = value;
		},
		getGameProp = function(key) {
			return gameProps[key];
		},
		number_commands = 0,
		makeCommand = function(cmd, fn) {
			commands[cmd] = fn;
			lastCmd = cmd;
			number_commands += 1;
		},
		alias = function(cmd) {
			commands[cmd] = commands[lastCmd];
			number_commands += 1;
		},
		thingsInEnvironment = function(env) {
			if(thingsInEnvExpr.evaluate === undefined) {
				thingsInEnvExpr = that.dataSource.adventure.prepare(["!environment.id"]);
			}
			if(env === undefined) {
				env = player().environment[0];
			}
			return that.dataSource.adventure.getItems(thingsInEnvExpr.evaluate([env]));
		},
		inventory = function() {
			return thingsInEnvironment("player");
		},
		print = function(stuff) {
			var el,
			container = $(selector.description);
			el = $('<p class="info"></p>');
			el.append(stuff);
			$(container).append(el);
			$(container).parent().animate({
				scrollTop: $(el).offset().top - $(container).parent().offset().top + $(container).parent().scrollTop()
			});
		},
		error = function(stuff) {
			var el,
			container = $(selector.description);
			el = $('<p class="error"></p>');
			el.append(stuff);
			$(container).append(el);
			$(container).parent().animate({
				scrollTop: $(el).offset().top - $(container).parent().offset().top + $(container).parent().scrollTop()
			});
		},
		messWord = function(word, msg) {
			makeCommand(word, function(bits) { print(msg); });
		}
		;
		
		// our parsing here is going to be a bit different than in the literate programming example
		that.parseCommand = function(cmd) {
			var bits = [ ],
			things = [ ];
			
			newLoc = "";
			
			cmd = $.trim(cmd.toLowerCase());
			if(cmd === "") {
				return;
			}
			
			bits = cmd.split(" ");
			if(bits.length === 0) {
				return;
			}
			
			if(thingsInEnvExpr.evaluate === undefined) {
				thingsInEnvExpr = that.dataSource.adventure.prepare(["!environment.id"]);
			}
			
			if(bits.length == 2 && bits[0] === "go") {
				bits = [ bits[1] ];
			}
			
			if(bits.length == 1) {
				// likely a word in the environment
				if(bits[0] == "east") { bits[0] = "e"; }
				if(bits[0] == "west") { bits[0] = "w"; }
				if(bits[0] == "north") { bits[0] = "n"; }
				if(bits[0] == "south") { bits[0] = "s"; }
				if(bits[0] == "up") { bits[0] = "u"; }
				if(bits[0] == "down") { bits[0] = "d"; }
				
				bits[0] = bits[0].toUpperCase();
				things = $.grep(thingsInEnvironment(),
				function(word, idx) {
					return word.type[0] === "Word" && word.word[0] === bits[0];
				});
				if(things !== undefined && things.length > 0) {
					$.each(things, function(idx, word) {
						var condSatisfied = false;
						if(newLoc !== "") { return; }
						if(word.condition !== undefined) {
							if(word.condition[0] === 0) {
								condSatisfied = true;
							}
						}
						else if(word.functionCondition !== undefined) {
							condSatisfied = conditions[word.functionCondition[0]]();
						}
						if(condSatisfied) {
							if(word.destination !== undefined) {
								newLoc = word.destination[0];
							}
							else if(word.remark !== undefined) {
								print(word.remark[0]);
								newLoc = player().environment[0]; // don't move, but don't try to run command
							}
						}
					});
				}
			}
			
			bits[0] = bits[0].toLowerCase();
			if(newLoc === "") { // no movement, so we still haven't done anything
				if(commands[bits[0]] !== undefined) {
					commands[bits[0]](bits);
				}
				else {
					error("I don't understand what you mean.");
				}
			}

			if(newLoc !== "") {
				that.dataSource.adventure.updateItems([{
					id: "player",
					environment: newLoc
				}]);
			}
		};
		
		messWord("abra", "Good try, but that is an old worn-out magic word.");
		alias("abracadabra"); alias("opensesame"); alias("sesame");
		alias("shazam"); alias("hocus"); alias("pocus"); alias("hocuspocus");

		messWord("?", "I know of places, actions, and things.  Most of my vocabulary describes places and is used " +
			"to move you there.  To move, try words like forest, building, downstream, enter, east, west, north, " +
			"south, up, or down.  I know about a few special objects, like a black rod hidden in the cave.  These " +
			"objects can be manipulated using some of the action words that I know.  Usually you will need to " + 
			"give both the object and action words (in either order), but sometimes I can infer the object from " +
			"the verb alone.  Some objects also imply verbs; in particular, \"inventory\" implies \"take inventory\", " +
			"which causes me to give you a list of what you're carrying.  The objects have side effects; for " +
			"instance, the rod scares the bird.  Usually people having trouble moving just need to try a few more " +
			"words.  Usually people trying unsuccessfully to manipulate an object are attempting something beyond " +
			"their (or my!) capabilities and should try a completely different tack.  To speed the game you can " +
			"sometimes move long distances with a single word.  For example, \"building\" usually gets you to the " +
			"building from anywhere bove ground except when lost in the forest.  Also, note that cave passages " +
			"turn a lot, and that leaving a room to the north does not guarantee entering the next from the south. " +
			"<br/>Good luck!"
		);
		alias("help");
		
		messWord("tree", "The trees of the forest are large hardwood oak and maple, with an occasional grove of " +
			"pine or spruce.  There is quite a bit of undergrowth, largely birch and ash saplings plus nondescript " +
			"brushes of various sorts.  This time of year visibility is quite restricted by all the leaves, but " +
			"travel is quite easy if you detour around the spruce and berry bushes."
		);
		alias("trees");
		
		messWord("dig", "Digging without a shovel is quite impractical.  Even with a shovel progress is unlikely.");
		alias("excavate");
		
		messWord("lost", "I'm as confused as you are.");
		
		messWord("mist", "Mist is a white vapor, usually water, seen from time to time in caverns.  It can be found " +
		    "anywhere but is frequently a sign of a deep pit leading down to water."
		);
		
		
		
		makeCommand("take", function(bits) {
			// is there something in the player's environment that is named by bits[1]?
			var things = $.grep(thingsInEnvironment(), function(thing, idx) {
				return thing.type[0] === "Object" && (
					$.inArray(bits[1], thing.label) || $.inArray(bits.slice(1).join(" "), thing.name)
				);
			});
			if( things.length === 0 ) {
				things = $.grep(inventory(), function(thing, idx) {
					return thing.type[0] === "Object" && (
						$.inArray(bits[1], thing.label) || $.inArray(bits.slice(1).join(" "), thing.name)
					);
				});
				if( things.length === 0) {
					error("I don't see anything like that here.");
				}
				else {
					print("You already have that.");
				}
			}
			else if(things.length === 1) {
				carry(things[0].id[0]);
				if(toting(things[0].id[0])) {
					print("You " + bits[0] + " the "+ things[0].label[0] + ".");
				}
				else {
					print("You try to " + bits[0] + " the " + things[0].label[0] + ", but they slip through your fingers.");
				}
			}
			else {
				print("I'm not sure which of these you're talking about: " + 
				      $.map(things, function(thing) { return thing.label[0]; }).join(", ") + ".");
			}
		});
		alias("carry"); alias("keep"); alias("catch");
		alias("capture"); alias("steal"); alias("get");
		alias("tote");
		
		makeCommand("drop", function(bits) {
			var things = $.grep(inventory(), function(thing, idx) {
				return thing.type[0] === "Object" && (
					$.inArray(bits[1], thing.label) || $.inArray(bits.slice(1).join(" "), thing.name)
				);
			});
			if(things.length === 0) {
				print("You have to have that before you can "+ bits[0] + " it.");
			}
			else if(things.length === 1) {
				drop(things[0].id[0]);
				if(!toting(things[0].id[0])) {
					print("You " + bits[0] + " the " + things[0].label[0] + ".");
				}
				else {
					print("You try to " + bits[0] + " the " + things[0].label[0] + ", but they stick to your hands.");
				}
			}
			else if(things.length > 1) {
				print("I'm not sure which of these you're talking about: " +
				      $.map(things, function(thing) { return thing.label[0]; }).join(", ") + ".");
			}
		});
		alias("release"); alias("free"); alias("discard");
		alias("dump");
		
		makeCommand("open", function(bits) {
			
		});
		alias("unlock");
		
		makeCommand("close", function(bits) {
			
		});
		alias("lock");
		
		makeCommand("light", function(bits) {
			
		});
		alias("on");
		
		makeCommand("extinguish", function(bits) {
			
		});
		alias("off");

		makeCommand("wave", function(bits) {
			
		});
		alias("shake"); alias("swing");
		
		makeCommand("calm", function(bits) {
			
		});
		alias("placate"); alias("tame");

		// the following create the locations and movement between locations
        makeLoc("road",
        "You are standing at the end of a road before a small brick building.\n" +
        "Around you is a forest.  A small stream flows out of the building and\n" +
        "down a gully.",
        "You're at end of road again.",
        ["lighted", "liquid"]
        );
        makeInst("W", 0, "hill");
        ditto("U");
        ditto("ROAD");
        makeInst("E", 0, "house");
        ditto("IN");
        ditto("HOUSE");
        ditto("ENTER");
        makeInst("S", 0, "valley");
        ditto("D");
        ditto("GULLY");
        ditto("STREAM");
        ditto("DOWNSTREAM");
        makeInst("N", 0, "forest");
        ditto("WOODS");
        makeInst("DEPRESSION", 0, "outside");

        makeLoc("hill",
        "You have walked up a hill, still in the forest.  The road slopes back\n" +
        "down the other side of the hill.  There is a building in the distance.",
        "You're at hill in road.",
        "lighted"
        );
        makeInst("ROAD", 0, "road");
        ditto("HOUSE");
        ditto("FORWARD");
        ditto("E");
        ditto("D");
        makeInst("WOODS", 0, "forest");
        ditto("N");
        ditto("S");

        makeLoc("house",
        "You are inside a building, a well house for a large spring.",
        "You're inside building.",
        ["lighted", "liquid"]
        );
        makeInst("ENTER", 0, "road");
        ditto("OUT");
        ditto("OUTDOORS");
        ditto("W");
        makeInst("XYZZY", 0, "debris");
        makeInst("PLUGH", 0, "y2");
        makeInst("DOWNSTREAM", 0, "sewer");
        ditto("STREAM");

        makeLoc("valley",
        "You are in a valley in the forest beside a stream tumbling along a\n" +
        "rocky bed.",
        "You're in valley.",
        ["lighted", "liquid"]
        );
        makeInst("UPSTREAM", 0, "road");
        ditto("HOUSE");
        ditto("N");
        makeInst("WOODS", 0, "forest");
        ditto("E");
        ditto("W");
        ditto("U");
        makeInst("DOWNSTREAM", 0, "slit");
        ditto("S");
        ditto("D");
        makeInst("DEPRESSION", 0, "outside");

        makeLoc("forest",
        "You are in open forest, with a deep valley to one side.",
        "You're in forest.",
        "lighted"
        );
        makeInst("VALLEY", 0, "valley");
        ditto("E");
        ditto("D");
        makeInst("WOODS", 50, "forest");
        ditto("FORWARD");
        ditto("N");
        makeInst("WOODS", 0, "woods");
        makeInst("W", 0, "forest");
        ditto("S");

        makeLoc("woods",
        "You are in open forest near both a valley and a road.",
        "You're in forest",
        "lighted"
        );
        makeInst("ROAD", 0, "road");
        ditto("N");
        makeInst("VALLEY", 0, "valley");
        ditto("E");
        ditto("W");
        ditto("D");
        makeInst("WOODS", 0, "forest");
        ditto("S");

		makeLoc("slit",
		"At your feet all the water of the stream splashes into a 2-inch slit\n" +
		"in the rock.  Downstream the streambed is bare rock.",
		"You're at slit in streambed.",
		["lighted", "liquid"]
		);
		makeInst("HOUSE", 0, "road");
		makeInst("UPSTREAM", 0, "valley");
		ditto("N");
		makeInst("WOODS", 0, "forest");
		ditto("E");
		ditto("W");
		makeInst("DOWNSTREAM", 0, "outside");
		ditto("ROCK");
		ditto("BED");
		ditto("S");
		remark("You don't fit through a two-inch slit!");
		makeInst("SLIT", 0, "sayit");
		ditto("STREAM");
		ditto("D");
		
		makeLoc("outside",
		"You are in a 20-foot depression floored with bare dirt.  Set into the\n" +
		"dirt is a strong steel grate mounted in concrete.  A dry streambed\n" +
		"leads into the depression.",
		"You're outside grate.",
		[ "lighted", "cave_hint" ]
		);
		makeInst("WOODS", 0, "forest");
		ditto("E");
		ditto("W");
		ditto("S");
		makeInst("HOUSE", 0, "road");
		makeInst("UPSTREAM", 0, "slit");
		ditto("GULLY");
		ditto("N");
		makeInst("ENTER", notValue("grate", 0), "inside");
		ditto("ENTER");
		ditto("IN");
		ditto("D");
		remark("You can't go through a locked steel grate!");
		makeInst("ENTER", 0, "sayit");

        // next location: section 30, page 18 ("inside")
        // now add a few one-place objects (section 70, page 48)
        newObj("chain", "Golden chain", "chain", "barr");
        newNote("There is a golden chain lying in a heap on the floor!");
        newNote("The bear is locked to the wall with a golden chain!");
        newNote("There is a golden chain locked to the wall!");

        newObj("keys", "Set of keys", 0, "house");
        newNote("There are some keys on the ground here.");

        // user interface stuff
        //
        // double click on an item in the room will pick it up
        // double click on an item in the inventory will drop it
        // clicking on an exit will go through that exit
        //
        // we also have a CLI for commands
        that.ready(function() {
	        selector.description = "#" + $(container).attr('id') + " > .room > .description";
            selector.objects = "#" + $(container).attr('id') + " > .room > .objects";
            selector.directions = "#" + $(container).attr('id') + " > .directions";
            selector.inventory = "#" + $(container).attr('id') + " > .inventory";
			selector.cli = "#" + $(container).attr('id') + " > .cli > .cli-input";
			selector.compass = "#" + $(container).attr('id') + " > .compass";
        });
        // selectors:
        //   description: "#" + $(container).id + " .room .description"
        //   objects: ... ".room .description"
        //   cli: ... ".cli"
        //   directions: ... ".directions"
        //   inventory: ... ".inventory"
        that.ready(function() {
			that.dataSource.adventure.loadItems([{
	            id: "player",
	            label: "You, the Player",
	            environment: "room:road",
	            type: 'Player'
	        }]);
			
			$('#number-rooms').text($.grep(that.dataSource.adventure.items(), function(id, idx) {
				return that.dataSource.adventure.getItem(id).type[0] === "Room"
			}).length);
			$('#number-objects').text($.grep(that.dataSource.adventure.items(), function(id, idx) {
				return that.dataSource.adventure.getItem(id).type[0] === "Object"
			}).length);
			$('#number-verbs').text(number_commands + 1); // +1 for "go"
			
			$(selector.cli).keypress(function(event) {
				var cmd;
				if( event.which === 13 ) {
					event.preventDefault();
					cmd = $(selector.cli).val();
					$(selector.cli).val('');
					that.parseCommand(cmd);
				}
			});
			
			// make compass active
			$.each(['n', 's', 'e', 'w', 'u', 'd'], function(idx, dir) {
				$(selector.compass + " ." + dir).click(function() {
					if($(selector.compass + " ." + dir).hasClass("unavailable")) {
						return;
					}
					that.parseCommand(dir);	
				});
			})
			$(selector.cli).focus();
        });

        return that;
    };
} (jQuery, MITHGrid));