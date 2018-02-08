({
    resetColumn: function(cmp, oldColumn, newColumn){
        //resets highlighted arrow and arrow direction
        var columnArray = cmp.find("columnSort");
        for(var i=0, col=0; i<columnArray.length; i++){
            var colName = columnArray[i].get("v.name");

            if(colName === newColumn) {
                $A.util.addClass(columnArray[i], 'buttonIconClicked');
                //breaks early if this is the first sort
                if(oldColumn === 'none'){
                    break;
                }
                col++;
            }
            else if(colName === oldColumn){
                $A.util.removeClass(columnArray[i], 'buttonIconClicked');
                //default position is pointing down, so only need to reset if it is up
                if(columnArray[i].get("v.iconName") === "utility:arrowup"){
                    columnArray[i].set("v.iconName", "utility:arrowdown");
                }
                col++;
            }
            //break once both columns have been reset
            if(col == 2){
                break;
            }
            }
    }
})