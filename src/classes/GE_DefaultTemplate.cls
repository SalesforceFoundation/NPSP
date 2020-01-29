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
