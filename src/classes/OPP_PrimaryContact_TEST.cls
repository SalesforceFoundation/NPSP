/*
    Copyright (c) 2014, Salesforce.org
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
* @date 2014
* @group Opportunity
* @description Test class for the Opportunity Primary Contact lookup.
*/
@isTest
private with sharing class OPP_PrimaryContact_TEST {
    private static final String CLOSE_WON_STAGE = UTIL_UnitTestData_TEST.getClosedWonStage();

    /*******************************************************************************************************
    * @description Tests insert, update, and delete of the primary opportunity contact role based on the opportunity
    * Primary Contact field.
    ********************************************************************************************************/
    @isTest
    private static void shouldUpdateCreateOrDeleteOCRsBasedPrimaryContactFieldOnOppChange() {
        List<Contact> contacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(2);
        insert contacts;

        Opportunity opp = new Opportunity(
            Name = 'foo',
            Primary_Contact__c = contacts[0].Id,
            CloseDate = System.today(),
            StageName = CLOSE_WON_STAGE,
            Amount = 8
        );
        insert opp;

        List<OpportunityContactRole> actualOCRs = getOCRs(opp.Id);
        System.assertEquals(1, actualOCRs.size(), 'One primary contact role should be created for the opportunity.');
        System.assertEquals(contacts[0].Id, actualOCRs[0].ContactId, 'The first contact should have the primary contact role.');

        opp.Primary_Contact__c = contacts[1].Id;
        Test.startTest();
        update opp;
        Test.stopTest();
        
        actualOCRs = getOCRs(opp.Id);
        System.assertEquals(1,actualOCRs.size(), 'One primary contact role should exist for the opportunity.');
        System.assertEquals(contacts[1].Id, actualOCRs[0].ContactId, 'The second contact should now have the primary contact role.');

        opp.Primary_Contact__c = null;
        update opp;
        
        actualOCRs = getOCRs(opp.Id);
        System.assertEquals(0,actualOCRs.size(), 'The primary contact role should be deleted.');
    }
    
    /*******************************************************************************************************
    * @description Creates opportunities with primary contact roles and with a blank Primary Contact field.
    * Runs the batch utility and verifies the Primary Contact field has been populated.
    * Only Opportunities with unchecked Disable Contact Role Automation field will be processed.
    ********************************************************************************************************/
    @isTest
    private static void shouldUpdatePrimaryContactOnOppBasedOnPrimaryOCRContact() {
        Integer size = 2;
        List<Contact> contacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(size);
        insert contacts;

        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < size; i++) {
            opps.add(new Opportunity(
                Name = 'foo',
                Primary_Contact__c = contacts[i].Id,
                CloseDate = System.today(),
                StageName = CLOSE_WON_STAGE,
                Amount = 8
            ));
        }
        insert opps;

        //null out the field without deleting the OCR
        TDTM_TriggerHandler.disableTDTM = true;
        opps[0].Primary_Contact__c = null;
        opps[1].Primary_Contact__c = null;
        opps[1].DisableContactRoleAutomation__c = true;
        update opps;
        TDTM_TriggerHandler.disableTDTM = false;

        List<OpportunityContactRole> actualOCRs = getOCRs(opps);
        System.assertEquals(size, actualOCRs.size(), 'An OCR should exist for each Opp.');

        List<Opportunity> actualOpps = getOpportunities(opps);
        System.assertEquals(null, actualOpps[0].Primary_Contact__c, 'The primary contact on Opp should be blank.');
        System.assertEquals(null, actualOpps[1].Primary_Contact__c, 'The primary contact on Opp should be blank.');

        Test.startTest();
        Database.executeBatch(new OPP_PrimaryContact_BATCH());
        Test.stopTest();

        Map<Id, Opportunity> actualOppById = new Map<Id, Opportunity>(getOpportunities(opps));
        System.assertEquals(contacts[0].Id, actualOppById.get(opps[0].Id).Primary_Contact__c, 
            'The primary contact on Opp should be updated when DisableContactRoleAutomation is unchecked.');
        System.assertEquals(null, actualOppById.get(opps[1].Id).Primary_Contact__c, 
            'The primary contact on Opp should remain unchanged when DisableContactRoleAutomation is checked.');
    }

    /*******************************************************************************************************
    * @description Bulk creates opportunities with Primary Contact set, verifies Contact Roles are created.
    ********************************************************************************************************/
    @isTest
    private static void shouldCreateOCRsOnBulkOppInsert() {
        Integer bulkSize = 50;
        
        List<Contact> contacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(bulkSize);
        insert contacts;
        
        List<Opportunity> opps = UTIL_UnitTestData_TEST.OppsForContactList(contacts, null, CLOSE_WON_STAGE, System.Today(), 8, null, null);
        Test.startTest();
        insert opps;
        Test.stopTest();

        List<OpportunityContactRole> actualOCRs = getOCRs(opps);
        System.assertEquals(50,actualOCRs.size(), 'An OCR should be created for each Opportunity.');

    }

    /*******************************************************************************************************
    * @description Update an opportunity primary contact to a contact with an existing ocr. Verify that the
    * old OCR is deleted.
    ********************************************************************************************************/
    @isTest
    private static void shouldRecreateOCRsWhenPrimaryContactFieldOnOppIsUpdated() {
        List<Contact> contacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(2);
        insert contacts;
        
        Opportunity opp = new Opportunity(
            Name = 'foo',
            Primary_Contact__c = contacts[0].Id,
            CloseDate = System.today(),
            StageName = CLOSE_WON_STAGE,
            Amount = 8
        );
        insert opp;

        OpportunityContactRole secondaryOCR = new OpportunityContactRole(
            ContactId = contacts[1].Id,
            OpportunityId = opp.Id,
            Role = 'foo'
        );
        insert secondaryOCR;

        List<OpportunityContactRole> actualOCRs = getOCRs(opp.Id);
        System.assertEquals(2, actualOCRs.size(), 'Two OCRs should exist.');
        System.assertEquals(contacts[0].Id, actualOCRs[0].ContactId, 'Contact 0 should be primary.');

        opp.Primary_Contact__c = contacts[1].Id;
        Test.startTest();
        update opp;
        Test.stopTest();

        actualOCRs = getOCRs(opp.Id);
        System.assertEquals(1, actualOCRs.size(), 'One OCR should exist.');
        System.assertEquals(contacts[1].Id, actualOCRs[0].ContactId, 'Contact 0 should be primary.');
    }

    // Helpers
    /////////////

    /*******************************************************************************************************
    * @description Retrieve OpportunityContactRoles for the Opportunity
    * @param oppId An Opportunity Id
    * @return List<OpportunityContactRole>
    */
    private static List<OpportunityContactRole> getOCRs(Id oppId) {
        return getOCRs(new Set<Id>{ oppId });
    }

    /*******************************************************************************************************
    * @description Retrieve OpportunityContactRoles for Opportunities
    * @param opps Opportunity records
    * @return List<OpportunityContactRole> 
    */
    private static List<OpportunityContactRole> getOCRs(List<Opportunity> opps) {
        return getOCRs(new Map<Id, Opportunity>(opps).keySet());
    }

    /*******************************************************************************************************
    * @description Retrieve OpportunityContactRoles for Opportunity Ids
    * @param oppIds Opportunity Ids
    * @return List<OpportunityContactRole> 
    */
    private static List<OpportunityContactRole> getOCRs(Set<Id> oppIds) {
        return [
            SELECT Id, OpportunityId, ContactId, IsPrimary 
            FROM OpportunityContactRole 
            WHERE OpportunityId IN :oppIds
            ORDER BY IsPrimary DESC
        ];
    }

    /*******************************************************************************************************
    * @description Retrieve Opportunities
    * @param opps Opportunities
    * @return List<Opportunity>
    */
    private static List<Opportunity> getOpportunities(List<Opportunity> opps) {
        return [
            SELECT Id, Primary_Contact__c 
            FROM Opportunity 
            WHERE Id IN :opps
        ];
    }
}