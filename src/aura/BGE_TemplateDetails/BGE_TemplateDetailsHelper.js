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
                templateInfoView.description = templateInfo.description;
                templateInfoView.displayTotalPrompt = templateInfo.displayTotalPrompt;
                templateInfoView.requireTotalMatch = templateInfo.requireTotalMatch;

                component.set('v.templateInfo', templateInfoView);
            });
            
            //  module public functions and properties
            return {
                name: '', 
                description: '',
                displayTotalPrompt: false,
                requireTotalMatch: false
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

                component.set('v.templateMetadata', templateMetadataView);
            });

            //  module public functions and properties
            return {
                labels: {},
                mode: ''
            };
        })(component, model);
    },

    /* ***************************************************************
     * @Description Returns the Available Template Fields View module.
     * @param component. Lightning Component reference.
     * @param model. The Template Fields Model.
     * @return View of the Available Template Fields module.
     *****************************************************************/
    AvailableTemplateFieldsView : function(component, model) {
		return (function (component, model) {
            var _columns = [
                {
                	type: 'text',
                	fieldName: 'name',
                	label: $A.get("$Label.c.bgeBatchTemplateAvailableFields")
            	}
            ];

            // Subscribe to the model onFieldsUpdated event. 
            model.getTemplateFields().onFieldsUpdated.subscribe(function() {
                var availableTemplateFields = component.get('v.availableTemplateFields');
                availableTemplateFields.data = _convertToGridData(model.getTemplateFields().getAvailablesBySObject());
                availableTemplateFields.selectedRows = [];

                availableTemplateFields.data.forEach(function(fieldGroup) {
                    if (fieldGroup.selected) {
                        availableTemplateFields.selectedRows.push(fieldGroup.id);
                    }
                    if (fieldGroup._children) {
                        fieldGroup._children.forEach(function(currentField) {
                            if (currentField.selected) {
                                availableTemplateFields.selectedRows.push(currentField.id);
                            }
                        });
                    }  
                });

                component.set('v.availableTemplateFields', availableTemplateFields);
            });
            
            /* *******************************************************************
             * @Description Converts the Available Fields list to the availableTemplateFields
             * Lightning:treeGrid data format.
             * @return availableTemplateFields Lightning:treeGrid data format.
             *********************************************************************/
            function _convertToGridData(fieldsBySObject) {
                var result = [];
                
                Object.keys(fieldsBySObject).sort().forEach(function(sObjectName) {
                    var gridDataRow = {
                        id: sObjectName,
                        name: sObjectName,
                        selected: false,
                        _children: []
                    };

                    fieldsBySObject[sObjectName].forEach(function(sObjectField) {
                        gridDataRow._children.push(
                            {
                                id: sObjectField.id,
                            	name: sObjectField.name,
                                selected: sObjectField.selected,
                                availableSortOrder: sObjectField.availableSortOrder
                            }
                        );
                    });

                    result.push(gridDataRow);
                });
                
                return result;
            }
            
            // AvailableTemplateFieldsView module public functions and properties
			return {
                columns: _columns,
                data: [],
                selectedRows: []
            };
        })(component, model);
	},
    
    /* ***************************************************************
     * @Description Returns the Active Template Fields View module.
     * @param component. Lightning Component reference.
     * @param model(). The Template Fields Model.
     * @return View of the Active Template Fields module.
     *****************************************************************/
    ActiveTemplateFieldsView : function(component, model) {

		return (function (component, model) {
    		var _columns = [
                {
                    type: 'text',
                    fieldName: 'name',
                    label: $A.get("$Label.c.bgeBatchTemplateActiveFields")
                },
                {
                    type: 'text',
                    fieldName: 'defaultValue',
                    label: $A.get("$Label.c.stgDefaultValue")
                },
                {
                    type: 'boolean',
                    fieldName: 'required',
                    label: $A.get("$Label.c.lblRequired")
                },
                {
                    type: 'boolean',
                    fieldName: 'hide',
                    label: $A.get("$Label.c.stgLabelHide")
                }
            ];
            
            // Subscribe to the model onFieldsUpdated event.
            model.getTemplateFields().onFieldsUpdated.subscribe(function() {
                var activeTemplateFields = component.get('v.activeTemplateFields');
                activeTemplateFields.data = _convertToGridData(model.getTemplateFields().getActivesBySObject());
                activeTemplateFields.selectedRows = [];

                activeTemplateFields.data.forEach(function(fieldGroup) {
                    if (fieldGroup.selected) {
                        activeTemplateFields.selectedRows.push(fieldGroup.id);
                    }
                    if (fieldGroup._children) {
                        fieldGroup._children.forEach(function(currentField) {
                            if (currentField.selected) {
                                activeTemplateFields.selectedRows.push(currentField.id);
                            }
                        });
                    }  
                });
                 component.set('v.activeTemplateFields', activeTemplateFields);
            });
            
            /* *******************************************************************
             * @Description Converts the Active Fields list to the activeTemplateFields
             * Lightning:treeGrid data format.
             * @return activeTemplateFields Lightning:treeGrid data format.
             *********************************************************************/
            function _convertToGridData(fieldsBySObject) {
                var result = [];
                
                Object.keys(fieldsBySObject).sort().forEach(function(sObjectName) {
                    var gridDataRow = {
                        id: sObjectName,
                        name: sObjectName,
                        selected: false,
                        _children: []
                    };
                    fieldsBySObject[sObjectName].forEach(function(sObjectField) {
                        gridDataRow._children.push(
                            {
                                id: sObjectField.id,
                            	name: sObjectField.name,
                                selected: sObjectField.selected,
                                defaultValue: sObjectField.defaultValue,
                                required: sObjectField.required,
                                hide: sObjectField.hide,
                                activeSortOrder: sObjectField.activeSortOrder
                            }
                        );
                    });
                    result.push(gridDataRow);
                });
                
                return result;
            }
            
            // ActiveTemplateFieldsView module public functions and properties
			return {
                columns: _columns,
                data: [],
                selectedFields: []
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
                                description: response.description,
                                displayTotalPrompt: response.displayTotalPrompt,
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
                    description: _templateInfo.description,
                    displayTotalPrompt: _templateInfo.displayTotalPrompt,
                    requireTotalMatch: _templateInfo.requireTotalMatch
                };
                var activeFields = [];

                _templateFields.getActives().forEach(function(currentField) {
                    activeFields.push({
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
                        console.log('Success!');
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
                this.displayTotalPrompt = info.displayTotalPrompt;
                this.requireTotalMatch = info.requireTotalMatch;
                this.onInfoUpdated.notify();
            }
            
            // TemplateInfo module public functions and properties
            return {
                name: '',
                description: '',
                displayTotalPrompt: false,
                requireTotalMatch: false,
                load: load,
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
             * @Description Gets the available fields.
             * @return List of inactive fields.
             ************************************************************/
            function getAvailables() {
                var _availableFields = [];
                _allFields.forEach(function(currentField) {
                    if (!currentField.isActive) {
                        _availableFields.push(currentField);
                    }
                });
                return _availableFields;
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

            /* **********************************************************
             * @Description moves the selected fields up in the Active Fields view
             * @return void
             ************************************************************/
            function moveSelectedUp() {
                var activeFieldsBySObject = getActivesBySObject();

                Object.keys(activeFieldsBySObject).forEach(function(sObjectName) {
                    var currentGroupFields = activeFieldsBySObject[sObjectName];
                    if (_getSelectedFields(currentGroupFields).length > 1 || 
                        (currentGroupFields.length > 0 && currentGroupFields[0].selected)
                    ) {
                        return;
                    }
                    for (var i = 0; i < currentGroupFields.length; i ++) {
                        if (currentGroupFields[i].selected) {
                            currentGroupFields[i].activeSortOrder --;
                            currentGroupFields[i - 1].activeSortOrder ++;
                            break;
                        }
                    }
                });
                this.onFieldsUpdated.notify();
            }

            /* **********************************************************
             * @Description moves the selected fields down in the Active Fields view
             * @return void
             ************************************************************/
            function moveSelectedDown() {
                var activeFieldsBySObject = getActivesBySObject();

                Object.keys(activeFieldsBySObject).forEach(function(sObjectName) {
                    var currentGroupFields = activeFieldsBySObject[sObjectName];
                    if (_getSelectedFields(currentGroupFields).length > 1 || 
                        (currentGroupFields.length > 0 && currentGroupFields[currentGroupFields.length - 1].selected)
                    ) {
                        return;
                    }
                    for (var i = 0; i < currentGroupFields.length; i ++) {
                        if (currentGroupFields[i].selected) {
                            currentGroupFields[i].activeSortOrder ++;
                            currentGroupFields[i + 1].activeSortOrder --;
                            break;
                        }
                    }
                });
                this.onFieldsUpdated.notify();
            }

            /* **********************************************************
             * @Description Selects the available fields and
             *      notify onFieldsUpdated listeners.
             * @param fieldsToSelect. Map of IDs to available fields.
             * @return void.
             ************************************************************/
            function selectAvailables(fieldsToSelect) {
                var availableTemplateFields = getAvailables();
                _selectFields(availableTemplateFields, fieldsToSelect);
                this.onFieldsUpdated.notify();
            }

            /* **********************************************************
             * @Description Selects the active fields and notifies onFieldsUpdated listeners.
             * @param fieldsToSelect. Map of IDs to active fields.
             * @return void.
             ************************************************************/
            function selectActives(fieldsToSelect) {
                var activeTemplateFields = getActives();
                _selectFields(activeTemplateFields, fieldsToSelect);
                this.onFieldsUpdated.notify();
            }

            /* **********************************************************
             * @Description Updates the selected fields to Active, unselects
             *      fields, and notifies onFieldsUpdated listeners.
             * @return void.
             ************************************************************/
            function updateSelectedToActive() {
                _allFields.forEach(function(currentField) {
                    if (!currentField.isActive && currentField.selected) {
                        currentField.isActive = true;
                        currentField.selected = false;

                        // TODO: this seems expensive. is there a better way?
                        var activeFieldsBySObject = getActivesBySObject();
                        currentField.activeSortOrder = activeFieldsBySObject[currentField.sObjectName] ? activeFieldsBySObject[currentField.sObjectName].length-1 : 0;
                    }
                });
                this.onFieldsUpdated.notify();
            }

            /* **********************************************************
             * @Description Updates the selected fields to Available, unselects
             *      fields, and notifies onFieldsUpdated listeners.
             * @return void.
             ************************************************************/
            function updateSelectedToAvailable() {
                _allFields.forEach(function(currentField) {
                    if (currentField.isActive && currentField.selected) {
                        currentField.isActive = false;
                        currentField.selected = false;
                        currentField.activeSortOrder = null;
                    }
                });
                this.onFieldsUpdated.notify();
            }

            /* ******************PRIVATE FUNCTIONS************************/

            /* **********************************************************
             * @Description Get selected fields
             * @param fields: list of fields.
             * @return Selected fields.
             ************************************************************/
            function _getSelectedFields(fields) {
                var result = [];
                fields.forEach(function(currentField) {
                    if (currentField.selected) {
                        result.push(currentField);
                    }
                });
                return result;
            }

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

            /* **********************************************************
             * @Description Selects the fields by updating fields reference.
             * @param fields. List of fields.
             * @param fieldsToSelect. Id of fields to select.
             * @return void.
             ************************************************************/
            function _selectFields(fields, fieldsToSelect) {
                fields.forEach(function(currentField) {
                    currentField.selected = (currentField.id in fieldsToSelect);
                });
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
                getAvailables: getAvailables,
                getAvailablesBySObject: getAvailablesBySObject,
                getActives: getActives,
                getActivesBySObject: getActivesBySObject,
                selectAvailables: selectAvailables,
                selectActives: selectActives,
                updateSelectedToActive: updateSelectedToActive,
                updateSelectedToAvailable: updateSelectedToAvailable,
                onFieldsUpdated: _onFieldsUpdated,
                moveSelectedUp: moveSelectedUp,
                moveSelectedDown: moveSelectedDown

            }
        })(Event);
	},

    /* **********************************************************
     * @Description Gets the Model module of the Template Metadata, such as page mode and labels.
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
                this.onMetadataUpdated.notify();
            }

            // TemplateInfo module public functions and properties
            return {
                labels: {},
                mode: '',
                load: load,
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