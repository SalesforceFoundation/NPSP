({
    /**
     * @description: return to main grid from rollup detail and remove the rollup from the cached and active grids
     * @param recordName: message passed in from the handleMessage
     * @param list: active working list
     * @param grid: active grid, either rollup or filterGroup
    */
    deleteGridItem: function (cmp, list, recordName, grid) {
        for (var i = 0; i < list.length; i++) {
            if (list[i].recordName === recordName || list[i].name === recordName) {
                // if the Id matches, delete that record
                list.splice(i, 1);
                break;
            }
        }
        if (grid === 'rollup') {
            this.resetRollupDataGrid(cmp, list);
            this.showToast(cmp, 'success', cmp.get("v.labels.rollupDeleteProgress"), cmp.get("v.labels.rollupDeleteSuccess"));
            this.requeryFilterGroups(cmp);
        } else if (grid === 'filterGroup') {
            cmp.set("v.filterGroupList", list);
            this.showToast(cmp, 'success', cmp.get("v.labels.filtersDeleteProgress"), cmp.get("v.labels.filtersDeleteSuccess"));
        }
        this.handleCancelDetailEvent(cmp, grid);
    },

    /**
     * @description: resets the view assignments, clears detail information, and displays rollup grid
     */
    displayRollupsGrid: function(cmp) {
        cmp.set("v.isRollupsGrid", true);
        cmp.set("v.isFilterGroupsGrid", false);
        cmp.set("v.isRollupDetail", false);
        cmp.set("v.isFilterGroupDetail", false);
        cmp.set("v.detailMode", null);
        cmp.set("v.activeRecord", null);

        //checks if we're coming from the detail view
        cmp.set("v.activeRecordId", null);
    },

    /**
     * @description: resets the view assignments, clears detail information, and displays filter group grid
     */
    displayFilterGroupsGrid: function(cmp) {
        cmp.set("v.isFilterGroupsGrid",true);
        cmp.set("v.isRollupsGrid", false);
        cmp.set("v.isFilterGroupDetail", false);
        cmp.set("v.detailMode", null);
        cmp.set("v.activeRecord", null);

        //checks if we're coming from the detail view
        cmp.set("v.activeRecordId", null);
    },

    /**
     * @description: filters row data based on user's selection of summary object
     */
    filterData: function(cmp, object) {
        var cachedRollupList = cmp.get("v.cachedRollupList");
        if(object === 'All'){
            cmp.set("v.rollupList", cachedRollupList);
        } else{
            var filteredRollupList = cachedRollupList.filter(function(rollup){
               return rollup.summaryObjectApiName === object;
            });
            cmp.set("v.rollupList", filteredRollupList);
        }
    },

    /**
     * @description: switches to selected grid with correct width after hearing cancel event from rollup or filter group detail
     */
    handleCancelDetailEvent: function(cmp, grid){
        //reset lastActiveRecordId in case user navigates from one detail component to another
        cmp.set("v.lastActiveRecordId", null);

        if (grid === 'rollup') {
            this.displayRollupsGrid(cmp);
            cmp.set("v.width", 12);
        } else if (grid === 'filterGroup') {
            this.displayFilterGroupsGrid(cmp);
            cmp.set("v.width", 12);
        }
    },

    /**
     * @description: handles the selection of a specific rollup from the filter group view and then return to filter group
     * @param message: passed in from the handleMessage
     */
    handleNavigateEvent: function(cmp, message) {
        //handles the selection of a specific rollup from the filter group view and then return to filter group
        cmp.set("v.activeRecordId", message.id);
        cmp.set("v.detailMode", 'view');
        cmp.set("v.width", 8);

        if (message.target === 'rollup') {
            cmp.set("v.lastActiveRecordId", message.lastId);
            cmp.set("v.isRollupDetail", true);
            cmp.set("v.isFilterGroupDetail", false);
        } else if (message.target === 'filterGroup'){
            cmp.set("v.lastActiveRecordId", null);
            cmp.set("v.isRollupDetail", false);
            cmp.set("v.isFilterGroupDetail", true);
        }
    },

    /**
     *  @description: merges and saves the updated row item into the existing list of rows
     *  @param list - list of items to merge into (this is the cached list for rollups)
     *  @param item - item to be merged into the list
     *  @param context - context running the merge
     */
    mergeRowItem: function(cmp, list, item, context) {
        var newItem = true;
        for (var i = 0; i < list.length; i++) {
            if (list[i].recordId === item.recordId) {
                //update filter group information on rollups only if master label has changed
                if (list[i].label !== item.label && context === 'filterGroup') {
                    this.requeryRollups(cmp);
                }
                //update filter group grid only if filter group reference on rollup has changed
                if (list[i].filterGroupName !== item.filterGroupName && context === 'rollup') {
                    this.requeryFilterGroups(cmp);
                }
                // if the Id matches, update that record
                list[i] = item;
                newItem = false;
                break;
            }
        }
        if (newItem) {
            list.push(item);
            if (context === 'rollup') {
                this.requeryFilterGroups(cmp);
            }
        }

        if (context === 'rollup') {
            this.resetRollupDataGrid(cmp, list);
        } else if (context === 'filterGroup') {
            cmp.set("v.filterGroupList", list);
        }
    },

    /**
     * @description: set an updated, sorted, unfiltered rollup list
     */
    resetRollupDataGrid: function(cmp, list) {
        var rollupList = JSON.parse(JSON.stringify(list));
        var sortedData = this.sortData(cmp, 'displayName', 'asc', rollupList);
        cmp.set("v.rollupList", sortedData);
        cmp.set("v.cachedRollupList", sortedData);
        cmp.set("v.filteredSummaryObject", "All");
    },

    /**
     * @description: sorts data by user's selected field and field direction
     */
    sortData: function(cmp, fieldName, sortDirection, data) {
        var reverse = sortDirection !== 'asc';
        data.sort(this.sortBy(fieldName, reverse));
        return data;
    },

    /**
     * @description: called by sortData, sorts by provided key and direction. Provided by Salesforce lightning:datatable documentation.
     */
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x[field])} :
            function(x) {return x[field]};
        //checks if the two rows should switch places
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    },

    /**
     * @description: toggles a modal popup and backdrop
     */
    toggleFilterRuleModal: function(cmp) {
        var backdrop = cmp.find('backdrop');
        $A.util.toggleClass(backdrop, 'slds-backdrop_open');
        var modal = cmp.find('modaldialog');
        $A.util.toggleClass(modal, 'slds-fade-in-open');
    },

    /**
     * @description: queries the filter groups to update the count of rollups after deleting
     */
    requeryFilterGroups: function(cmp) {
        var action = cmp.get("c.getFilterGroupDefinitions");

        //requery filter group records
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var filterGroupList = JSON.parse(JSON.stringify(response.getReturnValue()));

                cmp.set("v.filterGroupList", filterGroupList);
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.showToast(cmp, "error", cmp.get("v.labels.error"), errors[0].message);
                    }
                } else {
                    this.showToast(cmp, "error", cmp.get("v.labels.error"), "Unknown Error");
                }
            }
        });

        $A.enqueueAction(action);
    },

    /**
    * @description: queries the rollups to update filter group name references
    */
    requeryRollups: function(cmp) {
        var action = cmp.get("c.getRollupDefinitions");

        //requery rollup records
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var rollupList = JSON.parse(JSON.stringify(response.getReturnValue()));

                cmp.set("v.rollupList", rollupList);
                cmp.set("v.cachedRollupList", rollupList);
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.showToast(cmp, "error", cmp.get("v.labels.error"), errors[0].message);
                    }
                } else {
                    this.showToast(cmp, "error", cmp.get("v.labels.error"), "Unknown Error");
                }
            }
        });

        $A.enqueueAction(action);
    },

    /**
     * @description Show a message on the screen. Auto-hides success toasts after 5 seconds.
     * @param type - error, success, info
     * @param title - message title
     * @param message - message to display
     */
    showToast : function(cmp, type, title, message) {
        cmp.set("v.toastStatus", type);
        var altText = cmp.get("v.labels." + type);
        var text = {message: message, title: title, alternativeText: altText};
        cmp.set("v.notificationText", text);
        cmp.set("v.toastHideClass", "");

        if (type === 'success') {
            window.setTimeout(
                $A.getCallback(function() {
                    cmp.set("v.toastHideClass", "slds-hide");
                }), 5000
            );
        }
    },

    /**
     * @description Show or Hide the page spinner
     * @param showSpinner - true to show; false to hide
     */
    toggleSpinner : function(cmp, showSpinner) {
        var spinner = cmp.find("waitingSpinner");
        if (showSpinner === true) {
            $A.util.removeClass(spinner, "slds-hide");
        } else {
            $A.util.addClass(spinner, "slds-hide");
        }
    }
})