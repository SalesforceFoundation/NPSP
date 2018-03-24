({
    /* @description: filters the full rollup data to find which rollups use a particular filter group
    * @param filterGroupLabel: label of the selected filter group
    * @param labels: labels for the rollups UI
    */
    filterRollupList: function(cmp, filterGroupLabel, labels){
        //filters row data based selected filter group
        var rollupList = cmp.get("v.rollupList");
        var filteredRollupList = rollupList.filter(function(rollup){
            return rollup.filterGroupName === filterGroupLabel;
        });

        //todo: should summary obj be dynamic?
        var rollupsBySummaryObj = [{label: labels.labelAccount, list: []}
                                , {label: labels.labelContact, list: []}
                                , {label: labels.labelGAU, list: []}];
        var itemList = [];

        //filter rollup list by type
        filteredRollupList.forEach(function (rollup){
            var item = {label: rollup.rollupName, name: rollup.id};
            if(rollup.summaryObject === labels.labelAccount){
                rollupsBySummaryObj[0].list.push(item);
            } else if (rollup.summaryObject === labels.labelContact){
                rollupsBySummaryObj[1].list.push(item);
            } else if (rollup.summaryObject === labels.labelGAU){
                rollupsBySummaryObj[2].list.push(item);
            }
        });

        //only add object to list if there are rollups with matching summary objects
        rollupsBySummaryObj.forEach(function(objList){
           if(objList.list.length > 1){
               var obj = {label: objList.label
                         , name: "title"
                         , expanded: false
                         , items: objList.list
               };
               itemList.push(obj);

           }
        });

        cmp.set("v.rollupItems", itemList);
    },

    /* @description: opens a modal popup so user can add or edit a filter rule
     */
    openFilterRuleModal: function(cmp){

    },

    /* @description: verifies all required fields have been populated before saving the filter group
     */
    validateFields: function(cmp){
        var canSave = true;
        var name = cmp.get("v.activeFilterGroup.MasterLabel");
        var description = cmp.get("v.activeFilterGroup.Description__c");
        var filterRuleList = cmp.get("v.filterRuleList");

        cmp.find("nameInput").showHelpMessageIfInvalid();
        cmp.find("descriptionInput").showHelpMessageIfInvalid();
        //todo: where to put error message for filter rules? or can a filter group be saved w/o filter rules?

        if(!description){
            canSave = false;
        } else if(!name){
            canSave = false;
        } else if(filterRuleList.length() === 0){
            canSave = false;
        }

        return canSave;
    }
})