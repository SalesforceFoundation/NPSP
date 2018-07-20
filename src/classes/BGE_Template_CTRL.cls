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
    * @description Retrieves the Template Details information, and the related list of fields.
    * @return 
    */
    @AuraEnabled
    public static String getTemplateDetails(Id templateId) {
        TemplateDetails templateDetails = new TemplateDetails();

        if (templateId != null) {
            Batch_Template__c batchTemplate = [SELECT
                    Name,
                    Description__c,
                    Display_Total_Prompt__c,
                    Require_Total_Match__c,
                    Active_Fields__c
            FROM Batch_Template__c
            WHERE Id = :templateId];

            templateDetails.name = batchTemplate.Name;
            templateDetails.description = batchTemplate.Description__c;
            templateDetails.displayTotalPrompt = batchTemplate.Display_Total_Prompt__c;
            templateDetails.requireTotalMatch = batchTemplate.Require_Total_Match__c;
            //templateDetails.activeFields = batchTemplate.Active_Fields__c;

        }

        templateDetails.templateFields = getAvailableFields();

        return JSON.serialize(templateDetails);
    }

    /*******************************************************************************************************
    * @description Retrieves the Template Details information, and the related list of fields.
    * @return
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
            if (!bannedFields.contains(UTIL_Namespace.StrTokenRemoveNSPrefix(dfr.name)) && dfr.inlineHelpText != null) {
                Field fld = new Field();
                if (dfr.name == 'Donation_Donor__c') {
                    fld.sObjectName = 'Opportunity';
                } else {
                    fld.sObjectName = dfr.inlineHelpText.split('\\.')[0];
                }
                fld.name = (dfr.getLabel().contains(' ') && dfr.getLabel().split(' ',2)[0] == fld.sObjectName) ? dfr.getLabel().split(' ',2)[1] : dfr.getLabel() ;
                fields.add(fld);
            }
        }
        return fields;
    }

    /*******************************************************************************************************
    * @description Saves the Template Details information, and the list of active fields.
    * @return
    */
    @AuraEnabled
    public static void saveTemplate(String templateInfo, String activeFields) {
        try {
            TemplateDetails templateDetails = (TemplateDetails) JSON.deserialize(templateInfo, BGE_Template_CTRL.TemplateDetails.class);

            Batch_Template__c batchTemplate = new Batch_Template__c();
            batchTemplate.Name = templateDetails.name;
            batchTemplate.Description__c = templateDetails.description;
            batchTemplate.Display_Total_Prompt__c = templateDetails.displayTotalPrompt;
            batchTemplate.Require_Total_Match__c = templateDetails.requireTotalMatch;
            batchTemplate.Active_Fields__c = activeFields;

            insert batchTemplate;
        } catch (Exception ex) {
            //TODO: is BDI right to use here?
            ERR_Handler.processError(ex, ERR_Handler_API.Context.BDI);
            throw new AuraHandledException('ERROR: ' + ex.getMessage());
        }
    }

    /*******************************************************************************************************
    * @description 
    */
    public class TemplateDetails {
        @AuraEnabled public String name;
        @AuraEnabled public String description;
        @AuraEnabled public Boolean displayTotalPrompt;
        @AuraEnabled public Boolean requireTotalMatch;
        @AuraEnabled public List<Field> templateFields;

        public TemplateDetails() {
            displayTotalPrompt = false;
            requireTotalMatch = false;
            templateFields = new List<Field>();
        }
    }

    /*******************************************************************************************************
    * @description 
    */
    public class Field {
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