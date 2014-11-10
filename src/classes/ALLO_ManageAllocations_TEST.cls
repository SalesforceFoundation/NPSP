/*
    Copyright (c) 2014, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
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
* @author Salesforce.com Foundation
* @date 2014
* @description Tests for the Manage Allocations page. 
*/
@isTest
private class ALLO_ManageAllocations_TEST {

    private static string strTestOnly = '*';

    private static void setupSettings (Allocations_Settings__c alloset) {
        //set running user to avoid dml issue            
        System.runAs(new User(id = UserInfo.getUserId())){
            if (alloset!=null)
                UTIL_CustomSettingsFacade.getAllocationsSettingsForTests(alloset);
            else 
                UTIL_CustomSettingsFacade.getAllocationsSettingsForTests(new Allocations_Settings__c());

        }
    }

    //run manage allocations page on an opportunity with no allocations
    //add and delete a row, insert an allocation
	@isTest static void testOpp() {
        if (strTestOnly != '*' && strTestOnly != 'testOpp') return;
        setupSettings(null);
		
		Account acc = new Account(Name='foo');
        insert acc;
        Opportunity opp = new Opportunity(Name='foo', Amount = 8, AccountID=acc.id, CloseDate=system.today(), StageName=UTIL_UnitTestData_TEST.getClosedWonStage());
        insert opp;
        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(Name='foo');
        insert gau;

		PageReference pageRef = Page.ALLO_ManageAllocations;
    	Test.setCurrentPage(pageRef);
    	ApexPages.currentPage().getParameters().put('opp', opp.id);
    	ALLO_ManageAllocations_CTRL ctrl = new ALLO_ManageAllocations_CTRL();

    	system.assertEquals(1,ctrl.listAllo.size(),'The list of allocations should have a single empty allocation.');
    	system.assertEquals(null,ctrl.listAllo[0].id,'The allocation should have no Id.');
    	system.assertEquals(opp.Id,ctrl.listAllo[0].Opportunity__c,'The allocation should be attributed to current opportunity.');

    	ctrl.rowNumber = 0;
    	ctrl.addRow();
    	system.assertEquals(2,ctrl.listAllo.size(),'Adding a row increases the size of the allocation list.');

        ALLO_Allocations_TDTM.resetFlags(false);

    	ctrl.listAllo[0].Percent__c = 50;
    	ctrl.listAllo[0].General_Accounting_Unit__c = gau.id;
		ctrl.rowNumber = 1;
    	ctrl.delRow();
    	ctrl.saveClose();

    	list<Allocation__c> queryAllo = [SELECT Id, Percent__c, Amount__c FROM Allocation__c WHERE Opportunity__c=:opp.id];
    	system.assertEquals(1,queryAllo.size(),'The single allocation should be saved.');
    	system.assertEquals(4,queryAllo[0].Amount__c,'The amount should be calculated based on the percent.');
	}

    //run manage allocations page on campaign with two allocations
    //add a new allocation, delete an existing one, check results
	@isTest static void testCam() {
        if (strTestOnly != '*' && strTestOnly != 'testCam') return;
        setupSettings(null);
		
		Account acc = new Account(Name='foo');
        insert acc;
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

		PageReference pageRef = Page.ALLO_ManageAllocations;
    	Test.setCurrentPage(pageRef);
    	ApexPages.currentPage().getParameters().put('cam', cam.id);
    	ALLO_ManageAllocations_CTRL ctrl = new ALLO_ManageAllocations_CTRL();

    	system.assertEquals(2,ctrl.listAllo.size(),'The list of allocations should have two current campaign allocations.');

    	ctrl.addRow();
    	system.assertEquals(3,ctrl.listAllo.size(),'Adding a row increases the size of the allocation list.');

    	//delete the first allocation on the list
    	ctrl.rowNumber = 0;
    	ctrl.delRow();

        ALLO_Allocations_TDTM.resetFlags(false);

    	ctrl.listAllo[1].Amount__c = 5;
    	ctrl.listAllo[1].General_Accounting_Unit__c = campaigngau.id;
    	ctrl.saveClose();

    	list<Allocation__c> queryAllo = [SELECT Id, Percent__c, Amount__c FROM Allocation__c WHERE Campaign__c=:cam.id];
    	system.assertEquals(2,queryAllo.size(),'2 allocations should be saved, one original allocation should be deleted.');
	}

	//run manage allocations page on recurring with two allocations
    //add a new allocation, delete an existing one, check results
	@isTest static void testRD() {
        if (strTestOnly != '*' && strTestOnly != 'testRD') return;
        setupSettings(null);
        
        Account acc = new Account(Name='foo');
        insert acc;
        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(Name = 'foo');
        insert gau;
        npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c(
            Name = 'foo', 
            npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodYearly, 
            npe03__Date_Established__c=date.newinstance(1984,01,29), 
            npe03__Organization__c = acc.id, 
            npe03__Amount__c = 20,
            npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue,
            npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationOpenStatus
        );
        insert rd;
        list<Allocation__c> alloForInsert = new list<Allocation__c>();
        Allocation__c percentAllo = new Allocation__c(Recurring_Donation__c = rd.id, Percent__c = 50, General_Accounting_Unit__c = gau.id);
        alloForInsert.add(percentAllo);
        Allocation__c amountAllo = new Allocation__c(Recurring_Donation__c = rd.id, Amount__c = 10, General_Accounting_Unit__c = gau.id);
        alloForInsert.add(amountAllo);
        insert alloForInsert;

		PageReference pageRef = Page.ALLO_ManageAllocations;
    	Test.setCurrentPage(pageRef);
    	ApexPages.currentPage().getParameters().put('rd', rd.id);
    	ALLO_ManageAllocations_CTRL ctrl = new ALLO_ManageAllocations_CTRL();

    	system.assertEquals(2,ctrl.listAllo.size(),'The list of allocations should have two current campaign allocations.');

    	ctrl.addRow();
    	system.assertEquals(3,ctrl.listAllo.size(),'Adding a row increases the size of the allocation list.');

    	//delete the first allocation on the list
    	ctrl.rowNumber = 0;
    	ctrl.delRow();

        ALLO_Allocations_TDTM.resetFlags(false);

    	ctrl.listAllo[1].Amount__c = 5;
    	ctrl.listAllo[1].General_Accounting_Unit__c = gau.id;
    	ctrl.saveClose();

    	list<Allocation__c> queryAllo = [SELECT Id, Percent__c, Amount__c FROM Allocation__c WHERE Recurring_Donation__c=:rd.id];
    	system.assertEquals(2,queryAllo.size(),'2 allocations should be saved, one original allocation should be deleted.');
	}
}