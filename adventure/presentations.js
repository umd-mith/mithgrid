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
			notesForObjectExpr = model.prepare(["!object.id"]),
            room = model.getItem(model.getItem('player').environment[0]);

			/* thingsInEnvExpr is a prepared expression that will find all of the things in the game database
			 * that share the same environment as the provided object id - in this case, it will be the id
			 * of the room that the player is in
			 */
			var doRender = function() {
				var things = { "Word": [], "Object": [] },
				thingIds = thingsInEnvExpr.evaluate([room.id[0]]),
				roomDesc = "", hasForce = false, bear;
				
				//console.log(thingIds);
				roomDesc = room.description[0];
                
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
						if(words === undefined) {
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
				else {
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
            that.update = function(item) {
				if(room.id[0] !== item.environment[0]) {
					room = model.getItem(item.environment[0]);
					doRender();
				}
			};
			
			that.reRender = function() {
				doRender();
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
} (jQuery, MITHGrid));