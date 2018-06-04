/*
    Copyright (c) 2017 Salesforce.org
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
    'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
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
* @date 2017
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description tests specific to the Batch Data Importer Donations batch processing and record creation
*/

@isTest
public with sharing class BDI_Donations_TEST {

    /*********************************************************************************************************
    * @description if you only want to run one test in this class, fill in its name here.
    * if you want to run all tests, then use '*'
    */
    private static string strTestOnly = '*';

    /*********************************************************************************************************
    * @description holds test Contacts for BDI donations tests
    */
    private static List<Contact> listConT;
    
    /*********************************************************************************************************
    * @description holds test Opps for use in BDI donations tests
    */
    private static list<Opportunity> listOppT;
    
    /*********************************************************************************************************
    * @description create test contacts and donations for use in BDI donations tests
    */
    static void createTestData() {
        listConT = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(2);
        insert listConT;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConT);

        listOppT = UTIL_UnitTestData_TEST.OppsForContactList(listConT, null, 
            UTIL_unitTestData_TEST.getOpenStage(), system.Today(), 100, null, null);
        insert listOppT;
    }

    /*********************************************************************************************************
    * @description operation
    *        import existing contacts with existing open Opportunities  
    * verify: 
    *       opportunity objects matched & closed
    *       payment objects updated
    */
    static testMethod void TwoDIWithExistingDonations() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'TwoDIWithExistingDonations') return;
        
        createTestData();
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c=listConT[0].Firstname, Contact1_Lastname__c=listConT[0].Lastname, 
            Contact1_Work_Email__c=listConT[0].npe01__WorkEmail__c));
        listDI.add(new DataImport__c(Contact1_Firstname__c=listConT[1].Firstname, Contact1_Lastname__c=listConT[1].Lastname, 
            Contact1_Work_Email__c=listConT[1].npe01__WorkEmail__c));
        listDI[0].Donation_Amount__c = listOppT[0].Amount;
        listDI[0].Donation_Date__c = listOppT[0].CloseDate;
        listDI[1].Donation_Amount__c = listOppT[1].Amount;
        listDI[1].Donation_Date__c = listOppT[1].CloseDate;
        listDI[0].Payment_Check_Reference_Number__c = 'abc';
        listDI[1].Payment_Check_Reference_Number__c = '1234';
        listDI[0].Payment_Method__c = 'Check';
        listDI[1].Payment_Method__c = 'Visa';       
        insert listDI;

        // set the specified settings
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Donation_Matching_Rule__c = UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c');
        diSettings.Donation_Matching_Behavior__c = BDI_DataImport_API.ExactMatchOrCreate;
        diSettings.Run_Opportunity_Rollups_while_Processing__c = true;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Contact> listCon = [select Id, Name, AccountId, npo02__TotalOppAmount__c from Contact order by Id];
        system.assertEquals(2, listCon.size());
        system.assertEquals(listOppT[0].Amount, listCon[0].npo02__TotalOppAmount__c);
        system.assertEquals(listOppT[1].Amount, listCon[1].npo02__TotalOppAmount__c);
        
        list<Account> listAcc = [select Id, Name, npo02__TotalOppAmount__c from Account order by Id];
        system.assertEquals(2, listAcc.size());
        system.assertEquals(listOppT[0].Amount, listAcc[0].npo02__TotalOppAmount__c);
        system.assertEquals(listOppT[1].Amount, listAcc[1].npo02__TotalOppAmount__c);
        
        list<Opportunity> listOpp = [select Id, Name, Amount, StageName, isWon, isClosed, AccountId from Opportunity order by Id];
        system.assertEquals(2, listOpp.size());
        system.assertEquals(true, listOpp[0].isWon);
        system.assertEquals(true, listOpp[1].isWon);
        
        list<npe01__OppPayment__c> listPmt = [select Id, npe01__Payment_Amount__c, npe01__Payment_Method__c, npe01__Check_Reference_Number__c from npe01__OppPayment__c order by npe01__Opportunity__r.Id];
        system.assertEquals(2, listPmt.size());
        system.assertEquals('Check', listPmt[0].npe01__Payment_Method__c);
        system.assertEquals('Visa', listPmt[1].npe01__Payment_Method__c);
        system.assertEquals('abc', listPmt[0].npe01__Check_Reference_Number__c);
        system.assertEquals('1234', listPmt[1].npe01__Check_Reference_Number__c);

        listDI = [select Id, DonationImported__c, DonationImportStatus__c from DataImport__c order by Id];
        system.assertEquals(2, listDI.size());
        system.assertEquals(listDI[0].DonationImported__c, listOpp[0].Id); 
        system.assertEquals(listDI[1].DonationImported__c, listOpp[1].Id);
        system.assertEquals(label.bdiMatched, listDI[0].DonationImportStatus__c);
        system.assertEquals(label.bdiMatched, listDI[1].DonationImportStatus__c);        
    }

    /*********************************************************************************************************
    * @description operation
    *        import existing contacts with existing open Opportunities
    * verify:
    *       opportunity objects matched & closed
    *       payment objects marked paid (even when no other payment fields need updating)
    */
    static testMethod void TwoDIWithExistingDonationsNoExtraPaymentUpdates() {
        if (strTestOnly != '*' && strTestOnly != 'TwoDIWithExistingDonationsNoExtraPaymentUpdates') return;

        createTestData();

        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c=listConT[0].Firstname, Contact1_Lastname__c=listConT[0].Lastname,
            Contact1_Work_Email__c=listConT[0].npe01__WorkEmail__c));
        listDI.add(new DataImport__c(Contact1_Firstname__c=listConT[1].Firstname, Contact1_Lastname__c=listConT[1].Lastname,
            Contact1_Work_Email__c=listConT[1].npe01__WorkEmail__c));
        listDI[0].Donation_Amount__c = listOppT[0].Amount;
        listDI[0].Donation_Date__c = listOppT[0].CloseDate;
        listDI[1].Donation_Amount__c = listOppT[1].Amount;
        listDI[1].Donation_Date__c = listOppT[1].CloseDate;
        insert listDI;

        // set the specified settings
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Donation_Matching_Rule__c = UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c');
        diSettings.Donation_Matching_Behavior__c = BDI_DataImport_API.ExactMatchOrCreate;
        diSettings.Run_Opportunity_Rollups_while_Processing__c = true;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        list<Contact> listCon = [select Id, Name, AccountId, npo02__TotalOppAmount__c from Contact order by Id];
        system.assertEquals(2, listCon.size());
        system.assertEquals(listOppT[0].Amount, listCon[0].npo02__TotalOppAmount__c);
        system.assertEquals(listOppT[1].Amount, listCon[1].npo02__TotalOppAmount__c);

        list<Account> listAcc = [select Id, Name, npo02__TotalOppAmount__c from Account order by Id];
        system.assertEquals(2, listAcc.size());
        system.assertEquals(listOppT[0].Amount, listAcc[0].npo02__TotalOppAmount__c);
        system.assertEquals(listOppT[1].Amount, listAcc[1].npo02__TotalOppAmount__c);

        list<Opportunity> listOpp = [select Id, Name, Amount, StageName, isWon, isClosed, AccountId from Opportunity order by Id];
        system.assertEquals(2, listOpp.size());
        system.assertEquals(true, listOpp[0].isWon);
        system.assertEquals(true, listOpp[1].isWon);

        list<npe01__OppPayment__c> listPmt = [select Id, npe01__Paid__c from npe01__OppPayment__c order by npe01__Opportunity__r.Id];
        system.assertEquals(2, listPmt.size());
        system.assertEquals(true, listPmt[0].npe01__Paid__c);
        system.assertEquals(true, listPmt[1].npe01__Paid__c);

        listDI = [select Id, DonationImported__c, DonationImportStatus__c, PaymentImported__c, PaymentImportStatus__c from DataImport__c order by Id];
        system.assertEquals(2, listDI.size());
        system.assertEquals(listDI[0].DonationImported__c, listOpp[0].Id);
        system.assertEquals(listDI[1].DonationImported__c, listOpp[1].Id);
        system.assertEquals(label.bdiMatched, listDI[0].DonationImportStatus__c);
        system.assertEquals(label.bdiMatched, listDI[1].DonationImportStatus__c);
        system.assertEquals(label.bdiMatched, listDI[0].PaymentImportStatus__c);
        system.assertEquals(label.bdiMatched, listDI[1].PaymentImportStatus__c);
    }

    /*********************************************************************************************************
    * @description operation
    *        import existing contacts with existing open Opportunities
    * verify:
    *       opportunity objects matched & closed
    *       payment objects marked paid (even when no other payment fields need updating)
    *       original payment date not changed
    */
    static testMethod void TwoDIWithExistingDonationsPreservePaymentDate() {
        if (strTestOnly != '*' && strTestOnly != 'TwoDIWithExistingDonationsPreservePaymentDate') return;

        createTestData();

        list<npe01__OppPayment__c> listPmtT = [SELECT Id, npe01__Payment_Date__c FROM npe01__OppPayment__c];
        System.assertEquals(2, listPmtT.size());
        listPmtT[0].npe01__Payment_Date__c = listOppT[0].CloseDate;
        listPmtT[1].npe01__Payment_Date__c = listOppT[1].CloseDate;
        update listPmtT;

        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c=listConT[0].Firstname, Contact1_Lastname__c=listConT[0].Lastname,
            Contact1_Work_Email__c=listConT[0].npe01__WorkEmail__c));
        listDI.add(new DataImport__c(Contact1_Firstname__c=listConT[1].Firstname, Contact1_Lastname__c=listConT[1].Lastname,
            Contact1_Work_Email__c=listConT[1].npe01__WorkEmail__c));
        listDI[0].Donation_Amount__c = listOppT[0].Amount;
        listDI[0].Donation_Date__c = listOppT[0].CloseDate.addDays(2);
        listDI[1].Donation_Amount__c = listOppT[1].Amount;
        listDI[1].Donation_Date__c = listOppT[1].CloseDate.addDays(2);
        insert listDI;

        // set the specified settings
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Donation_Matching_Rule__c = UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c');
        diSettings.Donation_Matching_Behavior__c = BDI_DataImport_API.ExactMatchOrCreate;
        diSettings.Donation_Date_Range__c = 3;
        diSettings.Run_Opportunity_Rollups_while_Processing__c = true;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        list<Contact> listCon = [select Id, Name, AccountId, npo02__TotalOppAmount__c from Contact order by Id];
        system.assertEquals(2, listCon.size());
        system.assertEquals(listOppT[0].Amount, listCon[0].npo02__TotalOppAmount__c);
        system.assertEquals(listOppT[1].Amount, listCon[1].npo02__TotalOppAmount__c);

        list<Account> listAcc = [select Id, Name, npo02__TotalOppAmount__c from Account order by Id];
        system.assertEquals(2, listAcc.size());
        system.assertEquals(listOppT[0].Amount, listAcc[0].npo02__TotalOppAmount__c);
        system.assertEquals(listOppT[1].Amount, listAcc[1].npo02__TotalOppAmount__c);

        list<Opportunity> listOpp = [select Id, Name, Amount, StageName, isWon, isClosed, AccountId from Opportunity order by Id];
        system.assertEquals(2, listOpp.size());
        system.assertEquals(true, listOpp[0].isWon);
        system.assertEquals(true, listOpp[1].isWon);

        list<npe01__OppPayment__c> listPmt = [select Id, npe01__Paid__c, npe01__Payment_Date__c, npe01__Opportunity__r.CloseDate from npe01__OppPayment__c order by npe01__Opportunity__r.Id];
        system.assertEquals(2, listPmt.size());
        system.assertEquals(true, listPmt[0].npe01__Paid__c);
        system.assertEquals(true, listPmt[1].npe01__Paid__c);
        system.assertEquals(listPmt[0].npe01__Opportunity__r.CloseDate, listPmt[0].npe01__Payment_Date__c);
        system.assertEquals(listPmt[1].npe01__Opportunity__r.CloseDate, listPmt[1].npe01__Payment_Date__c);

        listDI = [select Id, DonationImported__c, DonationImportStatus__c, PaymentImported__c, PaymentImportStatus__c from DataImport__c order by Id];
        system.assertEquals(2, listDI.size());
        system.assertEquals(listDI[0].DonationImported__c, listOpp[0].Id);
        system.assertEquals(listDI[1].DonationImported__c, listOpp[1].Id);
        system.assertEquals(label.bdiMatched, listDI[0].DonationImportStatus__c);
        system.assertEquals(label.bdiMatched, listDI[1].DonationImportStatus__c);
        system.assertEquals(label.bdiMatched, listDI[0].PaymentImportStatus__c);
        system.assertEquals(label.bdiMatched, listDI[1].PaymentImportStatus__c);
    }

    /*********************************************************************************************************
    * @description operation
    *        import existing contacts with existing open Opportunities specified in DonationImported__c  
    * verify: 
    *       opportunity objects matched & closed
    *       payment objects updated
    */
    static testMethod void TwoDIWithExistingDonationsSpecified() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'TwoDIWithExistingDonationsSpecified') return;
        
        createTestData();
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c=listConT[0].Firstname, Contact1_Lastname__c=listConT[0].Lastname, 
            Contact1_Work_Email__c=listConT[0].npe01__WorkEmail__c));
        listDI.add(new DataImport__c(Contact1_Firstname__c=listConT[1].Firstname, Contact1_Lastname__c=listConT[1].Lastname, 
            Contact1_Work_Email__c=listConT[1].npe01__WorkEmail__c));

        listDI[0].Donation_Amount__c = listOppT[0].Amount;
        listDI[0].Donation_Date__c = listOppT[0].CloseDate;
        listDI[0].DonationImported__c = listOppT[0].Id;
        listDI[0].Payment_Check_Reference_Number__c = 'abc';
        listDI[0].Payment_Method__c = 'Check';

        listDI[1].Donation_Amount__c = listOppT[1].Amount;
        listDI[1].Donation_Date__c = listOppT[1].CloseDate;
        listDI[1].DonationImported__c = listOppT[1].Id;
        listDI[1].Payment_Check_Reference_Number__c = '1234';
        listDI[1].Payment_Method__c = 'Visa';       
        insert listDI;
          
        // set the specified settings
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Donation_Matching_Rule__c = UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c');
        // make sure we support matching by Id even when no match specified.
        diSettings.Donation_Matching_Behavior__c = BDI_DataImport_API.RequireNoMatch;
        diSettings.Run_Opportunity_Rollups_while_Processing__c = true;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Contact> listCon = [select Id, Name, AccountId, npo02__TotalOppAmount__c from Contact order by Id];
        system.assertEquals(2, listCon.size());
        system.assertEquals(listOppT[0].Amount, listCon[0].npo02__TotalOppAmount__c);
        system.assertEquals(listOppT[1].Amount, listCon[1].npo02__TotalOppAmount__c);
        
        list<Account> listAcc = [select Id, Name, npo02__TotalOppAmount__c from Account order by Id];
        system.assertEquals(2, listAcc.size());
        system.assertEquals(listOppT[0].Amount, listAcc[0].npo02__TotalOppAmount__c);
        system.assertEquals(listOppT[1].Amount, listAcc[1].npo02__TotalOppAmount__c);
        
        list<Opportunity> listOpp = [select Id, Name, Amount, StageName, isWon, isClosed, AccountId from Opportunity order by Id];
        system.assertEquals(2, listOpp.size());
        system.assertEquals(true, listOpp[0].isWon);
        system.assertEquals(true, listOpp[1].isWon);
        
        list<npe01__OppPayment__c> listPmt = [select Id, npe01__Payment_Amount__c, npe01__Payment_Method__c, npe01__Check_Reference_Number__c from npe01__OppPayment__c order by npe01__Opportunity__r.Id];
        system.assertEquals(2, listPmt.size());
        system.assertEquals('Check', listPmt[0].npe01__Payment_Method__c);
        system.assertEquals('Visa', listPmt[1].npe01__Payment_Method__c);
        system.assertEquals('abc', listPmt[0].npe01__Check_Reference_Number__c);
        system.assertEquals('1234', listPmt[1].npe01__Check_Reference_Number__c);

        listDI = [select Id, DonationImported__c, DonationImportStatus__c from DataImport__c order by Id];
        system.assertEquals(2, listDI.size());
        system.assertEquals(listDI[0].DonationImported__c, listOpp[0].Id); 
        system.assertEquals(listDI[1].DonationImported__c, listOpp[1].Id);
        system.assertEquals(label.bdiMatchedId, listDI[0].DonationImportStatus__c);
        system.assertEquals(label.bdiMatchedId, listDI[1].DonationImportStatus__c);        
    }
    
    /*********************************************************************************************************
    * @description operation
    *        import existing contacts with existing open Payments specified in PaymentImported__c  
    * verify: 
    *       opportunity objects matched & closed
    *       payment objects updated
    */
    static testMethod void TwoDIWithExistingPaymentsSpecified() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'TwoDIWithExistingPaymentsSpecified') return;
        
        createTestData();
        // for the first Opp, let's create multiple payments equal payments for it.
        list<npe01__OppPayment__c> listPmt = new list<npe01__OppPayment__c>();
        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOppT[0].Id, npe01__Payment_Amount__c=25, 
            npe01__Scheduled_Date__c=System.Today()));
        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOppT[0].Id, npe01__Payment_Amount__c=25, 
            npe01__Scheduled_Date__c=System.Today()));
        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOppT[0].Id, npe01__Payment_Amount__c=25, 
            npe01__Scheduled_Date__c=System.Today()));
        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOppT[0].Id, npe01__Payment_Amount__c=25, 
            npe01__Scheduled_Date__c=System.Today()));
        insert listPmt;
        listPmt = [select Id, npe01__Opportunity__c from npe01__OppPayment__c order by npe01__Opportunity__c, Id];
        system.assertEquals(6, listPmt.size());
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c=listConT[0].Firstname, Contact1_Lastname__c=listConT[0].Lastname, 
            Contact1_Work_Email__c=listConT[0].npe01__WorkEmail__c));
        listDI.add(new DataImport__c(Contact1_Firstname__c=listConT[1].Firstname, Contact1_Lastname__c=listConT[1].Lastname, 
            Contact1_Work_Email__c=listConT[1].npe01__WorkEmail__c));

        listDI[0].Donation_Amount__c = 25;
        listDI[0].Donation_Date__c = listOppT[0].CloseDate;
        listDI[0].PaymentImported__c = listPmt[2].Id;
        listDI[0].Payment_Check_Reference_Number__c = 'abc';
        listDI[0].Payment_Method__c = 'Check';

        listDI[1].Donation_Amount__c = listOppT[1].Amount;
        listDI[1].Donation_Date__c = listOppT[1].CloseDate;
        listDI[1].PaymentImported__c = listPmt[5].Id;
        listDI[1].Payment_Check_Reference_Number__c = '1234';
        listDI[1].Payment_Method__c = 'Visa';       
        insert listDI;
          
        // set the specified settings
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Donation_Matching_Rule__c = UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c');
        // make sure we support matching by Id even when no match specified.
        diSettings.Donation_Matching_Behavior__c = BDI_DataImport_API.RequireNoMatch;
        diSettings.Run_Opportunity_Rollups_while_Processing__c = true;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Opportunity> listOpp = [select Id, Name, Amount, StageName, isWon, isClosed, AccountId from Opportunity order by Id];
        system.assertEquals(2, listOpp.size());
        system.assertEquals(false, listOpp[0].isWon);
        system.assertEquals(true, listOpp[1].isWon);
        
        list<Contact> listCon = [select Id, Name, AccountId, npo02__TotalOppAmount__c from Contact order by Id];
        system.assertEquals(2, listCon.size());
        system.assertEquals(0, listCon[0].npo02__TotalOppAmount__c);
        system.assertEquals(listOppT[1].Amount, listCon[1].npo02__TotalOppAmount__c);
        
        list<Account> listAcc = [select Id, Name, npo02__TotalOppAmount__c from Account order by Id];
        system.assertEquals(2, listAcc.size());
        system.assertEquals(0, listAcc[0].npo02__TotalOppAmount__c);
        system.assertEquals(listOppT[1].Amount, listAcc[1].npo02__TotalOppAmount__c);
        
        npe01__OppPayment__c pmt0 = [select Id, npe01__Payment_Amount__c, npe01__Payment_Method__c, npe01__Check_Reference_Number__c 
            from npe01__OppPayment__c where id = :listDI[0].PaymentImported__c];
        system.assertEquals('abc', pmt0.npe01__Check_Reference_Number__c);
        system.assertEquals('Check', pmt0.npe01__Payment_Method__c);

        npe01__OppPayment__c pmt1 = [select Id, npe01__Payment_Amount__c, npe01__Payment_Method__c, npe01__Check_Reference_Number__c 
            from npe01__OppPayment__c where id = :listDI[1].PaymentImported__c];
        system.assertEquals('Visa', pmt1.npe01__Payment_Method__c);
        system.assertEquals('1234', pmt1.npe01__Check_Reference_Number__c);

        listDI = [select Id, DonationImported__c, DonationImportStatus__c, PaymentImported__c, PaymentImportStatus__c 
            from DataImport__c order by Id];
        system.assertEquals(2, listDI.size());
        system.assertEquals(listDI[0].DonationImported__c, listOpp[0].Id); 
        system.assertEquals(listDI[1].DonationImported__c, listOpp[1].Id);
        system.assertEquals(label.bdiMatchedId, listDI[0].DonationImportStatus__c);
        system.assertEquals(label.bdiMatchedId, listDI[1].DonationImportStatus__c);
        system.assertEquals(listDI[0].PaymentImported__c, pmt0.Id); 
        system.assertEquals(listDI[1].PaymentImported__c, pmt1.Id);
        system.assertEquals(label.bdiMatchedId, listDI[0].PaymentImportStatus__c);
        system.assertEquals(label.bdiMatchedId, listDI[1].PaymentImportStatus__c);        
    }

    /*********************************************************************************************************
    * @description operation
    *        import existing contacts with existing open Opportunities, and duplicate Donations  
    * verify: 
    *       opportunity objects matched & closed
    *       duplicate Donation doesn't match to same Opp, but creates a new Opp
    *       payment objects updated
    */
    static testMethod void TwoDIWithExistingDonationsOneDupe() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'TwoDIWithExistingDonationsOneDupe') return;
        
        createTestData();
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c=listConT[0].Firstname, Contact1_Lastname__c=listConT[0].Lastname, 
            Contact1_Work_Email__c=listConT[0].npe01__WorkEmail__c));
        listDI.add(new DataImport__c(Contact1_Firstname__c=listConT[1].Firstname, Contact1_Lastname__c=listConT[1].Lastname, 
            Contact1_Work_Email__c=listConT[1].npe01__WorkEmail__c));
        listDI.add(new DataImport__c(Contact1_Firstname__c=listConT[1].Firstname, Contact1_Lastname__c=listConT[1].Lastname, 
            Contact1_Work_Email__c=listConT[1].npe01__WorkEmail__c));

        listDI[0].Donation_Amount__c = listOppT[0].Amount;
        listDI[0].Donation_Date__c = listOppT[0].CloseDate;
        listDI[0].Payment_Check_Reference_Number__c = 'abc';
        listDI[0].Payment_Method__c = 'Check';

        listDI[1].Donation_Amount__c = listOppT[1].Amount;
        listDI[1].Donation_Date__c = listOppT[1].CloseDate;
        listDI[1].Payment_Check_Reference_Number__c = '1234';
        listDI[1].Payment_Method__c = 'Visa';       

        listDI[2].Donation_Amount__c = listOppT[1].Amount;
        listDI[2].Donation_Date__c = listOppT[1].CloseDate;
        listDI[2].Payment_Check_Reference_Number__c = '5678';
        listDI[2].Payment_Method__c = 'Mastercard';       
        insert listDI;
          
        // set the specified settings
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Donation_Matching_Rule__c = UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c');
        diSettings.Donation_Matching_Behavior__c = BDI_DataImport_API.ExactMatchOrCreate;
        diSettings.Run_Opportunity_Rollups_while_Processing__c = true;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Contact> listCon = [select Id, Name, AccountId, npo02__TotalOppAmount__c from Contact order by Id];
        system.assertEquals(2, listCon.size());
        system.assertEquals(listOppT[0].Amount, listCon[0].npo02__TotalOppAmount__c);
        system.assertEquals(listOppT[1].Amount * 2, listCon[1].npo02__TotalOppAmount__c);
        
        list<Account> listAcc = [select Id, Name, npo02__TotalOppAmount__c from Account order by npe01__One2OneContact__r.Id];
        system.assertEquals(2, listAcc.size());
        system.assertEquals(listOppT[0].Amount, listAcc[0].npo02__TotalOppAmount__c);
        system.assertEquals(listOppT[1].Amount * 2, listAcc[1].npo02__TotalOppAmount__c);
        
        list<Opportunity> listOpp = [select Id, Name, Amount, StageName, isWon, isClosed, AccountId from Opportunity order by Id];
        system.assertEquals(3, listOpp.size());
        system.assertEquals(true, listOpp[0].isWon);
        system.assertEquals(true, listOpp[1].isWon);
        system.assertEquals(true, listOpp[2].isWon);
        
        list<npe01__OppPayment__c> listPmt = [select Id, npe01__Payment_Amount__c, npe01__Payment_Method__c, npe01__Check_Reference_Number__c from npe01__OppPayment__c order by npe01__Opportunity__r.Id];
        system.assertEquals(3, listPmt.size());
        system.assertEquals('Check', listPmt[0].npe01__Payment_Method__c);
        system.assertEquals('abc', listPmt[0].npe01__Check_Reference_Number__c);
        system.assertEquals('Visa', listPmt[1].npe01__Payment_Method__c);
        system.assertEquals('1234', listPmt[1].npe01__Check_Reference_Number__c);
        system.assertEquals('Mastercard', listPmt[2].npe01__Payment_Method__c);
        system.assertEquals('5678', listPmt[2].npe01__Check_Reference_Number__c);

        listDI = [select Id, DonationImported__c, DonationImportStatus__c from DataImport__c order by Id];
        system.assertEquals(3, listDI.size());
        system.assertEquals(listDI[0].DonationImported__c, listOpp[0].Id); 
        system.assertEquals(listDI[1].DonationImported__c, listOpp[1].Id);
        system.assertEquals(listDI[2].DonationImported__c, listOpp[2].Id);
        system.assertEquals(label.bdiMatched, listDI[0].DonationImportStatus__c);
        system.assertEquals(label.bdiMatched, listDI[1].DonationImportStatus__c);        
        system.assertEquals(label.bdiCreated, listDI[2].DonationImportStatus__c);        
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Date, Amount, PaymentId to paid Pmt, Opp Closed
    *    requireExactMatch
    * verify: 
    *    no new donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static testMethod void matchPaymentIdToPaidClosedOppRequireExactMatch() {
        if (strTestOnly != '*' && strTestOnly != 'matchPaymentIdToPaidClosedOppRequireExactMatch') return;
        matchDonationIdToPaidClosedOppWithBehavior(BDI_DataImport_API.RequireExactMatch, 
            label.bdiErrorDonationLookupMatch, true);
    }
    
    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Date, Amount, PaymentId to paid Pmt, Opp Closed
    *    requireNoMatch
    * verify: 
    *    no new donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static testMethod void matchPaymentIdToPaidClosedOppRequireNoMatch() {
        if (strTestOnly != '*' && strTestOnly != 'matchPaymentIdToPaidClosedOppRequireNoMatch') return;
        matchDonationIdToPaidClosedOppWithBehavior(BDI_DataImport_API.RequireNoMatch, 
            label.bdiErrorDonationLookupMatch, true);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Date, Amount, PaymentId to paid Pmt, Opp Closed
    *    DoNotMatch
    * verify: 
    *    no new donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static testMethod void matchPaymentIdToPaidClosedOppDoNotMatch() {
        if (strTestOnly != '*' && strTestOnly != 'matchPaymentIdToPaidClosedOppDoNotMatch') return;
        matchDonationIdToPaidClosedOppWithBehavior(BDI_DataImport_API.DoNotMatch, null, true);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Date, Amount, PaymentId to paid Pmt, Opp Closed
    *    BestMatchOrCreate
    * verify: 
    *    no new donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static testMethod void matchPaymentIdToPaidClosedOppBestMatchOrCreate() {
        if (strTestOnly != '*' && strTestOnly != 'matchPaymentIdToPaidClosedOppBestMatchOrCreate') return;
        matchDonationIdToPaidClosedOppWithBehavior(BDI_DataImport_API.BestMatchOrCreate, 
            label.bdiErrorDonationLookupMatch, true);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Date, Amount, PaymentId to paid Pmt, Opp Closed
    *    ExactMatchOrCreate
    * verify: 
    *    no new donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static testMethod void matchPaymentIdToPaidClosedOppExactMatchOrCreate() {
        if (strTestOnly != '*' && strTestOnly != 'matchPaymentIdToPaidClosedOppExactMatchOrCreate') return;
        matchDonationIdToPaidClosedOppWithBehavior(BDI_DataImport_API.ExactMatchOrCreate, 
            label.bdiErrorDonationLookupMatch, true);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Date, Amount, PaymentId to paid Pmt, Opp Closed
    *    RequireBestMatch
    * verify: 
    *    no new donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static testMethod void matchPaymentIdToPaidClosedOppRequireBestMatch() {
        if (strTestOnly != '*' && strTestOnly != 'matchPaymentIdToPaidClosedOppRequireBestMatch') return;
        matchDonationIdToPaidClosedOppWithBehavior(BDI_DataImport_API.RequireBestMatch, 
            label.bdiErrorDonationLookupMatch, true);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Date, Amount, Id to paid donation, Opp Closed
    *    requireExactMatch
    * verify: 
    *    no new donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static testMethod void matchDonationIdToPaidClosedOppRequireExactMatch() {
        if (strTestOnly != '*' && strTestOnly != 'matchDonationIdToPaidClosedOppRequireExactMatch') return;
        matchDonationIdToPaidClosedOppWithBehavior(BDI_DataImport_API.RequireExactMatch, 
            label.bdiErrorDonationLookupMatch, false);
    }
    
    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Date, Amount, Id to paid donation, Opp Closed
    *    requireNoMatch
    * verify: 
    *    no new donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static testMethod void matchDonationIdToPaidClosedOppRequireNoMatch() {
        if (strTestOnly != '*' && strTestOnly != 'matchDonationIdToPaidClosedOppRequireNoMatch') return;
        matchDonationIdToPaidClosedOppWithBehavior(BDI_DataImport_API.RequireNoMatch, 
            label.bdiErrorDonationLookupMatch, false);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Date, Amount, Id to paid donation, Opp Closed
    *    DoNotMatch
    * verify: 
    *    no new donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static testMethod void matchDonationIdToPaidClosedOppDoNotMatch() {
        if (strTestOnly != '*' && strTestOnly != 'matchDonationIdToPaidClosedOppDoNotMatch') return;
        matchDonationIdToPaidClosedOppWithBehavior(BDI_DataImport_API.DoNotMatch, null, false);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Date, Amount, Id to paid donation, Opp Closed
    *    BestMatchOrCreate
    * verify: 
    *    no new donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static testMethod void matchDonationIdToPaidClosedOppBestMatchOrCreate() {
        if (strTestOnly != '*' && strTestOnly != 'matchDonationIdToPaidClosedOppBestMatchOrCreate') return;
        matchDonationIdToPaidClosedOppWithBehavior(BDI_DataImport_API.BestMatchOrCreate, 
            label.bdiErrorDonationLookupMatch, false);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Date, Amount, Id to paid donation, Opp Closed
    *    ExactMatchOrCreate
    * verify: 
    *    no new donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static testMethod void matchDonationIdToPaidClosedOppExactMatchOrCreate() {
        if (strTestOnly != '*' && strTestOnly != 'matchDonationIdToPaidClosedOppExactMatchOrCreate') return;
        matchDonationIdToPaidClosedOppWithBehavior(BDI_DataImport_API.ExactMatchOrCreate, 
            label.bdiErrorDonationLookupMatch, false);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Date, Amount, Id to paid donation, Opp Closed
    *    RequireBestMatch
    * verify: 
    *    no new donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static testMethod void matchDonationIdToPaidClosedOppRequireBestMatch() {
        if (strTestOnly != '*' && strTestOnly != 'matchDonationIdToPaidClosedOppRequireBestMatch') return;
        matchDonationIdToPaidClosedOppWithBehavior(BDI_DataImport_API.RequireBestMatch, 
            label.bdiErrorDonationLookupMatch, false);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Date, Amount, Id to paid donation, Opp Closed
    * @param behavior The matching behavior to use
    * @param expectedStatus the status value expected on PaymentImportStatus and DonationImportStatus
    * @param fillPaymentId whether to specify the OppId or PaymentId on the DI record
    * verify: 
    *    no new donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static void matchDonationIdToPaidClosedOppWithBehavior(String matchBehavior, 
        string expectedStatus, boolean fillPaymentId) {    

        createTestData();

        // Opp will have one Payment records, but it will be paid, opp will be closed
        Opportunity opp = new Opportunity(name='MyClosedOpp', Primary_Contact__c=listConT[0].Id, Amount=100, CloseDate=System.Today(), 
            StageName=UTIL_unitTestData_TEST.getClosedWonStage(), npe01__Do_Not_Automatically_Create_Payment__c=false);
        insert opp;
        npe01__OppPayment__c pmt = [select Id, npe01__Opportunity__c, npe01__Paid__c from npe01__OppPayment__c 
            where npe01__Opportunity__c = :opp.Id];
        system.assertEquals(true, pmt.npe01__Paid__c);

        DataImport__c di = new DataImport__c(Contact1_Firstname__c=listConT[0].Firstname, Contact1_Lastname__c=listConT[0].Lastname, 
            Contact1_Personal_Email__c=listConT[0].Email,
            Donation_Amount__c=100,
            Donation_Date__c=System.Today(),
            Donation_Donor__c='contact1',
            Payment_Method__c = 'Check'
            );
        if (fillPaymentId) {
            di.PaymentImported__c = pmt.Id;
        } else {
            di.DonationImported__c = opp.Id;
        }
        insert di;
            
        // set the specified settings
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Donation_Matching_Rule__c = UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c');
        diSettings.Donation_Matching_Behavior__c = matchBehavior;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify results
        list<DataImport__c> listDI = [select Status__c, DonationImported__c, DonationImportStatus__c, 
            Donation_Possible_Matches__c, PaymentImported__c, PaymentImportStatus__c from DataImport__c];        
        system.assertEquals(1, listDI.size());
        system.assertEquals(expectedStatus, listDI[0].DonationImportStatus__c);
        if (fillPaymentId) {
            system.assertEquals(expectedStatus, listDI[0].PaymentImportStatus__c);
            system.assertEquals(null, listDI[0].Donation_Possible_Matches__c);
            system.assertNotEquals(null, listDI[0].PaymentImported__c);
            system.assertEquals(null, listDI[0].DonationImported__c);        
        } else {
            system.assertEquals(null, listDI[0].PaymentImportStatus__c);
            system.assertEquals(null, listDI[0].Donation_Possible_Matches__c);
            system.assertEquals(null, listDI[0].PaymentImported__c);
            system.assertNotEquals(null, listDI[0].DonationImported__c);        
        }
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  avoid same amount, different day.
    * verify: 
    *    correct donations matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules1() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules1') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=100,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            0, BDI_DataImport_API.ExactMatchOrCreate, label.bdiMatched, label.bdiMatched, false, 0);
    }

    /*********************************************************************************************************
    * @description operation:
    *    import donations using different matching rules: Amount, Date.  avoid same amount, different day.
    *    use date range for the match.
    * verify:
    *    correct donations matched
    **********************************************************************************************************/
    static testMethod void donationMatchRules1b() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules1b') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=100,
            Donation_Date__c=System.Today()+1,
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');

        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
                UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            0, BDI_DataImport_API.ExactMatchOrCreate, label.bdiMatched, label.bdiMatched, false, 1);
    }

    /*********************************************************************************************************
    * @description operation:
    *    import donations using different matching rules: Amount, Date.  avoid same amount, different day.
    *    use date range for the match.
    * verify:
    *    error, due to multiple matches
    **********************************************************************************************************/
    static testMethod void donationMatchRules1c() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules1c') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=100,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');

        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
                UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.RequireExactMatch, label.bdiErrorPaymentMultiMatch, label.bdiErrorPaymentMultiMatch, true, 1);
    }

    /*********************************************************************************************************
    * @description operation:
    *    import donations using different matching rules: Amount, Date.  avoid same amount, different day.
    *    use date range for the match.
    * verify:
    *    correct donations matched
    **********************************************************************************************************/
    static testMethod void donationMatchRules1d() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules1d') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=100,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');

        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
                UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            0, BDI_DataImport_API.RequireBestMatch, label.bdiMatchedBest, label.bdiMatchedBest, true, 1);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  avoid different amount, same day.  
    * verify: 
    *    correct donations matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules2() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules2') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=300,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            4, BDI_DataImport_API.ExactMatchOrCreate, label.bdiMatched, label.bdiMatched, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date, RecordType 
    * verify: 
    *    correct donations matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules3() {
        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules3') return;
        
        string strRTName = UTIL_RecordTypes.getRecordTypeNameForMembershipTests(Opportunity.sObjectType);

        // if membership is the default recordtype, we can't assume we'll match the intended opp, so we can't test.
        if (UTIL_RecordTypes.isRecordTypeDefault(Opportunity.sObjectType, strRTName))
            return;
        
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=200,
            Donation_Date__c=System.Today(),
            Donation_Record_Type_Name__c=strRTName,
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Record_Type_Name__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            3, BDI_DataImport_API.ExactMatchOrCreate, label.bdiMatched, label.bdiMatched, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  Ambiguous match detected.
    * verify: 
    *    no donations matched
    *    ambiguous match error logged
    **********************************************************************************************************/            
    static testMethod void donationMatchRules4() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules4') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=200,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.ExactMatchOrCreate, label.bdiErrorDonationMultiMatch, label.bdiErrorDonationMultiMatch, true, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  ExactMatchOrCreate, no match found
    * verify: 
    *    no donations matched
    *    new donation created
    **********************************************************************************************************/            
    static testMethod void donationMatchRules4b() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules4b') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=99,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.ExactMatchOrCreate, label.bdiCreated, label.bdiCreated, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  BestMatchOrCreate. matches exist
    * verify: 
    *    best donation matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules5() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules5') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=200,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -2, BDI_DataImport_API.BestMatchOrCreate, label.bdiMatchedBest, label.bdiMatchedBest, true, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  BestMatchOrCreate, no match
    * verify: 
    *    no donation matched
    *    new donation created
    **********************************************************************************************************/            
    static testMethod void donationMatchRules5b() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules5b') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=99,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.BestMatchOrCreate, label.bdiCreated, label.bdiCreated, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  Specify No Match
    * verify: 
    *    new donation created (even though matches existing Opp)
    **********************************************************************************************************/            
    static testMethod void donationMatchRules6() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules6') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=100,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.DoNotMatch, label.bdiCreated, label.bdiCreated, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  Specify RequireNoMatch, but match exists
    * verify: 
    *    no donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static testMethod void donationMatchRules7() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules7') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=200,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.RequireNoMatch, label.bdiErrorDonationRequireNoMatch, label.bdiErrorDonationRequireNoMatch, true, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  Specify RequireNoMatch, no match exists
    * verify: 
    *    new donation created
    **********************************************************************************************************/            
    static testMethod void donationMatchRules7b() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules7b') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=99,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.RequireNoMatch, label.bdiCreated, label.bdiCreated, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  Specify RequireExactMatch, but none exists
    * verify: 
    *    no new donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static testMethod void donationMatchRules8() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules8') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=99,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.RequireExactMatch, label.bdiErrorDonationNoMatch, label.bdiErrorDonationNoMatch, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  Specify RequireExactMatch, but multi exists
    * verify: 
    *    no new donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static testMethod void donationMatchRules9() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules9') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=200,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.RequireExactMatch, label.bdiErrorPaymentMultiMatch, label.bdiErrorPaymentMultiMatch, true, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  Specify RequireExactMatch, exact exists
    * verify: 
    *    no new donation created
    *    record matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules9b() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules9b') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=100,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.RequireExactMatch, label.bdiMatched, label.bdiMatched, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  Specify RequireBestMatch, multi exists
    * verify: 
    *    no new donation created
    *    best opp matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules10() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules10') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=200,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            2, BDI_DataImport_API.RequireBestMatch, label.bdiMatchedBest, label.bdiMatchedBest, true, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  Specify RequireBestMatch, no match exists
    * verify: 
    *    no new donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static testMethod void donationMatchRules10b() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules10b') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=99,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.RequireBestMatch, label.bdiErrorDonationNoMatch, label.bdiErrorDonationNoMatch, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Opportunity Unique Id (string), opp exists
    * verify: 
    *    no new donation created
    *    existing opp matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules11() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules11') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=99,
            Donation_Date__c=System.Today(),
            Donation_Donor__c='contact1',
            Payment_Method__c = 'Check',
            Donation_Type__c='MyUniqueID');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Type__c'),
            2, BDI_DataImport_API.RequireExactMatch, label.bdiMatched, label.bdiMatched, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Opportunity Unique Id (number), opp exists
    * verify: 
    *    no new donation created
    *    existing opp matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules11b() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules11b') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=300,
            Donation_Date__c=System.Today().addDays(-100),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c'),
            4, BDI_DataImport_API.RequireExactMatch, label.bdiMatched, label.bdiMatched, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date, where Opp has NO Payments.
    * verify: 
    *    no new donation created
    *    existing opp matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules12() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules12') return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=700,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            7, BDI_DataImport_API.RequireExactMatch, label.bdiMatched, label.bdiMatched, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date, where Opp has Multiple Payments.
    * verify: 
    *    no new donation created
    *    existing opp matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules13() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules13') return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=550,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            9, BDI_DataImport_API.RequireExactMatch, label.bdiMatched, label.bdiMatched, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: check#, where Opp has Multiple Payments.
    * verify: 
    *    no new donation created
    *    existing opp matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules14() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules14') return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=25,
            Donation_Date__c=System.Today(),
            Donation_Donor__c='contact1',
            Payment_Method__c = 'Check',
            Payment_Check_Reference_Number__c='pick me'
            );
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Payment_Check_Reference_Number__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            9, BDI_DataImport_API.RequireExactMatch, label.bdiMatched, label.bdiMatched, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: check#, amount, date, 
    *    where no payment match found, but opp found.
    * verify: 
    *    no new donation created
    *    no opp matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules14b() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules14b') return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=300,
            Donation_Date__c=System.Today(),
            Donation_Donor__c='contact1',
            Payment_Method__c = 'Check',
            Payment_Check_Reference_Number__c='pick me'
            );
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Payment_Check_Reference_Number__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' + 
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.RequireExactMatch, label.bdiErrorDonationNoMatch, label.bdiErrorDonationNoMatch, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date, where Opp has Multiple Payments,
    *    and matches one of the payments under the opp
    * verify: 
    *    no new donation created
    *    existing opp matched, but left open
    *    payment matched
    *    opp remaining balance updated
    **********************************************************************************************************/            
    static testMethod void donationMatchRules14c() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules14c') return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=350,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            8, BDI_DataImport_API.RequireExactMatch, label.bdiMatched, label.bdiMatched, false, 0);
            
        DataImport__c di = [select Status__c, DonationImported__c, DonationImportStatus__c, 
            Donation_Possible_Matches__c, PaymentImported__c, PaymentImportStatus__c from DataImport__c];
        system.assertEquals(label.bdiMatched, di.DonationImportStatus__c);       
        system.assertEquals(label.bdiMatched, di.PaymentImportStatus__c);
        
        Opportunity opp = getOpportunityWithPayments(di.DonationImported__c);
        npe01__OppPayment__c pmt = [select Id, npe01__Payment_Amount__c, npe01__Paid__c from npe01__OppPayment__c where id = :di.PaymentImported__c];
        
        system.assertEquals(false, opp.IsWon);
        system.assertEquals(false, opp.IsClosed);
        system.assertEquals(600, opp.Amount);
        system.assertEquals(250, PMT_PaymentCreator.getAmountOutstanding(opp));
        system.assertEquals(350, pmt.npe01__Payment_Amount__c);
        system.assertEquals(true, pmt.npe01__Paid__c);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: check#, donation date, where Opp has Multiple Payments, 
    *    multi opps match, RequireExactMatch
    * verify: 
    *    no new donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static testMethod void donationMatchRules15() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules15') return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=25,
            Donation_Date__c=System.Today(),
            Donation_Donor__c='contact1',
            Payment_Method__c = 'Check',
            Payment_Check_Reference_Number__c='dupe'
            );
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Payment_Check_Reference_Number__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.RequireExactMatch, label.bdiErrorPaymentMultiMatch, label.bdiErrorPaymentMultiMatch, true, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Date, Amount, remaining payment matches 
    * verify: 
    *    no new donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static testMethod void donationMatchRules16() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;
        
        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules16') return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=125,
            Donation_Date__c=System.Today(),
            Donation_Donor__c='contact1',
            Payment_Method__c = 'Check'
            );
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            10, BDI_DataImport_API.RequireExactMatch, label.bdiMatched, label.bdiMatched, false, 0);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Date, Amount, matching opps payment was written off
    *    but opp left open. 
    * verify: 
    *    no new donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static testMethod void donationMatchRules17() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules17') return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=1100,
            Donation_Date__c=System.Today(),
            Donation_Donor__c='contact1',
            Payment_Method__c = 'Check'
            );
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            11, BDI_DataImport_API.RequireExactMatch, label.bdiMatched, label.bdiMatched, false, 0);
    }

    /*********************************************************************************************************
    * @description operation:
    *    import donations using different matching rules: Amount, Date, where Opp has Multiple Payments,
    *    and matches one of the payments under the opp
    * verify:
    *    no new donation created
    *    existing opp matched, but left open
    *    payment matched
    *    opp remaining balance updated
    **********************************************************************************************************/
    static testMethod void donationMatchRules18a() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules18a') return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=12,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');

        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
                UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            12, BDI_DataImport_API.RequireExactMatch, label.bdiMatched, label.bdiMatched, false, 0);

        DataImport__c di = [select Status__c, DonationImported__c, DonationImportStatus__c,
            Donation_Possible_Matches__c, PaymentImported__c, PaymentImportStatus__c from DataImport__c];
        system.assertEquals(label.bdiMatched, di.DonationImportStatus__c);
        system.assertEquals(label.bdiMatched, di.PaymentImportStatus__c);

        Opportunity opp = getOpportunityWithPayments(di.DonationImported__c);
        npe01__OppPayment__c pmt = [select Id, npe01__Payment_Amount__c, npe01__Paid__c from npe01__OppPayment__c where id = :di.PaymentImported__c];

        system.assertEquals(false, opp.IsWon);
        system.assertEquals(false, opp.IsClosed);
        system.assertEquals(48, opp.Amount);
        system.assertEquals(36, PMT_PaymentCreator.getAmountOutstanding(opp));
        system.assertEquals(12, pmt.npe01__Payment_Amount__c);
        system.assertEquals(true, pmt.npe01__Paid__c);
    }

    /*********************************************************************************************************
    * @description operation:
    *    import donations using different matching rules: Amount, Date, where Opp has Multiple Payments,
    *    and matches multiple of the payments under the opp, using a date range
    * verify:
    *    no new donation created
    *    existing opp matched, but left open
    *    payment matched
    *    opp remaining balance updated
    **********************************************************************************************************/
    static testMethod void donationMatchRules18b() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules18a') return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=12,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');

        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
                UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            12, BDI_DataImport_API.RequireBestMatch, label.bdiMatched, label.bdiMatchedBest, true, 1);

        DataImport__c di = [select Status__c, DonationImported__c, DonationImportStatus__c,
            Donation_Possible_Matches__c, PaymentImported__c, PaymentImportStatus__c from DataImport__c];
        system.assertEquals(label.bdiMatched, di.DonationImportStatus__c);
        system.assertEquals(label.bdiMatchedBest, di.PaymentImportStatus__c);

        Opportunity opp = getOpportunityWithPayments(di.DonationImported__c);
        npe01__OppPayment__c pmt = [select Id, npe01__Payment_Amount__c, npe01__Paid__c, npe01__Scheduled_Date__c from npe01__OppPayment__c where id = :di.PaymentImported__c];

        system.assertEquals(false, opp.IsWon);
        system.assertEquals(false, opp.IsClosed);
        system.assertEquals(48, opp.Amount);
        system.assertEquals(36, PMT_PaymentCreator.getAmountOutstanding(opp));
        system.assertEquals(12, pmt.npe01__Payment_Amount__c);
        system.assertEquals(true, pmt.npe01__Paid__c);
        system.assertEquals(system.Today(), pmt.npe01__Scheduled_Date__c);
    }

    /*********************************************************************************************************
    * @description operation:
    *    import donations using different matching rules: Amount, Date, where Opp has Multiple Payments,
    *    and matches multiple of the payments under the opp, using a date range
    * verify:
    *    no new donation created
    *    existing opp matched, but left open
    *    payment matched
    *    opp remaining balance updated
    **********************************************************************************************************/
    static testMethod void donationMatchRules18c() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules18c') return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=12,
            Donation_Date__c=System.Today()+1,
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');

        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
                UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            12, BDI_DataImport_API.RequireBestMatch, label.bdiMatched, label.bdiMatchedBest, true, 2);

        DataImport__c di = [select Status__c, DonationImported__c, DonationImportStatus__c,
            Donation_Possible_Matches__c, PaymentImported__c, PaymentImportStatus__c from DataImport__c];
        system.assertEquals(label.bdiMatched, di.DonationImportStatus__c);
        system.assertEquals(label.bdiMatchedBest, di.PaymentImportStatus__c);

        Opportunity opp = getOpportunityWithPayments(di.DonationImported__c);
        npe01__OppPayment__c pmt = [select Id, npe01__Payment_Amount__c, npe01__Paid__c, npe01__Scheduled_Date__c from npe01__OppPayment__c where id = :di.PaymentImported__c];

        system.assertEquals(false, opp.IsWon);
        system.assertEquals(false, opp.IsClosed);
        system.assertEquals(48, opp.Amount);
        system.assertEquals(36, PMT_PaymentCreator.getAmountOutstanding(opp));
        system.assertEquals(12, pmt.npe01__Payment_Amount__c);
        system.assertEquals(true, pmt.npe01__Paid__c);
        system.assertEquals(system.Today()+1, pmt.npe01__Scheduled_Date__c);
    }

    /*********************************************************************************************************
    * @description operation:
    *    import donations using different matching rules: Amount, Date, where Opp has Multiple Payments,
    *    and matches multiple of the payments under the opp, using a date range
    * verify:
    *    error, due to detection of multiple payments
    **********************************************************************************************************/
    static testMethod void donationMatchRules18d() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules18d') return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=12,
            Donation_Date__c=System.Today()+1,
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');

        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
                UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.RequireExactMatch, label.bdiErrorPaymentMultiMatch, label.bdiErrorPaymentMultiMatch, true, 2);
    }

    /*********************************************************************************************************
    * @description operation:
    *    import donations using different matching rules: Amount, Date, where Opp has a payment that has
    *    a different date and amount
    * verify:
    *    no new donation created
    *    existing opp matched, and closed
    *    payment matched and marked paid and updated to match opp
    **********************************************************************************************************/
    static testMethod void donationMatchRules19() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules19') return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=15,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');

        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
                UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            15, BDI_DataImport_API.RequireBestMatch, label.bdiMatched, label.bdiMatched, false, 0);

        DataImport__c di = [select Status__c, DonationImported__c, DonationImportStatus__c,
            Donation_Possible_Matches__c, PaymentImported__c, PaymentImportStatus__c from DataImport__c];
        system.assertEquals(label.bdiMatched, di.DonationImportStatus__c);
        system.assertEquals(label.bdiMatched, di.PaymentImportStatus__c);

        Opportunity opp = getOpportunityWithPayments(di.DonationImported__c);
        npe01__OppPayment__c pmt = [select Id, npe01__Payment_Amount__c, npe01__Paid__c, npe01__Scheduled_Date__c, npe01__Payment_Date__c from npe01__OppPayment__c where id = :di.PaymentImported__c];

        system.assertEquals(true, opp.IsWon);
        system.assertEquals(true, opp.IsClosed);
        system.assertEquals(15, opp.Amount);
        system.assertEquals(0, PMT_PaymentCreator.getAmountOutstanding(opp));
        system.assertEquals(15, pmt.npe01__Payment_Amount__c);
        system.assertEquals(true, pmt.npe01__Paid__c);
        system.assertEquals(system.Today(), pmt.npe01__Payment_Date__c);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    the shared routine to actually test the different donations different matching rules. 
    * verify: 
    *    correct donations matched
    *
    * @param strRule The matching rules to use in the test
    * @param imatch The existing Opp we expect to match against.  use -1 if no match expected.  use -2 if best match expected (which can be random)
    * @param expectedStatus The status value we expect to be set in DonationImportStatus__c
    * @param expectedStatusPmt The status value we expect to be set in PaymentImportStatus__c
    * @param hasMultiMatches Whether we expect anything in Donation_Possible_Matches__c
    **********************************************************************************************************/            
    static void donationMatchRules(string strRule, integer imatch, string matchBehavior, 
        string expectedStatus, string expectedStatusPmt, boolean hasMultiMatches, integer dateRange) {
        
        // create opps to match against
        Contact con = new Contact(firstname='c0', lastname='c0', email='c0@c0.com');
        insert con;
        UTIL_UnitTestData_TEST.setFixedSearchResults(new List<Contact>{ con });
        list<Opportunity> listOpp = new list<Opportunity>();
        
        // Opps 0-5 will get their default single Payment record
        listOpp.add(new Opportunity(name='Opp0', Primary_Contact__c=con.Id, Amount=100, CloseDate=System.Today(), 
            StageName=UTIL_unitTestData_TEST.getOpenStage()));
        listOpp.add(new Opportunity(name='Opp1', Primary_Contact__c=con.Id, Amount=100, CloseDate=System.Today().addDays(-1), 
            StageName=UTIL_unitTestData_TEST.getOpenStage()));
        listOpp.add(new Opportunity(name='Opp2', Primary_Contact__c=con.Id, Amount=200, CloseDate=System.Today(), 
            StageName=UTIL_unitTestData_TEST.getOpenStage(), Type='MyUniqueID'));
        listOpp.add(new Opportunity(name='Opp3', Primary_Contact__c=con.Id, Amount=200, CloseDate=System.Today(), 
            StageName=UTIL_unitTestData_TEST.getOpenStage(), 
            RecordTypeId=UTIL_RecordTypes.getRecordTypeIdForMembershipTests(Opportunity.sObjectType)));
        listOpp.add(new Opportunity(name='Opp4', Primary_Contact__c=con.Id, Amount=300, CloseDate=System.Today(), 
            StageName=UTIL_unitTestData_TEST.getOpenStage()));
        listOpp.add(new Opportunity(name='Opp5', Primary_Contact__c=con.Id, Amount=500, CloseDate=System.Today(), 
            StageName=UTIL_unitTestData_TEST.getOpenStage(), npe01__Do_Not_Automatically_Create_Payment__c=true));
        
        // Opps 6-7 will have no Payment records
        listOpp.add(new Opportunity(name='Opp6', Primary_Contact__c=con.Id, Amount=600, CloseDate=System.Today(), 
            StageName=UTIL_unitTestData_TEST.getOpenStage(), npe01__Do_Not_Automatically_Create_Payment__c=true));
        listOpp.add(new Opportunity(name='Opp7', Primary_Contact__c=con.Id, Amount=700, CloseDate=System.Today(), 
            StageName=UTIL_unitTestData_TEST.getOpenStage(), npe01__Do_Not_Automatically_Create_Payment__c=true));

        // Opps 8-9 will have multiple Payment records
        listOpp.add(new Opportunity(name='Opp8', Primary_Contact__c=con.Id, Amount=600, CloseDate=System.Today(), 
            StageName=UTIL_unitTestData_TEST.getOpenStage(), npe01__Do_Not_Automatically_Create_Payment__c=true));
        listOpp.add(new Opportunity(name='Opp9', Primary_Contact__c=con.Id, Amount=700, CloseDate=System.Today(), 
            StageName=UTIL_unitTestData_TEST.getOpenStage(), npe01__Do_Not_Automatically_Create_Payment__c=true));
            
        // Opp 10 will have multiple Payment records, but only one open
        listOpp.add(new Opportunity(name='Opp10', Primary_Contact__c=con.Id, Amount=600, CloseDate=System.Today(), 
            StageName=UTIL_unitTestData_TEST.getOpenStage(), npe01__Do_Not_Automatically_Create_Payment__c=true));

        // Opp 11 will have one Payment records, but it will be written off, but opp left open.
        listOpp.add(new Opportunity(name='Opp11', Primary_Contact__c=con.Id, Amount=1100, CloseDate=System.Today(), 
            StageName=UTIL_unitTestData_TEST.getOpenStage(), npe01__Do_Not_Automatically_Create_Payment__c=true));

        // Opp 12 will have multiple Payment records, different days, same amounts.
        listOpp.add(new Opportunity(name='Opp12', Primary_Contact__c=con.Id, Amount=48, CloseDate=System.Today(),
            StageName=UTIL_unitTestData_TEST.getOpenStage(), npe01__Do_Not_Automatically_Create_Payment__c=true));

        // Opp 13 will have a payment with no scheduled date!
        listOpp.add(new Opportunity(name='Opp13', Primary_Contact__c=con.Id, Amount=1330, CloseDate=System.Today(),
            StageName=UTIL_unitTestData_TEST.getOpenStage(), npe01__Do_Not_Automatically_Create_Payment__c=true));

        // Opp 14 will have no Amount, nor payment!
        listOpp.add(new Opportunity(name='Opp14', Primary_Contact__c=con.Id, Amount=null, CloseDate=System.Today(),
            StageName=UTIL_unitTestData_TEST.getOpenStage(), npe01__Do_Not_Automatically_Create_Payment__c=true));

        // Opp 15 will have a payment that doesn't agree on date
        listOpp.add(new Opportunity(name='Opp15', Primary_Contact__c=con.Id, Amount=15, CloseDate=System.Today(),
            StageName=UTIL_unitTestData_TEST.getOpenStage(), npe01__Do_Not_Automatically_Create_Payment__c=true));

        insert listOpp;
        
        // create Opps 8-11's Payment records
        list<npe01__OppPayment__c> listPmt = new list<npe01__OppPayment__c>();
        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOpp[8].Id, npe01__Payment_Amount__c=350, 
            npe01__Scheduled_Date__c=System.Today(), npe01__Check_Reference_Number__c='dupe'));
        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOpp[8].Id, npe01__Payment_Amount__c=250, 
            npe01__Scheduled_Date__c=System.Today()));

        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOpp[9].Id, npe01__Payment_Amount__c=550, 
            npe01__Scheduled_Date__c=System.Today(), npe01__Check_Reference_Number__c='dupe'));
        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOpp[9].Id, npe01__Payment_Amount__c=150, 
            npe01__Scheduled_Date__c=System.Today(), npe01__Check_Reference_Number__c='pick me'));

        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOpp[10].Id, npe01__Payment_Amount__c=575, 
            npe01__Scheduled_Date__c=System.Today(), npe01__Check_Reference_Number__c='dupe', npe01__Paid__c=true));
        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOpp[10].Id, npe01__Payment_Amount__c=125, 
            npe01__Scheduled_Date__c=System.Today(), npe01__Check_Reference_Number__c='dupe'));

        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOpp[11].Id, npe01__Payment_Amount__c=1100, 
            npe01__Scheduled_Date__c=System.Today(), npe01__Written_Off__c=true));

        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOpp[12].Id, npe01__Payment_Amount__c=12,
            npe01__Scheduled_Date__c=System.Today()));
        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOpp[12].Id, npe01__Payment_Amount__c=12,
            npe01__Scheduled_Date__c=System.Today()+1));
        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOpp[12].Id, npe01__Payment_Amount__c=12,
            npe01__Scheduled_Date__c=System.Today()+2));
        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOpp[12].Id, npe01__Payment_Amount__c=12,
            npe01__Scheduled_Date__c=System.Today()+3));

        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOpp[13].Id, npe01__Payment_Amount__c=12));

        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOpp[15].Id, npe01__Payment_Amount__c=55,
            npe01__Scheduled_Date__c=System.Today()+15));

        insert listPmt;
        
        // set the specified settings
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Donation_Matching_Rule__c = strRule;
        diSettings.Donation_Matching_Behavior__c = matchBehavior;
        diSettings.Donation_Date_Range__c = dateRange;
 
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        list<DataImport__c> listDI = [select Status__c, DonationImported__c, DonationImportStatus__c, 
            Donation_Possible_Matches__c, PaymentImported__c, PaymentImportStatus__c, Payment_Possible_Matches__c from DataImport__c];
        system.assertEquals(1, listDI.size());
        system.assertEquals(expectedStatus, listDI[0].DonationImportStatus__c);
        system.assertEquals(hasMultiMatches, listDI[0].Donation_Possible_Matches__c != null || listDI[0].Payment_Possible_Matches__c != null);
        if (imatch >= 0) {                
            system.assertEquals(BDI_DataImport_API.bdiImported, listDI[0].Status__c);
            system.assertEquals(listOpp[imatch].Id, listDI[0].DonationImported__c);
            if (imatch != 6 && imatch != 7) {
                system.assertNotEquals(null, listDI[0].PaymentImported__c);
                system.assertEquals(expectedStatusPmt, listDI[0].PaymentImportStatus__c);
                npe01__OppPayment__c pmt = [select Id, npe01__Payment_Method__c from npe01__OppPayment__c
                    where Id = :listDI[0].PaymentImported__c];
                system.assertEquals('Check', pmt.npe01__Payment_Method__c);
            }
	        // verify we matched an existing opp (no new opp created)
	        list<Opportunity> listOppX = [select Id, Name, Amount, Primary_Contact__c from Opportunity];
	        system.assertEquals(listOpp.size(), listOppX.size());
        }
    }

    private static Opportunity getOpportunityWithPayments(Id oppId) {
        // requery the Opportunity for all fields that we need.
        return [SELECT Id, IsWon, IsClosed, Amount, npe01__Amount_Outstanding__c,
            (SELECT Id, npe01__Payment_Amount__c, npe01__Written_Off__c, npe01__Paid__c FROM  npe01__OppPayment__r)
            FROM Opportunity WHERE Id = :oppId LIMIT 1];
    }
}