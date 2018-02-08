({
    displayRollupsGrid: function(cmp){
        cmp.set("v.isRollupsGrid", true);
        cmp.set("v.isFilterGroupsGrid", false);
        cmp.set("v.isRollupDetail", false);
        cmp.set("v.detailMode", null);
        cmp.set("v.activeRollup", null);

        var labels = cmp.get("v.labels");

        var cols = [{label: labels.name, name: 'rollupName'}
            , {label: labels.summaryObject, name: 'summaryObject'}
            , {label: labels.detailObject, name: 'detailObject'}
            , {label: labels.creditType, name: 'creditType'}
            , {label: labels.operation, name: 'operation'}
            , {label: labels.filterGroupLabel, name: 'filterGroupName'}
            , {label: labels.active, name: 'active'}
        ];
        cmp.set("v.columns", cols);
        //checks if we're coming from the detail view; if already null the onchange won't fire
        cmp.set("v.activeRollupId", null);
    },

    filterData: function(cmp, object){
        var cachedRollupList = cmp.get("v.cachedRollupList");
        if(object === 'All'){
            cmp.set("v.rollupList", cachedRollupList);
        } else{
            var filteredRollupList = cachedRollupList.filter(function(rollup){
               return rollup.summaryObject == object;
            });
            cmp.set("v.rollupList", filteredRollupList);
        }
    },

    sortData: function(cmp, fieldName, sortDirection){
        var data = cmp.get("v.rollupList");
        var reverse = sortDirection !== 'asc';
        //sorts the rows based on the column header that's clicked and in specified direction
        data.sort(this.sortBy(fieldName, reverse));
        cmp.set("v.rollupList", data);
    },

    sortBy: function (field, reverse, primer) {
        //provided by Salesforce lightning:datatable documentation
        var key = primer ?
            function(x) {return primer(x[field])} :
            function(x) {return x[field]};
        //checks if the two rows should switch places
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    }
})