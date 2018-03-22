({
    doInit: function(component, event, helper) {


        var actionLoad = component.get('c.loadDataImportApiNames');

        actionLoad.setCallback(this, function (response) {
            //store state of response
            var state = response.getState();
            if (state === "SUCCESS") {

                    var templateFields = response.getReturnValue();
                    var options = [];
                    templateFields.forEach(function (templateField) {

                        options.push({ value: templateField['Name'], label: templateField['Label__c'] });
                    });

                    component.set('v.listOptions', options);

                } else {
                    console.log('Failed with state: ' + state);
                }
            });
        $A.enqueueAction(actionLoad);

        var template = component.get("v.template");

        if (template.Id != null) {

            var action = component.get('c.loadTemplateFields');
            action.setParams({
                "templateId": template.Id
            });
            action.setCallback(this, function (response) {
                //store state of response
                var state = response.getState();

                if (state === "SUCCESS") {

                    if (response.getReturnValue() != null) {

                        var templateFields = response.getReturnValue();
                        var defaultOptions = [];
                        templateFields.forEach(function (templateField) {

                            defaultOptions.push(templateField['Name']);
                        });

                        component.set('v.templateFields', response.getReturnValue());
                        component.set('v.defaultOptions', defaultOptions);
                    }
                }
            });
            $A.enqueueAction(action);

        }
 
        // create a Default RowItem [Contact Instance] on first time Component Load
        // by call this helper function  
        helper.createObjectData(component, event);
    },

    lightningInputOnChange: function(component, event, helper) {

        var templateName = component.find("templateName").get("v.value")

        if (templateName && templateName.length > 2) {
            component.set("v.nextButtonEnabled", true);
        }
    },

    save: function (component, event, helper) {

        var template = component.get('v.template');
        var batchTemplateFields = component.get('v.templateFields');
        var batchTemplateFieldsToDelete = component.get('v.templateFieldsToDelete');

        helper.saveTemplate(component, template, batchTemplateFields, batchTemplateFieldsToDelete);
    },

    nextToInitial: function (component, event, helper) {

        $A.createComponent(
            "c:BGE_Initial",
            {},

            function (newComp) {
                var content = component.find("body");
                content.set("v.body", newComp);
            });
    },

    nextToSelectTemplate: function (component, event, helper) {

        $A.createComponent(
            "c:BGE_BatchContainer",
            {
                'showTemplateSelection': true,
                'showProgressBar': true,
                'processStage': 'selectBatchStage'
            },

            function (newComp) {
                var content = component.find("body");
                content.set("v.body", newComp);
            });
    },

    // function for create new object Row in Contact List 
    addNewRow: function (component, event, helper) {

        // call the comman "createObjectData" helper method for add new Object Row to List  
        helper.createObjectData(component, event);
    },

    // function for delete the row 
    removeRow: function (component, event, helper) {

        // get the selected row Index for delete, from Lightning Event Attribute  
        var index = event.getParam("indexVar");
        var fieldToDelete = event.getParam("templateFieldToDelete");
        var templateFieldsToDelete = component.get("v.templateFieldsToDelete");

        if (fieldToDelete.Id != undefined) {

            templateFieldsToDelete.push(fieldToDelete);
            component.set("v.templateFieldsToDelete", templateFieldsToDelete);
        }

        console.log('FIELD TO DELETE ' + fieldToDelete.Id);
        console.log('FIELDS TO DELETE ' + component.get("v.templateFieldsToDelete"));
        // get the all List (templateFields attribute) and remove the Object Element Using splice method
        var AllRowsList = component.get("v.templateFields");
        AllRowsList.splice(index, 1);
        // set the templateFields after remove selected row element
        component.set("v.templateFields", AllRowsList);
    },

    validateLabel: function (component, event, helper) {

        var data = component.get("v.labelsApiNames");
        var labelValue = component.get("v.labelValue");

        alert('API NAME ' + data[labelValue]);
    },

    handleChange: function (component, event) {
        // Get the list of the "value" attribute on all the selected options
        var selectedOptionsList = event.getParam("value");
        //var selectedOptionsLabels = event.getParam("label");

        var rowItemList = component.get("v.templateFields");
        var index = rowItemList.length;

        while (rowItemList.length > 0) {
            rowItemList.pop();
        }

        for (var indexVar = 0; indexVar < selectedOptionsList.length; indexVar++) {

            rowItemList.push({
                'sobjectType': 'Batch_Template_Field__c',
                'Name': selectedOptionsList[indexVar],
                'Order__c': indexVar+1,
                'Read_Only__c': false,
                'Required__c': false,
                'Sticky_Field__c': false,
                'Sticky_Field_Value__c': '',
                'Sticky_Field_Visibility__c': false
            });
        }

        component.set("v.templateFields", rowItemList);
    }
})