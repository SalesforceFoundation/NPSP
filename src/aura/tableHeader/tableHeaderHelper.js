({
    resetColumn: function(cmp){
        var columnArray = cmp.find("columnSort");
        for(var i=0; i<columnArray.length; i++){
            if(columnArray[i].get("v.iconName") === "utility:arrowup"){
                columnArray[i].set("v.iconName", "utility:arrowdown");
                break;
            }
        }
    }
})