/*
    Copyright (c) 2014 Salesforce.com Foundation
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
* @description tests specific to the Data Importer 
*/

@isTest
private with sharing class BDI_DataImport_TEST {

    // if you only want to run one test in this class, fill in its name here.
    // if you want to run all tests, then use '*'
    private static string strTestOnly = '*';
    
    
    // utility to create a new di record    
    static DataImport__c newDI(string firstname, string lastname) {
        return new DataImport__c(
           Contact1_Firstname__c = firstname,
           Contact1_Lastname__c = lastname,
           Contact1_Personal_Email__c = firstname + '@' + lastname + '.com'
        );
    }

    // utility to create a new di record    
    static DataImport__c newDI(string firstname, string lastname, string firstname2, string lastname2) {
        return new DataImport__c(
           Contact1_Firstname__c = firstname,
           Contact1_Lastname__c = lastname,
           Contact1_Personal_Email__c = firstname + '@' + lastname + '.com',
           Contact2_Firstname__c = firstname2,
           Contact2_Lastname__c = lastname2,
           Contact2_Personal_Email__c = firstname2 + '@' + lastname2 + '.com'
        );
    }

    /*********************************************************************************************************
    operation:
        import matching contacts within the same di record 
    verify:
        only one contact created
    **********************************************************************************************************/            
    static testMethod void OneDIDuplicateNewContacts() {
        if (strTestOnly != '*' && strTestOnly != 'OneDIDuplicateNewContacts') return;
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(newDI('c1', 'C1', 'c1', 'C1'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Contact> listCon = [select Id, Name from Contact];
        system.assertEquals(1, listCon.size());
        system.assertEquals('c1 C1', listCon[0].Name);
        
        listDI = [select Contact1Imported__c, Contact1ImportStatus__c, HouseholdAccountImported__c, Contact2Imported__c, Contact2ImportStatus__c from DataImport__c];
        system.assertEquals(1, listDI.size());
        system.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        system.assertEquals(listDI[0].Contact2Imported__c, listCon[0].Id);
        system.assertNotEquals(null, listDI[0].HouseholdAccountImported__c);
        system.assertEquals(label.bdiCreated, listDI[0].Contact1ImportStatus__c);
        system.assertEquals(label.bdiMatched, listDI[0].Contact2ImportStatus__c);        
    }
    
    /*********************************************************************************************************
    operation:
        import different contacts within the same di record 
    verify:
        two contacts created
    **********************************************************************************************************/            
    static testMethod void OneDITwoNewContacts() {
        if (strTestOnly != '*' && strTestOnly != 'OneDITwoNewContacts') return;
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(newDI('c1', 'C1', 'c2', 'C2'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Contact> listCon = [select Id, Name from Contact order by Lastname];
        system.assertEquals(2, listCon.size());
        system.assertNotEquals(listCon[1].Name, listCon[0].Name);

        listDI = [select Contact1Imported__c, Contact1ImportStatus__c, HouseholdAccountImported__c, 
            Contact2Imported__c, Contact2ImportStatus__c from DataImport__c];
        system.assertEquals(1, listDI.size());
        system.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        system.assertEquals(listDI[0].Contact2Imported__c, listCon[1].Id);
        system.assertNotEquals(null, listDI[0].HouseholdAccountImported__c);        
        system.assertEquals(label.bdiCreated, listDI[0].Contact1ImportStatus__c);
        system.assertEquals(label.bdiCreated, listDI[0].Contact2ImportStatus__c);        
    }

    /*********************************************************************************************************
    operation:
        import matching contacts within multiple di records in the same batch 
    verify:
        only one contact created
    **********************************************************************************************************/            
    static testMethod void TwoDIDuplicateNewContacts() {
        if (strTestOnly != '*' && strTestOnly != 'TwoDIDuplicateNewContacts') return;
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(newDI('c1', 'C1'));
        listDI.add(newDI('c1', 'C1'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Contact> listCon = [select Id, Name from Contact];
        system.assertEquals(1, listCon.size());
        system.assertEquals('c1 C1', listCon[0].Name);

        listDI = [select Contact1Imported__c, Contact1ImportStatus__c, HouseholdAccountImported__c, 
            Contact2Imported__c, Contact2ImportStatus__c from DataImport__c order by Contact1ImportStatus__c];
        system.assertEquals(2, listDI.size());
        system.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        system.assertEquals(listDI[1].Contact1Imported__c, listCon[0].Id);
        system.assertNotEquals(null, listDI[0].HouseholdAccountImported__c);
        system.assertNotEquals(null, listDI[1].HouseholdAccountImported__c);
        system.assertEquals(label.bdiCreated, listDI[0].Contact1ImportStatus__c);
        system.assertEquals(label.bdiMatched, listDI[1].Contact1ImportStatus__c);        
    }
    
    /*********************************************************************************************************
    operation:
        import different contacts within multiple di records in the same batch
    verify:
        two contacts created
    **********************************************************************************************************/            
    static testMethod void TwoDITwoNewContacts() {
        if (strTestOnly != '*' && strTestOnly != 'TwoDITwoNewContacts') return;
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(newDI('c1', 'C1'));
        listDI.add(newDI('c2', 'C2'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Contact> listCon = [select Id, Name from Contact order by Id];
        system.assertEquals(2, listCon.size());
        system.assertNotEquals(listCon[1].Name, listCon[0].Name);

        listDI = [select Contact1Imported__c, Contact1ImportStatus__c, HouseholdAccountImported__c, 
            Contact2Imported__c, Contact2ImportStatus__c from DataImport__c order by Contact1Imported__c];
        system.assertEquals(2, listDI.size());
        system.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        system.assertEquals(listDI[1].Contact1Imported__c, listCon[1].Id);
        system.assertNotEquals(null, listDI[0].HouseholdAccountImported__c);
        system.assertNotEquals(null, listDI[1].HouseholdAccountImported__c);
        system.assertEquals(label.bdiCreated, listDI[0].Contact1ImportStatus__c);
        system.assertEquals(label.bdiCreated, listDI[1].Contact1ImportStatus__c);        
    }

    /*********************************************************************************************************
    operation:
        import existing contacts within the same di record 
    verify:
        two contacts matched
    **********************************************************************************************************/            
    static testMethod void OneDITwoExistingContacts() {
        if (strTestOnly != '*' && strTestOnly != 'OneDITwoExistingContacts') return;
            
        // existing contacts
        list<Contact> listConExisting = new list<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com'));
        listConExisting.add(new Contact(Firstname='c2', Lastname='C2', Email='c2@C2.com'));
        insert listConExisting;
        
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(newDI('c1', 'C1', 'c2', 'C2'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Contact> listCon = [select Id, Name from Contact order by Lastname];
        system.assertEquals(2, listCon.size());
        system.assertNotEquals(listCon[1].Name, listCon[0].Name);
        
        listDI = [select Contact1Imported__c, Contact1ImportStatus__c, HouseholdAccountImported__c, 
            Contact2Imported__c, Contact2ImportStatus__c from DataImport__c];
        system.assertEquals(1, listDI.size());
        system.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        system.assertEquals(listDI[0].Contact2Imported__c, listCon[1].Id);
        system.assertNotEquals(null, listDI[0].HouseholdAccountImported__c);
        system.assertEquals(label.bdiMatched, listDI[0].Contact1ImportStatus__c);
        system.assertEquals(label.bdiMatched, listDI[0].Contact2ImportStatus__c);        
    }

    /*********************************************************************************************************
    operation:
        import different accounts within the same di record 
    verify:
        two accounts created
    **********************************************************************************************************/            
    static testMethod void OneDITwoNewAccounts() {
        if (strTestOnly != '*' && strTestOnly != 'OneDITwoNewAccounts') return;
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Account1_Name__c='A1', Account2_Name__c='A2'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Account> listAcc = [select Id, Name from Account order by Name];
        system.assertEquals(2, listAcc.size());
        system.assertNotEquals(listAcc[1].Name, listAcc[0].Name);

        listDI = [select Account1Imported__c, Account1ImportStatus__c, Account2Imported__c, Account2ImportStatus__c from DataImport__c];
        system.assertEquals(1, listDI.size());
        system.assertEquals(listDI[0].Account1Imported__c, listAcc[0].Id);
        system.assertEquals(listDI[0].Account2Imported__c, listAcc[1].Id);
        system.assertEquals(label.bdiCreated, listDI[0].Account1ImportStatus__c);
        system.assertEquals(label.bdiCreated, listDI[0].Account2ImportStatus__c);        
    }

    /*********************************************************************************************************
    operation:
        import matching accounts within the same di record 
    verify:
        one accounts created
    **********************************************************************************************************/            
    static testMethod void OneDITwoSameAccounts() {
        if (strTestOnly != '*' && strTestOnly != 'OneDITwoSameAccounts') return;
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Account1_Name__c='A1', Account2_Name__c='A1'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Account> listAcc = [select Id, Name from Account order by Name];
        system.assertEquals(1, listAcc.size());

        listDI = [select Account1Imported__c, Account1ImportStatus__c, Account2Imported__c, Account2ImportStatus__c from DataImport__c];
        system.assertEquals(1, listDI.size());
        system.assertEquals(listDI[0].Account1Imported__c, listAcc[0].Id);
        system.assertEquals(listDI[0].Account2Imported__c, listAcc[0].Id);
        system.assertEquals(label.bdiCreated, listDI[0].Account1ImportStatus__c);
        system.assertEquals(label.bdiMatched, listDI[0].Account2ImportStatus__c);        
    }

    /*********************************************************************************************************
    operation:
        import matching accounts in different di records 
    verify:
        one account created
    **********************************************************************************************************/            
    static testMethod void TwoDISameAccounts() {
        if (strTestOnly != '*' && strTestOnly != 'TwoDISameAccounts') return;
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Account1_Name__c='A1'));
        listDI.add(new DataImport__c(Account1_Name__c='A1'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Account> listAcc = [select Id, Name from Account order by Name];
        system.assertEquals(1, listAcc.size());

        listDI = [select Account1Imported__c, Account1ImportStatus__c, Account2Imported__c, Account2ImportStatus__c from DataImport__c order by Account1ImportStatus__c];
        system.assertEquals(2, listDI.size());
        system.assertEquals(listDI[0].Account1Imported__c, listAcc[0].Id);
        system.assertEquals(listDI[1].Account1Imported__c, listAcc[0].Id);
        system.assertEquals(label.bdiCreated, listDI[0].Account1ImportStatus__c);
        system.assertEquals(label.bdiMatched, listDI[1].Account1ImportStatus__c);        
    }

    /*********************************************************************************************************
    operation:
        import existing accounts 
    verify:
        no accounts created, just matched
    **********************************************************************************************************/            
    static testMethod void TwoDIExistingAccounts() {
        if (strTestOnly != '*' && strTestOnly != 'TwoDIExistingAccounts') return;
            
        list<Account> listAcc = new list<Account>();
        listAcc.add(new Account(name='A1'));
        listAcc.add(new Account(name='A2'));
        insert listAcc;    
                    
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Account1_Name__c='A1'));
        listDI.add(new DataImport__c(Account1_Name__c='A2'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        listAcc = [select Id, Name from Account order by Name];
        system.assertEquals(2, listAcc.size());

        listDI = [select Account1Imported__c, Account1ImportStatus__c, Account2Imported__c, Account2ImportStatus__c from DataImport__c order by Id];
        system.assertEquals(2, listDI.size());
        system.assertEquals(listDI[0].Account1Imported__c, listAcc[0].Id);
        system.assertEquals(listDI[1].Account1Imported__c, listAcc[1].Id);
        system.assertEquals(label.bdiMatched, listDI[0].Account1ImportStatus__c);
        system.assertEquals(label.bdiMatched, listDI[1].Account1ImportStatus__c);        
    }

    /*********************************************************************************************************
    operation:
        import contacts with Preferred Email set
    verify:
        ensure the appropriate contact email field gets copied into the standard email field.
    **********************************************************************************************************/
    /** can't use this test because it relies on our workflow rules being active, which we can't enforce.
    static testMethod void ThreeDINewContactsWithPreferredEmail() {
        if (strTestOnly != '*' && strTestOnly != 'ThreeDINewContactsWithPreferredEmail') return;
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(newDI('c1', 'C1'));
        listDI.add(newDI('c2', 'C2'));
        listDI.add(newDI('c3', 'C3'));
        listDI[0].Contact1_Preferred_Email__c = 'Home';
        listDI[0].Contact1_Personal_Email__c = 'c1@home.com';
        listDI[1].Contact1_Preferred_Email__c = 'Work';
        listDI[1].Contact1_Work_Email__c = 'c2@work.com';
        listDI[2].Contact1_Preferred_Email__c = 'Alternate';
        listDI[2].Contact1_Personal_Email__c = 'c3@alt.com';
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Contact> listCon = [select Id, Name, Email from Contact order by Lastname];
        system.assertEquals(3, listCon.size());
        system.assertEquals('c1 C1', listCon[0].Name);
        system.assertEquals('c1@home.com', listCon[0].Email);
        system.assertEquals('c2 C2', listCon[1].Name);
        system.assertEquals('c2@work.com', listCon[1].Email);
        system.assertEquals('c3 C3', listCon[2].Name);
        system.assertEquals('c3@alt.com', listCon[2].Email);        
    }
    ***************/

    /*********************************************************************************************************
    operation:
        import contacts with accounts
    verify:
        contacts created
        accounts created
        affiliations created between contacts and accounts
    **********************************************************************************************************/            
    static testMethod void TwoDIAffiliations() {
        if (strTestOnly != '*' && strTestOnly != 'TwoDIAffiliations') return;
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(newDI('c1', 'C1', 'c2', 'C2'));
        listDI.add(newDI('c3', 'C3', 'c4', 'C4'));
        listDI[0].Account1_Name__c = 'A1';
        listDI[1].Account2_Name__c = 'A2';
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Contact> listCon = [select Id, Name, AccountId, Primary_Affiliation__c from Contact order by Lastname];
        system.assertEquals(4, listCon.size());
        system.assertEquals('c1 C1', listCon[0].Name);
        system.assertEquals('c2 C2', listCon[1].Name);
        system.assertEquals('c3 C3', listCon[2].Name);
        system.assertEquals('c4 C4', listCon[3].Name);
        system.assertNotEquals(null, listCon[0].AccountId);
        system.assertNotEquals(null, listCon[1].AccountId);
        system.assertNotEquals(null, listCon[2].AccountId);
        system.assertNotEquals(null, listCon[3].AccountId);
        
        list<Account> listAcc = [select Id, Name from Account where Type != 'Household' order by Name];
        system.assertEquals(2, listAcc.size());
        system.assertEquals(listCon[0].Primary_Affiliation__c, listAcc[0].Id);
        system.assertEquals(listCon[1].Primary_Affiliation__c, null);
        system.assertEquals(listCon[2].Primary_Affiliation__c, null);
        system.assertEquals(listCon[3].Primary_Affiliation__c, listAcc[1].Id);
        
        list<npe5__Affiliation__c> listAffl = [select Id, npe5__Contact__c, npe5__Organization__c from npe5__Affiliation__c order by npe5__Contact__r.Name];
        system.assertEquals(2, listAffl.size());
        system.assertEquals(listCon[0].Id, listAffl[0].npe5__Contact__c);
        system.assertEquals(listCon[3].Id, listAffl[1].npe5__Contact__c);
                
    }

    /*********************************************************************************************************
    operation:
        import contacts with home addresses 
    verify:
        address objects created
        contacts' mailing address set
        hh accounts' billing address set
    **********************************************************************************************************/            
    static testMethod void TwoDIHomeAddresses() {
        if (strTestOnly != '*' && strTestOnly != 'TwoDIHomeAddresses') return;
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(newDI('c1', 'C1', 'c2', 'C2'));
        listDI.add(newDI('c3', 'C3', 'c4', 'C4'));
        listDI[0].Home_City__c = 'Seattle';
        listDI[1].Home_City__c = 'Portland';
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Contact> listCon = [select Id, Name, AccountId, MailingCity from Contact order by Lastname];
        system.assertEquals(4, listCon.size());
        system.assertEquals('c1 C1', listCon[0].Name);
        system.assertEquals('c2 C2', listCon[1].Name);
        system.assertEquals('c3 C3', listCon[2].Name);
        system.assertEquals('c4 C4', listCon[3].Name);
        system.assertNotEquals(null, listCon[0].AccountId);
        system.assertNotEquals(null, listCon[1].AccountId);
        system.assertNotEquals(null, listCon[2].AccountId);
        system.assertNotEquals(null, listCon[3].AccountId);
        system.assertEquals('Seattle', listCon[0].MailingCity);
        system.assertEquals('Seattle', listCon[1].MailingCity);
        system.assertEquals('Portland', listCon[2].MailingCity);
        system.assertEquals('Portland', listCon[3].MailingCity);
        
        list<Address__c> listAddr = [select Id, Household_Account__c, MailingCity__c from Address__c order by MailingCity__c]; 
        system.assertEquals(2, listAddr.size());
        system.assertEquals('Portland', listAddr[0].MailingCity__c);
        system.assertEquals('Seattle', listAddr[1].MailingCity__c);
        
        list<Account> listAcc = [select Id, Name, BillingCity from Account order by Name];
        system.assertEquals(2, listAcc.size());
        system.assertEquals('Seattle', listAcc[0].BillingCity);
        system.assertEquals('Portland', listAcc[1].BillingCity);
                
        listDI = [select HomeAddressImported__c, HomeAddressImportStatus__c, Home_City__c from DataImport__c order by Home_City__c];
        system.assertEquals(2, listDI.size());
        system.assertEquals(listDI[0].HomeAddressImported__c, listAddr[0].Id); 
        system.assertEquals(listDI[1].HomeAddressImported__c, listAddr[1].Id);
        system.assertEquals(label.bdiCreated, listDI[0].HomeAddressImportStatus__c);
        system.assertEquals(label.bdiCreated, listDI[1].HomeAddressImportStatus__c);        
    }
    
    /*********************************************************************************************************
    operation:
        import existing contacts with the same home address
    verify:
        contacts matched
        address matched
    **********************************************************************************************************/            
    static testMethod void TwoDIMixedAddresses() {
        if (strTestOnly != '*' && strTestOnly != 'TwoDIMixedAddresses') return;
            
        // existing contacts
        list<Contact> listConExisting = new list<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com', MailingCity='Seattle'));
        listConExisting.add(new Contact(Firstname='c2', Lastname='C2', Email='c2@C2.com', MailingCity='Portland'));
        insert listConExisting;
        
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(newDI('c1', 'C1'));
        listDI.add(newDI('c2', 'C2'));
        listDI[0].Home_City__c = 'Seattle';
        listDI[1].Home_City__c = 'Bellevue';
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Contact> listCon = [select Id, Name from Contact order by Lastname];
        system.assertEquals(2, listCon.size());
        
        list<Address__c> listAddr = [select Id, Household_Account__c, MailingCity__c from Address__c order by MailingCity__c]; 
        system.assertEquals(3, listAddr.size());
        system.assertEquals('Bellevue', listAddr[0].MailingCity__c);
        system.assertEquals('Portland', listAddr[1].MailingCity__c);
        system.assertEquals('Seattle', listAddr[2].MailingCity__c);
        
        listDI = [select Contact1Imported__c, Contact1ImportStatus__c, HouseholdAccountImported__c, 
            HomeAddressImported__c, HomeAddressImportStatus__c from DataImport__c order by Contact1_Lastname__c];
        system.assertEquals(2, listDI.size());
        system.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        system.assertEquals(listDI[1].Contact1Imported__c, listCon[1].Id);
        system.assertNotEquals(null, listDI[0].HouseholdAccountImported__c);
        system.assertNotEquals(null, listDI[1].HouseholdAccountImported__c);
        system.assertEquals(label.bdiMatched, listDI[0].Contact1ImportStatus__c);
        system.assertEquals(label.bdiMatched, listDI[1].Contact1ImportStatus__c);
        system.assertEquals(listAddr[2].Id, listDI[0].HomeAddressImported__c);   
        system.assertEquals(listAddr[0].Id, listDI[1].HomeAddressImported__c);   
        system.assertEquals(label.bdiMatched, listDI[0].HomeAddressImportStatus__c);
        system.assertEquals(label.bdiCreated, listDI[1].HomeAddressImportStatus__c);            
    }
    
    /*********************************************************************************************************
    operation:
        import contacts with donation & payment information 
    verify:
        opportunity objects created
        payment objects created
        ocr's created
        contacts' rollups updated
        hh account's rollups updated
    **********************************************************************************************************/            
    static testMethod void TwoDIWithDonations() {
        if (strTestOnly != '*' && strTestOnly != 'TwoDIWithDonations') return;
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(newDI('c1', 'C1', 'c2', 'C2'));
        listDI.add(newDI('c3', 'C3', 'c4', 'C4'));
        listDI[0].Donation_Amount__c = 100;
        listDI[1].Donation_Amount__c = 200;
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
        list<Contact> listCon = [select Id, Name, AccountId, npo02__TotalOppAmount__c from Contact order by Lastname];
        system.assertEquals(4, listCon.size());
        system.assertEquals('c1 C1', listCon[0].Name);
        system.assertEquals('c2 C2', listCon[1].Name);
        system.assertEquals('c3 C3', listCon[2].Name);
        system.assertEquals('c4 C4', listCon[3].Name);
        system.assertNotEquals(null, listCon[0].AccountId);
        system.assertNotEquals(null, listCon[1].AccountId);
        system.assertNotEquals(null, listCon[2].AccountId);
        system.assertNotEquals(null, listCon[3].AccountId);
        system.assertEquals(100, listCon[0].npo02__TotalOppAmount__c);
        system.assertEquals(0, listCon[1].npo02__TotalOppAmount__c);
        system.assertEquals(200, listCon[2].npo02__TotalOppAmount__c);
        system.assertEquals(0, listCon[3].npo02__TotalOppAmount__c);
        
        list<Account> listAcc = [select Id, Name, npo02__TotalOppAmount__c from Account order by Name];
        system.assertEquals(2, listAcc.size());
        system.assertEquals(100, listAcc[0].npo02__TotalOppAmount__c);
        system.assertEquals(200, listAcc[1].npo02__TotalOppAmount__c);
        
        list<Opportunity> listOpp = [select Id, Name, Amount, AccountId from Opportunity order by Name];
        system.assertEquals(2, listOpp.size());
        system.assertEquals(100, listOpp[0].Amount);
        system.assertEquals(200, listOpp[1].Amount);
        system.assertEquals(listAcc[0].Id, listOpp[0].AccountId);
        system.assertEquals(listAcc[1].Id, listOpp[1].AccountId);
                
        list<npe01__OppPayment__c> listPmt = [select Id, npe01__Payment_Amount__c, npe01__Payment_Method__c, npe01__Check_Reference_Number__c from npe01__OppPayment__c order by npe01__Opportunity__r.Name];
        system.assertEquals(2, listPmt.size());
        system.assertEquals(100, listPmt[0].npe01__Payment_Amount__c);
        system.assertEquals(200, listPmt[1].npe01__Payment_Amount__c);
        system.assertEquals('Check', listPmt[0].npe01__Payment_Method__c);
        system.assertEquals('Visa', listPmt[1].npe01__Payment_Method__c);
        system.assertEquals('abc', listPmt[0].npe01__Check_Reference_Number__c);
        system.assertEquals('1234', listPmt[1].npe01__Check_Reference_Number__c);

        list<OpportunityContactRole> listOCR = [select Id, ContactId, OpportunityId from OpportunityContactRole order by Contact.Name];
        system.assertEquals(4, listOCR.size());
        system.assertEquals(listCon[0].Id, listOCR[0].ContactId);
        system.assertEquals(listCon[1].Id, listOCR[1].ContactId);
        system.assertEquals(listCon[2].Id, listOCR[2].ContactId);
        system.assertEquals(listCon[3].Id, listOCR[3].ContactId);

        listDI = [select Id, DonationImported__c, DonationImportStatus__c from DataImport__c order by Contact1_Lastname__c];
        system.assertEquals(2, listDI.size());
        system.assertEquals(listDI[0].DonationImported__c, listOpp[0].Id); 
        system.assertEquals(listDI[1].DonationImported__c, listOpp[1].Id);
        system.assertEquals(label.bdiCreated, listDI[0].DonationImportStatus__c);
        system.assertEquals(label.bdiCreated, listDI[1].DonationImportStatus__c);        
    }

    /*********************************************************************************************************
    operation:
        import accounts with donation & payment information 
    verify:
        opportunity objects created
        payment objects created
        ocr's created
        account's rollups updated
    **********************************************************************************************************/            
    static testMethod void TwoDIWithAccountDonations() {
        if (strTestOnly != '*' && strTestOnly != 'TwoDIWithAccountDonations') return;
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Account1_Name__c='A1'));
        listDI.add(new DataImport__c(Account1_Name__c='A2'));
        listDI[0].Donation_Donor__c = 'Account1';
        listDI[1].Donation_Donor__c = 'Account1';
        listDI[0].Donation_Amount__c = 100;
        listDI[1].Donation_Amount__c = 200;
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
        list<Account> listAcc = [select Id, Name, npo02__TotalOppAmount__c from Account order by Name];
        system.assertEquals(2, listAcc.size());
        system.assertEquals(100, listAcc[0].npo02__TotalOppAmount__c);
        system.assertEquals(200, listAcc[1].npo02__TotalOppAmount__c);
        
        list<Opportunity> listOpp = [select Id, Name, Amount, AccountId from Opportunity order by Name];
        system.assertEquals(2, listOpp.size());
        system.assertEquals(100, listOpp[0].Amount);
        system.assertEquals(200, listOpp[1].Amount);
        system.assertEquals(listAcc[0].Id, listOpp[0].AccountId);
        system.assertEquals(listAcc[1].Id, listOpp[1].AccountId);
                
        list<npe01__OppPayment__c> listPmt = [select Id, npe01__Payment_Amount__c, npe01__Payment_Method__c, npe01__Check_Reference_Number__c from npe01__OppPayment__c order by npe01__Opportunity__r.Name];
        system.assertEquals(2, listPmt.size());
        system.assertEquals(100, listPmt[0].npe01__Payment_Amount__c);
        system.assertEquals(200, listPmt[1].npe01__Payment_Amount__c);
        system.assertEquals('Check', listPmt[0].npe01__Payment_Method__c);
        system.assertEquals('Visa', listPmt[1].npe01__Payment_Method__c);
        system.assertEquals('abc', listPmt[0].npe01__Check_Reference_Number__c);
        system.assertEquals('1234', listPmt[1].npe01__Check_Reference_Number__c);

        list<OpportunityContactRole> listOCR = [select Id, ContactId, OpportunityId from OpportunityContactRole order by Contact.Name];
        system.assertEquals(0, listOCR.size());

        listDI = [select Id, DonationImported__c, DonationImportStatus__c from DataImport__c order by Account1_Name__c];
        system.assertEquals(2, listDI.size());
        system.assertEquals(listDI[0].DonationImported__c, listOpp[0].Id); 
        system.assertEquals(listDI[1].DonationImported__c, listOpp[1].Id);
        system.assertEquals(label.bdiCreated, listDI[0].DonationImportStatus__c);
        system.assertEquals(label.bdiCreated, listDI[1].DonationImportStatus__c);        
    }

    /*********************************************************************************************************
    operation:
        import contacts with donation & campaign information 
    verify:
        opportunity objects created
        opportunities added to campaigns
    **********************************************************************************************************/            
    static testMethod void TwoDIWithDonationsAndCampaigns() {
        if (strTestOnly != '*' && strTestOnly != 'TwoDIWithDonationsAndCampaigns') return;
        
        list<Campaign> listC = new list<Campaign>();
        listC.add(new Campaign(Name='CmpExisting'));
        insert listC;
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(newDI('c1', 'C1'));
        listDI.add(newDI('c2', 'C2'));
        listDI[0].Donation_Amount__c = 100;
        listDI[1].Donation_Amount__c = 200;
        listDI[0].Donation_Campaign_Name__c = 'CmpExisting';
        listDI[1].Donation_Campaign_Name__c = 'CmpNew';
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Contact> listCon = [select Id, Name, AccountId, npo02__TotalOppAmount__c from Contact order by Lastname];
        system.assertEquals(2, listCon.size());
        
        list<Account> listAcc = [select Id, Name, npo02__TotalOppAmount__c from Account order by Name];
        system.assertEquals(2, listAcc.size());
        system.assertEquals(100, listAcc[0].npo02__TotalOppAmount__c);
        system.assertEquals(200, listAcc[1].npo02__TotalOppAmount__c);
        
        list<Opportunity> listOpp = [select Id, Name, Amount, AccountId, CampaignId from Opportunity order by Name];
        system.assertEquals(2, listOpp.size());
        system.assertEquals(100, listOpp[0].Amount);
        system.assertEquals(200, listOpp[1].Amount);
        system.assertEquals(listAcc[0].Id, listOpp[0].AccountId);
        system.assertEquals(listAcc[1].Id, listOpp[1].AccountId);
                
        list<Campaign> listCmp = [select Id, Name from Campaign order by Name];
        system.assertEquals(2, listCmp.size());
        system.assertEquals(listOpp[0].CampaignId, listCmp[0].Id);
        system.assertEquals(listOpp[1].CampaignId, listCmp[1].Id);
        
        listDI = [select Id, DonationImported__c, DonationImportStatus__c from DataImport__c order by Contact1_Lastname__c];
        system.assertEquals(2, listDI.size());
        system.assertEquals(listDI[0].DonationImported__c, listOpp[0].Id); 
        system.assertEquals(listDI[1].DonationImported__c, listOpp[1].Id);
        system.assertEquals(label.bdiCreated, listDI[0].DonationImportStatus__c);
        system.assertEquals(label.bdiCreated, listDI[1].DonationImportStatus__c);        
    }

    /*********************************************************************************************************
    operation:
        import accounts with invalid donation information 
    verify:
        opportunity objects created only for valid di
    **********************************************************************************************************/            
    static testMethod void TwoDIWithDonationErrors() {
        if (strTestOnly != '*' && strTestOnly != 'TwoDIWithDonationErrors') return;
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Account1_Name__c='A1'));
        listDI.add(new DataImport__c(Account1_Name__c='A2'));
        listDI[0].Donation_Donor__c = 'Account1';
        listDI[1].Donation_Donor__c = 'illegal value here!';
        listDI[0].Donation_Amount__c = 100;
        listDI[1].Donation_Amount__c = 200;
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results        
        list<Account> listAcc = [select Id, Name, npo02__TotalOppAmount__c from Account order by Name];
        system.assertEquals(2, listAcc.size());
        system.assertEquals(100, listAcc[0].npo02__TotalOppAmount__c);
        system.assertEquals(0, listAcc[1].npo02__TotalOppAmount__c);
        
        list<Opportunity> listOpp = [select Id, Name, Amount, AccountId from Opportunity order by Name];
        system.assertEquals(1, listOpp.size());
        system.assertEquals(100, listOpp[0].Amount);
        system.assertEquals(listAcc[0].Id, listOpp[0].AccountId);
                
        listDI = [select Id, Status__c, DonationImported__c, DonationImportStatus__c from DataImport__c order by Account1_Name__c];
        system.assertEquals(2, listDI.size());
        system.assertEquals(listDI[0].DonationImported__c, listOpp[0].Id); 
        system.assertEquals(listDI[1].DonationImported__c, null);
        system.assertEquals(label.bdiCreated, listDI[0].DonationImportStatus__c);
        system.assertEquals(label.bdiErrorInvalidDonor, listDI[1].DonationImportStatus__c);
        system.assertEquals(label.bdiImported, listDI[0].Status__c);        
        system.assertEquals(label.bdiFailed, listDI[1].Status__c);        
    }

    /*********************************************************************************************************
    operation:
        run data import through the visualforce page
    verify:
        all code tested in controller
    **********************************************************************************************************/            
    static testMethod void TestBDIVisualforcePage() {
        if (strTestOnly != '*' && strTestOnly != 'TestBDIVisualforcePage') return;
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(newDI('c1', 'C1', 'c2', 'C2'));
        listDI.add(newDI('c3', 'C3', 'c4', 'C4'));
        listDI[0].Account1_Name__c = 'A1';
        listDI[0].Donation_Amount__c = 100;
        listDI[1].Donation_Amount__c = 200;
        insert listDI;
        
        Test.startTest();

        // create the page 
        Test.setCurrentPage(Page.BDI_DataImport); 

        // instantiate the controller
        BDI_DataImport_CTRL ctrl = new BDI_DataImport_CTRL();

        system.assertEquals(2, ctrl.crecToProcess);
        system.assertEquals(false, ctrl.isBatchJobCompleted);
        system.assertEquals(null, ctrl.crecProcessed);
        system.assertEquals(null, ctrl.crecImported);
        system.assertEquals(null, ctrl.crecFailed);
        
        ctrl.importData();
        Test.stopTest();

        system.assertEquals(true, ctrl.isBatchJobCompleted);
        system.assertEquals(100, ctrl.percentComplete);
        system.assertEquals(null, ctrl.strTimeSpent);
        system.assertNotEquals(null, ctrl.aaj);
        system.assertEquals(2, ctrl.crecProcessed);
        system.assertEquals(2, ctrl.crecImported);
        system.assertEquals(0, ctrl.crecFailed);
        system.assertEquals(0, ctrl.crecToProcess);
        system.assertNotEquals(null, ctrl.close());

         // verify expected results
        list<Contact> listCon = [select Id, Name from Contact order by Name];
        system.assertEquals(4, listCon.size());
        system.assertEquals('c1 C1', listCon[0].Name);
        
        list<Account> listAcc = [select Id, Name from Account order by Name];
        system.assertEquals(3, listAcc.size());
        
        list<Opportunity> listOpp = [select Id, Name, Amount, AccountId from Opportunity order by Name];
        system.assertEquals(2, listOpp.size());
        system.assertEquals(100, listOpp[0].Amount);

        listDI = [select Contact1Imported__c, Contact1ImportStatus__c, HouseholdAccountImported__c, 
            Contact2Imported__c, Contact2ImportStatus__c from DataImport__c];
        system.assertEquals(2, listDI.size());
        system.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        system.assertEquals(listDI[0].Contact2Imported__c, listCon[1].Id);
        system.assertEquals(listDI[1].Contact1Imported__c, listCon[2].Id);
        system.assertEquals(listDI[1].Contact2Imported__c, listCon[3].Id);
        system.assertNotEquals(null, listDI[0].HouseholdAccountImported__c);
        system.assertNotEquals(null, listDI[1].HouseholdAccountImported__c);
        system.assertEquals(label.bdiCreated, listDI[0].Contact1ImportStatus__c);
        system.assertEquals(label.bdiCreated, listDI[0].Contact2ImportStatus__c);        
        system.assertEquals(label.bdiCreated, listDI[1].Contact1ImportStatus__c);
        system.assertEquals(label.bdiCreated, listDI[1].Contact2ImportStatus__c);        
    }

    /*********************************************************************************************************
    operation:
        test validation rules for settings on visualforce page
    verify:
        all code tested in controller
    **********************************************************************************************************/            
    static testMethod void TestBDIVisualforcePageValidation() {
        if (strTestOnly != '*' && strTestOnly != 'TestBDIVisualforcePageValidation') return;
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(newDI('c1', 'C1', 'c2', 'C2'));
        insert listDI;
        
        Test.startTest();

        // create the page 
        Test.setCurrentPage(Page.BDI_DataImport); 

        // instantiate the controller
        BDI_DataImport_CTRL ctrl = new BDI_DataImport_CTRL();
        
        ctrl.diSettings.Account_Custom_Unique_ID__c = 'Name';
        ctrl.importData();
        system.assertEquals(false, ctrl.batchRunning);
        
        ctrl.diSettings.Account_Custom_Unique_ID__c = null;
        ctrl.diSettings.Account_Custom_Unique_ID__c = 'Lastname';        
        ctrl.importData();
        system.assertEquals(false, ctrl.batchRunning);
        
        Test.stopTest();
    }

   /*********************************************************************************************************
    operation:
        test the Delete All Data Import Records button
    verify:
        all records deleted
    **********************************************************************************************************/            
    static testMethod void TestDeleteAllDIRecordsBtn() {
        if (strTestOnly != '*' && strTestOnly != 'TestDeleteAllDIRecordsBtn') return;
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(newDI('c1', 'C1', 'c2', 'C2'));
        listDI.add(newDI('c3', 'C3', 'c4', 'C4'));
        listDI.add(newDI('c3', 'C3', 'c4', 'C4'));
        listDI.add(newDI('c3', 'C3', 'c4', 'C4'));
        listDI[0].Status__c = label.bdiImported;
        listDI[1].Status__c = label.bdiFailed;
        insert listDI;
        
        Test.startTest();

        // create the page 
        Test.setCurrentPage(Page.BDI_DataImport); 

        // instantiate the controller
        BDI_DataImport_CTRL ctrl = new BDI_DataImport_CTRL();

        // call the deleteAll method
        ctrl.deleteAllDIRecords();
        Test.stopTest();

        // verify results
        listDI = [select Id, Status__c from DataImport__c];
        system.assertEquals(0, listDI.size());
    }

   /*********************************************************************************************************
    operation:
        test the Delete Imported Data Import Records button
    verify:
        all records deleted
    **********************************************************************************************************/            
    static testMethod void TestDeleteImportedDIRecordsBtn() {
        if (strTestOnly != '*' && strTestOnly != 'TestDeleteImportedDIRecordsBtn') return;
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(newDI('c1', 'C1', 'c2', 'C2'));
        listDI.add(newDI('c3', 'C3', 'c4', 'C4'));
        listDI.add(newDI('c3', 'C3', 'c4', 'C4'));
        listDI.add(newDI('c3', 'C3', 'c4', 'C4'));
        listDI[0].Status__c = label.bdiImported;
        listDI[1].Status__c = label.bdiFailed;
        listDI[3].Status__c = label.bdiImported;
        insert listDI;
        
        Test.startTest();

        // create the page 
        Test.setCurrentPage(Page.BDI_DataImport); 

        // instantiate the controller
        BDI_DataImport_CTRL ctrl = new BDI_DataImport_CTRL();

        // call the deleteAll method
        ctrl.deleteImportedDIRecords();
        Test.stopTest();

        // verify results
        listDI = [select Id, Status__c from DataImport__c order by Status__c];
        system.assertEquals(2, listDI.size());
        system.assertEquals(null, listDI[0].Status__c);
        system.assertEquals(label.bdiFailed, listDI[1].Status__c);
    }

    /*********************************************************************************************************
    operation:
        import matching contacts within multiple di records in the same batch, using different email fields
    verify:
        only one contact created
    **********************************************************************************************************/            
    static testMethod void ManyDIDuplicateEmailNewContacts() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDIDuplicateEmailNewContacts') return;
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@foo.com'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Work_Email__c='c1@foo.com'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Alternate_Email__c='c1@foo.com'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Contact> listCon = [select Id, Name from Contact];
        system.assertEquals(1, listCon.size());
        system.assertEquals('c1 C1', listCon[0].Name);

        listDI = [select Contact1Imported__c, Contact1ImportStatus__c, HouseholdAccountImported__c, 
            Contact2Imported__c, Contact2ImportStatus__c from DataImport__c order by Contact1ImportStatus__c];
        system.assertEquals(3, listDI.size());
        system.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        system.assertEquals(listDI[1].Contact1Imported__c, listCon[0].Id);
        system.assertEquals(listDI[2].Contact1Imported__c, listCon[0].Id);
        system.assertNotEquals(null, listDI[0].HouseholdAccountImported__c);
        system.assertNotEquals(null, listDI[1].HouseholdAccountImported__c);
        system.assertNotEquals(null, listDI[2].HouseholdAccountImported__c);
        system.assertEquals(label.bdiCreated, listDI[0].Contact1ImportStatus__c);
        system.assertEquals(label.bdiMatched, listDI[1].Contact1ImportStatus__c);        
        system.assertEquals(label.bdiMatched, listDI[1].Contact1ImportStatus__c);        
    }
    
    /*********************************************************************************************************
    operation:
        import existing contacts within multiple di records in the same batch, using different email fields
    verify:
        all contacts matched
    **********************************************************************************************************/            
    static testMethod void ManyDIDuplicateEmailExistingContacts() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDIDuplicateEmailExistingContacts') return;
            
         // existing contacts
        list<Contact> listConExisting = new list<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com'));
        listConExisting.add(new Contact(Firstname='c2', Lastname='C2', npe01__HomeEmail__c='c2@C2.com'));
        listConExisting.add(new Contact(Firstname='c3', Lastname='C3', npe01__WorkEmail__c='c3@C3.com'));
        listConExisting.add(new Contact(Firstname='c4', Lastname='C4', npe01__AlternateEmail__c='c4@C4.com'));
        insert listConExisting;
 
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Alternate_Email__c='c1@C1.com'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c2', Contact1_Lastname__c='C2', Contact1_Alternate_Email__c='c2@C2.com'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c3', Contact1_Lastname__c='C3', Contact1_Alternate_Email__c='c3@C3.com'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c4', Contact1_Lastname__c='C4', Contact1_Alternate_Email__c='c4@C4.com'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Contact> listCon = [select Id, Name from Contact order by Lastname];
        system.assertEquals(4, listCon.size());

        listDI = [select Contact1Imported__c, Contact1ImportStatus__c, HouseholdAccountImported__c, 
            Contact2Imported__c, Contact2ImportStatus__c from DataImport__c order by Contact1_Lastname__c];
        system.assertEquals(4, listDI.size());
        system.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        system.assertEquals(listDI[1].Contact1Imported__c, listCon[1].Id);
        system.assertEquals(listDI[2].Contact1Imported__c, listCon[2].Id);
        system.assertEquals(listDI[3].Contact1Imported__c, listCon[3].Id);
        system.assertNotEquals(null, listDI[0].HouseholdAccountImported__c);
        system.assertNotEquals(null, listDI[1].HouseholdAccountImported__c);
        system.assertNotEquals(null, listDI[2].HouseholdAccountImported__c);
        system.assertEquals(label.bdiMatched, listDI[0].Contact1ImportStatus__c);
        system.assertEquals(label.bdiMatched, listDI[1].Contact1ImportStatus__c);        
        system.assertEquals(label.bdiMatched, listDI[2].Contact1ImportStatus__c);        
        system.assertEquals(label.bdiMatched, listDI[3].Contact1ImportStatus__c);        
    }

    /*********************************************************************************************************
    operation:
        import existing contacts within multiple di records in the same batch, using overlapping email fields
    verify:
        all contacts matched
    **********************************************************************************************************/            
    static testMethod void ManyDIOverlappingEmailExistingContacts() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDIOverlappingEmailExistingContacts') return;
            
         // existing contacts
        list<Contact> listConExisting = new list<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@c1.com'));
        insert listConExisting;
 
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@c1.com'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@c1.com', Contact1_Alternate_Email__c='c1@alt.com'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Work_Email__c='c1@alt.com'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Contact> listCon = [select Id, Name, Email, npe01__HomeEmail__c, npe01__WorkEmail__c, npe01__AlternateEmail__c from Contact order by Lastname];
        system.assertEquals(1, listCon.size());
        system.assertEquals('c1@c1.com', listCon[0].npe01__HomeEmail__c);
        system.assertEquals('c1@alt.com', listCon[0].npe01__AlternateEmail__c);
        system.assertEquals('c1@alt.com', listCon[0].npe01__WorkEmail__c);
        
        
        listDI = [select Contact1Imported__c, Contact1ImportStatus__c, HouseholdAccountImported__c, 
            Contact2Imported__c, Contact2ImportStatus__c from DataImport__c order by Contact1_Lastname__c];
        system.assertEquals(3, listDI.size());
        system.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        system.assertEquals(listDI[1].Contact1Imported__c, listCon[0].Id);
        system.assertEquals(listDI[2].Contact1Imported__c, listCon[0].Id);
        system.assertNotEquals(null, listDI[0].HouseholdAccountImported__c);
        system.assertNotEquals(null, listDI[1].HouseholdAccountImported__c);
        system.assertNotEquals(null, listDI[2].HouseholdAccountImported__c);
        system.assertEquals(label.bdiMatched, listDI[0].Contact1ImportStatus__c);
        system.assertEquals(label.bdiMatched, listDI[1].Contact1ImportStatus__c);        
        system.assertEquals(label.bdiMatched, listDI[2].Contact1ImportStatus__c);        
    }

   /*********************************************************************************************************
    operation:
        import existing contacts within multiple di records in the same batch, using Custom Unique Id matching
    verify:
        all contacts matched
    **********************************************************************************************************/            
    static testMethod void ManyDIUniqueIdMatchingExistingContacts() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDIUniqueIdMatchingExistingContacts') return;
            
         // existing contacts
        list<Contact> listConExisting = new list<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='foo@bar.com', Title='c1Title'));
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@c1.com', Title='c1PrimeTitle'));
        insert listConExisting;
 
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@c1.com', Contact1_Title__c='c1Title'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@c1.com', Contact1_Title__c='c1PrimeTitle'));
        insert listDI;
        
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Contact_Custom_Unique_ID__c = 'Title';
        upsert diSettings;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Contact> listCon = [select Id, Name, Email, Title from Contact];
        system.assertEquals(2, listCon.size());
        
        listDI = [select Contact1Imported__c, Contact1ImportStatus__c, Contact2Imported__c, Contact2ImportStatus__c from DataImport__c order by Contact1_Title__c desc];
        system.assertEquals(2, listDI.size());
        system.assertEquals(listDI[0].Contact1Imported__c, listConExisting[0].Id);
        system.assertEquals(listDI[1].Contact1Imported__c, listConExisting[1].Id);
        system.assertEquals(label.bdiMatched, listDI[0].Contact1ImportStatus__c);
        system.assertEquals(label.bdiMatched, listDI[1].Contact1ImportStatus__c);        
    }

   /*********************************************************************************************************
    operation:
        import existing accounts within multiple di records in the same batch, using Custom Unique Id matching
    verify:
        all accounts matched
    **********************************************************************************************************/            
    static testMethod void ManyDIUniqueIdMatchingExistingAccounts() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDIUniqueIdMatchingExistingAccounts') return;
            
         // existing Accounts
        list<Account> listAccExisting = new list<Account>();
        listAccExisting.add(new Account(Name='foo', website='a1.com'));
        listAccExisting.add(new Account(Name='a1', website='nota1.com'));
        insert listAccExisting;
 
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Account1_Name__c='z', Account1_Website__c='a1.com'));
        listDI.add(new DataImport__c(Account1_Name__c='a1', Account1_Website__c='z.com'));
        insert listDI;
        
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Account_Custom_Unique_ID__c = 'Website';
        upsert diSettings;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Account> listAcc = [select Id, Name, Website from Account];
        system.assertEquals(2, listAcc.size());
        
        listDI = [select Account1Imported__c, Account1ImportStatus__c, Account2Imported__c, Account2ImportStatus__c from DataImport__c order by Account1_Website__c];
        system.assertEquals(2, listDI.size());
        system.assertEquals(listDI[0].Account1Imported__c, listAccExisting[0].Id);
        system.assertEquals(listDI[1].Account1Imported__c, listAccExisting[1].Id);
        system.assertEquals(label.bdiMatched, listDI[0].Account1ImportStatus__c);
        system.assertEquals(label.bdiMatched, listDI[1].Account1ImportStatus__c);        
    }

    /*********************************************************************************************************
    operation:
        import new contacts with a variety of emails 
    verify:
        correct preferred email set for contacts with only one email specified
        preferred email left null for contants with multiple emails specified
    **********************************************************************************************************/            
    static testMethod void testPreferredEmailAutoSetting() {
        if (strTestOnly != '*' && strTestOnly != 'testPreferredEmailAutoSetting') return;
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(newDI('c0', 'C0'));
        listDI.add(newDI('c1', 'C1'));
        listDI.add(newDI('c2', 'C2'));
        listDI.add(newDI('c3', 'C3'));
        // switch c1 to work email
        listDI[1].Contact1_Work_Email__c = 'c1@c1.com';
        listDI[1].Contact1_Personal_Email__c = null;
        // switch c2 to alt email
        listDI[2].Contact1_Alternate_Email__c = 'c2@c2.com';
        listDI[2].Contact1_Personal_Email__c = null;
        // c3 gets multiple emails
        listDI[3].Contact1_Work_Email__c = 'c3@c3.com';
        UTIL_Debug.debug('****DJH: listDI' + listDI);
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Contact> listCon = [select Id, Name, npe01__Preferred_Email__c from Contact order by Name];
        system.assertEquals(4, listCon.size());
        system.assertEquals('Personal', listCon[0].npe01__Preferred_Email__c);
        system.assertEquals('Work', listCon[1].npe01__Preferred_Email__c);
        system.assertEquals('Alternate', listCon[2].npe01__Preferred_Email__c);
        // turns out we can't assume this, because the org may have a value specified as default!
        //system.assertEquals(null, listCon[3].npe01__Preferred_Email__c);
      
        listDI = [select Contact1Imported__c, Contact1ImportStatus__c, Contact1_Preferred_Email__c from DataImport__c order by Contact1_Lastname__c];
        system.assertEquals(4, listDI.size());
        for (integer i = 0; i < 3; i++) {
            system.assertEquals(listDI[i].Contact1Imported__c, listCon[i].Id);
            system.assertEquals(label.bdiCreated, listDI[i].Contact1ImportStatus__c);
            system.assertEquals(listDI[i].Contact1_Preferred_Email__c, listCon[i].npe01__Preferred_Email__c);
        }
    }

    /*********************************************************************************************************
    operation:
        import new contacts with a variety of phones 
    verify:
        correct preferred phone set for contacts with only one phone specified
        preferred Phone left null for contants with multiple Phones specified
    **********************************************************************************************************/            
    static testMethod void testPreferredPhoneAutoSetting() {
        if (strTestOnly != '*' && strTestOnly != 'testPreferredPhoneAutoSetting') return;
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(newDI('c0', 'C0'));
        listDI.add(newDI('c1', 'C1'));
        listDI.add(newDI('c2', 'C2'));
        listDI.add(newDI('c3', 'C3'));
        listDI.add(newDI('c4', 'C4'));
        listDI[0].Contact1_Home_Phone__c = '000-0000';
        listDI[1].Contact1_Work_Phone__c = '111-1111';
        listDI[2].Contact1_Mobile_Phone__c = '222-2222';
        listDI[3].Contact1_Other_Phone__c = '333-3333';
        listDI[4].Contact1_Mobile_Phone__c = '444-4444';
        listDI[4].Contact1_Other_Phone__c = '555-5555';
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Contact> listCon = [select Id, Name, npe01__PreferredPhone__c from Contact order by Name];
        system.assertEquals(5, listCon.size());
        system.assertEquals('Home', listCon[0].npe01__PreferredPhone__c);
        system.assertEquals('Work', listCon[1].npe01__PreferredPhone__c);
        system.assertEquals('Mobile', listCon[2].npe01__PreferredPhone__c);
        system.assertEquals('Other', listCon[3].npe01__PreferredPhone__c);
        // turns out we can't assume this, because the org may have a value specified as default!
        //system.assertEquals(null, listCon[4].npe01__PreferredPhone__c);
      
        listDI = [select Contact1Imported__c, Contact1ImportStatus__c, Contact1_Preferred_Phone__c from DataImport__c order by Contact1_Lastname__c];
        system.assertEquals(5, listDI.size());
        for (integer i = 0; i < 4; i++) {
            system.assertEquals(listDI[i].Contact1Imported__c, listCon[i].Id);
            system.assertEquals(label.bdiCreated, listDI[i].Contact1ImportStatus__c);
            system.assertEquals(listDI[i].Contact1_Preferred_Phone__c, listCon[i].npe01__PreferredPhone__c);
        }
    }

    /*********************************************************************************************************
    operation:
        import contacts using different matching rules
    verify:
        only one contact created
    **********************************************************************************************************/            
    static testMethod void ManyDIMultiContactMatchRules1() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDIMultiContactMatchRules1') return;
        ManyDIMultiContactMatchRules('Firstname,Lastname,Email');
    }
    static testMethod void ManyDIMultiContactMatchRules2() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDIMultiContactMatchRules2') return;
        ManyDIMultiContactMatchRules('Lastname,Email');
    }
    static testMethod void ManyDIMultiContactMatchRules3() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDIMultiContactMatchRules3') return;
        ManyDIMultiContactMatchRules('Email');
    }
    static testMethod void ManyDIMultiContactMatchRules4() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDIMultiContactMatchRules4') return;
        ManyDIMultiContactMatchRules('Firstname,Lastname');
    }
    static testMethod void ManyDIMultiContactMatchRules5() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDIMultiContactMatchRules5') return;
        ManyDIMultiContactMatchRules('Firstname,Email');
    }
    static void ManyDIMultiContactMatchRules(string strRule) {            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Account1_Name__c='a0', Contact1_Firstname__c='c0', Contact1_Lastname__c='C0'));
        listDI.add(new DataImport__c(Account1_Name__c='a1', Contact1_Firstname__c=null, Contact1_Lastname__c='C1'));
        listDI.add(new DataImport__c(Account1_Name__c='a2', Contact1_Firstname__c='c2', Contact1_Lastname__c=null));
        listDI.add(new DataImport__c(Account1_Name__c='a3', Contact1_Firstname__c='c3', Contact1_Lastname__c='C3', Contact1_Personal_Email__c='c3@C3.com'));   
        
        // one additional di that will always match given the current rule.
        listDI.add(new DataImport__c(Account1_Name__c='a4', Contact1_Firstname__c='c3', Contact1_Lastname__c='C3', Contact1_Personal_Email__c='c3@C3.com'));                
        insert listDI;
          
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Contact_Matching_Rule__c = strRule;
        upsert diSettings;
 
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Contact> listCon = [select Id, Name from Contact];
        system.assertEquals(3, listCon.size());
        
        listDI = [select Account1_Name__c, Status__c, Contact1Imported__c, Contact1ImportStatus__c, Contact1_Lastname__c from DataImport__c order by Account1_Name__c];        
        system.assertEquals(5, listDI.size());
        for (integer i = 0; i < listDI.size(); i++) {
            if (listDI[i].Account1_Name__c == 'a2') {
                system.assertEquals(label.bdiErrorInvalidLastname, listDI[i].Contact1ImportStatus__c);                
                system.assertEquals(label.bdiFailed, listDI[i].Status__c);                
            } else if (listDI[i].Account1_Name__c == 'a4') {
                system.assertNotEquals(null, listDI[i].Contact1Imported__c);                
                system.assertEquals(label.bdiMatched, listDI[i].Contact1ImportStatus__c);                
                system.assertEquals(label.bdiImported, listDI[i].Status__c);                
            } else {
                system.assertNotEquals(null, listDI[i].Contact1Imported__c);                
                system.assertEquals(label.bdiCreated, listDI[i].Contact1ImportStatus__c);                
                system.assertEquals(label.bdiImported, listDI[i].Status__c);                
            }
            
        }
    }
    
    /*********************************************************************************************************
    operation:
        import contacts with some missing required fields
    verify:
        contacts with errors not created, failures logged in di records
        contacts without errors are created
    **********************************************************************************************************/            
    static testMethod void ManyDISomeInvalidContactData() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDISomeInvalidContactData') return;
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c=null, Contact1_Personal_Email__c='c0@foo.com'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Work_Email__c='c1@foo.com'));
        listDI.add(new DataImport__c(Contact2_Firstname__c='c2', Contact2_Lastname__c=null, Contact2_Alternate_Email__c='c2@foo.com'));
        listDI.add(new DataImport__c(Contact2_Firstname__c='c3', Contact2_Lastname__c='C3', Contact2_Alternate_Email__c='c3@foo.com'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c4', Contact1_Lastname__c='C4', Contact1_Work_Email__c='c1@foo.com', Contact2_Firstname__c='c5'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Contact> listCon = [select Id, Name from Contact order by Name];
        system.assertEquals(4, listCon.size());
        system.assertEquals('c1 C1', listCon[0].Name);

        listDI = [select Status__c, FailureInformation__c, 
            Contact1Imported__c, Contact1ImportStatus__c, Contact2Imported__c, Contact2ImportStatus__c 
            from DataImport__c order by Contact1ImportStatus__c];
        system.assertEquals(5, listDI.size());
        integer cC1 = 0;
        integer cC2 = 0;
        for (integer i = 0; i < listDI.size(); i++) {
            if (listDI[i].Contact1Imported__c != null) {
                system.assertEquals(label.bdiCreated, listDI[i].Contact1ImportStatus__c);
                cC1++;
            }
            if (listDI[i].Contact2Imported__c != null) {
                system.assertEquals(label.bdiCreated, listDI[i].Contact2ImportStatus__c);            
                cC2++;
            }
            if (listDI[i].Contact1Imported__c == null && listDI[i].Contact2Imported__c == null) {
                system.assertEquals(label.bdiFailed, listDI[i].Status__c);
                system.assertNotEquals(null, listDI[i].FailureInformation__c);    
                system.assert(listDI[i].FailureInformation__c.contains(label.bdiErrorInvalidLastname));                 
            }
        }
        system.assertEquals(2, cC1);
        system.assertEquals(2, cC2);
    }
    
    /*********************************************************************************************************
    operation:
        import contacts with some data that forces commit errors
    verify:
        contacts with errors not created, failures logged in di records
        contacts without errors are created
    **********************************************************************************************************/            
    static testMethod void ManyDITestContactDataErrorHandling() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDITestContactDataErrorHandling') return;
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='FailTest', Contact1_Personal_Email__c='c0@foo.com'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Work_Email__c='c1@foo.com'));
        listDI.add(new DataImport__c(Contact2_Firstname__c='c2', Contact2_Lastname__c='FailTest', Contact2_Alternate_Email__c='c2@foo.com'));
        listDI.add(new DataImport__c(Contact2_Firstname__c='c3', Contact2_Lastname__c='C3', Contact2_Alternate_Email__c='c3@foo.com'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c4', Contact1_Lastname__c='C4', Contact1_Work_Email__c='c1@foo.com', Contact2_Firstname__c='c5'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Contact> listCon = [select Id, Name from Contact order by Name];
        system.assertEquals(4, listCon.size());
        system.assertEquals('c1 C1', listCon[0].Name);

        listDI = [select Status__c, FailureInformation__c, 
            Contact1Imported__c, Contact1ImportStatus__c, Contact2Imported__c, Contact2ImportStatus__c 
            from DataImport__c order by Contact1ImportStatus__c];
        system.assertEquals(5, listDI.size());
        integer cC1 = 0;
        integer cC2 = 0;
        for (integer i = 0; i < listDI.size(); i++) {
            if (listDI[i].Contact1Imported__c != null) {
                system.assertEquals(label.bdiCreated, listDI[i].Contact1ImportStatus__c);
                cC1++;
            }
            if (listDI[i].Contact2Imported__c != null) {
                system.assertEquals(label.bdiCreated, listDI[i].Contact2ImportStatus__c);            
                cC2++;
            }
            if (listDI[i].Contact1Imported__c == null && listDI[i].Contact2Imported__c == null) {
                system.assertEquals(label.bdiFailed, listDI[i].Status__c);
                system.assertNotEquals(null, listDI[i].FailureInformation__c);    
                system.assert(listDI[i].Contact1ImportStatus__c != null || listDI[i].Contact2ImportStatus__c != null);                 
            }
        }
        system.assertEquals(2, cC1);
        system.assertEquals(2, cC2);
    }

    /*********************************************************************************************************
    operation:
        import accounts with some data that forces commit errors
    verify:
        accounts with errors not created, failures logged in di records
        accounts without errors are created
    **********************************************************************************************************/            
    static testMethod void ManyDITestAccountDataErrorHandling() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDITestAccountDataErrorHandling') return;
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Account1_Name__c='a0'));
        listDI.add(new DataImport__c(Account1_Name__c='FailTest1'));
        listDI.add(new DataImport__c(Account1_Name__c='a2'));
        listDI.add(new DataImport__c(Account1_Name__c='FailTest3'));
        listDI.add(new DataImport__c(Account1_Name__c='a4'));
        listDI.add(new DataImport__c(Account2_Name__c='a5'));
        listDI.add(new DataImport__c(Account2_Name__c='FailTest6'));
        listDI.add(new DataImport__c(Account2_Name__c='a7'));
        listDI.add(new DataImport__c(Account2_Name__c='FailTest8'));
        listDI.add(new DataImport__c(Account2_Name__c='a9'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Account> listAcc = [select Id, Name from Account order by Name];
        system.assertEquals(6, listAcc.size());

        listDI = [select Status__c, FailureInformation__c, Account1Imported__c, Account1ImportStatus__c,
            Account2Imported__c, Account2ImportStatus__c from DataImport__c];
        system.assertEquals(10, listDI.size());
        integer cA1 = 0;
        integer cA2 = 0;
        for (integer i = 0; i < listDI.size(); i++) {
            if (listDI[i].Account1Imported__c != null) {
                system.assertEquals(label.bdiCreated, listDI[i].Account1ImportStatus__c);
                cA1++;
            }
            if (listDI[i].Account2Imported__c != null) {
                system.assertEquals(label.bdiCreated, listDI[i].Account2ImportStatus__c);            
                cA2++;
            }
            if (listDI[i].Account1Imported__c == null && listDI[i].Account2Imported__c == null) {
                system.assertEquals(label.bdiFailed, listDI[i].Status__c);
                system.assertNotEquals(null, listDI[i].FailureInformation__c);    
                system.assert(listDI[i].Account1ImportStatus__c != null || listDI[i].Account2ImportStatus__c != null);                 
            }
        }
        system.assertEquals(3, cA1);
        system.assertEquals(3, cA2);
    }

    /*********************************************************************************************************
    operation:
        import donations with some data that forces commit errors
    verify:
        donations with errors not created, failures logged in di records
        donations without errors are created
    **********************************************************************************************************/            
    static testMethod void ManyDITestDonationDataErrorHandling() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDITestDonationDataErrorHandling') return;
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Account1_Name__c='a0', Donation_Donor__c='Account1', Donation_Amount__c=10));
        listDI.add(new DataImport__c(Account1_Name__c='a0', Donation_Donor__c='Account1', Donation_Amount__c=20, Donation_Name__c='FailTest1'));
        listDI.add(new DataImport__c(Account1_Name__c='a0', Donation_Donor__c='FailTest2', Donation_Amount__c=30));
        listDI.add(new DataImport__c(Account1_Name__c='a0', Donation_Donor__c='Contact1', Donation_Amount__c=40)); // will fail.
        listDI.add(new DataImport__c(Account1_Name__c='a0', Donation_Donor__c='Account1', Donation_Amount__c=50, Donation_Record_Type_Name__c='FailTest3'));
        listDI.add(new DataImport__c(Account1_Name__c='a0', Donation_Donor__c='Account1', Donation_Amount__c=70));         
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Opportunity> listOpp = [select Id, Name, Amount from Opportunity order by Amount];
        system.assertEquals(2, listOpp.size());

        listDI = [select Status__c, FailureInformation__c, DonationImported__c, DonationImportStatus__c from DataImport__c];
        system.assertEquals(6, listDI.size());
        integer cOpp = 0;
        for (integer i = 0; i < listDI.size(); i++) {
            if (listDI[i].DonationImported__c != null) {
                system.assertEquals(label.bdiCreated, listDI[i].DonationImportStatus__c);
                cOpp++;
            } else {
                system.assertEquals(label.bdiFailed, listDI[i].Status__c);
                system.assertNotEquals(null, listDI[i].FailureInformation__c);    
                system.assertNotEquals(null, listDI[i].DonationImportStatus__c);    
            }
        }
        system.assertEquals(cOpp, listOpp.size());
    }

    /*********************************************************************************************************
    operation:
        import donations with campaigns that have some data that forces commit errors
    verify:
        campaigns with errors not created, failures logged in di records
        campaigns without errors are created
    **********************************************************************************************************/            
    static testMethod void ManyDITestCampaignDataErrorHandling() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDITestCampaignDataErrorHandling') return;
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Account1_Name__c='a0', Donation_Donor__c='Account1', Donation_Amount__c=10, Donation_Campaign_Name__c='cmp1'));
        listDI.add(new DataImport__c(Account1_Name__c='a1', Donation_Donor__c='Account1', Donation_Amount__c=20, Donation_Campaign_Name__c='FailTest1'));
        listDI.add(new DataImport__c(Account1_Name__c='a2', Donation_Donor__c='Account1', Donation_Amount__c=30, Donation_Campaign_Name__c='cmp1'));
        listDI.add(new DataImport__c(Account1_Name__c='a3', Donation_Donor__c='Account1', Donation_Amount__c=40, Donation_Campaign_Name__c='cmp2'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Opportunity> listOpp = [select Id, Name, Amount from Opportunity order by Amount];
        system.assertEquals(3, listOpp.size());
        list<Campaign> listCmp = [select Id, Name from Campaign];
        system.assertEquals(2, listCmp.size());

        listDI = [select Status__c, FailureInformation__c, DonationImported__c, DonationImportStatus__c, Donation_Campaign_Name__c from DataImport__c];
        system.assertEquals(4, listDI.size());
        for (integer i = 0; i < listDI.size(); i++) {
            if (listDI[i].Donation_Campaign_Name__c == 'FailTest1') {
                system.assertEquals(label.bdiFailed, listDI[i].Status__c);
                system.assertNotEquals(label.bdiCreated, listDI[i].DonationImportStatus__c);
                system.assertEquals(null, listDI[i].DonationImported__c);
            } else {
                system.assertEquals(label.bdiImported, listDI[i].Status__c);
                system.assertEquals(null, listDI[i].FailureInformation__c);    
                system.assertEquals(label.bdiCreated, listDI[i].DonationImportStatus__c);    
            }
        }
    }

    /*********************************************************************************************************
    operation:
        import addresses with some data that forces commit errors
    verify:
        addresses with errors not created, failures logged in di records
        addresses without errors are created
    **********************************************************************************************************/            
    static testMethod void ManyDITestAddressDataErrorHandling() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDITestAddressDataErrorHandling') return;
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c='C0', Contact1_Personal_Email__c='c0@foo.com',Home_City__c='Seattle'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@foo.com',Home_City__c='FailTest1'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c2', Contact1_Lastname__c='C2', Contact1_Personal_Email__c='c2@foo.com',Home_City__c='Portland'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Address__c> listAddr = [select Id, MailingCity__c from Address__c];
        system.assertEquals(2, listAddr.size());

        listDI = [select Status__c, FailureInformation__c, HomeAddressImported__c, HomeAddressImportStatus__c from DataImport__c];
        system.assertEquals(3, listDI.size());
        integer cAddr = 0;
        for (integer i = 0; i < listDI.size(); i++) {
            if (listDI[i].HomeAddressImported__c != null) {
                system.assertEquals(label.bdiCreated, listDI[i].HomeAddressImportStatus__c);
                cAddr++;
            } else {
                system.assertEquals(label.bdiFailed, listDI[i].Status__c);
                system.assertNotEquals(null, listDI[i].FailureInformation__c);    
                system.assertNotEquals(null, listDI[i].HomeAddressImportStatus__c);    
            }
        }
        system.assertEquals(cAddr, listAddr.size());
    }

    /*********************************************************************************************************
    operation:
        import multiple di records with C2 not fully providing match critera, in the same batch
    verify:
        duplicate C2's not created
    **********************************************************************************************************/            
    static testMethod void TwoDINewC2PartialMatch() {
        if (strTestOnly != '*' && strTestOnly != 'TwoDINewC2PartialMatch') return;
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@C1.com',
            Contact2_Firstname__c='c2'));   
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@C1.com',
            Contact2_Firstname__c='c2'));   
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Contact> listCon = [select Id, Name from Contact order by Name];
        system.assertEquals(2, listCon.size());
        system.assertNotEquals(listCon[1].Name, listCon[0].Name);

        listDI = [select Contact1Imported__c, Contact1ImportStatus__c, HouseholdAccountImported__c, 
            Contact2Imported__c, Contact2ImportStatus__c from DataImport__c order by Contact1Imported__c];
        system.assertEquals(2, listDI.size());
        system.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        system.assertEquals(listDI[1].Contact1Imported__c, listCon[0].Id);
        system.assertEquals(listDI[0].Contact2Imported__c, listCon[1].Id);
        system.assertEquals(listDI[1].Contact2Imported__c, listCon[1].Id);
        system.assertEquals(label.bdiCreated, listDI[0].Contact1ImportStatus__c);
        system.assertEquals(label.bdiCreated, listDI[0].Contact2ImportStatus__c);
        system.assertEquals(label.bdiMatched, listDI[1].Contact1ImportStatus__c);        
        system.assertEquals(label.bdiMatched, listDI[1].Contact2ImportStatus__c);        
    }

    /*********************************************************************************************************
    operation:
        import multiple di records with Existing C2 not fully providing match critera, in the same batch
    verify:
        duplicate C2's not created
    **********************************************************************************************************/            
    static testMethod void TwoDIExistingC2PartialMatch() {
        if (strTestOnly != '*' && strTestOnly != 'TwoDIExistingC2PartialMatch') return;
            
         // existing contacts in same household
        Account hh = new Account(Name='household', npe01__SYSTEM_AccountType__c=CAO_Constants.HH_ACCOUNT_TYPE);
        insert hh;
        list<Contact> listConExisting = new list<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com', AccountId=hh.Id));
        listConExisting.add(new Contact(Firstname='c2', Lastname='C2', Email='c2@C2.com', AccountId=hh.Id));
        insert listConExisting;
 
        // data import records
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@C1.com',
            Contact2_Firstname__c='c2'));   
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@C1.com',
            Contact2_Firstname__c='c2'));   
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        list<Contact> listCon = [select Id, Name from Contact order by Name];
        system.assertEquals(2, listCon.size());
        system.assertNotEquals(listCon[1].Name, listCon[0].Name);

        listDI = [select Contact1Imported__c, Contact1ImportStatus__c, HouseholdAccountImported__c, 
            Contact2Imported__c, Contact2ImportStatus__c from DataImport__c order by Contact1Imported__c];
        system.assertEquals(2, listDI.size());
        system.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        system.assertEquals(listDI[1].Contact1Imported__c, listCon[0].Id);
        system.assertEquals(listDI[0].Contact2Imported__c, listCon[1].Id);
        system.assertEquals(listDI[1].Contact2Imported__c, listCon[1].Id);
        system.assertEquals(label.bdiMatched, listDI[0].Contact1ImportStatus__c);
        system.assertEquals(label.bdiMatched, listDI[0].Contact2ImportStatus__c);
        system.assertEquals(label.bdiMatched, listDI[1].Contact1ImportStatus__c);        
        system.assertEquals(label.bdiMatched, listDI[1].Contact2ImportStatus__c);        
    }

}