/*
    Copyright (c) 2020, Salesforce.org
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
* @group BGE
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Class to hold functionality related to Gift Entry Templates.
*/

public with sharing class GE_Template {
    static final String TEMPLATE_VERSION = '1.0';
    static final String FIELD_ELEMENT_TYPE = 'field';
    private static FieldMappings mappings = FieldMappings.newInstance();

    /**
     * @description This method determines if there is a default template, 
     * if not, it will create a new template and update the custom setting with 
     * the newly created template's ID as the default template. 
     *
     */
    public static void createDefaultTemplateIfNecessary() {
        // TODO: Should also block template creation if Advanced Mapping is not enabled
        if (giftEntryIsEnabled() && !hasDefaultTemplate()) {
            Form_Template__c newDefaultTemplate = buildDefaultTemplate();
            
            insert newDefaultTemplate;

            Gift_Entry_Settings__c giftEntryCustomSetting = UTIL_CustomSettingsFacade.getGiftEntrySettings();
            giftEntryCustomSetting.Default_Gift_Entry_Template__c = newDefaultTemplate.Id;

            update giftEntryCustomSetting;
        }
    }

    /**
     * @description This method determines if there is an existing default template.  
     *
     * @return Returns whether or not there is an existing default template. 
     */
    private static Boolean hasDefaultTemplate() {
            
        // Get the gift entry custom setting to check for the default template.             
        Gift_Entry_Settings__c giftEntryCustomSetting = UTIL_CustomSettingsFacade.getGiftEntrySettings();

        if (giftEntryCustomSetting.Default_Gift_Entry_Template__c != null && 
            giftEntryCustomSetting.Default_Gift_Entry_Template__c != '') {
            
            // If there is an ID already stored, try to get this particular template. 
            List<Form_Template__c> templateList = [SELECT 
                        Id, 
                        Name 
                FROM Form_Template__c 
                WHERE Id =: giftEntryCustomSetting.Default_Gift_Entry_Template__c];

            // If there is an associated template, there is a valid default template. 
            return templateList.isEmpty() ? false : true;
        }

        return false;
    }

    /**
     * @description This method determines if the gift entry feature is enabled  
     *
     * @return Returns whether or not the feature is enabled.
     */
    private static Boolean giftEntryIsEnabled() {
            
        // Get the gift entry custom setting to check for the default template.             
        Gift_Entry_Settings__c giftEntryCustomSetting = UTIL_CustomSettingsFacade.getGiftEntrySettings();

        if (giftEntryCustomSetting.Enable_Gift_Entry__c) {
            return true;
        }

        return false;
    }

    /**
     * @description This method builds a new default template using the base JSON string. 
     * It will update the base JSON string with the updated field mapping dev names.
     *   
     *
     * @return A new Form template that is ready to be saved into the DB and used. 
     */
    @TestVisible
    private static Form_Template__c buildDefaultTemplate() {
        Template orgSpecificDefaultTemplate = getOrgSpecificDefaultTemplate();
        return getFormTemplateFor(orgSpecificDefaultTemplate);
    }

    private static Form_Template__c getFormTemplateFor(Template aTemplate) {
        Form_Template__c formTemplate = new Form_Template__c();
        formTemplate.Name = aTemplate.name;
        formTemplate.Description__c = aTemplate.description;
        formTemplate.Template_JSON__c = JSON.serialize(aTemplate);
        formTemplate.Format_Version__c = TEMPLATE_VERSION;
        return formTemplate;
    }

    private static void applyNamespaceToBatchHeaderFields(Template aTemplate) {
        List<BatchHeaderField> batchHeaderFieldList = aTemplate.batchHeaderFields;
        for (BatchHeaderField batchHeaderField : batchHeaderFieldList) {
            if (batchHeaderField.apiName.endsWith('__c')) {
                batchHeaderField.apiName = UTIL_Namespace.StrTokenNSPrefix(batchHeaderField.apiName);
            }
        }
    }

    private static void updateLayoutUsingLocalMigratedFieldMappings(Template aTemplate) {
        Layout orgSpecificTemplate = aTemplate.layout;
        List<Section> sectionList = orgSpecificTemplate.sections;

        // Get a mapping of partial dev names to full dev names for this org.
        // Example:
        // Account1_Name -> Account1_Name_ee63cf9df
        // This is used for updating the base JSON's field mapping dev names with the org's dev names.
        Map<String, String> updatedFieldDevNameMap = new Map<String, String>();

        // This is used for updating the base JSON's object mapping dev names with the org's dev names.
        Map<String, String> updatedObjectDevNameMap = new Map<String, String>();

        populateDevNameMapping(updatedFieldDevNameMap, updatedObjectDevNameMap);
        for (Section section : sectionList) {
            List<Element> elementList = section.elements;

            for (Element element : elementList) {
                if (element.dataImportObjectMappingDevName != null) {
                    String partialObjectDevName = element.dataImportObjectMappingDevName.substringBeforeLast('_');
                    if (updatedObjectDevNameMap.containsKey(partialObjectDevName)) {
                        element.dataImportObjectMappingDevName = updatedObjectDevNameMap.get(partialObjectDevName);
                    }
                }
                if (element.dataImportFieldMappingDevNames != null) {
                    for (Integer i = 0; i < element.dataImportFieldMappingDevNames.size(); i++) {
                        // Get the updated dev name for this org and replace it into the Base JSON
                        String partialDevName =
                                element.dataImportFieldMappingDevNames.get(i).substringBeforeLast('_');

                        // If the updated Dev Name map doesn't contain the partial dev name
                        // it is not necessary to be updated. It is probably a field
                        // that is on the DI itself and not a mapped field.
                        // e.g. 'Donation_Donor__c', 'Account1Imported__c', etc
                        if (updatedFieldDevNameMap.containsKey(partialDevName)) {
                            element.dataImportFieldMappingDevNames.set(i, updatedFieldDevNameMap.get(partialDevName));
                        } else {
                            String fullDevName = element.dataImportFieldMappingDevNames.get(i);

                            if (fullDevName.endsWith('__c')) {
                                fullDevName = UTIL_Namespace.StrTokenNSPrefix(fullDevName);
                                // Align field api name with environment namespace if needed
                                element.fieldApiName =
                                        element.fieldApiName != null ?
                                                UTIL_Namespace.StrTokenNSPrefix(element.fieldApiName) :
                                                element.fieldApiName;
                                // Align object api name with environment namespace if needed
                                element.objectApiName = element.objectApiName != null ?
                                        UTIL_Namespace.StrTokenNSPrefix(element.objectApiName) :
                                        element.objectApiName;
                            }

                            // If it is a DI field, apply the namespace, if there is one.
                            element.dataImportFieldMappingDevNames.set(i, fullDevName);
                        }
                    }
                }
            }
        }

        // In order to properly check whether any of the
        // migrated field mappings have been deleted, the call
        // to stripElementsWithDeletedFieldMappings() must happen
        // after the template's dev names have been updated.
        orgSpecificTemplate.stripElementsWithDeletedFieldMappings(mappings);
    }

    private static String getDefaultTemplateBaseJSON() {
        String defaultTemplateSRJSON = '';
        List<StaticResource> defaultTemplateSRList = [
                SELECT
                        Id,
                        Body
                FROM StaticResource
                WHERE Name = 'DefaultGiftEntryTemplate'
                LIMIT 1
        ];


        if (!defaultTemplateSRList.isEmpty()) {
            defaultTemplateSRJSON = defaultTemplateSRList[0].Body.toString();
        }
        return defaultTemplateSRJSON;
    }

    private static Template getOrgSpecificDefaultTemplate() {
        Template orgSpecificDefaultTemplate =
                (Template) JSON.deserialize(getDefaultTemplateBaseJSON(), Template.class);

        // Update the batch header fields with the namespace prefix, if necessary
        applyNamespaceToBatchHeaderFields(orgSpecificDefaultTemplate);

        // Update the Base Template to have it reflect the Developer Names of the
        // migrated Field Mappings that exist in this Org.
        updateLayoutUsingLocalMigratedFieldMappings(orgSpecificDefaultTemplate);

        return orgSpecificDefaultTemplate;
    }

    /**
     * @description This method builds a mapping of partial dev name to 
     * the full dev name using the org's field mapping custom metadata records. 
     *
     * @return A mapping of partial dev name to full dev name. 
     * e.g. Account1_Name -> Account1_Name_ee63cf9df
     */
    private static void populateDevNameMapping(Map<String,String> updatedFieldDevNameMap,
        Map<String,String> updatedObjectDevNameMap) {

        for (Data_Import_Field_Mapping__mdt fieldMapping :
                (List<Data_Import_Field_Mapping__mdt>) mappings.getRecords()) {
            String partialFieldDevName = fieldMapping.DeveloperName.substringBeforeLast('_');
            String partialObjectDevName = 
                fieldMapping.Target_Object_Mapping__r.DeveloperName.substringBeforeLast('_');
            
            // Only add it into the map if there was a change at all. If there wasn't a change
            // that means that there was no '_' in the dev name and is probably not something we want
            if (partialFieldDevName != fieldMapping.DeveloperName) {
                updatedFieldDevNameMap.put(partialFieldDevName, fieldMapping.DeveloperName);
            }
            
            if (partialObjectDevName != fieldMapping.Target_Object_Mapping__r.DeveloperName) {
                updatedObjectDevNameMap.put(partialObjectDevName, 
                    fieldMapping.Target_Object_Mapping__r.DeveloperName);
            }            
        }
    }

    /**
    * @description Form template definition for use in entering gifts
    */
    public class Template {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String description;
        @AuraEnabled public String version;
        @AuraEnabled public Layout layout;
        @AuraEnabled public String[] defaultBatchTableColumns;
        @AuraEnabled public String permissionErrorType;
        @AuraEnabled public String permissionErrors;
        @AuraEnabled public ElevateSettings elevateSettings;

        /* Additional props PS */
        @AuraEnabled public BatchHeaderField[] batchHeaderFields;
        /* END */

        public Template(String name, String description, String version, Layout layout) {
            this.name = name;
            this.description = description;
            this.version = version;
            this.layout = layout;
        }

        public List<String> giftFieldApiNames() {
            List<Element> allElements = new List<Element>();
            for (Section section : this.layout.sections) {
                allElements.addAll(section.elements);
            }

            List<String> giftFieldApiNames = new List<String>();
            BDI_FieldMappingSet fieldMappings = BDI_MappingServiceAdvanced.getInstance(false).fieldMappingSet;
            for (Element element : allElements) {

                if (element.elementType == FIELD_ELEMENT_TYPE && element.dataImportFieldMappingDevNames.size() > 0) {
                    String fieldMappingDeveloperName = element.dataImportFieldMappingDevNames[0];
                    BDI_FieldMapping fieldMapping = fieldMappings.fieldMappingByDevName.get(fieldMappingDeveloperName);

                    Boolean isReferenceFieldMappedInObjectMapping = fieldMapping == null;
                    if (isReferenceFieldMappedInObjectMapping) {
                        giftFieldApiNames.add(element.fieldApiName);
                    } else {
                        String sourceFieldDevName = fieldMapping.Source_Field_API_Name;
                        giftFieldApiNames.add(sourceFieldDevName);
                    }
                }
            }

            return giftFieldApiNames;
        }
    }

    public class ElevateSettings {
        @AuraEnabled public String uniqueKey;
        @AuraEnabled public Boolean isACHEnabled;
        @AuraEnabled public Boolean isCreditCardEnabled;
        @AuraEnabled public String gatewayName;
    }

    /**
    * @description Form Layout definition for use in entering gifts.
    */
    public class Layout {
        @AuraEnabled public String fieldMappingSetDevName;
        @AuraEnabled public Section[] sections;

        public Layout(String fieldMappingSetDevName, Section[] sections) {
            this.fieldMappingSetDevName = fieldMappingSetDevName;
            this.sections = sections;
        }

        public Boolean containsField(SObjectField sObjectField) {
            for (Section section : sections) {
                List<Element> elements = section.elements;
                for (Element element : elements) {
                    if (element.fieldApiName == String.valueOf(sObjectField)) {
                        return true;
                    }
                }
            }
            return false;
        }

        public void stripElementsWithDeletedFieldMappings(FieldMappings fieldMappings) {
            for (Section section : sections) {
                List<Element> els = new List<Element>();
                for (Element e : section.elements) {
                    if (!fieldMappings.isDeleted(e.fieldMappingDevName())) {
                        els.add(e);
                    }
                }
                section.elements = els;
            }
        }
    }

    /**
    * @description Form Section definition for use in entering gifts.
    */
    public class Section {

        @AuraEnabled public String label;
        @AuraEnabled public String displayType;
        @AuraEnabled public String defaultDisplayMode;
        @AuraEnabled public String displayRule;
        @AuraEnabled public Element[] elements;

        /* Additional props PS */
        @AuraEnabled public String id;
        /* END */

        public Section(String label,
                String displayType,
                String defaultDisplayMode,
                String displayRule,
                Element[] elements) {

            this.label = label;
            this.displayType = displayType;
            this.defaultDisplayMode = defaultDisplayMode;
            this.displayRule = displayRule;
            this.elements = elements;
        }
    }

    /**
    * @description Form Element definition for use in entering gifts.
    */
    public class Element {

        @AuraEnabled public String elementType;
        @AuraEnabled public String displayRule;
        @AuraEnabled public String validationRule;
        @AuraEnabled public String customLabel;
        @AuraEnabled public String componentName;
        @AuraEnabled public String[] dataImportFieldMappingDevNames;
        @AuraEnabled public String dataImportObjectMappingDevName;
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public String objectApiName;

        /* PS Additional props for FormFields */
        @AuraEnabled public String id;
        @AuraEnabled public String label;
        @AuraEnabled public Boolean required;
        @AuraEnabled public String sectionId;
        @AuraEnabled public String defaultValue;
        @AuraEnabled public String dataType;

        //Constructor for form field
        public Element(String elementType,
                String displayRule,
                String validationRule,
                String customLabel,
                String[] dataImportFieldMappingDevNames) {
            this.elementType = elementType;
            this.displayRule = displayRule;
            this.validationRule = validationRule;
            this.customLabel = customLabel;
            this.dataImportFieldMappingDevNames = dataImportFieldMappingDevNames;
            this.required = false;
        }

        //Constructor for widget
        public Element(String elementType,
                String displayRule,
                String componentName,
                String[] dataImportFieldMappingDevNames) {
            this.elementType = elementType;
            this.displayRule = displayRule;
            this.componentName = componentName;
            this.dataImportFieldMappingDevNames = dataImportFieldMappingDevNames;
            this.required = false;
        }

        private String fieldMappingDevName() {
            return dataImportFieldMappingDevNames[0];
        }
    }

    /**
    * @description Form Batch Header Field definition for use in entering gifts.
    */
    public class BatchHeaderField {

        @AuraEnabled public String elementType;
        @AuraEnabled public String displayRule;
        @AuraEnabled public String validationRule;
        @AuraEnabled public String customLabel;
        @AuraEnabled public String label;
        @AuraEnabled public String apiName;
        @AuraEnabled public Boolean required;
        @AuraEnabled public Boolean isRequiredFieldDisabled;
        @AuraEnabled public Boolean allowDefaultValue;
        @AuraEnabled public String defaultValue;
        @AuraEnabled public String dataType;

        public BatchHeaderField(String elementType,
                String displayRule,
                String validationRule,
                String customLabel) {
            this.elementType = elementType;
            this.displayRule = displayRule;
            this.validationRule = validationRule;
            this.customLabel = customLabel;
        }
    }

    public enum AccessLevel {
        VALIDATE_READ, VALIDATE_CREATE, VALIDATE_UPDATE
    }
    public static final String OBJECT_CRUD_ERROR = 'CRUD';
    public static final String FLS_ERROR = 'FLS';

    /**
    * @description Service to provide CRUD and FLS permission validations for form templates
    */
    public class PermissionValidator {

        Template template;
        Set<AccessLevel> accessLevels;
        UTIL_Permissions permissionsService = UTIL_Permissions.getInstance();
        UTIL_Describe describeService = UTIL_Describe.getInstance();
        Map<String, Set<String>> permissionErrorsBySObject;

        public PermissionValidator(Template template, Set<AccessLevel>
                accessLevels) {
            this.template = template;
            this.accessLevels = accessLevels;
            this.permissionErrorsBySObject = new Map<String, Set<String>>();
        }

        public PermissionValidator(Set<AccessLevel> accessLevels) {
            this.accessLevels = accessLevels;
            this.permissionErrorsBySObject = new Map<String, Set<String>>();
        }

        public Boolean hasObjectPermissions (String objectDevName) {
            return isValid(objectDevName);
        }

        public Boolean hasFieldPermissions (String objectDevName, String fieldDevName) {
            return isValid(objectDevName, fieldDevName);
        }

        /*******************************************************************************************************
        * @description Method for validating CRUD/FLS permissions for a template
        * @return {Template} template
        * */
        public Template validateTemplate() {

            BDI_FieldMappingSet fieldMappings =  BDI_MappingServiceAdvanced.getInstance(true).fieldMappingSet;
            for (Section section : template.layout.sections) {
                for (Element element : section.elements) {

                    if (element.elementType == FIELD_ELEMENT_TYPE) {
                        for (String fieldDevName : element.dataImportFieldMappingDevNames) {
                            if (fieldMappings.fieldMappingByDevName.containsKey(fieldDevName)) {
                                BDI_FieldMapping fieldMapping = fieldMappings.fieldMappingByDevName.get(fieldDevName);
                                if (fieldMapping.isDescribable) {

                                    String targetObjDevName = fieldMapping.Target_Object_API_Name;
                                    String targetFieldDevName = fieldMapping.Target_Field_API_Name;
                                    String sourceObjDevName = Schema.SObjectType.DataImport__c.getName();
                                    String sourceFieldDevName = fieldMapping.Source_Field_API_Name;

                                    validate(sourceObjDevName);
                                    validate(targetObjDevName);
                                    validate(sourceObjDevName, sourceFieldDevName);
                                    validate(targetObjDevName, targetFieldDevName);

                                }
                            }
                        }
                    }
                }
            }
            handlePermissionsErrors();
            return template;
        }

        private void validate(String objDevName) {
            if (!isValid(objDevName)) {
                permissionErrorsBySObject.put(objDevName, new Set<String>{
                        OBJECT_CRUD_ERROR
                });
            }
        }

        private void validate(String objDevName, String fieldDevName) {
            if (!isValid(objDevName, fieldDevName)) {
                if (permissionErrorsBySObject.containsKey(objDevName)) {
                    permissionErrorsBySObject.get(objDevName).add(fieldDevName);
                } else {
                    permissionErrorsBySObject.put(objDevName, new Set<String>{
                            fieldDevName
                    });
                }
            }
        }

        /*******************************************************************************************************
        * @description Perform CRUD validation on an SObject
        * @param objDevName - the API name of the SObject to validate
        * @return {Boolean}
        */
        private Boolean isValid(String objDevName) {

            SObjectType objType = ((SObject) Type.forName(objDevName).newInstance()).getSObjectType();

            if ((accessLevels.contains(AccessLevel.VALIDATE_CREATE)
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
        * @return {Boolean}
        */
        private Boolean isValid(String objDevName, String fieldDevName) {

            SObjectType objectType = UTIL_Describe.getSObjectType(objDevName);
            SObjectField objField = objectType.getDescribe().fields.getMap().get(fieldDevName);

            if (objField == null) {
                return false;
            }

            Set<SObjectField> fields = new Set<SObjectField>{objField};

            if ((accessLevels.contains(AccessLevel.VALIDATE_CREATE)
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
        * @return {Boolean}
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
        */
        private void handlePermissionsErrors() {

            Set<String> crudErrors = new Set<String>();

            // The map will contain only the object key if there is a CRUD error
            for (String objDevName : permissionErrorsBySObject.keySet()) {
                if (permissionErrorsBySObject.get(objDevName).contains(OBJECT_CRUD_ERROR)) {
                    crudErrors.add(objDevName);
                }
            }
            if (!crudErrors.isEmpty()) {
                template.permissionErrorType = OBJECT_CRUD_ERROR;
                template.permissionErrors = String.join(new List<String>(crudErrors), ', ');
            } else if (crudErrors.isEmpty() && !permissionErrorsBySObject.values().isEmpty()){
                template.permissionErrorType = FLS_ERROR;
                template.permissionErrors = formatFLSError();
            }
        }

        /*******************************************************************************************************
        * @description Format FLS errors for the UI in a readable format, pairing all fields with their associated SObject
        * @return {String} message
        */
        private String formatFLSError() {
            String message;
            if (!permissionErrorsBySObject.isEmpty()) {
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
}