({
    displayRollupsGrid: function(cmp){
        cmp.set("v.isRollupsGrid", true);
        cmp.set("v.isFilterGroupsGrid", false);
        cmp.set("v.isRollupDetail", false);
        cmp.set("v.detailMode", null);
        cmp.set("v.activeRollup", null);

        var labels = cmp.get("v.labels");

        var cols = [labels.name
            , labels.summaryObject
            , labels.detailObject
            , labels.creditType
            , labels.operation
            , labels.filterGroupLabel
            , labels.active
        ];
        cmp.set("v.columns", cols);
        //checks if we're coming from the detail view; if already null the onchange won't fire
        cmp.set("v.activeRollupId", null);
    }
})