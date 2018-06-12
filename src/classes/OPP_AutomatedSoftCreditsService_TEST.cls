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
    private static final String RELATIONSHIP_OPPORTUNITY_CONTACT_ROLE_TRIBUTE = 'Tribute';


    /*********************************************************************************************************
    * @description Creates data to test Automated Soft Credits functionality
    *
    * @return void
    **********************************************************************************************************/
    @testSetup static void createAutomatedSoftCreditsData() {
        Account acct1 = new Account(Name = 'Organization Account1');
        Account acct2 = new Account(Name = 'Organization Account2');
        insert new List<Account>{ acct1, acct2 };

        List<Contact> testContacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(7);
        testContacts[0].FirstName = 'Primary0';
        testContacts[1].FirstName = 'Primary1';
        testContacts[2].FirstName = 'Related2';
        testContacts[3].FirstName = 'Related3';
        testContacts[4].FirstName = 'Related4';
        testContacts[5].FirstName = 'Affiliation5';
        testContacts[5].AccountId = acct1.Id;
        testContacts[6].FirstName = 'Affiliation6';
        testContacts[6].AccountId = acct2.Id;
        insert testContacts;
        testContacts = [SELECT Id, AccountId, FirstName, LastName FROM Contact];

        // Create Relationships
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

        // Create Affiliations
        npe5__Affiliation__c testCon5AccountToTestCon2
            = new npe5__Affiliation__c(npe5__Organization__c = testContacts[5].AccountId,
                                       npe5__Contact__c = testContacts[2].Id,
                                       npe5__Role__c = RELATIONSHIP_TYPE_PARTNER,
                                       npe5__Status__c = RELATIONSHIP_STATUS_CURRENT,
                                       Related_Opportunity_Contact_Role__c = RELATIONSHIP_OPPORTUNITY_CONTACT_ROLE_SOFT_CREDIT);

        npe5__Affiliation__c testCon5AccountToTestCon4
            = new npe5__Affiliation__c(npe5__Organization__c = testContacts[5].AccountId,
                                       npe5__Contact__c = testContacts[4].Id,
                                       npe5__Role__c = RELATIONSHIP_TYPE_PARTNER,
                                       npe5__Status__c = RELATIONSHIP_STATUS_CURRENT,
                                       Related_Opportunity_Contact_Role__c = RELATIONSHIP_OPPORTUNITY_CONTACT_ROLE_SOFT_CREDIT);

        npe5__Affiliation__c testCon6AccountToTestCon3
            = new npe5__Affiliation__c(npe5__Organization__c = testContacts[6].AccountId,
                                       npe5__Contact__c = testContacts[3].Id,
                                       npe5__Role__c = RELATIONSHIP_TYPE_PARTNER,
                                       npe5__Status__c = RELATIONSHIP_STATUS_CURRENT,
                                       Related_Opportunity_Contact_Role__c = RELATIONSHIP_OPPORTUNITY_CONTACT_ROLE_SOFT_CREDIT);

        npe5__Affiliation__c testCon6AccountToTestCon2
            = new npe5__Affiliation__c(npe5__Organization__c = testContacts[6].AccountId,
                                       npe5__Contact__c = testContacts[2].Id,
                                       npe5__Role__c = RELATIONSHIP_TYPE_PARTNER,
                                       npe5__Status__c = RELATIONSHIP_STATUS_CURRENT,
                                       Related_Opportunity_Contact_Role__c = null);

        List<npe5__Affiliation__c> testAccountAffiliations
            = new List<npe5__Affiliation__c>{ testCon5AccountToTestCon2, testCon5AccountToTestCon4, testCon6AccountToTestCon3, testCon6AccountToTestCon2 };
        insert testAccountAffiliations;

        // Create Opportunities
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

        Contact testCon = returnContact('Primary1');
        System.assertEquals('Primary1', testCon.FirstName);

        List<OpportunityContactRole> retrievedOCR
            = [SELECT Id, ContactId, Role
                FROM OpportunityContactRole
                WHERE ContactId = :testCon.Id
                AND Role = :RELATIONSHIP_OPPORTUNITY_CONTACT_ROLE_SOFT_CREDIT];

        System.assertEquals(1, retrievedOCR.size());

        Test.stopTest();

        System.assertEquals(testCon.Id, retrievedOCR[0].ContactId);
    }


    /*********************************************************************************************************
    * @description Tests the retrieval of Relationship records for the Opportunity's Primary Contact.
    * verify:
    *   Relationship records were retrieved.
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRetrieveRelationships() {
        Map<Id, List<npe4__Relationship__c>> relationshipRecords = new Map<Id, List<npe4__Relationship__c>>();

        Contact testCon0 = returnContact('Primary0');
        System.assertEquals('Primary0', testCon0.FirstName);

        Contact testCon1 = returnContact('Primary1');
        System.assertEquals('Primary1', testCon1.FirstName);

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

        Map<Id, List<Id>> primaryContactIdToOpportunityIds = new Map<Id, List<Id>>();
        Map<Id, List<npe4__Relationship__c>> relationshipRecords = new Map<Id, List<npe4__Relationship__c>>();
        Map<Id, List<OpportunityContactRole>> transactionOCR = new Map<Id, List<OpportunityContactRole>>();

        Contact testCon0 = returnContact('Primary0');
        System.assertEquals('Primary0', testCon0.FirstName);

        Contact testCon1 = returnContact('Primary1');
        System.assertEquals('Primary1', testCon1.FirstName);

        List<Opportunity> opptys = [SELECT Id, Primary_Contact__c FROM Opportunity];
        for (Opportunity eachOppty : opptys) {
            primaryContactIdToOpportunityIds.put(eachOppty.Primary_Contact__c, new List<Id>{ eachOppty.Id });
        }

        relationshipRecords = OPP_AutomatedSoftCreditsService.retrieveRelationships(primaryContactIdToOpportunityIds.keySet());
        System.assertEquals(2, relationshipRecords.size());
        System.assertEquals(2, relationshipRecords.get(testCon0.Id).size());
        System.assertEquals(1, relationshipRecords.get(testCon1.Id).size());

        Test.startTest();

        List<OpportunityContactRole> retrievedOCRs = [SELECT Id, OpportunityId, ContactId, Role FROM OpportunityContactRole];
        System.assertEquals(13, retrievedOCRs.size()); // Five OCRs for the Opportunities' Primary Contacts and three OCRs for the Relationships
        transactionOCR.put(retrievedOCRs[0].OpportunityId, retrievedOCRs);

        creatededOCRs = OPP_AutomatedSoftCreditsService.buildRelationshipOCRs(primaryContactIdToOpportunityIds, relationshipRecords, transactionOCR);
        System.assertEquals(0, creatededOCRs.size()); // Confirm no duplicate OCRs were created

        // Update Relationship records
        List<npe4__Relationship__c> testCon0Relationships = relationshipRecords.get(testCon0.Id);
        testCon0Relationships[0].Related_Opportunity_Contact_Role__c = RELATIONSHIP_OPPORTUNITY_CONTACT_ROLE_SOLICITOR;
        testCon0Relationships[1].Related_Opportunity_Contact_Role__c = RELATIONSHIP_OPPORTUNITY_CONTACT_ROLE_SOLICITOR;
        update testCon0Relationships;

        creatededOCRs = OPP_AutomatedSoftCreditsService.buildRelationshipOCRs(primaryContactIdToOpportunityIds, relationshipRecords, transactionOCR);

        Test.stopTest();

        System.assertEquals(0, creatededOCRs.size()); // Confirm no new OCR records were created
    }


    /*********************************************************************************************************
    * @description Tests that Opportunity Contact Role records are created for the Opportunity's Account's
    *               Related Contacts.
    * verify:
    *   Opportunity Contact Role records created for Related Contacts.
    * @return void
    **********************************************************************************************************/
    private static testMethod void testCreateAffiliationOCRs() {
        Test.startTest();

        Contact testCon = returnContact('Affiliation5');
        System.assertEquals('Affiliation5', testCon.FirstName);

        Account testAcount = [SELECT Id, npe01__SYSTEMIsIndividual__c FROM Account WHERE Id = :testCon.AccountId][0];
        System.assertEquals(false, testAcount.npe01__SYSTEMIsIndividual__c);
        List<OpportunityContactRole> retrievedOCR
            = [SELECT Id, ContactId, OpportunityId, Role
                FROM OpportunityContactRole
                WHERE ContactId = :testCon.Id
                AND Role = :RELATIONSHIP_OPPORTUNITY_CONTACT_ROLE_SOFT_CREDIT];

        System.assertEquals(1, retrievedOCR.size());

        List<Opportunity> retrievedOppty
            = [SELECT Id, AccountId
                FROM Opportunity
                WHERE Id = :retrievedOCR[0].OpportunityId];

        Test.stopTest();

        System.assertEquals(testCon.Id, retrievedOCR[0].ContactId);
        System.assertEquals(testAcount.Id, retrievedOppty[0].AccountId);
    }


    /*********************************************************************************************************
    * @description Tests the retrieval of Affiliation records for the Opportunity's Account.
    * verify:
    *   Affiliation records were retrieved.
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRetrieveAffiliations() {
        Map<Id, List<npe5__Affiliation__c>> affiliationRecords = new Map<Id, List<npe5__Affiliation__c>>();

        Contact testCon0 = returnContact('Affiliation5');
        System.assertEquals('Affiliation5', testCon0.FirstName);

        Contact testCon1 = returnContact('Affiliation6');
        System.assertEquals('Affiliation6', testCon1.FirstName);

        Set<Id> testConsAccounts = new Set<Id>{ testCon0.AccountId, testCon1.AccountId };

        Test.startTest();

        affiliationRecords = OPP_AutomatedSoftCreditsService.retrieveAffiliations(testConsAccounts);

        Test.stopTest();

        System.assertEquals(2, affiliationRecords.size());
        System.assertEquals(2, affiliationRecords.get(testCon0.AccountId).size());
    }


    /*********************************************************************************************************
    * @description Tests the Opportunity Contact Role records were created with the expected values.
    * verify:
    *   Opportunity Contact Role records created with expected values.
    * @return void
    **********************************************************************************************************/
    private static testMethod void testBuildAffiliationOCRs() {
        List<OpportunityContactRole> creatededOCRs = new List<OpportunityContactRole>();

        Map<Id, List<Id>> accountIdToOpportunityIds = new Map<Id, List<Id>>();
        Map<Id, List<npe5__Affiliation__c>> affiliationRecords = new Map<Id, List<npe5__Affiliation__c>>();
        Map<Id, List<OpportunityContactRole>> transactionOCR = new Map<Id, List<OpportunityContactRole>>();

        Contact testCon0 = returnContact('Affiliation5');
        System.assertEquals('Affiliation5', testCon0.FirstName);

        Contact testCon1 = returnContact('Affiliation6');
        System.assertEquals('Affiliation6', testCon1.FirstName);

        List<Id> testAccoutIds = new List<Id>{ testCon0.AccountId, testCon1.AccountId };

        List<Opportunity> opptys = [SELECT Id, AccountId FROM Opportunity WHERE AccountId IN :testAccoutIds];
        for (Opportunity eachOppty : opptys) {
            accountIdToOpportunityIds.put(eachOppty.AccountId, new List<Id>{ eachOppty.Id });
        }
        System.assertEquals(2, accountIdToOpportunityIds.size());

        affiliationRecords = OPP_AutomatedSoftCreditsService.retrieveAffiliations(accountIdToOpportunityIds.keySet());
        System.assertEquals(2, affiliationRecords.size());
        System.assertEquals(2, affiliationRecords.get(testCon0.AccountId).size());
        System.assertEquals(1, affiliationRecords.get(testCon1.AccountId).size());

        Test.startTest();

        List<OpportunityContactRole> retrievedOCRs = [SELECT Id, OpportunityId, ContactId, Role FROM OpportunityContactRole];
        System.assertEquals(13, retrievedOCRs.size()); // Seven OCRs for the Opportunities and six OCRs for Relationship and Affiliations
        transactionOCR.put(retrievedOCRs[0].OpportunityId, retrievedOCRs);

        creatededOCRs = OPP_AutomatedSoftCreditsService.buildAffiliationOCRs(accountIdToOpportunityIds, affiliationRecords, transactionOCR);
        System.assertEquals(0, creatededOCRs.size()); // Confirm no duplicate OCRs were created

        // Update Affiliation records
        List<npe5__Affiliation__c> testCon0Affiliations = affiliationRecords.get(testCon0.AccountId);
        testCon0Affiliations[0].Related_Opportunity_Contact_Role__c = RELATIONSHIP_OPPORTUNITY_CONTACT_ROLE_SOLICITOR;
        testCon0Affiliations[1].Related_Opportunity_Contact_Role__c = RELATIONSHIP_OPPORTUNITY_CONTACT_ROLE_SOLICITOR;
        update testCon0Affiliations;

        creatededOCRs = OPP_AutomatedSoftCreditsService.buildAffiliationOCRs(accountIdToOpportunityIds, affiliationRecords, transactionOCR);

        Test.stopTest();

        System.assertEquals(0, creatededOCRs.size()); // Confirm no new OCR records were created
    }


    /*********************************************************************************************************
    * @description Tests the retrieval of Opportunity Contact Role records for given Opportunities.
    * verify:
    *   Opportunity Contact Role records were retrieved.
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRetrieveOpportunityContactRoles() {
        List<List<Id>> opptyIds = new List<List<Id>>();
        Map<Id, List<OpportunityContactRole>> transactionOCR = new Map<Id, List<OpportunityContactRole>>();

        Contact testCon = returnContact('Primary0');
        System.assertEquals('Primary0', testCon.FirstName);

        List<Opportunity> opptys = [SELECT Id FROM Opportunity WHERE Primary_Contact__c = :testCon.Id];
        for (Opportunity eachOppty : opptys) {
            opptyIds.add(new List<Id>{ eachOppty.Id });
        }

        Test.startTest();

        Map<Id, List<OpportunityContactRole>> opportunityIdToOCR = OPP_AutomatedSoftCreditsService.retrieveOpportunityContactRoles(opptyIds, transactionOCR.values());

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
        List<List<Id>> opptyIds = new List<List<Id>>();
         Map<Id, List<OpportunityContactRole>> transactionOCR = new Map<Id, List<OpportunityContactRole>>();

        Contact testCon = returnContact('Primary1');
        System.assertEquals('Primary1', testCon.FirstName);

        List<Opportunity> opptys = [SELECT Id FROM Opportunity WHERE Primary_Contact__c = :testCon.Id];
        for (Opportunity eachOppty : opptys) {
            opptyIds.add(new List<Id>{ eachOppty.Id });
        }

        Test.startTest();

        Map<Id, List<OpportunityContactRole>> opportunityIdToOCR = OPP_AutomatedSoftCreditsService.retrieveOpportunityContactRoles(opptyIds, transactionOCR.values());
        List<OpportunityContactRole> retrievedOCRs = opportunityIdToOCR.get(opptyIds[0][0]);

        Map<Id, List<npe4__Relationship__c>> relationshipRecords = OPP_AutomatedSoftCreditsService.retrieveRelationships(new Set<Id>{ testCon.Id });
        npe4__Relationship__c currentRelationship = relationshipRecords.get(testCon.Id)[0];

        isDuplicate = OPP_AutomatedSoftCreditsService.isDuplicateOCR(retrievedOCRs,
                                                                     currentRelationship.npe4__RelatedContact__c);

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
        List<List<Id>> opptyIds = new List<List<Id>>();
        Map<Id, List<OpportunityContactRole>> transactionOCR = new Map<Id, List<OpportunityContactRole>>();

        Contact testCon = returnContact('Primary0');
        System.assertEquals('Primary0', testCon.FirstName);

        List<Opportunity> opptys = [SELECT Id FROM Opportunity WHERE Primary_Contact__c = :testCon.Id];
        for (Opportunity eachOppty : opptys) {
            opptyIds.add(new List<Id>{ eachOppty.Id });
        }

        Test.startTest();

        Map<Id, List<OpportunityContactRole>> opportunityIdToOCR = OPP_AutomatedSoftCreditsService.retrieveOpportunityContactRoles(opptyIds, transactionOCR.values());
        List<OpportunityContactRole> retrievedOCRs = opportunityIdToOCR.get(opptyIds[0][0]);

        Map<Id, List<npe4__Relationship__c>> relationshipRecords = OPP_AutomatedSoftCreditsService.retrieveRelationships(new Set<Id>{ testCon.Id });
        npe4__Relationship__c currentRelationship = relationshipRecords.get(testCon.Id)[0];
        currentRelationship.Related_Opportunity_Contact_Role__c = RELATIONSHIP_OPPORTUNITY_CONTACT_ROLE_SOFT_CREDIT;
        update currentRelationship;

        isDuplicate = OPP_AutomatedSoftCreditsService.isDuplicateOCR(retrievedOCRs,
                                                                     currentRelationship.npe4__RelatedContact__c);

        Test.stopTest();

        System.assertEquals(true, isDuplicate);
    }


    /*********************************************************************************************************
    * @description Tests if there are multiple Relationship records for a Contact and removes duplicates.
    * verify:
    *   Relationship records are unique based on Contac.
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRemoveDuplicateAssociatedRecordsForRelationships() {
        Map<Id, List<npe4__Relationship__c>> relationshipRecords = new Map<Id, List<npe4__Relationship__c>>();

        Contact testCon0 = returnContact('Primary0');
        System.assertEquals('Primary0', testCon0.FirstName);

        Contact testCon1 = returnContact('Primary1');
        System.assertEquals('Primary1', testCon1.FirstName);

        Set<Id> testCons = new Set<Id>{ testCon0.Id, testCon1.Id };

        npe4__Relationship__c testCon0ToTestCon1
                = new npe4__Relationship__c(npe4__Contact__c = testCon0.Id,
                                            npe4__RelatedContact__c = testCon1.Id,
                                            npe4__Type__c = RELATIONSHIP_TYPE_FRIEND,
                                            npe4__Status__c = RELATIONSHIP_STATUS_CURRENT,
                                            Related_Opportunity_Contact_Role__c = RELATIONSHIP_OPPORTUNITY_CONTACT_ROLE_SOLICITOR);

        insert testCon0ToTestCon1;

        Test.startTest();

        relationshipRecords = OPP_AutomatedSoftCreditsService.retrieveRelationships(testCons);

        Test.stopTest();

        System.assertEquals(2, relationshipRecords.size());
        System.assertEquals(2, relationshipRecords.get(testCon0.Id).size());
        System.assertEquals(1, relationshipRecords.get(testCon1.Id).size());
    }


    /*********************************************************************************************************
    * @description Tests if there are multiple Affiliation records for a Contact and removes duplicates.
    * verify:
    *   Affiliation records are unique based on Contac.
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRemoveDuplicateAssociatedRecordsForAffiliations() {
        Map<Id, List<npe5__Affiliation__c>> affiliationRecords = new Map<Id, List<npe5__Affiliation__c>>();

        Contact testCon0 = returnContact('Affiliation5');
        System.assertEquals('Affiliation5', testCon0.FirstName);

        Contact testCon1 = returnContact('Related2');
        System.assertEquals('Related2', testCon1.FirstName);

        Set<Id> testConsAccounts = new Set<Id>{ testCon0.AccountId, testCon1.AccountId };

        npe5__Affiliation__c testCon5AccountToTestCon2
            = new npe5__Affiliation__c(npe5__Organization__c = testCon0.AccountId,
                                       npe5__Contact__c = testCon1.Id,
                                       npe5__Role__c = RELATIONSHIP_TYPE_PARTNER,
                                       npe5__Status__c = RELATIONSHIP_STATUS_CURRENT,
                                       Related_Opportunity_Contact_Role__c = RELATIONSHIP_OPPORTUNITY_CONTACT_ROLE_SOLICITOR);

        insert testCon5AccountToTestCon2;

        Test.startTest();

        affiliationRecords = OPP_AutomatedSoftCreditsService.retrieveAffiliations(testConsAccounts);

        Test.stopTest();


        //System.assertEquals(false, isDuplicate);

        System.assertEquals(1, affiliationRecords.size());
        System.assertEquals(2, affiliationRecords.get(testCon0.AccountId).size());
    }



    /*********************************************************************************************************
    * @description Returns a Contact based value passed into the method.
    *
    * @return Contact
    **********************************************************************************************************/
    private static Contact returnContact(String searchValue) {
        Contact retrievedContact = new Contact();

        List<Contact> allContacts = [SELECT Id, AccountId, FirstName FROM Contact];

        for (Contact eachContact : allContacts) {
            if (searchValue.equalsIgnoreCase(eachContact.FirstName)) {
                retrievedContact = eachContact;
            }
        }

        return retrievedContact;
    }


}