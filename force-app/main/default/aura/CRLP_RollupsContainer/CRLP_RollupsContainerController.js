({
    /**
    * @description: setup for rollup app including cached rollups, filter groups, and labels for the app
    */
    doInit: function (cmp, event, helper) {
        var action = cmp.get("c.setupRollupGrid");

        //setup rollup records, filter group records, and labels
        //also sets the rollups grid to display on page load
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var modelString = response.getReturnValue();
                var model = JSON.parse(modelString);

                var labels = model.labels;
                cmp.set("v.labels", labels);

                if (!model.isSystemAdminUser) {
                    cmp.set("v.isSystemAdminUser", false);
                }

                //notify user that CRLP is disabled or proceed with setting data
                if (!model.isCRLPEnabled) {
                    cmp.set("v.isCRLPEnabled", false);

                } else {
                    var sortedData = helper.sortData(cmp, 'displayName', 'asc', model.items);
                    cmp.set("v.rollupList", sortedData);
                    cmp.set("v.cachedRollupList", sortedData);
                    cmp.set("v.filterGroupList", model.filterGroups);

                    var actions = [{label: labels.edit, name: 'edit'}
                        , {label: labels.clone, name: 'clone'}
                    ];

                    //these are the current lists of summary + detail objects in the app
                    var summaryObjects = [{label: labels.labelAccount, name: labels.objectAccount}
                        , {label: labels.labelContact, name: labels.objectContact}
                        , {label: labels.labelGAU, name: labels.objectGAU}
                        , {label: labels.labelRD, name: labels.objectRD}];
                    cmp.set("v.summaryObjects", summaryObjects);

                    var unsortedDetailObjects = [{label: labels.labelOpportunity, name: labels.objectOpportunity}
                        , {label: labels.labelContactSoftCredit, name: labels.objectPartialSoftCredit}
                        , {label: labels.labelPayment, name: labels.objectPayment}
                        , {label: labels.labelAccountSoftCredit, name: labels.objectAccountSoftCredit}
                        , {label: labels.labelAllocation, name: labels.objectAllocation}];
                    var detailObjects = helper.sortData(cmp, 'label', 'asc', unsortedDetailObjects);
                    cmp.set("v.detailObjects", detailObjects);

                    var rollupColumns = [{
                        label: labels.name,
                        fieldName: 'displayName',
                        type: 'button',
                        sortable: 'true',
                        initialWidth: 300,
                        typeAttributes: {
                            label: {fieldName: 'displayName'},
                            name: 'view',
                            variant: 'bare',
                            title: {fieldName: 'description'}
                        }
                    }
                        , {
                            label: labels.summaryObject,
                            fieldName: 'summaryObject',
                            type: 'string',
                            sortable: 'true'
                        }
                        , {
                            label: labels.detailObject,
                            fieldName: 'detailObject',
                            type: 'string',
                            sortable: 'true'
                        }
                        , {
                            label: labels.creditType,
                            fieldName: 'creditType',
                            type: 'string',
                            sortable: 'true',
                            initialWidth: 150
                        }
                        , {
                            label: labels.operation,
                            fieldName: 'operation',
                            type: 'string',
                            sortable: 'true',
                            initialWidth: 130
                        }
                        , {
                            label: labels.filterGroupLabel,
                            fieldName: 'filterGroupName',
                            type: 'string',
                            sortable: 'true'
                        }
                        , {
                            label: labels.active,
                            fieldName: 'active',
                            type: 'string',
                            sortable: 'true',
                            initialWidth: 100,
                            cellAttributes: {iconName: {fieldName: 'activeIcon'}}
                        }
                        , {type: 'action', typeAttributes: {rowActions: actions}}
                    ];
                    cmp.set("v.rollupColumns", rollupColumns);

                    var filterGroupColumns = [{
                        label: labels.name,
                        fieldName: 'label',
                        type: 'button',
                        sortable: 'true',
                        typeAttributes: {label: {fieldName: 'label'}, name: 'view', variant: 'bare'}
                    }
                        , {
                            label: labels.filterGroupDescription,
                            fieldName: 'description',
                            type: 'string',
                            sortable: 'true'
                        }
                        , {
                            label: labels.countOf + ' ' + labels.filterRuleLabelPlural,
                            fieldName: 'countFilterRules',
                            type: 'number',
                            sortable: 'true',
                            initialWidth: 200
                        }
                        , {
                            label: labels.countOf + ' ' + labels.rollupLabelPlural,
                            fieldName: 'countRollups',
                            type: 'number',
                            sortable: 'true',
                            initialWidth: 200
                        }
                        , {type: 'action', typeAttributes: {rowActions: actions}}
                    ];

                    cmp.set("v.filterGroupColumns", filterGroupColumns);

                    cmp.set("v.isRollupsGrid", true);
                    cmp.set("v.isFilterGroupsGrid", false);
                }
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                var msg = "Unknown error. Please try again.";
                if (errors && errors[0] && errors[0].message) {
                    msg = errors[0].message;
                }
                helper.showToast(cmp, 'error', "Error displaying Customizable Rollups", msg);
            }
            helper.toggleSpinner(cmp, false);
        });

        $A.enqueueAction(action);
    },

    /**
     * @description: closes the toast notification window
     */
    closeNotificationWindow: function (cmp, event, helper) {
        cmp.set("v.toastHideClass", "slds-hide");
    },

    /**
     * @description: calls the helper function to display the filter group grid and resets shared sorting information
     */
    displayFilterGroupsGrid: function(cmp, event, helper){
        helper.displayFilterGroupsGrid(cmp);
        cmp.set("v.sortedBy", "");
        cmp.set("v.sortedDirection", "asc");
    },

    /**
     * @description: resets the active record to ensure there is no leftover data and applies filtered summary object to the creation of a new rollup if applicable
     */
    displayNewRollupForm: function (cmp, event, helper) {
        cmp.set("v.activeRecord", {});
        cmp.set("v.activeRecord.label", cmp.get("v.labels.rollupNew"));
        var summaryFilterObject = cmp.find("selectSummaryObject").get("v.value");
        if(summaryFilterObject !== 'All'){
            cmp.set("v.activeRecord.summaryObject", summaryFilterObject);
        }

        //toggle grid and detail views, set detail mode to create
        cmp.set("v.isRollupsGrid", false);
        cmp.set("v.isRollupDetail", true);
        cmp.set("v.width", 8);
        cmp.set("v.detailMode", "create");
    },

    /**
     * @description: resets the active record and toggles the grid and detail views
     */
    displayNewFilterGroupForm: function (cmp, event, helper) {
        cmp.set("v.activeRecord", {});
        cmp.set("v.isFilterGroupsGrid", false);
        cmp.set("v.isFilterGroupDetail", true);
        cmp.set("v.width", 8);
        cmp.set("v.detailMode", "create");
    },

    /**
     * @description: calls the helper function to display the rollups grid and resets shared sorting information
     */
    displayRollupsGrid: function(cmp, event, helper){
        helper.displayRollupsGrid(cmp);
        cmp.set("v.sortedBy", "");
        cmp.set("v.sortedDirection", "asc");
    },

    /**
     * @description: filters visible rollups by the summary object picklist
     */
    filterBySummaryObject: function(cmp, event, helper){
        var object = cmp.find("selectSummaryObject").get("v.value");
        helper.filterData(cmp, object);
    },

    /**
     * @description: switches to selected grid with correct width after hearing cancel event from rollup or filter group detail
     */
    handleBreadcrumbEvent: function(cmp, event, helper){
        var labels = cmp.get("v.labels");
        var breadcrumbName = event.getSource().get('v.name');
        cmp.set("v.lastActiveRecordId", null);

        if (breadcrumbName === labels.rollupSummaryTitle) {
            helper.displayRollupsGrid(cmp);
            cmp.set("v.width", 12);
        } else if (breadcrumbName === labels.filterGroupLabelPlural) {
            helper.displayFilterGroupsGrid(cmp);
            cmp.set("v.width", 12);
        }
    },

    /**
     * @description: handles the ltng:message event to update the rollup name or to update rollup or filter groups in the grid
     */
    handleMessage: function(cmp, event, helper){
        var message = event.getParam("message");
        var channel = event.getParam("channel");

        //ordered by frequency
        if (channel === 'cancelEvent') {
            helper.handleCancelDetailEvent(cmp, message.grid);

        } else if (channel === 'toggleSpinner') {
            helper.toggleSpinner(cmp, message.showSpinner);

        } else if (channel === 'showToast') {
            helper.showToast(cmp, message.type, message.title, message.message);

        } else if (channel === 'nameChange'){
            //note: full javascript object must be used here: cmp.set("v.activeRecord.MasterLabel", message) won't work
            var activeRecord = cmp.get("v.activeRecord");
            activeRecord.label = message;
            cmp.set("v.activeRecord", activeRecord);

        } else if (channel === 'rollupRecordChange') {
            helper.mergeRowItem(cmp, cmp.get("v.cachedRollupList"), message, 'rollup');

        } else if (channel === 'filterRecordChange') {
            helper.mergeRowItem(cmp, cmp.get("v.filterGroupList"), message, 'filterGroup');
            //update record name for the detail page
            var activeRecord = cmp.get("v.activeRecord");
            activeRecord.MasterLabel = message.MasterLabel;
            cmp.set("v.activeRecord", activeRecord);

        } else if (channel === 'rollupDeleted') {
            helper.deleteGridItem(cmp, cmp.get("v.cachedRollupList"), message, 'rollup');

        } else if (channel === 'filterGroupDeleted') {
            helper.deleteGridItem(cmp, cmp.get("v.filterGroupList"), message, 'filterGroup');

        } else if (channel === 'navigateEvent') {
            helper.handleNavigateEvent(cmp, message);
        }
    },

    /**
     * @description: handles the selected action in the either grid
     */
    handleRowAction: function(cmp, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        var isRollupsGrid = cmp.get("v.isRollupsGrid");

        cmp.set("v.detailMode", action.name);
        cmp.set("v.activeRecordId", row.recordId);
        //check which grid is displayed
        if (isRollupsGrid) {
            cmp.set("v.isRollupsGrid", false);
            cmp.set("v.isRollupDetail", true);
            cmp.set("v.width", 8);
        } else {
            cmp.set("v.isFilterGroupsGrid", false);
            cmp.set("v.isFilterGroupDetail", true);
            cmp.set("v.width", 8);
        }

    },

    /**
     * @description: used in the breadcrumb to return to the filter group grid from the filter group detail view
     */
    returnToFilterGroup: function(cmp, event, helper){
        cmp.set("v.activeRecordId", cmp.get("v.lastActiveRecordId"));
        cmp.set("v.lastActiveRecordId", null);
        cmp.set("v.isRollupDetail", false);
        cmp.set("v.isFilterGroupDetail", true);
    },

    /**
     * @description: changes the mode from the edit or clone buttons
     */
    setMode: function(cmp, event, helper) {
        var name = event.getSource().get("v.name");
        cmp.set("v.detailMode", name);
    },

    /**
     * @description: sorts the data in either grid by the field name and current direction
     */
    sortByColumns: function(cmp, event, helper){
        var col = event.getParam();
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');

        if(!sortDirection){
            sortDirection = 'asc';
        }

        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        if(cmp.get("v.isRollupsGrid")){
            var data = cmp.get("v.rollupList");
            var sortedData = helper.sortData(cmp, fieldName, sortDirection, data);
            cmp.set("v.rollupList", data);
        } else if (cmp.get("v.isFilterGroupsGrid")){
            var data = cmp.get("v.filterGroupList");
            var sortedData = helper.sortData(cmp, fieldName, sortDirection, data);
            cmp.set("v.filterGroupList", data);
        }

    },

    /**
     * @description: toggles a modal popup and backdrop
     */
    toggleFilterRuleModal: function(cmp, event, helper){
        helper.toggleFilterRuleModal(cmp);
    }

})