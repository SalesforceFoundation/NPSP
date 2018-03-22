({

     locationChange : function(component, event, helper) {

         helper.getBatches(component);
     },

     pageChange: function(component, event, helper) {
         var page = component.get("v.page") || 1;
         var direction = event.getParam("direction");
         page = direction === "previous" ? (page - 1) : (page + 1);
         helper.getBatches(component, page);
     },

     nextToEnterData : function(component, event, helper) {

         var batchId = component.get("v.batchId");
         var batch = component.get("v.selectedBatch");

         if (batchId != null && batch != null) {

            var hasTemplate = component.get("v.hasTemplateSelected");
            // If the Batch has an associated template
            if (hasTemplate) {

                $A.createComponent(
                    "c:BatchDataEntryPOCGrid",
                    {"batchId": component.get("v.batchId"),
                        "batchName": batch.Name},

                    function(newComp) {

                        var content = component.find("body");
                        content.set("v.body", newComp);
                });
            }
            else{
                // When selecting a Batch with no template associated through BGE, flow will redirect user to select one.
                $A.createComponent(
                    "c:BGE_TemplateSelection",{
                        'showTemplateSelection': true,
                        'showProgressBar': true,
                        'processStage': 'selectBatchStage',
                        'associatedBatch': batch
                    },

                    function (newComp) {

                        var content = component.find("body");
                        content.set("v.body", newComp);
                    }
                );
            }
         }
         else {
             component.set("v.warnings", "You must select a Batch to click Next");
         }
     },

     searchKeyChange: function(component, event) {
         var searchKey = event.getParam("searchKey");
         var action = component.get("c.findByName");
         action.setParams({
           "searchKey": searchKey
         });

         // Clean batch Id
         component.set("v.batchId", null);

         if (searchKey == '') {
             component.set("v.hasBatches", false);
         }
         else {
             action.setCallback(this, function(a) {
                 component.set("v.batches", a.getReturnValue());
                 component.set("v.hasBatches", true);
             });
             $A.enqueueAction(action);
         }
     },
     setSelectedBatch: function(component, event, helper) {

         var batchRecord = event.getParam("batch");

         component.set("v.batchId", batchRecord.Id);
         component.set("v.selectedBatch", batchRecord);
         component.set("v.hasTemplateSelected", batchRecord.Batch_Template__c);
     },

    nextToInitial : function(component, event, helper) {

		$A.createComponent(
			"c:BGE_Initial",
			{},

			function(newComp) {
			var content = component.find("body");
			content.set("v.body", newComp);
		});
	},

})