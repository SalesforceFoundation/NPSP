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
public class BDI_DataImportFLSService implements BDI_FieldLevelSecurityService {
    Set<BDI_FieldLevelSecurityAccessLevel> accessLevels;
    Map<SObjectField, BDI_TargetFields> fieldMap;
    List<DataImport__c> dataImportsValidated;
    List<DataImport__c> dataImportsInvalidated;
    Map<Id, List<BDI_SObjectFieldWrapper>> invalidFieldsByDataImportId;

    public BDI_DataImportFLSService(List<DataImport__c> dataImports,
            BDI_FieldMapping fieldMap,
            Set<BDI_FieldLevelSecurityAccessLevel> accessLevels){
        this.accessLevels = accessLevels;
        this.fieldMap = fieldMap.getTargetFieldsBySourceField();
        this.dataImportsValidated = new List<DataImport__c>();
        this.dataImportsInvalidated = new List<DataImport__c>();
        this.invalidFieldsByDataImportId = new Map<Id, List<BDI_SObjectFieldWrapper>>();
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
        for (BDI_SObjectFieldWrapper fieldWrapper : invalidFieldsByDataImportId.get(dataImportId)) {
            qualifiedInvalidFieldNames.add(fieldWrapper.getQualifiedName());
        }
        return qualifiedInvalidFieldNames;
    }

    void validateTargetMappingFieldLevelSecurity(List<DataImport__c> dataImportsInitial) {
        for (DataImport__c dataImport : dataImportsInitial) { //Loop DIs
            String sourceObjectName = DataImport__c.SObjectType.getDescribe().getName();

            List<BDI_SObjectFieldWrapper> invalidFields = new List<BDI_SObjectFieldWrapper>();
            for (String dataImportFieldName : dataImport.getPopulatedFieldsAsMap().keySet()) { //Loop populated fields
                SObjectField sourceSObjectField = UTIL_Describe.getFieldDescribe(sourceObjectName, dataImportFieldName).getSobjectField();

                BDI_TargetFields targetFields = fieldMap.get(sourceSObjectField);

                if (targetFields == null) { //this source field is unmapped
                    continue;
                }

                //Now loop through all of the target object + field combos for this source field
                Map<SObjectType, Set<SObjectField>> targetFieldsByObject = targetFields.getTargetFieldsByTargetObject();
                for (SObjectType objectType : targetFieldsByObject.keySet()) {
                    for (SObjectField field : targetFieldsByObject.get(objectType)) {
                        if (!isValid(field)) {
                            invalidFields.add(
                                    new BDI_SObjectFieldWrapper(
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

    Boolean isValid(SObjectField field) {
        if ((accessLevels.contains(BDI_FieldLevelSecurityAccessLevel.VALIDATE_CREATE)
                && !field.getDescribe().isCreateable())
                ||
                (accessLevels.contains(BDI_FieldLevelSecurityAccessLevel.VALIDATE_UPDATE)
                        && !field.getDescribe().isUpdateable())
                ||
                (accessLevels.contains(BDI_FieldLevelSecurityAccessLevel.VALIDATE_READ)
                        && !field.getDescribe().isAccessible())) {
            return false;
        } else {
            return true;
        }
    }
}