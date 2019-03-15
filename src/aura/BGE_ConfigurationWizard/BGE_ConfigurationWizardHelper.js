({
    /******************************** Init Functions *****************************/
    init: function(component) {
        var recordId = component.get('v.recordId');
        var sourceBatchId = component.get('v.sourceBatchId');
        var action = component.get('c.getRecordDetails');
        action.setParams({
            'recordId': (sourceBatchId || recordId)
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var model = JSON.parse(response.getReturnValue());
            if (state === 'SUCCESS') {
                this.loadModel(component, model);
            } else {
                this.handleApexErrors(component, response);
            }
        });
        $A.enqueueAction(action);
    },

    /**
     * @description: sets basic batch info and processing settings
     * @param model: parsed JSON response from the model
     */
    loadModel: function(component, model) {
        this.loadBatchInfo(component, model);
        this.loadWizardMetadata(component, model);

        //parse active fields because it's another level JSON object
        let activeFields = JSON.parse(model.activeFields);
        let allFields = model.availableFields;
        this.loadAvailableFields(component, activeFields, allFields);
    },

    /**
     * @description: sets basic batch info and processing settings
     * @param model: parsed JSON model from the model
     */
    loadBatchInfo: function(component, model) {
        let batchInfo = {};

        //generic batch info
        if (!component.get('v.sourceBatchId')) {
            batchInfo.name = model.name;
            batchInfo.id = model.id;
            batchInfo.description = model.description;
            batchInfo.expectedCount = model.expectedCount || 0;
            batchInfo.expectedTotal = model.expectedTotal || 0;
            batchInfo.recordCount = model.recordCount;
        } else {
            batchInfo.name = model.name + ' - ' + $A.get('$Label.c.bgeCopyBatchSetupBatchNameAppend');
            // when copying setup from existing Batch, explicitly initialize these properties
            batchInfo.id = null;
            batchInfo.description = null;
            batchInfo.expectedCount = 0;
            batchInfo.expectedTotal = 0;
            batchInfo.recordCount = null;
        }

        // batch processing settings
        batchInfo.requireTotalMatch = model.requireTotalMatch;
        batchInfo.batchProcessSize = model.batchProcessSize;
        batchInfo.runOpportunityRollupsWhileProcessing = model.runOpportunityRollupsWhileProcessing;
        batchInfo.donationMatchingBehavior = model.donationMatchingBehavior;
        batchInfo.donationMatchingClass = model.donationMatchingClass;
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
        let wizardMetadata = {};
        wizardMetadata.labels = model.labels;
        wizardMetadata.showAdvancedOptions = false;
        wizardMetadata.namespacePrefix = model.namespacePrefix ? model.namespacePrefix+'__' : '';
        wizardMetadata.errorMessage = null;

        wizardMetadata.progressIndicatorStep = '0';
        wizardMetadata.headers = [
            model.labels.recordInfoLabel,
            $A.get('$Label.c.bgeBatchSelectFields'),
            $A.get('$Label.c.bgeBatchSetFieldOptions'),
            $A.get('$Label.c.bgeBatchSetBatchOptions')
        ];
        component.set('v.wizardMetadata', wizardMetadata);
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
                currentField.options = activeFieldMap.get(currentField.id).options;
                currentField.alwaysRequired = activeFieldMap.get(currentField.id).alwaysRequired;
                if (currentField.defaultValue && currentField.type == 'reference') {
                    // recordeditform expects an array for a reference field
                    currentField.defaultValue = [currentField.defaultValue];
                }
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
        let activeFieldsBySObject = this.getActivesBySObject(component);
        // returns map of sobject name => list of fields
        var allFieldsBySObject = this.groupFieldsBySObject(component, everyField);

        let sObjectNames = Object.keys(allFieldsBySObject);
     
        sObjectNames.forEach(function(sObjectName) {
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
            availableFieldsBySObject.fieldGroups.push(currentFieldGroup);
        });
        component.set('v.availableFieldsBySObject', availableFieldsBySObject);
    },
    
    /******************************** Step Functions *****************************/

    /**
     * @description: moves the modal wizard to the next step
     */
    nextStep: function(component) {
        this.stepUp(component);
        this.setModalFooter(component);
        this.setModalHeader(component);
    },

    /**
     * @description: parses and increments the stored step in the wizard
     */
    stepUp: function(component) {
        let stepNum = parseInt(component.get('v.wizardMetadata.progressIndicatorStep'));
        stepNum++;
        let progressIndicatorStep = stepNum.toString();
        component.set('v.wizardMetadata.progressIndicatorStep', progressIndicatorStep);
    },

    /**
     * @description: moves the modal wizard to the previous step
     */
    backStep: function(component) {
        this.stepDown(component);
        this.setModalFooter(component);
        this.setModalHeader(component);
    },

    /**
     * @description: parses and decrements the stored step in the wizard
     */
    stepDown: function(component) {
        let stepNum = parseInt(component.get('v.wizardMetadata.progressIndicatorStep'));
        stepNum--;
        let progressIndicatorStep = stepNum.toString();
        component.set('v.wizardMetadata.progressIndicatorStep', progressIndicatorStep);
    },

    /******************************** Dynamic Display Functions *****************************/

    /**
     * @description sets the showAdvancedOptions flag to hide/reveal the advanced options accordingly
     */
    toggleShowAdvanced: function(component) {
        let showAdvancedOptions = component.get('v.wizardMetadata.showAdvancedOptions');
        component.set('v.wizardMetadata.showAdvancedOptions', !showAdvancedOptions);
    },

    /**
     * @description turns off pendingSave flag to enable Save button if an error is found on save
     */
    enableSaveButton: function(component) {
        component.set('v.wizardMetadata.pendingSave', false);
        this.sendMessage(component,'pendingSave', false);
    },

    /**
     * @description updates the attribute that tracks whether or not Donation Date is selected in the Donation Matching Rule
     */
    updateMatchOnDate: function(component) {
        let donationMatchingRule = component.get('v.batchInfo.donationMatchingRule');
        let matchOnDateSelected = donationMatchingRule.indexOf(component.get('v.wizardMetadata.namespacePrefix') + 'donation_date__c') >= 0;
        component.set('v.wizardMetadata.matchOnDateSelected', matchOnDateSelected);
    },

    /******************************** Sort and Group Functions *****************************/

    /**
     * @description Gets a flat list of the active fields sorted by order.
     * @return List of active fields.
     */
    getActives: function(component) {
        let allFields = component.get('v.everyField');
        let activeFields = [];
        allFields.forEach(function(currentField) {
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
    getActivesBySObject: function(component) {
        let activeFields = this.getActives(component);
        var activesBySObject = this.groupFieldsBySObject(component, activeFields);
        return activesBySObject;
    },

    /**
     * @description Sort the fields by order.
     * @param fields. List of the fields to sort.
     * @return sorted fields.
     */
    sortFieldsByOrder: function(fields) {
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
     * @param fields: list of fields to be grouped.
     * @return Map of SObject name to List of related fields.
     */
    groupFieldsBySObject: function(component, fields) {

        const opportunitySObjectName = component.get('v.wizardMetadata.labels.opportunitySObjectName');
        const paymentSObjectName = component.get('v.wizardMetadata.labels.paymentSObjectName');

        let result = {};
        result[opportunitySObjectName] = [];
        result[paymentSObjectName] = [];

        fields.forEach(function(currentField) {
            if ((currentField.sObjectName in result) === false) {
                result[currentField.sObjectName] = [];
            }
            result[currentField.sObjectName].push(currentField);
        });

        return result;
    },

    /******************************** Validity Functions *****************************/

    /**
     * @description Checks for required fields name and description
     * @return Boolean if user can proceed to next step
     */
    checkBatchInfoValidity: function(component) {
        let batchInfo = component.get('v.batchInfo');
        let isValid = batchInfo.name;

        if (batchInfo.expectedTotal == '' || batchInfo.expectedTotal == null) {
            batchInfo.expectedTotal = 0;
        }
        if (batchInfo.expectedCount == '' || batchInfo.expectedCount == null) {
            batchInfo.expectedCount = 0;
        }
        if (isValid) {
            this.clearError(component);
        } else {
            component.set('v.wizardMetadata.errorMessage', component.get('v.wizardMetadata.labels.missingNameError'));
        }
        return isValid;
    },

    /**
     * @description Checks for required fields Donation Date Range and Batch Process Size
     * @return Boolean if user can proceed to next step
     */
    checkBatchProcessingSettingsValidity: function(component) {
        const batchInfo = component.get('v.batchInfo');
        let isValid = true;
        let errormsg = component.get('v.wizardMetadata.labels.missingFieldsError');

        if (batchInfo.donationDateRange === '') {
            errormsg = errormsg + ' ' + component.get('v.wizardMetadata.labels.donationDateRangeLabel');
            isValid = false;
        }
        if (batchInfo.batchProcessSize === '') {
            errormsg = errormsg + (isValid ? ' ' : ', ') + component.get('v.wizardMetadata.labels.batchProcessSizeLabel');
            isValid = false;
        }

        if (isValid) {
            this.clearError(component);
        } else {
            component.set('v.wizardMetadata.errorMessage', errormsg);
        }
        return isValid;
    },

    /**
     * @description Clears error message and notifies footer via message
     */
    clearError: function(component) {
        component.set('v.wizardMetadata.errorMessage', null);
        this.sendMessage(component, 'setError', false);
    },

    /**
     * @description Shows error message.
     */
    showError: function(component) {
        let message = component.get('v.wizardMetadata.errorMessage');
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
     */
    updateToActive: function(component) {
        var fieldCountPreviousObjects = 0;
        var allFieldsBySObject = this.groupFieldsBySObject(component, component.get('v.everyField'));
        var everyFieldUpdated = [];
        Object.keys(allFieldsBySObject).forEach(function(currentSObject) {
            var batchFieldGroups = component.get('v.availableFieldsBySObject').fieldGroups;
            batchFieldGroups.forEach(function(currentFieldGroup) {
                if (currentFieldGroup.sObjectName === currentSObject) {
                    allFieldsBySObject[currentSObject].forEach(function(currentField) {
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
     */
    updateBatchFieldOptions: function(component) {
        let donationMatchingOptions = [];
        let batchFieldOptions = {
            fieldGroups: []
        };
        let activeFieldsBySObject = this.getActivesBySObject(component);

        let sObjectNames = Object.keys(activeFieldsBySObject);
        sObjectNames.forEach(function(sObjectName) {

            let currentFieldGroup = {
                sObjectName: sObjectName,
                fields: []
            };

            activeFieldsBySObject[sObjectName].forEach(function(currentField) {
                currentFieldGroup.fields.push(currentField);
                currentFieldGroup.sObjectLabel = currentField.sObjectLabel;
                donationMatchingOptions.push({
                    label: currentField.label,
                    value: currentField.name.toLowerCase()
                });
            });

            batchFieldOptions.fieldGroups.push(currentFieldGroup);

        });

        let selectedMatchingRule = component.get('v.batchInfo.donationMatchingRule');
        let donationMatchingOptionValues = donationMatchingOptions.map(function (option) {
            return option.value;
        });
        // Filter out any selected matching rules that aren't selected as available matching fields
        selectedMatchingRule = selectedMatchingRule.filter(function (selectedRule) {
            return (donationMatchingOptionValues.indexOf(selectedRule) >= 0);
        });

        component.set('v.batchFieldOptions', batchFieldOptions);
        component.set('v.batchInfo.donationMatchingOptions', donationMatchingOptions);
        component.set("v.batchInfo.donationMatchingRule", selectedMatchingRule);
    },

    /**
     * @description Commits Batch record
     */
    saveRecord: function(component) {
        var batchInfo = component.get('v.batchInfo');
        // getActives grabs allFields, returns those isActive, sorted.
        let activeFields = this.getActives(component);

        activeFields.forEach(function(currentField) {
            if (currentField.defaultValue && currentField.type == 'reference') {
                // lookups in recordeditform store as an array of IDs; need to flatten
                currentField.defaultValue = currentField.defaultValue[0];
            }
        });

        var action = component.get('c.saveRecord');
        action.setParams({
            'recordInfo': JSON.stringify(batchInfo),
            'activeFields': JSON.stringify(activeFields)
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var response = JSON.parse(response.getReturnValue());
            if (state === 'SUCCESS') {
                var navEvt = $A.get('e.force:navigateToSObject');
                navEvt.setParams({
                    'recordId': response.id
                });
                navEvt.fire();
            } else {
                this.enableSaveButton(component, false);
                this.handleApexErrors(component, response);
            }
        });
        $A.enqueueAction(action);
    },

    /******************************** Utility Functions *****************************/

    /**
     * @description: handles the display of errors from an Apex callout
     * @param response: the Apex response, which may contain errors or may be null
     */
    handleApexErrors: function(component, response) {
        let message;
        let errors;
        if (response) {
            errors = response.getError();
        }
        if (errors && errors[0] && errors[0].message) {
            message = errors[0].message;
        } else {
            message = 'Unknown error';
        }
        component.find('notifLib').showNotice({
            'variant': 'error',
            'header': $A.get('$Label.c.PageMessagesError'),
            'message': message
        });
    },

    /**
     * @description Sets progress indicator step on modal footer
     */
    setModalFooter: function(component) {
        const progressIndicatorStep = component.get('v.wizardMetadata.progressIndicatorStep');
        this.sendMessage(component,'setStep', progressIndicatorStep);
    },

    /**
     * @description Sets header title on modal
     */
    setModalHeader: function(component) {
        const wizardMetadata = component.get('v.wizardMetadata');
        const headers = wizardMetadata.headers;
        const progressIndicatorStep = parseInt(wizardMetadata.progressIndicatorStep);
        this.sendMessage(component,'setHeader', headers[progressIndicatorStep]);
    },

    /**
     * @description Sends a generic ltng:sendMessage
     * @param channel - Channel to use
     * @param message - Message to be sent
     */
    sendMessage: function(component, channel, message) {
        let sendMessage = $A.get('e.ltng:sendMessage');
        sendMessage.setParams({
            'channel': channel,
            'message': message
        });
        sendMessage.fire();
    },
})