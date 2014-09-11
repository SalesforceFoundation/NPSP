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
* @description tests for the PaymentCreator class 
*/

@isTest
private with sharing class PMT_PaymentCreator_TEST {

    // if you only want to run one test in this class, fill in its name here.
    // if you want to run all tests, then use '*'
    private static string strTestOnly = '*';
    
        
    /*********************************************************************************************************
    operation:
        close an Opp as Lost that has a mixture of paid & unpaid payments, some written off 
    verify:
        opp is closed
        paid payments are left alone
        written off payments are left alone
        unpaid (and not written off) are deleted
    **********************************************************************************************************/            
    static testMethod void CloseLostOppWithMixOfPayments() {
        if (strTestOnly != '*' && strTestOnly != 'CloseLostOppWithMixOfPayments') return;
        
        npe01__Contacts_And_Orgs_Settings__c PaymentsSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_And_Orgs_Settings__c (npe01__Payments_Enabled__c= true));
        
        // create test data
        Account acct = new Account (
            Name='Test Account'
        );
        insert acct;
        Opportunity opp1 = new Opportunity (
            Name='Test Opp',
            AccountId = acct.id,
            Amount = 150,
            CloseDate = date.today(), 
            StageName = 'Closed Won'
        );
        insert opp1;
        
        npe01__OppPayment__c[] opmtUpdate = [select id,npe01__paid__c, npe01__payment_amount__c from npe01__OppPayment__c WHERE npe01__opportunity__c = :opp1.Id];
        opmtUpdate[0].npe01__payment_amount__c = 50;
        system.assertEquals(true, opmtUpdate[0].npe01__paid__c);
        update opmtUpdate;
        
        npe01__OppPayment__c pmtUnpaid = new npe01__OppPayment__c(
            npe01__Opportunity__c = opp1.id,
            npe01__Payment_Amount__c = 50,
            npe01__Paid__c = false,
            npe01__Payment_Date__c = date.today()
        );
        insert pmtUnpaid;
        npe01__OppPayment__c pmtWrittenOff = new npe01__OppPayment__c(
            npe01__Opportunity__c = opp1.id,
            npe01__Payment_Amount__c = 50,
            npe01__Paid__c = false,
            npe01__Written_Off__c = true,
            npe01__Payment_Date__c = date.today()
        );
        insert pmtWrittenOff;
        
        Test.startTest();
        opp1.StageName = 'Closed Lost';
        update opp1;
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
        system.assertEquals(50, opmtWrittenOff[0].npe01__payment_amount__c);       
    }


}