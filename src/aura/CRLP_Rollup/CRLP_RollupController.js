({

    changeMode: function (cmp, event, helper) {
        //this works like a doInit in this case; a doInit is not necessary
        //we check to see if mode is null since the change handler is called when mode is cleared in the container
        var mode = cmp.get("v.mode");
        if(mode != null) {
            console.log("Mode is " + mode);
            console.log("In changeMode");
            //set readonly fields if mode is View, else allow user to make changes
            if(mode != "view"){
                cmp.set("v.isReadOnly",false);
            } else {
                cmp.set("v.isReadOnly", true);
            }
            //this checks that fields are set; this action only needs to be done once per rollup
            if($A.util.isEmpty(cmp.get("v.objectDetails"))){
                console.log('calling helper...');
                helper.setObjectAndFieldDependencies(cmp);
            } else {
                //TODO: this is what's causing the mode to change. there's something wrong with the change handler that seems to be blocking this.
                helper.resetAllFields(cmp);
            }
        }
    },

    onModeChanged:function(cmp,event,helper){
            console.log('heard ModeChanged event');
            var mode = event.getParam('mode');
            cmp.set("v.mode", mode);
    },

    setModeEdit: function(cmp, event, helper) {
        //resetting mode here kicks off changeMode
        cmp.set("v.mode", "edit");
        console.log("In setModeEdit");
    },

    setModeClone: function(cmp, event, helper) {
        //resetting mode here kicks off changeMode
        cmp.set("v.mode", "clone");
    },

    onCancel: function(cmp, event, helper) {
        //resets mode to view to become display-only
        //also needs to reset rollup values to match what exists in the database
        cmp.set("v.mode", "view");
        console.log('in cancel');
        helper.resetRollup(cmp);
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
        //likely: change to 'please select'

    },
    changeSummaryField: function(cmp, event, helper){
        //change summary fields to match available detail field types + existing summary object
        console.log('in change summary field');
        //var detailField = cmp.find("detailFieldSelect").get("v.value");
        var summaryObject = cmp.find("summaryObjectSelect").get("v.value");
        var detailField = cmp.get("v.activeRollup.Detail_Field__r.QualifiedApiName");
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