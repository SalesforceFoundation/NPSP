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
* @group Allocations
* @group-content ../../ApexDocContent/Allocations.htm
* @description Tests for the Manage Allocations page. 
*/
@isTest
private class ALLO_ManageAllocations_TEST {

    /*******************************************************************************************************
    * @description Setup of allocations settings.
    * @param alloset An instance of Allocations_Settings__c custom setting. Calling this method with a null
    * parameter uses default settings.
    * @return void Modifies settings, returns nothing.
    ********************************************************************************************************/
    private static void setupSettings (Allocations_Settings__c alloset) {
        //set running user to avoid dml issue            
        System.runAs(new User(id = UserInfo.getUserId())){
            if (alloset!=null)
                UTIL_CustomSettingsFacade.getAllocationsSettingsForTests(alloset);
            else 
                UTIL_CustomSettingsFacade.getAllocationsSettingsForTests(new Allocations_Settings__c());

        }
    }

    /*******************************************************************************************************
    * @description Runs manage allocations page on an opportunity with no allocations. Adds then deletes a
    * row, then inserts an allocation and verifies the allocation was created properly.
    ********************************************************************************************************/
    @isTest
    static void testOpp() {
        setupSettings(null);
        
        Account acc = new Account(Name='foo');
        insert acc;
        Opportunity opp = new Opportunity(Name='foo', Amount = 8, AccountID=acc.id, CloseDate=system.today(), StageName=UTIL_UnitTestData_TEST.getClosedWonStage());
        insert opp;
        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(Name='foo');
        insert gau;

        ALLO_ManageAllocations_CTRL ctrl = setUpController(opp.Id);

        system.assertEquals(1,ctrl.allocations.size(),'The list of allocations should have a single empty allocation.');
        system.assertEquals(null,ctrl.allocations[0].id,'The allocation should have no Id.');
        system.assertEquals(opp.Id,ctrl.allocations[0].Opportunity__c,'The allocation should be attributed to current opportunity.');

        ctrl.rowNumber = 0;
        ctrl.addRow();
        system.assertEquals(2,ctrl.allocations.size(),'Adding a row increases the size of the allocation list.');

        ctrl.allocations[0].Percent__c = 50;
        ctrl.allocations[0].General_Accounting_Unit__c = gau.id;
        ctrl.rowNumber = 1;
        ctrl.delRow();
        Test.startTest();
        ctrl.saveClose();
        Test.stopTest();

        list<Allocation__c> queryAllo = [SELECT Id, Percent__c, Amount__c FROM Allocation__c WHERE Opportunity__c=:opp.id];
        system.assertEquals(1,queryAllo.size(),'The single allocation should be saved.');
        system.assertEquals(4,queryAllo[0].Amount__c,'The amount should be calculated based on the percent.');
    }

    /*******************************************************************************************************
    * @description Runs manage allocations page on a payment with no allocations. Adds then deletes a
    * row, then inserts an allocation and verifies the allocation was created properly.
    ********************************************************************************************************/
    @isTest
    static void testPayment() {
        Decimal amt = 100;
        Account acc = new Account(Name='foo');
        insert acc;
        Opportunity opp = new Opportunity(Name='foo', Amount = amt, AccountID=acc.id, CloseDate=system.today(), StageName=UTIL_UnitTestData_TEST.getClosedWonStage());
        insert opp;
        npe01__OppPayment__c payment = new npe01__OppPayment__c(
            npe01__Opportunity__c = opp.Id,
            npe01__Payment_Amount__c = amt
        );
        insert payment;
        General_Accounting_Unit__c defaultGau = new General_Accounting_Unit__c(Name='def');
        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(Name='foo');
        insert new List<General_Accounting_Unit__c>{defaultGau, gau};
        setupSettings(new Allocations_Settings__c(
            Payment_Allocations_Enabled__c = true,
            Default_Allocations_Enabled__c = true,
            Default__c = defaultGau.Id)
        );

        ALLO_ManageAllocations_CTRL ctrl = setUpController(payment.Id);

        system.assertEquals(1,ctrl.allocations.size(),'The list of allocations should have a single empty allocation.');
        system.assertEquals(null,ctrl.allocations[0].id,'The allocation should have no Id.');
        system.assertEquals(payment.Id,ctrl.allocations[0].Payment__c,'The allocation should be attributed to current payment.');

        ctrl.rowNumber = 0;
        ctrl.addRow();
        system.assertEquals(2,ctrl.allocations.size(),'Adding a row increases the size of the allocation list.');

        ctrl.allocations[0].Percent__c = 25;
        ctrl.allocations[0].General_Accounting_Unit__c = gau.Id;
        ctrl.rowNumber = 1;
        ctrl.delRow();
        Test.startTest();
        ctrl.saveClose();
        Test.stopTest();

        list<Allocation__c> queryAllo = [SELECT Id, Percent__c, Amount__c 
            FROM Allocation__c 
            WHERE Payment__c=:payment.id
            ORDER BY Amount__c ASC
        ];
        Decimal firstAmt = amt/4;
        Decimal remainderAmt = amt - firstAmt;
        system.assertEquals(2,queryAllo.size(),'The allocation, and the default to make up the remainder, should be saved.');
        system.assertEquals(firstAmt,queryAllo[0].Amount__c,'The amount should be calculated based on the percent.');
        system.assertEquals(remainderAmt,queryAllo[1].Amount__c,'The default allocation should make up the remainder');
    }

    /*******************************************************************************************************
    * @description Runs manage allocations page on a campaign with two allocations. Adds a new allocation,
    * deletes an existing one, and verifies the results.
    ********************************************************************************************************/
    @isTest
    static void testCam() {
        setupSettings(null);
        
        General_Accounting_Unit__c campaigngau = new General_Accounting_Unit__c(Name='foo');
        insert campaigngau;
        Campaign cam = new Campaign(Name='Foo', IsActive=true);
        insert cam;

        list<Allocation__c> alloForInsert = new list<Allocation__c>();
        Allocation__c percentAllo = new Allocation__c(Campaign__c=cam.id, Percent__c = 50, General_Accounting_Unit__c = campaigngau.id);
        alloForInsert.add(percentAllo);
        Allocation__c amountAllo = new Allocation__c(Campaign__c=cam.id, Amount__c = 4, General_Accounting_Unit__c = campaigngau.id);
        alloForInsert.add(amountAllo);
        insert alloForInsert;

        ALLO_ManageAllocations_CTRL ctrl = setUpController(cam.Id);

        system.assertEquals(2,ctrl.allocations.size(),'The list of allocations should have two current campaign allocations.');

        ctrl.addRow();
        system.assertEquals(3,ctrl.allocations.size(),'Adding a row increases the size of the allocation list.');

        //delete the first allocation on the list
        ctrl.rowNumber = 0;
        ctrl.delRow();

        ctrl.allocations[1].Amount__c = 5;
        ctrl.allocations[1].General_Accounting_Unit__c = campaigngau.id;
        Test.startTest();
        ctrl.saveClose();
        Test.stopTest();

        list<Allocation__c> queryAllo = [SELECT Id, Percent__c, Amount__c FROM Allocation__c WHERE Campaign__c=:cam.id];
        system.assertEquals(2,queryAllo.size(),'2 allocations should be saved, one original allocation should be deleted.');
    }

    /*******************************************************************************************************
    * @description Runs manage allocations page on a recurring with two allocations. Adds a new allocation,
    * deletes an existing one, and verifies the results.
    ********************************************************************************************************/
    @isTest
    static void testRD() {
        setupSettings(null);
        
        Account acc = new Account(Name='foo');
        insert acc;
        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(Name = 'foo');
        insert gau;
        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withInstallmentPeriodYearly()
            .withDateEstablished(Date.newInstance(1984,01,29))
            .withAccount(acc.Id)
            .withAmount(20)
            .withScheduleTypeMultiplyValue()
            .withOpenEndedStatusOpen()
            .build();
        insert rd;
        
        list<Allocation__c> alloForInsert = new list<Allocation__c>();
        Allocation__c percentAllo = new Allocation__c(Recurring_Donation__c = rd.id, Percent__c = 50, General_Accounting_Unit__c = gau.id);
        alloForInsert.add(percentAllo);
        Allocation__c amountAllo = new Allocation__c(Recurring_Donation__c = rd.id, Amount__c = 10, General_Accounting_Unit__c = gau.id);
        alloForInsert.add(amountAllo);
        insert alloForInsert;

        Integer oppCnt = [SELECT Count() FROM Opportunity WHERE npe03__Recurring_Donation__c = :rd.Id];
        system.assertNotEquals(0, oppCnt, 'There should be at least one installment Opportunity');
        system.assertEquals(oppCnt * 2, [SELECT Count() FROM Allocation__c WHERE Opportunity__r.npe03__Recurring_Donation__c = :rd.Id],
            'There should be two Allocations per Installment Opportunity');

        ALLO_ManageAllocations_CTRL ctrl = setUpController(rd.Id);

        system.assertEquals(2,ctrl.allocations.size(),'The list of allocations should have two current campaign allocations.');

        ctrl.addRow();
        system.assertEquals(3,ctrl.allocations.size(),'Adding a row increases the size of the allocation list.');

        //delete the first allocation on the list
        ctrl.rowNumber = 0;
        ctrl.delRow();

        ctrl.allocations[1].Amount__c = 5;
        ctrl.allocations[1].General_Accounting_Unit__c = gau.id;
        Test.startTest();
        ctrl.saveClose();
        Test.stopTest();

        list<Allocation__c> queryAllo = [SELECT Id, Percent__c, Amount__c FROM Allocation__c WHERE Recurring_Donation__c=:rd.id];
        system.assertEquals(2,queryAllo.size(),'2 allocations should be saved on the recurring donation; one original allocation should be deleted.');

        system.assertEquals(oppCnt * 2, [SELECT Count() FROM Allocation__c WHERE Opportunity__r.npe03__Recurring_Donation__c = :rd.Id],
                'There should still be two Allocations per Installment Opportunity');
    }

    /*********************************************************************************************************
    @description 
        Test save rollback when an exception occurs 
    verify:
        The transaction is completely rolled back and there is no partial commit
    **********************************************************************************************************/ 
    @isTest
    private static void testSaveRollsBackAllDmlsOnError() {
        setupSettings(null);

        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(Name = 'gau');
        Campaign campaign = new Campaign(Name = 'TestCampaign', IsActive = true);        
        insert new sObject[] { gau, campaign };

        Allocation__c[] allocations = new Allocation__c[]{
            new Allocation__c(Campaign__c = campaign.Id, Amount__c = 100, General_Accounting_Unit__c = gau.Id),
            new Allocation__c(Campaign__c = campaign.Id, Amount__c = 200, General_Accounting_Unit__c = gau.Id),
            new Allocation__c(Campaign__c = campaign.Id, Amount__c = 300, General_Accounting_Unit__c = gau.Id)
        };
        insert allocations;

        ALLO_ManageAllocations_CTRL ctrl = setUpController(campaign.Id);

        System.assertEquals(allocations.size(), ctrl.allocations.size(), 'Allocations in the controller should match existing records: ' + ctrl.allocations);

        //delete two Allocations
        ctrl.rowNumber = 0;
        ctrl.delRow();
        ctrl.delRow();
        System.assertEquals(1, ctrl.allocations.size(), 'Two Allocations should be deleted: ' + ctrl.allocations);

        //update an Allocation
        ctrl.allocations[0].Amount__c = 1000;

        //add a new Allocation
        ctrl.rowNumber = 1;
        ctrl.addRow();        
        ctrl.allocations[1].Percent__c = 200; //cause the Allocation insert to fail
        ctrl.allocations[1].General_Accounting_Unit__c = gau.id;

        Test.startTest();
        PageReference retPage = ctrl.saveClose();
        Test.stopTest();

        System.assertEquals(null, retPage, 'The return page on the error should be null');

        Map<Id, Allocation__c> actualAllocationsById = new Map<Id, Allocation__c>([SELECT Percent__c, Amount__c FROM Allocation__c WHERE Campaign__c = :campaign.id]);
        System.assertEquals(allocations.size(), actualAllocationsById.size(), 'The Allocations should be unchanged: ' + actualAllocationsById.values());

        for (Allocation__c alloc : allocations) {
            Allocation__c actual = actualAllocationsById.get(alloc.Id);

            System.assertEquals(alloc.Amount__c, actual.Amount__c, 'Allocation Amount should be unchanged: ' + actual);
        }
    }

    /*********************************************************************************************************
    @description 
        Test re-saving of Allocations after an error is fixed 
    verify:
        Records are saved as expected
    **********************************************************************************************************/ 
    @isTest
    private static void testResaveSucceedsWhenErrorIsFixed() {
        setupSettings(null);

        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(Name = 'gau');
        Campaign campaign = new Campaign(Name = 'TestCampaign', IsActive = true);        
        insert new sObject[] { gau, campaign };

        Allocation__c[] allocations = new Allocation__c[]{
            new Allocation__c(Campaign__c = campaign.Id, Amount__c = 100, General_Accounting_Unit__c = gau.Id)
        };
        insert allocations;

        ALLO_ManageAllocations_CTRL ctrl = setUpController(campaign.Id);

        System.assertEquals(allocations.size(), ctrl.allocations.size(), 'Allocations in the controller should match existing records: ' + ctrl.allocations);

        ctrl.allocations[0].Amount__c = 1000;

        ctrl.rowNumber = 0;
        ctrl.addRow();   
        ctrl.allocations[1].Amount__c = 2000; 
        ctrl.allocations[1].General_Accounting_Unit__c = gau.id;

        ctrl.rowNumber = 1;
        ctrl.addRow();        
        ctrl.allocations[2].Percent__c = 200; //cause the Allocation insert to fail
        ctrl.allocations[2].General_Accounting_Unit__c = gau.id;

        PageReference retPage = ctrl.saveClose();        
        System.assertEquals(null, retPage, 'The return page on the error should be null');

        Map<Id, Allocation__c> actualAllocationsById = new Map<Id, Allocation__c>([SELECT Percent__c, Amount__c FROM Allocation__c WHERE Campaign__c = :campaign.id]);
        System.assertEquals(allocations.size(), actualAllocationsById.size(),
        'The Allocations should be unchanged: ' + actualAllocationsById.values());
        System.assertEquals(false, ctrl.isLoading,
            'isLoading should be set back to false when there is an error');

        //fix the error
        ctrl.allocations[2].Percent__c = 20; 

        Test.startTest();
        retPage = ctrl.saveClose();
        Test.stopTest();

        System.assertEquals(true, ctrl.redirect,
        'The page redirect should be set to true. Page messages: ' + ApexPages.getMessages());

        actualAllocationsById = new Map<Id, Allocation__c>([SELECT Percent__c, Amount__c FROM Allocation__c WHERE Campaign__c = :campaign.id]);
        System.assertEquals(3, actualAllocationsById.size(), 'New Allocations should be created: ' + actualAllocationsById.values());
    }

    /*******************************************************************************************************
    * @description Runs manage allocations page on a general allocation and verifies an
    * error is thrown when the page action to getPageLoadValidationmessages is called.
    ********************************************************************************************************/
    @isTest
    private static void testUnsupportedObject() {
        setupSettings(null);

        Account acc = new Account(Name='foo');
        insert acc;
        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(Name = 'foo');
        insert gau;

        ALLO_ManageAllocations_CTRL ctrl = setUpController(gau.Id);
        ctrl.verifyPageLoadConditions();

        List<Apexpages.Message> msgs = ApexPages.getMessages();
        Boolean errorFound = false;
        for (Apexpages.Message msg : msgs){
            if (msg.getDetail().contains(System.Label.alloObjectUnsupported)) errorFound = true;
        }
        System.assert(errorFound);
    }

    /*******************************************************************************************************
    * @description Runs manage allocations page on an opportunity and verifies an
    * error is not thrown when the page action to getPageLoadValidationmessages is called.
    ********************************************************************************************************/
    @isTest
    private static void testSupportedObject() {
        setupSettings(null);

        Account acc = new Account(Name='foo');
        insert acc;
        Opportunity opp = new Opportunity(Name='foo', Amount = 8, AccountID=acc.id, CloseDate=system.today(), StageName=UTIL_UnitTestData_TEST.getClosedWonStage());
        insert opp;
        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(Name = 'foo');
        insert gau;

        ALLO_ManageAllocations_CTRL ctrl = setUpController(opp.Id);
        ctrl.verifyPageLoadConditions();

        List<Apexpages.Message> msgs = ApexPages.getMessages();
        Boolean errorFound = false;
        for (Apexpages.Message msg : msgs){
            if (msg.getDetail().contains(System.Label.alloObjectUnsupported)) errorFound = true;
        }
        System.assert(!errorFound);
    }

    /*******************************************************************************************************
    * @description Runs manage allocations page on an opportunity with no amount and verifies an
    * error is thrown when the page action to validatePageLoadConditions is called.
    ********************************************************************************************************/
    @isTest
    private static void testOppNoAmount() {
        setupSettings(null);

        Account acc = new Account(Name='foo');
        insert acc;
        Opportunity opp = new Opportunity(Name='foo', AccountID=acc.id, CloseDate=system.today(), StageName=UTIL_UnitTestData_TEST.getClosedWonStage());
        insert opp;
        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(Name = 'foo');
        insert gau;

        ALLO_ManageAllocations_CTRL ctrl = setUpController(opp.Id);
        ctrl.verifyPageLoadConditions();

        List<Apexpages.Message> msgs = ApexPages.getMessages();
        Boolean errorFound = false;
        for (Apexpages.Message msg : msgs){
            if (msg.getDetail().contains(System.Label.alloCantAllocateNothing)) errorFound = true;
        }
        System.assert(errorFound);
    }

    /**
     * @description getCurrencySymbol() should return the appropriate currency
     * symbol as returned by UTIL_Currency
     */
    @isTest
    private static void testGetCurrencySymbolCallsUtilCurrency() {

        Test.startTest();

        UTIL_Currency_TEST.UtilCurrencyMock mock = new UTIL_Currency_TEST.UtilCurrencyMock();
        mock.getCurrencySymbolReturn = 'FOO';
        UTIL_Currency.instance = mock;

        ALLO_ManageAllocations_CTRL controller = new ALLO_ManageAllocations_CTRL();
        controller.parentCurrencyCode = 'FOO';
        controller.parentId = UTIL_UnitTestData_TEST.MOCK_ACCOUNT_ID;

        System.assertEquals(
            'FOO',
            controller.getCurrencySymbol()
        );
    }

    /**
     * @description getCurrencySymbol() should returned a cached currency
     * symbol, if it has been set
     */
    @isTest
    private static void testGetCurrencySymbolReturnsCachedSymbol() {
        ALLO_ManageAllocations_CTRL controller = new ALLO_ManageAllocations_CTRL();
        controller.currencySymbol = 'FOO';

        System.assertEquals(
            'FOO',
            controller.getCurrencySymbol()
        );
    }

    /** @description test the methods to retreive the currency separator characters */
    @isTest
    private static void testGetSeparators() {
        ALLO_ManageAllocations_CTRL controller = new ALLO_ManageAllocations_CTRL();
        system.AssertNotEquals(null, controller.getDecimalSeparator());
        system.AssertNotEquals(null, controller.getThousandsSeparator());
    }

    /**
    * @description Verifies that the controller should not include Rich Text Field type and parent sobject field 
    */
    @isTest
    private static void shouldReturnFieldSetsWithoutRichTextAndParentSobjectFields() {
        ALLO_ManageAllocations_CTRL controller = new ALLO_ManageAllocations_CTRL();

        Test.startTest();
        List<Schema.FieldSetMember> additionalFields = controller.getAdditionalAllocationFields();
        Test.stopTest();

        for (Schema.FieldSetMember field : additionalFields) {
            Boolean isRichTextField = 
                field.getType() == Schema.DisplayType.TEXTAREA && field.getSObjectField().getDescribe().isHtmlFormatted();
            Boolean isParentSobjectField = field.getFieldPath().contains('__r.');

            System.assertEquals(false, isRichTextField,
                'Rich Text field should not be included in the Manage Allocation Additional Fields fieldset');
            System.assertEquals(false, isParentSobjectField,
                'Parent Sobject field should not be included in the Manage Allocation Additional Fields fieldset ');
        }
    }

    // Helpers
    ///////////

    /**
     * @description Creates the Manage Allocations controller 
     * @param Id An RD/Campaign/Opportunity Id
     * @return ALLO_ManageAllocations_CTRL The controller
     */
    private static ALLO_ManageAllocations_CTRL setUpController(Id sobjId) {
        Test.setCurrentPage(Page.ALLO_ManageAllocations);
        ApexPages.currentPage().getParameters().put('id', sobjId);

        return new ALLO_ManageAllocations_CTRL(
            new ApexPages.StandardSetController(new List<Allocation__c>())
        );
    }
}