/*
    Copyright (c) 2009, Salesforce.org
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
* @date 2015
* @description Tests Contact Merge when done through the API
* @group ContactMerge
*/

@isTest(IsParallel=true)

public with sharing class CON_ContactMergeTDTM_TEST2 {
    /*******************************************************************************************************************
    * @description Counter for creating unique contacts
    */
    private static Integer uniqueCounter {
        get {
            if (uniqueCounter == null) {
                uniqueCounter = 0;
            }
            uniqueCounter++;
            return uniqueCounter;
        }
        set;
    }

    /*******************************************************************************************************
    * @description merge three Contacts from different Household Accounts with many Relationships.  
    * verify: 
    *   No Duplicate Relationships
    */
    @isTest
    private static void mergeContactsDifferentHHAccountManyRel() {
        // this creates 3 Household Accounts, each with 2 Contacts, and a default Address for each HH
        ADDR_Addresses_TEST.createHHTestData(3, 2);

        Contact conWinner = ADDR_Addresses_TEST.listConT[1];
        Contact conLoser1 = ADDR_Addresses_TEST.listConT[3];
        Contact conLoser2 = ADDR_Addresses_TEST.listConT[4];

        // create relationships between the contacts in each household
        List<npe4__Relationship__c> listRel = new List<npe4__Relationship__c>();
        for (integer i = 0; i < 3; i++) {
            npe4__Relationship__c rel = new npe4__Relationship__c(
                npe4__Contact__c = ADDR_Addresses_TEST.listConT[i * 2].id, 
                npe4__RelatedContact__c = ADDR_Addresses_TEST.listConT[i * 2 + 1].id, 
                npe4__Type__c='Friend',
                npe4__Status__c='Active',
                npe4__Description__c='notes');
            listRel.add(rel);
        }

        // create relationships between the winners & losers, and one of the other contacts
        // these will be the duplicate relationships that should be merged.
        Contact conRel = ADDR_Addresses_TEST.listConT[0];
        listRel.add(new npe4__Relationship__c(npe4__Contact__c=conWinner.Id, npe4__RelatedContact__c=conRel.Id));
        listRel.add(new npe4__Relationship__c(npe4__Contact__c=conLoser1.Id, npe4__RelatedContact__c=conRel.Id));
        listRel.add(new npe4__Relationship__c(npe4__Contact__c=conLoser2.Id, npe4__RelatedContact__c=conRel.Id));
        insert listRel;

        // verify rels all there
        System.assertEquals(12, [SELECT count() FROM npe4__Relationship__c]);

        // now let's do the merge!
        Test.startTest();
        merge conWinner new List<Contact>{conLoser1, conLoser2};

        // to flush our future calls that fix related data up!
        Test.stopTest();

        // reload our contacts
        List<Contact> listCon = CON_ContactMergeTDTM_TEST.getContacts();
        System.assertEquals(conWinner.Id, listCon[1].Id);
        conWinner = listCon[1];

        // verify the merge
        System.assertEquals(4, listCon.size());
        CON_ContactMergeTDTM_TEST.verifyAccountsContactCount(conWinner.AccountId, conLoser1.AccountId, 2, 1);
        CON_ContactMergeTDTM_TEST.verifyLosingAccountsContactCount(conLoser2.AccountId, 1);

        // verify the expected relationships
        System.assertEquals(8, [SELECT count() FROM npe4__Relationship__c]);
        System.assertEquals(4, [SELECT count() FROM npe4__Relationship__c WHERE npe4__Contact__c = :conWinner.Id]);
        System.assertEquals(4, [SELECT count() FROM npe4__Relationship__c WHERE npe4__RelatedContact__c = :conWinner.Id]);
    }

    /*******************************************************************************************************
    * @description Merge two Contacts in different Accounts and verifies Opps, OCRs, Rollups, and Names
    * are updated as appropriate for the account types.
    */ 
    @isTest
    private static void testNamesAndOppsMergeHHToHH() {
        testNamesAndOppsMerge(CAO_Constants.HH_ACCOUNT_TYPE, CAO_Constants.HH_ACCOUNT_TYPE);
    }

    /*******************************************************************************************************
    * @description Merge two Contacts in different Accounts and verifies Opps, OCRs, Rollups, and Names
    * are updated as appropriate for the account types.
    */ 
    @isTest
    private static void testNamesAndOppsMergeOne2OneToOne2One() {
        testNamesAndOppsMerge(CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE, CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE);
    }

    /*******************************************************************************************************
    * @description Merge two Contacts in different Accounts and verifies Opps, OCRs, Rollups, and Names
    * are updated as appropriate for the account types.
    */ 
    @isTest
    private static void testNamesAndOppsMergeOrgToHH() {
        testNamesAndOppsMerge(null, CAO_Constants.HH_ACCOUNT_TYPE);
    }

    /*******************************************************************************************************
    * @description Merge two Contacts in different Accounts and verifies Opps, OCRs, Rollups, and Names
    * are updated as appropriate for the account types.
    */ 
    @isTest
    private static void testNamesAndOppsMergeHHToOrg() {
        testNamesAndOppsMerge(CAO_Constants.HH_ACCOUNT_TYPE, null);
    }

    /*******************************************************************************************************
    * @description Merge two Contacts in different Accounts and verifies Opps, OCRs, Rollups, and Names
    * are updated as appropriate for the account types.
    */ 
    @isTest
    private static void testNamesAndOppsMergeOrgToOne2One() {
        testNamesAndOppsMerge(null, CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE);
    }

    /*******************************************************************************************************
    * @description Merge two Contacts in different Accounts and verifies Opps, OCRs, Rollups, and Names
    * are updated as appropriate for the account types.
    */ 
    @isTest
    private static void testNamesAndOppsMergeOne2OneToOrg() {
        testNamesAndOppsMerge(CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE, null);
    }
    
    /*******************************************************************************************************
    * @description Merge two Contacts in different Accounts and verifies Opps, OCRs, Rollups, and Names
    * are updated as appropriate for the account types.
    */ 
    @isTest
    private static void testNamesAndOppsMergeOrgToOrg() {
        testNamesAndOppsMerge(null, null);
    }

    /*******************************************************************************************************
    * @description Merge two Contacts in different Accounts and verifies Opps, OCRs, Rollups, and Names
    *   the account's names and greetings are updated.
    *   Opps owned by the contact are moved over.
    *   Soft Credits for the moved Opps are recalculated.
    *   Soft Credits the contact previously had are still there.
    *   Opp Rollups are recalculated for both accounts.
    */
    private static void testNamesAndOppsMerge(string accTypeLoser, string accTypeWinner) {
        // create our losing account and contacts
        UTIL_UnitTestData_TEST.createAccountContactTestData(accTypeLoser, 1, 2, 1);
        Account accLoser = UTIL_UnitTestData_TEST.listAccT[0];
        List<Contact> listConAll = UTIL_UnitTestData_TEST.listConT; 

        // create our winning account and contacts
        UTIL_UnitTestData_TEST.createAccountContactTestData(accTypeWinner, 1, 2, 3);
        Account accWinner = UTIL_UnitTestData_TEST.listAccT[0];
        listConAll.addAll(UTIL_UnitTestData_TEST.listConT);

        // create an opp for each contact
        // note that for Org accounts, these Opps won't generate Soft Credits.
        List<Opportunity> listOpp = UTIL_UnitTestData_TEST.OppsForContactWithAccountList(listConAll, null, 
            UTIL_UnitTestData_TEST.getclosedWonStage(), System.Today(), 100, null, null);
        insert listOpp;

        // Merge the first contact in the first account to the first contact in the other account.
        Contact conWinner = listConAll[2];
        Contact conLoser = listConAll[0];
        Test.startTest();
        merge conWinner conLoser;
        Test.stopTest();

        // reload our contacts and accounts
        List<Account> listAcc = CON_ContactMergeTDTM_TEST.getHouseholdAccounts();
        List<Contact> listCon = CON_ContactMergeTDTM_TEST.getContacts();

        // verify the contacts belong to correct account.
        System.assertEquals(accLoser.Id, listAcc[0].Id, 'Expected the first account in the list to be the losing contact\'s account.');
        accLoser = listAcc[0];
        System.assertEquals(accWinner.Id, listAcc[1].Id, 'Expected the second account in the list to be the winning contact\'s account.');
        accWinner = listAcc[1];
        System.assertEquals(3, listCon.size(), 'Expected three contacts to remain after the merge.');
        System.assertEquals(conWinner.Id, listCon[1].Id, 'Expected the first contact in the list to be the winning contact\'s record.');
        conWinner = listCon[1];
        System.assertEquals(listCon[0].AccountId, accLoser.Id, 'Expected the first contact in the list to be the losing contact\'s record.');
        System.assertEquals(conWinner.AccountId, accWinner.Id, 'Expected the winning contact\'s account Id to match the winning account Id.');
        System.assertEquals(listCon[2].AccountId, accWinner.Id, 'Expected the third contact in the list to belong to the winning contact\'s account.');

        // verify the account's names and greetings are updated
        if (accTypeLoser == CAO_Constants.HH_ACCOUNT_TYPE){
            System.assertEquals(false, accLoser.npo02__Formal_Greeting__c.contains(conLoser.Firstname), 'When the losing contact\'s account is a household, expected the name to no longer contain the losing contact\'s name.');
        }
        if (accTypeWinner == CAO_Constants.HH_ACCOUNT_TYPE) {
            System.assertEquals(false, accWinner.npo02__Formal_Greeting__c.contains(conLoser.Firstname), 'When the winning contacts\'s account is a household, expected the household to not contain the losing contact\'s name.');
            System.assertEquals(true, accWinner.npo02__Formal_Greeting__c.contains(conWinner.Firstname), 'When the winning contacts\'s account is a household, expected the household to contain the winning contact\'s name.');
        }
        System.assertEquals(false, accWinner.Name.contains('Anonymous'), 'The winning account name should not contain Anonymous.');

        Integer cAccLoserOpps = [SELECT count() FROM Opportunity WHERE AccountId = :accLoser.Id];
        Integer cAccWinnerOpps = [SELECT count() FROM Opportunity WHERE AccountId = :accWinner.Id];
        Integer cOCRCon0 = [SELECT count() FROM OpportunityContactRole WHERE ContactId = :listCon[0].Id];
        Integer cOCRConWinner = [SELECT count() FROM OpportunityContactRole WHERE ContactId = :conWinner.Id];
        Integer cOCRCon2 = [SELECT count() FROM OpportunityContactRole WHERE ContactId = :listCon[2].Id];

        Boolean isHH2HH = accTypeLoser == CAO_Constants.HH_ACCOUNT_TYPE && accTypeWinner == CAO_Constants.HH_ACCOUNT_TYPE;
        Boolean isIndividual2Individual = accTypeLoser == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE && accTypeWinner == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE;
        Boolean isNone2HH = accTypeLoser == null && accTypeWinner == CAO_Constants.HH_ACCOUNT_TYPE;
        Boolean isHH2None = accTypeLoser == CAO_Constants.HH_ACCOUNT_TYPE && accTypeWinner == null;
        Boolean isNone2Individual = accTypeLoser == null && accTypeWinner == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE;
        Boolean isIndividual2None = accTypeLoser == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE && accTypeWinner == null;
        Boolean isNone2None = accTypeLoser == null && accTypeWinner == null;

        Integer expAccLoserOpps = isHH2HH || isIndividual2Individual ? 1 : 2;
        Integer expAccWinnerOpps = isHH2HH || isIndividual2Individual ? 3 : 2;
        Integer expOcrAccLoserCon = 1;
        Integer expOcrConWinner = isHH2HH || isNone2HH ? 3 : 2;
        Integer expOcrAccWinnerCon = isHH2HH ? 3 : (isNone2HH ? 2 : 1);

        System.assertEquals(expAccLoserOpps, cAccLoserOpps, 'The number of opps on the losing account is not as expected.');
        System.assertEquals(expAccWinnerOpps, cAccWinnerOpps, 'The number of opps on the winning account is not as expected.');
        System.assertEquals(expOcrAccLoserCon, cOCRCon0, 'The number of ocrs for the losing account\'s remaining contact is not as expected.');
        System.assertEquals(expOcrConWinner, cOCRConWinner, 'The number of ocrs for the winning is not as expected.');
        System.assertEquals(expOcrAccWinnerCon, cOCRCon2, 'The number of ocrs on the winng account\'s other contact is not as expected.');
        System.assertEquals(expAccLoserOpps, accLoser.npo02__NumberOfClosedOpps__c, 'The number of rolled up opps on the losing account is not as expected.');
        System.assertEquals(expAccWinnerOpps, accWinner.npo02__NumberOfClosedOpps__c, 'The number of rolled up opps on the winning account is not as expected.');

    }

    /*******************************************************************************************************
    * @description Verifies rollup is calculted on merge
    */
    @isTest
    private static void contactMergeShouldRecalculateRollup() {
        List<Contact> contactsToMerge = buildContactsWithOppsForAccount();

        Test.startTest();
        merge contactsToMerge[0] contactsToMerge[1];
        Test.stopTest();

        List<Contact> contacts = [SELECT npo02__NumberOfClosedOpps__c FROM Contact];
        System.assertEquals(1, contacts.size(), 'There should only be one contact after merge');
        System.assertEquals(2, contacts[0].npo02__NumberOfClosedOpps__c, 'The rollup should have been calculated');
    }

    /*******************************************************************************************************
    * @description Verifies legacy rollup is used when Customizable Rollups is not activated
    */
    @isTest
    private static void contactMergeShouldUseLegacyRollupWhenCRLPNotEnabled() {
        RLLP_OppRollupMock mock = setRollupMock();

        List<Contact> contactsToMerge = buildContactsWithOppsForAccount();

        Test.startTest();
        merge contactsToMerge[0] contactsToMerge[1];
        Test.stopTest();

        System.assert(mock.rollupContactsCalled, 'Legacy rollup should have been called');
    }

    /*******************************************************************************************************
    * @description Verifies legacy rollup is NOT used when Customizable Rollups is activated
    */
    @isTest
    private static void contactMergeShouldNotUseLegacyRollupWhenCRLPEnabled() {
        UTIL_CustomSettingsFacade.getCustomizableRollupSettings().Customizable_Rollups_Enabled__c = true;
        RLLP_OppRollupMock mock = setRollupMock();

        List<Contact> contactsToMerge = buildContactsWithOppsForAccount();

        TDTM_ObjectDataGateway.ClearCachedTriggerHandlersForTest();

        Test.startTest();
        merge contactsToMerge[0] contactsToMerge[1];
        Test.stopTest();

        //CRLP rollup method is static, so we cannot mock it so just confirming that legacy is not called and rollup is still calculated
        System.assert(!mock.rollupContactsCalled, 'Legacy rollup should not have been called');

        List<Contact> contacts = [SELECT npo02__NumberOfClosedOpps__c FROM Contact];
        System.assertEquals(2, contacts[0].npo02__NumberOfClosedOpps__c, 'The rollup should have been calculated');
    }

    /*******************************************************************************************************************
    * @description Builds and inserts contacts with one opportunity each for a single account
    */
    private static List<Contact> buildContactsWithOppsForAccount() {
        UTIL_UnitTestData_TEST.createAccountContactTestData(CAO_Constants.HH_ACCOUNT_TYPE, 1, 2, uniqueCounter);
        List<Contact> contacts = UTIL_UnitTestData_TEST.listConT;

        List<Opportunity> listOpp = UTIL_UnitTestData_TEST.OppsForContactWithAccountList(
            contacts,
            null,
            UTIL_UnitTestData_TEST.getclosedWonStage(),
            System.Today(),
            100,
            null,
            null
        );

        insert listOpp;

        return contacts;
    }

    /*******************************************************************************************************************
    * @description Builds mock instance and stubs RLLP_OppRollupMock in CON_ContactMerge_TDTM
    */
    private static RLLP_OppRollupMock setRollupMock() {
        RLLP_OppRollupMock rollupMock = new RLLP_OppRollupMock();
        CON_ContactMerge_TDTM.opprollup =
            (RLLP_OppRollup)Test.createStub(RLLP_OppRollup.class, rollupMock);
        return rollupMock;
    }

    /*******************************************************************************************************************
    * @description Stub for RLLP_OppRollupMock instance
    */
    private class RLLP_OppRollupMock implements System.StubProvider {
        private Boolean rollupContactsCalled = false;
        public Object handleMethodCall(
            Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs
        ) {
            switch on stubbedMethodName {
                when 'rollupContacts' {
                    rollupContactsCalled = true;
                }
            }
            return null;
        }
    }
}