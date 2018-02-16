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

                cmp.set("v.labels", model.labels);
                cmp.set("v.rollupList", model.items);
                cmp.set("v.cachedRollupList", model.items);
                cmp.set("v.filterGroupList", model.filterGroups);

                var ops = [];
                for(var i in model.operations){
                    ops.push({name: i, label: model.operations[i]});
                }
                cmp.set("v.operations", ops);

                var yOps = [];
                for(var i in model.yearlyOperations){
                    yOps.push({name: i, label: model.yearlyOperations[i]});
                }
                cmp.set("v.yearlyOperations", yOps);

                var actions = [{label: 'Edit', name:'edit'}
                    , {label: 'Clone', name:'clone'}
                    , {label: 'Delete', name:'delete'}
                    ];

                //note: if lightning:datatable supports Boolean attribute in the future the 'active' column will need retesting
                var rollupColumns = [{label: model.labels.name, fieldName: 'rollupName', type: 'button', sortable: 'true', initialWidth: 300
                                , typeAttributes: {label: {fieldName: 'rollupName'}, name: 'view', variant: 'bare'}}
                            , {label: model.labels.summaryObject, fieldName: 'summaryObject', type: 'string', sortable: 'true'}
                            , {label: model.labels.detailObject, fieldName: 'detailObject', type: 'string', sortable: 'true'}
                            , {label: model.labels.creditType, fieldName: 'creditType', type: 'string', sortable: 'true', initialWidth: 150}
                            , {label: model.labels.operation, fieldName: 'operation', type: 'string', sortable: 'true', initialWidth: 130}
                            , {label: model.labels.filterGroupLabel, fieldName: 'filterGroupName', type: 'string', sortable: 'true'}
                            , {label: model.labels.active, fieldName: 'active', type: 'string', sortable: 'true', initialWidth: 100
                                , cellAttributes: {iconName: {fieldName: 'activeIcon'}}}
                            , {type: 'action', typeAttributes: { rowActions: actions }}
                            ];
                cmp.set("v.rollupColumns", rollupColumns);

                var filterGroupColumns = [{label: model.labels.name, fieldName: 'label', type: 'button', sortable: 'true', typeAttributes: {label: {fieldName: 'label'}, name: 'view', variant: 'bare'}}
                    , {label: model.labels.filterGroupDescription, fieldName: 'description', type: 'string', sortable: 'true'}
                    , {label: model.labels.countOf+' '+model.labels.filterGroupLabelPlural, fieldName: 'countFilterRules', type: 'number', sortable: 'true'}
                    , {label: model.labels.countOf+' '+model.labels.rollupLabelPlural, fieldName: 'countRollups', type: 'number', sortable: 'true'}
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

    displayFilterGroupsGrid: function(cmp, event, helper){
        //sets the filter group grid to be displayed
        helper.displayFilterGroupsGrid(cmp);
        cmp.set("v.sortedBy", "");
        cmp.set("v.sortedDirection", "");
    },

    displayNewRollupForm: function (cmp, event, helper) {
        //toggle grid and detail views, set detail mode to create
        //resets the active record to ensure there is no leftover data
        cmp.set("v.isRollupsGrid", false);
        cmp.set("v.isRollupDetail", true);
        cmp.set("v.detailMode", "create");
        cmp.set("v.activeRecord", {});
    },

    displayNewFilterGroupForm: function (cmp, event, helper) {
        //toggle grid and detail views, set detail mode to create
        //resets the active record to ensure there is no leftover data
        cmp.set("v.isFilterGroupsGrid", false);
        cmp.set("v.isFilterGroupDetail", true);
        cmp.set("v.detailMode", "create");
        cmp.set("v.activeRecord", {});
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

        if(gridTarget === 'rollup' || breadcrumbName === labels.rollupSummaryTitle){
            helper.displayRollupsGrid(cmp);
            cmp.set("v.width", 12);
        }
        else if (gridTarget === 'filterGroup' || breadcrumbName === labels.filterGroupLabelPlural) {
            helper.displayFilterGroupsGrid(cmp);
        }
    },

    handleRowAction: function(cmp, event, helper){
        //handles the selected action in the rollups grid
        var action = event.getParam('action');
        var row = event.getParam('row');

        if(action.name != 'delete'){
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
            }
        } else {
            var rows = cmp.get("v.rollupList");
            var rowIndex = rows.indexOf(row);
            rows.splice(rowIndex, 1);
            cmp.set("v.rollupList", rows);
        }
    },

    setMode: function(cmp, event, helper) {
        //changes the mode from the edit or clone buttons
        var name = event.getSource().get("v.name");
        cmp.set("v.detailMode", name);
    },

    sortByColumns: function(cmp, event, helper){
        //sorts the data grid by the field name and current direction
        var col = event.getParam()
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');

        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        helper.sortData(cmp, fieldName, sortDirection);
    },
})