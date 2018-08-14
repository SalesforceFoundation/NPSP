/*
    Copyright (c) 2018, Salesforce.org
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
* @date 2018
* @group BGE
* @group-content 
* @description BGE Template Component Controller.
*/
public with sharing class BGE_Template_CTRL {

    /*******************************************************************************************************
    * @description Retrieves the Template Details information, the related list of fields, and component labels.
    * @return JSON model of all template details data.
    */
    @AuraEnabled
    public static String getTemplateDetails(Id templateId) {
        TemplateDetailsModel templateDetails = new TemplateDetailsModel();

        if (templateId != null) {
            Batch_Template__c batchTemplate = [SELECT
                    Name,
                    Id,
                    Description__c,
                    Enable_Total_Entry__c,
                    Require_Total_Match__c,
                    Active_Fields__c
            FROM Batch_Template__c
            WHERE Id = :templateId];

            templateDetails.name = batchTemplate.Name;
            templateDetails.description = batchTemplate.Description__c;
            templateDetails.enableTotalEntry = batchTemplate.Enable_Total_Entry__c;
            templateDetails.id = batchTemplate.Id;
            templateDetails.requireTotalMatch = batchTemplate.Require_Total_Match__c;
            templateDetails.activeFields = batchTemplate.Active_Fields__c;
        }

        templateDetails.templateFields = getAvailableFields();
        templateDetails.labels = getBatchTemplateLabels();

        return JSON.serialize(templateDetails);
    }

    /*******************************************************************************************************
    * @description Retrieves the related list of fields.
    * @return list of Template Fields with sObjectName and Name.
    */
    @AuraEnabled
    public static List<Field> getAvailableFields() {

        List<Field> fields = new List<Field>();

        Map<String, Schema.DescribeFieldResult> fieldMap = UTIL_Describe.getAllFieldsDescribe(UTIL_Namespace.StrTokenNSPrefix('DataImport__c'));
        Set<String> bannedFields = new Set<String>{'Account1Imported__c',
                'Account1ImportStatus__c',
                'Account2Imported__c',
                'Account2ImportStatus__c',
                'ApexJobId__c',
                'Contact1Imported__c',
                'Contact1ImportStatus__c',
                'Contact2Imported__c',
                'Contact2ImportStatus__c',
                'DonationImported__c',
                'DonationImportStatus__c',
                'Donation_Possible_Matches__c',
                'FailureInformation__c',
                'HomeAddressImported__c',
                'HomeAddressImportStatus__c',
                'HouseholdAccountImported__c',
                'ImportedDate__c',
                'NPSP_Data_Import_Batch__c',
                'PaymentImported__c',
                'PaymentImportStatus__c',
                'Payment_Possible_Matches__c',
                'Status__c',
                'Account2ImportStatus__c'
        };

        for (Schema.DescribeFieldResult dfr : fieldMap.values()) {
            String namespacedObject = UTIL_Namespace.StrTokenRemoveNSPrefix(dfr.name);
            if (!bannedFields.contains(namespacedObject) && dfr.inlineHelpText != null) {
                Field fld = new Field();
                if (namespacedObject == 'Donation_Donor__c') {
                    fld.sObjectName = 'Opportunity';
                } else {
                    fld.sObjectName = dfr.inlineHelpText.split('\\.')[0];
                }
                fld.label = (dfr.getLabel().contains(' ') && dfr.getLabel().split(' ',2)[0] == fld.sObjectName) ? dfr.getLabel().split(' ',2)[1] : dfr.getLabel() ;
                fld.name = dfr.getName();
                fields.add(fld);
            }
        }
        return fields;
    }
    /*******************************************************************************************************
    * @description Retrieves the object and field labels for the component.
    * @return Map of Batch Template object and field name keys to their labels.
    */
    @AuraEnabled
    public static Map<String, String> getBatchTemplateLabels() {

        Map<String, String> labels = new Map<String, String> {
            'batchTemplateLabel' => Schema.SObjectType.Batch_Template__c.getLabel(),
            'backToTemplates' => String.format(Label.CRLP_Return, new List<String>{Schema.SObjectType.Batch_Template__c.getLabelPlural()}),
            'batchTemplateObject' => Schema.SObjectType.Batch_Template__c.getName(),
            'description' => Schema.Batch_Template__c.Description__c.getDescribe().getLabel(),
            'totalEntryHelp' => Schema.Batch_Template__c.Enable_Total_Entry__c.getDescribe().getInlineHelpText(),
            'totalEntryLabel' => Schema.Batch_Template__c.Enable_Total_Entry__c.getDescribe().getLabel(),
            'totalMatchHelp' => Schema.Batch_Template__c.Require_Total_Match__c.getDescribe().getInlineHelpText(),
            'totalMatchLabel' => Schema.Batch_Template__c.Require_Total_Match__c.getDescribe().getLabel()
        };

        return labels;
    }

    /*******************************************************************************************************
    * @description Saves the Template Details information with the structured list of active fields.
    * @return void.
    */
    @AuraEnabled
    public static string saveTemplate(String templateInfo, String activeFields) {
        try {
            TemplateDetailsModel templateDetails = (TemplateDetailsModel) JSON.deserialize(templateInfo, TemplateDetailsModel.class);
            system.debug(templateDetails);

            Batch_Template__c batchTemplate = new Batch_Template__c();

            if (templateDetails.id != null) {
                batchTemplate.Id = templateDetails.id;
            }
            batchTemplate.Name = templateDetails.name;
            batchTemplate.Description__c = templateDetails.description;
            batchTemplate.Enable_Total_Entry__c = templateDetails.enableTotalEntry;
            batchTemplate.Require_Total_Match__c = templateDetails.requireTotalMatch;
            batchTemplate.Active_Fields__c = activeFields;

            upsert batchTemplate;
            templateDetails.id = batchTemplate.Id;

            return JSON.serialize(templateDetails);

        } catch (Exception ex) {
            //TODO: is BDI right to use here?
            ERR_Handler.processError(ex, ERR_Handler_API.Context.BDI);
            throw new AuraHandledException('ERROR: ' + ex.getMessage());
        }
    }

    /*******************************************************************************************************
    * @description a class to retrieve and save the required information for the BGE_TemplateDetails component.
    */
    public class TemplateDetailsModel {
        @AuraEnabled public String name;
        @AuraEnabled public String description;
        @AuraEnabled public Boolean enableTotalEntry;
        @AuraEnabled public Id id;
        @AuraEnabled public Boolean requireTotalMatch;
        @AuraEnabled public List<Field> templateFields;
        @AuraEnabled public String activeFields;
        @AuraEnabled public Map<String, String> labels;

        public TemplateDetailsModel() {
            enableTotalEntry = false;
            requireTotalMatch = false;
            templateFields = new List<Field>();
        }
    }

    /*******************************************************************************************************
    * @description a class to retrieve and save information related to Active and Available fields.
    */
    public class Field {
        @AuraEnabled public String label;
        @AuraEnabled public String name;
        @AuraEnabled public String sObjectName;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public String defaultValue;
        @AuraEnabled public Boolean required;
        @AuraEnabled public Boolean hide;

        public Field() {
            isActive = false;
            required = false;
            hide = false;
        }
    }
}