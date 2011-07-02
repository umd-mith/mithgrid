// app won't have presentations populated until the document is ready
var app = MITHGrid.Application({
    dataSources: [{
        label: 'internal',
        types: [{
            label: 'Application'
        },
        {
            label: 'View'
        },
        {
            label: 'Transition'
        }],
        properties: [{
            label: 'view',
            valueType: 'item'
        },
        {
            label: 'transition-from',
            valueType: 'item'
        },
        {
            label: 'transition-to',
            valueType: 'item'
        },
        {
            label: 'transition',
            valueType: 'item'
        },
        {
            label: 'initialization-action',
            valueType: 'item'
        },
        {
            label: 'position-x',
            valueType: 'numeric'
        },
        {
            label: 'position-y',
            valueType: 'numeric'
        }]
    }],
    dataViews: [{
        label: 'internal',
        dataSource: 'internal'
    }],
    presentations: [{
        type: MITHGrid.Presentation.Flow,
        container: '#edit-canvas',
        label: 'sheet',
        dataView: 'internal',
        options: {
            margins: {
                right: 0,
                left: 0,
                top: function() {
                    return $('#header').outerHeight()
                },
                bottom: 0
            }
        }
    }]
});

app.ready(function() {
    var views_counter = 0;
    var create_view = function(label, x, y) {
        var id = 'view-' + views_counter;
        views_counter += 1;
        app.dataSource.internal.loadItems([{
            label: label,
            id: id,
            "position-x": x,
            "position-y": y,
            type: 'View'
        }]);
        return id;
    };
    var create_transition = function(from, to) {
        var id = 'transition-' + views_counter;
        views_counter += 1;
        app.dataSource.internal.loadItems([{
            label: 'transition from ' + from + ' to ' + to,
            id: id,
            "transition-from": from,
            "transition-to": to,
            type: "Transition"
        }]);
        return id;
    };
    var view0 = create_view('start', 10, 20);
    var view1 = create_view('done', 220, 120);
    var view2 = create_view('more', 10, 120);
    var view3 = create_view('most', 200, 400);
    create_transition(view0, view1);
    create_transition(view2, view0);
    create_transition(view1, view2);
    create_transition(view0, view3);
});