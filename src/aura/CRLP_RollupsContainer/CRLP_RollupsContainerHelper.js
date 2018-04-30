({
    /**
     * @description: resets the view assignments, clears detail information, and displays rollup grid
     */
    displayRollupsGrid: function(cmp) {
        cmp.set("v.isRollupsGrid", true);
        cmp.set("v.isFilterGroupsGrid", false);
        cmp.set("v.isRollupDetail", false);
        cmp.set("v.isFilterGroupDetail", false);
        cmp.set("v.detailMode", null);
        cmp.set("v.activeRecord", null);

        //checks if we're coming from the detail view
        cmp.set("v.activeRecordId", null);
    },

    /**
     * @description: resets the view assignments, clears detail information, and displays filter group grid
     */
    displayFilterGroupsGrid: function(cmp) {
        cmp.set("v.isFilterGroupsGrid",true);
        cmp.set("v.isRollupsGrid", false);
        cmp.set("v.isFilterGroupDetail", false);
        cmp.set("v.detailMode", null);
        cmp.set("v.activeRecord", null);

        //checks if we're coming from the detail view
        cmp.set("v.activeRecordId", null);
    },

    /**
     * @description: filters row data based on user's selection of summary object
     */
    filterData: function(cmp, object) {
        var cachedRollupList = cmp.get("v.cachedRollupList");
        if(object === 'All'){
            cmp.set("v.rollupList", cachedRollupList);
        } else{
            var filteredRollupList = cachedRollupList.filter(function(rollup){
               return rollup.summaryObjectApiName === object;
            });
            cmp.set("v.rollupList", filteredRollupList);
        }
    },

    /**
     *  @description: merges and saves the updated row item into the existing list of rows
     *  @param list - list of items to merge into
     *  @param item - item to be merged into the list
     *  @param context - context running the merge
     */
    mergeRowItem: function(cmp, list, item, context) {
        var newItem = true;
        for (var i = 0; i < list.length; i++) {
            if (list[i].recordId === item.recordId) {
                //update filter group information on rollups only if master label has changed
                if (list[i].label !== item.label && context === 'filterGroup') {
                    this.requeryRollups(cmp);
                }
                // if the Id matches, update that record
                list[i] = item;
                newItem = false;
                break;
            }
        }
        if (newItem) {
            list.push(item);
        }

        //save the updated, sorted list and clear any list filtering
        if (context === 'rollup') {
            var sortedData = this.sortData(cmp, 'displayName', 'asc', list);
            cmp.set("v.filteredSummaryObject", "All");
            cmp.set("v.rollupList", sortedData);
        } else if (context === 'filterGroup') {
            cmp.set("v.filterGroupList", list);
        }
    },

    /**
     * @description: sorts data by user's selected field and field direction
     */
    sortData: function(cmp, fieldName, sortDirection, data) {
        var reverse = sortDirection !== 'asc';
        data.sort(this.sortBy(fieldName, reverse));
        return data;
    },

    /**
     * @description: called by sortData, sorts by provided key and direction. Provided by Salesforce lightning:datatable documentation.
     */
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x[field])} :
            function(x) {return x[field]};
        //checks if the two rows should switch places
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    },

    /**
     * @description: toggles a modal popup and backdrop
     */
    toggleFilterRuleModal: function(cmp) {
        var backdrop = cmp.find('backdrop');
        $A.util.toggleClass(backdrop, 'slds-backdrop_open');
        var modal = cmp.find('modaldialog');
        $A.util.toggleClass(modal, 'slds-fade-in-open');
    },

    /**
    * @description: queries the rollups to update filter group name references
    */
    requeryRollups: function(cmp) {
        var action = cmp.get("c.getRollupDefinitions");

        //requery rollup records
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var rollupList = JSON.parse(JSON.stringify(response.getReturnValue()));

                cmp.set("v.rollupList", rollupList);
                cmp.set("v.cachedRollupList", rollupList);
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.showToast(cmp, "error", cmp.get("v.labels.error"), errors[0].message);
                    }
                } else {
                    this.showToast(cmp, "error", cmp.get("v.labels.error"), "Unknown Error");
                }
            }
        });

        $A.enqueueAction(action);
    },

    /**
     * @description Show a message on the screen
     * @param type - error, success, info
     * @param title - message title
     * @param message - message to display
     */
    showToast : function(cmp, type, title, message) {
        cmp.set("v.toastStatus", type);
        var altText = cmp.get("v.labels." + type);
        var text = {message: message, title: title, alternativeText: altText};
        cmp.set("v.notificationText", text);
        cmp.set("v.notificationClasses", "");
    }
})