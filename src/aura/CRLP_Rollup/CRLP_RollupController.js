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
        console.log('calling helper...');
        helper.setObjectAndFieldDependencies(cmp);
    },

    onModeChanged:function(cmp,event,helper){
            console.log('heard ModeChanged event');
            var mode = event.getParam('mode');
            cmp.set("v.mode",mode);
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

    onCancel: function(cmp, event, helper) {
        cmp.set("v.mode", "view");
        console.log('in cancel');
        helper.handleRollupSelect(cmp);
    },

    changeDetailObject: function(cmp, event, helper){
        //set new summary objects based on selected value
        var object = cmp.find("detailObjectSelect").get("v.value");
        //var object = cmp.get("v.activeRollup.Detail_Object__r.QualifiedApiName");
        console.log('object: '+object);
        helper.resetSummaryObjects(cmp, object);

        //set new detail fields based on new selected detail object
        helper.resetFields(cmp, object, 'detail');

        //TODO: what should we be doing with summary fields?

    },
    changeSummaryField: function(cmp, event, helper){
        //change summary fields to match available detail field types + existing summary object
        var detailField = cmp.find("detailFieldSelect").get("v.value");
        var summaryObject = cmp.find("summaryObjectSelect").get("v.value");
        //var detailField = cmp.get("v.activeRollup.Detail_Field__r.QualifiedApiName");
        //var summaryObject = cmp.get("v.activeRollup.Summary_Object__r.QualifiedApiName")
        helper.filterSummaryFieldsByDetailField(cmp, detailField, summaryObject);
    },

    changeAmountObject: function(cmp, event, helper){
        //change amount fields to match new summary object + existing detailField
        var object = cmp.find("amountObjectSelect").get("v.value");
        helper.resetFields(cmp, object, 'amount');
    },
    changeDateObject: function(cmp, event, helper){
        console.log('HITTING CHANGEDATEOBJECT FUNCTION');
        //change date fields to match new summary object + existing detailField
        var object = cmp.find("dateObjectSelect").get("v.value");
        helper.resetFields(cmp, object, 'date');
    },

})