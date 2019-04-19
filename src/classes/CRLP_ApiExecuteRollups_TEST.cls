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
* @group API
* @description Unit Tests for the Customizable Rollups Api Execution Service class
*/
@IsTest(IsParallel=true)
private class CRLP_ApiExecuteRollups_TEST {

    /**
     * @description Verify that the call to executeRollups() successfully completes a ContactSoftCredit
     * rollup and the target (summary) record is not updated as a result.
     */
    @IsTest
    private static void shouldCompleteExecuteRollupsForContactSoftCredit() {
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
            Customizable_Rollups_Enabled__c = true
        ));

        CMT_UnitTestData_TEST.mockFullSetOfRollupDefinitions();

        List<Contact> contacts = new List<Contact>{
            UTIL_UnitTestData_TEST.getContact(),
            UTIL_UnitTestData_TEST.getContact()
        };
        insert contacts;
        contacts = [SELECT Id, AccountId FROM Contact WHERE Id = :contacts];

        Opportunity opp = buildMockOpportunity(contacts[0].AccountId,100);
        List<OpportunityContactRole> ocrRecords = buildMockContactRoles(opp, contacts);
        Partial_Soft_Credit__c psc = buildMockPartialSoftCredit(opp, ocrRecords[0], contacts[0], opp.Amount);

        Map<Id, Map<SObjectType, List<SObject>>> rollupData = new Map<Id, Map<SObjectType, List<SObject>>>{
            opp.Id => new Map<SObjectType, List<SObject>>{
                Opportunity.SObjectType => new List<SObject>{ opp },
                OpportunityContactRole.SObjectType => ocrRecords,
                Partial_Soft_Credit__c.SObjectType => new List<SObject>{ psc }
            }
        };

        Test.startTest();

        CRLP_ApiExecuteRollups service = new CRLP_ApiExecuteRollups()
            .withRollupType(CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit)
            .withRollupData(rollupData)
            .withCommitToDatabase(true)
            .withParentId(contacts[0].Id);

        List<CRLP_Rollup> rollupDefs = service.executeRollups();

        Test.stopTest();

        System.assertEquals(1, rollupDefs[0].theCount,
            'The Rollup Definition counter var should be set to 1');
        System.assertEquals(opp.Amount, rollupDefs[0].theSum,
            'The Rollup Definition sum var should be set to ' + opp.Amount);

        Contact contact1 = [SELECT Id, Number_of_Soft_Credits__c, npo02__Soft_Credit_Total__c
            FROM Contact
            WHERE Id = :contacts[0].Id LIMIT 1];

        System.assertEquals(1, contact1.Number_of_Soft_Credits__c,
            'The Contact Number_of_Soft_Credits__c should be 1');
        System.assertEquals(opp.Amount, contact1.npo02__Soft_Credit_Total__c,
            'The Contact npo02__Soft_Credit_Total__c should be ' + opp.Amount);
    }

    /**
     * @description Verify that the call to executeRollups() successfully completes a GAU
     * rollup and the target (summary) record is not updated as a result.
     */
    @IsTest
    private static void shouldCompleteExecuteRollupsForGAU() {
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
            Customizable_Rollups_Enabled__c = true
        ));

        CMT_UnitTestData_TEST.mockFullSetOfRollupDefinitions();

        List<General_Accounting_Unit__c> gaus = new List<General_Accounting_Unit__c>{
            new General_Accounting_Unit__c(Name = 'GAU 1'),
            new General_Accounting_Unit__c(Name = 'GAU 2')
        };
        insert gaus;

        Account account = new Account(
            Id = UTIL_UnitTestData_TEST.mockId(Account.SObjectType)
        );

        Opportunity opp = buildMockOpportunity(account.Id,100);
        List<Allocation__c> allocations = buildMockAllocations(opp, gaus, 50);

        Map<Id, Map<SObjectType, List<SObject>>> rollupData = new Map<Id, Map<SObjectType, List<SObject>>>{
            opp.Id => new Map<SObjectType, List<SObject>>{
                Opportunity.SObjectType => new List<SObject>{ opp },
                Allocation__c.SObjectType => allocations
            }
        };

        Test.startTest();

        CRLP_ApiExecuteRollups service = new CRLP_ApiExecuteRollups()
            .withRollupType(CRLP_RollupProcessingOptions.RollupType.GAU)
            .withRollupData(rollupData)
            .withCommitToDatabase(true)
                .withParentId(gaus[0].Id);

        List<CRLP_Rollup> rollupDefs = service.executeRollups();

        Test.stopTest();

        System.assertEquals(1, rollupDefs[0].theCount,
            'The Rollup Definition counter var should be set to 1');
        System.assertEquals(allocations[0].Amount__c, rollupDefs[0].theSum,
            'The Rollup Definition sum var should be set to ' + allocations[0].Amount__c);

        General_Accounting_Unit__c gau = [SELECT Id, Total_Allocations__c, Total_Number_of_Allocations__c
            FROM General_Accounting_Unit__c
        WHERE Id = :gaus[0].Id LIMIT 1];

        System.assertEquals(1, gau.Total_Number_of_Allocations__c,
            'The Contact Total_Number_of_Allocations__c should be 1');
        System.assertEquals(allocations[0].Amount__c, gau.Total_Allocations__c,
            'The Contact Total_Allocations__c should be ' + allocations[0].Amount__c);
    }

    /**
     * @description Validate that the buildPartialSoftCreditRecordsFromOCRs() method properly matches
     * and builds a set of PartialSoftCredit records to use for the rollup operations.
     */
    @IsTest
    private static void shouldProperlyConvertOCRs() {

        Account account = new Account(
            Id = UTIL_UnitTestData_TEST.mockId(Account.SObjectType),
            Name = 'TestAccount'
        );
        List<Contact> contacts = new List<Contact>{
            UTIL_UnitTestData_TEST.getContact(),
            UTIL_UnitTestData_TEST.getContact()
        };
        for (Contact c : contacts) {
            c.Id = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
            c.AccountId = account.Id;
            c.npo02__Soft_Credit_Total__c = null;
            c.Number_of_Soft_Credits__c = null;
        }

        Opportunity opp = buildMockOpportunity(account.Id,100);
        List<OpportunityContactRole> ocrRecords = buildMockContactRoles(opp, new List<Contact>{ contacts[0] });

        Test.startTest();

        // =============================================================================
        // Test 1: Partial Soft Credit is for a different Contact than the OCR, and the
        // Summary record assigned to the service.
        List<Partial_Soft_Credit__c> pscRecords = new List<Partial_Soft_Credit__c>{
            buildMockPartialSoftCredit(opp, ocrRecords[0], contacts[1], (opp.Amount / 2))
        };

        CRLP_ApiExecuteRollups service = new CRLP_ApiExecuteRollups()
            .withRollupType(CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit)
            .withParentId(contacts[0].Id);
        List<Partial_Soft_Credit__c> builtPSCs = service.buildPartialSoftCreditRecordsFromOCRs(opp, ocrRecords, pscRecords);

        System.assertEquals(ocrRecords.size(), builtPSCs.size(),
            'The number of built PartialSoftCredit records should match the number of OCR records');
        System.assertEquals(opp.Amount, builtPSCs[0].Amount__c,
            'The resulting PartialSoftCredit record Amount should match the Opportunity');

        // =============================================================================
        // Test 2: Partial Soft Credit is for a same Contact than the OCR, and the
        // Summary record assigned to the service.
        pscRecords = new List<Partial_Soft_Credit__c>{
            buildMockPartialSoftCredit(opp, ocrRecords[0], contacts[0], (opp.Amount / 2))
        };

        builtPSCs = service.buildPartialSoftCreditRecordsFromOCRs(opp, ocrRecords, pscRecords);

        System.assertEquals(ocrRecords.size(), builtPSCs.size(),
            'The number of built PSC records should match the number of OCR records');
        System.assertEquals(opp.Amount / 2 , builtPSCs[0].Amount__c,
            'The resulting PartialSoftCredit record Amount should match the PSC (half the Opp Amt)');
    }

    // **************************** HELPER METHODS ****************************

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

    /**
     * @description Instantiate mock Allocation records for each GAU
     */
    private static List<Allocation__c> buildMockAllocations(Opportunity opp, List<General_Accounting_Unit__c> gaus, Decimal amt) {
        List<Allocation__c> allocations = new List<Allocation__c>();
        for (General_Accounting_Unit__c gau : gaus) {
            allocations.add(new Allocation__c(
                Id = UTIL_UnitTestData_TEST.mockId(Allocation__c.SObjectType),
                Opportunity__c = opp.Id,
                Opportunity__r = opp,
                General_Accounting_Unit__c = gau.Id,
                Amount__c = amt
            ));
        }
        return allocations;
    }
}