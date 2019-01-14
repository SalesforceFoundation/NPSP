({
    /******************************** Init Functions *****************************/
    init: function (component) {
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
                this.handleApexErrors(component, response.getError());
            }
        });
        $A.enqueueAction(action);
    },

    /**
     * @description: sets basic batch info and processing settings
     * @param model: parsed JSON response from the model
     */
    loadModel: function (component, model) {
        this.loadBatchInfo(component, model);
        this.loadWizardMetadata(component, model);

        //parse active fields because it's another level JSON object
        let activeFields = JSON.parse(model.activeFields);
        let allFields = model.availableFields;
        this.loadAvailableFields(component, activeFields, allFields);

        let availableFieldsBySObject = component.get('v.availableFieldsBySObject');
        this.loadBatchFieldOptions(component, availableFieldsBySObject);
    },

    /**
     * @description: sets basic batch info and processing settings
     * @param model: parsed JSON model from the model
     */
    loadBatchInfo: function(component, model) {
        let batchInfo = {};

        //generic batch info
        batchInfo.name = model.name;
        batchInfo.id = model.id;
        batchInfo.description = model.description;
        batchInfo.expectedCount = (model.expectedCount === null || model.expectedCount === '') ? 0 : model.expectedCount;
        batchInfo.expectedTotal = (model.expectedTotal === null || model.expectedTotal === '') ? 0 : model.expectedTotal;
        batchInfo.recordCount = model.recordCount;

        // batch processing settings
        batchInfo.requireTotalMatch = model.requireTotalMatch;
        batchInfo.batchProcessSize = model.batchProcessSize;
        batchInfo.runOpportunityRollupsWhileProcessing = model.runOpportunityRollupsWhileProcessing;
        batchInfo.donationMatchingBehavior = model.donationMatchingBehavior;
        batchInfo.donationMatchingClass = model.donationMatchingClass;
        batchInfo.donationMatchingOptions = model.donationMatchingOptions;
        batchInfo.donationMatchingRule = model.donationMatchingRule;
        batchInfo.donationDateRange = model.donationDateRange;
        batchInfo.postProcessClass = model.postProcessClass;

        component.set('v.batchInfo', batchInfo);
    },

    /**
     * @description: sets wizard metadata such as labels and current step
     * @param model: parsed JSON response from the model
     */
    loadWizardMetadata: function(component, model) {
        let batchMetadata = {};
        batchMetadata.labels = model.labels;
        batchMetadata.showAdvancedOptions = false;
        batchMetadata.namespacePrefix = model.namespacePrefix ? model.namespacePrefix+'__' : '';
        batchMetadata.errorMessage = null;

        //todo: Beth! will remove readOnly + mode
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
            model.labels.recordInfoLabel,
            $A.get('$Label.c.bgeBatchSelectFields'),
            $A.get('$Label.c.bgeBatchSetFieldOptions'),
            $A.get('$Label.c.bgeBatchSetBatchOptions')
        ];
        component.set('v.batchMetadata', batchMetadata);
        this.updateMatchOnDate(component);
    },

    /**
     * @description: set available fields for field selection in dueling picklist
     * @param activeFields: parsed list of user-selected active fields
     * @param allFields: parsed list of all possible fields for dueling picklist
     */
    loadAvailableFields: function(component, activeFields, allFields) {
        let availableFieldsBySObject = {
            fieldGroups: []
        };
        let everyField = [];
        var activeFieldMap = new Map();

        if (activeFields) {
            activeFields.forEach(function (activeField) {
                var fieldId = activeField.sObjectName + '.' + activeField.name;
                activeFieldMap.set(fieldId, activeField);
            });
        }

        var availableSortOrder = 1;
        allFields.forEach(function (currentField) {
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

        // store everyField with its metadata
        component.set('v.everyField', everyField);
        // sort into groups by object
        // returns map of sobject name => list of fields
        var activeFieldsBySObject = this.getActivesBySObject(component);
        // returns map of sobject name => list of fields
        var allFieldsBySObject = this.groupFieldsBySObject(everyField);

        Object.keys(allFieldsBySObject).forEach(function (sObjectName) {
            let currentFieldGroup = {
                sObjectName: sObjectName,
                options: [],
                requiredOptions: [],
                values: []
            };

            allFieldsBySObject[sObjectName].forEach(function (currentField) {
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
                activeFieldsBySObject[sObjectName].forEach(function (currentField) {
                    currentFieldGroup.values.push(currentField.id);
                });
            }
            availableFieldsBySObject.fieldGroups.push(currentFieldGroup);
        });
        component.set('v.availableFieldsBySObject', availableFieldsBySObject);
    },

    /**
     * @description: sets batch field options, which is the derived set of active fields with applicable defaults
     * and requiredness
     * @param activeFieldsBySObject: fields set in loadAvailableFields
     */
    loadBatchFieldOptions: function (component, activeFieldsBySObject) {

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

    /**
     * @description: moves the modal to the next step in the wizard
     */
    nextStep: function (component) {
        this.stepUp(component);
        this.setModalFooter(component);
        this.setModalHeader(component);
    },

    /**
     * @description: parses and increments the current step in the wizard
     */
    stepUp: function (component) {
        let stepNum = parseInt(component.get('v.batchMetadata.progressIndicatorStep'));
        stepNum++;
        let progressIndicatorStep = stepNum.toString();
        component.set('v.batchMetadata.progressIndicatorStep', progressIndicatorStep);
    },

    /**
     * @description: moves the modal to the previous step in the wizard
     */
    backStep: function (component) {
        this.clearError(component);
        this.stepDown(component);
        this.setModalFooter(component);
        this.setModalHeader(component);
    },

    /**
     * @description: parses and decrements the current step in the wizard
     */
    stepDown: function (component) {
        let stepNum = parseInt(component.get('v.batchMetadata.progressIndicatorStep'));
        stepNum--;
        let progressIndicatorStep = stepNum.toString();
        component.set('v.batchMetadata.progressIndicatorStep', progressIndicatorStep);
    },

    /******************************** Dynamic Display Functions *****************************/

    /**
     * @description sets the showAdvancedOptions flag to hide/reveal the advanced options accordingly
     */
    toggleShowAdvanced: function (component) {
        let showAdvancedOptions = component.get('v.batchMetadata.showAdvancedOptions');
        component.set('v.batchMetadata.showAdvancedOptions', !showAdvancedOptions);
    },         

    /**
     * @description turns off pendingSave flag to enable Save button if an error is found on save
     */
    enableSaveButton: function (component) {
        component.set('v.batchMetadata.pendingSave', false);
        this.sendMessage(component,'pendingSave', false);
    },

    /**
     * @description updates the attribute that tracks whether or not Donation Date is selected in the Donation Matching Rule
     * @return void.
     */
    updateMatchOnDate: function (component) {
        let donationMatchingRule = component.get('v.batchInfo.donationMatchingRule');
        let matchOnDateSelected = donationMatchingRule.indexOf(component.get('v.batchMetadata.namespacePrefix') + "donation_date__c") >= 0;
        component.set('v.batchMetadata.matchOnDateSelected', matchOnDateSelected);
    },

    /******************************** Sort and Group Functions *****************************/

    /**
     * @description Gets a flat list of the active fields sorted by order.
     * @return List of active fields.
     */
    getActives: function (component) {
        let allFields = component.get('v.everyField');
        let activeFields = [];
        allFields.forEach(function (currentField) {
            if (currentField.isActive) {
                activeFields.push(currentField);
            }
        });
        var sortedActiveFields = this.sortFieldsByOrder(activeFields);
        return sortedActiveFields;
    },

    /**
     * @description Gets the active fields sorted and grouped by SObject.
     * @return Map of SObject group to List of related active fields.
     */
    getActivesBySObject: function (component) {
        let activeFields = this.getActives(component);
        var activesBySObject = this.groupFieldsBySObject(activeFields);
        return activesBySObject;
    },

    /**
     * @description Sort the fields by order.
     * @param fields. List of the fields to sort.
     * @return sorted fields.
     */
    sortFieldsByOrder: function (fields) {
        fields.sort(function (currentField, nextField) {
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
    groupFieldsBySObject: function (fields) {
        var result = {};
        fields.forEach(function (currentField) {
            if ((currentField.sObjectName in result) === false) {
                result[currentField.sObjectName] = [];
            }
            result[currentField.sObjectName].push(currentField);
        });

        return result;
    },

    /******************************** Validity Functions *****************************/

    /**
     * @description  
     * @return Boolean.
     */
    checkBatchInfoValidity: function (component) {
        let batchInfo = component.get('v.batchInfo');
        let isValid = batchInfo.name && batchInfo.description;
        if (isValid) {
            this.clearError(component);
        } else {
            component.set('v.batchMetadata.errorMessage', component.get('v.batchMetadata.labels.missingNameDescriptionError'));    
        }
        return isValid;
    },

    /**
     * @description 
     * @return Boolean.
     */
    checkBatchFieldOptionsValidity: function (component) {
        var isValid = component.find("defaultValueField").reduce(function (validSoFar, defaultValueField) {
            return validSoFar && defaultValueField.get("v.validity").valid;
        }, true);
        return isValid;
    },

    /**
     * @description 
     * @return Boolean.
     */
    checkBatchProcessingSettingsValidity: function (component) {
        let batchInfo = component.get('v.batchInfo');
        let isValid = batchInfo.donationDateRange !== '' &&
            batchInfo.donationDateRange > -1 &&
            batchInfo.batchProcessSize !== '' &&
            batchInfo.batchProcessSize > 0;
        if (isValid) {
            this.clearError(component);
        } else {
            component.set('v.batchMetadata.errorMessage', component.get('v.batchMetadata.labels.missingProcessingSettingsError'));
        }
        return isValid;
    },

    /**
     * @description Clears error message and notifies footer via message
     * @return void.
     */
    clearError: function (component) {
        component.set('v.batchMetadata.errorMessage', null);
        this.sendMessage(component, 'setError', false);
    },

    /**
     * @description Shows error message.
     * @return void.
     */
    showError: function (component) {
        let message = component.get('v.batchMetadata.errorMessage');
        if (message) {
            component.find('notifLib').showNotice({
                'variant': 'error',
                'header': $A.get('$Label.c.PageMessagesError'),
                'message': message
            });      
        }
        // when in modal context, need to notify the modal footer component
        this.sendMessage(component, 'setError', true);              
    },     

    /******************************** Save Functions *****************************/

    /**
     * @description Updates isActive flag and sort Order of all fields
     * @return void.
     */
    updateToActive: function (component) {
        var fieldCountPreviousObjects = 0;
        var allFieldsBySObject = this.groupFieldsBySObject(component.get('v.everyField'));
        var everyFieldUpdated = [];
        Object.keys(allFieldsBySObject).forEach(function (currentSObject) {
            var batchFieldGroups = component.get('v.availableFieldsBySObject').fieldGroups;
            batchFieldGroups.forEach(function (currentFieldGroup) {
                if (currentFieldGroup.sObjectName === currentSObject) {
                    allFieldsBySObject[currentSObject].forEach(function (currentField) {
                        currentField.isActive = currentFieldGroup.values.includes(currentField.id);
                        // the field's sort order is its index PLUS the total of all active fields from all previous object groups
                        currentField.sortOrder = currentField.isActive ? currentFieldGroup.values.indexOf(currentField.id) + fieldCountPreviousObjects : null;
                        everyFieldUpdated.push(currentField);
                    });
                    // increase the buffer by the number of active fields from this object
                    fieldCountPreviousObjects += currentFieldGroup.values.length;
                }
            });
        });
        component.set('v.everyField', everyFieldUpdated);
    },

    /**
     * @description Updates batchFieldOptions attribute based on selected fields
     * @return void.
     */
    updateBatchFieldOptions: function (component) {
        let batchFieldOptions = {
            fieldGroups: []
        };
        let activeFieldsBySObject = this.getActivesBySObject(component);
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

    /**
     * @description Updates the selected fields to Active, unselects fields
     * @return void.
     */
    commitBatchFieldOptionsToEveryField: function (component) {

        var batchFieldGroups = component.get('v.batchFieldOptions.fieldGroups');
        var batchFieldOptions = [];
        batchFieldGroups.forEach(function (currentFieldGroup) {
            currentFieldGroup.fields.forEach(function (currentField) {
                batchFieldOptions.push(currentField);
            });
        });

        let everyField = component.get('v.everyField');

        everyField.forEach(function (currentField) {
            batchFieldOptions.forEach(function (currentActiveField) {
                if (currentField.name === currentActiveField.name) {
                    currentField.requiredInEntryForm = currentActiveField.requiredInEntryForm;
                    currentField.hide = currentActiveField.hide;
                    currentField.defaultValue = currentActiveField.defaultValue;
                }
            });
        });

        component.set('v.everyField',everyField);
    },

    /*setMode: function (component, mode) {
        let batchMetadata = component.get('v.batchMetadata');
        batchMetadata.mode = mode;
        batchMetadata.progressIndicatorStep = '0';
        component.set('v.batchMetadata', batchMetadata);
    },*/

    saveRecord: function (component) {
        var batchInfo = component.get('v.batchInfo');
        // getActives grabs allFields, returns those isActive, sorted.
        let activeFields = this.getActives(component);

        var action = component.get('c.saveRecord');
        action.setParams({
            'recordInfo': JSON.stringify(batchInfo),
            'activeFields': JSON.stringify(activeFields)
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            var response = JSON.parse(response.getReturnValue());
            if (state === 'SUCCESS') {
                var navEvt = $A.get('e.force:navigateToSObject');
                navEvt.setParams({
                    'recordId': response.id
                });
                navEvt.fire();
            } else if (state === 'ERROR') {
                this.enableSaveButton(component, false);
                this.handleApexErrors(component, response.getError());
            }
        });
        $A.enqueueAction(action);
    },

    /******************************** Utility Functions *****************************/

    /**
     * @description: handles the display of errors from an apex callout
     * @param errors: list of potential errors passed back from apex
     */
    handleApexErrors: function(component, errors) {
        let message;
        if (errors && errors[0] && errors[0].message) {
            message = errors[0].message;
        } else {
            message = 'Unknown error';
        }
        component.find('notifLib').showToast({
            'variant': 'error',
            'mode': 'sticky',
            'title': $A.get('$Label.c.PageMessagesError'),
            'message': message
        });
    },

    setModalFooter: function (component) {
        const progressIndicatorStep = component.get('v.batchMetadata.progressIndicatorStep');
        this.sendMessage(component,'setStep', progressIndicatorStep);
    },

    setModalHeader: function (component) {
        const batchMetadata = component.get('v.batchMetadata');
        const headers = batchMetadata.headers;
        const progressIndicatorStep = parseInt(batchMetadata.progressIndicatorStep);
        this.sendMessage(component,'setHeader', headers[progressIndicatorStep]);
    },

    sendMessage: function (component, channel, message) {
        let sendMessage = $A.get('e.ltng:sendMessage');
        sendMessage.setParams({
            'channel': channel,
            'message': message
        });
        sendMessage.fire();
    },
})