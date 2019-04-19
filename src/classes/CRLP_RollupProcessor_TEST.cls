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
* @group Customizable Rollups Operations Services
* @description Unit Tests for the Rollup Processor Class
*/
@IsTest(IsParallel=true)
private class CRLP_RollupProcessor_TEST {

    /**
    * @description Validate the Account Hard Credit Non-Skew processes as expected
    */
    @IsTest
    private static void shouldHandleAccountHardCreditNonSkew() {
        CMT_UnitTestData_TEST.mockFullSetOfRollupDefinitions();

        Account account = buildMockAccount();
        List<SObject> opps = new List<SObject>{ buildMockOpportunity(account.Id, 100) };

        Test.startTest();

        CRLP_RollupProcessor processor = new CRLP_RollupProcessor()
                .withBatchJobMode(CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode)
                .withRollupType(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit)
                .withSummaryRecord(account)
                .withDetailRecords(opps);

        System.assertEquals(Opportunity.SObjectType, processor.detailObjectType);
        System.assertEquals('AccountId', processor.parentKeyField);
        System.assertEquals('AccountId', processor.parentRelationshipField);
        System.assertEquals(null, processor.parentRelationshipObject);

        System.assertEquals(false, processor.isSkewMode);
        System.assertEquals(false, processor.isOppContactRoleSoftCreditRollup);

        Account updatedAcct = (Account)processor.startRollupProcessing()[0];
        System.assertEquals(1, updatedAcct.npo02__NumberOfClosedOpps__c,
            'The number of closed opportunities for this Account should be 1');
        System.assertEquals(100, updatedAcct.npo02__TotalOppAmount__c,
            'The total of closed opportunities for this Account should be 100');
    }

    /**
    * @description Validate the Contact Soft Credit Skew processes as expected
    */
    @IsTest
    private static void shouldHandleContactSoftCreditSkewMode() {
        CMT_UnitTestData_TEST.mockFullSetOfRollupDefinitions();

        Account account = buildMockAccount();
        Contact contact = buildMockContact(account.Id);
        Opportunity opp = buildMockOpportunity(account.Id, 100);
        OpportunityContactRole ocr = buildMockContactRoles(opp, new List<Contact>{ contact })[0];
        Partial_Soft_Credit__c psc = buildMockPartialSoftCredit(opp, ocr, contact, opp.Amount);

        CRLP_RollupProcessingOptions.ProcessingOptions options = new CRLP_RollupProcessingOptions.ProcessingOptions();
        options.useRollupDefsByParentIdMap = true;

        Test.startTest();

        CRLP_RollupProcessor processor = new CRLP_RollupProcessor()
                .withBatchJobMode(CRLP_RollupProcessingOptions.BatchJobMode.SkewMode)
                .withRollupType(CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit)
                .withSummaryRecord(contact)
                .withDetailRecords(new List<SObject> { psc })
                .withJobOptions(options);

        System.assertEquals(OpportunityContactRole.SObjectType, processor.detailObjectType);
        System.assertEquals(UTIL_Namespace.StrAllNSPrefix('Contact__c'), processor.parentKeyField);
        System.assertEquals(UTIL_Namespace.StrAllNSPrefix('Contact__c'), processor.parentRelationshipField);
        System.assertEquals(null, processor.parentRelationshipObject);

        System.assertEquals(1, processor.detailRecordsByParentId.get(contact.Id).size());

        System.assertEquals(true, processor.isSkewMode);
        System.assertEquals(true, processor.isOppContactRoleSoftCreditRollup);

        // Run the Account through the Skew Mode processor.
        List<SObject> updatedRecords = processor.startRollupProcessing();

        System.assert(updatedRecords.isEmpty());
        System.assertEquals(1, processor.getRollupDefsForParent(contact.Id).size());
        System.assertNotEquals(null, processor.getLastParentIdProcessed());
        System.assertEquals(true, processor.hasLastParentIdCompleted());

        List<CRLP_Rollup> previousRollupDefs = processor.getRollupDefsForParent(contact.Id);

        // In Skew Mode, the last Contact processed has to be sent back through the
        // completeRollupForSingleSummaryRecord() method.
        processor = new CRLP_RollupProcessor()
                .withRollupType(CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit)
                .withBatchJobMode(CRLP_RollupProcessingOptions.BatchJobMode.SkewMode)
                .withSummaryRecord(contact)
                .withDetailRecords(new List<SObject>())
                .withRollupDefinitions(previousRollupDefs)
                .withJobOptions(options);

        Contact updatedContact = (Contact)processor.completeRollupForSingleSummaryRecord(contact);

        System.assertEquals(1, updatedContact.Number_of_Soft_Credits__c,
                'The number of closed opportunities for this Account should be 1');
        System.assertEquals(100, updatedContact.npo02__Soft_Credit_Total__c,
                'The total of closed opportunities for this Account should be 100');
    }

    /**
    * @description Validate that the processing options var in the Processor doesn't crash if it's not set
    */
    @IsTest
    private static void shouldHandleNullJobOptions() {
        CRLP_RollupProcessor processor = new CRLP_RollupProcessor();

        System.assertEquals(true, processor.options.doSummaryObjectComparison);
        System.assertEquals(false, processor.options.useRollupDefsByParentIdMap);

        CRLP_RollupProcessingOptions.ProcessingOptions options = new CRLP_RollupProcessingOptions.ProcessingOptions();
        options.useRollupDefsByParentIdMap = true;
        options.doSummaryObjectComparison = false;

        processor.withJobOptions(options);
        System.assertEquals(false, processor.options.doSummaryObjectComparison);
        System.assertEquals(true, processor.options.useRollupDefsByParentIdMap);
    }

    /**
    * @description Validate the PreviouslyProcessed Map in the process properly sets and retrieves values.
    */
    @IsTest
    private static void shouldHandleAlreadyProcessedMap() {
        Id accountId = UTIL_UnitTestData_TEST.mockId(Account.SObjectType);
        Id oppId1 = UTIL_UnitTestData_TEST.mockId(Opportunity.SObjectType);
        Id oppId2 = UTIL_UnitTestData_TEST.mockId(Opportunity.SObjectType);

        Map<Id, Set<Id>> previouslyProcessedOpps = new Map<Id, Set<Id>>{
            accountId => new Set<Id>{ oppId1 }
        };

        Test.startTest();

        CRLP_RollupProcessor processor = new CRLP_RollupProcessor();

        System.assertEquals(false, processor.isOppAlreadyProcessedForParent(accountId, oppId1));
        System.assertEquals(false, processor.isOppAlreadyProcessedForParent(accountId, oppId2));
        System.assertEquals(null, processor.getPreviouslyProcessedOppIds(accountId));

        processor.withPreviouslyProcessedOppIdsMap(previouslyProcessedOpps);

        System.assertEquals(true, processor.isOppAlreadyProcessedForParent(accountId, oppId1));
        System.assertEquals(false, processor.isOppAlreadyProcessedForParent(accountId, oppId2));
        System.assertEquals(1, processor.getPreviouslyProcessedOppIds(accountId).size());
    }

    /**
    * @description Validate the Parameter Validation method throws exceptions for missing data
    */
    @IsTest
    private static void shouldHandleRequiredParameterValidation() {
        CMT_UnitTestData_TEST.mockFullSetOfRollupDefinitions();

        Account account = buildMockAccount();

        Test.startTest();

        CRLP_RollupProcessor processor = new CRLP_RollupProcessor()
                .withBatchJobMode(CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode)
                .withSummaryRecords(new List<Account>{ account });

        // Test with a missing Rollup Type
        try {
            processor.validateProcessSettingsBeforeStarting();
            System.assert(false, 'An exception should not have been thrown');
        } catch (Exception ex) {
            System.assert(ex.getMessage().containsIgnoreCase('RollupType'),
                    'A CRLP_RollupException exception should have been thrown: ' + ex.getMessage());
        }

        // Test with a missing Parent (Summary) record
        processor.withSummaryRecords(null);
        processor.withRollupType(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit);
        try {
            processor.validateProcessSettingsBeforeStarting();
            System.assert(false, 'An exception should not have been thrown');
        } catch (Exception ex) {
            System.assert(ex.getMessage().containsIgnoreCase('Summary'),
                    'A CRLP_RollupException exception should have been thrown: ' + ex.getMessage());
        }

        // Test with both required parameters provided.
        processor.withSummaryRecords(new List<Account>{ account });
        processor.validateProcessSettingsBeforeStarting();
        System.assert(true, 'An exception should not have been thrown');
    }

    /**
    * @description Validate the cleanDetailOppsListForSoftCreditMode() method removes the expected
    * previously processed detail records
    */
    @IsTest
    private static void shouldRemoveSummaryRecordWithNoDetailRecords() {

        Account account = buildMockAccount();
        List<Contact> contacts = new List<Contact>();
        List<Opportunity> opps = new List<Opportunity>();

        for (Integer n=0; n<3; n++) {
            contacts.add(buildMockContact(account.Id));
            opps.add(buildMockOpportunity(account.Id, 100));
        }
        List<OpportunityContactRole> ocrs = buildMockContactRoles(opps[0], contacts);

        // Create same set of 3 PSC records for each Contact and Opportunity
        List<Partial_Soft_Credit__c> detailRecords = new List<Partial_Soft_Credit__c>();
        for (Integer numContact =0; numContact <3; numContact++) {
            for (Integer numOpp =0; numOpp <3; numOpp++) {
                detailRecords.add(buildMockPartialSoftCredit(opps[numOpp], ocrs[numOpp], contacts[numContact], 100));
            }
        }

        // Define the set of Previously processed data such that Contact0 will have 0 records not previously processeed
        Map<Id, Set<Id>> previouslyProcessedOpps = new Map<Id, Set<Id>>{
            contacts[0].Id => new Set<Id>{ opps[0].Id, opps[1].Id, opps[2].Id },
            contacts[1].Id => new Set<Id>{ opps[0].Id, opps[1].Id },
            contacts[2].Id => new Set<Id>{ opps[0].Id }
        };

        Test.startTest();

        CRLP_RollupProcessor processor = new CRLP_RollupProcessor()
            .withBatchJobMode(CRLP_RollupProcessingOptions.BatchJobMode.SkewMode)
            .withRollupType(CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit)
            .withSummaryRecords(contacts)
            .withDetailRecords(detailRecords)
            .withPreviouslyProcessedOppIdsMap(previouslyProcessedOpps);

        for (Integer n=0; n < contacts.size(); n++) {
            List<SObject> pscDetails = processor.detailRecordsByParentId.get(contacts[n].Id);
            System.assertEquals(n, processor.cleanDetailOppsListForSoftCreditMode(contacts[n].Id, pscDetails).size(),
                String.format('The cleans process should return {0} Detail records for Contact {0}',
                new List<String>{ n.format() })
            );
        }
    }

    // **************************** HELPER METHODS ****************************

    /**
     * @description Instantiate a single mock account that will not be inserted
     */
    private static Account buildMockAccount() {
        return new Account(
            Id = UTIL_UnitTestData_TEST.mockId(Account.SObjectType),
            Name = 'TestAccount',
            npo02__TotalOppAmount__c = null,
            npo02__NumberOfClosedOpps__c = null
        );
    }

    private static Contact buildMockContact(Id acctId) {
        return new Contact(
            Id = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType),
            AccountId = acctId,
            LastName = 'TestContact',
            Number_of_Soft_Credits__c = null,
            npo02__Soft_Credit_Total__c = null
        );
    }

    /**
     * @description Instantiate a single mock Opportunity that will not be inserted
     */
    private static Opportunity buildMockOpportunity(Id accountId, Double amt) {
        return new Opportunity(
            Id = UTIL_UnitTestData_TEST.mockId(Opportunity.SObjectType),
            AccountId = accountId,
            Amount = amt,
            CloseDate = Date.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );
    }

    /**
     * @description Instantiate mock OpportunityContactRole records for each Contact
     */
    private static List<OpportunityContactRole> buildMockContactRoles(Opportunity opp, List<Contact> contacts) {
        final String donorRole = UTIL_CustomSettingsFacade.DEFAULT_OPPORTUNITY_CONTACT_ROLE_DONOR;
        List<OpportunityContactRole> ocrs = new List<OpportunityContactRole>();

        for (Contact c : contacts) {
            ocrs.add(new OpportunityContactRole(
                Id = UTIL_UnitTestData_TEST.mockId(OpportunityContactRole.SObjectType),
                OpportunityId = opp.Id,
                ContactId = c.Id,
                Role = donorRole,
                IsPrimary = false
            ));
        }
        return ocrs;
    }

    /**
     * @description Instantiate a mock PartialSoftCredit records for passed OCR and Contact
     */
    private static Partial_Soft_Credit__c buildMockPartialSoftCredit(Opportunity opp,
            OpportunityContactRole ocr, Contact con, Decimal amt
    ) {
        return new Partial_Soft_Credit__c(
            Id = UTIL_UnitTestData_TEST.mockId(Partial_Soft_Credit__c.SObjectType),
            Opportunity__c = opp.Id,
            Opportunity__r = opp,
            Contact__c = con.Id,
            Contact__r = con,
            Role_Name__c = UTIL_CustomSettingsFacade.DEFAULT_OPPORTUNITY_CONTACT_ROLE_DONOR,
            Contact_Role_Id__c = ocr.Id,
            Amount__c = amt
        );
    }
}