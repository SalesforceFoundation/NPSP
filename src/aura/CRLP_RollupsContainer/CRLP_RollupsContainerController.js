({
    doInit: function (cmp, event, helper) {
        var action = cmp.get("c.setupRollups");
        console.log("in the init function");

        //setup rollup records, filter group records, and operations
        //also sets the rollups grid to display on page load
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var modelString = response.getReturnValue();
                var model = JSON.parse(modelString);

                var labels = model.labels;
                cmp.set("v.labels", labels);
                cmp.set("v.rollupList", model.items);
                cmp.set("v.cachedRollupList", model.items);
                cmp.set("v.filterGroupList", model.filterGroups);
                cmp.set("v.operations", model.operations);

                var yOps = [];
                for(var j in model.yearlyOperations){
                    yOps.push({name: j, label: model.yearlyOperations[j]});
                }
                yOps.sort(function(a,b){
                    return a.name > b.name;
                });
                cmp.set("v.yearlyOperations", yOps);

                var actions = [{label: labels.edit, name:'edit'}
                    , {label: labels.clone, name:'clone'}
                    , {label: labels.delete, name:'delete'}
                ];

                //TODO: update here RD
                var summaryObjects = [{label: labels.accountLabel, name: 'Account'}
                    , {label: labels.contactLabel, name: 'Contact'}
                    , {label: labels.gauLabel, name: 'General_Accounting_Unit__c'}
                    , {label: labels.rdLabel, name: 'npe03__Recurring_Donation__c'}];
                cmp.set("v.summaryObjects", summaryObjects);

                //note: if lightning:datatable supports Boolean attribute in the future the 'active' column will need retesting
                var rollupColumns = [{label: labels.name, fieldName: 'rollupName', type: 'button', sortable: 'true', initialWidth: 300
                                , typeAttributes: {label: {fieldName: 'rollupName'}, name: 'view', variant: 'bare', title: {fieldName: 'description'}}}
                            , {label: labels.summaryObject, fieldName: 'summaryObject', type: 'string', sortable: 'true'}
                            , {label: labels.detailObject, fieldName: 'detailObject', type: 'string', sortable: 'true'}
                            , {label: labels.creditType, fieldName: 'creditType', type: 'string', sortable: 'true', initialWidth: 150}
                            , {label: labels.operation, fieldName: 'operation', type: 'string', sortable: 'true', initialWidth: 130}
                            , {label: labels.filterGroupLabel, fieldName: 'filterGroupName', type: 'string', sortable: 'true'}
                            , {label: labels.active, fieldName: 'active', type: 'string', sortable: 'true', initialWidth: 100
                                , cellAttributes: {iconName: {fieldName: 'activeIcon'}}}
                            , {type: 'action', typeAttributes: { rowActions: actions }}
                            ];
                cmp.set("v.rollupColumns", rollupColumns);

                var filterGroupColumns = [{label: labels.name, fieldName: 'label', type: 'button', sortable: 'true', typeAttributes: {label: {fieldName: 'label'}, name: 'view', variant: 'bare'}}
                    , {label: labels.filterGroupDescription, fieldName: 'description', type: 'string', sortable: 'true'}
                    , {label: labels.countOf+ ' ' + labels.filterRuleLabelPlural, fieldName: 'countFilterRules', type: 'number', sortable: 'true', initialWidth: 200}
                    , {label: labels.countOf+ ' ' + labels.rollupLabelPlural, fieldName: 'countRollups', type: 'number', sortable: 'true', initialWidth: 200}
                    , {type: 'action', typeAttributes: { rowActions: actions }}
                ];

                cmp.set("v.filterGroupColumns", filterGroupColumns);

                cmp.set("v.isRollupsGrid",true);
                cmp.set("v.isFilterGroupsGrid",false);
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                            errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });

        $A.enqueueAction(action);
    },

    activeChange: function(cmp){
        var activeRecord = cmp.get("v.activeRecord");
        console.log("Active record changed in Parent");
        console.log(JSON.stringify(activeRecord));
    },

    displayFilterGroupsGrid: function(cmp, event, helper){
        //sets the filter group grid to be displayed
        helper.displayFilterGroupsGrid(cmp);
        cmp.set("v.sortedBy", "");
        cmp.set("v.sortedDirection", "");
    },

    displayNewRollupForm: function (cmp, event, helper) {
        //resets the active record to ensure there is no leftover data
        //applies filtered summary object to the creation of a new rollup if applicable
        cmp.set("v.activeRecord", {});
        cmp.set("v.activeRecord.MasterLabel", cmp.get("v.labels.rollupNew"));
        var summaryFilterObject = cmp.find("selectSummaryObject").get("v.value");
        if(summaryFilterObject !== 'All'){
            cmp.set("v.activeRecord.Summary_Object__r.QualifiedApiName", summaryFilterObject);
        }

        //toggle grid and detail views, set detail mode to create
        cmp.set("v.isRollupsGrid", false);
        cmp.set("v.isRollupDetail", true);
        cmp.set("v.detailMode", "create");
    },

    displayNewFilterGroupForm: function (cmp, event, helper) {
        //toggle grid and detail views, set detail mode to create
        //resets the active record to ensure there is no leftover data
        cmp.set("v.activeRecord", {});
        cmp.set("v.isFilterGroupsGrid", false);
        cmp.set("v.isFilterGroupDetail", true);
        cmp.set("v.detailMode", "create");
    },

    displayRollupsGrid: function(cmp, event, helper){
        //sets the rollups grid to be displayed
        helper.displayRollupsGrid(cmp);
        cmp.set("v.sortedBy", "");
        cmp.set("v.sortedDirection", "");
    },

    filterBySummaryObject: function(cmp, event, helper){
        //filters visible rollups by the summary object picklist
        var object = cmp.find("selectSummaryObject").get("v.value");
        helper.filterData(cmp, object);
    },

    handleCancelEvent: function(cmp, event, helper){
        //switches to selected grid with correct width after hearing cancel event from rollup or filter group detail
        //if cancel comes from the breadcrumbs in parent, check for name to toggle grid selection
        var labels = cmp.get("v.labels");
        var breadcrumbName = event.getSource().get('v.name');
        var gridTarget = event.getParam('grid');
        cmp.set("v.lastActiveRecordId", null);

        if(gridTarget === 'rollup' || breadcrumbName === labels.rollupSummaryTitle){
            helper.displayRollupsGrid(cmp);
            cmp.set("v.width", 12);
        }
        else if (gridTarget === 'filterGroup' || breadcrumbName === labels.filterGroupLabelPlural) {
            helper.displayFilterGroupsGrid(cmp);
            cmp.set("v.width", 12);
        }
    },

    /* @description: handles the ltng:message event
    * currently listens for the rollup name change on the Rollup cmp since this doesn't bind correctly
    */
    handleMessage: function(cmp, event, helper){
        var message = event.getParam("message");
        var channel = event.getParam("channel");

        if(channel === 'rollupNameChange'){
            //message is the masterLabel
            //note: javascript object must be used here: cmp.set("v.activeRecord.MasterLabel", message) won't
            var activeRecord = cmp.get("v.activeRecord");
            activeRecord.MasterLabel = message;
            cmp.set("v.activeRecord", activeRecord);

        } else if (channel === 'rollupRecordChange') {
            // message will inserted or updated the Rollup__mdt record
            var
            var rollupsList = cmp.get("v.rollupList")
            rollupsList.forEach(function(row) {
                if (row.id === message.id) {
                    // if the Id matches, update that record

                    row.active = message.Active__c;
                    if (message.Active__c === true) {
                        row.activeIcon = 'utility:check';
                    } else {
                        row.activeIcon = 'utility:close';
                    }
                    // value.creditType = TBD
                    row.description = message.Description__c;
                    row.detailObject = message.Detail_Object__r.Label;
                    row.detailField = message.Detail_Field__r.Label;
                    row.filterGroupName = message.Filter_Group__r.MasterLabel;
                    row.operation = message.Operation__c;
                    row.rollupName = message.MasterLabel;
                    row.summaryObject = message.Summary_Object__r.Label;
                    row.summaryObjectApiName = message.Summary_Object__r.QualifiedApiName;
                }
            });
        }
    },

    handleNavigateEvent: function(cmp, event, helper){
        //handles the selection of a specific rollup from the filter group view and the return to filter group
        var id = event.getParam('id');
        var lastId = event.getParam('lastId');
        var target = event.getParam('target');

        cmp.set("v.activeRecordId", id);
        cmp.set("v.detailMode", 'view');
        cmp.set("v.width", 8);

        if(target === 'rollup'){
            cmp.set("v.lastActiveRecordId", lastId);
            cmp.set("v.isRollupDetail", true);
            cmp.set("v.isFilterGroupDetail", false);
        } else if (target === 'filterGroup'){
            cmp.set("v.lastActiveRecordId", null);
            cmp.set("v.isRollupDetail", false);
            cmp.set("v.isFilterGroupDetail", true);
        }

    },

    handleRowAction: function(cmp, event, helper){
        //handles the selected action in the rollups grid
        var action = event.getParam('action');
        var row = event.getParam('row');

        if(action.name !== 'delete'){
            cmp.set("v.detailMode", action.name);
            cmp.set("v.activeRecordId", row.id);
            //check which grid is displayed
            if(cmp.get("v.isRollupsGrid")){
                cmp.set("v.isRollupsGrid", false);
                cmp.set("v.isRollupDetail", true);
                cmp.set("v.width", 8);
            } else{
                cmp.set("v.isFilterGroupsGrid", false);
                cmp.set("v.isFilterGroupDetail", true);
                cmp.set("v.width", 8);
            }
        } else {
            var rows = cmp.get("v.rollupList");
            var rowIndex = rows.indexOf(row);
            rows.splice(rowIndex, 1);
            cmp.set("v.rollupList", rows);
        }
    },

    returnToFilterGroup: function(cmp, event, helper){
        cmp.set("v.activeRecordId", cmp.get("v.lastActiveRecordId"));
        cmp.set("v.lastActiveRecordId", null);
        cmp.set("v.isRollupDetail", false);
        cmp.set("v.isFilterGroupDetail", true);
    },

    setMode: function(cmp, event, helper) {
        //changes the mode from the edit or clone buttons
        var name = event.getSource().get("v.name");
        cmp.set("v.detailMode", name);
    },

    sortByColumns: function(cmp, event, helper){
        //sorts the data grid by the field name and current direction
        var col = event.getParam();
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');

        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        if(cmp.get("v.isRollupsGrid")){
            helper.sortRollupGrid(cmp, fieldName, sortDirection);
        } else if (cmp.get("v.isFilterGroupsGrid")){
            helper.sortFilterGroupGrid(cmp, fieldName, sortDirection);
        }

    },
})