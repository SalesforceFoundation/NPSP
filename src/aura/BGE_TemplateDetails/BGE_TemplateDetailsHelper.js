({
    /********************************************* View Modules *********************************************/
    
    /* ***************************************************************
     * @Description Returns the Available Template Fields View module.
     * @param component. Lightning Component reference.
     * @param templateFieldsModel. The Template Fields Model.
     * @return View of the Available Template Fields module.
     *****************************************************************/
    AvailableTemplateFieldsView : function(component, templateFieldsModel) {
		return (function (component, templateFieldsModel) {
            var _columns = [
                {
                	type: 'text',
                	fieldName: 'name',
                	label: 'Available Fields'
            	}
            ];

            // Subscribe to the TemplateFieldsModel onDataChanged event. 
            templateFieldsModel.onDataChanged.subscribe(function() {
                var availableTemplateFields = component.get('v.availableTemplateFields');
                availableTemplateFields.data = _convertToGridData(templateFieldsModel.getAvailables());
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
             * @Description Converts the Fields list to the availableTemplateFields
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

                    fieldsBySObject[sObjectName].sort().forEach(function(sObjectField) {
                        gridDataRow._children.push(
                            {
                                id: sObjectField.id,
                            	name: sObjectField.name,
                                selected: sObjectField.selected
                            }
                        );
                    });

                    result.push(gridDataRow);
                });
                
                return result;
            }
            
            // AvailableTemplateFieldsView module public functions
			return {
                columns: _columns,
                data: [],
                selectedRows: []
            };
        })(component, templateFieldsModel);
	},
    
    /* ***************************************************************
     * @Description Returns the Available Template Fields View module.
     * @param component. Lightning Component reference.
     * @param templateFieldsModel. The Template Fields Model.
     * @return View of the Available Template Fields module.
     *****************************************************************/
    ActiveTemplateFieldsView : function(component, templateFieldsModel) {
		return (function (component, templateFieldsModel) {
    		var _columns = [
                {
                    type: 'text',
                    fieldName: 'name',
                    label: 'Active Fields'
                },
                {
                    type: 'text',
                    fieldName: 'defaultValue',
                    label: 'Default Value'
                },
                {
                    type: 'boolean',
                    fieldName: 'required',
                    label: 'Required'
                },
                {
                    type: 'boolean',
                    fieldName: 'hide',
                    label: 'Hide'
                }
            ];
            
            // Subscribe to the TemplateFieldsModel onDataChanged event. 
            templateFieldsModel.onDataChanged.subscribe(function() {
                var activeTemplateFields = component.get('v.activeTemplateFields');
                activeTemplateFields.data = _convertToGridData(templateFieldsModel.getActives());
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
             * @Description Converts the Fields list to the activeTemplateFields
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
                    fieldsBySObject[sObjectName].sort().forEach(function(sObjectField) {
                        gridDataRow._children.push(
                            {
                                id: sObjectField.id,
                            	name: sObjectField.name,
                                selected: sObjectField.selected,
                                defaultValue: sObjectField.defaultValue,
                                required: sObjectField.required,
                                hide: sObjectField.hide,
                            }
                        );
                    });
                    result.push(gridDataRow);
                });
                
                return result;
            }
            
            // ActiveTemplateFieldsView module public functions.
			return {
                columns: _columns,
                data: [],
                selectedFields: []
            };
     
        })(component, templateFieldsModel);
	},
    
    /*********************************************** Model Modules *********************************************/

    /* **********************************************************
     * @Description Gets the Model module of the Template Fields.
     * This is the main and only Model module for the Template 
     * Details components.
     * @return Model module of the Template Fields.
     ************************************************************/
     TemplateDetailsModel : function() {
        var templateFields = this.TemplateFields();

        return (function (templateFields) {
            var _templateFields = templateFields;
            var _bgeTemplateController;
            
            /* **********************************************************
             * @Description Gets the Template Fields module.
             * @return Template Fields module.
             ************************************************************/
            function init() {
                _bgeTemplateController.getTemplateDetails({
                    success: function(response) {
                        _templateFields.load(response.templateFields);
                    },
                    error: function(error) {
                        console.log(error);
                    }
                });
            }

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
            
            // TemplateDetailsModel module public functions.
            return {
                init: init,
                setBackendController: setBackendController,
                getTemplateFields: getTemplateFields
            }
        })(templateFields);
    },

    /* **********************************************************
     * @Description Gets the Template Fields module.
     * @return Model module of the Template Fields.
     ************************************************************/
     TemplateFields : function() {
  		var Event = this.Event();
        
		return (function (Event) {
            var _allFields = [];
            var _onDataChanged = new Event(this);
            
            /* **********************************************************
             * @Description Groups the fields by SObject name.
             * @return Maps of SObject group to List of related fields.
             ************************************************************/
            function _groupFieldsBySObject(fields) {
                var result = {};
                fields.forEach(function(currentField) {
                	if ((currentField.sObjectName in result) == false) {
                        result[currentField.sObjectName] = [];
                    }
                    result[currentField.sObjectName].push(currentField);
                });
                return result;
            }
            
            /* **********************************************************
             * @Description Loads the fields, and notify all the 
             * onDataChanged listeners.
             * @return List of fields.
             ************************************************************/
            function load(allFields) {
                _allFields = [];
                allFields.forEach(function(currentField) {
                    currentField.id = currentField.sObjectName + "." + currentField.name;
                    currentField.selected = false;
                    _allFields.push(currentField);
                });
                this.onDataChanged.notify();
            }
            
            /* **********************************************************
             * @Description Gets the available fields.
             * @return Maps of SObject group to List of related available
             * fields.
             ************************************************************/
            function getAvailables() {
                var _availableFields = [];
                _allFields.forEach(function(currentField) {
                    if (!currentField.activeInfo) {
                        _availableFields.push(currentField);
                    }
                });
                return _groupFieldsBySObject(_availableFields);
            }
            
            /* **********************************************************
             * @Description Gets the active fields.
             * @return Maps of SObject group to List of related active
             * fields.
             ************************************************************/
            function getActives() {
                var _activeFields = [];
                _allFields.forEach(function(currentField) {
                    if (currentField.activeInfo) {
                        _activeFields.push(currentField);
                    }
                });
                return _groupFieldsBySObject(_activeFields);
            }

            /* **********************************************************
             * @Description Selects the available fields.
             * @param fieldsToSelect. Set of available fields to select.
             * @return void.
             ************************************************************/
            function selectAvailables(fieldsToSelect) {
                var availableTemplateFields = getAvailables();
                _selectFields(availableTemplateFields, fieldsToSelect)
                this.onDataChanged.notify();
            }

            /* **********************************************************
             * @Description Selects the available fields.
             * @param fieldsToSelect. Set of active fields to select.
             * @return void.
             ************************************************************/
            function selectActives(fieldsToSelect) {
                var activeTemplateFields = getActives();
                _selectFields(activeTemplateFields, fieldsToSelect)
                this.onDataChanged.notify();
            }

            /* **********************************************************
             * @Description Updates the selected fields to Active.
             * @param fieldsToSelect. Set of active fields to select.
             * @return void.
             ************************************************************/
            function updateToActive() {
                _allFields.forEach(function(currentField) {
                    if (!currentField.activeInfo && currentField.selected) {
                        currentField.activeInfo = {
                            defaultValue: "",
                            required: false,
                            hide: false
                        };
                    }
                });
                this.onDataChanged.notify();
            }

            /* **********************************************************
             * @Description Updates the selected fields to Available.
             * @param fieldsToSelect. Set of active fields to select.
             * @return void.
             ************************************************************/
            function updateToAvailable() {
                _allFields.forEach(function(currentField) {
                    if (currentField.activeInfo && currentField.selected) {
                        delete currentField.activeInfo;
                    }
                });
                this.onDataChanged.notify();
            }

            /* **********************************************************
             * @Description Selects the fields.
             * @param fieldsGroupBySObject. Fields to select.
             * @param fieldsToSelect. Set of available fields to select.
             * @return void.
             ************************************************************/
            function _selectFields(fieldsGroupBySObject, fieldsToSelect) {
                Object.keys(fieldsGroupBySObject).forEach(function(sObjectName) {
                    if (sObjectName in fieldsToSelect) {
                        fieldsGroupBySObject[sObjectName].forEach(function(currentField) {
                            currentField.selected = false;
                        });
                    } else {
                        fieldsGroupBySObject[sObjectName].forEach(function(currentField) {
                            currentField.selected = (currentField.id in fieldsToSelect);
                        });
                    }  
                });
            }
            
            // TemplateFieldsModel module public functions.
            return {
                load: load,
                getAvailables: getAvailables,
                getActives: getActives,
                selectAvailables: selectAvailables,
                selectActives: selectActives,
                updateToActive: updateToActive,
                updateToAvailable: updateToAvailable,
                onDataChanged: _onDataChanged
            }
        })(Event);
	},
    
    /* **********************************************************
     * @Description. Publisher/Subscribers. It is used by the Model 
     * modules to notify the View modules on a specific change in the
     * Model module.
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
     ************************************************************/
    BGETemplateController : function(component) {
        return (function (component) {
            var _component = component;

            /* **********************************************************
             * @Description Calls the getTemplateDetails method.
             * @return Template Fields module.
             ************************************************************/
            function getTemplateDetails(callback) {
                var action = _component.get("c.getTemplateDetails");
                action.setCallback(callback, _processResponse);
                $A.enqueueAction(action);
            }

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
                getTemplateDetails: getTemplateDetails
            }
        })(component);
    },
})