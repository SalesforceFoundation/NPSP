({
    /* @description: resets the view assignments, clears detail information, and displays rollup grid
    */
    displayRollupsGrid: function(cmp){
        cmp.set("v.isRollupsGrid", true);
        cmp.set("v.isFilterGroupsGrid", false);
        cmp.set("v.isRollupDetail", false);
        cmp.set("v.isFilterGroupDetail", false);
        cmp.set("v.detailMode", null);
        cmp.set("v.activeRecord", null);

        //checks if we're coming from the detail view
        cmp.set("v.activeRecordId", null);
    },

    /* @description: resets the view assignments, clears detail information, and displays filter group grid
    */
    displayFilterGroupsGrid: function(cmp){
        cmp.set("v.isFilterGroupsGrid",true);
        cmp.set("v.isRollupsGrid", false);
        cmp.set("v.isFilterGroupDetail", false);
        cmp.set("v.detailMode", null);
        cmp.set("v.activeRecord", null);

        //checks if we're coming from the detail view
        cmp.set("v.activeRecordId", null);
    },

    /* @description: filters row data based on user's selection of summary object
    */
    filterData: function(cmp, object){
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

    /* @description: sorts data by user's selected field and field direction
    */
    sortData: function(cmp, fieldName, sortDirection, data){
        var reverse = sortDirection !== 'asc';
        data.sort(this.sortBy(fieldName, reverse));
        return data;
    },

    /* @description: called by sortData, sorts by provided key and direction. Provided by Salesforce lightning:datatable documentation.
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

    /* @description: toggles a modal popup and backdrop
    */
    toggleFilterRuleModal: function(cmp){
        var backdrop = cmp.find('backdrop');
        $A.util.toggleClass(backdrop, 'slds-backdrop_open');
        var modal = cmp.find('modaldialog');
        $A.util.toggleClass(modal, 'slds-fade-in-open');
    },
})