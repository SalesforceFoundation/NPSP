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
    public static integer cItem = 10;
    public static list<Contact> listCon;
    public static list<Opportunity> listOpp;
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
    public static void initTestData(boolean isMGClosedWon, double matchingGiftPercent) {
        Date today = System.today();
        
        // create a matching gift company
        insert accMG = new Account(name='matching gift company', Matching_Gift_Percent__c = matchingGiftPercent);
        
        // create some Contacts in Household Accounts
        insert listCon = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(cItem);
        listCon = [select Id, Firstname,Lastname, AccountId from Contact];
        system.assertEquals(cItem, listCon.size());
        
        // create an Opportunity for each Contact
        listOpp = UTIL_UnitTestData_TEST.OppsForContactWithAccountList(
            listCon, null, UTIL_UnitTestData_TEST.getClosedWonStage(), today, 100, null, null
        ); 

        // only make half of them matching gift potentials
        for (integer i = 0; i < cItem/2; i++) {
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
        list<OpportunityContactRole> listOCR = new list<OpportunityContactRole>();
        list<Partial_Soft_Credit__c> listPSC = new list<Partial_Soft_Credit__c>();
        
        listOpp[0].Matching_Gift__c = oppMG.Id;
        listOpp[0].Matching_Gift_Status__c = RECEIVED_STATUS;
        listOpp[2].Matching_Gift__c = oppMG.Id;
        listOpp[2].Matching_Gift_Status__c = RECEIVED_STATUS;
        update listOpp;
        
        string role = UTIL_CustomSettingsFacade.getHouseholdsSettings().Matched_Donor_Role__c;
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

        system.assertEquals(cItem/2, ctrl.potentialGifts.size());
        system.assertEquals(cItem/2, ctrl.selection.size());
        system.assertEquals(false, ctrl.selection.get(listOpp[0].Id));
        system.assertEquals(false, ctrl.selection.get(listOpp[2].Id));
        system.assertEquals(0, ctrl.oppTotalSelected.Amount);

        ctrl.selection.put(listOpp[0].Id, true);    
        ctrl.selection.put(listOpp[2].Id, true);

        system.assertEquals(200, ctrl.oppTotalSelected.Amount);
        system.assertEquals(0, [select count() from Partial_Soft_Credit__c]);

        Test.startTest();
        system.assertNotEquals(null, ctrl.saveAndClose());
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

        system.assertEquals(cItem/2, ctrl.potentialGifts.size());
        system.assertEquals(cItem/2, ctrl.selection.size());
        system.assertEquals(false, ctrl.selection.get(listOpp[0].Id));
        system.assertEquals(false, ctrl.selection.get(listOpp[2].Id));
        system.assertEquals(0, ctrl.oppTotalSelected.Amount);

        ctrl.selection.put(listOpp[0].Id, true);    
        ctrl.selection.put(listOpp[2].Id, true);

        system.assertEquals(100, ctrl.oppTotalSelected.Amount);
        system.assertEquals(0, [select count() from Partial_Soft_Credit__c]);

        Test.startTest();
        system.assertNotEquals(null, ctrl.saveAndClose());
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

        system.assertEquals(cItem/2, ctrl.potentialGifts.size());
        system.assertEquals(cItem/2, ctrl.selection.size());
        system.assertEquals(true, ctrl.selection.get(listOpp[0].Id));
        system.assertEquals(true, ctrl.selection.get(listOpp[2].Id));
        system.assertEquals(200, ctrl.oppTotalSelected.Amount);

        ctrl.selection.put(listOpp[0].Id, false);    
        ctrl.selection.put(listOpp[2].Id, false);

        system.assertEquals(0, ctrl.oppTotalSelected.Amount);
        system.assertEquals(2, [select count() from Partial_Soft_Credit__c]);

        Test.startTest();
        system.assertNotEquals(null, ctrl.saveAndClose());
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

        system.assertEquals(cItem/2, ctrl.potentialGifts.size());
        system.assertEquals(cItem/2, ctrl.selection.size());

        // search for more opps
        ctrl.showSearchSection();
        ctrl.searchFieldsWrapper.First_Soft_Credit_Amount__c = 100;
        ctrl.searchMore();
        system.assertEquals(cItem, ctrl.potentialGifts.size());
        system.assertEquals(cItem, ctrl.selection.size());

        // select from the searched opps
        system.assertEquals(false, ctrl.selection.get(listOpp[5].Id));
        system.assertEquals(false, ctrl.selection.get(listOpp[6].Id));
        system.assertEquals(0, ctrl.oppTotalSelected.Amount);
        
        ctrl.selection.put(listOpp[5].Id, true);    
        ctrl.selection.put(listOpp[6].Id, true);

        system.assertEquals(200, ctrl.oppTotalSelected.Amount);
        system.assertEquals(0, [select count() from Partial_Soft_Credit__c]);

        Test.startTest();
        system.assertNotEquals(null, ctrl.saveAndClose());
        Test.stopTest();

        assertMatchingGiftsCount(2);
        
        // does nothing, but hey, let's get that code coverage up!
        system.assertEquals(null, ctrl.refresh());
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

        // deselect one match
        ctrl.selection.put(listOpp[0].Id, false); 

        // select new matches, listOpp[2] is already selected       
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
        system.assertEquals(expectedCount, [SELECT count() FROM Partial_Soft_Credit__c]);
        system.assertEquals(expectedCount, [SELECT count() FROM OpportunityContactRole where OpportunityId = :oppMG.Id]);
        system.assertEquals(expectedCount, [SELECT count() FROM Opportunity where Matching_Gift_Status__c = :RECEIVED_STATUS]);
        system.assertEquals(expectedCount, [SELECT count() FROM Opportunity where Matching_Gift__c = :oppMG.Id]);
    }
}