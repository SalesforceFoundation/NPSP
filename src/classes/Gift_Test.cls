/*
    Copyright (c) 2021 Salesforce.org
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

@isTest
private class Gift_Test {
    
    @isTest
    static void validateThatGiftNeedsToBeReauthorized() {
        DataImport__c dataImport = new DataImport__c(
            Payment_Status__c = ElevateTransactionStatus.AUTHORIZED.name(),
            Payment_Elevate_Batch_ID__c = 'test-valid-group-id',
            Donation_Amount__c = 3.00
        );

        insert dataImport;

        Test.startTest();

        dataImport.Donation_Amount__c = 5.00;
        Gift authorizedGift = new Gift(dataImport);
        Boolean needsReauthorization = authorizedGift.requiresReauthorizationBeforeChange();

        Test.stopTest();

        System.assertEquals(dataImport.Id, authorizedGift.dataImport.Id);
        System.assert(needsReauthorization);
    }

    @isTest
    static void shouldReturnDataImportRecord() {
        DataImport__c dataImport = new DataImport__c(
            Donation_Amount__c = 10,
            Donation_Date__c = Date.today()
        );

        Gift gift = new Gift(dataImport);

        System.assertEquals(10, gift.dataImportRecord().Donation_Amount__c);
    }

    @isTest
    static void shouldHave2SoftCreditsFromAdditionalObjectJSON() {
        DataImport__c dataImport = new DataImport__c(
            Donation_Amount__c = 10,
            Donation_Date__c = Date.today(),
            Additional_Object_JSON__c = DUMMY_ADDITIONAL_OBJECT_JSON_WITH_SOFT_CREDITS
        );
        Gift gift = new Gift(dataImport);

        System.assertEquals(2, gift.softCredits().size());
    }

    @isTest
    static void shouldHave0SoftCreditsFromAdditionalObjectJSON() {
        DataImport__c dataImport = new DataImport__c(
            Donation_Amount__c = 10,
            Donation_Date__c = Date.today(),
            Additional_Object_JSON__c = DUMMY_ADDITIONAL_OBJECT_JSON_WITH_ALLOCATIONS
        );
        Gift gift = new Gift(dataImport);

        System.assertEquals(0, gift.softCredits().size());
    }

    final static string DUMMY_ADDITIONAL_OBJECT_JSON_WITH_SOFT_CREDITS = '{"name":"Additional_Object_JSON__c","dynamicSourceByObjMappingDevName":{"Opportunity_Contact_Role_1temp2":{"sourceObj":{"attributes":{"type":"DataImport__c"},"Opportunity_Contact_Role_1_Role__c":"Household Member","Contact1Imported__c":"0035600000VNllNAAT"},"objectMappingTemplateDevName":"Opportunity_Contact_Role_1","objectMappingDevName":"Opportunity_Contact_Role_1temp2","importedRecordStatus":null,"importedRecordId":null,"fieldMappingSetDevName":"Migrated_Custom_Field_Mapping_Set"},"Opportunity_Contact_Role_1temp1":{"sourceObj":{"attributes":{"type":"DataImport__c"},"Opportunity_Contact_Role_1_Role__c":"Matched Donor","Contact1Imported__c":"0035600000VNllSAAT"},"objectMappingTemplateDevName":"Opportunity_Contact_Role_1","objectMappingDevName":"Opportunity_Contact_Role_1temp1","importedRecordStatus":null,"importedRecordId":null,"fieldMappingSetDevName":"Migrated_Custom_Field_Mapping_Set"}}}';
    static final String DUMMY_ADDITIONAL_OBJECT_JSON_WITH_ALLOCATIONS = '{"name":"Additional_Object_JSON__c","dynamicSourceByObjMappingDevName":{"GAU_Allocation_1temp2":{"sourceObj":{"attributes":{"type":"DataImport__c"},"GAU_Allocation_1_GAU__c":"DUMMY_ID","GAU_Allocation_1_Percent__c":0,"GAU_Allocation_1_Amount__c":100},"objectMappingTemplateDevName":"GAU_Allocation_1","objectMappingDevName":"GAU_Allocation_1temp2","importedRecordStatus":null,"importedRecordId":null,"fieldMappingSetDevName":"Migrated_Custom_Field_Mapping_Set"},"GAU_Allocation_1temp1":{"sourceObj":{"attributes":{"type":"DataImport__c"},"GAU_Allocation_1_GAU__c":"DUMMY_ID","GAU_Allocation_1_Percent__c":0,"GAU_Allocation_1_Amount__c":200},"objectMappingTemplateDevName":"GAU_Allocation_1","objectMappingDevName":"GAU_Allocation_1temp1","importedRecordStatus":null,"importedRecordId":null,"fieldMappingSetDevName":"Migrated_Custom_Field_Mapping_Set"}}}';
}
