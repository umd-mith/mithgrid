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
    var that = MITHGrid.Presentation.initPresentation("TextList", container, options);

    return that;
};

} (jQuery, MITHGrid));