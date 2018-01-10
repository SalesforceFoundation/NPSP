({
    changeMode: function (cmp, event, helper) {
        var mode = cmp.get("v.mode");
        console.log("Mode is " + mode);
        console.log("In changeMode");
        //set readonly fields if mode is View
        if(mode != "view"){
            cmp.set("v.isReadOnly",false);
        } else {
            cmp.set("v.isReadOnly", true);
        }
        helper.setObjectAndFieldDependencies(cmp);
    },

    setModeEdit: function(cmp, event, helper) {
        cmp.set("v.mode", "edit");
        console.log("In setModeEdit");
        helper.setObjectAndFieldDependencies(cmp);
    },

    setModeClone: function(cmp, event, helper) {
        cmp.set("v.mode", "clone");
        helper.setObjectAndFieldDependencies(cmp);
    },

    setModeView: function(cmp, event, helper) {
        cmp.set("v.mode", "view");
    },

    changeDetailObject: function(cmp, event, helper){
        //clear out everything else?
        //set new summary objects based on selected value
        var detailObject = cmp.find("detailObjectSelect").get("v.value");
        helper.resetSummaryObjects(cmp, detailObject);

        //set new detail fields based on new selected object
        helper.resetDetailFields(cmp, detailObject);

        //reset anything else necessary
        //helper.resetSummaryFields(cmp, detailObject);
    },
    changeDetailField: function(cmp, event, helper){
        //change summary fields to match available detail field types + existing summary object
        var detailField = cmp.find("detailFieldSelect").get("v.value");
        var summaryObject = cmp.find("summaryObjectSelect").get("v.value");
        //helper.resetSummaryFields(cmp, detailField, summaryObject);
    },
    changeSummaryObject: function(cmp, event, helper){
        //change summary fields to match new summary object + existing detailField
        var summaryObject = cmp.find("summaryObjectSelect").get("v.value");
        var detailField = cmp.find("detailFieldSelect").get("v.value");
        //helper.resetSummaryFields(cmp, detailField, summaryObject);
    },

})