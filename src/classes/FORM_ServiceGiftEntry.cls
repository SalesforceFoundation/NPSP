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
* @date 2019
* @group Gift Entry
* @group-content ../../ApexDocContent/GiftEntry.htm
* @description Form Service implementations specifically used for gift entry use cases.
*/
public with sharing class FORM_ServiceGiftEntry {

    private static final String TEMPLATES = 'Templates';
    private static final String BATCHES = 'Batches';
    
    /*******************************************************************************************************
    * @description Retrieves Matching string values from BDI_DataImport_API
    * @return Map of object and field name keys to their values.
    */
    @AuraEnabled
    public static Map<String, String> getDonationMatchingValues() {
        Map<String, String> matchingValues = new Map<String, String> {
            'DoNotMatch' => BDI_DataImport_API.DoNotMatch,
            'RequireNoMatch' => BDI_DataImport_API.RequireNoMatch,
            'RequireExactMatch' => BDI_DataImport_API.RequireExactMatch,
            'ExactMatchOrCreate' => BDI_DataImport_API.ExactMatchOrCreate,
            'RequireBestMatch' => BDI_DataImport_API.RequireBestMatch,
            'BestMatchOrCreate' => BDI_DataImport_API.BestMatchOrCreate
        };
        return matchingValues;
    }

    /*******************************************************************************************************
    * @description Method retrieves records based on a query string.
    */
    @AuraEnabled
    public static SObject[] retrieveRecords(String[] selectFields,
        String sObjectApiName, String[] whereClauses, String orderByClause, Integer limitClause) {

        String queryString = new UTIL_Query()
            .withSelectFields(selectFields)
            .withFrom(sObjectApiName)
            .withWhere(whereClauses)
            .withSecurityEnforced()
            .withOrderBy(orderByClause)
            .withLimit(limitClause)
            .build();
        return Database.query(queryString);
    }

    /*******************************************************************************************************
    * @description Method retrieves custom Column Header Data (Custom Setting records & Permission Data)
    * for tables in the Gift
    * Entry landing page.
    * @param listName
    * @return {ColumnHeaderData}
    */
    @AuraEnabled
    public static ColumnHeaderData retrieveCustomColumnHeaders(String listName) {
        String[] selectFields = new String[] {
            SObjectType.Custom_Column_Header__c.fields.Id.name,
            SObjectType.Custom_Column_Header__c.fields.Name.name,
            SObjectType.Custom_Column_Header__c.fields.Field_Api_Name__c.name,
            SObjectType.Custom_Column_Header__c.fields.Index__c.name,
            SObjectType.Custom_Column_Header__c.fields.List_Name__c.name
        };
        String sObjectApiName = SObjectType.Custom_Column_Header__c.name;
        String whereVal = '\'' + String.escapeSingleQuotes(listName) + '\'';
        String whereClauses = SObjectType.Custom_Column_Header__c.fields.List_Name__c.name + ' = ' + whereVal;
        String orderByClause = SObjectType.Custom_Column_Header__c.fields.Index__c.name + ' ASC';

        String queryString = new UTIL_Query()
            .withSelectFields(selectFields)
            .withFrom(sObjectApiName)
            .withWhere(whereClauses)
            .withSecurityEnforced()
            .withOrderBy(orderByClause)
            .build();
        return getColumnHeaderDataWithPermissions(Database.query(queryString), listName);
    }

    /*******************************************************************************************************
    * @description Method retrieves records based on a query string.
    */
    @AuraEnabled
    public static ColumnHeaderData upsertCustomColumnHeaders(String columnHeadersString,
        String listName) {

        Custom_Column_Header__c[] columnHeaders =
            (Custom_Column_Header__c[])JSON.deserialize(columnHeadersString, Custom_Column_Header__c[].class);
        upsert columnHeaders;

        Id[] headerIdsToKeep = new Id[]{};
        for (Custom_Column_Header__c columnHeader : columnHeaders) {
            headerIdsToKeep.add(columnHeader.Id);
        }

        Custom_Column_Header__c[] headersToDelete = [
            SELECT Id
            FROM Custom_Column_Header__c
            WHERE Id NOT IN :headerIdsToKeep
            AND List_Name__c = :listName
            WITH SECURITY_ENFORCED
        ];
        delete headersToDelete;

        return getColumnHeaderDataWithPermissions(columnHeaders, listName);
    }

    /*******************************************************************************************************
    * @description Method for retrieving all existing form templates.
    */
    @AuraEnabled
    public static FORM_Template[] getAllFormTemplates() {
        FORM_Template[] formTemplates = new FORM_Template[]{};
        Form_Template__c[] allTemplates = [
            SELECT Id,
                Name,
                Template_JSON__c,
                Description__c,
                Format_Version__c
            FROM Form_Template__c
            WITH SECURITY_ENFORCED
            ORDER BY Name ASC
        ];

        for (Form_Template__c formTemplate : allTemplates) {
            FORM_Template deserializedFormTemplate = deserializeFormTemplateFromObj(formTemplate);
            if (formTemplate.id != null) {
                deserializedFormTemplate.id = formTemplate.id;
            }

            formTemplates.add(deserializedFormTemplate);
        }

        return formTemplates;
    }

    /*******************************************************************************************************
    * @description Method deletes a Form_Template__c record by id.
    *
    * @param id: Form_Template__c record id
    *
    * @return FormTemplateWrapper: Wrapper object of the list of deleted template names and the result
    * of the DML action
    */
    @AuraEnabled
    public static String [] deleteFormTemplates(String[] ids) {
        String[] formTemplateNames = new String[] {};
        Form_Template__c[] templates = [
                SELECT Id, Name
                FROM Form_Template__c
                WHERE Id IN :ids
                WITH SECURITY_ENFORCED
            ];
        try {
            delete templates;
            for (Form_Template__c template : templates) {
                formTemplateNames.add(template.Name);
            }
        } catch (DmlException ex) {
            throw new AuraHandledException(ex.getDmlMessage(0));
        }
       return formTemplateNames;
    }

    /*******************************************************************************************************
    * @description Method for retrieving an existing template that you already have the Id for.
    * @param templateId - the Id of an existing form template record for retrieval.
    */
    @AuraEnabled
    public static FORM_Template retrieveFormTemplateById(Id templateId) {
        FORM_Template template;

        Form_Template__c templateObj = [
                                SELECT Id, Name, Format_Version__c, Template_JSON__c
                                FROM Form_Template__c 
                                WHERE Id =: templateId
                                WITH SECURITY_ENFORCED
                                LIMIT 1
                            ];
        
        template = deserializeFormTemplateFromObj(templateObj);
        
        template = checkPermissions(template,
                new Set<FORM_PermissionValidator.AccessLevel>{
                    FORM_PermissionValidator.AccessLevel.VALIDATE_READ,
                    FORM_PermissionValidator.AccessLevel.VALIDATE_CREATE,
                    FORM_PermissionValidator.AccessLevel.VALIDATE_UPDATE});

        return template;
    }
    
    /*******************************************************************************************************
    * @description Method for retrieving the current default template.
    */
    public static FORM_Template retrieveDefaultSGEFormTemplate() {
        Gift_Entry_Settings__c giftEntrySettings = getGiftEntrySettings();
        FORM_Template template;
        List<Form_Template__c> templateObjList = [
                                SELECT Id, Name, Format_Version__c, Template_JSON__c
                                FROM Form_Template__c 
                                WHERE Id =: giftEntrySettings.Default_Gift_Entry_Template__c
                                WITH SECURITY_ENFORCED
                            ];
         
         if (!templateObjList.isEmpty()) {
            template = deserializeFormTemplateFromObj(templateObjList[0]);

            template = checkPermissions(template,
                new Set<FORM_PermissionValidator.AccessLevel>{
                    FORM_PermissionValidator.AccessLevel.VALIDATE_READ,
                    FORM_PermissionValidator.AccessLevel.VALIDATE_CREATE,
                    FORM_PermissionValidator.AccessLevel.VALIDATE_UPDATE});
            }
        return template;
    }

    /*******************************************************************************************************
    * @description Method for validating CRUD/FLS permissions for a template
    * @param template - the template to use for CRUD/FLS validation
    * @param accessLevels - a collection of CRUD/FLS validations to perform on the template (i.e. CREATE/UPDATE/READ)
    */
    public static FORM_Template checkPermissions(FORM_Template template, Set<FORM_PermissionValidator.AccessLevel> accessLevels){
        
        FORM_PermissionValidator validator = new FORM_PermissionValidator(template, accessLevels);

        return validator.validateTemplate();
    }

    /*******************************************************************************************************
    * @description Stores the template JSON.
    * @param id - the Id of an existing form template record if this is an update of an existing template
    * @param name - The name that should be applied to template storage record.
    * @param description - the description of the template.
    * @param formatVersion - the version id/number of the template format
    * @param templateJSON - The JSON for the FormTemplate class that is being stored.
    */
    @AuraEnabled
    public static String storeFormTemplate(String id, 
                                            String name, 
                                            String description,
                                            String formatVersion,
                                            String templateJSON) {
        if (templateJSON != null) {
            Form_Template__c templateObj = new Form_Template__c(Id = id, 
                                                            Name = name,
                                                            Description__c = description,
                                                            Template_JSON__c = templateJSON,
                                                            Format_Version__c = formatVersion);
            upsert templateObj;
            return templateObj.Id;
        }

        return null;
    }

    /*******************************************************************************************************
    * @description Method checks if the provided name is in use by another existing Form Template.
    *
    * @param String name: Name of a Form_Template__c record.
    * @param String id: Id of a Form_Template__c record.
    */
    @AuraEnabled
    public static Boolean checkNameUniqueness(String name, String id) {
        Form_Template__c[] formTemplates = [
                            SELECT Id
                            FROM Form_Template__c
                            WHERE Name = :name
                            WITH SECURITY_ENFORCED
                        ];
        Boolean isNameValid = formTemplates.size() > 0 ? false : true;

        if (id != null) {
            for (Form_Template__c formTemplate : formTemplates) {
                if (formTemplate.Id == id) {
                    isNameValid = true;
                    break;
                }
            }
        }

        return isNameValid;
    }

    /*******************************************************************************************************
    * @description Private helper method for deserializing the JSON stored in a form template record.
    * @param templateObj - The Form_Template__c object with the Template JSON.
    */
    private static FORM_Template deserializeFormTemplateFromObj(Form_Template__c templateObj) {
        FORM_Template template;
        if (templateObj != null && templateObj.Template_JSON__c != null) {
            template = (FORM_Template)JSON.deserialize(templateObj.Template_JSON__c, FORM_Template.class);
        }
        return template;
    }

    /******************************************************************************************************
     * @description Private method for checking FLS & CRUD permissions for custom column headers for the
     * the GE List View headers
     * @param columnHeaders Custom Column Headers
     * @param listName List View Name
     * @return Instance of the ColumnHeaderData object
    */
    private static ColumnHeaderData getColumnHeaderDataWithPermissions(Custom_Column_Header__c[] columnHeaders,
            String listName) {
        String listNameDevName = listName == TEMPLATES ?
                Schema.SObjectType.Form_Template__c.getName() :
                Schema.SObjectType.DataImportBatch__c.getName();

        ColumnHeaderData headerData;

        if (columnHeaders.isEmpty()) {
            //populate column headers with default headers
            columnHeaders = populateDefaultColumnHeaders(listName);
        }

        FORM_PermissionValidator validator = new FORM_PermissionValidator(
                new Set<FORM_PermissionValidator.AccessLevel>{FORM_PermissionValidator.AccessLevel.VALIDATE_READ});

        if (validator.hasObjectPermissions(listNameDevName)) {
            headerData = new ColumnHeaderData(columnHeaders, '');
            List<String> flsErrors = new List<String>();
            for (Custom_Column_Header__c header : columnHeaders) {
                if (!validator.hasFieldPermissions(listNameDevName, header.Field_Api_Name__c)) {
                    List<String> errors = new List<String>{header.Field_Api_Name__c};
                    flsErrors.add(listNameDevName + ': (' + String.join(errors, ', ') + ')');
                }
            }
            headerData.permissionErrorData += String.join(flsErrors, ' ,');
        }
        return headerData;
    }

    /**
     * @description Method to populate default column headers for the Gift Entry list view tables
     * @param listName
     * @return {Custom_Column_Header__c}
    */
    private static Custom_Column_Header__c[] populateDefaultColumnHeaders(String listName) {
        Custom_Column_Header__c[] columnHeaders = new Custom_Column_Header__c[]{};
        Integer index = 0;
        for (String field : buildListViewDefaultFields(listName)) {
            index++;
            Custom_Column_Header__c columnHeader = new Custom_Column_Header__c();
            columnHeader.Field_Api_Name__c = field;
            columnHeader.Index__c = index;
            columnHeader.Name = generateId();
            columnHeader.List_Name__c = listName;
            columnHeaders.add(columnHeader);
        }
        return columnHeaders;
    }


    /**
     * @description Builds default fields for the Gift Entry list view column headers
     * @param listName List view tab name
     * @return {List} defaultFields
    */
    private static List<String> buildListViewDefaultFields (String listName) {
        List<String> defaultFields;
        if (listName == TEMPLATES) {
            defaultFields = new List<String> {
                    'Name',
                    UTIL_Namespace.StrTokenNSPrefix('Description__c'),
                    'CreatedById',
                    'LastModifiedDate'
            };
        } else if (listName == BATCHES) {
            defaultFields = new List<String> {
                    'Name',
                    UTIL_Namespace.StrTokenNSPrefix('Batch_Description__c'),
                    UTIL_Namespace.StrTokenNSPrefix('Form_Template__c'),
                    UTIL_Namespace.StrTokenNSPrefix('Expected_Count_of_Gifts__c'),
                    UTIL_Namespace.StrTokenNSPrefix('Expected_Total_Batch_Amount__c'),
                    'CreatedById',
                    'LastModifiedDate'
            };
        }
        return defaultFields;
    }

    /**
     * Inner class representation of the Custom Column Headers with permission data
    */
    public with sharing class ColumnHeaderData {
        @AuraEnabled
        public Custom_Column_Header__c[] columnHeaders;
        @AuraEnabled
        public String permissionErrorData;

        public ColumnHeaderData (Custom_Column_Header__c[] columnHeaders,
                String permissionErrorData) {
            this.columnHeaders = columnHeaders;
            this.permissionErrorData = permissionErrorData;
        }
    }

    /*******************************************************************************************************
    * @description @description Creates a 'unique' id made to look like a UUID..
    *
    * @return {String} guid: Generated UUID.
    */
    private static String generateId() {
        Blob key = Crypto.generateAesKey(128);
        String hexString = EncodingUtil.convertToHex(key);
        String generateUniqueId = hexString.substring(0,8)+ '-' + hexString.substring(8,12) +
                '-' + hexString.substring(12,16) + '-' + hexString.substring(16,20) + '-' + hexString.substring(20);
        return generateUniqueId;
    }

    /**
     * @description This method will create a default template
     * if it is necessary and then return the Gift_Entry_Settings__c
     * custom setting  for use.
     *
     * @return Returns whether or not there is an existing default template.
     */
    @AuraEnabled
    public static Gift_Entry_Settings__c getGiftEntrySettings() {
        try {
            GE_DefaultTemplate.createDefaultTemplateIfNecessary();
            Gift_Entry_Settings__c giftEntryCustomSetting = UTIL_CustomSettingsFacade.getGiftEntrySettings();

            return giftEntryCustomSetting;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}