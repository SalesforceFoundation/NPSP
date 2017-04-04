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
    *        import existing contacts with existiong open Opportunities  
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
    
}