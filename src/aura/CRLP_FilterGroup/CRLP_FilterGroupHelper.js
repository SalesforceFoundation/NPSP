({
    /* @description: changes field visibility and save button access based on the mode
    * this is bound to a change handler to the mode attribute
    */
    changeMode: function(cmp){
        var mode = cmp.get("v.mode");
        //we check to see if mode is null since the change handler is called when mode is cleared in the container
        if (mode) {
            console.log("Mode is " + mode);
            console.log("In changeMode");

            //View is the only readOnly mode. Clone removes the activeRollupId for save.
            //Create hides all fields
            if (mode === "view") {
                cmp.set("v.isReadOnly", true);
            } else if (mode === "clone") {
                cmp.set("v.activeFilterGroupId", null);
                cmp.set("v.isReadOnly", false);
            } else if (mode === "edit") {
                cmp.set("v.isReadOnly", false);
            } else if (mode === "create") {
                cmp.set("v.isReadOnly", false);
            }
        }
    },

    /* @description: closes modal popup
     */
    closeFilterRuleModal: function(cmp){
        var backdrop = cmp.find('backdrop');
        $A.util.removeClass(backdrop, 'slds-backdrop_open');
        var modal = cmp.find('modaldialog');
        $A.util.removeClass(modal, 'slds-fade-in-open');
    },

    /* @description: filters the full rollup data to find which rollups use a particular filter group
    * @param filterGroupLabel: label of the selected filter group
    * @param labels: labels for the rollups UI
    */
    filterRollupList: function(cmp, filterGroupLabel, labels){
        //filters row data based selected filter group
        var rollupList = cmp.get("v.rollupList");
        var filteredRollupList = rollupList.filter(function(rollup){
            return rollup.filterGroupName === filterGroupLabel;
        });

        //todo: should summary obj be dynamic?
        var rollupsBySummaryObj = [{label: labels.labelAccount, list: []}
                                , {label: labels.labelContact, list: []}
                                , {label: labels.labelGAU, list: []}];
        var itemList = [];

        //filter rollup list by type
        filteredRollupList.forEach(function (rollup){
            var item = {label: rollup.rollupName, name: rollup.id};
            if(rollup.summaryObject === labels.labelAccount){
                rollupsBySummaryObj[0].list.push(item);
            } else if (rollup.summaryObject === labels.labelContact){
                rollupsBySummaryObj[1].list.push(item);
            } else if (rollup.summaryObject === labels.labelGAU){
                rollupsBySummaryObj[2].list.push(item);
            }
        });

        //only add object to list if there are rollups with matching summary objects
        rollupsBySummaryObj.forEach(function(objList){
           if(objList.list.length > 1){
               var obj = {label: objList.label
                         , name: "title"
                         , expanded: false
                         , items: objList.list
               };
               itemList.push(obj);

           }
        });

        cmp.set("v.rollupItems", itemList);
    },

    /* @description: opens a modal popup to warn user about
     */
    openFilterRuleDeleteModal: function(cmp, row){
        if(row){
            //editing rule

        } else {
            //adding new rule

        }
    },

    /* @description: opens a modal popup so user can add or edit a filter rule
     */
    openFilterRuleModal: function(cmp){
        var backdrop = cmp.find('backdrop');
        $A.util.addClass(backdrop, 'slds-backdrop_open');
        var modal = cmp.find('modaldialog');
        $A.util.addClass(modal, 'slds-fade-in-open');
    },

    /* @description: opens a modal popup so user can add or edit a filter rule
     */
    resetActiveFilterRule: function(cmp){
        cmp.set("v.activeFilterRule", "{objectName: '', fieldName: '', operatorName: '', constant: ''}");
        cmp.set("v.filteredFields", "");
    },

    /* @description: restructures returned Apex response to preserve separate variables
    * @return: the parsed and stringified JSON
    */
    restructureResponse: function (resp) {
        return JSON.parse(JSON.stringify(resp));
    },

    /* @description: retrieves the label of an entity (field, operation, etc) based on the api name from a LIST of objects with name and label entries
    * @param apiName: the name of the field
    * @param entityList: list of fields to search
    * @return label: field label that matches the apiName
    */
    retrieveFieldLabel: function (apiName, entityList) {
        var label;
        if (entityList) {
            for (var i = 0; i < entityList.length; i++) {
                if (entityList[i].name === apiName) {
                    label = entityList[i].label;
                    break;
                }
            }
        }
        return label;
    },

    /* @description: verifies all required fields have been populated before saving the filter group
     */
    validateFilterGroupFields: function(cmp){
        var canSave = true;
        var name = cmp.get("v.activeFilterGroup.MasterLabel");
        var description = cmp.get("v.activeFilterGroup.Description__c");
        var filterRuleList = cmp.get("v.filterRuleList");

        cmp.find("nameInput").showHelpMessageIfInvalid();
        cmp.find("descriptionInput").showHelpMessageIfInvalid();
        //todo: where to put error message for filter rules? or can a filter group be saved w/o filter rules?

        if(!description){
            canSave = false;
        } else if(!name){
            canSave = false;
        } else if(filterRuleList.length === 0){
            canSave = false;
        }

        return canSave;
    }
})