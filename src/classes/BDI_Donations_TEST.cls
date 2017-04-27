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
        diSettings.Donation_Matching_Rule__c = UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ',' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c');
        diSettings.Donation_Matching_Behavior__c = BDI_DataImport_API.ExactMatchOrCreate;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Contact> listCon = [select Id, Name, AccountId, npo02__TotalOppAmount__c from Contact order by Firstname];
        system.assertEquals(2, listCon.size());
        system.assertEquals(listOppT[0].Amount, listCon[0].npo02__TotalOppAmount__c);
        system.assertEquals(listOppT[1].Amount, listCon[1].npo02__TotalOppAmount__c);
        
        list<Account> listAcc = [select Id, Name, npo02__TotalOppAmount__c from Account order by Name];
        system.assertEquals(2, listAcc.size());
        system.assertEquals(listOppT[0].Amount, listAcc[0].npo02__TotalOppAmount__c);
        system.assertEquals(listOppT[1].Amount, listAcc[1].npo02__TotalOppAmount__c);
        
        list<Opportunity> listOpp = [select Id, Name, Amount, StageName, isWon, isClosed, AccountId from Opportunity order by Name];
        system.assertEquals(2, listOpp.size());
        system.assertEquals(true, listOpp[0].isWon);
        system.assertEquals(true, listOpp[1].isWon);
        
        list<npe01__OppPayment__c> listPmt = [select Id, npe01__Payment_Amount__c, npe01__Payment_Method__c, npe01__Check_Reference_Number__c from npe01__OppPayment__c order by npe01__Opportunity__r.Name];
        system.assertEquals(2, listPmt.size());
        system.assertEquals('Check', listPmt[0].npe01__Payment_Method__c);
        system.assertEquals('Visa', listPmt[1].npe01__Payment_Method__c);
        system.assertEquals('abc', listPmt[0].npe01__Check_Reference_Number__c);
        system.assertEquals('1234', listPmt[1].npe01__Check_Reference_Number__c);

        listDI = [select Id, DonationImported__c, DonationImportStatus__c from DataImport__c order by Contact1_Lastname__c];
        system.assertEquals(2, listDI.size());
        system.assertEquals(listDI[0].DonationImported__c, listOpp[0].Id); 
        system.assertEquals(listDI[1].DonationImported__c, listOpp[1].Id);
        system.assertEquals(label.bdiMatched, listDI[0].DonationImportStatus__c);
        system.assertEquals(label.bdiMatched, listDI[1].DonationImportStatus__c);        
    }
    
    /*********************************************************************************************************
    * @description operation
    *        import existing contacts with existiong open Opportunities specified in DonationImported__c  
    * verify: 
    *       opportunity objects matched & closed
    *       payment objects updated
    */
    static testMethod void TwoDIWithExistingDonationsSpecified() {
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
        diSettings.Donation_Matching_Rule__c = UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ',' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c');
        diSettings.Donation_Matching_Behavior__c = BDI_DataImport_API.ExactMatchOrCreate;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Contact> listCon = [select Id, Name, AccountId, npo02__TotalOppAmount__c from Contact order by Firstname];
        system.assertEquals(2, listCon.size());
        system.assertEquals(listOppT[0].Amount, listCon[0].npo02__TotalOppAmount__c);
        system.assertEquals(listOppT[1].Amount, listCon[1].npo02__TotalOppAmount__c);
        
        list<Account> listAcc = [select Id, Name, npo02__TotalOppAmount__c from Account order by Name];
        system.assertEquals(2, listAcc.size());
        system.assertEquals(listOppT[0].Amount, listAcc[0].npo02__TotalOppAmount__c);
        system.assertEquals(listOppT[1].Amount, listAcc[1].npo02__TotalOppAmount__c);
        
        list<Opportunity> listOpp = [select Id, Name, Amount, StageName, isWon, isClosed, AccountId from Opportunity order by Name];
        system.assertEquals(2, listOpp.size());
        system.assertEquals(true, listOpp[0].isWon);
        system.assertEquals(true, listOpp[1].isWon);
        
        list<npe01__OppPayment__c> listPmt = [select Id, npe01__Payment_Amount__c, npe01__Payment_Method__c, npe01__Check_Reference_Number__c from npe01__OppPayment__c order by npe01__Opportunity__r.Name];
        system.assertEquals(2, listPmt.size());
        system.assertEquals('Check', listPmt[0].npe01__Payment_Method__c);
        system.assertEquals('Visa', listPmt[1].npe01__Payment_Method__c);
        system.assertEquals('abc', listPmt[0].npe01__Check_Reference_Number__c);
        system.assertEquals('1234', listPmt[1].npe01__Check_Reference_Number__c);

        listDI = [select Id, DonationImported__c, DonationImportStatus__c from DataImport__c order by Contact1_Lastname__c];
        system.assertEquals(2, listDI.size());
        system.assertEquals(listDI[0].DonationImported__c, listOpp[0].Id); 
        system.assertEquals(listDI[1].DonationImported__c, listOpp[1].Id);
        system.assertEquals(label.bdiMatched, listDI[0].DonationImportStatus__c);
        system.assertEquals(label.bdiMatched, listDI[1].DonationImportStatus__c);        
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
        diSettings.Donation_Matching_Rule__c = UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ',' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c');
        diSettings.Donation_Matching_Behavior__c = BDI_DataImport_API.ExactMatchOrCreate;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Contact> listCon = [select Id, Name, AccountId, npo02__TotalOppAmount__c from Contact order by Firstname];
        system.assertEquals(2, listCon.size());
        system.assertEquals(listOppT[0].Amount, listCon[0].npo02__TotalOppAmount__c);
        system.assertEquals(listOppT[1].Amount * 2, listCon[1].npo02__TotalOppAmount__c);
        
        list<Account> listAcc = [select Id, Name, npo02__TotalOppAmount__c from Account order by npe01__One2OneContact__r.Firstname];
        system.assertEquals(2, listAcc.size());
        system.assertEquals(listOppT[0].Amount, listAcc[0].npo02__TotalOppAmount__c);
        system.assertEquals(listOppT[1].Amount * 2, listAcc[1].npo02__TotalOppAmount__c);
        
        list<Opportunity> listOpp = [select Id, Name, Amount, StageName, isWon, isClosed, AccountId from Opportunity order by Name];
        system.assertEquals(3, listOpp.size());
        system.assertEquals(true, listOpp[0].isWon);
        system.assertEquals(true, listOpp[1].isWon);
        system.assertEquals(true, listOpp[2].isWon);
        
        list<npe01__OppPayment__c> listPmt = [select Id, npe01__Payment_Amount__c, npe01__Payment_Method__c, npe01__Check_Reference_Number__c from npe01__OppPayment__c order by npe01__Opportunity__r.Name];
        system.assertEquals(3, listPmt.size());
        system.assertEquals('Check', listPmt[0].npe01__Payment_Method__c);
        system.assertEquals('abc', listPmt[0].npe01__Check_Reference_Number__c);
        system.assertEquals('Visa', listPmt[1].npe01__Payment_Method__c);
        system.assertEquals('1234', listPmt[1].npe01__Check_Reference_Number__c);
        system.assertEquals('Mastercard', listPmt[2].npe01__Payment_Method__c);
        system.assertEquals('5678', listPmt[2].npe01__Check_Reference_Number__c);

        listDI = [select Id, DonationImported__c, DonationImportStatus__c from DataImport__c order by Contact1_Lastname__c];
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
    *    import donations using different matching rules: Amount, Date.  avoid same amount, different day.
    * verify: 
    *    correct donations matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules1() {
        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules1') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=100,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ',' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            0, BDI_DataImport_API.ExactMatchOrCreate, label.bdiMatched, false);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  avoid different amount, same day.  
    * verify: 
    *    correct donations matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules2() {
        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules2') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=300,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ',' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            4, BDI_DataImport_API.ExactMatchOrCreate, label.bdiMatched, false);
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
        system.debug('****DJH: testing match with recordtype: ' + strRTName);

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
            UTIL_Namespace.StrTokenNSPrefix('Donation_Record_Type_Name__c') + ',' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ',' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            3, BDI_DataImport_API.ExactMatchOrCreate, label.bdiMatched, false);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  Ambiguous match detected.
    * verify: 
    *    no donations matched
    *    ambiguous match error logged
    **********************************************************************************************************/            
    static testMethod void donationMatchRules4() {
        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules4') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=200,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ',' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.ExactMatchOrCreate, label.bdiErrorDonationMultiMatch, true);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  ExactMatchOrCreate, no match found
    * verify: 
    *    no donations matched
    *    new donation created
    **********************************************************************************************************/            
    static testMethod void donationMatchRules4b() {
        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules4b') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=99,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ',' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.ExactMatchOrCreate, label.bdiCreated, false);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  BestMatchOrCreate. matches exist
    * verify: 
    *    best donation matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules5() {
        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules5') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=200,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ',' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -2, BDI_DataImport_API.BestMatchOrCreate, label.bdiMatchedBest, true);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  BestMatchOrCreate, no match
    * verify: 
    *    no donation matched
    *    new donation created
    **********************************************************************************************************/            
    static testMethod void donationMatchRules5b() {
        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules5b') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=99,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ',' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.BestMatchOrCreate, label.bdiCreated, false);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  Specify No Match
    * verify: 
    *    new donation created (even though matches existing Opp)
    **********************************************************************************************************/            
    static testMethod void donationMatchRules6() {
        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules6') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=100,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ',' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.DoNotMatch, label.bdiCreated, false);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  Specify RequireNoMatch, but match exists
    * verify: 
    *    no donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static testMethod void donationMatchRules7() {
        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules7') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=200,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ',' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.RequireNoMatch, label.bdiErrorDonationMultiMatch, true);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  Specify RequireNoMatch, no match exists
    * verify: 
    *    new donation created
    **********************************************************************************************************/            
    static testMethod void donationMatchRules7b() {
        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules7b') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=99,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ',' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.RequireNoMatch, label.bdiCreated, false);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  Specify RequireExactMatch, but none exists
    * verify: 
    *    no new donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static testMethod void donationMatchRules8() {
        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules8') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=99,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ',' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.RequireExactMatch, label.bdiErrorDonationNoMatch, false);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  Specify RequireExactMatch, but multi exists
    * verify: 
    *    no new donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static testMethod void donationMatchRules9() {
        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules9') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=200,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ',' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.RequireExactMatch, label.bdiErrorDonationMultiMatch, true);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  Specify RequireExactMatch, exact exists
    * verify: 
    *    no new donation created
    *    record matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules9b() {
        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules9b') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=100,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ',' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.RequireExactMatch, label.bdiMatched, false);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  Specify RequireBestMatch, multi exists
    * verify: 
    *    no new donation created
    *    best opp matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules10() {
        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules10') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=200,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ',' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            2, BDI_DataImport_API.RequireBestMatch, label.bdiMatchedBest, true);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date.  Specify RequireBestMatch, no match exists
    * verify: 
    *    no new donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static testMethod void donationMatchRules10b() {
        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules10b') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=99,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ',' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.RequireBestMatch, label.bdiErrorDonationNoMatch, false);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Opportunity Unique Id (string), opp exists
    * verify: 
    *    no new donation created
    *    existing opp matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules11() {
        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules11') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=99,
            Donation_Date__c=System.Today(),
            Donation_Donor__c='contact1',
            Payment_Method__c = 'Check',
            Donation_Type__c='MyUniqueID');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Type__c'),
            2, BDI_DataImport_API.RequireExactMatch, label.bdiMatched, false);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Opportunity Unique Id (number), opp exists
    * verify: 
    *    no new donation created
    *    existing opp matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules11b() {
        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules11b') return;
        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=300,
            Donation_Date__c=System.Today().addDays(-100),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c'),
            4, BDI_DataImport_API.RequireExactMatch, label.bdiMatched, false);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date, where Opp has NO Payments.
    * verify: 
    *    no new donation created
    *    existing opp matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules12() {
        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules12') return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=700,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ',' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            7, BDI_DataImport_API.RequireExactMatch, label.bdiMatched, false);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: Amount, Date, where Opp has Multiple Payments.
    * verify: 
    *    no new donation created
    *    existing opp matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules13() {
        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules13') return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=550,
            Donation_Date__c=System.Today(),
            Payment_Method__c = 'Check',
            Donation_Donor__c='contact1');
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ',' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            9, BDI_DataImport_API.RequireExactMatch, label.bdiMatched, false);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: check#, where Opp has Multiple Payments.
    * verify: 
    *    no new donation created
    *    existing opp matched
    **********************************************************************************************************/            
    static testMethod void donationMatchRules14() {
        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules14') return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=25,
            Donation_Date__c=System.Today(),
            Donation_Donor__c='contact1',
            Payment_Method__c = 'Check',
            Payment_Check_Reference_Number__c='pick me'
            );
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Payment_Check_Reference_Number__c') + ',' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            9, BDI_DataImport_API.RequireExactMatch, label.bdiMatched, false);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations using different matching rules: check#, where Opp has Multiple Payments, 
    *    multi opps match, RequireExactMatch
    * verify: 
    *    no new donation created
    *    error reported on bdi
    **********************************************************************************************************/            
    static testMethod void donationMatchRules15() {
        if (strTestOnly != '*' && strTestOnly != 'donationMatchRules15') return;

        insert new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='c0', Contact1_Personal_Email__c='c0@c0.com',
            Donation_Amount__c=25,
            Donation_Date__c=System.Today(),
            Donation_Donor__c='contact1',
            Payment_Method__c = 'Check',
            Payment_Check_Reference_Number__c='dupe'
            );
            
        donationMatchRules(
            UTIL_Namespace.StrTokenNSPrefix('Payment_Check_Reference_Number__c') + ',' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c'),
            -1, BDI_DataImport_API.RequireExactMatch, label.bdiErrorDonationMultiMatch, true);
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
    * @param hasMultiMatches Whether we expect anything in Donation_Possible_Matches__c
    **********************************************************************************************************/            
    static void donationMatchRules(string strRule, integer imatch, string matchBehavior, 
        string expectedStatus, boolean hasMultiMatches) { 
        
        // create opps to match against
        Contact con = new Contact(firstname='c0', lastname='c0', email='c0@c0.com');
        insert con;
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

        insert listOpp;
        
        // create Opps 8-9's Payment records
        list<npe01__OppPayment__c> listPmt = new list<npe01__OppPayment__c>();
        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOpp[8].Id, npe01__Payment_Amount__c=350, 
            npe01__Scheduled_Date__c=System.Today(), npe01__Check_Reference_Number__c='dupe'));
        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOpp[8].Id, npe01__Payment_Amount__c=250, 
            npe01__Scheduled_Date__c=System.Today()));
        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOpp[9].Id, npe01__Payment_Amount__c=550, 
            npe01__Scheduled_Date__c=System.Today(), npe01__Check_Reference_Number__c='dupe'));
        listPmt.add(new npe01__OppPayment__c(npe01__Opportunity__c=listOpp[9].Id, npe01__Payment_Amount__c=150, 
            npe01__Scheduled_Date__c=System.Today(), npe01__Check_Reference_Number__c='pick me'));
        insert listPmt;
        
        // set the specified settings
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Donation_Matching_Rule__c = strRule;
        diSettings.Donation_Matching_Behavior__c = matchBehavior;
 
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        list<DataImport__c> listDI = [select Status__c, DonationImported__c, DonationImportStatus__c, 
            Donation_Possible_Matches__c, PaymentImported__c, PaymentImportStatus__c from DataImport__c];        
        system.assertEquals(1, listDI.size());
        system.assertEquals(expectedStatus, listDI[0].DonationImportStatus__c);
        system.assertEquals(hasMultiMatches, listDI[0].Donation_Possible_Matches__c != null);
        if (imatch >= 0) {                
            system.assertEquals(label.bdiImported, listDI[0].Status__c);
            system.assertEquals(listOpp[imatch].Id, listDI[0].DonationImported__c);
            if (imatch != 6 && imatch != 7) {
                system.assertNotEquals(null, listDI[0].PaymentImported__c);
                system.assertEquals(label.bdiMatched, listDI[0].PaymentImportStatus__c);
                npe01__OppPayment__c pmt = [select Id, npe01__Payment_Method__c from npe01__OppPayment__c 
                    where Id = :listDI[0].PaymentImported__c];
                system.assertEquals('Check', pmt.npe01__Payment_Method__c);
            }
	        // verify we matched an existing opp (no new opp created)
	        list<Opportunity> listOppX = [select Id, Name, Amount, Primary_Contact__c from Opportunity];
	        system.assertEquals(listOpp.size(), listOppX.size());
        }
    }
}