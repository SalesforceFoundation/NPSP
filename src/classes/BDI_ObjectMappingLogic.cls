public with sharing virtual class BDI_ObjectMappingLogic {

    public virtual BDI_ObjectWrap[] populateObjects(BDI_ObjectWrap[] objWraps) {
        if (objWraps == null) {
            return objWraps;
        }

        for (BDI_ObjectWrap objWrap : objWraps) {
            Map<String, Schema.DescribeFieldResult> fieldDescribeMap = UTIL_Describe.getAllFieldsDescribe(UTIL_Namespace.adjustNPSPNamespace(objWrap.objMapping.Object_API_Name__c));
            System.debug('fieldDescribeMap is: ' + fieldDescribeMap.keySet());
            objWrap.sObj = Schema.getGlobalDescribe().get(UTIL_Namespace.adjustNPSPNamespace(objWrap.objMapping.Object_API_Name__c)).newSObject();

            if (objWrap.existingSobjectId != null) {
                objWrap.sObj.put('Id', objWrap.existingSobjectId);
            }

            for (Data_Import_Field_Mapping__mdt fieldMapping : objWrap.fieldMappings) {
                String sourceFieldName = UTIL_Namespace.adjustNPSPNamespace(fieldMapping.Source_Field_API_Name__c);
                String targetFieldName = UTIL_Namespace.adjustNPSPNamespace(fieldMapping.Target_Field_API_Name__c);
                
                Schema.DescribeFieldResult targetDescribe = fieldDescribeMap.get(targetFieldName.toLowerCase());
                System.debug('Target Describe field name: ' + targetFieldName);
                System.debug('Target Describe is: ' + targetDescribe);
                System.debug('Target Describe accessible: ' + targetDescribe.isAccessible());
                System.debug('Target Describe isUpdateable: ' + targetDescribe.isUpdateable());
                System.debug('Target Describe existingSobjectId: ' + objWrap.existingSobjectId);
                System.debug('Target Describe sobj Id: ' + objWrap.sObj.Id );
                //Confirm that it is real field, and that it is accessible to the running user.
                if (targetDescribe != null && targetDescribe.isAccessible()) {
                    //Confirm that either the sObj Id is null (ie new record) or that the field is updatable if it is not new.
                    if (objWrap.sObj.Id == null || targetDescribe.isUpdateable()) {
                        System.debug('Passed checks for field update with: ' + targetFieldName);
                        Object value = objWrap.di.get(sourceFieldName);
                        System.debug('Value is: ' + value);
                        //only copy values that are not null to avoid overwriting data when updating existing sobjects.
                        if (value != null) {
                            objWrap.sObj.put(targetFieldName,value);
                        }
                    }
                }

            } 
        }
        return objWraps;
    }
}