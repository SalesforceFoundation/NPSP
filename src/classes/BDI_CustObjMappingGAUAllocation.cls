public with sharing class BDI_CustObjMappingGAUAllocation extends BDI_ObjectMappingLogic {

    public override BDI_ObjectWrap[] populateObjects(BDI_ObjectWrap[] objWraps) {

        Allocations_Settings__c settings = UTIL_CustomSettingsFacade.getAllocationsSettings();

        System.debug('BDI_CustObjMappingGAUAllocation ');
        String PAYMENT_FN = 'npsp__Payment__c';
        String OPPORTUNITY_FN = 'npsp__Opportunity__c';
        String CAMPAIGN_FN = 'npsp__Campaign__c';

        for (BDI_ObjectWrap objWrap : objWraps) {
            Map<String, Schema.DescribeFieldResult> fieldDescribeMap = UTIL_Describe.getAllFieldsDescribe(UTIL_Namespace.adjustNPSPNamespace(objWrap.objMapping.Object_API_Name__c));

            objWrap.sObj = Schema.getGlobalDescribe().get(UTIL_Namespace.adjustNPSPNamespace(objWrap.objMapping.Object_API_Name__c)).newSObject();

            if (objWrap.existingSobjectId != null) {
                objWrap.sObj.put('Id', objWrap.existingSobjectId);
            }

            Object campaignValue;
            Object paymentValue;
            Object opportunityValue;

            for (Data_Import_Field_Mapping__mdt fieldMapping : objWrap.fieldMappings) {
                String sourceFieldName = UTIL_Namespace.adjustNPSPNamespace(fieldMapping.Source_Field_API_Name__c);
                String targetFieldName = UTIL_Namespace.adjustNPSPNamespace(fieldMapping.Target_Field_API_Name__c);
                Object value = objWrap.di.get(sourceFieldName);

                Schema.DescribeFieldResult targetDescribe = fieldDescribeMap.get(targetFieldName.toLowerCase());

                //Confirm that it is real field, and that it is accessible to the running user.
                if (targetDescribe != null && targetDescribe.isAccessible()) {
                    //Confirm that either the sObj Id is null (ie new record) or that the field is updatable if it is not new.
                    if (objWrap.sObj.Id == null || targetDescribe.isUpdateable()) {
                        // If the target field mapping is one of the key parent objects, then extract the values for later logic
                        if (fieldMapping.Target_Field_API_Name__c == PAYMENT_FN) {
                            paymentValue = value;
                        } else if (fieldMapping.Target_Field_API_Name__c == OPPORTUNITY_FN) {
                            opportunityValue = value;
                        } else if (fieldMapping.Target_Field_API_Name__c == CAMPAIGN_FN) {
                            campaignValue = value;
                        } else {
                            //only copy values that are not null to avoid overwriting data when updating existing sobjects.
                            if (value != null) {
                                objWrap.sObj.put(UTIL_Namespace.adjustNPSPNamespace(fieldMapping.Target_Field_API_Name__c),value);
                            }
                        }
                    }
                }
            }

            // If the payment is specified and payment allocations are enabled, always use that first.
            if ( paymentValue != null && settings.Payment_Allocations_Enabled__c) {
                objWrap.sObj.put(UTIL_Namespace.adjustNPSPNamespace(PAYMENT_FN),paymentValue);
            } else if ( opportunityValue != null ) {
                objWrap.sObj.put(UTIL_Namespace.adjustNPSPNamespace(OPPORTUNITY_FN),opportunityValue);
            } else if ( campaignValue != null ) { 
                objWrap.sObj.put(UTIL_Namespace.adjustNPSPNamespace(CAMPAIGN_FN),campaignValue);
            }

            System.debug('BDI_CustObjMappingGAUAllocation at end SObj is: ' + objWrap.sObj);
        }
        return objWraps;
    }
}