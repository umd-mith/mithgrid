/*
 * This version of Adventure is based on the literate programming version available at
 * http://www.literateprogramming.com/adventure.pdf
 * Copyright (C) 1998 by Don Woods and Don Knuth; all rights reserved
 *
 * This illustrates the use of data views providing different filtered versions of the core
 * data store.
 *
 */

 (function($, MITHGrid) {

    /*
	 * This is the main application configuration, providing information about the game database, the
	 * various filtered data views, and the DOM content inside the container.
	 */
	MITHGrid.Application.namespace("Adventure");
    MITHGrid.Application.Adventure.initApp = function(container, options) {
        // the initApp call sets up the basic data sources, views, and presentations we want to use
        var that = MITHGrid.Application.initApp("MITHGrid.Application.Adventure", container, options, {
		    /*
			 * here, we tie the presentation definitions from presentations.js to the DOM elements that will house
			 * the presentation 
			 * we also point the presentation at the appropriate filtered data view
			 * the label is used to refer to the presentation later if we need to:
			 *   that.presentation[label]
			 */
			    presentations: {
					inventory: {
			            type: MITHGrid.Presentation.TextList,
			            container: ".inventory-holder > .inventory",
			            dataView: 'inventory',
			            lenses: {
			                "Object": function(container, view, model, itemId) {
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
			            }
			        },
			    	score: {
			            type: MITHGrid.Presentation.TextList,
			            container: ".score-holder > .score",
			            dataView: 'player',
						lenses: {
							Player: function(container, view, model, itemId) {
								var that = { },
								el,
								doRender = function() {
									var player = model.getItem(itemId);
									el = $("<span>0</span>");
									$(el).appendTo(container);
									el.text(player.score[0]);
								};

								that.update = function(item) {
									el.text(item.score[0]);
								};

								doRender();
								return that;
							}
						}
			        },
			    	room: {
			            type: MITHGrid.Presentation.TextList,
			            container: ".room > .description",
			            dataView: 'player',
			            lenses: {
							Player: function(container, view, model, itemId) {
					            var rendering = {}, // here, "that" refers to the game application
					            el, el2,
								thingsInEnvExpr = model.prepare(["!environment.id"]),
								notesForObjectExpr = model.prepare(["!object.id"]),
					            room = model.getItem(model.getItem('player').environment[0]);

								/* thingsInEnvExpr is a prepared expression that will find all of the things in the game database
								 * that share the same environment as the provided object id - in this case, it will be the id
								 * of the room that the player is in
								 */
								var doRender = function(override_brief) {
									var things = { "Word": [], "Object": [] },
									thingIds = thingsInEnvExpr.evaluate([room.id[0]]),
									player = model.getItem('player'),
									roomDesc = "", hasForce = false, bear;

									//console.log(thingIds);
									if(that.isDark() && !that.wasForced()) {
										roomDesc = ""
									}
									else {
										if(player.brief[0] || (room.timesHere[0] % 5 !== 0)) {
											roomDesc = room.brief[0];
										}
										if(roomDesc === "" || roomDesc === undefined || override_brief === true) {
											roomDesc = room.description[0];
						                }
									}

									if(!that.isDark()) {
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
										    $.each(things.Object,
										    function(idx, object) {
										        var notes = [ ],
												note_idx = 0;

												// we want to find the first note associated with this object
												// the 'value' property of the item indexes the notes
												if(object.value !== undefined) {
													note_idx = object.value[0];
												}

												notes = model.getItems(notesForObjectExpr.evaluate([object.id[0]]));

												if(notes.length < note_idx) {
													note_idx = 0;
												}
												if(notes.length === 0) {
													roomDesc += " You see a " + object.name[0].toLowerCase + ". ";
												}
												else {
													if(notes[note_idx].content[0]) {
														roomDesc += " " + notes[note_idx].content[0] + " ";
													}
												}
										    });
										}
									}

									/* available actions have a type of 'Word' */
									if(things.Word.length > 0) {
										things.WordHash = { };
										things.WordList = [ ];
										$.each(things.Word, function(idx, word) {
											if(things.WordHash[word.word[0]] === undefined) {
												things.WordHash[word.word[0]] = [];
												things.WordList.push(word.word[0]);
											}
											things.WordHash[word.word[0]].push(word);
										});
										$.each(["N", "E", "S", "W", "U", "D"], function(idx, w) {
											var words = things.WordHash[w],
											cmdEl = $(".compass > ." + w.toLowerCase());
											if(words === undefined || that.isDark()) {
												cmdEl.addClass("unavailable");
											}
											else {
												cmdEl.removeClass("unavailable");
											}
										});

										if(things.WordHash.FORCE !== undefined && things.WordHash.FORCE.length > 0) {
											// we force the player to do these
											hasForce = true;
											setTimeout(function() {
												game.parseCommand("force");
											}, 0);
										}
									}

									if(hasForce) {
										el = $("<p class='info'>" + roomDesc + "</p>");
									}
									else if(!that.isDark()){
										bear = model.getItem("obj:bear");
										if(bear.environment[0] === "player") {
											roomDesc += " You are being followed by a very large, tame bear.";
										}
										el = $('<p class="desc">' + roomDesc + '</p>');
									}

					                $(container).append(el);

									$(container).parent().animate({
										scrollTop: $(el).offset().top - $(container).parent().offset().top + $(container).parent().scrollTop()
									});
								};

								/*
								 * an update just updates the room if the player's environment is different than the
								 * previously rendered room
								 */
					            rendering.update = function(item) {
									if(room.id[0] !== item.environment[0]) {
										room = model.getItem(item.environment[0]);
										doRender();
										model.updateItems([{
											id: room.id,
											timesHere: room.timesHere[0] + 1
										}]);
									}
								};

								rendering.reRender = function(override_brief) {
									doRender(override_brief);
								};

								doRender();
								model.updateItems([{
									id: room.id,
									timesHere: room.timesHere[0] + 1
								}]);

					            return rendering;
					        }
			            }
			        }
				}
			}),
        selector = {},
        // holds DOM selectors for various parts of the game display
        commands = {},
        // maps the command to the appropriate function
        lastCmd = "",
        // holds the name of the last command for creating aliases
        ids = {
            // holds the last assigned id number for words and notes
            inst: 0,
            note: 0,
            location: 0,
        },
        lastLoc = "",
        // the id of the last Room created
        lastInst = {},
        // the object representing the last Word created
        lastObj = {},
        // the object representing the last Object created
        thingsInEnvExpr = {},
        // will be the prepared expression to list things in an environment
        /*
		 * makeLoc: location (room label)
		 *			long description
		 *			short description
		 *			optional flags (array if more than one; flags are strings)
		 *				lighted: room is lit and does not require lamp
		 *				liquid:  room has liquid (water by default)
		 *				oil:     room has oil as its liquid
		 *				snake hint: provide a hint about the snake
		 *				twist hint: provide a hint about the twisty maze
		 *
		 * makeLoc creates a room in the database
		 */
        makeLoc = function(location, longDesc, shortDesc, flags) {
            var room = {
                id: 'room:' + location,
                label: location,
                description: longDesc,
                brief: shortDesc,
                flags: flags,
                locationCount: ids.location,
                timesHere: 0,
                type: 'Room'
            };
            // travels: each entry has 'command', 'condition', 'destination'
            ids.location += 1;
            lastLoc = room.id;
            that.dataStore.adventure.loadItems([room]);
        },
        lastOutsideRoom = 0,
        remarkStr = "",
        // temporary holder
        /*
		 * remark: str
		 *
		 * remark sets the string that will be shown for Words that have the destination of "sayit"
		 */
        remark = function(str) {
            remarkStr = str;
        },
        conditions = [],
        // holds functions for conditions since the database can't handle functions yet
        /*
		 * makeInst: word
		 *			 condition
		 *				0: always available/happens
		 *				1-99: will fail with the indicated probability
		 *				100: dwarves will not go this direction
		 *				function: works if function returns true
		 *			 destination
		 *
		 * makeInst creates an action word for the most recent location created
		 */
        makeInst = function(word, condition, destination) {
            var inst = {
                id: 'inst:' + ids.inst,
                environment: lastLoc,
                //destination: "room:" + destination,
                //condition: condition,
                word: word,
                type: 'Word'
            };
            if ($.isFunction(condition)) {
                conditions.push(condition);
                inst.functionCondition = conditions.length - 1;
            }
            else {
                inst.condition = condition;
            }
            if (destination === "sayit") {
                inst.remark = remarkStr;
            }
            else {
                inst.destination = "room:" + destination;
            }
            lastInst = inst;
            ids.inst += 1;
            that.dataStore.adventure.loadItems([inst]);
        },
        // creates an action synonym for the most recently created action word
        ditto = function(word) {
            lastInst = $.extend(true, {},
            lastInst);
            lastInst.id = "inst:" + ids.inst;
            ids.inst += 1;
            lastInst.word = word;
            that.dataStore.adventure.loadItems([lastInst]);
        },
        /*
		 * force: destination
		 *		  condition
		 *
		 * force creates a conditional motion that always executes as soon as the player enters the location
		 * this is shorthand for: makeInst("FORCE", condition, destination)
		 */
        force = function(dest, c) {
            if (c === undefined) {
                c = 0;
            }
            makeInst("FORCE", c, dest);
        },
        /*
		 * newObj:  label (used in some other functions to refer to this object)
		 *			name (used in the inventory listing)
		 *			base (not used yet, but may be the same as the label)
		 *			location (id of the initial room in which this object appears, without the "room:" prefix)
		 *
		 * newObj creates a new object.  If location is an array, then it appears in multiple locations
		 */
        newObj = function(labels, name, base, location) {
            var obj = {
                label: labels,
                value: 0,
                type: 'Object'
            }
            if ($.isArray(labels)) {
                obj.id = "obj:" + labels[0];
                if (base === undefined || base === 0) {
                    base = labels[0];
                }
            }
            else {
                obj.id = "obj:" + labels;
                if (base === undefined || base === 0) {
                    base = labels;
                }
            }
            obj.base = base;
            if (name !== 0) {
                obj.name = name;
            }
            if ($.isArray(location)) {
                obj.environment = $.map(location,
                function(l, i) {
                    return "room:" + l;
                });
            }
            else {
                obj.environment = "room:" + location;
            }
            lastObj = obj;
            that.dataStore.adventure.loadItems([obj]);
        },
        /*
		 * newNote: note
		 *
		 * newNote attaches a note to the most recently created item
		 * notes are used in building the room description.  multiple notes can be used to describe the
		 * state of an object.  The getGameProp(label) function is used as an index into the list of notes
		 * for the object with the given label.
		 */
        newNote = function(note) {
            var n = {
                id: "note:" + ids.note,
                content: note,
                object: lastObj.id,
                type: 'Note'
            };
            ids.note += 1;
            that.dataStore.adventure.loadItems([n]);
        },
        /*
		 * player() always returns the database info for the player
		 */
        player = function() {
            return that.dataStore.adventure.getItem('player');
        },
        /* 
		 * returns true if the treasure is at the given location 
		 */
        isAtLocation = function(treasure, location) {
            var t;
            if (treasure.substr(0, 4) !== "obj:") {
                treasure = "obj:" + treasure;
            }
            t = that.dataStore.adventure.getItem(treasure);
            return $.inArray("room:" + location, t.environment);
        },
        /*
		 * returns true if the treasure is in the player's inventory
		 */
        toting = function(treasure) {
            // is the player carrying this treasure?
            if (treasure.substr(0, 4) !== "obj:") {
                treasure = "obj:" + treasure;
            }
            var t = that.dataStore.adventure.getItem(treasure);
            return t.environment[0] === "player";
        },
        /*
		 * moves the treasure to the designated location
		 */
        move = function(treasure, location) {
            if (treasure.substr(0, 4) !== "obj:") {
                treasure = "obj:" + treasure;
            }
            if (location !== "player" && location.substr(0, 5) !== "room:") {
                location = "room:" + location;
            }
            that.dataStore.adventure.updateItems([{
                id: treasure,
                environment: location
            }]);
        },
        /*
		 * moves the treasure to the room the player is in
		 */
        drop = function(treasure) {
            if (toting(treasure)) {
                move(treasure, player().environment[0]);
            }
        },
        /*
		 * returns the number of items the player is carrying
		 */
        holding = function() {
            return that.dataView.inventory.items().length;
        },
        /*
		 * moves the given item to the player's inventory if it is in the player's room
		 */
        carry = function(treasure) {
            if (isAtLocation(treasure, player().environment[0])) {
                move(treasure, "player");
            }
        },
        /*
		 * 'destroy's an object by moving it to limbo.  Player's can't get to limbo
		 */
        destroy = function(treasure) {
            move(treasure, "room:limbo");
        },
        /*
		 * returns true if the treasure is in the player's inventory or in the same room as the player
		 */
        here = function(treasure) {
            var t = that.dataStore.adventure.getItem("obj:" + treasure);
            return t.environment[0] === "player" || t.environment[0] == player().environment[0];
        },
        /*
		 * returns true if there is oil in the room (liquid + oil flags)
		 */
        oilHere = function() {
            var here = that.dataStore.adventure.getItem(player().environment[0]);
            return $.inArray("liquid", here.flags) >= 0 && $.inArray("oil", here.flags) >= 0;
        },
        /*
		 * returns true if there is neither oil nor water here
		 */
        noLiquidHere = function() {
            var here = that.dataStore.adventure.getItem(player().environment[0]);
            return $.inArray("liquid", here.flags) === -1;
        },
        /*
		 * returns true if there is water in the room (liquid flag, but no oil flag)
		 */
        waterHere = function() {
            var here = that.dataStore.adventure.getItem(player().environment[0]);
            return $.inArray("liquid", here.flags) >= 0 && $.inArray("oil", here.flags) === -1;
        },
        /*
		 * when constructing room exits, it's useful to have helper functions to create the
		 * condition functions...
		 */

        /*
		 * returns a function that tests if the player has a treasure in their inventory
		 */
        holds = function(treasure) {
            return function() {
                return toting(treasure);
            }
        },
        /*
		 * returns a function that tests if the player can see the object in their environment
		 */
        sees = function(treasure) {
            return function() {
                return isAtLocation(treasure, player().environment[0]);
            }
        },
        /*
		 * returns the value property of the object -- this is used to track the state of an object
		 * this value also affects which note is shown in a room description
		 */
        getGameProp = function(key) {
            var item = that.dataStore.adventure.getItem("obj:" + key);
            if (item === undefined || item.value === undefined) {
                return 0;
            }
            else {
                if (item.base === undefined || item.base[0] === item.label[0]) {
                    return item.value[0];
                }
                else {
                    return getGameProp(item.base[0]);
                }
            }
        },
        /*
		 * returns a function that tests the value property of an object
		 */
        notValue = function(obj, value) {
            return function() {
                var sv = getGameProp(obj);
                return sv !== value;
            };
        },
        /*
		 * set the value of an object - this hides how we're tracking the status of objects
		 */
        setGameProp = function(key, value) {
            var item = that.dataStore.adventure.getItem("obj:" + key);
            if (item === undefined || item.id === undefined) {
                that.dataStore.adventure.loadItems([{
                    id: "obj:" + key,
                    label: key,
                    value: value,
                    base: key,
                    type: "Object",
                    environment: "room:limbo"
                }]);
            }
            else {
                that.dataStore.adventure.updateItems([{
                    id: "obj:" + key,
                    value: value
                }]);
            }
        },
        number_commands = 0,
        // used to cache the number of commands in the game
        /*
		 * makeCommand: cmd (the command used by the player)
		 *				fn (the function that implements the command)
		 */
        makeCommand = function(cmd, fn) {
            commands[cmd] = fn;
            lastCmd = cmd;
            number_commands += 1;
        },
        /*
		 * makes an alias for the previously defined command
		 */
        alias = function(cmd) {
            commands[cmd] = commands[lastCmd];
            number_commands += 1;
        },
        /*
		 * thingsInEnvironment: env (the location we're looking in)
		 *						bits (array of words that make up the name of the item we're looking for)
		 */
        thingsInEnvironment = function(env, bits) {
            var things;
            if (thingsInEnvExpr.evaluate === undefined) {
                thingsInEnvExpr = that.dataStore.adventure.prepare(["!environment.id"]);
            }
            if (env === undefined || env === 0) {
                env = player().environment[0];
            }
            things = that.dataStore.adventure.getItems(thingsInEnvExpr.evaluate([env]));
            if (bits === undefined) {
                return things;
            }
            if (!$.isArray(bits)) {
                bits = [bits];
            }
            else {
                return $.grep(things,
                function(thing, idx) {
                    return thing.type[0] === "Object" && (
                    $.inArray(bits[0], thing.label) > -1 || $.inArray(bits.join(" "), thing.name) > -1
                    );
                })
            }
        },
        /*
		 * returns the list of things matching the name in the player's inventory
		 */
        inventory = function(bits) {
            return thingsInEnvironment("player", bits);
        },
        /*
		 * adds an informative message to the DOM element holding the room descriptions -- effectively adds the info
		 * to the running game narrative
		 */
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
        /*
		 * adds an error message to the game narrative
		 */
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
        /*
		 * adds a command that simply prints out the message
		 */
        messWord = function(word, msg) {
            makeCommand(word,
            function(bits) {
                print(msg);
            });
        },
        /*
		 * the following are common aliases for movement commands
		 */
        commandAliases = {
            north: "N",
            south: "S",
            east: "E",
            west: "W",
            upwards: "U",
            up: "U",
            above: "U",
            ascend: "U",
            downward: "D",
            down: "D",
            descend: "D",
            left: "L",
            right: "R",
            inward: "IN",
            inside: "IN",
            outside: "OUT",
            exit: "OUT",
            leave: "OUT",
            "continue": "FORWARD",
            onward: "FORWARD",
            "return": "BACK",
            retreat: "BACK",
            forest: "WOODS",
            building: "HOUSE",
            slabrock: "SLAB",
            tunnel: "PASSAGE",
            main: "OFFICE",
            "null": "NOWHERE",
            walk: "GO",
            run: "GO",
            travel: "GO",
            proceed: "GO",
            explore: "GO",
            "goto": "GO",
            follow: "GO",
            turn: "GO"
        },
        west_count = 0
        // how many times we have parsed the word 'west'
        was_dark = false,
        dark = false
        ;

		console.log(that);
        that.isDark = function() {
            return dark;
        };
        that.wasDark = function() {
            return was_dark;
        };

        /*
		 * our parsing here is going to be a bit different than in the literate programming example
		 *
		 * we make this a method on the game object so that the presentations can access the parser
		 * we force the player to execute the 'FORCE' command after moving to a room - this executes
		 * the various automatic events upon entry
		 */
        that.parseCommand = function(cmd, fail_if_unknown) {
            var bits = [],
            things = [],
            newLoc = "",
            value = 0,
            dest = {};

            cmd = $.trim(cmd.toLowerCase());
            if (cmd === "") {
                return;
            }

            if (cmd === "force") {
                that.wasForced = function() {
                    return true;
                }
            }
            else {
                that.wasForced = function() {
                    return false;
                }
            }

            bits = cmd.split(" ");
            if (bits.length === 0) {
                return;
            }

            if (commandAliases[bits[0]] !== undefined) {
                bits[0] = commandAliases[bits[0]].toLowerCase();
            }

            if (thingsInEnvExpr.evaluate === undefined) {
                thingsInEnvExpr = that.dataStore.adventure.prepare(["!environment.id"]);
            }

            if (bits.length == 2 && bits[0] === "go") {
                bits = [bits[1]];
            }

            /*
			 * if we only have a single word in the command, we look for actions attached to the room
			 *
			 * we allow the various cardinal directions to map to their abbreviations; we don't do this
			 * for southwest, etc., which are used as (sw, ...) in the mazes
			 */
            if (bits.length == 1) {
                bits[0] = bits[0].toUpperCase();
                if (bits[0] === "WEST") {
                    west_count += 1;
                    if (west_count === 10) {
                        print("If you prefer, simply type W rather than WEST.");
                    }
                }
                things = $.grep(thingsInEnvironment(),
                function(word, idx) {
                    return word.type[0] === "Word" && word.word[0] === bits[0];
                });

                if (things !== undefined && things.length > 0) {
                    $.each(things,
                    function(idx, word) {
                        var condSatisfied = false;
                        if (newLoc !== "") {
                            return;
                        }
                        if (word.condition !== undefined) {
                            if ($.type(word.condition[0]) === "number") {
                                value = parseInt(word.condition[0]);
                                if (value === 0) {
                                    condSatisfied = true;
                                }
                                else if (value > 0 && value < 100) {
                                    condSatisfied = Math.foor(Math.random() * 100) >= value;
                                }
                            }
                        }
                        else if (word.functionCondition !== undefined) {
                            condSatisfied = conditions[word.functionCondition[0]]();
                        }
                        if (condSatisfied) {
                            if (word.destination !== undefined) {
                                newLoc = word.destination[0];
                            }
                            else if (word.remark !== undefined) {
                                print(word.remark[0]);
                                newLoc = player().environment[0];
                                // don't move, but don't try to run command
                            }
                        }
                    });
                    /*
					 * if we found at least one action in the environment, then either we move to a different
					 * location, or we stay put
					 * either way, we're done executing the command at this point.
					 */
                    if (newLoc === "") {
                        newLoc = player().environment[0];
                        print("You can't go that way!");
                        return;
                    }
                }
            }

            bits[0] = bits[0].toLowerCase();

            if (newLoc === "") {
                // no movement, so we still haven't done anything
                if (commands[bits[0]] !== undefined) {
                    commands[bits[0]](bits);
                }
                else {
                    if (fail_if_unknown === true) {
                        error("I don't understand what you mean.");
                    }
                    else {
                        that.parseCommand(bits[1] + " " + bits[0], true);
                    }
                }
            }
            else {
                dest = that.dataStore.adventure.getItem(newLoc);
                if (dest === undefined || dest.type === undefined || dest.type[0] !== "Room") {
                    /*
					 * once the game is complete, this should never happen
					 * we get here if we try to go to a location that hasn't been defined yet
					 */
                    print("You can't go that way! (" + newLoc + ")");
                }
                else {
                    /*
					 * we move the player to the new location
					 * this will cascade to the room description presentation, which will in turn execute the
					 * 'FORCE' command on the player, so we may end up back here again
					 */
                    was_dark = dark;
                    that.dataStore.adventure.updateItems([{
                        id: "player",
                        environment: newLoc
                    }]);
                }
            }
        };

        that.ready(function() {
            selector.description = "#" + $(container).attr('id') + " > .room > .description";
            selector.objects = "#" + $(container).attr('id') + " > .room > .objects";
            selector.inventory = "#" + $(container).attr('id') + " > .inventory";
            selector.cli = "#" + $(container).attr('id') + " > .cli > .cli-input";
            selector.compass = "#" + $(container).attr('id') + " > .compass";
        });

        that.ready(function() {
            that.dataStore.adventure.loadItems([{
                id: "player",
                label: "You, the Player",
                environment: "room:road",
                score: 0,
                brief: false,
                type: 'Player'
            }]);

            $('#number-rooms').text($.grep(that.dataStore.adventure.items(),
            function(id, idx) {
                return that.dataStore.adventure.getItem(id).type[0] === "Room"
            }).length);
            $('#number-objects').text($.grep(that.dataStore.adventure.items(),
            function(id, idx) {
                return that.dataStore.adventure.getItem(id).type[0] === "Object"
            }).length);
            $('#number-verbs').text(number_commands + 1);
            // +1 for "go"
            $(selector.cli).keypress(function(event) {
                var cmd;
                if (event.which === 13) {
                    // "enter" will parse command
                    event.preventDefault();
                    cmd = $(selector.cli).val();
                    $(selector.cli).val('');
                    that.parseCommand(cmd);
                }
                else if (event.which === 21) {
                    // ctrl+U will erase line
                    $(selector.cli).val('');
                }
            });

            // make compass active
            $.each(['n', 's', 'e', 'w', 'u', 'd'],
            function(idx, dir) {
                $(selector.compass + " ." + dir).click(function() {
                    if ($(selector.compass + " ." + dir).hasClass("unavailable")) {
                        return;
                    }
                    that.parseCommand(dir);
                });
            })
            $(selector.cli).focus();
        });

        ////
        // The rest of this is the game data
        ////
        // we begin with non-motion commands
        messWord("abra", "Good try, but that is an old worn-out magic word.");
        alias("abracadabra");
        alias("opensesame");
        alias("sesame");
        alias("shazam");
        alias("hocus");
        alias("pocus");
        alias("hocuspocus");

        messWord("?", "I know of places, actions, and things.  Most of my vocabulary describes places and is used " +
        "to move you there.  To move, try words like forest, building, downstream, enter, east, west, north, " +
        "south, up, or down.  I know about a few special objects, like a black rod hidden in the cave.  These " +
        "objects can be manipulated using some of the action words that I know.  Usually you will need to " +
        "give both the object and action words (in either order), but sometimes I can infer the object from " +
        "the verb alone.  The objects have side effects; for " +
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

        messWord("stop", "I don't know the word \"stop\".  Use \"quit\" if you want to give up.");

        messWord("quit", "You can quit at any time by browsing to another page.");

        messWord("info", "If you want to end your adventure early, say \"quit\".  To get full credit for a treasure, " +
        "you must have left it safely in the building, though you get partial credit just for locating it.  You lose " +
        "points for getting killed, or for quitting, though the former costs you more.  There are also points based " +
        "on how much (if any) of the cave you've managed to explore; in particular, there is a large bonus just for " +
        "getting in (to distinguish the beginners from the rest of the pack), and there are other ways to determine " +
        "whether you've been through some of the more harrowing sections.  If you think you've found all the treasures, " +
        "just keep exploring for a while.  If nothing interesting happens, you haven't found them all yet.  If something " +
        "interesting DOES happen, it means you're getting a bonus and have an opportunity to garner many more points in " +
        "the master's section.<br /><br />I may occasionally offer hints if you seem to be having trouble.  If I do, " +
        "I'll warn you in advance how much it will affect your score to accept the hints.  Finally, to save paper, " +
        "you may specify \"brief\", which tells me never to repeat the full description of a place unless you explicitely " +
        "aske me to.");
        alias("information");

        messWord("swim", "I don't know how.");

        makeCommand("commands",
        function(bits) {
            var cmds = [],
            c;

            for (c in commands) {
                if (typeof c === "string") {
                    cmds.push(c);
                }
            }
            print("The following commands are available: " + cmds.sort().join(", ") + ".");
        })

        makeCommand("take",
        function(bits) {
            // is there something in the player's environment that is named by bits[1]?
            var things = thingsInEnvironment(undefined, bits.slice(1)),
            obj;
            if (things.length === 0) {
                things = inventory(bits.slice(1));
                if (things.length === 0 && $.inArray(bits[1], ["water", "oil"]) == -1) {
                    error("I don't see anything like that here.");
                    return;
                }
                print("You already have that.");
                return;
            }
            if (things.length === 1) {
                obj = things[0];
            }
            else if (things.length > 1) {
                print("I'm not sure which of these you're talking about: " +
                $.map(things,
                function(thing) {
                    return thing.label[0];
                }).join(", ") + ".");
                return;
            }
            if (bits[1] === "water") {
                return;
            }
            if (bits[1] === "oil") {
                return;
            }
            if (obj.name === undefined) {
                // immovable
                if (obj.id[0] === "obj:chain" && getGameProp("bear") > 0) {
                    print("The chain is still locked.");
                    return;
                }
                if (obj.id[0] === "obj:bear" && getGameProp("bear") == 1) {
                    print("The bear is still chained to the wall.");
                    return;
                }
                if (obj.id[0] === "obj:plant" && getGameProp("plant") <= 0) {
                    print("The plant has exceptionally deep roots and cannot be pulled free.");
                    return;
                }
                print("You can't be serious!");
                return;
            }
            if (holding() >= 7) {
                print("You can't carry anything more.  You'll have to drop something first.");
                return;
            }
            if (obj.id[0] === "obj:bird" && getGameProp("bird") == 0) {
                if (toting("rod")) {
                    print("The bird was unafraid when you entered, but as you approach it becomes\n" +
                    "disturbed and you cannot catch it.");
                    return;
                }
                if (toting("cage")) {
                    setGameProp("bird", 1);
                }
                else {
                    print("You can catch the bird, but you cannot carry it.");
                    return;
                }
            }
            if (obj.id[0] === "obj:bird" || (obj.id[0] === "obj:cage" && getGameProp("bird") > 0)) {
                if (obj.id[0] === "obj:bird") {
                    carry("obj:cage");
                }
                else {
                    carry("obj:bird");
                }
            }

            carry(things[0].id[0]);

            if (toting(things[0].id[0])) {
                print("You " + bits[0] + " the " + things[0].label[0] + ".");
            }
            else {
                print("You try to " + bits[0] + " the " + things[0].label[0] + ", but it slips through your fingers.");
            }
        });
        alias("carry");
        alias("keep");
        alias("catch");
        alias("capture");
        alias("steal");
        alias("get");
        alias("tote");

        makeCommand("drop",
        function(bits) {
            var things = inventory(bits.slice(1));
            if (things.length === 0) {
                print("You have to have that before you can " + bits[0] + " it.");
            }
            else if (things.length === 1) {
                drop(things[0].id[0]);
                if (!toting(things[0].id[0])) {
                    print("You " + bits[0] + " the " + things[0].label[0] + ".");
                }
                else {
                    print("You try to " + bits[0] + " the " + things[0].label[0] + ", but they stick to your hands.");
                }
            }
            else if (things.length > 1) {
                print("I'm not sure which of these you're talking about: " +
                $.map(things,
                function(thing) {
                    return thing.label[0];
                }).join(", ") + ".");
            }
        });
        alias("release");
        alias("free");
        alias("discard");
        alias("dump");

        makeCommand("open",
        function(bits) {
            var obj,
            things,
            playerEnv = player().environment[0],
            lockable = ["grate", "door", "clam", "oyster", "chain"],
            openers = {
                "obj:oyster": function() {

                    },
                "obj:clam": function() {

                    },
                "obj:grate": function() {
                    var k;
                    if (!here("keys")) {
                        print("You have no keys!");
                        return;
                    }
                    k = getGameProp("grate");
                    setGameProp("grate", 1);
                    if (k === 0) {
                        print("The grate is now unlocked.");
                    }
                    else {
                        print("It was already unlocked.");
                    }
                },
                "obj:chain": function() {
                    if (!here("keys")) {
                        print("You have no keys!");
                        return;
                    }
                },
                "obj:door": function() {
                    if (getGameProp("door") > 0) {
                        print("The door is extremely rusty and refuses to open.");
                    }
                }
            };

            if (bits.length == 1) {
                // we aren't specifying what we want to open, so we walk through the possibilities
                $.each(lockable,
                function(idx, nom) {
                    var item;
                    if (obj !== undefined) {
                        return;
                    }

                    item = that.dataStore.adventure.getItem("obj:" + nom);
                    if (item !== undefined && item.environment !== undefined) {
                        if ($.inArray(playerEnv, item.environment) > -1) {
                            obj = item;
                            bits.push(nom);
                        }
                    }
                });
                if (obj === undefined) {
                    print("There is nothing here with a lock!");
                }
            }
            if (obj === undefined) {
                things = thingsInEnvironment(0, bits.slice(1));
                if (things.length == 0) {
                    print("That isn't here.");
                    return;
                }
                if (things.length > 1) {
                    print("I'm not sure which of these you're talking about: " +
                    $.map(things,
                    function(thing) {
                        return thing.label[0];
                    }).join(", ") + ".");
                    return;
                }
                if ($.inArray(things[0].label[0], lockable) == -1) {
                    print("You can't " + bits[0] + " that!");
                    return;
                }
                obj = things[0];
            }
            if (openers[obj.id[0]] === undefined) {
                print("You can't " + bits[0] + " that!");
            }
            else {
                openers[obj.id[0]]();
            }
        });
        alias("unlock");

        makeCommand("close",
        function(bits) {
            var obj,
            things,
            playerEnv = player().environment[0],
            lockable = ["grate", "door", "clam", "oyster", "chain"],
            closers = {
                "obj:oyster": function() {

                    },
                "obj:clam": function() {

                    },
                "obj:grate": function() {
                    var k;
                    if (!here("keys")) {
                        print("You have no keys!");
                        return;
                    }
                    k = getGameProp("grate");
                    setGameProp("grate", 0);
                    if (k === 0) {
                        print("It was already locked.");
                    }
                    else {
                        print("The grate is now locked.");
                    }
                },
                "obj:chain": function() {
                    if (!here("keys")) {
                        print("You have no keys!");
                        return;
                    }
                },
                "obj:door": function() {
                    if (getGameProp("door") > 0) {
                        print("The door is extremely rusty and refuses to open.");
                    }
                }
            };

            if (bits.length == 1) {
                // we aren't specifying what we want to open, so we walk through the possibilities
                $.each(lockable,
                function(idx, nom) {
                    var item;
                    if (obj !== undefined) {
                        return;
                    }

                    item = that.dataStore.adventure.getItem("obj:" + nom);
                    if (item !== undefined && item.environment !== undefined) {
                        if ($.inArray(playerEnv, item.environment) > -1) {
                            obj = item;
                            bits.push(nom);
                        }
                    }
                });
                if (obj === undefined) {
                    print("There is nothing here with a lock!");
                    return
                }
            }

        });
        alias("lock");

        makeCommand("light",
        function(bits) {

            });
        alias("on");

        makeCommand("extinguish",
        function(bits) {

            });
        alias("off");

        makeCommand("wave",
        function(bits) {

            });
        alias("shake");
        alias("swing");

        makeCommand("calm",
        function(bits) {

            });
        alias("placate");
        alias("tame");

        makeCommand("look",
        function(bits) {
            if (bits.length === 1) {
                that.presentation.room.renderingFor("player").reRender(true);
            }
            else {
                // we want to look at the indicated item
                }
        });
        alias("examine");

        makeCommand("relax",
        function(bits) {

            });
        alias("nothing");

        makeCommand("pour",
        function(bits) {

            });

        makeCommand("eat",
        function(bits) {

            });
        alias("devour");

        makeCommand("drink",
        function(bits) {

            });

        makeCommand("rub",
        function(bits) {

            });

        makeCommand("throw",
        function(bits) {

            });
        alias("toss");

        makeCommand("wake",
        function(bits) {

            });
        alias("disturb");

        makeCommand("feed",
        function(bits) {

            });

        makeCommand("fill",
        function(bits) {

            });

        makeCommand("break",
        function(bits) {

            });
        alias("smash");
        alias("shatter");

        makeCommand("blast",
        function(bits) {

            });
        alias("detonate");
        alias("ignite");
        alias("blowup");

        makeCommand("attack",
        function(bits) {

            });
        alias("kill");
        alias("fight");
        alias("hit");
        alias("strike");
        alias("slay");

        makeCommand("say",
        function(bits) {

            });
        alias("chant");
        alias("sing");
        alias("utter");
        alias("mumble");

        makeCommand("read",
        function(bits) {

            });
        alias("peruse");

        makeCommand("fee",
        function(bits) {

            });
        alias("fie");
        alias("foe");
        alias("foo");
        alias("fum");

        makeCommand("brief",
        function(bits) {
            that.dataStore.adventure.updateItems([{
                id: "player",
                brief: !(player().brief[0])
            }]);
        });

        makeCommand("find",
        function(bits) {

            });
        alias("where");

        makeCommand("inventory",
        function(bits) {

            });

        makeCommand("score",
        function(bits) {

            });

        makeCommand("enter",
        function(bits) {
            if (bits[1] === "water" || bits[1] === "stream") {
                if (waterHere()) {
                    print("Your feet are now wet.");
                }
            }
            else {
                that.parseCommand("go " + bits[1]);
            }
        });


        ////
        // the following create the locations and movement between locations
        // the commentary is taken from the literate programming pdf
        ////
        /*
		 * The _road_ is where you start
		 *
		 * The instructions here say that if you want to go west, or up, or on the road, we take you to
		 * _hill_; if you want to go east, or in, or to the house, or if you say 'enter', we take you to
		 * _house_; etc.  Of course you won't know about all the motions available at this point until you
		 * have played the game for awhile.
		 */
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

        /*
		 * There's nothing up the hill, but a good explorer has to try anyway.
		 */
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

        /*
		 * The house initially contains several objects: keys, food, a bottle, and a lantern.
		 * We'll put them in there later.
		 *
		 * Two magic words are understood in this house, for spelunkers who have been there
		 * and done that.
		 */
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

        /*
		 * A foolish consistency is the hobgoblin of little minds. (Emerson)
		 */
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

        /*
		 * The instructions here keep you in the _forest_ with probability 50%, otherwise they take you
		 * to the _woods_.  This gives the illusion that we maintain more state information about you
		 * than we really do.
		 */
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

        /*
		 * You're getting closer. (But the program has forgotten that DEPRESSION leads _outside_; it knew this
		 * when you were at the _road_ or the _valley_.)
		 */
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

        /*
		 * We'll see later that the GRATE will change from state 0 to state 1 if you unlock it.  So let's hope you
		 * have the KEYS.
		 */
        makeLoc("outside",
        "You are in a 20-foot depression floored with bare dirt.  Set into the\n" +
        "dirt is a strong steel grate mounted in concrete.  A dry streambed\n" +
        "leads into the depression.",
        "You're outside grate.",
        ["lighted", "cave_hint"]
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

        lastOutsideRoom = ids.location;

        /*
		 * If you've come this far, you're probably hooked, although your adventure has barely begun.
		 */
        makeLoc("inside",
        "You are in a small chamber beneath a 3x3 steel grate to the surface.\n" +
        "A low crawl over cobbles leads inwards to the west.",
        "You're below the grate.",
        "lighted"
        );
        makeInst("OUT", notValue("grate", 0), "outside");
        ditto("OUT");
        ditto("U");
        remark("You can't go through a locked steel grate!");
        makeInst("OUT", 0, "sayit");
        makeInst("CRAWL", 0, "cobbles");
        ditto("COBBLES");
        ditto("IN");
        ditto("W");
        makeInst("PIT", 0, "spit");
        makeInst("DEBRIS", 0, "debris");

        /*
		 * Go West, young man. (IF you've got a lamp.)
		 */
        makeLoc("cobbles",
        "You are crawling over cobbles in a low passage.  There is a dim light\n" +
        "at the east end of the passage.",
        "You're in cobble crawl.",
        "lighted"
        );
        makeInst("OUT", 0, "inside");
        ditto("SURFACE");
        ditto("NOWHERE");
        ditto("E");
        makeInst("IN", 0, "debris");
        ditto("DARK");
        ditto("W");
        ditto("DEBRIS");
        makeInst("PIT", 0, "spit");

        makeLoc("debris",
        "You are in a debris room filled with stuff washed in from the surface.\n" +
        "A low wide passage with cobbles becomes plugged with mud and debris\n" +
        "here, but an awkward canyon leads upward and west.  A note on the wall\n" +
        "says \"MAGIC WORD XYZZY\".",
        "You're in debris room."
        );
        makeInst("DEPRESSION", notValue("grate", 0), "outside");
        makeInst("ENTRANCE", 0, "inside");
        makeInst("CRAWL", 0, "cobbles");
        ditto("COBBLES");
        ditto("PASSAGE");
        ditto("LOW");
        ditto("E");
        makeInst("CANYON", 0, "awk");
        ditto("IN");
        ditto("U");
        ditto("W");
        makeInst("XYZZY", 0, "house");
        makeInst("PIT", 0, "spit");

        makeLoc("awk",
        "You are in an awkward sloping east/west canyon."
        );
        makeInst("DEPRESSION", notValue("grate", 0), "outside");
        makeInst("ENTRANCE", 0, "inside");
        makeInst("D", 0, "debris");
        ditto("E");
        ditto("DEBRIS");
        makeInst("IN", 0, "bird");
        ditto("U");
        ditto("W");
        makeInst("PIT", 0, "spit");

        makeLoc("bird",
        "You are in a splendid chamber thirty feet high.  The walls are frozen\n" +
        "rivers of orange stone.  An awkward canyon and a good passage exit\n" +
        "from east and west sides of the chamber.",
        "You're in bird chamber.",
        "bird hint"
        );
        makeInst("DEPRESSION", notValue("grate", 0), "outside");
        makeInst("ENTRANCE", 0, "inside");
        makeInst("DEBRIS", 0, "debris");
        makeInst("CANYON", 0, "awk");
        ditto("E");
        makeInst("PASSAGE", 0, "spit");
        ditto("PIT");
        ditto("W");

        makeLoc("spit",
        "At your feet is a small pit breathing traces of white mist.  An east\n" +
        "passage ends here except for a small crack leading on.",
        "You're at top of small pit.");
        makeInst("DEPRESSION", notValue("grate", 0), "outside");
        makeInst("ENTRANCE", 0, "inside");
        makeInst("DEBRIS", 0, "debris");
        makeInst("PASSAGE", 0, "bird");
        ditto("E");
        makeInst("D", holds("gold"), "neck");
        ditto("PIT");
        ditto("STEPS");
        makeInst("D", 0, "emist");
        makeInst("CRACK", 0, "crack");
        ditto("W");

        /*
		 * Welcome to the main caverns and a deeper level of adventures.
		 */
        makeLoc("emist",
        "You are at one end of a vast hall stretching forward out of sight to\n" +
        "the west.  There are openings to either side.  Nearby, a wide stone\n" +
        "staircase leads downward.  The hall is filled with wisps of white mist\n" +
        "swaying to and fro almost as if alive.  A cold wind blows up the\n" +
        "staircase.  There is a passage at the top of a dome behind you.",
        "You're in Hall of Mists.");
        makeInst("L", 0, "nugget");
        ditto("S");
        makeInst("FORWARD", 0, "efiss");
        ditto("HALL");
        ditto("W");
        makeInst("STAIRS", 0, "hmk");
        ditto("D");
        ditto("N");
        makeInst("U", holds("gold"), "cant");
        ditto("PIT");
        ditto("STEPS");
        ditto("DOME");
        ditto("PASSAGE");
        ditto("E");
        makeInst("U", 0, "spit");
        makeInst("Y2", 0, "jumble");

        /*
		 * To the left or south of the misty threshold, you might spot the first treasure.
		 */
        makeLoc("nugget",
        "This is a low room with a crude note on the wall.  The note says,\n" +
        "\"You won't get it up the steps.\".",
        "You're in the nugget of gold room.");
        makeInst("HALL", 0, "emist");
        ditto("OUT");
        ditto("N");

        /*
		 * Unless you take a circuitous route to the other side of the Hall of Mists, via the Hall of the
		 * Mountain King, you should make the CRYSTAL bridge appear (by getting it into state 1).
		 */
        makeLoc("efiss",
        "You are on the east bank of a fissure slicing clear across the hall.\n" +
        "The mist is quite thick here, and the fissure is too wide to jump.",
        "You're on the east bank of fissure.");
        makeInst("HALL", 0, "emist");
        ditto("E");
        remark("I respectfully suggest you go across the bridge instead of jumping.");
        makeInst("JUMP", notValue("crystal", 0), "sayit");
        makeInst("FORWARD", notValue("crystal", 1), "lose");
        remark("There is no way across the fissure.");
        makeInst("OVER", notValue("crystal", 1), "sayit");
        ditto("ACROSS");
        ditto("W");
        ditto("CROSS");
        makeInst("OVER", 0, "wfiss");

        makeLoc("wfiss",
        "You are on the west side of the fissure in the Hall of Mists.", 0);
        makeInst("JUMP", notValue("crystal", 0), "bridge_rmk");
        makeInst("FORWARD", notValue("crystal", 1), "lose");
        remark("There is no way across the fissure.");
        makeInst("OVER", notValue("crystal", 1), "sayit");
        ditto("ACROSS");
        ditto("E");
        ditto("CROSS");
        makeInst("OVER", 0, "efiss");
        makeInst("N", 0, "thru");
        makeInst("W", 0, "wmist");

        /* 
		 * What you see here isn't exactly what you get; N takes you east and S sucks you in to an amazing maze.
		 */
        makeLoc("wmist",
        "You are at the west end of the Hall of Mists.  A low wide crawl\n" +
        "continues west and another goes north.  To the south is a little\n" +
        "passage 6 feet off the floor.",
        "You're at west end of Hall of Mists.");
        makeInst("S", 0, "like1");
        ditto("U");
        ditto("PASSAGE");
        ditto("CLIMB");
        makeInst("E", 0, "wfiss");
        makeInst("N", 0, "duck");
        makeInst("W", 0, "elong");
        ditto("CRAWL");

        /*
		 * The twisty little passages of this maze are said to be all alike, but they respond differently to
		 * different motions.  For example, you can go north, east, south, or west from _like1_, but you
		 * can't go north from _like2_.  In that way you can psych out the whole maze of 14 similar locations.
		 * (And eventually you will want to know every place where treasure might be hidden.)  The only exits
		 * are to _wmist_ and _brink_.
		 */
        (function() {
            var all_alike = "You are in a maze of twisty little passages, all alike.",
            rm,
            dir,
            passages = {
                like1: {
                    U: "wmist",
                    N: "like1",
                    E: "like2",
                    S: "like4",
                    W: "like11"
                },
                like2: {
                    W: "like1",
                    S: "like3",
                    E: "like4"
                },
                like3: {
                    E: "like2",
                    D: "dead5",
                    S: "like6",
                    N: "dead9"
                },
                like4: {
                    W: "like1",
                    N: "like2",
                    E: "dead3",
                    S: "dead4",
                    U: "like14",
                    D: "like14"
                },
                like5: {
                    E: "like6",
                    W: "like7"
                },
                like6: {
                    E: "like3",
                    W: "like5",
                    D: "like7",
                    S: "like8"
                },
                like7: {
                    W: "like5",
                    U: "like6",
                    E: "like8",
                    S: "like9"
                },
                like8: {
                    W: "like6",
                    E: "like7",
                    S: "like8",
                    U: "like9",
                    N: "like10",
                    D: "dead11"
                },
                like9: {
                    W: "like7",
                    N: "like8",
                    S: "dead6"
                },
                like10: {
                    W: "like8",
                    N: "like10",
                    D: "dead7",
                    E: "brink"
                },
                like11: {
                    N: "like1",
                    W: "like11",
                    S: "like11",
                    E: "dead1"
                },
                like12: {
                    S: "brink",
                    E: "like13",
                    W: "dead10"
                },
                like13: {
                    N: "brink",
                    W: "like12",
                    NW: "dead2"
                },
                like14: {
                    U: "like4",
                    D: "like4"
                }
            };

            for (rm in passages) {
                makeLoc(rm, all_alike, 0, "twist hint");
                for (dir in passages[rm]) {
                    makeInst(dir, 0, passages[rm][dir]);
                }
            }
        } ());

        makeLoc("brink",
        "You are on the brink of a thirty-foot pit with a massive orange column\n" +
        "down one wall.  You could climb down here but you could not get back\n" +
        "up.  The maze continues at this level.",
        "You're at brink of pit.");
        makeInst("D", 0, "bird");
        ditto("CLIMB");
        makeInst("W", 0, "like10");
        makeInst("S", 0, "dead8");
        makeInst("N", 0, "like12");
        makeInst("E", 0, "like13");

        /*
		 * Crawling west from _wmist_ instead of south, you encounter this.
		 */
        makeLoc("elong",
        "You are at the east end of a very long hall apparently without side\n" +
        "chambers.  To the east a low wide crawl slants up.  To the north a\n" +
        "round two-foot hole slants down.",
        "You're at east end of long hall.");
        makeInst("E", 0, "wmist");
        ditto("U");
        ditto("CRAWL");
        makeInst("W", 0, "wlong");
        makeInst("N", 0, "cross");
        ditto("D");
        ditto("HOLE");

        makeLoc("wlong",
        "You are at the west end of a very long featureless hall.  The hall\n" +
        "joins up with a narrow north/south passage.",
        "You're at west end of long hall.");
        makeInst("E", 0, "elong");
        makeInst("N", 0, "cross");
        makeInst("S", 100, "diff0");

        /*
		 * Recall that the '100' on the last instruction above means, "Dwarves not permitted."  It keeps them out
		 * of the following maze, which is based on an 11 x 11 latin square. (Each of the eleven locations leads
		 * to each of the others under the ten motions N, S, E, W, NE, SE, NW, SW, U, D -- except that _diff0_
		 * goes down to the entrance location _wlong_ instead of to _diff10_, and _diff10_ goes south to the
		 * dead-end location _pony_ instead of to _diff0_.  Furthermore, each location is accessible from all
		 * ten possible directions.)
		 *
		 * Incidentally, if you ever get into a "little twisting maze of passages," you're really lost.
		 */
        (function() {
            var links = {
                diff0: {
                    long: "You are in a maze of twisty little passages, all different.",
                    exits: [
                    "diff6", "diff9", "diff3",
                    "diff8", "diff7",
                    "diff2", "diff1", "diff4",
                    "diff5", "wlong"
                    ]
                },
                diff1: {
                    long: "You are in a maze of twisting little passages, all different.",
                    exits: [
                    "diff3", "diff8", "diff5",
                    "diff0", "diff10",
                    "diff4", "diff9", "diff2",
                    "diff6", "diff7"
                    ]
                },
                diff2: {
                    long: "You are in a little maze of twisty passages, all different.",
                    exits: [
                    "diff0", "diff3", "diff7",
                    "diff5", "diff8",
                    "diff6", "diff4", "diff10",
                    "diff1", "diff9"
                    ]
                },
                diff3: {
                    long: "You are in a twisting maze of little passages, all different.",
                    exits: [
                    "diff8", "diff7", "diff4",
                    "diff2", "diff6",
                    "diff5", "diff10", "diff9",
                    "diff0", "diff1"
                    ]
                },
                diff4: {
                    long: "You are in a twisting little maze of passages, all different.",
                    exits: [
                    "diff2", "diff1", "diff0",
                    "diff9", "diff5",
                    "diff10", "diff7", "diff3",
                    "diff8", "diff6"
                    ]
                },
                diff5: {
                    long: "You are in a twisty little maze of passages, all different.",
                    exits: [
                    "diff9", "diff0", "diff8",
                    "diff6", "diff4",
                    "diff7", "diff3", "diff1",
                    "diff10", "diff2"
                    ]
                },
                diff6: {
                    long: "You are in a twisty maze of little passages, all different.",
                    exits: [
                    "diff7", "diff10", "diff9",
                    "diff1", "diff9",
                    "diff8", "diff2", "diff0",
                    "diff4", "diff3"
                    ]
                },
                diff7: {
                    long: "You are in a little twisty maze of passages, all different.",
                    exits: [
                    "diff5", "diff6", "diff1",
                    "diff10", "diff9",
                    "diff8", "diff2", "diff0",
                    "diff4", "diff3"
                    ]
                },
                diff8: {
                    long: "You are in a maze of little twisting passages, all different.",
                    exits: [
                    "diff10", "diff5", "diff2",
                    "diff4", "diff1",
                    "diff9", "diff6", "diff7",
                    "diff3", "diff0"
                    ]
                },
                diff9: {
                    long: "You are in a maze of little twisty passages, all different.",
                    exits: [
                    "diff1", "diff4", "diff10",
                    "diff3", "diff2",
                    "diff0", "diff8", "diff6",
                    "diff7", "diff5"
                    ]
                },
                diff10: {
                    long: "You are in a little maze of twisting passages, all different.",
                    exits: [
                    "diff4", "diff2", "diff6",
                    "diff7", "diff3",
                    "diff1", "pony", "diff5",
                    "diff9", "diff8"
                    ]
                }
            },
            rm;

            for (rm in links) {
                makeLoc(rm, links[rm].long);
                makeInst("NW", 0, links[rm].exits[0]);
                makeInst("N", 0, links[rm].exits[1]);
                makeInst("NE", 0, links[rm].exits[2]);
                makeInst("W", 0, links[rm].exits[3]);
                makeInst("E", 0, links[rm].exits[4]);
                makeInst("SW", 0, links[rm].exits[5]);
                makeInst("S", 0, links[rm].exits[6]);
                makeInst("SE", 0, links[rm].exits[7]);
                makeInst("U", 0, links[rm].exits[8]);
                makeInst("D", 0, links[rm].exits[9]);
            }
        } ());

        /*
		 * Going north of the long hall, we come to the vicinity of another large room, with royal treasures
		 * nearby.  (You probably first reached this part of the cavern from the east, via the Hall of Mists.)
		 * Unfortunately, a vicious snake is here too; the conditional instructions for getting past the snake
		 * are worthy of study.
		 */
        makeLoc("cross",
        "You are at a crossover of a high N/S passage and a low E/W one.");
        makeInst("W", 0, "elong");
        makeInst("N", 0, "dead0");
        makeInst("E", 0, "west");
        makeInst("S", 0, "wlong");

        makeLoc("hmk",
        "You are in the Hall of the Mountain King, with passages off in all\n" +
        "directions.",
        "You're in Hall of Mt King.",
        "snake hint");
        makeInst("STAIRS", 0, "emist");
        ditto("U");
        ditto("E");
        makeInst("N", notValue("snake", 0), "ns");
        ditto("L");
        makeInst("S", notValue("snake", 0), "south");
        ditto("R");
        makeInst("W", notValue("snake", 0), "west");
        ditto("FORWARD");
        makeInst("N", 0, "snaked");
        makeInst("SW", 35, "secret");
        makeInst("SW", sees("snake"), "snaked");
        makeInst("SECRET", 0, "secret");

        makeLoc("west",
        "You are in the west side chamber of the Hall of the Mountain King.\n" +
        "A passage containues west and up here.",
        "You're in west side chamber.");
        makeInst("HALL", 0, "hmk");
        ditto("OUT");
        ditto("E");
        makeInst("W", 0, "cross");
        ditto("U");

        makeLoc("south",
        "You are in the south side chamber.");
        makeInst("HALL", 0, "hmk");
        ditto("OUT");
        ditto("N");

        /*
		 * North of the mountain king's domain is a curious shuttle station called Y2, with magic connections
		 * to two other places.
		 *
		 * (Real-world cave maps often use the symbol Y to stand for an entrance, and Y2 for a secondary entrance.)
		 */

        makeLoc("ns",
        "You are in a low N/S passage at a hole in the floor.  The hole goes down to an E/W passage.",
        "You're in N/S passage.");
        makeInst("HALL", 0, "hmk");
        ditto("OUT");
        ditto("S");
        makeInst("N", 0, "y2");
        ditto("Y2");
        makeInst("D", 0, "dirty");
        ditto("HOLE");

        makeLoc("y2",
        "You are in a large room, with a passage to the south, a passage to the west, and a wall of broken rock " +
        "to the east.  There is a large \"Y2\" on a rock in the room's center.",
        "You're at \"Y2\".");
        makeInst("PLUGH", 0, "house");
        makeInst("S", 0, "ns");
        makeInst("E", 0, "jumble");
        ditto("WALL");
        ditto("BROKEN");
        makeInst("W", 0, "windoe");
        makeInst("PLOVER", holds("emerald"), "pdrop");
        makeInst("PLOVER", 0, "proom");

        makeLoc("jumble",
        "You are in a jumble of rock, with cracks everywhere.");
        makeInst("D", 0, "y2");
        ditto("Y2");
        makeInst("U", 0, "emist");

        makeLoc("windoe",
        "You're at a low window overlooking a huge pit, which extends up out of sight.  A floor is indistinctly " +
        "visible over 50 feet below.  Traces of white mist cover the floor of the pit, becoming thicker to the " +
        "right.  Marks in the dust around the window would seem to indicate that someone has been here recently. " +
        "Directly across the pit from you and 25 feet away there is a similar window looking into a lighted room. " +
        "A shadowy figure can be seen there peering back at you.",
        "You're at window on pit.");
        makeInst("E", 0, "y2");
        ditto("Y2");
        makeInst("JUMP", 0, "neck");

        // next: sec. 42, pg. 27

        (function() {
            var dead_end = "Dead end.";

            makeLoc("pony", dead_end);
            makeInst("N", 0, "diff10");
            ditto("OUT");

            makeLoc("dead0", dead_end);
            makeInst("S", 0, "cross");
            ditto("OUT");

            makeLoc("dead1", dead_end, 0, "twist_hint");
            makeInst("W", 0, "like11");
            ditto("OUT");

            makeLoc("dead2", dead_end);
            makeInst("SE", 0, "like13");

            makeLoc("dead3", dead_end, 0, "twist_hint");
            makeInst("W", 0, "like4");
            ditto("OUT");

            makeLoc("dead4", dead_end, 0, "twist_hint");
            makeInst("E", 0, "like4");
            ditto("OUT");

            makeLoc("dead5", dead_end, 0, "twist_hint");
            makeInst("U", 0, "like3");
            ditto("OUT");

            makeLoc("dead6", dead_end, 0, "twist_hint");
            makeInst("W", 0, "like9");
            ditto("OUT");

            makeLoc("dead7", dead_end, 0, "twist_hint");
            makeInst("U", 0, "like10");
            ditto("OUT");

            makeLoc("dead8", dead_end);
            makeInst("E", 0, "brink");
            ditto("OUT");

            makeLoc("dead9", dead_end, 0, "twist_hint");
            makeInst("S", 0, "like3");
            ditto("OUT");

            makeLoc("dead10", dead_end, 0, "twist_hint");
            makeInst("E", 0, "like12");
            ditto("OUT");

            makeLoc("dead11", dead_end, 0, "twist_hint");
            makeInst("U", 0, "like8");
            ditto("OUT");
        } ());


        /*
		 * The following locations are used to provide feedback when certain movement isn't possible
		 */
        makeLoc("crack",
        "The crack is far too small for you to follow.");
        force("spit");

        makeLoc("neck",
        "You are at the bottom of the pit with a broken neck.");
        force("limbo2");

        makeLoc("limbo2",
        "Game over.  Reload the page to play again.");

        makeLoc("lose",
        "You didn't make it.");
        force("limbo2");

        makeLoc("cant",
        "The dome is unclimbable.");
        makeInst("FORCE", 0, "emist");

        makeLoc("climb",
        "You clamber up the plant and scurry through the hole at the top");
        force("narrow");

        makeLoc("check", "");
        force("upnout", notValue("plant", 2));
        force("didit");

        makeLoc("snaked",
        "You can't get by the snake.");
        force("hmk");

        makeLoc("thru",
        "You have crawled through a very low wide passage parallel to and north of the Hall of Mists.");
        force("wmist");

        makeLoc("duck",
        "You have crawled through a very low wide passage parallel to and north of the Hall of Mists.");
        force("wfiss");

        makeLoc("sewer",
        "The stream flows out through a pair of 1-foot-diameter sewer pipes.\n" +
        "It would be advisable to use the exit.");
        force("house");

        makeLoc("upnout",
        "There is nothing here to climb.  Use\"up\" or \"out\" to leave the pit.");
        force("wpit");

        makeLoc("didit",
        "You have climbed up the plant and out of the pit.");
        force("w2pit");

        newObj(["rug", "persian"], "Persian rug", "rug", ["scan1", "scan3"]);
        newNote("There is a Persian rub spread out on the floor!");
        newNote("The dragon is sprawled out on a Persian rug!!");

        newObj("troll2", 0, "troll2", "limbo");
        newNote("The troll is nowhere to be seen.");

        newObj("crystal", 0, "crystal", ["wfiss", "efiss"]);
        newNote("");
        newNote("A crystal bridge now spans the fissure.");
        newNote("The crystal bridge has vanished!");

        newObj("treads", 0, "treads", ["emist", "spit"]);
        newNote("Rough stone steps lead down the pit.");
        newNote("Rough stone steps lead up the dome.");

        newObj("grate", 0, "grate", ["inside", "outside"]);
        newNote("The grate is locked.");
        newNote("The grate is open.");

        newObj("mirror", 0, "mirror", ["mirror", "limbo"]);
        newNote("");


        ////
        // These are all of the objects that are in a single location
        ////
        newObj("chain", "Golden chain", "chain", "barr");
        newNote("There is a golden chain lying in a heap on the floor!");
        newNote("The bear is locked to the wall with a golden chain!");
        newNote("There is a golden chain locked to the wall!");

        newObj(["spices", "spice"], "Rare spices", 0, "chamber");
        newNote("There are rare spices here!");

        newObj("pearl", "Glistening perl", 0, "limbo");
        newNote("Off to one side lies a glistening pearl!");

        newObj(["pyramid", "platinum"], "Platinum pyramid", 0, "droom");
        newNote("There is a platinum pyramid here, 8 inches on a side!");

        newObj("emerald", "Egg-sized emerald", 0, "proom");
        newNote("There is an emerald here the size of a plover's egg!");

        newObj(["vase", "ming", "shard"], "Ming vase", 0, "oriental");
        newNote("There is a delicate, precious, Ming vase here!");
        newNote("The vase is now resting, delicately, on a velvet pillow.");
        newNote("The floor is littered with worthless shards of pottery.");
        newNote("The Ming vase drops with a delicate crash.");

        newObj("trident", "Jeweled trident", 0, "falls");
        newNote("There is a jewel-encrusted trident here!");

        newObj(["eggs", "egg", "nest"], "Golden eggs", 0, "giant");
        newNote("There is a large nest here, fill of golden eggs!");
        newNote("The nest of golden eggs has vanished!");
        newNote("Done!");

        newObj(["chest", "box", "treasure", "treasurechest"], "Treasure chest", 0, "limbo");
        newNote("The pirate's treasure chest is here!");

        newObj("coins", "Rare coins", 0, "west");
        newNote("There are many coins here!");

        newObj("jewels", "Precious jewelry", 0, "south");
        newNote("There is precious jewelry here!");

        newObj(["silver", "bars"], "Bars of silver", 0, "ns");
        newNote("There are bars of silver here!");

        newObj("diamonds", "Several diamonds", 0, "wfiss");
        newNote("There are diamonds here!");

        newObj(["gold", "nugget"], "Large gold nugget", 0, "nugget");
        newNote("There is a large sparkling nugget of gold here!");

        newObj(["moss", "carpet"], 0, "moss", "soft");
        newNote("");

        newObj("batteries", "Batteries", 0, "limbo");
        newNote("There are fresh batteries here.");
        newNote("Some worn-out batteries have been discarded nearby.");

        newObj(["pony", "vending", "machine"], 0, "pony", "pony");
        newNote("There is a massive vending machine here.  The instructions on it read: " +
        "\"Drop coins here to receive fresh batteries.\"");

        newObj(["geyser", "volcano"], 0, "geyser", "view");
        newNote("");

        newObj("message", 0, "message", "limbo");
        newNote("There is a message scrawled in the dust in a flowery script, reading: " +
        "\"This is not the maze where the pirate hides his treasure chest.\"");

        newObj("bear", 0, "bear", "barr");
        newNote("There is a ferocious cave bea eying you from the far end of the room!");
        newNote("There is a gentle cave bear sitting placidly in one corner.");
        newNote("There is a contented-looking bear wandering about nearby.");
        newNote("");

        newObj("pirate", 0, "pirate", "limbo");
        newNote("");

        newObj("art", 0, "art", "oriental");
        newNote("");

        newObj("axe", "Dwarf's axe", 0, "limbo");
        newNote("There is a little axe here.");
        newNote("There is a little axe lying beside the bear.");

        newObj("stalactite", 0, "stalactite", "tite");
        newNote("");

        newObj(["plant", "beans"], 0, "plant", "wpit");
        newNote("There is a tiny little plant in the pit, murmuring \"Water, water, ...\"");
        newNote("The plant spurts into furious growth for a few seconds.");
        newNote("There is a 12-foot-tall beanstalk streatching up out of the pit, bellowing \"Water!!  Water!!\"");
        newNote("The plant grows explosively, almost filling the bottom of the pit.");
        newNote("There is a gigantic beanstalk stretching all the way up to the hole.");
        newNote("You've over-watered the plant!  It's shriveling up!  It's, it's...");
        newNote("");

        newObj("oil", "Oil in the bottle", 0, "limbo");
        newObj(["water", "h2o"], "Water in the bottle", 0, "limbo");
        newObj(["bottle", "jar"], "Small bottle", 0, "house");
        newNote("There is a bottle of water here.");
        newNote("There is an empty bottle here.");
        newNote("There is a bottle of oil here.");

        newObj(["food", "ration"], "Tasty food", 0, "house");
        newNote("There is food here.");

        newObj(["knife", "knives"], 0, 0, "limbo");

        newObj(["dwarf", "dwarves"], 0, "dwarf", "limbo");

        newObj(["mag", "magazine", "issue", "spelunker"], "\"Spelunker Today\"", 0, "ante");
        newNote("There are a few recent issues of \"Spelunker Today\" magazine here.");

        newObj("oyster", "Giant oyster. &gt;GROAN!&lt;", 0, "limbo");
        newNote("There is an enormous oyster here with its shell tightly closed.");
        newNote("Interesting.  There seems to be something written on the underside of the oyster.");

        newObj("clam", "Giant clam &gt;GRUNT!&lt;", 0, "shell");
        newNote("There is an enormous clam here with its shell tightly closed.");

        newObj("tablet", 0, "tablet", "droom");
        newNote("A massive stone tablet embedded in the wall reads: \"CONGRATULATIONS ON BRINGING LIGHT INTO THE DARK-ROOM!\"");

        newObj("snake", 0, "snake", "hmk");
        newNote("A huge green fierce snake bars the way!");
        newNote("");

        newObj("pillow", "Velvet pillow", 0, "soft");
        newNote("A small velvet pillow lies on the floor.");

        newObj("door", 0, "door", "immense");
        newNote("The way north is barred by a massive, rusty, iron door.");
        newNote("The way north leads through a massive, rusty, iron door.");

        newObj("bird", "Little bird in cage", 0, "bird");
        newNote("A cheerful little bird is sitting here singing.");
        newNote("There is a little bird in the cage");

        newObj("rod2", "Black rod", 0, "limbo");
        newNote("A three-foot black rod with a rusty star on an end lies nearby.");

        newObj("rod", "Black rod", 0, "debris");
        newNote("A three-foot black rod with a rusty star on an end lies nearby.");

        newObj("cage", "Wicker cage", 0, "cobbles");
        newNote("There is a small wicker cage discarded nearby.");

        newObj(["lamp", "lantern", "headlamp"], "Brass lantern", 0, "house");
        newNote("There is a shiny brass lamp nearby.");
        newNote("There is a lamp shining nearby.");

        newObj(["keys", "key"], "Set of keys", 0, "house");
        newNote("There are some keys on the ground here.");

        ////
        // done with game data now
        ////
        return that;
    };
} (jQuery, MITHGrid));

fluid.defaults("MITHGrid.Application.Adventure", {
    // the game has a single core database of objects, rooms, and actions (words) within a room
    dataStores: {
		adventure: {
            // let the database know what kinds of items we expect to have
            // commands are kept separate since the data source doesn't handle function references yet
            types: {
				Player: {},
				Room: {},
				"Object": {},
				Word: {},
				Note: {}
            },
            // let the database know that the 'environment' and 'object' properties point to other items
            properties: {
				environment: {
                	valueType: "Item"
            	},
            	object: {
                	valueType: "Item"
            	}
			}
		}
    },
    /*
	 * we have a number of data views that let us see when particular items in the database have changed
	 */
    dataViews: {
		inventory: {
           /*
			 * this data view lists the items that are part of the player's inventory
			 */
            dataStore: 'adventure',
			types: ["Object"],
			filters: [".environment = 'player'"],
        },
		player: {
            /*
			 * this data view is the player, so we can watch this model for events such as
			 * a player moving from one room to another room.
			 *
			 * There's only one object of type "Player"
			 */
            dataStore: 'adventure',
			types: ["Player"],
    	}
	},
    /*
	 * This is the DOM content we want within our configured container, but we need to wait
	 * until the DOM is ready before we try to add this
	 */
    viewSetup:
    "<div class='room'>" +
    "<div class='description'></div>" +
    "<div class='objects'></div>" +
    "</div>" +
    "<div class='score-holder'>" +
    "<h2>Score</h2>" +
    "<div class='score'></div>" +
    "</div>" +
    "<div class='inventory-holder'>" +
    "<h2>Inventory</h2>" +
    "<ul class='inventory'></ul>" +
    "</div>" +
    "<div class='compass'>" +
    "<span class='n'>N</span>" +
    "<span class='e'>E</span>" +
    "<span class='w'>W</span>" +
    "<span class='s'>S</span>" +
    "<span class='u'>U</span>" +
    "<span class='d'>D</span>" +
    "</div>" +
    "<div class='cli'>" +
    "<input class='cli-input' type='text' name='command'></input>" +
    "</div>"
});