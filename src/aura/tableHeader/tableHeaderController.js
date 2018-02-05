({
    sortColumn: function(cmp, event, helper){
        var selectedColumn = event.getSource();
        var columnName = selectedColumn.get("v.name");
        var sortedColumn = cmp.get("v.sortedColumn");
        var direction;

        //check if column is the same and toggles direction, or different and changes sorted column
        if(columnName == sortedColumn.columnName){
            //toggles arrow direction on icon and in sortedComponent attribute
            var currentIconName = selectedColumn.get("v.iconName");
            if(currentIconName == "utility:arrowup"){
                selectedColumn.set("v.iconName", "utility:arrowdown");
                direction = 'asc';
            } else {
                selectedColumn.set("v.iconName", "utility:arrowup");
                direction = 'desc';
            }
            cmp.set("v.sortedColumn.direction", direction);
        } else {
            //default position is pointing down, so need to check if active column needs resetting
            if(sortedColumn.direction != 'asc'){
                helper.resetColumn(cmp);
            }
            direction = 'asc';
            var newSortedColumn = {columnName: columnName, direction: direction};
            cmp.set("v.sortedColumn", newSortedColumn);
        }

        var sortEvent = $A.get("e.c:CRLP_SortEvent");
        sortEvent.setParams({fieldName: columnName, sortDirection: direction});
        sortEvent.fire();
    },
})