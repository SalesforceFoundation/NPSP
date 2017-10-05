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
 * @date 12/22/2015
 * @group Opportunity
 * @description test class for the Manage Soft Credits VF page 
 */
 
@isTest 
public with sharing class PSC_ManageSoftCredits_TEST {
    
    /*******************************************************************************************************
    * @description test data for all tests
    */ 
    public static Account acc;
    public static integer cContact = 10;
    public static integer cPSCExisting = 2;
    public static list<Contact> listCon;
    public static Opportunity opp;

    /*******************************************************************************************************
    * @description Initialize test data and create Partial Soft Credits
    * @return void
    */ 
    public static void initTestDataWithPscs() {
        initTestData(true);
    }

    /*******************************************************************************************************
    * @description Initialize test data without creating Partial Soft Credits
    * @return void
    */ 
    public static void initTestDataWithoutPscs() {
        initTestData(false);
    }
        
    /*******************************************************************************************************
    * @description initialize test data for all tests
    * @param createPSCs Create Partial Soft Credit flag
    * @return void
    */ 
    public static void initTestData(boolean createPSCs) {
        
        // create a matching gift company
        insert acc = new Account(name='some company');
        
        // create some Contacts in Household Accounts
        insert listCon = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(cContact);
        listCon = [select Id, Firstname,Lastname, AccountId from Contact];
        system.assertEquals(cContact, listCon.size());
        
        // create an Opportunity
        insert opp = new Opportunity(
            Name='test opp', 
            Amount=1000, 
            AccountId=acc.Id, 
            CloseDate=System.Today(),
            StageName=UTIL_UnitTestData_TEST.getClosedWonStage()
            ); 
        
        if (createPSCs) {
	        list<Partial_Soft_Credit__c> listPSC = new list<Partial_Soft_Credit__c>();
	        for (integer i = 0; i < cPSCExisting; i++) {
	            listPSC.add(new Partial_Soft_Credit__c(
	                Contact__c = listCon[i].Id,
	                Opportunity__c = opp.Id,
	                Role_Name__c = 'Soft Credit',
	                Amount__c = 100                
	                ));
	        }
	        insert listPSC;            
        }        
    }
    
    /*******************************************************************************************************
    * @description create some new Soft Credits on an Opp with no OCRs or PSCs.
    * verify OCRs and PSCs created
    */ 
    static testmethod void createNewPSCs() {
        initTestDataWithoutPscs();
        Test.setCurrentPage(Page.PSC_ManageSoftCredits);
        PSC_ManageSoftCredits_CTRL ctrl = new PSC_ManageSoftCredits_CTRL(new ApexPages.StandardController(opp));
        system.assertEquals(0, ctrl.softCredits.size());
        system.assertEquals(0, ctrl.numberOfSoftCredits);
        system.assertEquals(acc.Id, ctrl.PrimaryContactId);
        system.assertEquals(acc.Name, ctrl.PrimaryContactName);
        
        ctrl.addAnotherSoftCredit();
        ctrl.addAnotherSoftCredit();
        ctrl.addAnotherSoftCredit();
        system.assertEquals(3, ctrl.softCredits.size());
        system.assertEquals(3, ctrl.numberOfSoftCredits);
        ctrl.softCredits[0].contactRole.ContactId = listCon[0].Id;
        ctrl.softCredits[0].contactRole.Role = 'Soft Credit';
        ctrl.softCredits[0].partial.Amount__c = 100;

        ctrl.softCredits[1].contactRole.ContactId = listCon[1].Id;
        ctrl.softCredits[1].contactRole.Role = 'Soft Credit';
        ctrl.softCredits[1].partial.Amount__c = 200;

        ctrl.softCredits[2].contactRole.ContactId = listCon[2].Id;
        ctrl.softCredits[2].contactRole.Role = 'Soft Credit';
        ctrl.softCredits[2].partial.Amount__c = 300;
        
        system.assertEquals(600, ctrl.oppTotalSoftCredit.Amount);
        Test.startTest();
        system.assertNotEquals(null, ctrl.save());
        Test.stopTest();
        
        list<Partial_Soft_Credit__c> listPSC = [select Id, Contact__c, Opportunity__c, Amount__c, Role_Name__c from Partial_Soft_Credit__c];
        system.assertEquals(3, listPSC.size());
        
        double amount = 0;
        for (Partial_Soft_Credit__c psc : listPSC)
            amount += psc.Amount__c;
        system.assertEquals(600, amount);
        
        list<OpportunityContactRole> listOCR = [select Id, ContactId, OpportunityId, Role from OpportunityContactRole];
        system.assertEquals(3, listOCR.size());        
    }

    /*******************************************************************************************************
    * @description create some new Soft Credits on an Opp with no OCRs or PSCs, using percents.
    * verify OCRs and PSCs created
    */ 
    static testmethod void createNewPSCsByPercent() {
        initTestDataWithoutPscs();
        Test.setCurrentPage(Page.PSC_ManageSoftCredits);
        PSC_ManageSoftCredits_CTRL ctrl = new PSC_ManageSoftCredits_CTRL(new ApexPages.StandardController(opp));
        system.assertEquals(0, ctrl.softCredits.size());
        ctrl.addAnotherSoftCredit();
        ctrl.addAnotherSoftCredit();
        ctrl.addAnotherSoftCredit();
        system.assertEquals(3, ctrl.softCredits.size());
        
        
        // switch to percents
        ctrl.isAmount = true;

        ctrl.softCredits[0].contactRole.ContactId = listCon[0].Id;
        ctrl.softCredits[0].contactRole.Role = 'Soft Credit';
        ctrl.softCredits[0].partial.Amount__c = 10;
        ctrl.softCredits[0].fullCredit = false;

        ctrl.softCredits[1].contactRole.ContactId = listCon[1].Id;
        ctrl.softCredits[1].contactRole.Role = 'Soft Credit';
        ctrl.softCredits[1].partial.Amount__c = 20;
        ctrl.softCredits[1].fullCredit = false;

        ctrl.softCredits[2].contactRole.ContactId = listCon[2].Id;
        ctrl.softCredits[2].contactRole.Role = 'Soft Credit';
        ctrl.softCredits[2].partial.Amount__c = 30;
        ctrl.softCredits[2].fullCredit = false;
        
        // update amounts
        ctrl.checkFullAndPartialCredit();
        
        system.assertEquals(600, ctrl.oppTotalSoftCredit.Amount);
        Test.startTest();
        system.assertNotEquals(null, ctrl.save());
        Test.stopTest();
        
        list<Partial_Soft_Credit__c> listPSC = [select Id, Contact__c, Opportunity__c, Amount__c, Role_Name__c from Partial_Soft_Credit__c];
        system.assertEquals(3, listPSC.size());
        
        double amount = 0;
        for (Partial_Soft_Credit__c psc : listPSC)
            amount += psc.Amount__c;
        system.assertEquals(600, amount);
        
        list<OpportunityContactRole> listOCR = [select Id, ContactId, OpportunityId, Role from OpportunityContactRole];
        system.assertEquals(3, listOCR.size());        

        // switch back from percents
        ctrl.isAmount = false;
        ctrl.checkFullAndPartialCredit();
        system.assertEquals(600, ctrl.oppTotalSoftCredit.Amount);
        system.assertNotEquals(null, ctrl.save());
        
    }

    /*******************************************************************************************************
    * @description create some new Soft Credits on an Opp with existing PSCs.
    * verify OCRs and PSCs created
    */ 
    static testmethod void createNewPSCsToExistingPSCs() {
        initTestDataWithPscs();
        Test.setCurrentPage(Page.PSC_ManageSoftCredits);
        PSC_ManageSoftCredits_CTRL ctrl = new PSC_ManageSoftCredits_CTRL(new ApexPages.StandardController(opp));
        system.assertEquals(cPSCExisting, ctrl.softCredits.size());
        ctrl.addAnotherSoftCredit();
        ctrl.addAnotherSoftCredit();
        ctrl.addAnotherSoftCredit();
        system.assertEquals(cPSCExisting + 3, ctrl.softCredits.size());
        ctrl.softCredits[cPSCExisting].contactRole.ContactId = listCon[cPSCExisting].Id;
        ctrl.softCredits[cPSCExisting].contactRole.Role = 'Soft Credit';
        ctrl.softCredits[cPSCExisting].partial.Amount__c = 100;

        ctrl.softCredits[cPSCExisting + 1].contactRole.ContactId = listCon[cPSCExisting + 1].Id;
        ctrl.softCredits[cPSCExisting + 1].contactRole.Role = 'Soft Credit';
        ctrl.softCredits[cPSCExisting + 1].partial.Amount__c = 200;

        ctrl.softCredits[cPSCExisting + 2].contactRole.ContactId = listCon[cPSCExisting + 2].Id;
        ctrl.softCredits[cPSCExisting + 2].contactRole.Role = 'Soft Credit';
        ctrl.softCredits[cPSCExisting + 2].partial.Amount__c = 300;
        
        system.assertEquals(cPSCExisting * 100 + 600, ctrl.oppTotalSoftCredit.Amount);
        Test.startTest();
        system.assertNotEquals(null, ctrl.save());
        Test.stopTest();
        
        list<Partial_Soft_Credit__c> listPSC = [select Id, Contact__c, Opportunity__c, Amount__c, Role_Name__c from Partial_Soft_Credit__c];
        system.assertEquals(cPSCExisting + 3, listPSC.size());
        
        double amount = 0;
        for (Partial_Soft_Credit__c psc : listPSC)
            amount += psc.Amount__c;
        system.assertEquals(cPSCExisting * 100 + 600, amount);
        
        list<OpportunityContactRole> listOCR = [select Id, ContactId, OpportunityId, Role from OpportunityContactRole];
        system.assertEquals(cPSCExisting + 3, listOCR.size());        
    }

    /*******************************************************************************************************
    * @description handle loading PSC's with invalid OCR id's
    */ 
    static testmethod void loadInvalidPSCs() {
        initTestDataWithPscs();

        // set the PSC's OCR lookups to invalid values
        list<Partial_Soft_Credit__c> listPSC = [select Id, Contact__c, Opportunity__c, Amount__c, Role_Name__c, 
            Contact_Role_ID__c from Partial_Soft_Credit__c];
        system.assertEquals(cPSCExisting, listPSC.size());
        listPSC[0].Contact_Role_ID__c = opp.Id; // a bogus OCR id, but a valid Id for type checking!
        listPSC[1].Contact_Role_ID__c = null;
        update listPSC;

        Test.setCurrentPage(Page.PSC_ManageSoftCredits);
        PSC_ManageSoftCredits_CTRL ctrl = new PSC_ManageSoftCredits_CTRL(new ApexPages.StandardController(opp));
        system.assertEquals(cPSCExisting + 2, ctrl.softCredits.size());
    }
    
    /*******************************************************************************************************
    * @description handle loading Soft Credit OCR's with no PSC's
    */ 
    static testmethod void loadSoftCreditOCRs() {
        initTestData(false);
        
        // create Soft Credit OCR
        OpportunityContactRole ocr = new OpportunityContactRole(
            ContactId = listCon[0].Id, 
            OpportunityId = opp.Id,
            Role = 'Soft Credit',
            IsPrimary = false);
        insert ocr; 

        Test.setCurrentPage(Page.PSC_ManageSoftCredits);
        PSC_ManageSoftCredits_CTRL ctrl = new PSC_ManageSoftCredits_CTRL(new ApexPages.StandardController(opp));
        system.assertEquals(1, ctrl.softCredits.size());
    }
    
    /*******************************************************************************************************
    * @description change some Soft Credits to full credits on an Opp with existing PSCs.
    * verify PSC's deleted, OCR's remain
    */ 
    static testmethod void makeExistingPSCsFullCredits() {
        initTestDataWithPscs();
        Test.setCurrentPage(Page.PSC_ManageSoftCredits);
        PSC_ManageSoftCredits_CTRL ctrl = new PSC_ManageSoftCredits_CTRL(new ApexPages.StandardController(opp));
        system.assertEquals(cPSCExisting, ctrl.softCredits.size());        
        system.assertEquals(cPSCExisting * 100 , ctrl.oppTotalSoftCredit.Amount);
        for (integer i = 0; i < cPSCExisting; i++)
            ctrl.softCredits[i].fullCredit = true;
        ctrl.checkFullCredit();
        ctrl.checkFullAndPartialCredit();
        ctrl.allowTooManySoftCredits = true;
        
        Test.startTest();
        system.assertNotEquals(null, ctrl.save());
        Test.stopTest();
        
        list<Partial_Soft_Credit__c> listPSC = [select Id, Contact__c, Opportunity__c, Amount__c, Role_Name__c from Partial_Soft_Credit__c];
        system.assertEquals(0, listPSC.size());
        
        list<OpportunityContactRole> listOCR = [select Id, ContactId, OpportunityId, Role from OpportunityContactRole];
        system.assertEquals(cPSCExisting, listOCR.size());        
    }
    
    /*******************************************************************************************************
    * @description make some Soft Credits be full credits on an Opp with existing PSCs.
    * verify PSC's not there, OCR's created
    */ 
    static testmethod void makeNewPSCsFullCredits() {
        initTestDataWithoutPscs();
        Test.setCurrentPage(Page.PSC_ManageSoftCredits);
        PSC_ManageSoftCredits_CTRL ctrl = new PSC_ManageSoftCredits_CTRL(new ApexPages.StandardController(opp));
        system.assertEquals(0, ctrl.softCredits.size());        
        system.assertEquals(0 * 100 , ctrl.oppTotalSoftCredit.Amount);
        system.assertEquals(true, ctrl.isAmount);  // amount mode, not percent mode.

        // create new soft credits that are full.
        ctrl.addAnotherSoftCredit();
        ctrl.addAnotherSoftCredit();
        system.assertEquals(2, ctrl.softCredits.size());
        system.assertEquals(2, ctrl.numberOfSoftCredits);
        ctrl.softCredits[0].contactRole.ContactId = listCon[0].Id;
        ctrl.softCredits[0].contactRole.Role = 'Soft Credit';
        ctrl.softCredits[0].partial.Amount__c = opp.Amount;  // full amount should not create a PSC

        ctrl.softCredits[1].contactRole.ContactId = listCon[1].Id;
        ctrl.softCredits[1].contactRole.Role = 'Soft Credit';
        ctrl.softCredits[1].fullCredit = true;

        ctrl.checkFullCredit();
        ctrl.allowTooManySoftCredits = true;
                
        Test.startTest();
        system.assertNotEquals(null, ctrl.save());
        Test.stopTest();
        
        list<Partial_Soft_Credit__c> listPSC = [select Id, Contact__c, Opportunity__c, Amount__c, Role_Name__c from Partial_Soft_Credit__c];
        system.assertEquals(0, listPSC.size());
        
        list<OpportunityContactRole> listOCR = [select Id, ContactId, OpportunityId, Role from OpportunityContactRole];
        system.assertEquals(2, listOCR.size());        
    }
    
    /*******************************************************************************************************
    * @description delete some existing PSCs by clearing their contactId.
    * verify PSC's deleted, OCR's deleted
    */ 
    static testmethod void deleteExistingPSCsByClearContactId() {
        initTestDataWithPscs();
        Test.setCurrentPage(Page.PSC_ManageSoftCredits);
        PSC_ManageSoftCredits_CTRL ctrl = new PSC_ManageSoftCredits_CTRL(new ApexPages.StandardController(opp));
        system.assertEquals(cPSCExisting, ctrl.softCredits.size());        
        system.assertEquals(cPSCExisting * 100 , ctrl.oppTotalSoftCredit.Amount);
        for (integer i = 0; i < cPSCExisting; i++)
            ctrl.softCredits[i].contactRole.ContactId = null;
        
        Test.startTest();
        system.assertNotEquals(null, ctrl.save());
        Test.stopTest();
        
        list<Partial_Soft_Credit__c> listPSC = [select Id, Contact__c, Opportunity__c, Amount__c, Role_Name__c from Partial_Soft_Credit__c];
        system.assertEquals(0, listPSC.size());
        
        list<OpportunityContactRole> listOCR = [select Id, ContactId, OpportunityId, Role from OpportunityContactRole];
        system.assertEquals(0, listOCR.size());        
    }

    /*******************************************************************************************************
    * @description delete some existing PSCs by calling the delete action.
    * verify one PSC was deleted, one OCR was deleted
    */
    static testmethod void deleteExistingPSCs() {
        initTestDataWithPscs();
        Test.setCurrentPage(Page.PSC_ManageSoftCredits);
        PSC_ManageSoftCredits_CTRL ctrl = new PSC_ManageSoftCredits_CTRL(new ApexPages.StandardController(opp));
        system.assertEquals(cPSCExisting, ctrl.softCredits.size());
        system.assertEquals(cPSCExisting * 100 , ctrl.oppTotalSoftCredit.Amount);
        ctrl.rowNumber = 1;
        ctrl.delRow();

        Test.startTest();
        system.assertNotEquals(null, ctrl.save());
        Test.stopTest();

        list<Partial_Soft_Credit__c> listPSC = [select Id, Contact__c, Opportunity__c, Amount__c, Role_Name__c from Partial_Soft_Credit__c];
        system.assertEquals(cPSCExisting - 1, listPSC.size());

        list<OpportunityContactRole> listOCR = [select Id, ContactId, OpportunityId, Role from OpportunityContactRole];
        system.assertEquals(cPSCExisting - 1, listOCR.size());
    }
    
    /*******************************************************************************************************
    * @description change some existing Soft Credits.
    * verify PSC's and OCR's
    */ 
    static testmethod void updateExistingPSCs() {
        initTestDataWithPscs();
        Test.setCurrentPage(Page.PSC_ManageSoftCredits);
        PSC_ManageSoftCredits_CTRL ctrl = new PSC_ManageSoftCredits_CTRL(new ApexPages.StandardController(opp));
        system.assertEquals(cPSCExisting, ctrl.softCredits.size());        
        system.assertEquals(cPSCExisting * 100 , ctrl.oppTotalSoftCredit.Amount);
        system.assert(cPSCExisting >= 2);
        // change to a different contact
        ctrl.softCredits[0].contactRole.ContactId = listCon[cPSCExisting].Id;
        // change Amount
        ctrl.softCredits[1].partial.Amount__c = 500;

        Test.startTest();
        system.assertNotEquals(null, ctrl.save());
        Test.stopTest();
        
        list<Partial_Soft_Credit__c> listPSC = [select Id, Contact__c, Opportunity__c, Amount__c, Role_Name__c from Partial_Soft_Credit__c];
        system.assertEquals(cPSCExisting, listPSC.size());
        
        double amount = 0;
        for (Partial_Soft_Credit__c psc : listPSC)
            amount += psc.Amount__c;
        system.assertEquals(600, amount);

        list<OpportunityContactRole> listOCR = [select Id, ContactId, OpportunityId, Role from OpportunityContactRole];
        system.assertEquals(cPSCExisting, listOCR.size());        
    }

    /*********************************************************************************************************
    @description 
        Test save rollback when an exception occurs 
    verify:
        The transaction is completely rolled back and there is no partial commit
    **********************************************************************************************************/ 
    private static testMethod void testSaveRollsBackAllDmlsOnError() {
        initTestDataWithPscs();
        Test.setCurrentPage(Page.PSC_ManageSoftCredits);
        PSC_ManageSoftCredits_CTRL ctrl = new PSC_ManageSoftCredits_CTRL(new ApexPages.StandardController(opp));

        System.assertEquals(cPSCExisting, ctrl.softCredits.size(), 'The Soft Credits should be loaded by the controller');      

        // delete a Soft Credit
        ctrl.rowNumber = 0;
        ctrl.delRow();

        ctrl.addAnotherSoftCredit();
        ctrl.softCredits[cPSCExisting - 1].contactRole.ContactId = listCon[cPSCExisting - 1].Id;
        ctrl.softCredits[cPSCExisting - 1].contactRole.Role = 'Soft Credit';
        ctrl.softCredits[cPSCExisting - 1].partial.Amount__c = 100;

        ctrl.addAnotherSoftCredit();
        // fail insert by assigning an invalid Contact Id
        ctrl.softCredits[cPSCExisting].contactRole.ContactId = Contact.sObjectType.getDescribe().getKeyPrefix() + '000000000001AAA';
        ctrl.softCredits[cPSCExisting].contactRole.Role = 'Soft Credit';
        ctrl.softCredits[cPSCExisting].partial.Amount__c = 200;

        system.assertEquals(cPSCExisting + 1, ctrl.softCredits.size(), 'The Soft Credit size should be increased due to adding new records');

        Test.startTest();
        PageReference retPage = ctrl.save();
        Test.stopTest();

        System.assertEquals(null, retPage, 'The return page on the error should be null. Page messages: ' + ApexPages.getMessages());
        UTIL_UnitTestData_TEST.assertPageHasError('INVALID_CROSS_REFERENCE_KEY');

        List<Partial_Soft_Credit__c> pscs = new List<Partial_Soft_Credit__c>([SELECT Contact__c, Opportunity__c, Amount__c, Role_Name__c FROM Partial_Soft_Credit__c]);
        System.assertEquals(cPSCExisting, pscs.size(), 'The Soft Credits should not change');
    }

    /*********************************************************************************************************
    @description 
        Test re-saving of Soft Credits after an error is fixed 
    verify:
        Records are saved as expected
    **********************************************************************************************************/ 
    private static testMethod void testResaveSucceedsWhenErrorIsFixed() {
        initTestDataWithPscs();
        Test.setCurrentPage(Page.PSC_ManageSoftCredits);
        PSC_ManageSoftCredits_CTRL ctrl = new PSC_ManageSoftCredits_CTRL(new ApexPages.StandardController(opp));

        System.assertEquals(cPSCExisting, ctrl.softCredits.size(), 'The Soft Credits should be loaded by the controller');  
        
        ctrl.addAnotherSoftCredit();
        ctrl.softCredits[cPSCExisting].contactRole.ContactId = listCon[cPSCExisting].Id;
        ctrl.softCredits[cPSCExisting].contactRole.Role = 'Soft Credit';
        ctrl.softCredits[cPSCExisting].partial.Amount__c = 100;

        ctrl.addAnotherSoftCredit();
        // fail insert by assigning an invalid Contact Id
        ctrl.softCredits[cPSCExisting + 1].contactRole.ContactId = Contact.sObjectType.getDescribe().getKeyPrefix() + '000000000001AAA';
        ctrl.softCredits[cPSCExisting + 1].contactRole.Role = 'Soft Credit';
        ctrl.softCredits[cPSCExisting + 1].partial.Amount__c = 200;

        system.assertEquals(cPSCExisting + 2, ctrl.softCredits.size(), 'The Soft Credit size should be increased due to adding new records');    

        PageReference retPage = ctrl.save();
        System.assertEquals(null, retPage, 'The return page on the error should be null. Page messages: ' + ApexPages.getMessages());

        // fix an issue
        ctrl.softCredits[cPSCExisting + 1].contactRole.ContactId = listCon[cPSCExisting + 1].Id;

        Test.startTest();
        retPage = ctrl.save();
        Test.stopTest();

        System.assertNotEquals(null, retPage, 'The return page on success should be provided. Page messages: ' + ApexPages.getMessages());

        List<Partial_Soft_Credit__c> pscs = new List<Partial_Soft_Credit__c>([SELECT Contact__c, Opportunity__c, Amount__c, Role_Name__c FROM Partial_Soft_Credit__c]);
        System.assertEquals(cPSCExisting + 2, pscs.size(), 'The new Soft Credits should be created');
    }

    /*******************************************************************************************************
    * @description test error scenarios
    * verify errors detected and reported
    */ 
    static testmethod void testErrors() {
        initTestDataWithoutPscs();
        
        // create a primary donor OCR on the opp
        OpportunityContactRole ocrPrimary = new OpportunityContactRole(
            ContactId = listCon[0].Id,
            OpportunityId = opp.Id,
            Role = 'Donor',
            IsPrimary = true
            );
        insert ocrPrimary;
        
        Test.setCurrentPage(Page.PSC_ManageSoftCredits);
        PSC_ManageSoftCredits_CTRL ctrl = new PSC_ManageSoftCredits_CTRL(new ApexPages.StandardController(opp));
        system.assertEquals(0, ctrl.softCredits.size());
        
        // test not allowing partial on the Primary OCR
        ctrl.addAnotherSoftCredit();
        system.assertEquals(1, ctrl.softCredits.size());
        ctrl.softCredits[0].contactRole.ContactId = listCon[0].Id;
        ctrl.softCredits[0].contactRole.Role = 'Soft Credit';
        ctrl.softCredits[0].partial.Amount__c = 100;
        system.assertEquals(null, ctrl.save());
        
        // test amount not filled in
        ctrl.softCredits[0].contactRole.ContactId = listCon[1].Id;
        ctrl.softCredits[0].contactRole.Role = 'Soft Credit';
        ctrl.softCredits[0].partial.Amount__c = null;
        system.assertEquals(null, ctrl.save());
      
        // test Role not filled in
        ctrl.softCredits[0].contactRole.ContactId = listCon[1].Id;
        ctrl.softCredits[0].contactRole.Role = null;
        ctrl.softCredits[0].partial.Amount__c = 100;
        system.assertEquals(null, ctrl.save());

        // test amount > opp.amount
        ctrl.softCredits[0].contactRole.ContactId = listCon[1].Id;
        ctrl.softCredits[0].contactRole.Role = 'Soft Credit';
        ctrl.softCredits[0].partial.Amount__c = opp.Amount + 100;
        ctrl.allowTooManySoftCredits = false;
        system.assertEquals(null, ctrl.save());
          
        // hit a few remaining code paths
        ctrl.refresh();
        system.assertNotEquals(null, ctrl.cancel());
    }
 
    /*******************************************************************************************************
    * @description test handling of no Soft Credit Roles in NPSP Settings
    * verify errors detected and reported
    */ 
    static testmethod void testNoSoftCreditRoles() {
        initTestDataWithoutPscs();
        
        // create a primary donor OCR on the opp
        OpportunityContactRole ocrPrimary = new OpportunityContactRole(
            ContactId = listCon[0].Id,
            OpportunityId = opp.Id,
            Role = 'Donor',
            IsPrimary = true
            );
        insert ocrPrimary;

        UTIL_CustomSettingsFacade.getHouseholdsSettings().npo02__Soft_Credit_Roles__c = null;    
        
        Test.setCurrentPage(Page.PSC_ManageSoftCredits);
        PSC_ManageSoftCredits_CTRL ctrl = new PSC_ManageSoftCredits_CTRL(new ApexPages.StandardController(opp));
        system.assertEquals(0, ctrl.softCredits.size());
        
        system.assertNotEquals(0, ApexPages.getMessages().size());
    }
}