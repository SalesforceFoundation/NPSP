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
    	   Contact1_std_Firstname__c = firstname,
    	   Contact1_std_Lastname__c = lastname,
    	   Contact1_npe01_HomeEmail__c = firstname + '@' + lastname + '.com'
        );
    }

    // utility to create a new di record    
    static DataImport__c newDI(string firstname, string lastname, string firstname2, string lastname2) {
        return new DataImport__c(
           Contact1_std_Firstname__c = firstname,
           Contact1_std_Lastname__c = lastname,
           Contact1_npe01_HomeEmail__c = firstname + '@' + lastname + '.com',
           Contact2_std_Firstname__c = firstname2,
           Contact2_std_Lastname__c = lastname2,
           Contact2_npe01_HomeEmail__c = firstname2 + '@' + lastname2 + '.com'
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
        
        listDI = [select Contact1Imported__c, Contact1ImportStatus__c, Contact2Imported__c, Contact2ImportStatus__c from DataImport__c];
        system.assertEquals(1, listDI.size());
        system.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        system.assertEquals(listDI[0].Contact2Imported__c, listCon[0].Id);
        system.assertEquals('Created', listDI[0].Contact1ImportStatus__c);
        system.assertEquals('Matched', listDI[0].Contact2ImportStatus__c);        
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

        listDI = [select Contact1Imported__c, Contact1ImportStatus__c, Contact2Imported__c, Contact2ImportStatus__c from DataImport__c];
        system.assertEquals(1, listDI.size());
        system.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        system.assertEquals(listDI[0].Contact2Imported__c, listCon[1].Id);
        system.assertEquals('Created', listDI[0].Contact1ImportStatus__c);
        system.assertEquals('Created', listDI[0].Contact2ImportStatus__c);        
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

        listDI = [select Contact1Imported__c, Contact1ImportStatus__c, Contact2Imported__c, Contact2ImportStatus__c from DataImport__c order by Contact1ImportStatus__c];
        system.assertEquals(2, listDI.size());
        system.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        system.assertEquals(listDI[1].Contact1Imported__c, listCon[0].Id);
        system.assertEquals('Created', listDI[0].Contact1ImportStatus__c);
        system.assertEquals('Matched', listDI[1].Contact1ImportStatus__c);        
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

        listDI = [select Contact1Imported__c, Contact1ImportStatus__c, Contact2Imported__c, Contact2ImportStatus__c from DataImport__c order by Contact1Imported__c];
        system.assertEquals(2, listDI.size());
        system.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        system.assertEquals(listDI[1].Contact1Imported__c, listCon[1].Id);
        system.assertEquals('Created', listDI[0].Contact1ImportStatus__c);
        system.assertEquals('Created', listDI[1].Contact1ImportStatus__c);        
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
        
        listDI = [select Contact1Imported__c, Contact1ImportStatus__c, Contact2Imported__c, Contact2ImportStatus__c from DataImport__c];
        system.assertEquals(1, listDI.size());
        system.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        system.assertEquals(listDI[0].Contact2Imported__c, listCon[1].Id);
        system.assertEquals('Matched', listDI[0].Contact1ImportStatus__c);
        system.assertEquals('Matched', listDI[0].Contact2ImportStatus__c);        
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
        listDI.add(new DataImport__c(Account1_std_Name__c='A1', Account2_std_Name__c='A2'));
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
        system.assertEquals('Created', listDI[0].Account1ImportStatus__c);
        system.assertEquals('Created', listDI[0].Account2ImportStatus__c);        
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
        listDI.add(new DataImport__c(Account1_std_Name__c='A1', Account2_std_Name__c='A1'));
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
        system.assertEquals('Created', listDI[0].Account1ImportStatus__c);
        system.assertEquals('Matched', listDI[0].Account2ImportStatus__c);        
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
        listDI.add(new DataImport__c(Account1_std_Name__c='A1'));
        listDI.add(new DataImport__c(Account1_std_Name__c='A1'));
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
        system.assertEquals('Created', listDI[0].Account1ImportStatus__c);
        system.assertEquals('Matched', listDI[1].Account1ImportStatus__c);        
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
        listDI.add(new DataImport__c(Account1_std_Name__c='A1'));
        listDI.add(new DataImport__c(Account1_std_Name__c='A2'));
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
        system.assertEquals('Matched', listDI[0].Account1ImportStatus__c);
        system.assertEquals('Matched', listDI[1].Account1ImportStatus__c);        
    }

    /*********************************************************************************************************
    operation:
        import contacts with Preferred Email set
    verify:
        ensure the appropriate contact email field gets copied into the standard email field.
    **********************************************************************************************************/            
    static testMethod void ThreeDINewContactsWithPreferredEmail() {
        if (strTestOnly != '*' && strTestOnly != 'ThreeDINewContactsWithPreferredEmail') return;
            
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(newDI('c1', 'C1'));
        listDI.add(newDI('c2', 'C2'));
        listDI.add(newDI('c3', 'C3'));
        listDI[0].Contact1_npe01_Preferred_Email__c = 'Home';
        listDI[0].Contact1_npe01_HomeEmail__c = 'c1@home.com';
        listDI[1].Contact1_npe01_Preferred_Email__c = 'Work';
        listDI[1].Contact1_npe01_WorkEmail__c = 'c2@work.com';
        listDI[2].Contact1_npe01_Preferred_Email__c = 'Alternate';
        listDI[2].Contact1_npe01_HomeEmail__c = 'c3@alt.com';
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

}