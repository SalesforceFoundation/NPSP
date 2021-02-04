/*
    Copyright (c) 2019, Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2019
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Service class used to validate
* Field Level Security of the target fields mapped in the data import process.
*/
public class BDI_DataImportFLSService {
    Set<AccessLevel> accessLevels;
    Map<SObjectField, BDI_TargetFields> targetFieldsBySObjectFields;
    List<DataImport__c> dataImportsValidated;
    List<DataImport__c> dataImportsInvalidated;
    Map<Id, List<SObjectFieldWrapper>> invalidFieldsByDataImportId;
    UTIL_Describe describeService;
    UTIL_Permissions permissionsService;

    public enum AccessLevel {
        VALIDATE_READ, VALIDATE_CREATE, VALIDATE_UPDATE
    }

    public BDI_DataImportFLSService (Set<AccessLevel> accessLevels){
        this.accessLevels = accessLevels;
        describeService = UTIL_Describe.getInstance();
        permissionsService = UTIL_Permissions.getInstance();
    }

    public BDI_DataImportFLSService(List<DataImport__c> dataImports,
            BDI_MappingService mappingService,
            Set<AccessLevel> accessLevels){
        this.accessLevels = accessLevels;
        this.targetFieldsBySObjectFields = mappingService.getTargetFieldsBySourceField();
        this.dataImportsValidated = new List<DataImport__c>();
        this.dataImportsInvalidated = new List<DataImport__c>();
        this.invalidFieldsByDataImportId = new Map<Id, List<SObjectFieldWrapper>>();
        describeService = UTIL_Describe.getInstance();
        permissionsService = UTIL_Permissions.getInstance();
        validateTargetMappingFieldLevelSecurity(dataImports);
    }

    public List<DataImport__c> getValidRecords() {
        return dataImportsValidated;
    }

    public List<DataImport__c> getInvalidRecords() {
        return dataImportsInvalidated;
    }

    public List<String> getQualifiedInvalidFieldNamesById(Id dataImportId) {
        List<String> qualifiedInvalidFieldNames = new List<String>();
        for (SObjectFieldWrapper fieldWrapper :
                invalidFieldsByDataImportId.get(dataImportId)) {
            qualifiedInvalidFieldNames.add(fieldWrapper.getQualifiedName());
        }
        return qualifiedInvalidFieldNames;
    }

    private void validateTargetMappingFieldLevelSecurity(List<DataImport__c> dataImportsInitial) {
        for (DataImport__c dataImport : dataImportsInitial) { //Loop DIs
            String sourceObjectName = DataImport__c.SObjectType.getDescribe().getName();

            List<SObjectFieldWrapper> invalidFields = new List<SObjectFieldWrapper>();
            for (String dataImportFieldName : dataImport.getPopulatedFieldsAsMap().keySet()) {
                String relationshipFieldName;
                if (dataImportFieldName.endsWith('__r')) {
                    //getPopulatedFieldsAsMap() will return a field name ending in "__r" if a
                    //lookup field is populated with an in-memory object. Replacing it with
                    //"__c" ensures that the call to UTIL_Describe.getFieldDescribe will
                    //succeed and validate the field appropriately.
                    relationshipFieldName = dataImportFieldName.replace('__r', '__c');
                }

                String fieldName =
                        relationshipFieldName != null ?
                                relationshipFieldName :
                                dataImportFieldName;

                SObjectField sourceSObjectField =
                        UTIL_Describe.getFieldDescribe(
                                sourceObjectName,
                                fieldName).getSobjectField();

                BDI_TargetFields targetFields = targetFieldsBySObjectFields.get(sourceSObjectField);

                if (targetFields == null) { //this source field is unmapped
                    continue;
                }

                //Now loop through all of the target object + field combos for this source field
                Map<SObjectType, Set<SObjectField>> targetFieldsByObject =
                        targetFields.getTargetFieldsByTargetObject();

                for (SObjectType objectType : targetFieldsByObject.keySet()) {
                    for (SObjectField field : targetFieldsByObject.get(objectType)) {
                        if (!isValid(objectType, field)) {
                            invalidFields.add(
                                    new SObjectFieldWrapper(
                                            objectType,
                                            field
                                    )
                            );
                        }
                    }//END loop of mapped target fields for this target object
                }//END loop of mapped target objects
            }//END loop of populated Data Import fields

            if (invalidFields.size() > 0) {
                dataImportsInvalidated.add(dataImport);
                invalidFieldsByDataImportId.put(dataImport.Id, invalidFields);
            } else {
                dataImportsValidated.add(dataImport);
            }
        }//END loop of Data Import records
    }

    @TestVisible
    private Boolean isValid(SObjectType objectType, SObjectField field) {
        Set<SObjectField> fieldSet = new Set<SObjectField>{
                field
        };
        if ((accessLevels.contains(AccessLevel.VALIDATE_CREATE)
                && !permissionsService.canCreate(fieldSet))
                ||
                (accessLevels.contains(AccessLevel.VALIDATE_UPDATE)
                        && !isValidateUpdateException(objectType, field))
                ||
                (accessLevels.contains(AccessLevel.VALIDATE_READ)
                        && !permissionsService.canRead(fieldSet))) {
            return false;
        } else {
            return true;
        }
    }


    private Boolean isValidateUpdateException(SObjectType objectType, SObjectField field) {
        if (describeService.isMasterDetailField(field)) {
            return true;
        } else {
            if (objectType == CampaignMember.SObjectType
                    && field == CampaignMember.CampaignId) {
                return true;
            }else if (permissionsService.canUpdate(new Set<SObjectField>{field})) {
                return true;
            }
        }
        return false;
    }

    private class SObjectFieldWrapper {

        SObjectType sObjType;
        SObjectField field;

        SObjectFieldWrapper(SObjectType obj, SObjectField field) {
            this.sObjType = obj;
            this.field = field;
        }

        String getQualifiedName() {
            return sObjType.getDescribe().getName() + '.' + field.getDescribe().getName();
        }
    }
}
