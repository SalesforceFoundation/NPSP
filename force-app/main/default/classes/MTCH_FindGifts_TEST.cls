/*
    Copyright (c) 2015 Salesforce.org
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
 * @date 12/8/2015
 * @group Opportunity
 * @description test class for the FindGifts VF page allowing users to find matched gifts for a particular Opportunity using custom filters.
 */

@isTest
public with sharing class MTCH_FindGifts_TEST {

    private static final String RECEIVED_STATUS = 'Received';

    /*******************************************************************************************************
    * @description test data for all tests
    */
    public static Account accMG;
    public static Integer cItem = 10;
    public static List<Contact> listCon;
    public static List<Opportunity> listOpp;
    public static Opportunity oppMG;

    /*******************************************************************************************************
    * @description Initialize test data, create Matching Gift as Closed Won and set gift percent to 100
    * @return void
    */
    public static void initTestData() {
        initTestData(true, 100);
    }

    /*******************************************************************************************************
    * @description initialize test data for all tests
    * @param isMGClosedWon whether the Matching Gift should be created as Closed Won or Open
    * @param matchingGiftPercent Matching Gift percent
    * @return void
    */
    public static void initTestData(Boolean isMGClosedWon, Double matchingGiftPercent) {
        Date today = System.today();

        // create a matching gift company
        insert accMG = new Account(Name='matching gift company', Matching_Gift_Percent__c = matchingGiftPercent);

        // create some Contacts in Household Accounts
        insert listCon = UTIL_UnitTestData_TEST.createMultipleTestContacts(cItem);
        listCon = [SELECT Id, FirstName, LastName, AccountId FROM Contact];
        System.assertEquals(cItem, listCon.size());

        // create an Opportunity for each Contact
        listOpp = UTIL_UnitTestData_TEST.oppsForContactWithAccountList(
            listCon, null, UTIL_UnitTestData_TEST.getClosedWonStage(), today, 100, null, null
        );

        // only make half of them matching gift potentials
        for (Integer i = 0; i < cItem/2; i++) {
            Opportunity opp = listOpp[i];
            opp.Matching_Gift_Account__c = accMG.Id;
            opp.Matching_Gift_Status__c = 'Potential';
        }
        insert listOpp;

        // create the Matching Gift Opp
        String stage = isMGClosedWon
            ? UTIL_UnitTestData_TEST.getClosedWonStage()
            : UTIL_UnitTestData_TEST.getOpenStage();

        insert oppMG = new Opportunity(Name='Matching Gift Opp', AccountId=accMG.Id, Amount=1000, StageName=stage, CloseDate=today);
    }

    /*******************************************************************************************************
    * @description create several matched gifts to the Matching Gift opp
    */
    static void createMatchesWithTestData() {
        List<OpportunityContactRole> listOCR = new List<OpportunityContactRole>();
        List<Partial_Soft_Credit__c> listPSC = new List<Partial_Soft_Credit__c>();

        listOpp[0].Matching_Gift__c = oppMG.Id;
        listOpp[0].Matching_Gift_Status__c = RECEIVED_STATUS;
        listOpp[2].Matching_Gift__c = oppMG.Id;
        listOpp[2].Matching_Gift_Status__c = RECEIVED_STATUS;
        update listOpp;

        String role = UTIL_CustomSettingsFacade.getHouseholdsSettings().Matched_Donor_Role__c;
        // The PSC trigger handler creates OCRs if needed, no need to create them here.

        listPSC.add(new Partial_Soft_Credit__c(Opportunity__c=oppMG.Id, Contact__c=listCon[0].Id, Role_Name__c=role, Amount__c=100));
        listPSC.add(new Partial_Soft_Credit__c(Opportunity__c=oppMG.Id, Contact__c=listCon[2].Id, Role_Name__c=role, Amount__c=100));
        insert listPSC;
    }

    /*******************************************************************************************************
    * @description match some existing Opps to the Matching Gift
    * verify OCR and PSC created
    */
    static testmethod void testCreateMatches() {
        initTestData();
        Test.setCurrentPage(Page.MTCH_FindGifts);
        MTCH_FindGifts_CTRL ctrl = new MTCH_FindGifts_CTRL(new ApexPages.StandardController(oppMG));

        System.assertEquals(cItem/2, ctrl.potentialGifts.size());
        System.assertEquals(cItem/2, ctrl.selection.size());
        System.assertEquals(false, ctrl.selection.get(listOpp[0].Id));
        System.assertEquals(false, ctrl.selection.get(listOpp[2].Id));
        System.assertEquals(0, ctrl.oppTotalSelected.Amount);

        ctrl.selection.put(listOpp[0].Id, true);
        ctrl.selection.put(listOpp[2].Id, true);

        System.assertEquals(200, ctrl.oppTotalSelected.Amount);
        System.assertEquals(0, [SELECT count() FROM Partial_Soft_Credit__c]);

        Test.startTest();
        System.assertNotEquals(null, ctrl.saveAndClose());
        Test.stopTest();

        assertMatchingGiftsCount(2);
    }

    /*******************************************************************************************************
    * @description match some existing Opps to the Matching Gift with a Matching Gift Percent < 100
    * verify OCR and PSC created
    */
    static testmethod void testCreateMatchesPercent() {
        initTestData(true, 50);
        Test.setCurrentPage(Page.MTCH_FindGifts);
        MTCH_FindGifts_CTRL ctrl = new MTCH_FindGifts_CTRL(new ApexPages.StandardController(oppMG));

        System.assertEquals(cItem/2, ctrl.potentialGifts.size());
        System.assertEquals(cItem/2, ctrl.selection.size());
        System.assertEquals(false, ctrl.selection.get(listOpp[0].Id));
        System.assertEquals(false, ctrl.selection.get(listOpp[2].Id));
        System.assertEquals(0, ctrl.oppTotalSelected.Amount);

        ctrl.selection.put(listOpp[0].Id, true);
        ctrl.selection.put(listOpp[2].Id, true);

        System.assertEquals(100, ctrl.oppTotalSelected.Amount);
        System.assertEquals(0, [SELECT count() FROM Partial_Soft_Credit__c]);

        Test.startTest();
        System.assertNotEquals(null, ctrl.saveAndClose());
        Test.stopTest();

        assertMatchingGiftsCount(2);
    }

    /*******************************************************************************************************
    * @description unmatch some existing Opps to the Matching Gift
    * verify OCR and PSC deleted
    */
    static testmethod void testUnmatchMatches() {
        initTestData();
        createMatchesWithTestData();
        Test.setCurrentPage(Page.MTCH_FindGifts);
        MTCH_FindGifts_CTRL ctrl = new MTCH_FindGifts_CTRL(new ApexPages.StandardController(oppMG));

        System.assertEquals(cItem/2, ctrl.potentialGifts.size());
        System.assertEquals(cItem/2, ctrl.selection.size());
        System.assertEquals(true, ctrl.selection.get(listOpp[0].Id));
        System.assertEquals(true, ctrl.selection.get(listOpp[2].Id));
        System.assertEquals(200, ctrl.oppTotalSelected.Amount);

        ctrl.selection.put(listOpp[0].Id, false);
        ctrl.selection.put(listOpp[2].Id, false);

        System.assertEquals(0, ctrl.oppTotalSelected.Amount);
        System.assertEquals(2, [SELECT count() FROM Partial_Soft_Credit__c]);

        Test.startTest();
        System.assertNotEquals(null, ctrl.saveAndClose());
        Test.stopTest();

        assertMatchingGiftsCount(0);
    }

    /*******************************************************************************************************
    * @description match some Searched for existing Opps to the Matching Gift
    * verify OCR and PSC created
    */
    static testmethod void testCreateSearchedMatches() {
        initTestData();
        Test.setCurrentPage(Page.MTCH_FindGifts);
        MTCH_FindGifts_CTRL ctrl = new MTCH_FindGifts_CTRL(new ApexPages.StandardController(oppMG));

        System.assertEquals(cItem/2, ctrl.potentialGifts.size());
        System.assertEquals(cItem/2, ctrl.selection.size());

        // search for more opps
        ctrl.showSearchSection();
        ctrl.searchFieldsWrapper.First_Soft_Credit_Amount__c = 100;
        ctrl.searchFieldsWrapper.First_Soft_Credit_Date__c = Date.today().addYears(-1);
        ctrl.searchFieldsWrapper.Last_Soft_Credit_Date__c = Date.today().addYears(1);
        ctrl.searchMore();
        System.assertEquals(cItem, ctrl.potentialGifts.size());
        System.assertEquals(cItem, ctrl.selection.size());

        // SELECT from the searched opps
        System.assertEquals(false, ctrl.selection.get(listOpp[5].Id));
        System.assertEquals(false, ctrl.selection.get(listOpp[6].Id));
        System.assertEquals(0, ctrl.oppTotalSelected.Amount);

        ctrl.selection.put(listOpp[5].Id, true);
        ctrl.selection.put(listOpp[6].Id, true);

        System.assertEquals(200, ctrl.oppTotalSelected.Amount);
        System.assertEquals(0, [SELECT count() FROM Partial_Soft_Credit__c]);

        Test.startTest();
        System.assertNotEquals(null, ctrl.saveAndClose());
        Test.stopTest();

        assertMatchingGiftsCount(2);

        // does nothing, but hey, let's get that code coverage up!
        System.assertEquals(null, ctrl.refresh());
    }

    /*********************************************************************************************************
    @description
        Test save rollback when an exception occurs
    verify:
        The transaction is completely rolled back and there is no partial commit
    **********************************************************************************************************/
    private static testMethod void testSaveAndCloseRollsBackAllDmlsOnError() {
        initTestData();
        createMatchesWithTestData();
        Test.setCurrentPage(Page.MTCH_FindGifts);
        MTCH_FindGifts_CTRL ctrl = new MTCH_FindGifts_CTRL(new ApexPages.StandardController(oppMG));

        // deSELECT one match
        ctrl.selection.put(listOpp[0].Id, false);

        // SELECT new matches, listOpp[2] is already selected
        ctrl.selection.put(listOpp[1].Id, true);
        ctrl.selection.put(listOpp[3].Id, true);

        // fail Opportunity Contact Role insert for a newly selected match
        Map<Id, Opportunity> potentialGiftsById = new Map<Id, Opportunity>(ctrl.potentialGifts);
        Opportunity matchedOpp = potentialGiftsById.get(listOpp[1].Id);
        System.assert(!matchedOpp.OpportunityContactRoles.isEmpty(), 'Matched Opportunity should have a Primary Contact');
        matchedOpp.OpportunityContactRoles[0].ContactId = Contact.sObjectType.getDescribe().getKeyPrefix() + '000000000001AAA';

        Test.startTest();
        PageReference retPage = ctrl.saveAndClose();
        Test.stopTest();

        System.assertEquals(null, retPage, 'The return page should be null on error.');

        assertMatchingGiftsCount(2);
    }

    // Helpers
    ////////////

    /**
     * @description Asserts Matching Gifts' related data
     * @param expectedCount An expected count of records for each data query
     * @return void
     */
    private static void assertMatchingGiftsCount(Integer expectedCount) {
        System.assertEquals(expectedCount, [SELECT count() FROM Partial_Soft_Credit__c]);
        System.assertEquals(expectedCount, [SELECT count() FROM OpportunityContactRole where OpportunityId = :oppMG.Id]);
        System.assertEquals(expectedCount, [SELECT count() FROM Opportunity where Matching_Gift_Status__c = :RECEIVED_STATUS]);
        System.assertEquals(expectedCount, [SELECT count() FROM Opportunity where Matching_Gift__c = :oppMG.Id]);
    }
}