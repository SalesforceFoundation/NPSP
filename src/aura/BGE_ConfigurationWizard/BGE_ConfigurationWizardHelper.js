({
    /********************************************* View Modules *********************************************/

    /**
     * @description Returns the Template Info View module.
     * @param component. Lightning Component reference.
     * @param model. The Model.
     * @return View of the Template Info module.
     */
    TemplateInfoView : function(component, model) {
        return (function (component, model) {

            // Subscribe to the model onInfoUpdated event.
            model.getBatchInfo().onInfoUpdated.subscribe(function() {
                var templateInfoView = component.get('v.batchInfo');
                var batchInfo = model.getBatchInfo();

                // record info
                templateInfoView.name = batchInfo.name;
                templateInfoView.id = batchInfo.id;
                templateInfoView.description = batchInfo.description;
                templateInfoView.expectedCount = batchInfo.expectedCount;
                templateInfoView.expectedTotal = batchInfo.expectedTotal;
                templateInfoView.recordCount = batchInfo.recordCount;

                // batch processing settings
                templateInfoView.requireTotalMatch = batchInfo.requireTotalMatch;
                templateInfoView.batchProcessSize = batchInfo.batchProcessSize;
                templateInfoView.runOpportunityRollupsWhileProcessing = batchInfo.runOpportunityRollupsWhileProcessing;
                templateInfoView.donationMatchingBehavior = batchInfo.donationMatchingBehavior;
                templateInfoView.donationMatchingClass = batchInfo.donationMatchingClass;
                templateInfoView.donationMatchingOptions = batchInfo.donationMatchingOptions;
                templateInfoView.donationMatchingRule = batchInfo.donationMatchingRule;
                templateInfoView.donationDateRange = batchInfo.donationDateRange;
                templateInfoView.postProcessClass = batchInfo.postProcessClass;
                templateInfoView.processUsingScheduledJob = batchInfo.processUsingScheduledJob;

                component.set('v.batchInfo', templateInfoView);
            });

            // TemplateInfoView module public functions and properties
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
                postProcessClass: '',
                processUsingScheduledJob: false
            };
        })(component, model);
    },

    /**
     * @description Returns the Template Metadata View module.
     * @param component. Lightning Component reference.
     * @param model. The Model.
     * @return View of the Template Metadata module.
     */
    TemplateMetadataView : function(component, model) {
        return (function (component, model) {

            // Subscribe to the model onMetadataUpdated event.
            model.getTemplateMetadata().onMetadataUpdated.subscribe(function() {
                var templateMetadataView = component.get('v.templateMetadata');
                var templateMetadata = model.getTemplateMetadata();
                var headerChanged = Boolean(templateMetadataView.pageHeader !== templateMetadata.pageHeader);

                templateMetadataView.labels = templateMetadata.labels;
                templateMetadataView.mode = templateMetadata.mode;
                templateMetadataView.hasError = templateMetadata.hasError;
                templateMetadataView.errorMessage = templateMetadata.errorMessage;
                templateMetadataView.pageHeader = templateMetadata.pageHeader;
                templateMetadataView.pendingSave = templateMetadata.pendingSave;

                if (!templateMetadataView.hasError) {
                    templateMetadataView.progressIndicatorStep = templateMetadata.progressIndicatorStep;
                    _sendMessage('setStep',templateMetadata.progressIndicatorStep);
                } else {
                    component.find('notifLib').showNotice({
                        'variant': 'error',
                        'header': $A.get('$Label.c.PageMessagesError'),
                        'message': templateMetadataView.errorMessage,
                        closeCallback: function() {
                            //callback action here
                        }
                    });
                }

                if (templateMetadataView.mode === 'view') {
                    component.set('v.isReadOnly', true);
                } else if (templateMetadataView.mode === 'create' || templateMetadataView.mode === 'edit') {
                    component.set('v.isReadOnly', false);
                    if (templateMetadata.mode === 'edit') {
                        templateMetadata.labels.batchTemplateHeader = $A.get('$Label.c.bgeBatchTemplateEdit')
                    } else if (templateMetadata.mode === 'create') {
                        templateMetadata.labels.batchTemplateHeader = $A.get('$Label.c.bgeBatchTemplateNew');
                    }
                }

                //update page header in modal if page header has changed and modal is used
                if (headerChanged) {
                    _sendMessage('setHeader', templateMetadataView.pageHeader);
                }

                //update footer in modal to keep save button appropriately enabled/disabled
                _sendMessage('pendingSave', templateMetadataView.pendingSave);

                // when in modal context, need to notify the modal footer component
                _sendMessage('setError', templateMetadataView.hasError);

                component.set('v.templateMetadata', templateMetadataView);
            });

            function _sendMessage(channel, message) {
                var sendMessage = $A.get('e.ltng:sendMessage');
                sendMessage.setParams({
                    'channel': channel,
                    'message': message
                });
                sendMessage.fire();
            }

            // TemplateMetadataView module public functions and properties
            return {
                labels: {},
                mode: '',
                progressIndicatorStep: '',
                hasError: false,
                errorMessage: '',
                pendingSave: false
            };
        })(component, model);
    },

    /**
     * @description Returns the Template Fields View module.
     * @param component. Lightning Component reference.
     * @param model. The Template Fields Model.
     * @return View of the Template Fields module.
     */
    TemplateFieldsView : function(component, model) {
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

            // TemplateFieldsView module public functions and properties
            return {
                fieldGroups: []
            };
        })(component, model);
    },

    /**
     * @description Returns the Template Field Options View module.
     * @param component. Lightning Component reference.
     * @param model. The Template Fields Model.
     * @return View of the Template Field Options module.
     */
    TemplateFieldOptionsView : function(component, model) {
        return (function (component, model) {

            // Subscribe to the model onFieldsUpdated event.
            model.getAvailableFields().onFieldsUpdated.subscribe(function() {
                var templateFieldOptions = component.get('v.templateFieldOptions');
                templateFieldOptions.fieldGroups = [];
                var activeFieldsBySObject = model.getAvailableFields().getActivesBySObject();
                var availableFields = model.getAvailableFields();
                templateFieldOptions.errors = availableFields.errors;

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

                    templateFieldOptions.fieldGroups.push(currentFieldGroup);

                });
                component.set('v.templateFieldOptions', templateFieldOptions);

            });

            // TemplateFieldOptionsView module public functions and properties
            return {
                fieldGroups: []
            };

        })(component, model);
    },


    /*********************************************** Model Modules *********************************************/

    /**
     * @description Gets the Model module of Template Details.
     * This is the main and only Model module for the Template
     * Details components. Contains references to TemplateFields
     * and TemplateInfo sub-modules.
     * @return Model module of Template Details.
     */
    TemplateDetailsModel : function() {
        return (function (availableFields, batchInfo, templateMetadata) {
            var _availableFields = availableFields;
            var _batchInfo = batchInfo;
            var _templateMetadata = templateMetadata;
            var _bgeTemplateController;

            /* **********************************************************
             * @Description Gets the Template Details and loads sub-modules.
             * @param component. Lightning Component reference.
             * @return void.
             ************************************************************/
            function init(component) {
                var recordId = _batchInfo.id ? _batchInfo.id : component.get('v.recordId');
                _bgeTemplateController.getRecordDetails(recordId, {
                    success: function(response) {
                        _batchInfo.load(response);
                        _availableFields.load(response.availableFields, JSON.parse(response.activeFields));
                        _templateMetadata.load(response.labels, component);
                    },
                    error: function(error) {
                        console.log(error);
                    }
                });
            }

            /**
             * @description Saves the model information to the backend.
             * @return void.
             */
            function save() {
                var templateDetailsData = {
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

                _bgeTemplateController.saveRecord(templateDetailsData, activeFields, {
                    success: function(response) {
                        _templateMetadata.navigateToRecord(response.id);
                    },
                    error: function(error) {
                        console.log(error);
                        _templateMetadata.togglePendingSave();
                    }
                });
            }

            /**
             * @description Sets the Apex backend controller module.
             * @return void.
             */
            function setBackendController(bgeTemplateController) {
                _bgeTemplateController = bgeTemplateController
            }

            /**
             * @description Gets the Template Fields module.
             * @return Template Fields module.
             */
            function getAvailableFields() {
                return _availableFields;
            }

            /**
             * @description Gets the Template Info module.
             * @return Template Info module.
             */
            function getBatchInfo() {
                return _batchInfo;
            }

            /**
             * @description Gets the Template Metadata module.
             * @return Template Metadata module.
             */
            function getTemplateMetadata() {
                return _templateMetadata;
            }

            // TemplateDetailsModel module public functions and properties
            return {
                init: init,
                save: save,
                setBackendController: setBackendController,
                getAvailableFields: getAvailableFields,
                getBatchInfo: getBatchInfo,
                getTemplateMetadata: getTemplateMetadata
            }
        })(this.TemplateFields(), this.BatchInfo(), this.TemplateMetadata());
    },

    /**
     * @description Gets the Model module of the Template Info.
     * @return Model module of the Template Info.
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
                onInfoUpdated: _onInfoUpdated
            }
        })(this.Event());
    },

    /**
     * @description Gets the Template Fields module.
     * @return Model module of the Template Fields.
     */
    TemplateFields : function() {
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

                return errors.length > 0 ? $A.get('$Label.c.bgeBatchTemplateErrorRequiredFields') + ' ' + errors.join(', ') + '.' : '';
            }

            /**
             * @description Updates isActive flag and sort Order of all fields
             * @return void.
             */
            function updateToActive(templateFieldGroups) {
                var fieldCountPreviousObjects = 0;
                var allFieldsBySObject = getAllFieldsBySObject();
                Object.keys(allFieldsBySObject).forEach(function(currentSObject) {
                    templateFieldGroups.forEach(function(currentFieldGroup) {
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
            function updateTemplateFieldOptions(templateFieldGroups) {

                var templateFieldOptions = [];
                templateFieldGroups.forEach(function(currentFieldGroup) {
                    currentFieldGroup.fields.forEach(function(currentField) {
                        templateFieldOptions.push(currentField);
                    });
                });

                _allFields.forEach(function(currentField) {
                    templateFieldOptions.forEach(function(currentActiveField) {
                        if (currentField.name === currentActiveField.name) {
                            currentField.required = currentActiveField.required;
                            currentField.hide = currentActiveField.hide;
                            currentField.defaultValue = currentActiveField.defaultValue;
                        }
                    });

                    /* todo: put this back when we decide to use hidden attribute
                    // will need to figure out where/how to display errors
                    // this error/allvalid handling is remnant from datatable display
                    if (currentField.hide && !currentField.defaultValue) {

                        allValid = false;
                        var fieldName = currentField.name;
                        var fieldNameGroup = {
                            title: $A.get('$Label.c.PageMessagesError'),
                            messages: [$A.get('$Label.c.bgeBatchTemplateErrorDefaultValue')],
                            fieldNames: ['defaultValue']
                        };
                        errors.rows[fieldName] = fieldNameGroup;
                        errors.size += 1;
                    }*/

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

            // TemplateFieldsModel module public functions and properties
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
                updateTemplateFieldOptions: updateTemplateFieldOptions,
                onFieldsUpdated: _onFieldsUpdated

            }
        })(this.Event());
    },

    /**
     * @description Gets the Model module of the Template Metadata,
     * such as page mode and labels.
     * @return Model module of the Template Metadata.
     */
    TemplateMetadata : function() {
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
                if (this.mode === 'edit' && this.labels.sObjectNameNoNamespace === 'Batch_Template__c') {
                    this.clearError();
                    this.setMode('view');
                } else {
                    //navigate to record home
                    var homeEvent = $A.get('e.force:navigateToObjectHome');
                    var objectName = this.labels.sObjectName;
                    homeEvent.setParams({
                        'scope': objectName
                    });
                    homeEvent.fire();
                }
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
                    $A.get('$Label.c.bgeBatchTemplateSelectFields'),
                    $A.get('$Label.c.bgeBatchTemplateSetFieldOptions'),
                    $A.get('$Label.c.bgeBatchTemplateSetBatchOptions')
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

            // TemplateMetadata module public functions and properties
            return {
                labels: {},
                mode: '',
                progressIndicatorStep: '',
                hasError: false,
                errorMessage: '',
                pageHeader: '',
                pendingSave: false,
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
                onMetadataUpdated: _onMetadataUpdated
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

    /*********************************************** Template Detail Controller *********************************************/

    /**
     * @description Gets Template Details Controller
     * @return Template Details Controller.
     */
    BGETemplateController : function(component) {
        return (function (component) {
            var _component = component;

            /**
             * @description Calls the getRecordDetails method.
             * @param recordId. The Id of the Template.
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
             * @param templateDetails. The Template fields.
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

            // BGETemplateController module public functions.
            return {
                errors: '',
                getRecordDetails: getRecordDetails,
                saveRecord: saveRecord
            }
        })(component);
    },
})