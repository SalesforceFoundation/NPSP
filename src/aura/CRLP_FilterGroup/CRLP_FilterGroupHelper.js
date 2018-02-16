({
    filterRollupList: function(cmp, filterGroupLabel, labels){
        //todo: should summary obj be dynamic?
        //filters row data based selected filter group
        var rollupList = cmp.get("v.rollupList");
        var filteredRollupList = rollupList.filter(function(rollup){
                return rollup.filterGroupName == filterGroupLabel;
        });

        var rollupsBySummaryObj = [{label: labels.accountLabel, list: []}
                                , {label: labels.contactLabel, list: []}
                                , {label: labels.gauLabel, list: []}];
        var itemList = [];

        //filter rollup list by type
        filteredRollupList.forEach(function (rollup){
            var item = {label: rollup.rollupName, name: rollup.id};
            if(rollup.summaryObject == 'Account'){
                rollupsBySummaryObj[0].list.push(item);
            } else if (rollup.summaryObject == 'Contact'){
                rollupsBySummaryObj[1].list.push(item);
            } else if (rollup.summaryObject == 'General Accounting Unit'){
                rollupsBySummaryObj[2].list.push(item);
            }
        });

        //only add object to list if there are rollups with matching summary objects
        rollupsBySummaryObj.forEach(function(item){
           if(item.list.length > 1){
               var item = {label: item.label, name: "title"
                         , items: item.list
               };
               itemList.push(item);
           }
        });

        var items = [{
            "label": labels.rollupsByFilterGroup,
            "name": "title",
            "expanded": false,
            "items": itemList
        }];
        cmp.set("v.rollupItems", items);
    },
})