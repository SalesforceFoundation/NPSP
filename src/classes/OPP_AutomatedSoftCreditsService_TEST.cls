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
    private static final String RELATIONSHIP_STATUS_CURRENT = 'Current';
    private static final String RELATIONSHIP_OPPORTUNITY_CONTACT_ROLE_SOFT_CREDIT = 'Soft Credit';
    private static final String RELATIONSHIP_OPPORTUNITY_CONTACT_ROLE_SOLICITOR = 'Solicitor';


    /*********************************************************************************************************
    * @description Creates data to test Automated Soft Credits functionality
    *
    * @return void
    **********************************************************************************************************/
    @testSetup static void createAutomatedSoftCreditsData() {
        Contact primaryCon = new Contact(FirstName = 'Primary', LastName = 'Contact');
        insert primaryCon;

        Contact relatedCon = new Contact(FirstName = 'Related', LastName = 'Contact');
        insert relatedCon;

        npe4__Relationship__c primeToRelated
                = new npe4__Relationship__c(npe4__Contact__c = primaryCon.Id,
                                            npe4__RelatedContact__c = relatedCon.Id,
                                            npe4__Type__c = RELATIONSHIP_TYPE_FRIEND,
                                            npe4__Status__c = RELATIONSHIP_STATUS_CURRENT,
                                            Related_Opportunity_Contact_Role__c = RELATIONSHIP_OPPORTUNITY_CONTACT_ROLE_SOFT_CREDIT);
        insert primeToRelated;

        Opportunity oppForRelationships
             = new Opportunity(Name = 'Automated Soft Credits Oppty',
                                AccountId =  primaryCon.AccountId,
                                Primary_Contact__c = primaryCon.Id,
                                Amount = 100,
                                CloseDate = System.today(),
                                StageName = RELATIONSHIP_OPPORTUNITY_CONTACT_ROLE_SOFT_CREDIT);
        insert oppForRelationships;
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

        Contact relatedContact = [SELECT Id FROM Contact WHERE FirstName = 'Related'][0];
        OpportunityContactRole retrievedOCR = [SELECT Id, ContactId, Role FROM OpportunityContactRole WHERE ContactId = :relatedContact.Id][0];

        Test.stopTest();

        System.assertEquals(relatedContact.Id, retrievedOCR.ContactId);
        System.assertEquals(RELATIONSHIP_OPPORTUNITY_CONTACT_ROLE_SOFT_CREDIT, retrievedOCR.Role);
    }


    /*********************************************************************************************************
    * @description Tests the retrieval of Relationship records for the Opportunity's Primary Contact.
    * verify:
    *   Relationship records were retrieved.
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRetrieveRelationships() {
        Map<Id, List<npe4__Relationship__c>> relationshipRecords = new Map<Id, List<npe4__Relationship__c>>();

        Contact primaryContact = [SELECT Id FROM Contact WHERE FirstName = 'Primary'][0];

        Test.startTest();

        relationshipRecords = OPP_AutomatedSoftCreditsService.retrieveRelationships(new Set<Id>{ primaryContact.Id });

        Test.stopTest();

        System.assertEquals(1, relationshipRecords.size());
        System.assertEquals(relationshipRecords.get(primaryContact.Id)[0].npe4__Contact__c, primaryContact.Id);
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

        Contact primaryContact = [SELECT Id FROM Contact WHERE FirstName = 'Primary'][0];
        Opportunity primaryConOppty = [SELECT Id FROM Opportunity WHERE Primary_Contact__c = :primaryContact.Id][0];
        primaryContactIdToOpportunityId.put(primaryContact.Id, primaryConOppty.Id);
        relationshipRecords = OPP_AutomatedSoftCreditsService.retrieveRelationships(new Set<Id>{ primaryContact.Id });

        Test.startTest();

        Contact relatedContact = [SELECT Id FROM Contact WHERE FirstName = 'Related'][0];

        creatededOCRs = OPP_AutomatedSoftCreditsService.buildRelationshipOCRs(primaryContactIdToOpportunityId, relationshipRecords);
        List<OpportunityContactRole> retrievedOCRs = [SELECT Id, ContactId, Role FROM OpportunityContactRole WHERE ContactId = :relatedContact.Id];

        Test.stopTest();

        System.assertEquals(0, creatededOCRs.size()); // Confirm no duplicate OCRs were created
        System.assertEquals(retrievedOCRs[0].Role, RELATIONSHIP_OPPORTUNITY_CONTACT_ROLE_SOFT_CREDIT);
    }


    /*********************************************************************************************************
    * @description Tests the retrieval of Opportunity Contact Role records for given Opportunities.
    * verify:
    *   Opportunity Contact Role records were retrieved.
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRetrieveOpportunityContactRoles() {
        Contact primaryContact = [SELECT Id FROM Contact WHERE FirstName = 'Primary'][0];
        Opportunity primaryContactOpportunity = [SELECT Id FROM Opportunity WHERE Primary_Contact__c = :primaryContact.Id];

        Test.startTest();

        Map<Id, List<OpportunityContactRole>> opportunityIdToOCR = OPP_AutomatedSoftCreditsService.retrieveOpportunityContactRoles(new Map<Id, Id>{ primaryContact.Id => primaryContactOpportunity.Id});

        Test.stopTest();

        System.assertEquals(2, opportunityIdToOCR.get(primaryContactOpportunity.Id).size());
        System.assertEquals(primaryContactOpportunity.Id, opportunityIdToOCR.get(primaryContactOpportunity.Id)[0].OpportunityId);
    }


    /*********************************************************************************************************
    * @description Tests if a Relationship record has the same values an Opportunity Contact Role record.
    * verify:
    *   Relationship record is a duplicate.
    * @return void
    **********************************************************************************************************/
    private static testMethod void testIsDuplicateOCR() {
        Boolean isDuplicate = false;

        Contact primaryContact = [SELECT Id FROM Contact WHERE FirstName = 'Primary'][0];
        Contact relatedContact = [SELECT Id FROM Contact WHERE FirstName = 'Related'][0];
        Opportunity primaryContactOpportunity = [SELECT Id FROM Opportunity WHERE Primary_Contact__c = :primaryContact.Id][0];

        Test.startTest();

        List<OpportunityContactRole> retrievedOCRs = [SELECT Id, ContactId, Role FROM OpportunityContactRole WHERE ContactId = :relatedContact.Id];
        Map<Id, List<npe4__Relationship__c>> relationshipRecords = OPP_AutomatedSoftCreditsService.retrieveRelationships(new Set<Id>{ primaryContact.Id });

        npe4__Relationship__c currentRelationship = relationshipRecords.get(primaryContact.Id)[0];
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

        Contact primaryContact = [SELECT Id FROM Contact WHERE FirstName = 'Primary'][0];
        Contact relatedContact = [SELECT Id FROM Contact WHERE FirstName = 'Related'][0];
        Opportunity primaryContactOpportunity = [SELECT Id FROM Opportunity WHERE Primary_Contact__c = :primaryContact.Id];

        Test.startTest();

        List<OpportunityContactRole> retrievedOCRs = [SELECT Id, ContactId, Role FROM OpportunityContactRole WHERE ContactId = :relatedContact.Id];
        retrievedOCRs[0].Role = RELATIONSHIP_OPPORTUNITY_CONTACT_ROLE_SOLICITOR;
        update retrievedOCRs;

        Map<Id, List<npe4__Relationship__c>> relationshipRecords = OPP_AutomatedSoftCreditsService.retrieveRelationships(new Set<Id>{ primaryContact.Id });

        npe4__Relationship__c currentRelationship = relationshipRecords.get(primaryContact.Id)[0];
        isDuplicate = OPP_AutomatedSoftCreditsService.isDuplicateOCR(retrievedOCRs,
                                                                     currentRelationship.npe4__RelatedContact__c,
                                                                     currentRelationship.Related_Opportunity_Contact_Role__c);

        Test.stopTest();

        System.assertEquals(false, isDuplicate);
    }


}