({
    /********************************************* View Modules *********************************************/
    
    /* ***************************************************************
     * @Description Returns the Template Info View module.
     * @param component. Lightning Component reference.
     * @param model. The Model.
     * @return View of the Template Info module.
     *****************************************************************/
    TemplateInfoView : function(component, model) {
        return (function (component, model) {

            // Subscribe to the model onInfoUpdated event.
            model.getTemplateInfo().onInfoUpdated.subscribe(function() {
                var templateInfoView = component.get('v.templateInfo');
                var templateInfo = model.getTemplateInfo();
                templateInfoView.name = templateInfo.name;
                templateInfoView.id = templateInfo.id;
                templateInfoView.description = templateInfo.description;
                templateInfoView.enableTotalEntry = templateInfo.enableTotalEntry;
                templateInfoView.requireTotalMatch = templateInfo.requireTotalMatch;

                component.set('v.templateInfo', templateInfoView);
            });

            // Subscribe to the model onFieldsUpdated event.
            model.getTemplateFields().onFieldsUpdated.subscribe(function() {
                var templateInfoView = component.get('v.templateInfo');

                Object.keys(model.getTemplateFields().getAvailablesBySObject()).forEach(function(sObjectName) {

                    var objLabel = sObjectName.slice(-1) == '1' || sObjectName.slice(-1) == '2' ?  sObjectName.slice(0,-1) + ' ' + sObjectName.slice(-1) : sObjectName;

                    templateInfoView.availableSObjects.push(
                        {
                            label: objLabel,
                            value: sObjectName
                        }
                    );
                });

                component.set('v.templateInfo', templateInfoView);
            });

            // TemplateInfoView module public functions and properties
            return {
                name: '',
                id: '',
                description: '',
                enableTotalEntry: false,
                requireTotalMatch: false,
                availableSObjects: []
            };
        })(component, model);
    },

    /* ***************************************************************
     * @Description Returns the Template Metadata View module.
     * @param component. Lightning Component reference.
     * @param model. The Model.
     * @return View of the Template Metadata module.
     *****************************************************************/
    TemplateMetadataView : function(component, model) {
        return (function (component, model) {

            // Subscribe to the model onMetadataUpdated event.
            model.getTemplateMetadata().onMetadataUpdated.subscribe(function() {
                var templateMetadataView = component.get('v.templateMetadata');
                var templateMetadata = model.getTemplateMetadata();
                templateMetadataView.labels = templateMetadata.labels;
                templateMetadataView.mode = templateMetadata.mode;
                templateMetadataView.hasError = templateMetadata.hasError;
                templateMetadataView.errorMessage = templateMetadata.errorMessage;

                if (!templateMetadataView.hasError) {
                    templateMetadataView.progressIndicatorStep = templateMetadata.progressIndicatorStep;
                } else {
                    component.find('notifLib').showNotice({
                        "variant": "error",
                        "header": $A.get("$Label.c.PageMessagesError"),
                        "message": templateMetadataView.errorMessage,
                        closeCallback: function() {
                            //callback action here
                        }
                    });
                }

                if (templateMetadataView.mode === 'view') {
                    component.set("v.isReadOnly", true);
                } else if (templateMetadataView.mode === 'create' || templateMetadataView.mode === 'edit') {
                    component.set("v.isReadOnly", false);
                    if (templateMetadata.mode === 'edit') {
                        templateMetadata.labels.batchTemplateHeader = $A.get("$Label.c.bgeBatchTemplateEdit")
                    } else if (templateMetadata.mode === 'create') {
                        templateMetadata.labels.batchTemplateHeader = $A.get("$Label.c.bgeBatchTemplateNew");
                    }
                }

                component.set('v.templateMetadata', templateMetadataView);
            });

            // TemplateMetadataView module public functions and properties
            return {
                labels: {},
                mode: '',
                progressIndicatorStep: '',
                hasError: false,
                errorMessage: ''
            };
        })(component, model);
    },

    /* ***************************************************************
     * @Description Returns the Template Fields View module.
     * @param component. Lightning Component reference.
     * @param model. The Template Fields Model.
     * @return View of the Template Fields module.
     *****************************************************************/
    TemplateFieldsView : function(component, model) {
		return (function (component, model) {

            // Subscribe to the model onFieldsUpdated event. 
            model.getTemplateFields().onFieldsUpdated.subscribe(function() {
                var templateFields = component.get('v.templateFields');
                templateFields.fieldGroups = [];

                var activeFieldsBySObject = model.getTemplateFields().getActivesBySObject();
                var allFieldsBySObject = model.getTemplateFields().getAllFieldsBySObject();

                Object.keys(allFieldsBySObject).forEach(function(sObjectName) {
                    var currentFieldGroup = {
                        sObjectName : sObjectName,
                        options: [],
                        values: []
                    };

                    allFieldsBySObject[sObjectName].forEach(function(currentField) {
                        currentFieldGroup.options.push(
                            {
                                label: currentField.label,
                                value: currentField.id
                            }
                        );
                    });
                    if (activeFieldsBySObject[sObjectName]) {
                        activeFieldsBySObject[sObjectName].forEach(function(currentField) {
                            currentFieldGroup.values.push(currentField.id);
                        });
                    }
                    templateFields.fieldGroups.push(currentFieldGroup);
                });

                component.set('v.templateFields', templateFields);
            });
            
            // TemplateFieldsView module public functions and properties
			return {
                fieldGroups: []
            };
        })(component, model);
	},

    
    /*********************************************** Model Modules *********************************************/

    /* **********************************************************
     * @Description Gets the Model module of Template Details.
     * This is the main and only Model module for the Template 
     * Details components. Contains references to TemplateFields
     * and TemplateInfo sub-modules.
     * @return Model module of Template Details.
     ************************************************************/
    TemplateDetailsModel : function() {
        var templateFields = this.TemplateFields();
        var templateInfo = this.TemplateInfo();
        var templateMetadata = this.TemplateMetadata();

        return (function (templateFields, templateInfo, templateMetadata) {
            var _templateFields = templateFields;
            var _templateInfo = templateInfo;
            var _templateMetadata = templateMetadata;
            var _bgeTemplateController;
            
            /* **********************************************************
             * @Description Gets the Template Details and loads sub-modules.
             * @param component. Lightning Component reference.
             * @return void.
             ************************************************************/
            function init(component) {
                _bgeTemplateController.getTemplateDetails({
                    success: function(response) {
                        _templateInfo.load(
                            {
                                name: response.name,
                                id: response.id,
                                description: response.description,
                                enableTotalEntry: response.enableTotalEntry,
                                requireTotalMatch: response.requireTotalMatch
                            }
                        );

                        _templateFields.load(response.templateFields, JSON.parse(response.activeFields));
                        _templateMetadata.load(response.labels, component);
                    },
                    error: function(error) {
                        console.log(error);
                    }
                });
            }

            /* **********************************************************
             * @Description Saves the model information to the backend.
             * @return void.
             ************************************************************/
            function save() {
                var templateDetailsData = {
                    name: _templateInfo.name,
                    id: _templateInfo.id,
                    description: _templateInfo.description,
                    enableTotalEntry: _templateInfo.enableTotalEntry,
                    requireTotalMatch: _templateInfo.requireTotalMatch
                };
                var activeFields = [];

                _templateFields.getActives().forEach(function(currentField) {
                    activeFields.push({
                        label: currentField.label,
                        name: currentField.name,
                        sObjectName: currentField.sObjectName,
                        defaultValue: currentField.defaultValue,
                        required: currentField.required,
                        hide: currentField.hide,
                        activeSortOrder: currentField.activeSortOrder
                    });
                });

                _bgeTemplateController.saveTemplateDetails(templateDetailsData, activeFields, {
                    success: function(response) {
                        _templateMetadata.setMode('view');
                        _templateInfo.load(
                            {
                                name: response.name,
                                id: response.id,
                                description: response.description,
                                enableTotalEntry: response.enableTotalEntry,
                                requireTotalMatch: response.requireTotalMatch
                            }
                        );
                    },
                    error: function(error) {
                        console.log(error);
                    }
                });
            }

            /* **********************************************************
             * @Description Sets the Apex backend controller module.
             * @return void.
             ************************************************************/
            function setBackendController(bgeTemplateController) {
                _bgeTemplateController = bgeTemplateController
            }

            /* **********************************************************
             * @Description Gets the Template Fields module.
             * @return Template Fields module.
             ************************************************************/
            function getTemplateFields() {
                return _templateFields;
            }

            /* **********************************************************
             * @Description Gets the Template Info module.
             * @return Template Info module.
             ************************************************************/
            function getTemplateInfo() {
                return _templateInfo;
            }

            /* **********************************************************
             * @Description Gets the Template Metadata module.
             * @return Template Metadata module.
             ************************************************************/
            function getTemplateMetadata() {
                return _templateMetadata;
            }

            // TemplateDetailsModel module public functions and properties
            return {
                init: init,
                save: save,
                setBackendController: setBackendController,
                getTemplateFields: getTemplateFields,
                getTemplateInfo: getTemplateInfo,
                getTemplateMetadata: getTemplateMetadata
            }
        })(templateFields, templateInfo, templateMetadata);
    },

    /* **********************************************************
     * @Description Gets the Model module of the Template Info.
     * @return Model module of the Template Info.
     ************************************************************/
    TemplateInfo : function() {
        var Event = this.Event();

        return (function (Event) {
            var _onInfoUpdated = new Event(this);
            
            /* **********************************************************
             * @Description Loads the Info, and notify all the 
             * _onInfoUpdated listeners.
             * @return List of fields.
             ************************************************************/
            function load(info) {
                this.name = info.name;
                this.description = info.description;
                this.id = info.id;
                this.enableTotalEntry = info.enableTotalEntry;
                this.requireTotalMatch = info.requireTotalMatch;
                this.onInfoUpdated.notify();
            }

            /* **********************************************************
             * @Description Validates the required templateInfo.
             * @return Boolean validity.
             ************************************************************/
            function isValid() {
                return this.name && this.description
            }
            
            // TemplateInfo module public functions and properties
            return {
                name: '',
                id: '',
                description: '',
                enableTotalEntry: false,
                requireTotalMatch: false,
                load: load,
                isValid: isValid,
                onInfoUpdated: _onInfoUpdated
            }
        })(Event);
    },

    /* **********************************************************
     * @Description Gets the Template Fields module.
     * @return Model module of the Template Fields.
     ************************************************************/
    TemplateFields : function() {
  		var Event = this.Event();
        
		return (function (Event) {
            var _allFields = [];
            var _allSObjects = []
            var _onFieldsUpdated = new Event(this);

            /* ******************PUBLIC FUNCTIONS*************************/

            /* **********************************************************
             * @Description Load the fields and notify onFieldsUpdated listeners.
             * @param allFields: list of allFields with sObjectName/Name.
             * param activeFields: Map of activeFieldsBySObject with sObjectName, Name,
             * todo: and Default Value, Hide and Required flags.
             * @return void.
             ************************************************************/
            function load(allFields, activeFields) {
                _allFields = [];
                var activeFieldMap = new Map();

                if (activeFields) {
                    activeFields.forEach(function(activeField) {
                        var fieldId = activeField.sObjectName + "." + activeField.name;
                        activeFieldMap.set(fieldId, activeField.activeSortOrder);
                    });
                }

                var availableSortOrder = 1;
                allFields.forEach(function(currentField) {
                    currentField.id = currentField.sObjectName + "." + currentField.name;
                    //set Active fields with saved sort order
                    if (activeFieldMap.has(currentField.id)) {
                        currentField.isActive = true;
                        currentField.activeSortOrder = activeFieldMap.get(currentField.id);
                    } else {
                        currentField.isActive = false;
                    }
                    currentField.availableSortOrder = availableSortOrder;
                    availableSortOrder++;
                    _allFields.push(currentField);
                });
                this.onFieldsUpdated.notify();
            }

            /* **********************************************************
            * @Description Gets all fields grouped by SObject.
            * @return Map of SObject group to List of all fields.
            ************************************************************/
            function getAllFieldsBySObject() {
                return _groupFieldsBySObject(_allFields);
            }

            /* **********************************************************
             * @Description Gets the available fields grouped by SObject.
             * @return Map of SObject group to List of inactive fields.
             ************************************************************/
            function getAvailablesBySObject() {
                var _availableFields = [];
                _allFields.forEach(function(currentField) {
                    if (!currentField.isActive) {
                        _availableFields.push(currentField);
                    }
                });
                return _groupFieldsBySObject(_availableFields);
            }

            /* **********************************************************
             * @Description Gets the active fields.
             * @return List of related active fields.
             ************************************************************/
            function getActives() {
                var _activeFields = [];
                _allFields.forEach(function(currentField) {
                    if (currentField.isActive) {
                        _activeFields.push(currentField);
                    }
                });
                return _sortFieldsByOrder(_activeFields);
            }

            /* **********************************************************
             * @Description Gets the active fields grouped by SObject.
             * @return Map of SObject group to List of related active fields.
             ************************************************************/
            function getActivesBySObject() {
                var _activeFields = [];
                _allFields.forEach(function(currentField) {
                    if (currentField.isActive) {
                        _activeFields.push(currentField);
                    }
                });
                _activeFields = _sortFieldsByOrder(_activeFields);
                return _groupFieldsBySObject(_activeFields);
            }


            /* *******************************************************************
             * @Description Updates the selected fields to Active, unselects fields
             * @return void.
             **********************************************************************/
            function updateToActive(templateFieldGroups) {
                _allFields.forEach(function(currentField) {
                    templateFieldGroups.forEach(function(currentFieldGroup) {
                        if (currentFieldGroup.sObjectName === currentField.sObjectName) {
                            currentField.isActive = currentFieldGroup.values.includes(currentField.id);
                            currentField.activeSortOrder = currentField.isActive ? currentFieldGroup.values.indexOf(currentField.id) : 0;
                        }
                    });
                            
                });
            }

            /* ******************PRIVATE FUNCTIONS************************/

            /* **********************************************************
             * @Description Groups the fields by SObject name.
             * @param fields: list of fields.
             * @return Map of SObject name to List of related fields.
             ************************************************************/
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

            /***********************************************************
             * @Description Sort the fields by order.
             * @param fields. List of the fields to sort.
             * @return sorted fields.
             ************************************************************/
            function _sortFieldsByOrder(fields) {
                fields.sort(function(currentField, nextField) {
                    if (currentField.activeSortOrder < nextField.activeSortOrder) {
                        return -1;
                    }
                    if (currentField.activeSortOrder > nextField.activeSortOrder) {
                        return 1;
                    }
                    // numbers must be equal
                    return 0;
                });
                return fields;
            }

            // TemplateFieldsModel module public functions and properties
            return {
                load: load,
                getAllFieldsBySObject: getAllFieldsBySObject,
                getAvailablesBySObject: getAvailablesBySObject,
                getActives: getActives,
                getActivesBySObject: getActivesBySObject,
                updateToActive: updateToActive,
                onFieldsUpdated: _onFieldsUpdated

            }
        })(Event);
	},

    /* **********************************************************
     * @Description Gets the Model module of the Template Metadata, 
     * such as page mode and labels.
     * @return Model module of the Template Metadata.
     ************************************************************/
    TemplateMetadata : function() {
        var Event = this.Event();

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
                if (component.get("v.isReadOnly")) {
                    this.mode = 'view';
                } else {
                    if (component.get("v.recordId") !== null) {
                        this.mode = 'edit';
                    } else {
                        this.mode = 'create';
                    }
                }
                this.progressIndicatorStep = '1';
                this.onMetadataUpdated.notify();
            }

            /* **********************************************************
             * @Description sets the mode, and notify all the
             *      _onMetadataUpdated listeners.
             * @param mode - string that is the selected mode
             * @return void.
             ************************************************************/
            function setMode(mode) {
                this.mode = mode;
                this.onMetadataUpdated.notify();
            }

            /* **********************************************************
             * @Description sets error state and message
             * @param hasError - Boolean indicating error state.
             * @param message - String for the error message
             * @return void.
             ************************************************************/
            function setError(hasError, message) {
                this.hasError = hasError;
                this.errorMessage = message;
                this.onMetadataUpdated.notify();
            }

            /* **********************************************************
             * @Description increments the step for the progressIndicator
             * @param step - number of the current step
             * @return void.
             ************************************************************/
            function stepUp(step) {
                this.setError(false, '');
                var stepNum = parseInt(step);
                stepNum = stepNum + 1;
                this.progressIndicatorStep = stepNum.toString();
                this.onMetadataUpdated.notify();
            }

            /* **********************************************************
             * @Description decrements the step for the progressIndicator
             * @param step - number of the current step
             * @return void.
             ************************************************************/
            function stepDown(step) {
                var stepNum = parseInt(step);
                stepNum = stepNum - 1;
                this.progressIndicatorStep = stepNum.toString();
                this.onMetadataUpdated.notify();
            }

            // TemplateInfo module public functions and properties
            return {
                labels: {},
                mode: '',
                progressIndicatorStep: '',
                hasError: false,
                errorMessage: '',
                load: load,
                setMode: setMode,
                setError: setError,
                stepUp: stepUp,
                stepDown: stepDown,
                onMetadataUpdated: _onMetadataUpdated
            }
        })(Event);
    },

    /* **********************************************************
     * @Description. Publisher/Subscribers used by the Model modules
     *      to notify the View modules on a specific change.
     * @return Event
     ************************************************************/
    Event: function () {
        return function(sender) {
            var _sender = sender;
            var _listeners = [];
            
            /* **********************************************************
             * @Description subscribes the listener to the current Event.
             * @param listener. The event listener.
             * @return void.
             ************************************************************/
            function subscribe(listener) {
                _listeners.push(listener);
            }
            
            /* **********************************************************
             * @Description Notifies the listeners of the current Event.
             * @param args. The parameters to provide to the listeners.
             * @return void.
             ************************************************************/
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

    /* **********************************************************
     * @Description Gets Template Details Controller
     * @return Template Details Controller.
     ************************************************************/
    BGETemplateController : function(component) {
        return (function (component) {
            var _component = component;

            /* **********************************************************
             * @Description Calls the getTemplateDetails method.
             * @return void.
             ************************************************************/
            function getTemplateDetails(callback) {
                var action = _component.get("c.getTemplateDetails");
                action.setParams({
                    templateId: component.get("v.recordId")
                });
                action.setCallback(callback, _processResponse);
                $A.enqueueAction(action);
            }

            /* **********************************************************
             * @Description Calls the saveTemplateDetails method.
             * @return void.
             ************************************************************/
            function saveTemplateDetails(templateDetails, activeFields, callback) {
                var action = _component.get("c.saveTemplate");
                action.setParams({
                    "templateInfo": JSON.stringify(templateDetails),
                    "activeFields": JSON.stringify(activeFields)
                });
                action.setCallback(callback, _processResponse);
                $A.enqueueAction(action);
            }

            /* **********************************************************
             * @Description Processes the response from any Apex method.
             * @return void.
             ************************************************************/
            function _processResponse(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    this.success(JSON.parse(response.getReturnValue()));
                }
                else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            this.error(errors[0].message);
                        }
                    } else {
                        this.error("Unknown error");
                    }
                }
            }
            
            // BGETemplateController module public functions.
            return {
                getTemplateDetails: getTemplateDetails,
                saveTemplateDetails: saveTemplateDetails
            }
        })(component);
    },
})