({
    doInit: function (component, event, helper) {

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
        var recordId = component.get("v.recordId");

        // If we have a record id, that means we are editing from the button.
        if (recordId) {

            component.set('v.toCreate', false);
            component.set('v.toEdit', true);

            template.Id = recordId;

            var loadTemplateName = component.get('c.loadtemplateName');

            loadTemplateName.setParams({
                "templateId": template.Id
            });

            loadTemplateName.setCallback(this, function (response,component) {

                // store state of response
                var state = response.getState();
                
                if (state === "SUCCESS") {

                    var loadedTemplate = response.getReturnValue();

                //    template.Name = loadedTemplate.Name;
                //    template.Description__c = loadedTemplate.Description__c;
                                        
                    component.set("v.templateNameAttribute", loadedTemplate.Name);
                    component.set("v.templateDescriptionAttribute", loadedTemplate.Description__c);

                //    component.find("templateName").set("v.value",component.get("v.templateNameAttribute"));
                //    component.find("templateDescription").set("v.value",component.get("v.templateDescriptionAttribute"));
                }
                else {

                    console.log('Failed with state: ' + state);
                }


                /*
                // store state of response
                var state = response.getState();

                if (state === "SUCCESS") {

                    var loadedTemplate = response.getReturnValue();

                    template.Name = loadedTemplate.Name;
                    template.Description__c = loadedTemplate.Description__c;

                    var name = '';
                    var description = '';

                    name = template.Name ? "'" + template.Name + "'" : '';
                    description = template.Description__c ? "'" + template.Description__c + "'" : '';

                    component.find("templateName").set("v.value",name);
                    component.find("templateDescription").set("v.value",description);
                }
                else {

                    console.log('Failed with state: ' + state);
                }
                */

            });
            $A.enqueueAction(loadTemplateName);

        }

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
                        var requiredOptions = [];

                        templateFields.forEach(function (templateField) {

                            defaultOptions.push(templateField['Name']);
                            var required = templateField['Required__c'];

                            if (required) {
                                requiredOptions.push(templateField['Name']);
                            }
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

    lightningInputOnChange: function (component, event, helper) {

        var templateName = component.find("templateName").get("v.value")

        if (templateName && templateName.length > 2) {
            component.set("v.nextButtonEnabled", true);
        }
    },

    save: function (component, event, helper) {

        var template = component.get('v.template');
        var recordId = component.get("v.recordId");

        if (recordId) {

            template.Id = recordId;
            //component.set("v.template.Name", component.get("v.templateNameAttribute"));
            //component.set("v.template.Description__c", component.get("v.templateDescriptionAttribute"));
        }

        template.Name = component.get("v.templateNameAttribute");
        template.Description__c = component.get("v.templateDescriptionAttribute");

        var batchTemplateFields = component.get('v.templateFields');
        var batchTemplateFieldsToDelete = component.get('v.templateFieldsToDelete');
        
	    helper.saveTemplate(component, template, batchTemplateFields, batchTemplateFieldsToDelete);            

		var url = window.location.href; 
    	var value = url.substr(0,url.lastIndexOf('/') + 1);

	    window.history.back();

    	return false;        
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


    handleChange: function (component, event) {

        // Get the list of the "value" attribute on all the selected options
        var selectedOptionsList = event.getParam("value");
        //var selectedOptionsLabels = event.getParam("label");
        var rowItemList = component.get("v.templateFields");
        var index = rowItemList.length;

        /************CODE TO DELETE OLD TEMPLATE FIELD ITEMS***********************/
        var selectedIndexVar = 0;
        var existsToDelete = false;

        for (var existingIndexVar = 0; existingIndexVar < rowItemList.length; existingIndexVar++) {

            selectedIndexVar = 0;
            existsToDelete = false;

            var existingTemplateField = rowItemList[existingIndexVar];
            while (!existsToDelete && selectedIndexVar < selectedOptionsList.length) {

                var selectedTemplateField = selectedOptionsList[selectedIndexVar];
                
                if (existingTemplateField.Name === selectedTemplateField) {
                    
                    existsToDelete = true;
                }
                else {
                    
                    selectedIndexVar++;
                }
            }
            if (!existsToDelete) {

                var index = rowItemList.indexOf(existingTemplateField);

                if (index > -1) {
                    
                    rowItemList.splice(index, 1);
                }               
            }
        }
        /************CODE TO DELETE OLD TEMPLATE FIELD ITEMS***********************/

        /************CODE TO ADD NEW TEMPLATE FIELD ITEMS***********************/
        var existingIndexVar = 0;
        var existsToAdd = false;

        for (var selectedIndexVar = 0; selectedIndexVar < selectedOptionsList.length; selectedIndexVar++) {

            existingIndexVar = 0;
            existsToAdd = false;

            var selectedTemplateField = selectedOptionsList[selectedIndexVar];

            while (!existsToAdd && existingIndexVar < rowItemList.length) {

                var existingTemplateField = rowItemList[existingIndexVar];

                if (existingTemplateField.Name == selectedTemplateField) {

                    existsToAdd = true;
                }
                else {
                    existingIndexVar++;
                }
            }

            if (!existsToAdd) {

                //Add new item for template fields with default values.
                rowItemList.push({
                    'sobjectType': 'Batch_Template_Field__c',
                    'Name': selectedOptionsList[selectedIndexVar],
                    'Order__c': selectedIndexVar + 1,
                    'Read_Only__c': false,
                    'Required__c': false                    
                });
            }
        }
		
       
        
        /************CODE TO ADD NEW TEMPLATE FIELD ITEMS***********************/
        component.set("v.templateFields", rowItemList);
        
        if (rowItemList.length > 0) {
            
            component.find("saveButton").set("v.disabled", false);
        }
        else {
            
            component.find("saveButton").set("v.disabled", true);
        }
    },

    scriptLoaded: function (component, event, helper) {
        component.set("v.isjQueryLoaded", true);
    },

    onRequiredChange: function (component, event, helper) {

        var value = event.getParam("value");

        var templateFieldSelected = component.get("v.templateFieldSelected");
        var templateFields = component.get("v.templateFields");

        templateFieldSelected.Required__c = value;

        templateFields.forEach(function (templateField) {

            if (templateField['Name'] === templateFieldSelected.Name) {

                templateField = templateFieldSelected;
                var requiredOptions = component.get('v.requiredOptions');

                if (value) {

                    requiredOptions.push(templateFieldSelected.Name);
                    component.set('v.requiredOptions', requiredOptions);
                }
                else {

                    var index = requiredOptions.indexOf(templateFieldSelected.Name);

                    requiredOptions.splice(index, 1);
                    component.set('v.requiredOptions', requiredOptions);

                }
            }
        });
    },

})