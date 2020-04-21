/*
    Copyright (c) 2019 Salesforce.org
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
* @date 2020
* @group Gift Entry
* @group-content ../../ApexDocContent/GiftEntry.htm
* @description Service to provide CRUD and FLS permission validations for form templates
*/
public with sharing class FORM_PermissionValidator {

    public enum AccessLevel {
        VALIDATE_READ, VALIDATE_CREATE, VALIDATE_UPDATE
    }
    
    public static final String OBJECT_CRUD_ERROR = 'CRUD';
    public static final String FLS_ERROR = 'FLS';
    public static final String FIELD_ELEMENT_TYPE = 'field';
    FORM_Template template;
    Set<AccessLevel> accessLevels;
    UTIL_Permissions permissionsService = UTIL_Permissions.getInstance();
    UTIL_Describe describeService = UTIL_Describe.getInstance();
    
    public FORM_PermissionValidator(FORM_Template template, Set<AccessLevel> accessLevels) {
        this.template = template;
        this.accessLevels = accessLevels;
    }

    /*******************************************************************************************************
    * @description Method for validating CRUD/FLS permissions for a template */

    public FORM_Template validateTemplate() {
        Map<String, Set<String>> permissionErrorsBySObject = new Map<String, Set<String>>();

        BDI_FieldMappingSet fieldMappings =  BDI_MappingServiceAdvanced.getInstance(true).fieldMappingSet;
        for (FORM_Section section : template.layout.sections) {
            for (FORM_Element element : section.elements) {

                if (element.elementType == FIELD_ELEMENT_TYPE) {
                    for (String fieldDevName : element.dataImportFieldMappingDevNames) {
                        if(fieldMappings.fieldMappingByDevName.containsKey(fieldDevName)) {
                            BDI_FieldMapping fieldMapping = fieldMappings.fieldMappingByDevName.get(fieldDevName);
                            
                            String targetObjDevName = fieldMapping.Target_Object_API_Name;
                            String targetFieldDevName = fieldMapping.Target_Field_API_Name;
                            String sourceObjDevName = Schema.SObjectType.DataImport__c.getName();
                            String sourceFieldDevName = fieldMapping.Source_Field_API_Name;

                            if(!isValid(sourceObjDevName, accessLevels)) {
                                permissionErrorsBySObject.put(sourceObjDevName, new Set<String>{OBJECT_CRUD_ERROR});
                            }

                            if(!isValid(targetObjDevName, accessLevels)) {
                                permissionErrorsBySObject.put(targetObjDevName, new Set<String>{OBJECT_CRUD_ERROR});
                            }

                            if(!isValid(sourceObjDevName, sourceFieldDevName, accessLevels)) {
                                if(permissionErrorsBySObject.containsKey(sourceObjDevName)) {
                                    permissionErrorsBySObject.get(sourceObjDevName).add(sourceFieldDevName);
                                } else {
                                    permissionErrorsBySObject.put(sourceObjDevName, new Set<String>{sourceFieldDevName});
                                }
                            }
                            
                            if(!isValid(targetObjDevName, targetFieldDevName, accessLevels)) {
                                if(permissionErrorsBySObject.containsKey(targetObjDevName)) {
                                    permissionErrorsBySObject.get(targetObjDevName).add(targetFieldDevName);
                                } else {
                                    permissionErrorsBySObject.put(targetObjDevName, new Set<String>{targetFieldDevName});
                                }
                            }
                        }
                    }
                }
            }
        }
        handlePermissionsErrors(permissionErrorsBySObject);
        return template;
    }

    /*******************************************************************************************************
    * @description Perform CRUD validation on an SObject
    * @param objDevName - the API name of the SObject to validate
    * @param accessLevels - the levels of access to validate on the SObject
    */
    private Boolean isValid(String objDevName, Set<AccessLevel> accessLevels) {

        SObjectType objType = ((SObject) Type.forName(objDevName).newInstance()).getSObjectType();
        
        if((accessLevels.contains(AccessLevel.VALIDATE_CREATE)
            && !permissionsService.canCreate(objType))
            || (accessLevels.contains(AccessLevel.VALIDATE_READ)
            && !permissionsService.canRead(objType))
            || (accessLevels.contains(AccessLevel.VALIDATE_UPDATE)
            && !permissionsService.canUpdate(objType))
        ) {
            return false;
        } else {
            return true;
        }
    }

    /*******************************************************************************************************
    * @description Perform FLS validation on an SObject field
    * @param objDevName - the API name of the SObject
    * @param fieldDevName - the API name of the SObject field to validate
    * @param accessLevels - the levels of access to validate on the SObject
    */
    private Boolean isValid(String objDevName, String fieldDevName, Set<AccessLevel> accessLevels) {

        SObjectType objectType = UTIL_Describe.getSObjectType(objDevName);
        SObjectField objField = objectType.getDescribe().fields.getMap().get(fieldDevName);
        Set<SObjectField> fields = new Set<SObjectField>{objField};

        if((accessLevels.contains(AccessLevel.VALIDATE_CREATE)
            && !permissionsService.canCreate(fields))
            || (accessLevels.contains(AccessLevel.VALIDATE_READ)
            && !permissionsService.canRead(fields))
            || (accessLevels.contains(AccessLevel.VALIDATE_UPDATE)
            && !isValidateUpdateException(objectType, objField))
        ) {
            return false;
        } else {
            return true;
        }
    }

    /**********************************************************************************************************
    * @description Performs FLS update validation, taking master-detail relationships and campaign lookups into account 
    * @param objectType - SObjectType of the object
    * @param field - SObjectField type to validate
    */
    private Boolean isValidateUpdateException(SObjectType objectType, SObjectField field) {
        if (describeService.isMasterDetailField(field)) {
            return true;
        } else {
            if (objectType == CampaignMember.SObjectType
                    && field == CampaignMember.CampaignId) {
                return true;
            } else if (permissionsService.canUpdate(new Set<SObjectField>{field})) {
                return true;
            }
        }
        return false;
    }

    /*******************************************************************************************************
    * @description Format any CRUD or FLS errors for display in UI
    * @param permissionErrorsBySObject - a map of all permission errors by SObject
    */
    private void handlePermissionsErrors(Map<String, Set<String>> permissionErrorsBySObject) {
        
        Set<String> crudErrors = new Set<String>();
        Map<String, Set<String>> flsErrors = new Map<String, Set<String>>();

        // The map will contain only the object key if there is a CRUD error
        for (String objDevName : permissionErrorsBySObject.keySet()) {
            if(permissionErrorsBySObject.get(objDevName).contains(OBJECT_CRUD_ERROR)) {
                crudErrors.add(objDevName);
            }
        }
        if(!crudErrors.isEmpty()) {
            template.permissionErrorType = OBJECT_CRUD_ERROR;
            template.permissionErrors = String.join(new List<String>(crudErrors), ', ');
        } else if(crudErrors.isEmpty() && !permissionErrorsBySObject.values().isEmpty()){
            template.permissionErrorType = FLS_ERROR;
            template.permissionErrors = formatFLSError(permissionErrorsBySObject);
        }
    }

    /*******************************************************************************************************
    * @description Format FLS errors for the UI in a readable format, pairing all fields with their                associated SObject
    * @param permissionErrorsBySObject - map of all FLS fields in error with their associated SObject
    */
    private static String formatFLSError(Map<String, Set<String>> permissionErrorsBySObject) {
        String message;
        if(!permissionErrorsBySObject.isEmpty()) {
            message = '';
            List<String> crudErrors = new List<String>();
            for (String objDevName : permissionErrorsBySObject.keySet()) {
                List<String> errors = new List<String>(permissionErrorsBySObject.get(objDevName));
                crudErrors.add(objDevName + ': (' + String.join(errors, ', ') + ')');
            }
            message += String.join(crudErrors, ', ');
        }
        return message;
    }

}
