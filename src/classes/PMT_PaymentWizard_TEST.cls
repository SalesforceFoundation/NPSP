/*
    Copyright (c) 2011, Salesforce.com Foundation
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
* @author Evan Callahan & Steve Andersen
* @date 2008/7 (2.1)
* @description tests for payment creation wizard
*/
@isTest
private class PMT_PaymentWizard_TEST {

    /***  TEST METHODS ***/
    @isTest
    public static string closedWonStage(){      
        string closedWonStage;
        List<OpportunityStage> closedWonStages = [select MasterLabel from opportunitystage where isActive = true and iswon = true];
        if(closedWonStages.size()>0){
            closedWonStage = closedWonStages[0].MasterLabel;
        } else {
                closedWonStage = '';
        }
        return closedWonStage;      
    }     
    

    
    public static testMethod void test_paymentsEnabled_WriteOff() {
        
        npe01__Contacts_And_Orgs_Settings__c PaymentsSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_And_Orgs_Settings__c (npe01__Payments_Enabled__c= true));
        
        // create test data
        Account acct = new Account (
            Name='Test Account'
        );
        insert acct;
        Opportunity opp1 = new Opportunity (
            Name='Test Opp',
            AccountId = acct.id,
            Amount = 150,
            closedate = date.newInstance(2001,12,12),
            stagename = closedWonStage()
        );
        insert opp1;
        
        npe01__OppPayment__c[] opmtUpdate = [select id,npe01__paid__c, npe01__payment_amount__c from npe01__OppPayment__c WHERE npe01__opportunity__c = :opp1.Id];
        opmtUpdate[0].npe01__payment_amount__c = 50;
        system.assertEquals(true, opmtUpdate[0].npe01__paid__c);
        update opmtUpdate;
        
        npe01__OppPayment__c newOpmt = new npe01__OppPayment__c(
            npe01__Opportunity__c = opp1.id,
            npe01__Payment_Amount__c = 100,
            npe01__Paid__c = false,
            npe01__Payment_Date__c = date.newInstance(2001,12,12)
        );
        insert newOpmt;
        
        Test.startTest();
        
        npe01__OppPayment__c[] opmtAllStart = [select id, npe01__payment_method__c, npe01__payment_amount__c, npe01__paid__c, npe01__written_off__c from npe01__OppPayment__c WHERE npe01__opportunity__c = :opp1.Id];
        system.assertEquals(2, opmtAllStart.size());

        // create the page 
        PageReference pageRef=Page.PMT_PaymentWizard; 
        Test.setCurrentPage(pageRef);

        // set the parameter for the contact
        ApexPages.currentPage().getParameters().put('id', opp1.id);
        ApexPages.currentPage().getParameters().put('wtype', 'writeoff');
        
        // instantiate the controller
        PMT_PaymentWizard_CTRL controller=new PMT_PaymentWizard_CTRL();
        controller.PaymentWriteoffWizard();
        
        // set values
        controller.writeoffPayment.npe01__payment_date__c = date.newInstance(2001,12,12);
        
        // click calculate
        pagereference ref = controller.writeoff();

        Test.stopTest();
        
        // look for the data
        //should be two, one paid, one written off for the balance 
        npe01__OppPayment__c[] opmtAll = [select id, npe01__payment_method__c, npe01__payment_amount__c, npe01__paid__c, npe01__written_off__c from npe01__OppPayment__c WHERE npe01__opportunity__c = :opp1.Id];
        system.assertEquals(2, opmtAll.size());
        
        //the single payment should be written off
        npe01__OppPayment__c[] opmtOpen = [select id, npe01__payment_method__c, npe01__payment_amount__c, npe01__paid__c, npe01__written_off__c from npe01__OppPayment__c WHERE npe01__opportunity__c = :opp1.Id and npe01__paid__c = false and npe01__written_off__c = false];
        system.assertEquals(0, opmtOpen.size());
        
        npe01__OppPayment__c[] opmtPaid = [select id, npe01__payment_method__c, npe01__payment_amount__c, npe01__paid__c, npe01__written_off__c from npe01__OppPayment__c WHERE npe01__opportunity__c = :opp1.Id and npe01__paid__c = true and npe01__written_off__c = false];
        system.assertEquals(1, opmtPaid.size());
        system.assertEquals(50, opmtPaid[0].npe01__payment_amount__c);
        
        npe01__OppPayment__c[] opmtWrittenOff = [select id, npe01__payment_method__c, npe01__payment_amount__c, npe01__paid__c, npe01__written_off__c from npe01__OppPayment__c WHERE npe01__opportunity__c = :opp1.Id and npe01__paid__c = false and npe01__written_off__c = true];
        system.assertEquals(1, opmtWrittenOff.size());
        system.assertEquals(100, opmtWrittenOff[0].npe01__payment_amount__c);       
    }
    
    public static testMethod void test_PageElementsMonthly() {
        
        // create test data
        Account acct = new Account (
            Name='Test Account'
        );
        insert acct;
        Opportunity opp = new Opportunity (
            Name='Test Opp',
            AccountId = acct.id,
            Amount = 1300,
            closedate = system.today(),
            stagename = 'Pledged'
        );
        insert opp;
        npe01__OppPayment__c[] pmts = new npe01__OppPayment__c[0];
        pmts.add( new npe01__OppPayment__c (
            npe01__opportunity__c = opp.id,
            npe01__payment_amount__c = 100,
            npe01__paid__c = true )
        );
        pmts.add( new npe01__OppPayment__c (
            npe01__opportunity__c = opp.id,
            npe01__payment_amount__c = 999,
            npe01__paid__c = false )
        );
        insert pmts;
         
        Test.startTest();

        // create the page 
        PageReference pageRef=Page.PMT_PaymentWizard; 
        Test.setCurrentPage(pageRef); 

        // set the parameter for the contact
        ApexPages.currentPage().getParameters().put('id', opp.id);
        ApexPages.currentPage().getParameters().put('wtype', 'payment');
        
        // instantiate the controller
        PMT_PaymentWizard_CTRL controller=new PMT_PaymentWizard_CTRL();
        controller.SetupPaymentWizard();
        
        // get lists
        List<SelectOption> l = controller.getItems();
        l = controller.getIntervals();
        l = controller.getIntervalUnits();
        
        // set values
        controller.samplePayment.npe01__payment_method__c = 'Stock';
        
        // click calculate
        pagereference ref = controller.calculate();
        
        // save the page
        string nextPage=controller.createPayments().getUrl(); 

        // look for the data
        npe01__OppPayment__c[] opmt = [select id, npe01__payment_method__c, npe01__payment_amount__c from npe01__OppPayment__c WHERE npe01__opportunity__c = :opp.Id and npe01__paid__c = false];
        system.assertEquals(12, opmt.size());
        system.assertEquals('Stock', opmt[0].npe01__payment_method__c);
        system.assertEquals(100, opmt[0].npe01__payment_amount__c);

        // verify that the right page displays 
        System.assertEquals(nextPage, '/' + opp.id); 
    }
    
    public static testMethod void test_PageElementsWeekly() {
               
        // create test data
        Account acct = new Account (
            Name='Test Account'
        );
        insert acct;
        Opportunity opp = new Opportunity (
            Name='Test Opp',
            AccountId = acct.id,
            Amount = 400.01,
            closedate = date.newInstance(2001,12,12),
            stagename = 'Pledged'
        );
        insert opp;
         
        Test.startTest();

        // create the page 
        PageReference pageRef=Page.PMT_PaymentWizard; 
        Test.setCurrentPage(pageRef); 

        // set the parameter for the contact
        ApexPages.currentPage().getParameters().put('id', opp.id);
        ApexPages.currentPage().getParameters().put('wtype', 'payment');      
        
        // instantiate the controller
        PMT_PaymentWizard_CTRL controller=new PMT_PaymentWizard_CTRL();
        controller.SetupPaymentWizard();
        
        // get lists
        List<SelectOption> l = controller.getItems();
        l = controller.getIntervals();
        l = controller.getIntervalUnits();
        
        // set values
        controller.samplePayment.npe01__payment_method__c = 'Stock';
        controller.intervalUnit = 'Week';
        controller.numberOfPayments = 4;
        controller.samplePayment.npe01__Scheduled_Date__c = date.newInstance(2001,12,12);
        
        // click calculate
        pagereference ref = controller.calculate();
        
        // save the page
        string nextPage=controller.createPayments().getUrl(); 

        // look for the data
        npe01__OppPayment__c[] opmt = [select id, npe01__payment_method__c, npe01__payment_amount__c, npe01__scheduled_date__c from npe01__OppPayment__c WHERE npe01__opportunity__c = :opp.Id and npe01__paid__c = false order by npe01__scheduled_date__c asc];
        system.assertEquals(4, opmt.size());
        system.assertEquals('Stock', opmt[0].npe01__payment_method__c);        
        //system.assertEquals(100, opmt[0].npe01__payment_amount__c);
        system.assertEquals(opmt[1].npe01__scheduled_date__c, opmt[0].npe01__scheduled_date__c.addDays(7));
    }
    
    public static testMethod void test_PageElementsYearly() {
        
        // create test data
        Account acct = new Account (
            Name='Test Account'
        );
        insert acct;
        Opportunity opp = new Opportunity (
            Name='Test Opp',
            AccountId = acct.id,
            Amount = 400,
            closedate = date.newInstance(2001,12,12),
            stagename = 'Pledged'
        );
        insert opp;
         
        Test.startTest();

        // create the page 
        PageReference pageRef=Page.PMT_PaymentWizard; 
        Test.setCurrentPage(pageRef); 

        // set the parameter for the contact
        ApexPages.currentPage().getParameters().put('id', opp.id);      
        ApexPages.currentPage().getParameters().put('wtype', 'payment');
        // instantiate the controller
        PMT_PaymentWizard_CTRL controller=new PMT_PaymentWizard_CTRL();
        controller.SetupPaymentWizard();
        
        // get lists
        List<SelectOption> l = controller.getItems();
        l = controller.getIntervals();
        l = controller.getIntervalUnits();
        
        // set values
        controller.samplePayment.npe01__payment_method__c = 'Stock';
        controller.intervalUnit = 'Year';
        controller.numberOfPayments = 4;
        controller.samplePayment.npe01__Scheduled_Date__c = date.newInstance(2001,12,12);
        
        // click calculate
        pagereference ref = controller.calculate();
        
        // save the page
        string nextPage=controller.createPayments().getUrl(); 

        // look for the data
        npe01__OppPayment__c[] opmt = [select id, npe01__payment_method__c, npe01__payment_amount__c, npe01__scheduled_date__c from npe01__OppPayment__c WHERE npe01__opportunity__c = :opp.Id and npe01__paid__c = false];
        system.assertEquals(4, opmt.size());
        system.assertEquals('Stock', opmt[0].npe01__payment_method__c);
        system.assertEquals(100, opmt[0].npe01__payment_amount__c);
        system.assertEquals(opmt[1].npe01__scheduled_date__c, opmt[0].npe01__scheduled_date__c.addDays(365));
    }
    
    public static testMethod void test_nullOpps() {
    
        // create the page 
        PageReference pageRef=Page.PMT_PaymentWizard; 
        Test.setCurrentPage(pageRef);

        // set a bad id
        ApexPages.currentPage().getParameters().put('id', null);
        ApexPages.currentPage().getParameters().put('wtype', 'garbage');
        
        // instantiate the controller
        PMT_PaymentWizard_CTRL controller=new PMT_PaymentWizard_CTRL();
        
        //test bad page code
        Test.startTest();
        controller.SetupPaymentWizard();    
        controller.PaymentWriteoffWizard();             
        Test.stopTest();
    }
    
    public static testMethod void test_publicGetters() {
        
        // instantiate the controller
        PMT_PaymentWizard_CTRL controller=new PMT_PaymentWizard_CTRL();
        
        //test public method code
        Test.startTest();      
        controller.getPaymentsSettings();
        list<PMT_PaymentWizard_CTRL.payment> oplist = controller.getPayments();
        ApexPages.Pagereference pr = controller.RemovePaidPayments();             
        Test.stopTest();
    }    


    public static testMethod void test_RemovePaidPayments() {
        
        npe01__Contacts_And_Orgs_Settings__c PaymentsSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_And_Orgs_Settings__c (npe01__Payments_Enabled__c= true));
        
        // create test data
        Account acct = new Account (
            Name='Test Account'
        );
        insert acct;
        Opportunity opp1 = new Opportunity (
            Name='Test Opp',
            AccountId = acct.id,
            Amount = 150,
            closedate = date.newInstance(2001,12,12),
            stagename = closedWonStage()
        );
        insert opp1;
        
        npe01__OppPayment__c[] opmtUpdate = [select id,npe01__paid__c, npe01__payment_amount__c from npe01__OppPayment__c WHERE npe01__opportunity__c = :opp1.Id];
        opmtUpdate[0].npe01__payment_amount__c = 50;
        system.assertEquals(true, opmtUpdate[0].npe01__paid__c);
        update opmtUpdate;
        
        npe01__OppPayment__c newOpmt = new npe01__OppPayment__c(
            npe01__Opportunity__c = opp1.id,
            npe01__Payment_Amount__c = 100,
            npe01__Paid__c = true,
            npe01__Payment_Date__c = date.newInstance(2001,12,12)
        );
        insert newOpmt;
        
        Test.startTest();
        
        npe01__OppPayment__c[] opmtAllStart = [select id, npe01__payment_method__c, npe01__payment_amount__c, npe01__paid__c, npe01__written_off__c from npe01__OppPayment__c WHERE npe01__opportunity__c = :opp1.Id];
        system.assertEquals(2, opmtAllStart.size());

        // create the page 
        PageReference pageRef=Page.PMT_PaymentWizard; 
        Test.setCurrentPage(pageRef);

        // set the parameter for the contact
        ApexPages.currentPage().getParameters().put('id', opp1.id);
        ApexPages.currentPage().getParameters().put('wtype', 'payment');
        
        // instantiate the controller
        PMT_PaymentWizard_CTRL controller=new PMT_PaymentWizard_CTRL();
        controller.PaymentWriteoffWizard();
        
        // set values
        system.assertEquals(false, controller.haveAmount);        
        controller.RemovePaidPayments();
        system.assertEquals(true, controller.removePaidPayments);
        controller.intervalUnit = 'Monthly';
        controller.numberOfPayments = 4;
        controller.samplePayment.npe01__Scheduled_Date__c = date.newInstance(2001,12,12);
        
         // click calculate
        pagereference ref = controller.calculate();
        system.assertEquals(4, controller.getPayments().size());
        
        // save the page
        string nextPage=controller.createPayments().getUrl(); 

        // look for the data
        npe01__OppPayment__c[] opmt = [select id, npe01__payment_method__c, npe01__payment_amount__c, npe01__scheduled_date__c from npe01__OppPayment__c WHERE npe01__opportunity__c = :opp1.Id];
        system.assertEquals(4, opmt.size());
    }
}