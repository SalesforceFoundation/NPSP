({
    /**
     * @description: fired on each init of rollup
     *   queries active rollup ID to populate the full active rollup detail
     *   sets operations and object details
     */
    doInit: function (cmp, event, helper) {
        helper.toggleSpinner(cmp, true);
        var labels = cmp.get("v.labels");
        var detailObjects = cmp.get("v.detailObjects");
        var summaryObjects = cmp.get("v.summaryObjects");
        cmp.set("v.detailObjects", detailObjects);

        //put only the object names into a list
        var summaryNames = summaryObjects.map(function (summaryObj, index, array) {
            return summaryObj.name;
        });
        var detailNames = detailObjects.map(function (detailObj, index, array) {
            return detailObj.name;
        });

        var activeRollupId = cmp.get("v.activeRollupId");
        if (activeRollupId === null) {
            activeRollupId = '';
        }
        var action = cmp.get("c.setupRollupDetail");

        action.setParams({ rollupId: activeRollupId, targetObjectNames: summaryNames, detailObjectNames: detailNames });

        action.setCallback(this, function (response) {
            var state = response.getState();
            var labels = cmp.get("v.labels");

            if (state === "SUCCESS") {
                var data = response.getReturnValue();
                var model = JSON.parse(data);
                if (activeRollupId) {
                    // detail, amount, and date fields need to be held on client side
                    // with their object name to support multiple object selection

                    model.rollup.detailField = model.rollup.detailObject + ' ' + model.rollup.detailField;
                    model.rollup.detailFieldLabel = model.rollup.detailObjectLabel.replace(labels.labelPartialSoftCredit, labels.softCredit) + ': ' + model.rollup.detailFieldLabel;
                    model.rollup.amountField = model.rollup.amountObject + ' ' + model.rollup.amountField;
                    model.rollup.amountFieldLabel = helper.retrieveFieldLabel(model.rollup.amountObject, detailObjects).replace(labels.labelPartialSoftCredit, labels.softCredit) + ': ' + model.rollup.amountFieldLabel;
                    model.rollup.dateField = model.rollup.dateObject + ' ' + model.rollup.dateField;
                    model.rollup.dateFieldLabel = helper.retrieveFieldLabel(model.rollup.dateObject, detailObjects) + ': ' + model.rollup.dateFieldLabel;

                    //note: the duplicate parsing is important to avoid a shared reference
                    cmp.set("v.activeRollup", helper.restructureResponse(model.rollup));
                    cmp.set("v.cachedRollup", helper.restructureResponse(model.rollup));
                }

                var tOps = [];
                for (var j in model.timeBoundOperations) {
                    tOps.push({ name: j, label: model.timeBoundOperations[j] });
                }
                tOps.sort(function (a, b) {
                    return a.name > b.name;
                });
                cmp.set("v.timeBoundOperations", tOps);
                cmp.set("v.operations", model.operations);
                cmp.set("v.objectDetails", model.fieldsByDataType);

                //change mode needs to be fired here because the sibling change of mode isn't being registered
                helper.changeMode(cmp);
                helper.setObjectAndFieldDependencies(cmp);

            }
            else if (state === "ERROR") {
                var errors = response.getError();
                var msg = labels.unknownError;
                if (errors && errors[0] && errors[0].message) {
                    msg = errors[0].message;
                }
                helper.showToast(cmp, 'error', labels.rollupDisplayError, msg);
            }
            helper.toggleSpinner(cmp, false);
        });

        $A.enqueueAction(action);
    },

    /**
     * @description: fires when mode is changed
     */
    onChangeMode: function (cmp, event, helper) {
        helper.changeMode(cmp);
    },

    /**
     * @description: fires when cancel button is clicked
     * options for cancel: return to rollup summaries or return to view
     * if mode is clone or create and ID is null the user returns to the grid
     * else resets mode to view to become display-only and resets rollup values
     */
    onCancel: function (cmp, event, helper) {
        var cachedRollup = cmp.get("v.cachedRollup");
        //check for cachedRollup to avoid JS errors getting a null .valueOf()
        if (!cmp.get("v.activeRollupId") || !cachedRollup) {
            //set off cancel event for container
            helper.sendMessage(cmp, 'cancelEvent', { grid: 'rollup' });
        } else if (cmp.get("v.mode") === 'delete') {
            helper.toggleModal(cmp);
            cmp.set("v.mode", "view");
        } else {
            cmp.set("v.mode", "view");
            //json shenanigans to avoid shared reference
            cmp.set("v.activeRollup", helper.restructureResponse(cachedRollup.valueOf()));
            //reset all field visibility and values
            helper.fieldSetup(cmp);
        }
    },

    /**
     * @description: fires when save button is clicked
     */
    onSave: function (cmp, event, helper) {
        var activeRollup = cmp.get("v.activeRollup");
        if (cmp.get("v.mode") === 'delete') {
            helper.toggleModal(cmp);
            helper.saveRollup(cmp, activeRollup);
        } else if (helper.validateFields(cmp)) {
            helper.saveRollup(cmp, activeRollup);
            cmp.set("v.mode", 'view');
            helper.updateRollupName(cmp);
        }
    },

    /**
     * @description: listens for a message from the select field cmp to trigger a change in the rollup information
     * fields are IDed by their camelcase names. ex: Summary_Object__c is summaryObject
     */
    onSelectValueChange: function (cmp, event, helper) {
        var message = event.getParam("message");
        var channel = event.getParam("channel");
        if (channel === 'selectField') {
            var fieldName = message[0];
            var value = message[1];
            var label = message[2];

            if (fieldName === 'summaryObject') {
                helper.onChangeSummaryObject(cmp, value, label);
            } else if (fieldName === 'summaryField') {
                helper.onChangeSummaryField(cmp, value, label);
            } else if (fieldName === 'operation') {
                helper.onChangeOperation(cmp, value);
            } else if (fieldName === 'timeBoundOperationType') {
                helper.onChangeTimeBoundOperationsOptions(cmp, true, label);
            } else if (fieldName === 'integer') {
                helper.onChangeInteger(cmp, value);
            } else if (fieldName === 'rollupType') {
                helper.onChangeRollupType(cmp, value, label);
            } else if (fieldName === 'filterGroup') {
                helper.onChangeFilterGroup(cmp, label);
            } else if (fieldName === 'detailField') {
                helper.onChangeDetailField(cmp, value, label);
            } else if (fieldName === 'amountField') {
                cmp.set("v.activeRollup.amountFieldLabel", label);
            } else if (fieldName === 'dateField') {
                helper.onChangeDateField(cmp, value, label);
            }
        }
    }

})