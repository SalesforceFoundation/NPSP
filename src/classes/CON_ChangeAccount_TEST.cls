/*
    Copyright (c) 2009, Salesforce.com Foundation
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
* @date 2015
* @description Tests for Moving a Contact from one Account to another Account
* @group ContactMerge
*/

@isTest
private with sharing class CON_ChangeAccount_TEST {

    /*********************************************************************************************************
    * @description if you only want to run one test in this class, fill in its name here.
    * if you want to run all tests, then use '*'
    */
    private static string strTestOnly = '*';
    
    /*********************************************************************************************************
    * @description Holds the number of Households to create in tests.
    */
    static integer cHH = 2;

    /*********************************************************************************************************
    * @description Holds the number of Contacts per Household to create in tests.
    */
    static integer cCon = 2;    

    /*********************************************************************************************************
    * @description Creates test opportunities for our test contacts and accounts.
    */
    private static void createTestOpps(integer cHHT, integer cConT) {
        list<Opportunity> listOpp = new list<Opportunity>();
        
        // create an Opp for each contact
        for (integer i = 0; i < cHHT; i++) {
            for (integer j = 0; j < cConT; j++) {
                Opportunity opp = new Opportunity();
                opp.AccountId = ADDR_Addresses_TEST.listAccT[i].Id;
                opp.npe01__Contact_Id_for_Role__c = ADDR_Addresses_TEST.listConT[(i * cHHT) + j].Id;
                opp.Amount = 10 + (i * 1000) + (j * 100); 
                opp.CloseDate = system.today();
                opp.StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
                opp.Name = 'TestOpp' + i + j;
                listOpp.add(opp);
            }
        }
        insert listOpp;
    }
    
    /*******************************************************************************************************
    * @description Move a Contact to a different Account, and verify: 
    *   the account's names and greetings are updated.
    *   Opps owned by the contact are moved over.
    *   Soft Credits for the moved Opps are recalculated.
    *   Soft Credits the contact previously had are still there.
    *   Opp Rollups are recalculated for both accounts.
    */
    static testMethod void testNamesAndOppsUpdated() {
        if (strTestOnly != '*' && strTestOnly != 'testNamesAndOppsUpdated') return;
        
        // this creates 2 Household Accounts, each with 2 Contacts, and a default Address for each HH
        ADDR_Addresses_TEST.createHHTestData(cHH, cCon);
        
        // this creates some test opps
        createTestOpps(cHH, cCon);

        // move the first contact in the first account to the other account.
        ADDR_Addresses_TEST.listConT[0].AccountId = ADDR_Addresses_TEST.listAccT[1].Id;
        update ADDR_Addresses_TEST.listConT[0];
        Test.stopTest();

        // reload our contacts and accounts
        list<Account> listAcc = new list<Account>([select Id, Name, npo02__Formal_Greeting__c, npo02__Informal_Greeting__c, 
            npo02__NumberOfClosedOpps__c, 
            BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry 
            from Account order by Id]);
        list<Contact> listCon = [select Id, Firstname, AccountId, 
            is_Address_Override__c, Current_Address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry 
            from Contact order by Firstname];
            
        // verify the contacts belong to correct account.
        system.assertEquals(ADDR_Addresses_TEST.listConT[0].Id, listCon[0].Id);
        system.assertEquals(ADDR_Addresses_TEST.listAccT[0].Id, listAcc[0].Id);
        system.assertEquals(listCon[0].AccountId, listAcc[1].Id);
        system.assertEquals(listCon[1].AccountId, listAcc[0].Id);
        system.assertEquals(listCon[2].AccountId, listAcc[1].Id);
        system.assertEquals(listCon[3].AccountId, listAcc[1].Id);
            
        // verify the account's names and greetings are updated
        system.assertEquals(false, listAcc[0].npo02__Formal_Greeting__c.contains(listCon[0].Firstname));        
        system.assertEquals(true, listAcc[1].npo02__Formal_Greeting__c.contains(listCon[0].Firstname));    
        
        // verify opps owned by the contact are moved over
        system.assertEquals(1, [select count() from Opportunity where AccountId = :listAcc[0].Id]);  
        system.assertEquals(3, [select count() from Opportunity where AccountId = :listAcc[1].Id]);  
            
        // verify Account rollups are updated
        system.assertEquals(1, listAcc[0].npo02__NumberOfClosedOpps__c);            
        system.assertEquals(3, listAcc[1].npo02__NumberOfClosedOpps__c);            

        // verify Soft Credits recalculated
        system.assertEquals(2, [select count() from OpportunityContactRole where ContactId = :listCon[0].Id]);        
        system.assertEquals(1, [select count() from OpportunityContactRole where ContactId = :listCon[1].Id]);        
        system.assertEquals(3, [select count() from OpportunityContactRole where ContactId = :listCon[2].Id]);        
        system.assertEquals(3, [select count() from OpportunityContactRole where ContactId = :listCon[3].Id]);        
    }

    /*******************************************************************************************************
    * @description Move a Contact to a different Account, and verify: 
    *   the contact is updated with the new household's default address
    */
    static testMethod void testGetsDefaultAddress() {
        if (strTestOnly != '*' && strTestOnly != 'testGetsDefaultAddress') return;
        
        // this creates 2 Household Accounts, each with 2 Contacts, and a default Address for each HH
        ADDR_Addresses_TEST.createHHTestData(cHH, cCon);
        
        // move the first contact in the first account to the other account.
        ADDR_Addresses_TEST.listConT[0].AccountId = ADDR_Addresses_TEST.listAccT[1].Id;
        update ADDR_Addresses_TEST.listConT[0];
        Test.stopTest();

        // reload our contacts and accounts
        list<Account> listAcc = new list<Account>([select Id, Name, npo02__Formal_Greeting__c, npo02__Informal_Greeting__c, 
            BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry 
            from Account order by Id]);
        list<Contact> listCon = [select Id, Firstname, AccountId, 
            is_Address_Override__c, Current_Address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry 
            from Contact order by Firstname];
            
        // verify the contacts belong to correct account.
        system.assertEquals(ADDR_Addresses_TEST.listConT[0].Id, listCon[0].Id);
        system.assertEquals(ADDR_Addresses_TEST.listAccT[0].Id, listAcc[0].Id);
        system.assertEquals(listCon[0].AccountId, listAcc[1].Id);
        system.assertEquals(listCon[1].AccountId, listAcc[0].Id);
        system.assertEquals(listCon[2].AccountId, listAcc[1].Id);
        system.assertEquals(listCon[3].AccountId, listAcc[1].Id);
            
        // verify the contact's address is updated to the household's default address
        system.assertNotEquals(listCon[0].MailingStreet, listAcc[0].BillingStreet);
        system.assertEquals(listCon[0].MailingStreet, listAcc[1].BillingStreet);
    }

    /*******************************************************************************************************
    * @description Move a Contact with an Address Override to a different Account, and verify: 
    *   the Address Override is copied to the new Account
    *   the Contact's Address Override lookup is updated
    *   the Contact's mailing address matches the override
    */
    static testMethod void testAddressOverride() {
        if (strTestOnly != '*' && strTestOnly != 'testAddressOverride') return;
        
        // this creates 2 Household Accounts, each with 2 Contacts, and a default Address for each HH
        ADDR_Addresses_TEST.createHHTestData(cHH, cCon);
        
        Contact con = ADDR_Addresses_TEST.listConT[0];
        
        // create their own address override
        con.MailingStreet = 'street override';
        con.MailingCity = 'city override';
        con.is_Address_Override__c = true;
        ADDR_Addresses_TDTM.hasRunAddrTrigger = false;
        update con;
        ADDR_Addresses_TDTM.hasRunAddrTrigger = false;
        
        // move the first contact in the first account to the other account.
        con.AccountId = ADDR_Addresses_TEST.listAccT[1].Id;
        update con;
        Test.stopTest();

        // reload our contacts and accounts
        list<Account> listAcc = new list<Account>([select Id, Name, npo02__Formal_Greeting__c, npo02__Informal_Greeting__c, 
            BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry 
            from Account order by Id]);
        list<Contact> listCon = [select Id, Firstname, AccountId, 
            is_Address_Override__c, Current_Address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry 
            from Contact order by Firstname];
            
        // verify the contacts belong to correct account.
        system.assertEquals(ADDR_Addresses_TEST.listConT[0].Id, listCon[0].Id);
        system.assertEquals(ADDR_Addresses_TEST.listAccT[0].Id, listAcc[0].Id);
        system.assertEquals(listCon[0].AccountId, listAcc[1].Id);
        system.assertEquals(listCon[1].AccountId, listAcc[0].Id);
        system.assertEquals(listCon[2].AccountId, listAcc[1].Id);
        system.assertEquals(listCon[3].AccountId, listAcc[1].Id);
        
        // verify we have the expected number of addresses (2 + override we created + override copied to new account)
        system.assertEquals(4, [select count() from Address__c]);
        system.assertEquals(2, [select count() from Address__c where Default_Address__c = true]);
        system.assertEquals(1, [select count() from Contact where is_Address_Override__c = true]);
        
        // verify the correct contact has the override
        system.assertEquals(true, listCon[0].is_Address_Override__c);
        Address__c addr = [select Id, Household_Account__c, MailingStreet__c, MailingCity__c from Address__c where Id = :listCon[0].Current_Address__c];
        
        // verify the address was moved to the new acccount
        system.assertEquals(listCon[0].AccountId, addr.Household_Account__c);
        system.assertNotEquals(ADDR_Addresses_TEST.listConT[0].Current_Address__c, listCon[0].Current_Address__c);
            
        // verify the contact's address is still the address override
        system.assertEquals(listCon[0].MailingStreet, addr.MailingStreet__c);
        system.assertEquals(listCon[0].MailingCity, addr.MailingCity__c);
    }
}