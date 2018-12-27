({
    /********************************************* View Modules *********************************************/

    /**
     * @description Returns the Batch Info View module.
     * @param component. Lightning Component reference.
     * @param model. The Model.
     * @return View of the Batch Info module.
     */
    BatchInfoView : function(component, model) {
        return (function (component, model) {

            // Subscribe to the model onInfoUpdated event.
            model.getBatchInfo().onInfoUpdated.subscribe(function() {
                var batchInfoView = component.get('v.batchInfo');
                var batchInfo = model.getBatchInfo();

                // record info
                batchInfoView.name = batchInfo.name;
                batchInfoView.id = batchInfo.id;
                batchInfoView.description = batchInfo.description;
                batchInfoView.expectedCount = batchInfo.expectedCount;
                batchInfoView.expectedTotal = batchInfo.expectedTotal;
                batchInfoView.recordCount = batchInfo.recordCount;

                // batch processing settings
                batchInfoView.requireTotalMatch = batchInfo.requireTotalMatch;
                batchInfoView.batchProcessSize = batchInfo.batchProcessSize;
                batchInfoView.runOpportunityRollupsWhileProcessing = batchInfo.runOpportunityRollupsWhileProcessing;
                batchInfoView.donationMatchingBehavior = batchInfo.donationMatchingBehavior;
                batchInfoView.donationMatchingClass = batchInfo.donationMatchingClass;
                batchInfoView.donationMatchingOptions = batchInfo.donationMatchingOptions;
                batchInfoView.donationMatchingRule = batchInfo.donationMatchingRule;
                batchInfoView.donationDateRange = batchInfo.donationDateRange;
                batchInfoView.noMatchSelected = batchInfo.noMatchSelected;
                batchInfoView.noMatchOnDate = batchInfo.noMatchOnDate;
                batchInfoView.postProcessClass = batchInfo.postProcessClass;
                batchInfoView.processUsingScheduledJob = batchInfo.processUsingScheduledJob;

                component.set('v.batchInfo', batchInfoView);
            });

            // BatchInfoView module public functions and properties
            return {
                name: '',
                id: '',
                description: '',
                expectedCount: 0,
                expectedTotal: 0,
                recordCount: 0,

                // batch processing settings
                requireTotalMatch: false,
                batchProcessSize: 0,
                runOpportunityRollupsWhileProcessing: false,
                donationMatchingBehavior: '',
                donationMatchingClass: '',
                donationMatchingOptions: [],
                donationMatchingRule: [],
                donationDateRange: '',
                noMatchSelected: false,
                noMatchOnDate: false,
                postProcessClass: '',
                processUsingScheduledJob: false
            };
        })(component, model);
    },

    /**
     * @description Returns the Batch Metadata View module.
     * @param component. Lightning Component reference.
     * @param model. The Model.
     * @return View of the Batch Metadata module.
     */
    BatchMetadataView : function(component, model) {
        return (function (component, model) {

            // Subscribe to the model onMetadataUpdated event.
            model.getBatchMetadata().onMetadataUpdated.subscribe(function() {
                var batchMetadataView = component.get('v.batchMetadata');
                var batchMetadata = model.getBatchMetadata();
                var headerChanged = Boolean(batchMetadataView.pageHeader !== batchMetadata.pageHeader);

                batchMetadataView.labels = batchMetadata.labels;
                batchMetadataView.mode = batchMetadata.mode;
                batchMetadataView.hasError = batchMetadata.hasError;
                batchMetadataView.errorMessage = batchMetadata.errorMessage;
                batchMetadataView.pageHeader = batchMetadata.pageHeader;
                batchMetadataView.pendingSave = batchMetadata.pendingSave;
                batchMetadataView.showAdvancedOptions = batchMetadata.showAdvancedOptions;

                if (!batchMetadataView.hasError) {
                    batchMetadataView.progressIndicatorStep = batchMetadata.progressIndicatorStep;
                    _sendMessage('setStep',batchMetadata.progressIndicatorStep);
                } else {
                    component.find('notifLib').showNotice({
                        'variant': 'error',
                        'header': $A.get('$Label.c.PageMessagesError'),
                        'message': batchMetadataView.errorMessage,
                        closeCallback: function() {
                            //callback action here
                        }
                    });
                }

                if (batchMetadataView.mode === 'view') {
                    component.set('v.isReadOnly', true);
                } else if (batchMetadataView.mode === 'create' || batchMetadataView.mode === 'edit') {
                    component.set('v.isReadOnly', false);
                }

                //update page header in modal if page header has changed and modal is used
                if (headerChanged) {
                    _sendMessage('setHeader', batchMetadataView.pageHeader);
                }

                //update footer in modal to keep save button appropriately enabled/disabled
                _sendMessage('pendingSave', batchMetadataView.pendingSave);

                // when in modal context, need to notify the modal footer component
                _sendMessage('setError', batchMetadataView.hasError);

                component.set('v.batchMetadata', batchMetadataView);
            });

            function _sendMessage(channel, message) {
                var sendMessage = $A.get('e.ltng:sendMessage');
                sendMessage.setParams({
                    'channel': channel,
                    'message': message
                });
                sendMessage.fire();
            }

            // BatchMetadataView module public functions and properties
            return {
                labels: {},
                mode: '',
                progressIndicatorStep: '',
                hasError: false,
                errorMessage: '',
                pendingSave: false,
                showAdvancedOptions: false
            };
        })(component, model);
    },

    /**
     * @description Returns the Batch Fields View module.
     * @param component. Lightning Component reference.
     * @param model. The Batch Fields Model.
     * @return View of the Batch Fields module.
     */
    BatchFieldsView : function(component, model) {
        return (function (component, model) {

            // Subscribe to the model onFieldsUpdated event.
            model.getAvailableFields().onFieldsUpdated.subscribe(function() {
                var availableFields = component.get('v.availableFields');
                availableFields.fieldGroups = [];

                var activeFieldsBySObject = model.getAvailableFields().getActivesBySObject();
                var allFieldsBySObject = model.getAvailableFields().getAllFieldsBySObject();

                Object.keys(allFieldsBySObject).forEach(function(sObjectName) {
                    var currentFieldGroup = {
                        sObjectName : sObjectName,
                        options: [],
                        requiredOptions: [],
                        values: []
                    };

                    allFieldsBySObject[sObjectName].forEach(function(currentField) {
                        currentFieldGroup.options.push(
                            {
                                label: currentField.label,
                                value: currentField.id
                            }
                        );
                        //special case so Amount object is always visible
                        if (currentField.id.includes('Donation_Amount__c')) {
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
            });

            // BatchFieldsView module public functions and properties
            return {
                fieldGroups: []
            };
        })(component, model);
    },

    /**
     * @description Returns the Batch Field Options View module.
     * @param component. Lightning Component reference.
     * @param model. The Batch Fields Model.
     * @return View of the Batch Field Options module.
     */
    BatchFieldOptionsView : function(component, model) {
        return (function (component, model) {

            // Subscribe to the model onFieldsUpdated event.
            model.getAvailableFields().onFieldsUpdated.subscribe(function() {
                var batchFieldOptions = component.get('v.batchFieldOptions');
                batchFieldOptions.fieldGroups = [];
                var activeFieldsBySObject = model.getAvailableFields().getActivesBySObject();
                var availableFields = model.getAvailableFields();
                batchFieldOptions.errors = availableFields.errors;

                Object.keys(activeFieldsBySObject).forEach(function (sObjectName) {

                    var currentFieldGroup = {
                        sObjectName : sObjectName,
                        fields: []
                    };

                    activeFieldsBySObject[sObjectName].forEach(function (currentField) {

                        var fieldInfo = {
                            name: currentField.name,
                            sObjectName: currentField.sObjectName,
                            label: currentField.label,
                            defaultValue: currentField.defaultValue,
                            required: currentField.required,
                            hide: currentField.hide,
                            type: currentField.type,
                            formatter: currentField.formatter,
                            options: currentField.options
                        }

                        if (currentField.sObjectName === 'Opportunity' &&
                            (currentField.name == 'npsp__Donation_Amount__c' || currentField.name == 'Donation_Amount__c')) {
                            fieldInfo.systemRequired = true;
                        }

                        currentFieldGroup.fields.push(fieldInfo);

                    });

                    batchFieldOptions.fieldGroups.push(currentFieldGroup);

                });
                component.set('v.batchFieldOptions', batchFieldOptions);

            });

            // BatchFieldOptionsView module public functions and properties
            return {
                fieldGroups: []
            };

        })(component, model);
    },


    /*********************************************** Model Modules *********************************************/

    /**
     * @description Gets the Model module of Batch Details.
     * This is the main and only Model module for the Batch
     * Details components. Contains references to BatchFields
     * and BatchInfo sub-modules.
     * @return Model module of Batch Details.
     */
    DetailsModel : function() {
        return (function (availableFields, batchInfo, batchMetadata) {
            var _availableFields = availableFields;
            var _batchInfo = batchInfo;
            var _batchMetadata = batchMetadata;
            var _bgeBatchController;

            /* **********************************************************
             * @Description Gets the Batch Details and loads sub-modules.
             * @param component. Lightning Component reference.
             * @return void.
             ************************************************************/
            function init(component) {
                var recordId = _batchInfo.id ? _batchInfo.id : component.get('v.recordId');
                _bgeBatchController.getRecordDetails(recordId, {
                    success: function(response) {
                        _batchInfo.load(response);
                        _availableFields.load(response.availableFields, JSON.parse(response.activeFields));
                        _batchMetadata.load(response.labels, component);
                    },
                    error: function(error) {
                        _batchMetadatas.showError(error);
                        console.log(error);
                    }
                });
            }

            /**
             * @description Saves the model information to the backend.
             * @return void.
             */
            function save() {
                var batchDetailsData = {
                    //record info
                    name: _batchInfo.name,
                    id: _batchInfo.id,
                    description: _batchInfo.description,
                    expectedCount: _batchInfo.expectedCount,
                    expectedTotal: _batchInfo.expectedTotal,

                    // batch processing settings
                    requireTotalMatch: _batchInfo.requireTotalMatch,
                    batchProcessSize: _batchInfo.batchProcessSize,
                    runOpportunityRollupsWhileProcessing: _batchInfo.runOpportunityRollupsWhileProcessing,
                    donationMatchingBehavior: _batchInfo.donationMatchingBehavior,
                    donationMatchingClass: _batchInfo.donationMatchingClass,
                    donationMatchingRule: _batchInfo.donationMatchingRule,
                    donationDateRange: _batchInfo.donationDateRange,
                    postProcessClass: _batchInfo.postProcessClass,
                    processUsingScheduledJob: _batchInfo.processUsingScheduledJob
                };
                var activeFields = [];

                _availableFields.getActives().forEach(function(currentField) {
                    activeFields.push({
                        label: currentField.label,
                        name: currentField.name,
                        sObjectName: currentField.sObjectName,
                        defaultValue: currentField.defaultValue,
                        required: currentField.required,
                        hide: currentField.hide,
                        sortOrder: currentField.sortOrder,
                        type: currentField.type,
                        options: currentField.options
                    });
                });

                _bgeBatchController.saveRecord(batchDetailsData, activeFields, {
                    success: function(response) {
                        _batchMetadata.navigateToRecord(response.id);
                    },
                    error: function(error) {
                        console.log(error);
                        _batchMetadata.togglePendingSave();
                    }
                });
            }

            /**
             * @description Sets the Apex backend controller module.
             * @return void.
             */
            function setBackendController(bgeBatchController) {
                _bgeBatchController = bgeBatchController
            }

            /**
             * @description Gets the Batch Fields module.
             * @return Batch Fields module.
             */
            function getAvailableFields() {
                return _availableFields;
            }

            /**
             * @description Gets the Batch Info module.
             * @return Batch Info module.
             */
            function getBatchInfo() {
                return _batchInfo;
            }

            /**
             * @description Gets the Batch Metadata module.
             * @return Batch Metadata module.
             */
            function getBatchMetadata() {
                return _batchMetadata;
            }

            // DetailsModel module public functions and properties
            return {
                init: init,
                save: save,
                setBackendController: setBackendController,
                getAvailableFields: getAvailableFields,
                getBatchInfo: getBatchInfo,
                getBatchMetadata: getBatchMetadata
            }
        })(this.BatchFields(), this.BatchInfo(), this.BatchMetadata());
    },

    /**
     * @description Gets the Model module of the Batch Info.
     * @return Model module of the Batch Info.
     */
    BatchInfo : function() {
        return (function (Event) {
            var _onInfoUpdated = new Event(this);

            /**
             * @description Loads the Info, and notify all the
             * _onInfoUpdated listeners.
             * @return List of fields.
             */
            function load(info) {
                //record info
                this.name = info.name;
                this.description = info.description;
                this.id = info.id;
                this.expectedCount = (info.expectedCount === null || info.expectedCount === '') ? 0 : info.expectedCount;
                this.expectedTotal = (info.expectedTotal === null || info.expectedTotal === '') ? 0 : info.expectedTotal;
                this.recordCount = info.recordCount;

                //batch processing settings
                this.requireTotalMatch = info.requireTotalMatch;
                this.batchProcessSize = info.batchProcessSize;
                this.runOpportunityRollupsWhileProcessing = info.runOpportunityRollupsWhileProcessing;
                this.donationMatchingBehavior = info.donationMatchingBehavior;
                this.donationMatchingClass = info.donationMatchingClass;
                this.donationMatchingOptions = info.donationMatchingOptions;
                this.donationMatchingRule = info.donationMatchingRule;
                this.donationDateRange = info.donationDateRange;
                this.postProcessClass = info.postProcessClass;
                this.processUsingScheduledJob = info.processUsingScheduledJob;
                this.noMatchSelected = (info.donationMatchingBehavior === "Do Not Match");
                this.noMatchOnDate = !(info.donationMatchingRule.includes("donation_date__c"));

                this.onInfoUpdated.notify();
            }

            /**
             * @description Validates the required batchInfo.
             * @return Boolean validity.
             */
            function isValid() {
                return this.name && this.description
            }

            // BatchInfo module public functions and properties
            return {
                // record info
                name: '',
                id: '',
                description: '',
                expectedCount: 0,
                expectedTotal: 0,
                recordCount: 0,

                // batch processing settings
                requireTotalMatch: false,
                batchProcessSize: 0,
                runOpportunityRollupsWhileProcessing: false,
                donationMatchingBehavior: '',
                donationMatchingClass: '',
                donationMatchingOptions: [],
                donationMatchingRule: [],
                donationDateRange: '',
                postProcessClass: '',
                processUsingScheduledJob: false,
                load: load,
                isValid: isValid,
                noMatchSelected: false,
                noMatchOnDate: false,
                onInfoUpdated: _onInfoUpdated
            }
        })(this.Event());
    },

    /**
     * @description Gets the Batch Fields module.
     * @return Model module of the Batch Fields.
     */
    BatchFields : function() {
        return (function (Event) {
            var _allFields = [];
            var _onFieldsUpdated = new Event(this);

            /* ******************PUBLIC FUNCTIONS*************************/

            /**
             * @description Load the fields and notify onFieldsUpdated listeners.
             * @param allFields: list of allFields with sObjectName/Name.
             * param activeFields: Map of activeFieldsBySObject with sObjectName, Name,
             * and Default Value, Hide and Required flags.
             * @return void.
             */
            function load(allFields, activeFields) {
                _allFields = [];
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
                        currentField.required = activeFieldMap.get(currentField.id).required;
                        currentField.sortOrder = activeFieldMap.get(currentField.id).sortOrder;
                        currentField.type = activeFieldMap.get(currentField.id).type;
                        currentField.formatter = activeFieldMap.get(currentField.id).formatter;
                        currentField.options = activeFieldMap.get(currentField.id).options;
                    } else {
                        currentField.isActive = false;
                    }
                    currentField.availableSortOrder = availableSortOrder;
                    availableSortOrder++;
                    _allFields.push(currentField);
                });
                this.onFieldsUpdated.notify();
            }

            /**
             * @description Gets all fields grouped by SObject.
             * @return Map of SObject group to List of all fields.
             */
            function getAllFieldsBySObject() {
                return _groupFieldsBySObject(_allFields);
            }

            /**
             * @description Gets the available fields grouped by SObject.
             * @return Map of SObject group to List of inactive fields.
             */
            function getAvailablesBySObject() {
                var availableFields = [];
                _allFields.forEach(function(currentField) {
                    if (!currentField.isActive) {
                        availableFields.push(currentField);
                    }
                });
                return _groupFieldsBySObject(availableFields);
            }

            /**
             * @description Gets the active fields.
             * @return Sorted List of related active fields.
             */
            function getActives() {
                var activeFields = [];
                _allFields.forEach(function(currentField) {
                    if (currentField.isActive) {
                        activeFields.push(currentField);
                    }
                });
                return _sortFieldsByOrder(activeFields);
            }

            /**
             * @description Gets the active fields grouped by SObject.
             * @return Map of SObject group to List of related active fields.
             */
            function getActivesBySObject() {
                var activeFields = [];
                _allFields.forEach(function(currentField) {
                    if (currentField.isActive) {
                        activeFields.push(currentField);
                    }
                });
                activeFields = _sortFieldsByOrder(activeFields);
                return _groupFieldsBySObject(activeFields);
            }

            /**
             * @description Gets the aggregate validity of provided default values
             * @return Boolean
             */
            function getDefaultFieldValidity(component) {
                var isValid = component.find("defaultValueField").reduce(function (validSoFar, defaultValueField) {
                    return validSoFar && defaultValueField.get("v.validity").valid;
                }, true);
                return isValid;
            }

            /**
             * @description Validates the required batchInfo in Select Fields step.
             * @return Boolean validity.
             */
            function getRequiredFieldErrors() {
                var errors = [];
                var activeFieldsBySObject = getActivesBySObject();
                var systemRequiredFieldsBySObject = _getSystemRequiredFieldsBySObject();

                Object.keys(systemRequiredFieldsBySObject).forEach(function(currentSObject) {
                    var activeFieldNames = [];
                    var systemRequiredFieldNames = new Map();

                    //only check validity if sObject is included in activeFieldsBySObject
                    if (activeFieldsBySObject[currentSObject]) {
                        activeFieldsBySObject[currentSObject].forEach(function(currentField) {
                            activeFieldNames.push(currentField.name);
                        });
                        systemRequiredFieldsBySObject[currentSObject].forEach(function(currentField) {
                            systemRequiredFieldNames.set(currentField.name, currentField.label);
                        });

                        var containsSystemRequiredField = Array.from(systemRequiredFieldNames.keys()).every(function(currentFieldName) {
                            return activeFieldNames.indexOf(currentFieldName) > -1;
                        });
                        if (!containsSystemRequiredField) {
                            errors.push(currentSObject + ' (' + Array.from(systemRequiredFieldNames.values()).join(', ') + ')');
                        }
                    }
                });

                return errors.length > 0 ? $A.get('$Label.c.bgeBatchErrorRequiredFields') + ' ' + errors.join(', ') + '.' : '';
            }

            /**
             * @description Updates isActive flag and sort Order of all fields
             * @return void.
             */
            function updateToActive(batchFieldGroups) {
                var fieldCountPreviousObjects = 0;
                var allFieldsBySObject = getAllFieldsBySObject();
                Object.keys(allFieldsBySObject).forEach(function(currentSObject) {
                    batchFieldGroups.forEach(function(currentFieldGroup) {
                        if (currentFieldGroup.sObjectName === currentSObject) {
                            allFieldsBySObject[currentSObject].forEach(function (currentField) {
                                currentField.isActive = currentFieldGroup.values.includes(currentField.id);
                                // the field's sort order is its index PLUS the total of all active fields from all previous object groups
                                currentField.sortOrder = currentField.isActive ? currentFieldGroup.values.indexOf(currentField.id) + fieldCountPreviousObjects : null;
                            });
                            // increase the buffer by the number of active fields from this object
                            fieldCountPreviousObjects += currentFieldGroup.values.length;
                        }
                    });
                });

                this.onFieldsUpdated.notify();
            }

            /**
             * @description Updates the selected fields to Active, unselects fields
             * @return void.
             */
            function updateBatchFieldOptions(batchFieldGroups) {

                var batchFieldOptions = [];
                batchFieldGroups.forEach(function(currentFieldGroup) {
                    currentFieldGroup.fields.forEach(function(currentField) {
                        batchFieldOptions.push(currentField);
                    });
                });

                _allFields.forEach(function(currentField) {
                    batchFieldOptions.forEach(function(currentActiveField) {
                        if (currentField.name === currentActiveField.name) {
                            currentField.required = currentActiveField.required;
                            currentField.hide = currentActiveField.hide;
                            currentField.defaultValue = currentActiveField.defaultValue;
                        }
                    });

                });

            }

            /* ******************PRIVATE FUNCTIONS************************/

            /**
             * @description Gets the system required fields grouped by SObject.
             * @return Map of SObject group to List of system required fields.
             */
            function _getSystemRequiredFieldsBySObject() {
                var systemRequiredFields = [];
                _allFields.forEach(function(currentField) {
                    if (currentField.systemRequired) {
                        systemRequiredFields.push(currentField);
                    }
                });
                return _groupFieldsBySObject(systemRequiredFields);
            }

            /**
             * @description Groups the fields by SObject name.
             * @param fields: list of fields.
             * @return Map of SObject name to List of related fields.
             */
            function _groupFieldsBySObject(fields) {
                var result = {};
                fields.forEach(function(currentField) {
                    if ((currentField.sObjectName in result) === false) {
                        result[currentField.sObjectName] = [];
                    }
                    result[currentField.sObjectName].push(currentField);
                });

                return result;

            }

            /**
             * @description Sort the fields by order.
             * @param fields. List of the fields to sort.
             * @return sorted fields.
             */
            function _sortFieldsByOrder(fields) {
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
            }

            // BatchFieldsModel module public functions and properties
            return {
                errors: {},
                load: load,
                getRequiredFieldErrors: getRequiredFieldErrors,
                getAllFieldsBySObject: getAllFieldsBySObject,
                getAvailablesBySObject: getAvailablesBySObject,
                getActives: getActives,
                getActivesBySObject: getActivesBySObject,
                getDefaultFieldValidity: getDefaultFieldValidity,
                updateToActive: updateToActive,
                updateBatchFieldOptions: updateBatchFieldOptions,
                onFieldsUpdated: _onFieldsUpdated

            }
        })(this.Event());
    },

    /**
     * @description Gets the Model module of the Batch Metadata,
     * such as page mode and labels.
     * @return Model module of the Batch Metadata.
     */
    BatchMetadata : function() {
        return (function (Event) {
            var _onMetadataUpdated = new Event(this);

            /* **********************************************************
             * @Description Loads the Info, and notify all the
             *      _onMetadataUpdated listeners.
             * @return void.
             ************************************************************/
            function load(labels, component) {
                this.labels = labels;
                //isReadOnly (View) is passed from record home with lightning app builder
                if (component.get('v.isReadOnly')) {
                    this.setMode('view');
                } else {
                    if (component.get('v.recordId') !== null) {
                        this.setMode('edit');
                    } else {
                        this.setMode('create');
                    }
                }
                this.setPageHeader();
                this.onMetadataUpdated.notify();
            }

            /**
             * @description Navigates to the record's sObject Home
             * @param recordId - the record we want to view
             */
            function navigateToRecord(recordId) {
                var navEvt = $A.get('e.force:navigateToSObject');
                navEvt.setParams({
                    'recordId': recordId
                });
                navEvt.fire();
            }

            /**
             * @description Increments Wizard to next step
             * @return void.
             */
            function nextStep() {
                this.clearError();
                this.stepUp();
                this.setPageHeader();
            }

            /**
             * @description Decrements Wizard to previous step regardless of errors
             * @return void.
             */
            function backStep() {
                this.clearError();
                this.stepDown();
                this.setPageHeader();
            }

            /**
             * @description From Edit mode, sets back to View mode, otherwise returns user to dynamic Object home
             * @return void.
             */
            function cancel() {
                var homeEvent = $A.get('e.force:navigateToObjectHome');
                var objectName = this.labels.sObjectName;
                homeEvent.setParams({
                    'scope': objectName
                });
                homeEvent.fire();
            }

            /**
             * @description Sets the mode, and notify all the
             *      _onMetadataUpdated listeners. Resets progressIndicator.
             * @param mode - string that is the selected mode
             * @return void.
             */
            function setMode(mode) {
                this.mode = mode;
                this.progressIndicatorStep = '1';
                this.onMetadataUpdated.notify();
            }

            /**
             * @description Shows error message.
             * @param message - String for the error message
             * @return void.
             */
            function showError(message) {
                if (message) {
                    this.hasError = true;
                    this.errorMessage = message;
                    this.onMetadataUpdated.notify();
                }
            }

            /**
             * @description Clears error message
             * @return void.
             */
            function clearError() {
                this.hasError = false;
                this.errorMessage = '';
                this.onMetadataUpdated.notify();
            }

            /**
             * @description sets the page header based on the step in the wizard
             * @return void.
             */
            function setPageHeader() {
                var headers = [
                    this.labels.recordInfoLabel,
                    'Select Template',
                    $A.get('$Label.c.bgeBatchSelectFields'),
                    $A.get('$Label.c.bgeBatchSetFieldOptions'),
                    $A.get('$Label.c.bgeBatchSetBatchOptions')
                ];

                var progressIndicatorStepBase1 = parseInt(this.progressIndicatorStep) - 1;
                this.pageHeader = headers[progressIndicatorStepBase1];
                this.onMetadataUpdated.notify();
            }

            /**
             * @description sets the pendingsave flag to disable Save button so duplicates can't be created
             * @return void.
             */
            function togglePendingSave() {
                this.pendingSave = !this.pendingSave;
                this.onMetadataUpdated.notify();
            }

            /**
             * @description sets the showAdvancedOptions flag to hide/reveal the advanced options accordingly
             * @return void.
             */
            function toggleShowAdvanced() {
                this.showAdvancedOptions = !this.showAdvancedOptions;
                this.onMetadataUpdated.notify();
            }            

            /**
             * @description Increments the step for the progressIndicator
             * @return void.
             */
            function stepUp() {
                var stepNum = parseInt(this.progressIndicatorStep);
                switch (stepNum) {
                    case 1:
                        // TODO: adjust this when we add in step 2
                        stepNum = 3;
                        break;
                    case 2:
                        stepNum = 3;
                        break;
                    case 3:
                        stepNum = 4;
                        break;
                    case 4:
                        stepNum = 5;
                        break;
                    default:
                        stepNum = 1;
                        break;
                }
                this.progressIndicatorStep = stepNum.toString();
                this.onMetadataUpdated.notify();
            }

            /**
             * @description Decrements the step for the progressIndicator
             * @return void.
             */
            function stepDown() {
                var stepNum = parseInt(this.progressIndicatorStep);
                switch (stepNum) {
                    case 2:
                        stepNum = 1;
                        break;
                    case 3:
                        // TODO: adjust this when we add in step 2
                        stepNum = 1;
                        break;
                    case 4:
                        stepNum = 3;
                        break;
                    case 5:
                        stepNum = 4;
                        break;
                    default:
                        stepNum = 1;
                        break;
                }
                this.progressIndicatorStep = stepNum.toString();
                this.onMetadataUpdated.notify();
            }

            // BatchMetadata module public functions and properties
            return {
                labels: {},
                mode: '',
                progressIndicatorStep: '',
                hasError: false,
                errorMessage: '',
                pageHeader: '',
                pendingSave: false,
                showAdvancedOptions: false,
                load: load,
                navigateToRecord: navigateToRecord,
                nextStep: nextStep,
                backStep: backStep,
                cancel: cancel,
                setMode: setMode,
                showError: showError,
                clearError: clearError,
                setPageHeader: setPageHeader,
                stepUp: stepUp,
                stepDown: stepDown,
                togglePendingSave: togglePendingSave,
                onMetadataUpdated: _onMetadataUpdated,
                toggleShowAdvanced: toggleShowAdvanced
            }
        })(this.Event());
    },

    /**
     * @description. Publisher/Subscribers used by the Model modules
     *      to notify the View modules on a specific change.
     * @return Event
     */
    Event: function () {
        return function(sender) {
            var _sender = sender;
            var _listeners = [];

            /**
             * @description Subscribes the listener to the current Event.
             * @param listener. The event listener.
             * @return void.
             */
            function subscribe(listener) {
                _listeners.push(listener);
            }

            /**
             * @description Notifies the listeners of the current Event.
             * @param args. The parameters to provide to the listeners.
             * @return void.
             */
            function notify(args) {
                var index;
                for (index = 0; index < _listeners.length; index += 1) {
                    _listeners[index](_sender, args);
                }
            }

            // Event module public functions.
            return {
                subscribe: subscribe,
                notify: notify
            };
        };
    },

    /*********************************************** Batch Detail Controller *********************************************/

    /**
     * @description Gets Batch Details Controller
     * @return Batch Details Controller.
     */
    BGEBatchController : function(component) {
        return (function (component) {
            var _component = component;

            /**
             * @description Calls the getRecordDetails method.
             * @param recordId. The Id of the Batch.
             * @param callback. The callback function to execute.
             * @return void.
             */
            function getRecordDetails(recordId, callback) {
                var action = _component.get('c.getRecordDetails');
                action.setParams({
                    'recordId': recordId
                });
                action.setCallback(callback, _processResponse);
                $A.enqueueAction(action);
            }

            /**
             * @description Calls the saveRecord method.
             * @param batchDetails. The Batch fields.
             * @param activeFields. The active fields (JSON format)
             * @param callback. The callback function to execute.
             * @return void.
             */
            function saveRecord(recordDetails, activeFields, callback) {
                var action = _component.get('c.saveRecord');
                action.setParams({
                    'recordInfo': JSON.stringify(recordDetails),
                    'activeFields': JSON.stringify(activeFields)
                });
                action.setCallback(callback, _processResponse);
                $A.enqueueAction(action);
            }

            /**
             * @description Processes the response from any Apex method.
             * @param response. The response from the backend.
             * @return void.
             */
            function _processResponse(response) {
                var state = response.getState();
                if (state === 'SUCCESS') {
                    this.success(JSON.parse(response.getReturnValue()));
                }
                else if (state === 'ERROR') {
                    var errors = response.getError();
                    if (errors && errors[0] && errors[0].message) {
                        errors = errors[0].message;
                    } else {
                        errors = 'Unknown error';
                    }
                    this.error(errors);
                }
            }

            // BGEBatchController module public functions.
            return {
                errors: '',
                getRecordDetails: getRecordDetails,
                saveRecord: saveRecord
            }
        })(component);
    },
})