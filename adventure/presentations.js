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
    var that = MITHGrid.Presentation.initView("TextList", container, options);

    that.startDisplayUpdate = function() {};
    that.finishDisplayUpdate = function() {};

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
	game = that.options.application;

	that.getLens = function(item) {
		// we get light or dark lenses based on the state of the game
		var lensBase = {};
		
		if(game.isDark()) {	
		 	if(!game.wasForced()) {
				lensBase = that.options.lenses.isDark.wasNotForced;
			}
			else {
				lensBase = that.options.lenses.isDark.wasForced;
			}
		}
		else {
			lensBase = that.options.lenses.isLight;
		}
		
		if(lensBase[item.type[0]] !== undefined) {
			return { render: lensBase[item.type[0]] };
		}
	};
	
    that.startDisplayUpdate = function() {};
    that.finishDisplayUpdate = function() {};

    return that;
}
} (jQuery, MITHGrid));