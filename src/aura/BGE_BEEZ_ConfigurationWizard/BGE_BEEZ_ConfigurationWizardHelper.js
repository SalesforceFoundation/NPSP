({
    /******************************** Init Functions *****************************/
    init: function(component) {
        var recordId = component.get('v.recordId');
        var action = component.get('c.getRecordDetails');
        action.setParams({
            'recordId': recordId
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            var model = JSON.parse(response.getReturnValue());
            if (state === 'SUCCESS') {
                this.loadModel(component, model);
            } else if (state === 'ERROR') {
                console.log(response.getError());
                //todo: wire up error handling
                //this.handleApexErrors(component, response.getError());
            }
        });
        $A.enqueueAction(action);
    },
    
    loadModel: function(component, response) {

        let batchInfo = {};

        //generic batch info
        batchInfo.name = response.name;
        batchInfo.id = response.id;
        batchInfo.description = response.description;
        batchInfo.expectedCount = (response.expectedCount === null || response.expectedCount === '') ? 0 : response.expectedCount;
        batchInfo.expectedTotal = (response.expectedTotal === null || response.expectedTotal === '') ? 0 : response.expectedTotal;
        batchInfo.recordCount = response.recordCount;

        // batch processing settings
        batchInfo.requireTotalMatch = response.requireTotalMatch;
        batchInfo.batchProcessSize = response.batchProcessSize;
        batchInfo.runOpportunityRollupsWhileProcessing = response.runOpportunityRollupsWhileProcessing;
        batchInfo.donationMatchingBehavior = response.donationMatchingBehavior;
        batchInfo.donationMatchingClass = response.donationMatchingClass;
        batchInfo.donationMatchingOptions = response.donationMatchingOptions;
        batchInfo.donationMatchingRule = response.donationMatchingRule;
        batchInfo.donationDateRange = response.donationDateRange;
        //todo: @Patrick will fix this - PR: #3973
        //batchInfo.noMatchOnDate = response.donationMatchingRule.indexOf("donation_date__c") < 0;
        batchInfo.postProcessClass = response.postProcessClass;

        component.set('v.batchInfo', batchInfo);

        //batch metadata
        let batchMetadata = {};
        batchMetadata.labels = response.labels;
        //todo: Randi will remove readOnly + mode
        //isReadOnly (View) is passed from record home with lightning app builder
        if (component.get('v.isReadOnly')) {
            //this.setMode(component,'view');
            batchMetadata.mode = 'view';
        } else {
            if (component.get('v.recordId') !== null) {
                //this.setMode(component, 'edit');
                batchMetadata.mode = 'edit';
            } else {
                //this.setMode(component, 'create');
                batchMetadata.mode = 'create';
            }
        }
        batchMetadata.progressIndicatorStep = '0';
        batchMetadata.headers = [
            response.labels.recordInfoLabel,
            $A.get('$Label.c.bgeBatchSelectFields'),
            $A.get('$Label.c.bgeBatchSetFieldOptions'),
            $A.get('$Label.c.bgeBatchSetBatchOptions')
        ];
        component.set('v.batchMetadata', batchMetadata);

        //set available fields for field selection in dueling picklists
        let activeFields = JSON.parse(response.activeFields);
        let allFields = response.availableFields;
        let availableFields = {
            fieldGroups: []
        };
        let everyField = [];
        var activeFieldMap = new Map();

        if (activeFields) {
            activeFields.forEach(function(activeField) {
                var fieldId = activeField.sObjectName + '.' + activeField.name;
                activeFieldMap.set(fieldId, activeField);
            });
        }

        var availableSortOrder = 1;
        allFields.forEach(function(currentField) {
            currentField.id = currentField.sObjectName + '.' + currentField.name;
            //set Active fields with saved sort order
            if (activeFieldMap.has(currentField.id)) {
                currentField.isActive = true;
                currentField.defaultValue = activeFieldMap.get(currentField.id).defaultValue;
                currentField.hide = activeFieldMap.get(currentField.id).hide;
                currentField.requiredInEntryForm = activeFieldMap.get(currentField.id).requiredInEntryForm;
                currentField.sortOrder = activeFieldMap.get(currentField.id).sortOrder;
                currentField.type = activeFieldMap.get(currentField.id).type;
                currentField.formatter = activeFieldMap.get(currentField.id).formatter;
                currentField.options = activeFieldMap.get(currentField.id).options;
                currentField.alwaysRequired = activeFieldMap.get(currentField.id).alwaysRequired;
            } else {
                currentField.isActive = false;
            }
            currentField.availableSortOrder = availableSortOrder;
            availableSortOrder++;
            everyField.push(currentField);
        });

        // sort into groups by object
        // returns map of sobject name => list of fields 
        var activeFieldsBySObject = this.getActivesBySObject(everyField);
        // returns map of sobject name => list of fields 
        var allFieldsBySObject = this.groupFieldsBySObject(everyField);
        debugger;

        Object.keys(allFieldsBySObject).forEach(function(sObjectName) {
            let currentFieldGroup = {
                sObjectName: sObjectName,
                options: [],
                requiredOptions: [],
                values: []
            };

            allFieldsBySObject[sObjectName].forEach(function(currentField) {
                currentFieldGroup.sObjectLabel = currentField.sObjectLabel;
                currentFieldGroup.options.push(
                    {
                        label: currentField.label,
                        value: currentField.id
                    }
                );

                if (currentField.alwaysRequired) {
                    currentFieldGroup.requiredOptions.push(currentField.id);
                }
            });

            if (activeFieldsBySObject[sObjectName]) {
                activeFieldsBySObject[sObjectName].forEach(function(currentField) {
                    currentFieldGroup.values.push(currentField.id);
                });
            }
            availableFields.fieldGroups.push(currentFieldGroup);
        });
        component.set('v.availableFields', availableFields);


        /*
        component.set('v.availableFields', batchFieldsView);
        */


        //batchFieldOptions
        this.loadBatchFieldOptions(component, activeFieldsBySObject);

    },

    loadBatchFieldOptions: function(component, activeFieldsBySObject) {
        debugger;

        let batchFieldOptions = {
            fieldGroups: []
        };
        // todo: wire up this error handling
        // batchFieldOptions.errors = availableFields.errors;

        Object.keys(activeFieldsBySObject).forEach(function (sObjectName) {

            var currentFieldGroup = {
                sObjectName: sObjectName,
                fields: []
            };

            activeFieldsBySObject[sObjectName].forEach(function (currentField) {

                var fieldInfo = {
                    name: currentField.name,
                    sObjectName: currentField.sObjectName,
                    sObjectLabel: currentField.sObjectLabel,
                    label: currentField.label,
                    defaultValue: currentField.defaultValue,
                    requiredInEntryForm: currentField.requiredInEntryForm,
                    hide: currentField.hide,
                    type: currentField.type,
                    formatter: currentField.formatter,
                    options: currentField.options,
                    conditionallyRequired: currentField.conditionallyRequired,
                    alwaysRequired: currentField.alwaysRequired
                };

                currentFieldGroup.fields.push(fieldInfo);
                currentFieldGroup.sObjectLabel = currentField.sObjectLabel;

            });

            batchFieldOptions.fieldGroups.push(currentFieldGroup);

        });
        component.set('v.batchFieldOptions', batchFieldOptions);
    },

    /******************************** Step Functions *****************************/

    nextStep: function(component) {
        /*this.clearError();*/
        this.stepUp(component);
        this.setPageHeader(component);
    },

    stepUp: function(component) {
        let stepNum = parseInt(component.get('v.batchMetadata.progressIndicatorStep'));
        stepNum++;
        let progressIndicatorStep = stepNum.toString();
        component.set('v.batchMetadata.progressIndicatorStep', progressIndicatorStep);
        this.sendMessage(component,'setStep', progressIndicatorStep);
    },

    /**
     * @description sets the pendingsave flag to disable Save button so duplicates can't be created
     * @return void.
     */
    togglePendingSave: function(component) {
        component.get('v.batchMetadata.pendingSave');
        component.set('v.batchMetadata.pendingSave', !pendingSave);
    },

    /******************************** Sort and Group Functions *****************************/

    /**
     * @description Gets the active fields grouped by SObject.
     * @return Map of SObject group to List of related active fields.
     */
    getActivesBySObject: function(allFields){
        debugger;
        var activeFields = [];
        allFields.forEach(function(currentField) {
            if (currentField.isActive) {
                activeFields.push(currentField);
            }
        });
        activeFields = this.sortFieldsByOrder(activeFields);
        return this.groupFieldsBySObject(activeFields);
    },

    /**
     * @description Sort the fields by order.
     * @param fields. List of the fields to sort.
     * @return sorted fields.
     */
    sortFieldsByOrder: function(fields) {
        debugger;
        fields.sort(function(currentField, nextField) {
            if (currentField.sortOrder < nextField.sortOrder) {
                return -1;
            }
            if (currentField.sortOrder > nextField.sortOrder) {
                return 1;
            }
            // numbers must be equal
            return 0;
        });
        return fields;
    },

    /**
     * @description Groups the fields by SObject name.
     * @param fields: list of fields.
     * @return Map of SObject name to List of related fields.
     */
    groupFieldsBySObject: function(fields) {
        debugger;
        var result = {};
        fields.forEach(function(currentField) {
            if ((currentField.sObjectName in result) === false) {
                result[currentField.sObjectName] = [];
            }
            result[currentField.sObjectName].push(currentField);
        });

        return result;
    },

    /******************************** Save Functions *****************************/

    /*setMode: function(component, mode) {
        let batchMetadata = component.get('v.batchMetadata');
        batchMetadata.mode = mode;
        batchMetadata.progressIndicatorStep = '0';
        component.set('v.batchMetadata', batchMetadata);
    },*/


    /******************************** Communication Functions *****************************/

    setPageHeader: function(component) {
        const batchMetadata = component.get('v.batchMetadata');
        const headers = batchMetadata.headers;
        const progressIndicatorStep = parseInt(batchMetadata.progressIndicatorStep);
        this.sendMessage(component,'setHeader', headers[progressIndicatorStep]);
    },

    sendMessage: function(component, channel, message) {
        let sendMessage = $A.get('e.ltng:sendMessage');
        sendMessage.setParams({
            'channel': channel,
            'message': message
        });
        sendMessage.fire();
    }
    
})