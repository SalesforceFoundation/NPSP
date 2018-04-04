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
* @group Opportunity
* @description Test class for OPP_AutomatedSoftCreditsService class.
*/

@isTest
private class OPP_AutomatedSoftCreditsService_TEST {

    private static final String OPPORTUNITY_STAGENAME_CLOSED_WON = 'Closed Won';
    private static final String RELATIONSHIP_TYPE_FRIEND = 'Friend';
    private static final String RELATIONSHIP_TYPE_PARTNER = 'Partner';
    private static final String RELATIONSHIP_STATUS_CURRENT = 'Current';
    private static final String RELATIONSHIP_OPPORTUNITY_CONTACT_ROLE_SOFT_CREDIT = 'Soft Credit';
    private static final String RELATIONSHIP_OPPORTUNITY_CONTACT_ROLE_SOLICITOR = 'Solicitor';


    /*********************************************************************************************************
    * @description Creates data to test Automated Soft Credits functionality
    *
    * @return void
    **********************************************************************************************************/
    @testSetup static void createAutomatedSoftCreditsData() {
        List<Contact> testContacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(5);
        testContacts[0].FirstName = 'Primary0';
        testContacts[1].FirstName = 'Primary1';
        testContacts[2].FirstName = 'Related2';
        testContacts[3].FirstName = 'Related3';
        testContacts[4].FirstName = 'Related4';
        insert testContacts;
        testContacts = [SELECT Id, AccountId, FirstName, LastName FROM Contact];

        npe4__Relationship__c testCon0ToTestCon1
                = new npe4__Relationship__c(npe4__Contact__c = testContacts[0].Id,
                                            npe4__RelatedContact__c = testContacts[1].Id,
                                            npe4__Type__c = RELATIONSHIP_TYPE_FRIEND,
                                            npe4__Status__c = RELATIONSHIP_STATUS_CURRENT,
                                            Related_Opportunity_Contact_Role__c = RELATIONSHIP_OPPORTUNITY_CONTACT_ROLE_SOFT_CREDIT);

        npe4__Relationship__c testCon0ToTestCon2
                = new npe4__Relationship__c(npe4__Contact__c = testContacts[0].Id,
                                            npe4__RelatedContact__c = testContacts[2].Id,
                                            npe4__Type__c = RELATIONSHIP_TYPE_PARTNER,
                                            npe4__Status__c = RELATIONSHIP_STATUS_CURRENT,
                                            Related_Opportunity_Contact_Role__c = RELATIONSHIP_OPPORTUNITY_CONTACT_ROLE_SOFT_CREDIT);

        npe4__Relationship__c testCon0ToTestCon3
                = new npe4__Relationship__c(npe4__Contact__c = testContacts[0].Id,
                                            npe4__RelatedContact__c = testContacts[3].Id,
                                            npe4__Type__c = RELATIONSHIP_TYPE_FRIEND,
                                            npe4__Status__c = RELATIONSHIP_STATUS_CURRENT,
                                            Related_Opportunity_Contact_Role__c = null);

        npe4__Relationship__c testCon1ToTestCon3
                = new npe4__Relationship__c(npe4__Contact__c = testContacts[1].Id,
                                            npe4__RelatedContact__c = testContacts[3].Id,
                                            npe4__Type__c = RELATIONSHIP_TYPE_FRIEND,
                                            npe4__Status__c = RELATIONSHIP_STATUS_CURRENT,
                                            Related_Opportunity_Contact_Role__c = RELATIONSHIP_OPPORTUNITY_CONTACT_ROLE_SOFT_CREDIT);

        npe4__Relationship__c testCon1ToTestCon4
                = new npe4__Relationship__c(npe4__Contact__c = testContacts[1].Id,
                                            npe4__RelatedContact__c = testContacts[4].Id,
                                            npe4__Type__c = RELATIONSHIP_TYPE_PARTNER,
                                            npe4__Status__c = RELATIONSHIP_STATUS_CURRENT,
                                            Related_Opportunity_Contact_Role__c = null);

        List<npe4__Relationship__c> testRelationships
            = new List<npe4__Relationship__c>{ testCon0ToTestCon1, testCon0ToTestCon2, testCon0ToTestCon3, testCon1ToTestCon3, testCon1ToTestCon4 };
        insert testRelationships;

        List<Opportunity> testOpptys = UTIL_UnitTestData_TEST.OppsForContactWithAccountList(testContacts, null, UTIL_UnitTestData_TEST.getClosedWonStage(),
                                                                                            System.today(), 100, null, null);
        insert testOpptys;
    }


    /*********************************************************************************************************
    * @description Tests the Opportunity's Account classification is set to Organization.
    * verify:
    *   Account's classification is not set to Individual.
    * @return void
    **********************************************************************************************************/
    private static testMethod void testOpportunityAccountClassificationIsOrganization() {
        Boolean isOrganizationalAccount = false;

        Account acct = new Account(Name = 'Organization Account');
        acct.npe01__SYSTEMIsIndividual__c = false;
        insert acct;

        Test.startTest();

        isOrganizationalAccount = OPP_AutomatedSoftCreditsService.isOrganizationalAccount(acct.npe01__SYSTEMIsIndividual__c);

        Test.stopTest();

        System.assertEquals(true, isOrganizationalAccount);
    }


    /*********************************************************************************************************
    * @description Tests the Opportunity's Account classification is set to Individual.
    * verify:
    *   Account's classification is set to Individual.
    * @return void
    **********************************************************************************************************/
    private static testMethod void testOpportunityAccountClassificationIsIndividual() {
        Boolean isOrganizationalAccount = false;

        Account acct = new Account(Name = 'Household Account');
        acct.npe01__SYSTEMIsIndividual__c = true;
        insert acct;

        Test.startTest();

        isOrganizationalAccount = OPP_AutomatedSoftCreditsService.isOrganizationalAccount(acct.npe01__SYSTEMIsIndividual__c);

        Test.stopTest();

        System.assertEquals(false, isOrganizationalAccount);
    }


    /*********************************************************************************************************
    * @description Tests that Opportunity Contact Role records are created for the Opportunity's Primary
    *               Contact's Related Contacts.
    * verify:
    *   Opportunity Contact Role records created for Related Contacts.
    * @return void
    **********************************************************************************************************/
    private static testMethod void testCreateRelationshipOCRs() {
        Test.startTest();

        Contact testCon = [SELECT Id FROM Contact WHERE FirstName = 'Primary1'][0];
        List<OpportunityContactRole> retrievedOCR
            = [SELECT Id, ContactId, Role FROM OpportunityContactRole WHERE ContactId = :testCon.Id];

        Test.stopTest();

        System.assertEquals(testCon.Id, retrievedOCR[0].ContactId);
        System.assertEquals(RELATIONSHIP_OPPORTUNITY_CONTACT_ROLE_SOFT_CREDIT, retrievedOCR[0].Role);
    }


    /*********************************************************************************************************
    * @description Tests the retrieval of Relationship records for the Opportunity's Primary Contact.
    * verify:
    *   Relationship records were retrieved.
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRetrieveRelationships() {
        Map<Id, List<npe4__Relationship__c>> relationshipRecords = new Map<Id, List<npe4__Relationship__c>>();

        Contact testCon0 = [SELECT Id FROM Contact WHERE FirstName = 'Primary0'][0];
        Contact testCon1 = [SELECT Id FROM Contact WHERE FirstName = 'Primary1'][0];
        Set<Id> testCons = new Set<Id>{ testCon0.Id, testCon1.Id };

        Test.startTest();

        relationshipRecords = OPP_AutomatedSoftCreditsService.retrieveRelationships(testCons);

        Test.stopTest();

        System.assertEquals(2, relationshipRecords.size());
        System.assertEquals(2, relationshipRecords.get(testCon0.Id).size());
        System.assertEquals(1, relationshipRecords.get(testCon1.Id).size());
    }


    /*********************************************************************************************************
    * @description Tests the Opportunity Contact Role records were created with the expected values.
    * verify:
    *   Opportunity Contact Role records created with expected values.
    * @return void
    **********************************************************************************************************/
    private static testMethod void testBuildRelationshipOCRs() {
        List<OpportunityContactRole> creatededOCRs = new List<OpportunityContactRole>();

        Map<Id, Id> primaryContactIdToOpportunityId = new Map<Id, Id>();
        Map<Id, List<npe4__Relationship__c>> relationshipRecords = new Map<Id, List<npe4__Relationship__c>>();

        Contact testCon0 = [SELECT Id FROM Contact WHERE FirstName = 'Primary0'][0];
        Contact testCon1 = [SELECT Id FROM Contact WHERE FirstName = 'Primary1'][0];

        List<Opportunity> opptys = [SELECT Id, Primary_Contact__c FROM Opportunity];
        for (Opportunity eachOppty : opptys) {
            primaryContactIdToOpportunityId.put(eachOppty.Primary_Contact__c, eachOppty.Id);
        }

        relationshipRecords = OPP_AutomatedSoftCreditsService.retrieveRelationships(primaryContactIdToOpportunityId.keySet());
        System.assertEquals(2, relationshipRecords.size());
        System.assertEquals(2, relationshipRecords.get(testCon0.Id).size());
        System.assertEquals(1, relationshipRecords.get(testCon1.Id).size());

        Test.startTest();

        List<OpportunityContactRole> retrievedOCRs = [SELECT Id, ContactId, Role FROM OpportunityContactRole];
        System.assertEquals(8, retrievedOCRs.size()); // Five OCRs for the Opportunities' Primary Contacts and three OCRs for the Relationships

        creatededOCRs = OPP_AutomatedSoftCreditsService.buildRelationshipOCRs(primaryContactIdToOpportunityId, relationshipRecords);
        System.assertEquals(0, creatededOCRs.size()); // Confirm no duplicate OCRs were created

        // Update Relationship records
        List<npe4__Relationship__c> testCon0Relationships = relationshipRecords.get(testCon0.Id);
        testCon0Relationships[0].Related_Opportunity_Contact_Role__c = RELATIONSHIP_OPPORTUNITY_CONTACT_ROLE_SOLICITOR;
        testCon0Relationships[1].Related_Opportunity_Contact_Role__c = RELATIONSHIP_OPPORTUNITY_CONTACT_ROLE_SOLICITOR;
        update testCon0Relationships;

        creatededOCRs = OPP_AutomatedSoftCreditsService.buildRelationshipOCRs(primaryContactIdToOpportunityId, relationshipRecords);

        Test.stopTest();

        System.assertEquals(2, creatededOCRs.size()); // Confirm new OCR records were created
    }


    /*********************************************************************************************************
    * @description Tests the retrieval of Opportunity Contact Role records for given Opportunities.
    * verify:
    *   Opportunity Contact Role records were retrieved.
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRetrieveOpportunityContactRoles() {
        List<Id> opptyIds = new List<Id>();

        Contact testCon = [SELECT Id FROM Contact WHERE FirstName = 'Primary0'][0];
        List<Opportunity> opptys = [SELECT Id FROM Opportunity WHERE Primary_Contact__c = :testCon.Id];
        for (Opportunity eachOppty : opptys) {
            opptyIds.add(eachOppty.Id);
        }

        Test.startTest();

        Map<Id, List<OpportunityContactRole>> opportunityIdToOCR = OPP_AutomatedSoftCreditsService.retrieveOpportunityContactRoles(opptyIds);

        Test.stopTest();

        System.assertEquals(3, opportunityIdToOCR.get(opptys[0].Id).size());
        System.assertEquals(opptys[0].Id, opportunityIdToOCR.get(opptys[0].Id)[0].OpportunityId);
    }


    /*********************************************************************************************************
    * @description Tests if a Relationship record has the same values an Opportunity Contact Role record.
    * verify:
    *   Relationship record is a duplicate.
    * @return void
    **********************************************************************************************************/
    private static testMethod void testIsDuplicateOCR() {
        Boolean isDuplicate = false;

        Contact testCon0 = [SELECT Id FROM Contact WHERE FirstName = 'Primary0'][0];
        Contact testCon1 = [SELECT Id FROM Contact WHERE FirstName = 'Primary1'][0];
        Opportunity oppty = [SELECT Id FROM Opportunity WHERE Primary_Contact__c = :testCon0.Id][0];

        Test.startTest();

        List<OpportunityContactRole> retrievedOCRs = [SELECT Id, ContactId, Role FROM OpportunityContactRole WHERE ContactId = :testCon1.Id];
        Map<Id, List<npe4__Relationship__c>> relationshipRecords = OPP_AutomatedSoftCreditsService.retrieveRelationships(new Set<Id>{ testCon0.Id });

        npe4__Relationship__c currentRelationship = relationshipRecords.get(testCon0.Id)[0];
        isDuplicate = OPP_AutomatedSoftCreditsService.isDuplicateOCR(retrievedOCRs,
                                                                     currentRelationship.npe4__RelatedContact__c,
                                                                     currentRelationship.Related_Opportunity_Contact_Role__c);

        Test.stopTest();

        System.assertEquals(true, isDuplicate);
    }


    /*********************************************************************************************************
    * @description Tests if a Relationship record has the same values an Opportunity Contact Role record.
    * verify:
    *   Relationship record is not a duplicate.
    * @return void
    **********************************************************************************************************/
    private static testMethod void testIsNotDuplicateOCR() {
        Boolean isDuplicate = false;

        Contact testCon0 = [SELECT Id FROM Contact WHERE FirstName = 'Primary0'][0];
        Contact testCon1 = [SELECT Id FROM Contact WHERE FirstName = 'Primary1'][0];
        Opportunity oppty = [SELECT Id FROM Opportunity WHERE Primary_Contact__c = :testCon0.Id][0];

        Test.startTest();

        List<OpportunityContactRole> retrievedOCRs = [SELECT Id, ContactId, Role FROM OpportunityContactRole WHERE ContactId = :testCon1.Id];
        retrievedOCRs[0].Role = RELATIONSHIP_OPPORTUNITY_CONTACT_ROLE_SOLICITOR;
        update retrievedOCRs;

        Map<Id, List<npe4__Relationship__c>> relationshipRecords = OPP_AutomatedSoftCreditsService.retrieveRelationships(new Set<Id>{ testCon0.Id });

        npe4__Relationship__c currentRelationship = relationshipRecords.get(testCon0.Id)[0];
        isDuplicate = OPP_AutomatedSoftCreditsService.isDuplicateOCR(retrievedOCRs,
                                                                     currentRelationship.npe4__RelatedContact__c,
                                                                     currentRelationship.Related_Opportunity_Contact_Role__c);

        Test.stopTest();

        System.assertEquals(false, isDuplicate);
    }


}