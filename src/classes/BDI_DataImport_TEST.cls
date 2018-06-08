/*
    Copyright (c) 2014 Salesforce.org
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
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description tests specific to the Batch Data Importer batch processing and record creation
*/

@isTest
public with sharing class BDI_DataImport_TEST {

    /*******************************************************************************************************
    * @description if you only want to run one test in this class, fill in its name here.
    * if you want to run all tests, then use '*'
    */
    private static string strTestOnly = '*';
    
    /*******************************************************************************************************
    * @description creates a new di record for tests
    * @param firstname the firstname to specify for Contact1
    * @param lastname the lastname to specify for Contact1
    * @return DataImport__c the new Data Import record
    */
    public static DataImport__c newDI(string firstname, string lastname) {
        return new DataImport__c(
           Contact1_Firstname__c = firstname,
           Contact1_Lastname__c = lastname,
           Contact1_Personal_Email__c = firstname + '@' + lastname + '.com'
        );
    }

    /*******************************************************************************************************
    * @description creates a new di record for tests
    * @param firstname the firstname to specify for Contact1
    * @param lastname the lastname to specify for Contact1
    * @param firstname2 the firstname to specify for Contact2
    * @param lastname2 the lastname to specify for Contact2
    * @return DataImport__c the new Data Import record
    */
    public static DataImport__c newDI(string firstname, string lastname, string firstname2, string lastname2) {
        return new DataImport__c(
           Contact1_Firstname__c = firstname,
           Contact1_Lastname__c = lastname,
           Contact1_Personal_Email__c = (lastname == null ? null : firstname + '@' + lastname + '.com'),
           Contact2_Firstname__c = firstname2,
           Contact2_Lastname__c = lastname2,
           Contact2_Personal_Email__c = (lastname2 == null ? null : firstname2 + '@' + lastname2 + '.com')
        );
    }

    /*********************************************************************************************************
    * @description operation
    *     import matching contacts within the same di record 
    * verify:
    *     only one contact created
    **********************************************************************************************************/            
    static testMethod void OneDIDuplicateNewContacts() {
        if (strTestOnly != '*' && strTestOnly != 'OneDIDuplicateNewContacts') return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(newDI('c1', 'C1', 'c1', 'C1'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(1, listCon.size());
        System.assertEquals('c1 C1', listCon[0].Name);
        
        listDI = getDIs();
        System.assertEquals(1, listDI.size());
        System.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(listDI[0].Contact2Imported__c, listCon[0].Id);
        System.assertNotEquals(null, listDI[0].HouseholdAccountImported__c);
        System.assertEquals(label.bdiCreated, listDI[0].Contact1ImportStatus__c);
        System.assertEquals(label.bdiMatched, listDI[0].Contact2ImportStatus__c);        
    }
    
    /*********************************************************************************************************
    * @description operation
    *        import different contacts within the same di record  
    * verify: 
    *        two contacts created
    **********************************************************************************************************/            
    static testMethod void OneDITwoNewContacts() {
        if (strTestOnly != '*' && strTestOnly != 'OneDITwoNewContacts') return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(newDI('c1', 'C1', 'c2', 'C2'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(2, listCon.size());
        System.assertNotEquals(listCon[1].Name, listCon[0].Name);

        listDI = getDIs();
        System.assertEquals(1, listDI.size());
        System.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(listDI[0].Contact2Imported__c, listCon[1].Id);
        System.assertNotEquals(null, listDI[0].HouseholdAccountImported__c);        
        System.assertEquals(label.bdiCreated, listDI[0].Contact1ImportStatus__c);
        System.assertEquals(label.bdiCreated, listDI[0].Contact2ImportStatus__c);        
    }

    /*********************************************************************************************************
    * @description operation
    *        import matching contacts within multiple di records in the same batch  
    * verify: 
    *        only one contact created
    **********************************************************************************************************/            
    static testMethod void TwoDIDuplicateNewContacts() {
        if (strTestOnly != '*' && strTestOnly != 'TwoDIDuplicateNewContacts') return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(newDI('c1', 'C1'));
        listDI.add(newDI('c1', 'C1'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(1, listCon.size());
        System.assertEquals('c1 C1', listCon[0].Name);

        listDI = getDIs();
        System.assertEquals(2, listDI.size());
        System.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(listDI[1].Contact1Imported__c, listCon[0].Id);
        System.assertNotEquals(null, listDI[0].HouseholdAccountImported__c);
        System.assertNotEquals(null, listDI[1].HouseholdAccountImported__c);
        System.assertEquals(label.bdiCreated, listDI[0].Contact1ImportStatus__c);
        System.assertEquals(label.bdiMatched, listDI[1].Contact1ImportStatus__c);        
    }
    
    /*********************************************************************************************************
    * @description operation
    *        import different contacts within multiple di records in the same batch 
    * verify: 
    *        two contacts created
    **********************************************************************************************************/            
    static testMethod void TwoDITwoNewContacts() {
        if (strTestOnly != '*' && strTestOnly != 'TwoDITwoNewContacts') return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(newDI('c1', 'C1'));
        listDI.add(newDI('c2', 'C2'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(2, listCon.size());
        System.assertNotEquals(listCon[1].Name, listCon[0].Name);

        listDI = getDIs();
        System.assertEquals(2, listDI.size());
        System.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(listDI[1].Contact1Imported__c, listCon[1].Id);
        System.assertNotEquals(null, listDI[0].HouseholdAccountImported__c);
        System.assertNotEquals(null, listDI[1].HouseholdAccountImported__c);
        System.assertEquals(label.bdiCreated, listDI[0].Contact1ImportStatus__c);
        System.assertEquals(label.bdiCreated, listDI[1].Contact1ImportStatus__c);        
    }

    /*********************************************************************************************************
    * @description operation
    *        import matching contacts within multiple di records in the same batch  
    * verify: 
    *        only two contacts created
    *        only 1 household account created
    **********************************************************************************************************/            
    static testMethod void TwoDIDuplicateNewContactsDifferentOrder() {
        if (strTestOnly != '*' && strTestOnly != 'TwoDIDuplicateNewContactsDifferentOrder') return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(newDI('c1', 'C1', 'c2', 'C2'));
        listDI.add(newDI('c2', 'C2'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(2, listCon.size());
        System.assertEquals('c1 C1', listCon[0].Name);
        System.assertEquals('c2 C2', listCon[1].Name);
        
        // verify only one household account
        List<Account> listAcc = getAccounts();
        // because c2 is first created as a contact1, it will get a hh account, that will
        // later get orphaned when we move c2 to c1's hh account.
        System.assertEquals(2, listAcc.size());
        System.assertEquals(listAcc[0].Id, listCon[0].AccountId);
        System.assertEquals(listAcc[0].Id, listCon[1].AccountId);

        listDI = getDIs();
        System.assertEquals(2, listDI.size());
        System.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(listDI[1].Contact1Imported__c, listCon[1].Id);
        System.assertNotEquals(null, listDI[0].HouseholdAccountImported__c);
        System.assertNotEquals(null, listDI[1].HouseholdAccountImported__c);
        System.assertEquals(label.bdiCreated, listDI[0].Contact1ImportStatus__c);
        System.assertEquals(label.bdiCreated, listDI[1].Contact1ImportStatus__c);        
        System.assertEquals(label.bdiMatched, listDI[0].Contact2ImportStatus__c);        
    }

    /*********************************************************************************************************
    * @description operation
    *        import existing contacts within the same di record  
    * verify: 
    *        two contacts matched
    **********************************************************************************************************/            
    static testMethod void OneDITwoExistingContacts() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'OneDITwoExistingContacts') return;
            
        // existing contacts
        List<Contact> listConExisting = new List<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com'));
        listConExisting.add(new Contact(Firstname='c2', Lastname='C2', Email='c2@C2.com'));
        insert listConExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);
        
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(newDI('c1', 'C1', 'c2', 'C2'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(2, listCon.size());
        System.assertNotEquals(listCon[1].Name, listCon[0].Name);
        
        listDI = getDIs();
        System.assertEquals(1, listDI.size());
        System.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(listDI[0].Contact2Imported__c, listCon[1].Id);
        System.assertNotEquals(null, listDI[0].HouseholdAccountImported__c);
        System.assertEquals(label.bdiMatched, listDI[0].Contact1ImportStatus__c);
        System.assertEquals(label.bdiMatched, listDI[0].Contact2ImportStatus__c);        
    }

    /*********************************************************************************************************
    * @description operation
    *        import existing contacts that match a 1x1 contact 
    * verify: 
    *        error given, di not processed.
    **********************************************************************************************************/            
    static testMethod void OneDIExistingContacts1x1() {
        if (strTestOnly != '*' && strTestOnly != 'OneDIExistingContacts1x1') return;
            
        // existing 1x1 contact
        UTIL_UnitTestData_TEST.createAccountContactTestData(CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE, 1, 1, 0);   
        List<Contact> listConExisting = getContacts();
        System.assertEquals(1, listConExisting.size());
        System.assertEquals(CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE, listConExisting[0].Account.npe01__System_AccountType__c);
        System.assertEquals('TestFirstname00 TestLastname00', listConExisting[0].Name);
        listConExisting[0].email = 'foo@bar.com';
        update listConExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);
        
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(newDI('TestFirstname00', 'TestLastname00', 'c2', 'C2'));
        listDI[0].Contact1_Personal_Email__c = 'foo@bar.com';
        listDI[0].Home_City__c = 'Seattle';
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(1, listCon.size());
        System.assertEquals('TestFirstname00 TestLastname00', listCon[0].Name);
        
        listDI = getDIs();
        System.assertEquals(1, listDI.size());
        System.assertEquals(null, listDI[0].Contact1Imported__c);
        System.assertEquals(null, listDI[0].Contact2Imported__c);
        System.assertEquals(null, listDI[0].HouseholdAccountImported__c);
        System.assertEquals(label.bdiErrorNonHHAccountContact, listDI[0].Contact1ImportStatus__c);
        System.assertEquals(null, listDI[0].Contact2ImportStatus__c);     
        List<Address__c> listAddr = getAddresses();   
        System.assertEquals(0, listAddr.size());
    }

    /*********************************************************************************************************
    * @description operation
    *        import different accounts within the same di record  
    * verify: 
    *        two accounts created
    **********************************************************************************************************/            
    static testMethod void OneDITwoNewAccounts() {
        if (strTestOnly != '*' && strTestOnly != 'OneDITwoNewAccounts') return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(new DataImport__c(Account1_Name__c='A1', Account2_Name__c='A2'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Account> listAcc = getAccounts();
        System.assertEquals(2, listAcc.size());
        System.assertNotEquals(listAcc[1].Name, listAcc[0].Name);

        listDI = getDIs();
        System.assertEquals(1, listDI.size());
        System.assertEquals(listDI[0].Account1Imported__c, listAcc[0].Id);
        System.assertEquals(listDI[0].Account2Imported__c, listAcc[1].Id);
        System.assertEquals(label.bdiCreated, listDI[0].Account1ImportStatus__c);
        System.assertEquals(label.bdiCreated, listDI[0].Account2ImportStatus__c);        
    }

    /*********************************************************************************************************
    * @description operation
    *        import matching accounts within the same di record  
    * verify: 
    *        one accounts created
    **********************************************************************************************************/            
    static testMethod void OneDITwoSameAccounts() {
        if (strTestOnly != '*' && strTestOnly != 'OneDITwoSameAccounts') return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(new DataImport__c(Account1_Name__c='A1', Account2_Name__c='A1'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Account> listAcc = getAccounts();
        System.assertEquals(1, listAcc.size());

        listDI = getDIs();
        System.assertEquals(1, listDI.size());
        System.assertEquals(listDI[0].Account1Imported__c, listAcc[0].Id);
        System.assertEquals(listDI[0].Account2Imported__c, listAcc[0].Id);
        System.assertEquals(label.bdiCreated, listDI[0].Account1ImportStatus__c);
        System.assertEquals(label.bdiMatched, listDI[0].Account2ImportStatus__c);        
    }

    /*********************************************************************************************************
    * @description operation
    *        import matching accounts in different di records  
    * verify: 
    *        one account created
    **********************************************************************************************************/            
    static testMethod void TwoDISameAccounts() {
        if (strTestOnly != '*' && strTestOnly != 'TwoDISameAccounts') return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(new DataImport__c(Account1_Name__c='A1'));
        listDI.add(new DataImport__c(Account1_Name__c='A1'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Account> listAcc = getAccounts();
        System.assertEquals(1, listAcc.size());

        listDI = getDIs();
        System.assertEquals(2, listDI.size());
        System.assertEquals(listDI[0].Account1Imported__c, listAcc[0].Id);
        System.assertEquals(listDI[1].Account1Imported__c, listAcc[0].Id);
        System.assertEquals(label.bdiCreated, listDI[0].Account1ImportStatus__c);
        System.assertEquals(label.bdiMatched, listDI[1].Account1ImportStatus__c);
    }

    /*********************************************************************************************************
    * @description operation
    *        import existing accounts  
    * verify: 
    *        no accounts created, just matched
    **********************************************************************************************************/
    static testMethod void TwoDIExistingAccounts() {
        if (strTestOnly != '*' && strTestOnly != 'TwoDIExistingAccounts') return;
            
        List<Account> listAcc = new List<Account>();
        listAcc.add(new Account(name='A1', BillingCity='Seattle'));
        listAcc.add(new Account(name='A2'));
        insert listAcc;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listAcc);

        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(new DataImport__c(Account1_Name__c='A1', Account1_City__c='Seattle'));
        listDI.add(new DataImport__c(Account1_Name__c='A2'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        listAcc = getAccounts();
        System.assertEquals(2, listAcc.size());

        listDI = getDIs();
        System.assertEquals(2, listDI.size());
        System.assertEquals(listDI[0].Account1Imported__c, listAcc[0].Id);
        System.assertEquals(listDI[1].Account1Imported__c, listAcc[1].Id);
        System.assertEquals(label.bdiMatched, listDI[0].Account1ImportStatus__c);
        System.assertEquals(label.bdiMatched, listDI[1].Account1ImportStatus__c);
    }

    /*********************************************************************************************************
    * @description operation
    *        import existing accounts, matched by Salesforce Id  
    * verify: 
    *        no accounts created, just matched
    **********************************************************************************************************/
    static testMethod void TwoDIExistingAccountsSalesforceId() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'TwoDIExistingAccountsSalesforceId') return;
            
        List<Account> listAcc = new List<Account>();
        listAcc.add(new Account(name='A1'));
        listAcc.add(new Account(name='A2'));
        insert listAcc;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listAcc);

        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', 
            Account1Imported__c=listAcc[0].Id));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C2', Contact2_Firstname__c='c2', 
            Account1Imported__c=listAcc[0].Id, Account2Imported__c=listAcc[1].Id));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        listAcc = getOrganizations();
        System.assertEquals(2, listAcc.size());

        listDI = getDIs();
        System.assertEquals(2, listDI.size());
        System.assertEquals(listDI[0].Account1Imported__c, listAcc[0].Id);
        System.assertEquals(listDI[1].Account1Imported__c, listAcc[0].Id);
        System.assertEquals(listDI[1].Account2Imported__c, listAcc[1].Id);
        System.assertEquals(label.bdiMatched, listDI[0].Account1ImportStatus__c);
        System.assertEquals(label.bdiMatched, listDI[1].Account1ImportStatus__c);        
        System.assertEquals(label.bdiMatched, listDI[1].Account2ImportStatus__c);        
    }

    /*********************************************************************************************************
    operation:
    *        import contacts with Preferred Email set 
    * verify: 
    *        ensure the appropriate contact email field gets copied into the standard email field.
    **********************************************************************************************************/
    /** can't use this test because it relies on our workflow rules being active, which we can't enforce.
    static testMethod void ThreeDINewContactsWithPreferredEmail() {
        if (strTestOnly != '*' && strTestOnly != 'ThreeDINewContactsWithPreferredEmail') return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
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
        List<Contact> listCon = getContacts();
        System.assertEquals(3, listCon.size());
        System.assertEquals('c1 C1', listCon[0].Name);
        System.assertEquals('c1@home.com', listCon[0].Email);
        System.assertEquals('c2 C2', listCon[1].Name);
        System.assertEquals('c2@work.com', listCon[1].Email);
        System.assertEquals('c3 C3', listCon[2].Name);
        System.assertEquals('c3@alt.com', listCon[2].Email);        
    }
    ***************/

    /*********************************************************************************************************
    * @description operation
    *        import contacts with accounts 
    * verify: 
    *        contacts created
    *        accounts created
    *        affiliations created between contacts and accounts
    **********************************************************************************************************/            
    static testMethod void TwoDIAffiliations() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'TwoDIAffiliations') return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
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
        Map<Id, Contact> contactById = new Map<Id, Contact>(getContacts());
        System.assertEquals(4, contactById.size());
        
        listDI = getDIs();

        for (DataImport__c di : listDI) {
            System.assert(contactById.containsKey(di.Contact1Imported__c));
            System.assertEquals(di.Contact1_Firstname__c + ' ' + di.Contact1_Lastname__c, contactById.get(di.Contact1Imported__c).Name);
            System.assert(contactById.containsKey(di.Contact2Imported__c));
            System.assertEquals(di.Contact2_Firstname__c + ' ' + di.Contact2_Lastname__c, contactById.get(di.Contact2Imported__c).Name);
            System.assertNotEquals(null, contactById.get(di.Contact1Imported__c).AccountId);
            System.assertNotEquals(null, contactById.get(di.Contact2Imported__c).AccountId);
        }
        
        List<Account> listAcc = getOrganizations();
        System.assertEquals(2, listAcc.size());
        System.assertEquals(contactById.get(listDI[0].Contact1Imported__c).Primary_Affiliation__c, listAcc[0].Id);
        System.assertEquals(contactById.get(listDI[0].Contact2Imported__c).Primary_Affiliation__c, null);
        System.assertEquals(contactById.get(listDI[1].Contact1Imported__c).Primary_Affiliation__c, null);
        System.assertEquals(contactById.get(listDI[1].Contact2Imported__c).Primary_Affiliation__c, listAcc[1].Id);
        
        list<npe5__Affiliation__c> listAffl = getAffiliations();
        System.assertEquals(2, listAffl.size());
        System.assertEquals(listDI[0].Contact1Imported__c, listAffl[0].npe5__Contact__c);
        System.assertEquals(listDI[1].Contact2Imported__c, listAffl[1].npe5__Contact__c);

    }

    /*********************************************************************************************************
    * @description operation
    *        import contacts with home addresses  
    * verify: 
    *        address objects created
    *        contacts' mailing address set
    *        hh accounts' billing address set
    **********************************************************************************************************/            
    static testMethod void TwoDIHomeAddresses() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'TwoDIHomeAddresses') return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
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
        Map<Id, Contact> contactById = new Map<Id, Contact>(getContacts());
        System.assertEquals(4, contactById.size());
        listDI = getDIs();
        System.assertEquals(2, listDI.size());

        for (DataImport__c di : listDI) {
            System.assert(contactById.containsKey(di.Contact1Imported__c));
            System.assertEquals(di.Contact1_Firstname__c + ' ' + di.Contact1_Lastname__c, contactById.get(di.Contact1Imported__c).Name);
            System.assertEquals(di.Home_City__c, contactById.get(di.Contact1Imported__c).MailingCity);
            System.assert(contactById.containsKey(di.Contact2Imported__c));
            System.assertEquals(di.Contact2_Firstname__c + ' ' + di.Contact2_Lastname__c, contactById.get(di.Contact2Imported__c).Name);
            System.assertEquals(di.Home_City__c, contactById.get(di.Contact2Imported__c).MailingCity);
            System.assertNotEquals(null, contactById.get(di.Contact1Imported__c).AccountId);
            System.assertNotEquals(null, contactById.get(di.Contact2Imported__c).AccountId);
        }
        
        List<Address__c> listAddr = getAddresses(); 
        System.assertEquals(2, listAddr.size());
        System.assertEquals(listDI[0].Home_City__c, listAddr[0].MailingCity__c);
        System.assertEquals(listDI[0].HomeAddressImported__c, listAddr[0].Id);
        System.assertEquals(label.bdiCreated, listDI[0].HomeAddressImportStatus__c);
        System.assertEquals(listDI[1].Home_City__c, listAddr[1].MailingCity__c);
        System.assertEquals(listDI[1].HomeAddressImported__c, listAddr[1].Id);
        System.assertEquals(label.bdiCreated, listDI[1].HomeAddressImportStatus__c);

        List<Account> listAcc = getAccounts();
        System.assertEquals(2, listAcc.size());
        System.assertEquals(listDI[0].Home_City__c, listAcc[0].BillingCity);
        System.assertEquals(listDI[1].Home_City__c, listAcc[1].BillingCity);
    }

    /*********************************************************************************************************
    * @description operation
    *        import existing contacts with home addresses
    * verify:
    *        address objects not duplicated
    *        contacts' mailing address set
    *        hh accounts' billing address set
    **********************************************************************************************************/
    static testMethod void TwoDIExistingHomeAddresses() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'TwoDIExistingHomeAddresses') return;

        // existing contacts
        List<Contact> listConExisting = new List<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com', MailingCity='Seattle'));
        listConExisting.add(new Contact(Firstname='c3', Lastname='C3', Email='c3@C3.com', MailingCity='Seattle'));
        insert listConExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);

        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(newDI('c1', 'C1', 'c2', 'C2'));
        listDI.add(newDI('c3', 'C3', 'c4', 'C4'));
        listDI[0].Home_City__c = 'Portland';
        listDI[1].Home_City__c = 'Portland';
        insert listDI;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        Map<Id, Contact> contactById = new Map<Id, Contact>(getContacts());
        System.assertEquals(4, contactById.size());
        listDI = getDIs();
        System.assertEquals(2, listDI.size());

        for (DataImport__c di : listDI) {
            System.assert(contactById.containsKey(di.Contact1Imported__c));
            System.assertEquals(di.Contact1_Firstname__c + ' ' + di.Contact1_Lastname__c, contactById.get(di.Contact1Imported__c).Name);
            System.assertEquals(di.Home_City__c, contactById.get(di.Contact1Imported__c).MailingCity);
            System.assert(contactById.containsKey(di.Contact2Imported__c));
            System.assertEquals(di.Contact2_Firstname__c + ' ' + di.Contact2_Lastname__c, contactById.get(di.Contact2Imported__c).Name);
            System.assertEquals(di.Home_City__c, contactById.get(di.Contact2Imported__c).MailingCity);
            System.assertNotEquals(null, contactById.get(di.Contact1Imported__c).AccountId);
            System.assertNotEquals(null, contactById.get(di.Contact2Imported__c).AccountId);
        }
        
        List<Address__c> listAddr = getAddresses(); 
        System.assertEquals(4, listAddr.size());
        System.assertEquals(listDI[0].Home_City__c, listAddr[2].MailingCity__c);
        System.assertEquals(listDI[0].HomeAddressImported__c, listAddr[2].Id);
        System.assertEquals(label.bdiCreated, listDI[0].HomeAddressImportStatus__c);
        System.assertEquals(listDI[1].Home_City__c, listAddr[3].MailingCity__c);
        System.assertEquals(listDI[1].HomeAddressImported__c, listAddr[3].Id);
        System.assertEquals(label.bdiCreated, listDI[1].HomeAddressImportStatus__c);

        List<Account> listAcc = getAccounts();
        System.assertEquals(2, listAcc.size());
        System.assertEquals(listDI[0].Home_City__c, listAcc[0].BillingCity);
        System.assertEquals(listDI[1].Home_City__c, listAcc[1].BillingCity);

    }

    /*********************************************************************************************************
    * @description operation
    *        import duplicate contacts with duplicate home addresses  
    * verify: 
    *        no duplicate address objects created
    *        contacts' mailing address set
    *        hh accounts' billing address set
    **********************************************************************************************************/            
    static testMethod void ManyDISameHomeAddresses() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'ManyDISameHomeAddresses') return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(newDI('c1', 'C1', 'c2', 'C2'));
        listDI.add(newDI('c1', 'C1'));
        listDI.add(newDI('c1', 'C1'));
        listDI.add(newDI('c2', 'C2'));
        listDI.add(newDI('c2', 'C2'));

        // add same address to all
        for (DataImport__c di : listDI) {        
            di.Home_Street__c = '123 45th St NE';
            di.Home_City__c = 'Seattle';
            di.Home_State_Province__c = 'Washington';
            di.Home_Zip_Postal_Code__c = '98052';
            di.Home_Country__c = 'United States';
        }
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(2, listCon.size());
        listDI = getDIs();
        System.assertEquals(5, listDI.size());

        for (Contact con : listCon) {        
            System.assertEquals(listDI[0].Home_Street__c, con.MailingStreet);
            System.assertEquals(listDI[0].Home_City__c, con.MailingCity);
            System.assertEquals(listDI[0].Home_State_Province__c, con.MailingState);
            System.assertEquals(listDI[0].Home_Zip_Postal_Code__c, con.MailingPostalCode);
            System.assertEquals(listDI[0].Home_Country__c, con.MailingCountry);
        }
        
        List<Address__c> listAddr = getAddresses(); 
        System.assertEquals(1, listAddr.size());
        System.assertEquals(listDI[0].Home_Street__c, listAddr[0].MailingStreet__c);
        System.assertEquals(listDI[0].Home_City__c, listAddr[0].MailingCity__c);
        System.assertEquals(listDI[0].Home_State_Province__c, listAddr[0].MailingState__c);
        System.assertEquals(listDI[0].Home_Zip_Postal_Code__c, listAddr[0].MailingPostalCode__c);
        System.assertEquals(listDI[0].Home_Country__c, listAddr[0].MailingCountry__c);
        
        List<Account> listAcc = getAccounts();
        // because c2 is first created as a contact1, it will get a hh account, that will
        // later get orphaned when we move c2 to c1's hh account.
        System.assertEquals(2, listAcc.size());
        System.assertEquals(listDI[0].Home_Street__c, listAcc[0].BillingStreet);
        System.assertEquals(listDI[0].Home_City__c, listAcc[0].BillingCity);
        System.assertEquals(listDI[0].Home_State_Province__c, listAcc[0].BillingState);
        System.assertEquals(listDI[0].Home_Zip_Postal_Code__c, listAcc[0].BillingPostalCode);
        System.assertEquals(listDI[0].Home_Country__c, listAcc[0].BillingCountry);                

        integer cCreated = 0;
        integer cMatched = 0;
        for (DataImport__c di : listDI) {
            System.assertEquals(di.HomeAddressImported__c, listAddr[0].Id);
            if (di.HomeAddressImportStatus__c == label.bdiCreated)
                cCreated++; 
            else if (di.HomeAddressImportStatus__c == label.bdiMatched)
                cMatched++; 
        }
        // we didn't have an easy way to track the specific DI record that caused the addr to be created vs matched
        // in these duplicate (but new) scenarios, so we will live with marking them all as created.
        System.assertEquals(5, cCreated);
        System.assertEquals(0, cMatched);
    }

    /*********************************************************************************************************
    * @description operation
    *        import contacts with home addresses, while address management is disabled 
    * verify: 
    *        address objects NOT created
    *    contacts' mailing address set
    *    hh accounts' billing address set
    **********************************************************************************************************/            
    static testMethod void TwoDIHomeAddressesAddrMgmtOff() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'TwoDIHomeAddressesAddrMgmtOff') return;
            
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                Household_Account_Addresses_Disabled__c = true
        ));

        List<DataImport__c> listDI = new List<DataImport__c>();
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
        Map<Id, Contact> contactById = new Map<Id, Contact>(getContacts());
        System.assertEquals(4, contactById.size());
        listDI = getDIs();
        System.assertEquals(2, listDI.size());

        for (DataImport__c di : listDI) {
            System.assert(contactById.containsKey(di.Contact1Imported__c));
            System.assertEquals(di.Contact1_Firstname__c + ' ' + di.Contact1_Lastname__c, contactById.get(di.Contact1Imported__c).Name);
            System.assertEquals(di.Home_City__c, contactById.get(di.Contact1Imported__c).MailingCity);
            System.assert(contactById.containsKey(di.Contact2Imported__c));
            System.assertEquals(di.Contact2_Firstname__c + ' ' + di.Contact2_Lastname__c, contactById.get(di.Contact2Imported__c).Name);
            System.assertEquals(di.Home_City__c, contactById.get(di.Contact2Imported__c).MailingCity);
            System.assertNotEquals(null, contactById.get(di.Contact1Imported__c).AccountId);
            System.assertNotEquals(null, contactById.get(di.Contact2Imported__c).AccountId);
        }

        List<Address__c> listAddr = getAddresses(); 
        System.assertEquals(0, listAddr.size());
        
        List<Account> listAcc = getAccounts();
        System.assertEquals(2, listAcc.size());
        System.assertEquals('Seattle', listAcc[0].BillingCity);
        System.assertEquals('Portland', listAcc[1].BillingCity);                
    }

    /*********************************************************************************************************
    * @description operation
    *        import existing contacts with the same home address 
    * verify: 
    *        contacts matched
    *        address matched
    **********************************************************************************************************/            
    static testMethod void TwoDIMixedAddresses() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'TwoDIMixedAddresses') return;
            
        // existing contacts
        List<Contact> listConExisting = new List<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com', MailingCity='Seattle'));
        listConExisting.add(new Contact(Firstname='c2', Lastname='C2', Email='c2@C2.com', MailingCity='Portland'));
        insert listConExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);
        
        List<DataImport__c> listDI = new List<DataImport__c>();
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
        List<Contact> listCon = getContacts();
        System.assertEquals(2, listCon.size());
        
        List<Address__c> listAddr = getAddresses(); 
        System.assertEquals(3, listAddr.size());
        System.assertEquals('Seattle', listAddr[0].MailingCity__c);
        System.assertEquals('Portland', listAddr[1].MailingCity__c);
        System.assertEquals('Bellevue', listAddr[2].MailingCity__c);
        
        listDI = getDIs();
        System.assertEquals(2, listDI.size());
        System.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(listDI[1].Contact1Imported__c, listCon[1].Id);
        System.assertNotEquals(null, listDI[0].HouseholdAccountImported__c);
        System.assertNotEquals(null, listDI[1].HouseholdAccountImported__c);
        System.assertEquals(label.bdiMatched, listDI[0].Contact1ImportStatus__c);
        System.assertEquals(label.bdiMatched, listDI[1].Contact1ImportStatus__c);
        System.assertEquals(listAddr[0].Id, listDI[0].HomeAddressImported__c);   
        System.assertEquals(listAddr[2].Id, listDI[1].HomeAddressImported__c);   
        System.assertEquals(label.bdiMatched, listDI[0].HomeAddressImportStatus__c);
        System.assertEquals(label.bdiCreated, listDI[1].HomeAddressImportStatus__c);            
    }
    
    /*********************************************************************************************************
    * @description operation
    *        import existing contacts with the same home address, with Address Management off 
    * verify: 
    *        contacts matched
    *       no addresses created
    *       account addresses updated
    *       contact addresses updated
    **********************************************************************************************************/            
    static testMethod void TwoDIMixedAddressesAddrMgmtOff() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'TwoDIMixedAddressesAddrMgmtOff') return;
            
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                Household_Account_Addresses_Disabled__c = true
        ));

        // existing contacts
        List<Contact> listConExisting = new List<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com', MailingCity='Seattle'));
        listConExisting.add(new Contact(Firstname='c2', Lastname='C2', Email='c2@C2.com', MailingCity='Portland'));
        insert listConExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);
        
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(newDI('c1', 'C1'));
        listDI.add(newDI('c2', 'C2'));
        listDI[0].Home_City__c = 'Bellevue';
        listDI[1].Home_City__c = 'Bellevue';
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(2, listCon.size());
        System.assertEquals('Bellevue', listCon[0].MailingCity);
        System.assertEquals('Bellevue', listCon[1].MailingCity);
        
        List<Address__c> listAddr = getAddresses();
        System.assertEquals(0, listAddr.size()); 
        
        List<Account> listAcc = getAccounts();
        System.assertEquals(2, listAcc.size());
        System.assertEquals('Bellevue', listAcc[0].BillingCity);
        System.assertEquals('Bellevue', listAcc[1].BillingCity);                
    }
    
    /*********************************************************************************************************
    * @description operation
    *        import contacts with donation & payment information  
    * verify: 
    *        opportunity objects created
    *       payment objects created
    *       ocr's created
    *       contacts' rollups updated
    *       hh account's rollups updated
    **********************************************************************************************************/            
    static testMethod void TwoDIWithDonations() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'TwoDIWithDonations') return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
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
        // verify expected results
        Map<Id, Contact> contactById = new Map<Id, Contact>(getContacts());
        System.assertEquals(4, contactById.size());
        listDI = getDIs();
        System.assertEquals(2, listDI.size());

        for (DataImport__c di : listDI) {
            System.assert(contactById.containsKey(di.Contact1Imported__c));
            System.assertEquals(di.Contact1_Firstname__c + ' ' + di.Contact1_Lastname__c, contactById.get(di.Contact1Imported__c).Name);
            System.assertEquals(0, contactById.get(di.Contact1Imported__c).npo02__TotalOppAmount__c);
            System.assert(contactById.containsKey(di.Contact2Imported__c));
            System.assertEquals(di.Contact2_Firstname__c + ' ' + di.Contact2_Lastname__c, contactById.get(di.Contact2Imported__c).Name);
            System.assertEquals(0, contactById.get(di.Contact2Imported__c).npo02__TotalOppAmount__c);
            System.assertNotEquals(null, contactById.get(di.Contact1Imported__c).AccountId);
            System.assertNotEquals(null, contactById.get(di.Contact2Imported__c).AccountId);
        }

        // we no longer run rollups, unless the setting is specified
        
        List<Account> listAcc = getAccounts();
        System.assertEquals(2, listAcc.size());
        System.assertEquals(0, listAcc[0].npo02__TotalOppAmount__c);
        System.assertEquals(0, listAcc[1].npo02__TotalOppAmount__c);
        
        List<Opportunity> listOpp = getOpps();
        System.assertEquals(2, listOpp.size());
        System.assertEquals(100, listOpp[0].Amount);
        System.assertEquals(200, listOpp[1].Amount);
        System.assertEquals(listAcc[0].Id, listOpp[0].AccountId);
        System.assertEquals(listAcc[1].Id, listOpp[1].AccountId);
                
        List<npe01__OppPayment__c> listPmt = getPayments();
        System.assertEquals(2, listPmt.size());
        System.assertEquals(100, listPmt[0].npe01__Payment_Amount__c);
        System.assertEquals(200, listPmt[1].npe01__Payment_Amount__c);
        System.assertEquals('Check', listPmt[0].npe01__Payment_Method__c);
        System.assertEquals('Visa', listPmt[1].npe01__Payment_Method__c);
        System.assertEquals('abc', listPmt[0].npe01__Check_Reference_Number__c);
        System.assertEquals('1234', listPmt[1].npe01__Check_Reference_Number__c);

        List<OpportunityContactRole> listOCR = getOCRs();
        System.assertEquals(4, listOCR.size());
        for (OpportunityContactRole ocr : listOCR) {
            System.assert(contactById.containsKey(ocr.ContactId));
        }

        listDI = getDIs();
        System.assertEquals(2, listDI.size());
        System.assertEquals(listDI[0].DonationImported__c, listOpp[0].Id); 
        System.assertEquals(listDI[1].DonationImported__c, listOpp[1].Id);
        System.assertEquals(label.bdiCreated, listDI[0].DonationImportStatus__c);
        System.assertEquals(label.bdiCreated, listDI[1].DonationImportStatus__c);        
    }

    /*********************************************************************************************************
    * @description operation
    *        import accounts with donation & payment information  
    * verify: 
    *       opportunity objects created
    *       payment objects created
    *       ocr's created
    *       account's rollups updated
    **********************************************************************************************************/            
    static testMethod void TwoDIWithAccountDonations() {
        if (strTestOnly != '*' && strTestOnly != 'TwoDIWithAccountDonations') return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
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
        List<Account> listAcc = getAccounts();
        System.assertEquals(2, listAcc.size());
        // we no longer run rollups, unless the setting is specified
        System.assertEquals(0, listAcc[0].npo02__TotalOppAmount__c);
        System.assertEquals(0, listAcc[1].npo02__TotalOppAmount__c);
        
        List<Opportunity> listOpp = getOpps();
        System.assertEquals(2, listOpp.size());
        System.assertEquals(100, listOpp[0].Amount);
        System.assertEquals(200, listOpp[1].Amount);
        System.assertEquals(listAcc[0].Id, listOpp[0].AccountId);
        System.assertEquals(listAcc[1].Id, listOpp[1].AccountId);
                
        list<npe01__OppPayment__c> listPmt = getPayments();
        System.assertEquals(2, listPmt.size());
        System.assertEquals(100, listPmt[0].npe01__Payment_Amount__c);
        System.assertEquals(200, listPmt[1].npe01__Payment_Amount__c);
        System.assertEquals('Check', listPmt[0].npe01__Payment_Method__c);
        System.assertEquals('Visa', listPmt[1].npe01__Payment_Method__c);
        System.assertEquals('abc', listPmt[0].npe01__Check_Reference_Number__c);
        System.assertEquals('1234', listPmt[1].npe01__Check_Reference_Number__c);

        list<OpportunityContactRole> listOCR = getOCRs();
        System.assertEquals(0, listOCR.size());

        listDI = getDIs();
        System.assertEquals(2, listDI.size());
        System.assertEquals(listDI[0].DonationImported__c, listOpp[0].Id); 
        System.assertEquals(listDI[1].DonationImported__c, listOpp[1].Id);
        System.assertEquals(label.bdiCreated, listDI[0].DonationImportStatus__c);
        System.assertEquals(label.bdiCreated, listDI[1].DonationImportStatus__c);        
    }

    /*********************************************************************************************************
    * @description operation
    *        import contacts with donation & campaign information  
    * verify: 
    *        opportunity objects created
    *    opportunities added to campaigns
    **********************************************************************************************************/            
    static testMethod void TwoDIWithDonationsAndCampaigns() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'TwoDIWithDonationsAndCampaigns') return;
        
        List<Campaign> listC = new List<Campaign>();
        listC.add(new Campaign(Name='CmpExisting'));
        insert listC;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
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
        List<Contact> listCon = getContacts();
        System.assertEquals(2, listCon.size());
        
        List<Account> listAcc = getAccounts();
        System.assertEquals(2, listAcc.size());
        // we no longer run rollups, unless the setting is specified
        System.assertEquals(0, listAcc[0].npo02__TotalOppAmount__c);
        System.assertEquals(0, listAcc[1].npo02__TotalOppAmount__c);
        
        List<Opportunity> listOpp = getOpps();
        System.assertEquals(2, listOpp.size());
        System.assertEquals(100, listOpp[0].Amount);
        System.assertEquals(200, listOpp[1].Amount);
        System.assertEquals(listAcc[0].Id, listOpp[0].AccountId);
        System.assertEquals(listAcc[1].Id, listOpp[1].AccountId);
                
        List<Campaign> listCmp = getCampaigns();
        System.assertEquals(2, listCmp.size());
        System.assertEquals(listOpp[0].CampaignId, listCmp[0].Id);
        System.assertEquals(listOpp[1].CampaignId, listCmp[1].Id);
        
        listDI = getDIs();
        System.assertEquals(2, listDI.size());
        System.assertEquals(listDI[0].DonationImported__c, listOpp[0].Id); 
        System.assertEquals(listDI[1].DonationImported__c, listOpp[1].Id);
        System.assertEquals(label.bdiCreated, listDI[0].DonationImportStatus__c);
        System.assertEquals(label.bdiCreated, listDI[1].DonationImportStatus__c);        
    }

    /*********************************************************************************************************
    * @description operation
    *        import contacts with campaign information (no donation)  
    * verify: 
    *        opportunity objects created
    *    opportunities added to campaigns
    **********************************************************************************************************/            
    static testMethod void TwoDIWithCampaignMembers() {
        if (strTestOnly != '*' && strTestOnly != 'TwoDIWithCampaignMembers') return;
        
        List<Campaign> listC = new List<Campaign>();
        listC.add(new Campaign(Name='CmpExisting'));
        insert listC;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(newDI('c1', 'C1'));
        listDI.add(newDI('c2', 'C2'));

        listDI[0].Donation_Campaign_Name__c = 'CmpExisting';
        listDI[1].Donation_Campaign_Name__c = 'CmpNew';
        listDI[1].Campaign_Member_Status__c = 'zMyStatus';
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(2, listCon.size());
        
        List<Account> listAcc = getAccounts();
        System.assertEquals(2, listAcc.size());
                        
        List<Campaign> listCmp = getCampaigns();
        System.assertEquals(2, listCmp.size());
        
        list<CampaignMember> listCM = getCampaignMembers();
        System.assertEquals(2, listCM.size());
        System.assertEquals(listCon[0].Id, listCM[0].ContactId);
        System.assertNotEquals('zMyStatus', listCM[0].Status);
        System.assertEquals(listCon[1].Id, listCM[1].ContactId);
        System.assertEquals('zMyStatus', listCM[1].Status);
        
    }

    /*********************************************************************************************************
    * @description operation
    *        import accounts with invalid donation information  
    * verify: 
    *        opportunity objects created only for valid di
    **********************************************************************************************************/            
    static testMethod void TwoDIWithDonationErrors() {
        if (strTestOnly != '*' && strTestOnly != 'TwoDIWithDonationErrors') return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
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
        List<Account> listAcc = getAccounts();
        System.assertEquals(2, listAcc.size());
        // we no longer run rollups, unless the setting is specified
        System.assertEquals(0, listAcc[0].npo02__TotalOppAmount__c);
        System.assertEquals(0, listAcc[1].npo02__TotalOppAmount__c);
        
        List<Opportunity> listOpp = getOpps();
        System.assertEquals(1, listOpp.size());
        System.assertEquals(100, listOpp[0].Amount);
        System.assertEquals(listAcc[0].Id, listOpp[0].AccountId);
                
        listDI = getDIs();
        System.assertEquals(2, listDI.size());
        System.assertEquals(listDI[0].DonationImported__c, listOpp[0].Id); 
        System.assertEquals(listDI[1].DonationImported__c, null);
        System.assertEquals(label.bdiCreated, listDI[0].DonationImportStatus__c);
        System.assertEquals(label.bdiErrorInvalidDonor, listDI[1].DonationImportStatus__c);
        System.assertEquals(BDI_DataImport_API.bdiImported, listDI[0].Status__c);
        System.assertEquals(BDI_DataImport_API.bdiFailed, listDI[1].Status__c);
    }

    /*********************************************************************************************************
    * @description operation
    *        import different contacts within multiple di records in the same batch setting Household fields 
    * verify: 
    *        two contacts created
    **********************************************************************************************************/            
    static testMethod void TwoDITwoNewContactsHouseholdFields() {
        if (strTestOnly != '*' && strTestOnly != 'TwoDITwoNewContactsHouseholdFields') return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Lastname__c = 'c1', Household_Phone__c = '425-111-2222'));
        listDI.add(new DataImport__c(Contact1_Lastname__c = 'c2', Household_Phone__c = '425-111-2222'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(2, listCon.size());
        System.assertNotEquals(listCon[1].Name, listCon[0].Name);
        System.assertEquals(listDI[0].Household_Phone__c, listCon[0].Account.Phone);
        System.assertEquals(listDI[1].Household_Phone__c, listCon[1].Account.Phone);
        
        listDI = getDIs();
        System.assertEquals(2, listDI.size());
        System.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(listDI[1].Contact1Imported__c, listCon[1].Id);
        System.assertNotEquals(null, listDI[0].HouseholdAccountImported__c);
        System.assertNotEquals(null, listDI[1].HouseholdAccountImported__c);
        System.assertEquals(label.bdiCreated, listDI[0].Contact1ImportStatus__c);
        System.assertEquals(label.bdiCreated, listDI[1].Contact1ImportStatus__c);        
    }

    /*********************************************************************************************************
    * @description operation
    *        import new contacts into existing household accounts  
    * verify: 
    *        provided household account used
    **********************************************************************************************************/            
    static testMethod void TwoDINewContactsExistingsHousehold() {
        if (strTestOnly != '*' && strTestOnly != 'TwoDINewContactsExistingsHousehold') return;
            
        // existing contacts
        List<Contact> listConExisting = new List<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com'));
        listConExisting.add(new Contact(Firstname='c2', Lastname='C2', Email='c2@C2.com'));
        insert listConExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);
        
        // get their households
        listConExisting = getContacts();
        System.assertEquals(2, listConExisting.size());
        
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c='a1', Contact1_Lastname__c='C1',
            HouseholdAccountImported__c=listConExisting[0].AccountId));
        listDI.add(new DataImport__c(Contact1_Firstname__c='a2', Contact1_Lastname__c='C2', Contact2_Firstname__c='b2',
            HouseholdAccountImported__c=listConExisting[1].AccountId));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(5, listCon.size());
        System.assertEquals(listConExisting[0].AccountId, listCon[0].AccountId);
        System.assertEquals(listConExisting[1].AccountId, listCon[1].AccountId);
        System.assertEquals(listConExisting[0].AccountId, listCon[2].AccountId);
        System.assertEquals(listConExisting[1].AccountId, listCon[3].AccountId);
        System.assertEquals(listConExisting[1].AccountId, listCon[4].AccountId);
        
        List<Account> listAcc = getAccounts();
        System.assertEquals(2, listAcc.size());
    }

    /*********************************************************************************************************
    * @description operation
    *        import existing contacts, from the same household
    * verify:
    *        no problems updating additional fields on C1 and C2
    *        c2 matched in household
    **********************************************************************************************************/
    static testMethod void OneDIExistingContactsExistingHousehold() {
        if (strTestOnly != '*' && strTestOnly != 'OneDIExistingContactsExistingHousehold') return;

        // existing contacts into the same household
        List<Contact> listConExisting = new List<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com', Salutation='Mr'));
        insert listConExisting;
        ID hhId = getContacts()[0].AccountId;
        listConExisting.add(new Contact(Firstname='c2', Lastname='C1', Email='c2@C2.com', Salutation='Mrs', AccountId=hhId));
        upsert listConExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);

        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@C1.com', Contact1_Salutation__c='Dr',
            Contact2_Firstname__c='c2', Contact2_Salutation__c='Prof'));
        insert listDI;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(2, listCon.size());
        System.assertEquals(hhId, listCon[0].AccountId);
        System.assertEquals(hhId, listCon[1].AccountId);
        System.assertEquals('Dr', listCon[0].Salutation);
        System.assertEquals('Prof', listCon[1].Salutation);
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves data import records in the order they were created during the test. 
    * @return List<DataImport__c> All data import records in creation order
    **********************************************************************************************************/
    private static List<DataImport__c> getDIs() {
        return [
            SELECT Account1Imported__c, Account1ImportStatus__c, Account1_Name__c,
                Account2Imported__c, Account2ImportStatus__c, Account2_Name__c, Contact1_Preferred_Email__c, Contact1_Preferred_Phone__c,
                Contact1Imported__c, Contact1ImportStatus__c, Contact1_Firstname__c, Contact1_Lastname__c, Contact1_Title__c,
                Contact2Imported__c, Contact2ImportStatus__c, Contact2_Firstname__c, Contact2_Lastname__c,
                DonationImported__c, DonationImportStatus__c, Donation_Campaign_Name__c, FailureInformation__c, Status__c,
                HomeAddressImported__c, HomeAddressImportStatus__c, HouseholdAccountImported__c, Home_Street__c, Home_City__c,
                Home_State_Province__c, Home_Zip_Postal_Code__c, Home_Country__c
            FROM DataImport__c
            ORDER BY Id
        ];
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves account records in the order they were created during the test. 
    * @return List<Account> All account records in creation order
    **********************************************************************************************************/
    private static List<Account> getAccounts() {
        return [
            SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Name, Phone, npo02__TotalOppAmount__c
            FROM Account
            ORDER BY Id
        ];
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves account records in the order they were created during the test. 
    * @return List<Account> All account records, where type is not a Household, in creation order
    **********************************************************************************************************/
    private static List<Account> getOrganizations() {
        return [
            SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Name, Phone, npo02__TotalOppAmount__c
            FROM Account
            WHERE Type != 'Household'
            ORDER BY Id
        ];
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves contact records in the order they were created during the test. 
    * @return List<Contact> All contacts records in creation order
    **********************************************************************************************************/
    private static List<Contact> getContacts() {
        return [
            SELECT Id, AccountId, Birthdate, HomePhone,  MobilePhone, Name, Title, Salutation, Account.Phone,
                Account.npe01__System_AccountType__c, MailingState, MailingPostalCode, MailingCountry, MailingStreet, MailingCity,
                Primary_Affiliation__c, npe01__HomeEmail__c, npe01__AlternateEmail__c, npe01__Preferred_Email__c,
                npe01__PreferredPhone__c, npe01__WorkEmail__c, npe01__WorkPhone__c, npo02__TotalOppAmount__c
            FROM Contact
            ORDER BY Id
        ];
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves address records in the order they were created during the test. 
    * @return List<Address__c> All address records in creation order
    **********************************************************************************************************/
    private static List<Address__c> getAddresses() {
        return [
            SELECT Id, Household_Account__c, MailingStreet__c, MailingCity__c, MailingState__c, MailingPostalCode__c, MailingCountry__c
            FROM Address__c
            ORDER BY Id
        ];
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves affiliation records in the order they were created during the test. 
    * @return List<npe5__Affiliation__c> All affiliation records in creation order
    **********************************************************************************************************/
    private static List<npe5__Affiliation__c> getAffiliations() {
        return [SELECT Id, npe5__Contact__c, npe5__Organization__c FROM npe5__Affiliation__c ORDER BY Id];
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves opportunity records in the order they were created during the test. 
    * @return List<Opportunity> All opportunity records in creation order
    **********************************************************************************************************/
    private static List<Opportunity> getOpps() {
        return [SELECT Id, Name, Amount, AccountId, CampaignId FROM Opportunity ORDER BY Id];
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves opportunity contact role records in the order they were created during the test. 
    * @return List<OpportunityContactRole> All opportunity contact role records in creation order
    **********************************************************************************************************/
    private static List<OpportunityContactRole> getOCRs() {
        return [SELECT Id, ContactId, OpportunityId FROM OpportunityContactRole  ORDER BY Id];
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves payment records in the order they were created during the test. 
    * @return List<npe01__OppPayment__c> All payment records in creation order
    **********************************************************************************************************/
    private static List<npe01__OppPayment__c> getPayments() {
        return [
            SELECT Id, npe01__Payment_Amount__c, npe01__Payment_Method__c, npe01__Check_Reference_Number__c
            FROM npe01__OppPayment__c
            ORDER BY Id
        ];
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves campaign records in the order they were created during the test. 
    * @return List<Campaign> All campaign records
    **********************************************************************************************************/
    private static List<Campaign> getCampaigns() {
        return [SELECT Id, Name FROM Campaign ORDER BY Id];
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves campaign member records in the order they were created during the test. 
    * @return List<CampaignMember> All campaign member records
    **********************************************************************************************************/
    private static List<CampaignMember> getCampaignMembers() {
        return [SELECT Id, ContactId, Status FROM CampaignMember ORDER BY Id];
    }
}