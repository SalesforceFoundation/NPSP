({
	init : function(component, event, helper) {

        // Prepare a new record from template
        component.find("dataImportRecordCreator").getNewRecord(
            "DataImport__c", // sObject type (entityApiName)
            null,      // recordTypeId
            false,     // skip cache?
            $A.getCallback(function() {
                var rec = component.get("v.newDataImport");
                var error = component.get("v.dataImportError");
                if(error || (rec === null)) {
                    console.log("Error initializing record template: " + error);
                    return;
                }
                console.log("Record template initialized: " + rec.sobjectType);

            })
        );

	}
})