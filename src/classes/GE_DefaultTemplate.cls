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
* @group BGE
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Class to create a default template when needed
*/

public with sharing class GE_DefaultTemplate {

    public static string version1DefaultTemplate = '{"batchHeaderFields":[{"allowDefaultValue":true,"apiName":"Contact_Matching_Rule__c","dataType":"String",' + 
                                                    '"isRequiredFieldDisabled":true,"label":"Contact Matching Rule","required":true},{"allowDefaultValue":true,' + 
                                                    '"apiName":"GiftBatch__c","dataType":"Boolean","isRequiredFieldDisabled":true,"label":"Gift Batch","required"' + 
                                                    ':true},{"allowDefaultValue":true,"apiName":"Name","dataType":"String","isRequiredFieldDisabled":true,"label":' + 
                                                    '"Batch Name","required":true},{"allowDefaultValue":true,"apiName":"Process_Using_Scheduled_Job__c","dataType":' + 
                                                    '"Boolean","isRequiredFieldDisabled":true,"label":"Process Using Scheduled Job","required":true},{"allowDefaultValue"' + 
                                                    ':true,"apiName":"RequireTotalMatch__c","dataType":"Boolean","isRequiredFieldDisabled":true,"label":"Require Expected ' + 
                                                    'Totals Match","required":true},{"allowDefaultValue":true,"apiName":"Contact_Matching_Rule__c","dataType":"String",' + 
                                                    '"isRequiredFieldDisabled":true,"label":"Contact Matching Rule","required":true},{"allowDefaultValue":true,"apiName":' + 
                                                    '"GiftBatch__c","dataType":"Boolean","isRequiredFieldDisabled":true,"label":"Gift Batch","required":true},{"allowDefaultValue"' + 
                                                    ':true,"apiName":"Name","dataType":"String","isRequiredFieldDisabled":true,"label":"Batch Name","required":true},{"allowDefaultValue"' + 
                                                    ':true,"apiName":"Process_Using_Scheduled_Job__c","dataType":"Boolean","isRequiredFieldDisabled":true,"label":"Process Using ' + 
                                                    'Scheduled Job","required":true},{"allowDefaultValue":true,"apiName":"RequireTotalMatch__c","dataType":"Boolean",' + 
                                                    '"isRequiredFieldDisabled":true,"label":"Require Expected Totals Match","required":true},{"allowDefaultValue":true,' + 
                                                    '"apiName":"Contact_Matching_Rule__c","dataType":"String","isRequiredFieldDisabled":true,"label":"Contact Matching Rule"' + 
                                                    ',"required":true},{"allowDefaultValue":true,"apiName":"GiftBatch__c","dataType":"Boolean","isRequiredFieldDisabled":true,' + 
                                                    '"label":"Gift Batch","required":true},{"allowDefaultValue":true,"apiName":"Name","dataType":"String","isRequiredFieldDisabled"' + 
                                                    ':true,"label":"Batch Name","required":true},{"allowDefaultValue":true,"apiName":"Process_Using_Scheduled_Job__c","dataType"' + 
                                                    ':"Boolean","isRequiredFieldDisabled":true,"label":"Process Using Scheduled Job","required":true},{"allowDefaultValue":true,"apiName"' + 
                                                    ':"RequireTotalMatch__c","dataType":"Boolean","isRequiredFieldDisabled":true,"label":"Require Expected Totals Match","required"' + 
                                                    ':true}],"layout":{"fieldMappingSetDevName":"Migrated_Custom_Field_Mapping_Set","sections":[{"defaultDisplayMode":"expanded"' + 
                                                    ',"displayRule":"displayRule","displayType":"accordion","elements":[{"customLabel":"Donor Type","dataImportFieldMappingDevNames"' + 
                                                    ':["Donation_Donor__c"],"dataType":"PICKLIST","elementType":"field","id":"8ffa6e93-fd7b-2761-2c38-c466f1db98ec","label":' + 
                                                    '"Data Import: Donation Donor","required":true,"sectionId":"6bc77bf4-9949-5b8b-9f2c-efe5663ef052"},{"customLabel":' + 
                                                    '"Organization Account (Existing)","dataImportFieldMappingDevNames":["Account1Imported__c"],"dataType":"REFERENCE",' + 
                                                    '"elementType":"field","id":"5ed985fd-b631-852f-7d4e-c729db7d151d","label":"Data Import: Account1 Imported","required":' + 
                                                    'false,"sectionId":"6bc77bf4-9949-5b8b-9f2c-efe5663ef052"},{"customLabel":"Contact (Existing)","dataImportFieldMappingDevNames"' + 
                                                    ':["Contact1Imported__c"],"dataType":"REFERENCE","elementType":"field","id":"9ecc9037-8306-083d-960e-438643d706fa",' + 
                                                    '"label":"Data Import: Contact1 Imported","required":false,"sectionId":"6bc77bf4-9949-5b8b-9f2c-efe5663ef052"}],"id":' + 
                                                    '"6bc77bf4-9949-5b8b-9f2c-efe5663ef052","label":"Donor Information"},{"defaultDisplayMode":"expanded","displayRule":' + 
                                                    '"displayRule","displayType":"accordion","elements":[{"customLabel":"Organization Account Name","dataImportFieldMappingDevNames"' + 
                                                    ':["Account1_Name_51dfabd8b"],"dataType":"STRING","elementType":"field","id":"0daf0898-388f-62f5-b86f-7ead7dcbdc95","label"' + 
                                                    ':"Account 1: Account Name","required":false,"sectionId":"94d2bb2b-8cc4-3644-6ac6-d9180269c95c"},{"customLabel":' + 
                                                    '"Organization Account Street","dataImportFieldMappingDevNames":["Account1_Street_38a397e3c"],"dataType":"TEXTAREA"' + 
                                                    ',"elementType":"field","id":"201247cb-b794-2515-583a-e87cd6eda45b","label":"Account 1: Billing Street","required":' + 
                                                    'false,"sectionId":"94d2bb2b-8cc4-3644-6ac6-d9180269c95c"},{"customLabel":"Organization Account City","dataImportFieldMappingDevNames"' + 
                                                    ':["Account1_City_ce9854212"],"dataType":"STRING","elementType":"field","id":"dac1d011-072f-48e8-01d9-e597cabd7001","label":"Account 1: ' + 
                                                    'Billing City","required":false,"sectionId":"94d2bb2b-8cc4-3644-6ac6-d9180269c95c"},{"customLabel":"Organization Account State/Province",' + 
                                                    '"dataImportFieldMappingDevNames":["Account1_State_Province_9db6cdbd7"],"dataType":"STRING","elementType":"field","id":' + 
                                                    '"40cd5b93-3f6a-7be4-9e35-de769683460d","label":"Account 1: Billing State/Province","required":false,"sectionId":' + 
                                                    '"94d2bb2b-8cc4-3644-6ac6-d9180269c95c"},{"customLabel":"Organization Account Zip/Postal Code","dataImportFieldMappingDevNames":' + 
                                                    '["Account1_Zip_Postal_Code_4aea9a02f"],"dataType":"STRING","elementType":"field","id":"56f7dbf7-99dc-e9be-d5d8-21df79ba1621","label"' + 
                                                    ':"Account 1: Billing Zip/Postal Code","required":false,"sectionId":"94d2bb2b-8cc4-3644-6ac6-d9180269c95c"},{"customLabel":' + 
                                                    '"Organization Account Country","dataImportFieldMappingDevNames":["Account1_Country_1359e000c"],"dataType":"STRING","elementType":' + 
                                                    '"field","id":"e8a74c72-6a9a-66da-3129-f48cca998fdc","label":"Account 1: Billing Country","required":false,"sectionId":"94d2bb2b-8cc4-3644-6ac6-d9180269c95c"}],' + 
                                                    '"id":"94d2bb2b-8cc4-3644-6ac6-d9180269c95c","label":"Add or Edit Organization Account"},{"id":"1cb17425-5ced-ebd6-cdaf-44556f648e3f",' + 
                                                    '"displayType":"accordion","defaultDisplayMode":"expanded","displayRule":"displayRule","label":"Add or Edit Primary Contact","elements":' + 
                                                    '[{"id":"05724374-e3fa-b94b-fc6d-00dfbf358abb","label":"Contact 1: First Name","customLabel":"Contact First Name","required":false,"sectionId"' + 
                                                    ':"1cb17425-5ced-ebd6-cdaf-44556f648e3f","defaultValue":null,"dataType":"STRING","dataImportFieldMappingDevNames":["Contact1_First_Name_73301c3c5"]' + 
                                                    ',"elementType":"field"},{"id":"d89dbbb6-1a87-41e6-6e14-dd34a13a9274","label":"Contact 1: Last Name","customLabel":"Contact Last Name","required":false,' + 
                                                    '"sectionId":"1cb17425-5ced-ebd6-cdaf-44556f648e3f","defaultValue":null,"dataType":"STRING","dataImportFieldMappingDevNames":["Contact1_Last_Name_563ada236"]' + 
                                                    ',"elementType":"field"},{"id":"39051aa1-b149-6df7-6ced-02639bdacd82","label":"Address: Mailing Street","customLabel":"Contact Street",' + 
                                                    '"required":false,"sectionId":"1cb17425-5ced-ebd6-cdaf-44556f648e3f","defaultValue":null,"dataType":"STRING","dataImportFieldMappingDevNames"' + 
                                                    ':["Home_Street_24b1562dd"],"elementType":"field"},{"id":"f652fc2a-9637-6e7d-3c1a-ccdbc4cdf088","label":"Address: Mailing City","customLabel":' + 
                                                    '"Contact City","required":false,"sectionId":"1cb17425-5ced-ebd6-cdaf-44556f648e3f","defaultValue":null,"dataType":"STRING","dataImportFieldMappingDevNames"' + 
                                                    ':["Home_City_a9ad873d9"],"elementType":"field"},{"id":"9c23316b-28d3-cae7-b7ff-33e218dd03a4","label":"Address: Mailing State/Province","customLabel":' + 
                                                    '"Contact State/Province","required":false,"sectionId":"1cb17425-5ced-ebd6-cdaf-44556f648e3f","defaultValue":null,"dataType":"STRING",' + 
                                                    '"dataImportFieldMappingDevNames":["Home_State_Province_9ce119103"],"elementType":"field"},{"id":"a59a4769-bf07-7b59-4382-7c9dd19a2181",' + 
                                                    '"label":"Address: Mailing Zip/Postal Code","customLabel":"Contact Zip/Postal Code","required":false,"sectionId":"1cb17425-5ced-ebd6-cdaf-44556f648e3f",' + 
                                                    '"defaultValue":null,"dataType":"STRING","dataImportFieldMappingDevNames":["Home_Zip_Postal_Code_f9807b51a"],"elementType":"field"},{"id"' + 
                                                    ':"ac52960d-805e-fd42-542d-9b2b4a03c9e9","label":"Address: Mailing Country","customLabel":"Contact Country","required":false,"sectionId":' + 
                                                    '"1cb17425-5ced-ebd6-cdaf-44556f648e3f","defaultValue":null,"dataType":"STRING","dataImportFieldMappingDevNames":["Home_Country_bb5c416c4"],' + 
                                                    '"elementType":"field"}]},{"defaultDisplayMode":"expanded","displayRule":"displayRule","displayType":"accordion","elements":[{"customLabel":' + 
                                                    '"Donation Date","dataImportFieldMappingDevNames":["Donation_Date_dfe3de83a"],"dataType":"DATE","elementType":"field","id":"ce4e9472-6c75-53d2-2e1c-36fcbcda210a"' + 
                                                    ',"label":"Opportunity: Close Date","required":true,"sectionId":"3c42b004-03d7-90d5-98ed-e04f25af89e3"},{"customLabel":"Donation Amount",' + 
                                                    '"dataImportFieldMappingDevNames":["Donation_Amount_91e74ad7f"],"dataType":"CURRENCY","elementType":"field","id":"ca2be0bf-d07e-2ec5-0bb6-6908e49dfe49"' + 
                                                    ',"label":"Opportunity: Amount","required":true,"sectionId":"3c42b004-03d7-90d5-98ed-e04f25af89e3"},{"customLabel":"Payment Method","dataImportFieldMappingDevNames"' + 
                                                    ':["Payment_Method_449599d68"],"dataType":"PICKLIST","elementType":"field","id":"149fb6d3-4a3a-c387-6d2c-1a77dcd14f7f","label":"Payment: Payment Method",' + 
                                                    '"required":false,"sectionId":"3c42b004-03d7-90d5-98ed-e04f25af89e3"},{"customLabel":"Check/Reference Number","dataImportFieldMappingDevNames":' + 
                                                    '["Payment_Check_Reference_Number_2947b94f7"],"dataType":"STRING","elementType":"field","id":"cc94d1ce-d93b-dc47-7703-cd89c27843ce","label":' + 
                                                    '"Payment: Check/Reference Number","required":false,"sectionId":"3c42b004-03d7-90d5-98ed-e04f25af89e3"},{"componentName":"geFormWidgetAllocation"' + 
                                                    ',"elementType":"widget","id":"7019830b-8026-5eac-b65e-0f74a3e5382f","label":"Allocations","required":false,"sectionId":"3c42b004-03d7-90d5-98ed-e04f25af89e3"}]' + 
                                                    ',"id":"3c42b004-03d7-90d5-98ed-e04f25af89e3","label":"Donation Information"}]},"name":"Default Gift Entry Form"}';
    static final String ELEMENT_TYPE_FIELD = 'field';

    public GE_DefaultTemplate() {

    }

    /**
     * @description This method determines if there is a default template, if not, it will create a new template and update the custom setting with 
     * the newly created template's ID as the default template. 
     *
     */
    public static void createDefaultTemplate() {
        if (!hasDefaultTemplate()) {
            Form_Template__c newDefaultTemplate = buildDefaultTemplate();

            insert newDefaultTemplate;

            Gift_Entry_Settings__c giftEntryCustomSetting = UTIL_CustomSettingsFacade.getGiftEntrySettings();
            giftEntryCustomSetting.Default_Single_Gift_Entry_Template__c = newDefaultTemplate.Id;

            update giftEntryCustomSetting;
        }
    }

    /**
     * @description This method determines if there is an existing default template.  
     *
     * @return Returns whether or not there is an existing default template. 
     */
    private static boolean hasDefaultTemplate() {
            
        // Get the gift entry custom setting to check for the default template.             
        Gift_Entry_Settings__c giftEntryCustomSetting = UTIL_CustomSettingsFacade.getGiftEntrySettings();
        Boolean hasDefaultTemplate = false;

        if (giftEntryCustomSetting.Default_Single_Gift_Entry_Template__c != null && giftEntryCustomSetting.Default_Single_Gift_Entry_Template__c != '') {
            
            // If there is an ID already stored, try to get this particular template. 
            List<Form_Template__c> templateList = [SELECT Id, Name 
                                                    FROM Form_Template__c 
                                                    WHERE Id =: giftEntryCustomSetting.Default_Single_Gift_Entry_Template__c];

            // IF there is an associated template, there is a valid default template. 
            if (!templateList.isEmpty()){ 
                hasDefaultTemplate = true;
            }
        }

        return hasDefaultTemplate;
    }

    /**
     * @description This method builds a new default template using the base JSON string. It will update the base JSON string with the updated field mapping dev names.
     *   
     *
     * @return A new Form template that is ready to be saved into the DB and used. 
     */
    public static Form_Template__c buildDefaultTemplate() {
        FORM_Template__c newDefaultTemplate = new FORM_Template__c();
        List<StaticResource> defaultTemplateSRList = [Select Id, Body FROM StaticResource Where Name = 'DefaultGiftEntryTemplate' limit 1];
        String defaultTemplateSRJSON = '';

        if (!defaultTemplateSRList.isEmpty()) {
            defaultTemplateSRJSON = defaultTemplateSRList[0].Body.toString();
        }

        // Get a mapping of partial dev names to full dev names for this org.
        // Example:
        // Account1_Name -> Account1_Name_ee63cf9df
        // 
        // This is used for updating the base JSON's dev names with the org's dev names. 
        Map<String, String> updatedDevNameMap = getCurrentDevNameMapping();

        FORM_Template defaultTemplate = (FORM_Template)JSON.deserialize(defaultTemplateSRJSON, FORM_Template.class);
        // FORM_Template defaultTemplate = (FORM_Template)JSON.deserialize(version1DefaultTemplate, FORM_Template.class);
        FORM_Layout defaultLayout = defaultTemplate.layout;
        List<FORM_Section> sectionList = defaultLayout.sections;

        for (FORM_Section section : sectionList) {
            List<FORM_Element> elementList = section.elements;

            for (FORM_Element element : elementList) {
                if (element.elementType == ELEMENT_TYPE_FIELD) {

                    // Get the updated dev name for this org and replace it into the Base JSON
                    String partialDevName = element.dataImportFieldMappingDevNames.get(0).substringBeforeLast('_');

                    // If the updated Dev Name map doesn't contain the partial dev name
                    // it is not necessary to be updated. It is probably a field
                    // that is on the DI itself and not a mapped field.
                    // e.g. 'Donation_Donor__c', 'Account1Imported__c', etc
                    if (updatedDevNameMap.containsKey(partialDevName)) {
                        element.dataImportFieldMappingDevNames.set(0, updatedDevNameMap.get(partialDevName));
                    } else {
                        String namespacedFullDevName = UTIL_Namespace.StrTokenNSPrefix(element.dataImportFieldMappingDevNames.get(0));

                        // If it is a DI field, apply the namespace, if there is one. 
                        element.dataImportFieldMappingDevNames.set(0, namespacedFullDevName);
                    }
                }
            }
        }

        // Update the batch header fields with the namespace prefix, if necessary
        List<FORM_BatchHeaderField> batchHeaderFieldList = defaultTemplate.batchHeaderFields;
        
        for (FORM_BatchHeaderField batchHeaderField : batchHeaderFieldList) {
            batchHeaderField.apiName = UTIL_Namespace.StrTokenNSPrefix(batchHeaderField.apiName);
        }

        newDefaultTemplate.Name = defaultTemplate.name;
        newDefaultTemplate.Description__c = defaultTemplate.description;
        newDefaultTemplate.Template_JSON__c = JSON.serialize(defaultTemplate);
        newDefaultTemplate.Format_Version__c = '1.0';
        return newDefaultTemplate;
    }

    /**
     * @description This method builds a mapping of partial dev name to the full dev name using the org's field mapping custom metadata records. 
     *
     * @return A mapping of partial dev name to full dev name. e.g. Account1_Name -> Account1_Name_ee63cf9df
     */
    public static Map<String, String> getCurrentDevNameMapping() {
        // Get the org's migrated field mappings. 
        List<Data_Import_Field_Mapping__mdt> fieldMappingCMTList = [Select Id, MasterLabel, DeveloperName, Target_Field_API_Name__c, Source_Field_API_Name__c, Target_Object_Mapping__r.Object_API_Name__c
                                                            FROM Data_Import_Field_Mapping__mdt 
                                                            Where Data_Import_Field_Mapping_Set__r.DeveloperName = 'Migrated_Custom_Field_Mapping_Set' Limit 1000];

        // A map which contains the partial dev name to the org's full dev name.
        // An example would like this:
        // Account1_Name -> Account1_Name_ee63cf9df
        Map<String, String> partialDevNameToUpdatedDevName = new Map<String, String>();
        
        for (Data_Import_Field_Mapping__mdt fieldMapping : fieldMappingCMTList) {
            String partialDevName = fieldMapping.DeveloperName.substringBeforeLast('_');

            // Only add it into the map if there was a change at all. If there wasn't a change
            // that means that there was no '_' in the dev name and is probably not something we want
            if (partialDevName != fieldMapping.DeveloperName) {
                partialDevNameToUpdatedDevName.put(partialDevName, fieldMapping.DeveloperName);
            }
        }

        return partialDevNameToUpdatedDevName;
    }
}
