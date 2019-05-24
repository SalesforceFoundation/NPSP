/*
    Copyright (c) 2019 Salesforce.org
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
* @date 2019
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description tests specific to the Batch Data Importer batch processing and record creation
*/

@isTest
public with sharing class BDI_DataImport_TEST {
    /*******************************************************************************************************
    * @description creates a new di record for tests
    * @param firstname the firstname to specify for Contact1
    * @param lastname the lastname to specify for Contact1
    * @return DataImport__c the new Data Import record
    */
    public static DataImport__c newDI(String firstname, String lastname) {
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
    * @param donationamount the amount to use for the donation
    * @return DataImport__c the new Data Import record
    */
    public static DataImport__c newDI(String firstname, String lastname, Integer donationamount) {
        return new DataImport__c(
           Contact1_Firstname__c = firstname,
           Contact1_Lastname__c = lastname,
           Contact1_Personal_Email__c = firstname + '@' + lastname + '.com',
           Donation_Amount__c = donationamount,
           Donation_Date__c = System.today()
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
    public static DataImport__c newDI(String firstname, String lastname, String firstname2, String lastname2) {
        return new DataImport__c(
           Contact1_Firstname__c = firstname,
           Contact1_Lastname__c = lastname,
           Contact1_Personal_Email__c = (lastname == null ? null : firstname + '@' + lastname + '.com'),
           Contact2_Firstname__c = firstname2,
           Contact2_Lastname__c = lastname2,
           Contact2_Personal_Email__c = (lastname2 == null ? null : firstname2 + '@' + lastname2 + '.com')
        );
    }

    /*******************************************************************************************************
    * @description creates a new di record for tests
    * @param firstname the firstname to specify for Contact1
    * @param lastname the lastname to specify for Contact1
    * @param firstname2 the firstname to specify for Contact2
    * @param lastname2 the lastname to specify for Contact2
    * @param address the address to use for the Data Import record
    * @return DataImport__c the new Data Import record
    */
    public static DataImport__c newDI(String firstname, String lastname, String firstname2, String lastname2, Address__c address) {
        return new DataImport__c(
                Contact1_Firstname__c = firstname,
                Contact1_Lastname__c = lastname,
                Contact1_Personal_Email__c = (lastname == null ? null : firstname + '@' + lastname + '.com'),
                Contact2_Firstname__c = firstname2,
                Contact2_Lastname__c = lastname2,
                Contact2_Personal_Email__c = (lastname2 == null ? null : firstname2 + '@' + lastname2 + '.com'),
                Home_City__c = (address.MailingCity__c == null ? null : address.MailingCity__c),
                Home_State_Province__c = (address.MailingState__c == null ? null : address.MailingState__c),
                Home_Country__c = (address.MailingCountry__c == null ? null : address.MailingCountry__c)
        );
    }


    /*********************************************************************************************************
    * @description operation
    *     import matching contacts within the same di record 
    * verify:
    *     only one contact created
    **********************************************************************************************************/            
    static testMethod void OneDIDuplicateNewContacts() {
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1', 'c1', 'C1'));
        insert dataImports;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(1, listCon.size());
        System.assertEquals('c1 C1', listCon[0].Name);
        
        dataImports = getDataImports();
        System.assertEquals(1, dataImports.size());
        System.assertEquals(dataImports[0].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(dataImports[0].Contact2Imported__c, listCon[0].Id);
        System.assertNotEquals(null, dataImports[0].HouseholdAccountImported__c);
        System.assertEquals(label.bdiCreated, dataImports[0].Contact1ImportStatus__c);
        System.assertEquals(label.bdiMatched, dataImports[0].Contact2ImportStatus__c);        
    }
    
    /*********************************************************************************************************
    * @description operation
    *        import different contacts within the same di record  
    * verify: 
    *        two contacts created
    **********************************************************************************************************/            
    static testMethod void OneDITwoNewContacts() {
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1', 'c2', 'C2'));
        insert dataImports;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(2, listCon.size());
        System.assertNotEquals(listCon[1].Name, listCon[0].Name);

        dataImports = getDataImports();
        System.assertEquals(1, dataImports.size());
        System.assertEquals(dataImports[0].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(dataImports[0].Contact2Imported__c, listCon[1].Id);
        System.assertNotEquals(null, dataImports[0].HouseholdAccountImported__c);        
        System.assertEquals(label.bdiCreated, dataImports[0].Contact1ImportStatus__c);
        System.assertEquals(label.bdiCreated, dataImports[0].Contact2ImportStatus__c);        
    }

    /*********************************************************************************************************
    * @description operation
    *        match a contact with no firstname
    * verify:
    *        contact matched
    **********************************************************************************************************/
    static testMethod void OneDIWithoutFirstName() {
        // this test won't pass if middle name or suffix is enabled due to a
        // salesforce won't fix issue: https://success.salesforce.com/issues_view?id=a1p30000000eQRxAAM
        if (UTIL_Describe.isMiddleNameEnabled() || UTIL_Describe.isNameSuffixEnabled()) {
            return;
        }

        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Contact_Matching_Rule__c = 'Lastname,Email';

        insert new Contact(
            Lastname='foo',
            Email='foo@bar.com'
        );

        insert new DataImport__c(
            Contact1_Lastname__c = 'Foo',
            Contact1_Personal_Email__c = 'foo@bar.com'
        );

        //run batch data import
        Test.StartTest();
        ID ApexJobId = Database.executeBatch(new BDI_DataImport_BATCH(), 10);
        Test.stopTest();

        // verify expected results
        List<Contact> contacts = getContacts();
        System.assertEquals(1, contacts.size());
        System.assertEquals(null, contacts[0].FirstName);

        List<DataImport__c> imports = getDataImports();
        System.assertEquals(1, imports.size());
        System.assertEquals(imports[0].Contact1Imported__c, contacts[0].Id);
        System.assertNotEquals(null, imports[0].HouseholdAccountImported__c);
        System.assertEquals(System.Label.bdiMatched, imports[0].Contact1ImportStatus__c);
    }

    /*********************************************************************************************************
    * @description operation
    *        import matching contacts within multiple di records in the same batch  
    * verify: 
    *        only one contact created
    **********************************************************************************************************/            
    static testMethod void TwoDIDuplicateNewContacts() {
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1'));
        dataImports.add(newDI('c1', 'C1'));
        insert dataImports;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(1, listCon.size());
        System.assertEquals('c1 C1', listCon[0].Name);

        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size());
        System.assertEquals(dataImports[0].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(dataImports[1].Contact1Imported__c, listCon[0].Id);
        System.assertNotEquals(null, dataImports[0].HouseholdAccountImported__c);
        System.assertNotEquals(null, dataImports[1].HouseholdAccountImported__c);
        System.assertEquals(label.bdiCreated, dataImports[0].Contact1ImportStatus__c);
        System.assertEquals(label.bdiMatched, dataImports[1].Contact1ImportStatus__c);        
    }
    
    /*********************************************************************************************************
    * @description operation
    *        import different contacts within multiple di records in the same batch 
    * verify: 
    *        two contacts created
    **********************************************************************************************************/            
    static testMethod void TwoDITwoNewContacts() {
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1'));
        dataImports.add(newDI('c2', 'C2'));
        insert dataImports;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(2, listCon.size());
        System.assertNotEquals(listCon[1].Name, listCon[0].Name);

        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size());
        System.assertEquals(dataImports[0].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(dataImports[1].Contact1Imported__c, listCon[1].Id);
        System.assertNotEquals(null, dataImports[0].HouseholdAccountImported__c);
        System.assertNotEquals(null, dataImports[1].HouseholdAccountImported__c);
        System.assertEquals(label.bdiCreated, dataImports[0].Contact1ImportStatus__c);
        System.assertEquals(label.bdiCreated, dataImports[1].Contact1ImportStatus__c);        
    }

    /*********************************************************************************************************
    * @description operation
    *        import matching contacts within multiple di records in the same batch  
    * verify: 
    *        only two contacts created
    *        only 1 household account created
    **********************************************************************************************************/            
    static testMethod void TwoDIDuplicateNewContactsDifferentOrder() {
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1', 'c2', 'C2'));
        dataImports.add(newDI('c2', 'C2'));
        insert dataImports;
          
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

        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size());
        System.assertEquals(dataImports[0].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(dataImports[1].Contact1Imported__c, listCon[1].Id);
        System.assertNotEquals(null, dataImports[0].HouseholdAccountImported__c);
        System.assertNotEquals(null, dataImports[1].HouseholdAccountImported__c);
        System.assertEquals(label.bdiCreated, dataImports[0].Contact1ImportStatus__c);
        System.assertEquals(label.bdiCreated, dataImports[1].Contact1ImportStatus__c);        
        System.assertEquals(label.bdiMatched, dataImports[0].Contact2ImportStatus__c);        
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

        // existing contacts
        List<Contact> listConExisting = new List<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com'));
        listConExisting.add(new Contact(Firstname='c2', Lastname='C2', Email='c2@C2.com'));
        insert listConExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);
        
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1', 'c2', 'C2'));
        insert dataImports;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(2, listCon.size());
        System.assertNotEquals(listCon[1].Name, listCon[0].Name);
        
        dataImports = getDataImports();
        System.assertEquals(1, dataImports.size());
        System.assertEquals(dataImports[0].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(dataImports[0].Contact2Imported__c, listCon[1].Id);
        System.assertNotEquals(null, dataImports[0].HouseholdAccountImported__c);
        System.assertEquals(label.bdiMatched, dataImports[0].Contact1ImportStatus__c);
        System.assertEquals(label.bdiMatched, dataImports[0].Contact2ImportStatus__c);        
    }

    /*********************************************************************************************************
    * @description operation
    *        import existing contacts that match a 1x1 contact 
    * verify: 
    *        error given, di not processed.
    **********************************************************************************************************/            
    static testMethod void OneDIExistingContacts1x1() {
        // existing 1x1 contact
        UTIL_UnitTestData_TEST.createAccountContactTestData(CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE, 1, 1, 0);   
        List<Contact> listConExisting = getContacts();
        System.assertEquals(1, listConExisting.size());
        System.assertEquals(CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE, listConExisting[0].Account.npe01__System_AccountType__c);
        System.assertEquals('TestFirstname00 TestLastname00', listConExisting[0].Name);
        listConExisting[0].email = 'foo@bar.com';
        update listConExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);
        
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('TestFirstname00', 'TestLastname00', 'c2', 'C2', new Address__c(MailingCity__c='Seattle')));
        dataImports[0].Contact1_Personal_Email__c = 'foo@bar.com';
        insert dataImports;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        Boolean usingAdv = ADV_PackageInfo_SVC.useAdv();
        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(1, listCon.size());
        System.assertEquals('TestFirstname00 TestLastname00', listCon[0].Name);

        dataImports = getDataImports();
        System.assertEquals(1, dataImports.size());
        System.assertEquals(null, dataImports[0].Contact1Imported__c);
        System.assertEquals(null, dataImports[0].Contact2Imported__c);
        System.assertEquals(null, dataImports[0].HouseholdAccountImported__c);
        // With ADV installed, 1x1 Contacts can make Donations, but there cannot be a second Contact on the DI record
        String importError = usingAdv ? label.bdiErrorOneToOneMultiContact : label.bdiErrorNonHHAccountContact;
        System.assertEquals(importError, dataImports[0].Contact1ImportStatus__c);
        System.assertEquals(null, dataImports[0].Contact2ImportStatus__c);
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
            
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(new DataImport__c(Account1_Name__c='A1', Account2_Name__c='A2'));
        insert dataImports;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Account> listAcc = getAccounts();
        System.assertEquals(2, listAcc.size());
        System.assertNotEquals(listAcc[1].Name, listAcc[0].Name);

        dataImports = getDataImports();
        System.assertEquals(1, dataImports.size());
        System.assertEquals(dataImports[0].Account1Imported__c, listAcc[0].Id);
        System.assertEquals(dataImports[0].Account2Imported__c, listAcc[1].Id);
        System.assertEquals(label.bdiCreated, dataImports[0].Account1ImportStatus__c);
        System.assertEquals(label.bdiCreated, dataImports[0].Account2ImportStatus__c);        
    }

    /*********************************************************************************************************
    * @description operation
    *        import matching accounts within the same di record  
    * verify: 
    *        one accounts created
    **********************************************************************************************************/            
    static testMethod void OneDITwoSameAccounts() {
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(new DataImport__c(Account1_Name__c='A1', Account2_Name__c='A1'));
        insert dataImports;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Account> listAcc = getAccounts();
        System.assertEquals(1, listAcc.size());

        dataImports = getDataImports();
        System.assertEquals(1, dataImports.size());
        System.assertEquals(dataImports[0].Account1Imported__c, listAcc[0].Id);
        System.assertEquals(dataImports[0].Account2Imported__c, listAcc[0].Id);
        System.assertEquals(label.bdiCreated, dataImports[0].Account1ImportStatus__c);
        System.assertEquals(label.bdiMatched, dataImports[0].Account2ImportStatus__c);        
    }

    /*********************************************************************************************************
    * @description operation
    *        import matching accounts in different di records  
    * verify: 
    *        one account created
    **********************************************************************************************************/            
    static testMethod void TwoDISameAccounts() {
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(new DataImport__c(Account1_Name__c='A1'));
        dataImports.add(new DataImport__c(Account1_Name__c='A1'));
        insert dataImports;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Account> listAcc = getAccounts();
        System.assertEquals(1, listAcc.size());

        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size());
        System.assertEquals(dataImports[0].Account1Imported__c, listAcc[0].Id);
        System.assertEquals(dataImports[1].Account1Imported__c, listAcc[0].Id);
        System.assertEquals(label.bdiCreated, dataImports[0].Account1ImportStatus__c);
        System.assertEquals(label.bdiMatched, dataImports[1].Account1ImportStatus__c);
    }

    /*********************************************************************************************************
    * @description operation
    *        import existing accounts  
    * verify: 
    *        no accounts created, just matched
    **********************************************************************************************************/
    static testMethod void TwoDIExistingAccounts() {
        List<Account> listAcc = new List<Account>();
        listAcc.add(new Account(name='A1', BillingCity='Seattle'));
        listAcc.add(new Account(name='A2'));
        insert listAcc;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listAcc);

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(new DataImport__c(Account1_Name__c='A1', Account1_City__c='Seattle'));
        dataImports.add(new DataImport__c(Account1_Name__c='A2'));
        insert dataImports;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        listAcc = getAccounts();
        System.assertEquals(2, listAcc.size());

        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size());
        System.assertEquals(dataImports[0].Account1Imported__c, listAcc[0].Id);
        System.assertEquals(dataImports[1].Account1Imported__c, listAcc[1].Id);
        System.assertEquals(label.bdiMatched, dataImports[0].Account1ImportStatus__c);
        System.assertEquals(label.bdiMatched, dataImports[1].Account1ImportStatus__c);
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

        List<Account> listAcc = new List<Account>();
        listAcc.add(new Account(name='A1'));
        listAcc.add(new Account(name='A2'));
        insert listAcc;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listAcc);

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', 
            Account1Imported__c=listAcc[0].Id));
        dataImports.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C2', Contact2_Firstname__c='c2', 
            Account1Imported__c=listAcc[0].Id, Account2Imported__c=listAcc[1].Id));
        insert dataImports;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        listAcc = getOrganizations();
        System.assertEquals(2, listAcc.size());

        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size());
        System.assertEquals(dataImports[0].Account1Imported__c, listAcc[0].Id);
        System.assertEquals(dataImports[1].Account1Imported__c, listAcc[0].Id);
        System.assertEquals(dataImports[1].Account2Imported__c, listAcc[1].Id);
        System.assertEquals(label.bdiMatched, dataImports[0].Account1ImportStatus__c);
        System.assertEquals(label.bdiMatched, dataImports[1].Account1ImportStatus__c);        
        System.assertEquals(label.bdiMatched, dataImports[1].Account2ImportStatus__c);        
    }

    /*********************************************************************************************************
    operation:
    *        import contacts with Preferred Email set 
    * verify: 
    *        ensure the appropriate contact email field gets copied into the standard email field.
    **********************************************************************************************************/
    /** can't use this test because it relies on our workflow rules being active, which we can't enforce.
    static testMethod void ThreeDINewContactsWithPreferredEmail() {
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1'));
        dataImports.add(newDI('c2', 'C2'));
        dataImports.add(newDI('c3', 'C3'));
        dataImports[0].Contact1_Preferred_Email__c = 'Home';
        dataImports[0].Contact1_Personal_Email__c = 'c1@home.com';
        dataImports[1].Contact1_Preferred_Email__c = 'Work';
        dataImports[1].Contact1_Work_Email__c = 'c2@work.com';
        dataImports[2].Contact1_Preferred_Email__c = 'Alternate';
        dataImports[2].Contact1_Personal_Email__c = 'c3@alt.com';
        insert dataImports;
          
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

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1', 'c2', 'C2'));
        dataImports.add(newDI('c3', 'C3', 'c4', 'C4'));
        dataImports[0].Account1_Name__c = 'A1';
        dataImports[1].Account2_Name__c = 'A2';
        insert dataImports;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        Map<Id, Contact> contactById = new Map<Id, Contact>(getContacts());
        System.assertEquals(4, contactById.size());
        
        dataImports = getDataImports();

        for (DataImport__c di : dataImports) {
            System.assert(contactById.containsKey(di.Contact1Imported__c));
            System.assertEquals(di.Contact1_Firstname__c + ' ' + di.Contact1_Lastname__c, contactById.get(di.Contact1Imported__c).Name);
            System.assert(contactById.containsKey(di.Contact2Imported__c));
            System.assertEquals(di.Contact2_Firstname__c + ' ' + di.Contact2_Lastname__c, contactById.get(di.Contact2Imported__c).Name);
            System.assertNotEquals(null, contactById.get(di.Contact1Imported__c).AccountId);
            System.assertNotEquals(null, contactById.get(di.Contact2Imported__c).AccountId);
        }
        
        List<Account> listAcc = getOrganizations();
        System.assertEquals(2, listAcc.size());
        System.assertEquals(contactById.get(dataImports[0].Contact1Imported__c).Primary_Affiliation__c, listAcc[0].Id);
        System.assertEquals(contactById.get(dataImports[0].Contact2Imported__c).Primary_Affiliation__c, null);
        System.assertEquals(contactById.get(dataImports[1].Contact1Imported__c).Primary_Affiliation__c, null);
        System.assertEquals(contactById.get(dataImports[1].Contact2Imported__c).Primary_Affiliation__c, listAcc[1].Id);
        
        list<npe5__Affiliation__c> listAffl = getAffiliations();
        System.assertEquals(2, listAffl.size());
        System.assertEquals(dataImports[0].Contact1Imported__c, listAffl[0].npe5__Contact__c);
        System.assertEquals(dataImports[1].Contact2Imported__c, listAffl[1].npe5__Contact__c);

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

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1', 'c2', 'C2', new Address__c(MailingCity__c='Seattle')));
        dataImports.add(newDI('c3', 'C3', 'c4', 'C4', new Address__c(MailingCity__c='Portland')));
        insert dataImports;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        Map<Id, Contact> contactById = new Map<Id, Contact>(getContacts());
        System.assertEquals(4, contactById.size());
        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size());

        for (DataImport__c di : dataImports) {
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
        System.assertEquals(dataImports[0].Home_City__c, listAddr[0].MailingCity__c);
        System.assertEquals(dataImports[0].HomeAddressImported__c, listAddr[0].Id);
        System.assertEquals(label.bdiCreated, dataImports[0].HomeAddressImportStatus__c);
        System.assertEquals(dataImports[1].Home_City__c, listAddr[1].MailingCity__c);
        System.assertEquals(dataImports[1].HomeAddressImported__c, listAddr[1].Id);
        System.assertEquals(label.bdiCreated, dataImports[1].HomeAddressImportStatus__c);

        List<Account> listAcc = getAccounts();
        System.assertEquals(2, listAcc.size());
        System.assertEquals(dataImports[0].Home_City__c, listAcc[0].BillingCity);
        System.assertEquals(dataImports[1].Home_City__c, listAcc[1].BillingCity);
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

        // existing contacts
        List<Contact> listConExisting = new List<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com', MailingCity='Seattle'));
        listConExisting.add(new Contact(Firstname='c3', Lastname='C3', Email='c3@C3.com', MailingCity='Seattle'));
        insert listConExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1', 'c2', 'C2', new Address__c(MailingCity__c='Portland')));
        dataImports.add(newDI('c3', 'C3', 'c4', 'C4', new Address__c(MailingCity__c='Portland')));
        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        Map<Id, Contact> contactById = new Map<Id, Contact>(getContacts());
        System.assertEquals(4, contactById.size());
        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size());

        for (DataImport__c di : dataImports) {
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
        System.assertEquals(dataImports[0].Home_City__c, listAddr[2].MailingCity__c);
        System.assertEquals(dataImports[0].HomeAddressImported__c, listAddr[2].Id);
        System.assertEquals(label.bdiCreated, dataImports[0].HomeAddressImportStatus__c);
        System.assertEquals(dataImports[1].Home_City__c, listAddr[3].MailingCity__c);
        System.assertEquals(dataImports[1].HomeAddressImported__c, listAddr[3].Id);
        System.assertEquals(label.bdiCreated, dataImports[1].HomeAddressImportStatus__c);

        List<Account> listAcc = getAccounts();
        System.assertEquals(2, listAcc.size());
        System.assertEquals(dataImports[0].Home_City__c, listAcc[0].BillingCity);
        System.assertEquals(dataImports[1].Home_City__c, listAcc[1].BillingCity);

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

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1', 'c2', 'C2'));
        dataImports.add(newDI('c1', 'C1'));
        dataImports.add(newDI('c1', 'C1'));
        dataImports.add(newDI('c2', 'C2'));
        dataImports.add(newDI('c2', 'C2'));

        // add same address to all
        for (DataImport__c di : dataImports) {        
            di.Home_Street__c = '123 45th St NE';
            di.Home_City__c = 'Seattle';
            di.Home_State_Province__c = 'Washington';
            di.Home_Zip_Postal_Code__c = '98052';
            di.Home_Country__c = 'United States';
        }
        insert dataImports;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(2, listCon.size());
        dataImports = getDataImports();
        System.assertEquals(5, dataImports.size());

        for (Contact con : listCon) {        
            System.assertEquals(dataImports[0].Home_Street__c, con.MailingStreet);
            System.assertEquals(dataImports[0].Home_City__c, con.MailingCity);
            System.assertEquals(dataImports[0].Home_State_Province__c, con.MailingState);
            System.assertEquals(dataImports[0].Home_Zip_Postal_Code__c, con.MailingPostalCode);
            System.assertEquals(dataImports[0].Home_Country__c, con.MailingCountry);
        }
        
        List<Address__c> listAddr = getAddresses(); 
        System.assertEquals(1, listAddr.size());
        System.assertEquals(dataImports[0].Home_Street__c, listAddr[0].MailingStreet__c);
        System.assertEquals(dataImports[0].Home_City__c, listAddr[0].MailingCity__c);
        System.assertEquals(dataImports[0].Home_State_Province__c, listAddr[0].MailingState__c);
        System.assertEquals(dataImports[0].Home_Zip_Postal_Code__c, listAddr[0].MailingPostalCode__c);
        System.assertEquals(dataImports[0].Home_Country__c, listAddr[0].MailingCountry__c);
        
        List<Account> listAcc = getAccounts();
        // because c2 is first created as a contact1, it will get a hh account, that will
        // later get orphaned when we move c2 to c1's hh account.
        System.assertEquals(2, listAcc.size());
        System.assertEquals(dataImports[0].Home_Street__c, listAcc[0].BillingStreet);
        System.assertEquals(dataImports[0].Home_City__c, listAcc[0].BillingCity);
        System.assertEquals(dataImports[0].Home_State_Province__c, listAcc[0].BillingState);
        System.assertEquals(dataImports[0].Home_Zip_Postal_Code__c, listAcc[0].BillingPostalCode);
        System.assertEquals(dataImports[0].Home_Country__c, listAcc[0].BillingCountry);                

        integer cCreated = 0;
        integer cMatched = 0;
        for (DataImport__c di : dataImports) {
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

        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR,
                Household_Account_Addresses_Disabled__c = true
        ));

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1', 'c2', 'C2', new Address__c(MailingCity__c='Seattle')));
        dataImports.add(newDI('c3', 'C3', 'c4', 'C4', new Address__c(MailingCity__c='Portland')));
        insert dataImports;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        Map<Id, Contact> contactById = new Map<Id, Contact>(getContacts());
        System.assertEquals(4, contactById.size());
        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size());

        for (DataImport__c di : dataImports) {
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

        // existing contacts
        List<Contact> listConExisting = new List<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com', MailingCity='Seattle'));
        listConExisting.add(new Contact(Firstname='c2', Lastname='C2', Email='c2@C2.com', MailingCity='Portland'));
        insert listConExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);
        
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1'));
        dataImports.add(newDI('c2', 'C2'));
        dataImports[0].Home_City__c = 'Seattle';
        dataImports[1].Home_City__c = 'Bellevue';
        insert dataImports;
          
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
        
        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size());
        System.assertEquals(dataImports[0].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(dataImports[1].Contact1Imported__c, listCon[1].Id);
        System.assertNotEquals(null, dataImports[0].HouseholdAccountImported__c);
        System.assertNotEquals(null, dataImports[1].HouseholdAccountImported__c);
        System.assertEquals(label.bdiMatched, dataImports[0].Contact1ImportStatus__c);
        System.assertEquals(label.bdiMatched, dataImports[1].Contact1ImportStatus__c);
        System.assertEquals(listAddr[0].Id, dataImports[0].HomeAddressImported__c);   
        System.assertEquals(listAddr[2].Id, dataImports[1].HomeAddressImported__c);   
        System.assertEquals(label.bdiMatched, dataImports[0].HomeAddressImportStatus__c);
        System.assertEquals(label.bdiCreated, dataImports[1].HomeAddressImportStatus__c);            
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
        
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1'));
        dataImports.add(newDI('c2', 'C2'));
        dataImports[0].Home_City__c = 'Bellevue';
        dataImports[1].Home_City__c = 'Bellevue';
        insert dataImports;
          
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

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1', 'c2', 'C2'));
        dataImports.add(newDI('c3', 'C3', 'c4', 'C4'));
        dataImports[0].Donation_Amount__c = 100;
        dataImports[1].Donation_Amount__c = 200;
        dataImports[0].Payment_Check_Reference_Number__c = 'abc';
        dataImports[1].Payment_Check_Reference_Number__c = '1234';
        dataImports[0].Payment_Method__c = 'Check';
        dataImports[1].Payment_Method__c = 'Visa';       
        insert dataImports;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        Map<Id, Contact> contactById = new Map<Id, Contact>(getContacts());
        System.assertEquals(4, contactById.size());
        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size());

        for (DataImport__c di : dataImports) {
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

        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size());
        System.assertEquals(dataImports[0].DonationImported__c, listOpp[0].Id); 
        System.assertEquals(dataImports[1].DonationImported__c, listOpp[1].Id);
        System.assertEquals(label.bdiCreated, dataImports[0].DonationImportStatus__c);
        System.assertEquals(label.bdiCreated, dataImports[1].DonationImportStatus__c);        
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
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(new DataImport__c(Account1_Name__c='A1'));
        dataImports.add(new DataImport__c(Account1_Name__c='A2'));
        dataImports[0].Donation_Donor__c = 'Account1';
        dataImports[1].Donation_Donor__c = 'Account1';
        dataImports[0].Donation_Amount__c = 100;
        dataImports[1].Donation_Amount__c = 200;
        dataImports[0].Payment_Check_Reference_Number__c = 'abc';
        dataImports[1].Payment_Check_Reference_Number__c = '1234';
        dataImports[0].Payment_Method__c = 'Check';
        dataImports[1].Payment_Method__c = 'Visa';       
        insert dataImports;
          
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

        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size());
        System.assertEquals(dataImports[0].DonationImported__c, listOpp[0].Id); 
        System.assertEquals(dataImports[1].DonationImported__c, listOpp[1].Id);
        System.assertEquals(label.bdiCreated, dataImports[0].DonationImportStatus__c);
        System.assertEquals(label.bdiCreated, dataImports[1].DonationImportStatus__c);        
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

        List<Campaign> campaigns = new List<Campaign>();
        campaigns.add(new Campaign(Name='CmpExisting'));
        insert campaigns;
            
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1', 100));
        dataImports.add(newDI('c2', 'C2', 200));
        dataImports[0].Donation_Campaign_Name__c = 'CmpExisting';
        dataImports[1].Donation_Campaign_Name__c = 'CmpNew';
        insert dataImports;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Contact> contacts = getContacts();
        System.assertEquals(2, contacts.size());
        
        List<Account> accounts = getAccounts();
        System.assertEquals(2, accounts.size());
        // we no longer run rollups, unless the setting is specified
        System.assertEquals(0, accounts[0].npo02__TotalOppAmount__c);
        System.assertEquals(0, accounts[1].npo02__TotalOppAmount__c);
        
        List<Opportunity> opps = getOpps();
        System.assertEquals(2, opps.size());
        System.assertEquals(100, opps[0].Amount);
        System.assertEquals(200, opps[1].Amount);
        System.assertEquals(accounts[0].Id, opps[0].AccountId);
        System.assertEquals(accounts[1].Id, opps[1].AccountId);

        campaigns = getCampaigns();
        System.assertEquals(2, campaigns.size());
        System.assertEquals(opps[0].CampaignId, campaigns[0].Id);
        System.assertEquals(opps[1].CampaignId, campaigns[1].Id);
        
        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size());

        System.assertEquals(dataImports[0].DonationImported__c, opps[0].Id);
        System.assertEquals(System.Label.bdiCreated, dataImports[0].DonationImportStatus__c);
        System.assertEquals(System.Label.bdiMatched, dataImports[0].DonationCampaignImportStatus__c);
        System.assertEquals(campaigns[0].Id, dataImports[0].DonationCampaignImported__c);

        System.assertEquals(dataImports[1].DonationImported__c, opps[1].Id);
        System.assertEquals(System.Label.bdiCreated, dataImports[1].DonationImportStatus__c);
        System.assertEquals(System.Label.bdiCreated, dataImports[1].DonationCampaignImportStatus__c);
        System.assertEquals(campaigns[1].Id, dataImports[1].DonationCampaignImported__c);
    }

    /*********************************************************************************************************
    * @description operation
    *        import contacts with donation & campaign IDs and Names
    * verify:
    *    opportunity objects created
    *    campaigns added to opportunities
    *    campaigns matched by ID
    **********************************************************************************************************/
    static testMethod void TwoDIWithDonationsAndCampaignIds() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        List<Campaign> campaigns = new List<Campaign>();
        campaigns.add(new Campaign(Name='CmpExisting'));
        campaigns.add(new Campaign(Name='AnotherCmpExisting'));
        insert campaigns;

        Id campaignId = campaigns[0].Id;

        List<DataImport__c> dataImports = new List<DataImport__c>();

        dataImports.add(newDI('c1', 'C1', 100));
        dataImports[0].DonationCampaignImported__c = campaignId;

        dataImports.add(newDI('c2', 'C2', 200));
        dataImports[1].DonationCampaignImported__c = null;
        dataImports[1].Donation_Campaign_Name__c = 'AnotherCmpExisting';

        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Opportunity> opps = getOpps();
        System.assertEquals(2, opps.size());
        System.assertEquals(100, opps[0].Amount);
        System.assertEquals(200, opps[1].Amount);

        campaigns = getCampaigns();
        System.assertEquals(2, campaigns.size());
        System.assertEquals(campaigns[0].Id, opps[0].CampaignId);
        System.assertEquals(campaigns[1].Id, opps[1].CampaignId);

        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size());

        System.assertEquals(opps[0].Id, dataImports[0].DonationImported__c);
        System.assertEquals(System.Label.bdiCreated, dataImports[0].DonationImportStatus__c);
        System.assertEquals(campaigns[0].Id, dataImports[0].DonationCampaignImported__c);
        System.assertEquals(System.Label.bdiMatchedId, dataImports[0].DonationCampaignImportStatus__c);

        System.assertEquals(opps[1].Id, dataImports[1].DonationImported__c);
        System.assertEquals(System.Label.bdiCreated, dataImports[1].DonationImportStatus__c);
        System.assertEquals(campaigns[1].Id, dataImports[1].DonationCampaignImported__c);
        System.assertEquals(System.Label.bdiMatched, dataImports[1].DonationCampaignImportStatus__c);

    }

    /*********************************************************************************************************
    * @description operation
    *        import contacts with donation & campaign names -- Only Dry Run
    * verify:
    *    no opportunity objects created
    *    no campaign objects created
    *    correct campaign status for dry run matching
    **********************************************************************************************************/
    static testMethod void TwoDIWithDonationsAndDuplicateCampaignNameInDryRun() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        List<DataImport__c> dataImports = new List<DataImport__c>();
        String duplicateCampaignName = 'Matching Campaign Name';

        dataImports.add(newDI('c1', 'C1', 100));
        dataImports[0].Donation_Campaign_Name__c = duplicateCampaignName;

        dataImports.add(newDI('c2', 'C2', 200));
        dataImports[1].Donation_Campaign_Name__c = duplicateCampaignName;

        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        bdi.isDryRun = true;
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Opportunity> opps = getOpps();
        System.assertEquals(0, opps.size());

        List<Campaign> campaigns = getCampaigns();
        System.assertEquals(0, campaigns.size());

        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size());

        System.assertEquals(null, dataImports[0].DonationCampaignImported__c);
        System.assertEquals(System.Label.bdiDryRunNoMatch, dataImports[0].DonationCampaignImportStatus__c);
        System.assertEquals(null, dataImports[1].DonationCampaignImported__c);
        System.assertEquals(System.Label.bdiDryRunNoMatch, dataImports[1].DonationCampaignImportStatus__c);
    }

    /*********************************************************************************************************
    * @description operation
    *        import contacts with donation & campaign names
    * verify:
    *    opportunity objects created
    *    singular campaign object created
    *    campaign ID added to all opportunities
    **********************************************************************************************************/
    static testMethod void TwoDIWithDonationsAndDuplicateCampaignNames() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        List<DataImport__c> dataImports = new List<DataImport__c>();
        String duplicateCampaignName = 'Matching Campaign Name';

        dataImports.add(newDI('c1', 'C1', 100));
        dataImports[0].Donation_Campaign_Name__c = duplicateCampaignName;

        dataImports.add(newDI('c2', 'C2', 200));
        dataImports[1].Donation_Campaign_Name__c = duplicateCampaignName;

        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Opportunity> opps = getOpps();
        System.assertEquals(2, opps.size());
        System.assertEquals(100, opps[0].Amount);
        System.assertEquals(200, opps[1].Amount);

        List<Campaign> campaigns = getCampaigns();
        System.assertEquals(1, campaigns.size());
        System.assertEquals(campaigns[0].Id, opps[0].CampaignId);
        System.assertEquals(campaigns[0].Id, opps[1].CampaignId);

        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size());

        System.assertEquals(opps[0].Id, dataImports[0].DonationImported__c);
        System.assertEquals(System.Label.bdiCreated, dataImports[0].DonationImportStatus__c);
        System.assertEquals(campaigns[0].Id, dataImports[0].DonationCampaignImported__c);
        System.assertEquals(System.Label.bdiCreated, dataImports[0].DonationCampaignImportStatus__c);

        System.assertEquals(opps[1].Id, dataImports[1].DonationImported__c);
        System.assertEquals(System.Label.bdiCreated, dataImports[1].DonationImportStatus__c);
        System.assertEquals(campaigns[0].Id, dataImports[1].DonationCampaignImported__c);
        System.assertEquals(System.Label.bdiCreated, dataImports[1].DonationCampaignImportStatus__c);

    }

    /*********************************************************************************************************
    * @description operation
    *        run dry run contacts with donation & campaign IDs and Names
    * verify:
    *    DonationCampaignImported__c is set on ID and name match
    *    Campaign Status is still matched instead of Matched by ID
    **********************************************************************************************************/
    static testMethod void TwoDIWithDonationsAndCampaignIdsInDryRun() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        List<Campaign> campaigns = new List<Campaign>();
        campaigns.add(new Campaign(Name = 'CmpExisting'));
        campaigns.add(new Campaign(Name = 'AnotherCmpExisting'));
        insert campaigns;

        Id campaignId = campaigns[0].Id;

        List<DataImport__c> dataImports = new List<DataImport__c>();

        dataImports.add(newDI('c1', 'C1', 100));
        dataImports[0].DonationCampaignImported__c = campaignId;

        dataImports.add(newDI('c2', 'C2', 200));
        dataImports[1].DonationCampaignImported__c = null;
        dataImports[1].Donation_Campaign_Name__c = 'AnotherCmpExisting';

        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        bdi.isDryRun = true;
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        //verify dry run statuses and import fields
        dataImports = getDataImports();
        System.assertEquals(System.Label.bdiDryRunMatchedId, dataImports[0].DonationCampaignImportStatus__c);
        System.assertEquals(campaigns[0].Id, dataImports[0].DonationCampaignImported__c);
        System.assertEquals(System.Label.bdiDryRunMatched, dataImports[1].DonationCampaignImportStatus__c);
        System.assertEquals(campaigns[1].Id, dataImports[1].DonationCampaignImported__c);
    }

    /*********************************************************************************************************
    * @description operation
    *        run dry run contacts with donation & campaign IDs and Names and THEN process the batch
    * verify:
    *    DonationCampaignImported__c is set on ID and name match
    *    Campaign Status is still matched instead of Matched by ID
    **********************************************************************************************************/
    static testMethod void TwoDIWithDonationsAndCampaignIdsAfterDryRun() {
        //skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) return;

        List<Campaign> campaigns = new List<Campaign>();
        campaigns.add(new Campaign(Name = 'CmpExisting'));
        campaigns.add(new Campaign(Name = 'AnotherCmpExisting'));
        insert campaigns;

        Id campaignId = campaigns[0].Id;

        List<DataImport__c> dataImports = new List<DataImport__c>();

        dataImports.add(newDI('c1', 'C1', 100));
        dataImports[0].DonationCampaignImported__c = campaignId;

        dataImports.add(newDI('c2', 'C2', 200));
        dataImports[1].DonationCampaignImported__c = null;
        dataImports[1].Donation_Campaign_Name__c = 'AnotherCmpExisting';

        insert dataImports;

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        bdi.isDryRun = true;
        ID ApexJobId = Database.executeBatch(bdi, 10);
        bdi.isDryRun = false;
        ID ApexJobId2 = Database.executeBatch(bdi, 10);
        Test.stopTest();

        //verify dry run statuses and import fields
        dataImports = getDataImports();
        System.assertEquals(System.Label.bdiMatchedId, dataImports[0].DonationCampaignImportStatus__c);
        System.assertEquals(campaigns[0].Id, dataImports[0].DonationCampaignImported__c);
        System.assertEquals(System.Label.bdiMatched, dataImports[1].DonationCampaignImportStatus__c);
        System.assertEquals(campaigns[1].Id, dataImports[1].DonationCampaignImported__c);
    }

    /*********************************************************************************************************
    * @description operation
    *        import contacts with campaign information (no donation)  
    * verify: 
    *        opportunity objects created
    *    opportunities added to campaigns
    **********************************************************************************************************/            
    static testMethod void TwoDIWithCampaignMembers() {
        List<Campaign> listC = new List<Campaign>();
        listC.add(new Campaign(Name='CmpExisting'));
        insert listC;
            
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(newDI('c1', 'C1'));
        dataImports.add(newDI('c2', 'C2'));

        dataImports[0].Donation_Campaign_Name__c = 'CmpExisting';
        dataImports[1].Donation_Campaign_Name__c = 'CmpNew';
        dataImports[1].Campaign_Member_Status__c = 'zMyStatus';
        insert dataImports;
          
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
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(new DataImport__c(Account1_Name__c='A1'));
        dataImports.add(new DataImport__c(Account1_Name__c='A2'));
        dataImports[0].Donation_Donor__c = 'Account1';
        dataImports[1].Donation_Donor__c = 'illegal value here!';
        dataImports[0].Donation_Amount__c = 100;
        dataImports[1].Donation_Amount__c = 200;
        insert dataImports;
          
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
                
        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size());
        System.assertEquals(dataImports[0].DonationImported__c, listOpp[0].Id); 
        System.assertEquals(dataImports[1].DonationImported__c, null);
        System.assertEquals(label.bdiCreated, dataImports[0].DonationImportStatus__c);
        System.assertEquals(label.bdiErrorInvalidDonor, dataImports[1].DonationImportStatus__c);
        System.assertEquals(BDI_DataImport_API.bdiImported, dataImports[0].Status__c);
        System.assertEquals(BDI_DataImport_API.bdiFailed, dataImports[1].Status__c);
    }

    /*********************************************************************************************************
    * @description operation
    *        import different contacts within multiple di records in the same batch setting Household fields 
    * verify: 
    *        two contacts created
    **********************************************************************************************************/            
    static testMethod void TwoDITwoNewContactsHouseholdFields() {
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(new DataImport__c(Contact1_Lastname__c = 'c1', Household_Phone__c = '425-111-2222'));
        dataImports.add(new DataImport__c(Contact1_Lastname__c = 'c2', Household_Phone__c = '425-111-2222'));
        insert dataImports;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(2, listCon.size());
        System.assertNotEquals(listCon[1].Name, listCon[0].Name);
        System.assertEquals(dataImports[0].Household_Phone__c, listCon[0].Account.Phone);
        System.assertEquals(dataImports[1].Household_Phone__c, listCon[1].Account.Phone);
        
        dataImports = getDataImports();
        System.assertEquals(2, dataImports.size());
        System.assertEquals(dataImports[0].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(dataImports[1].Contact1Imported__c, listCon[1].Id);
        System.assertNotEquals(null, dataImports[0].HouseholdAccountImported__c);
        System.assertNotEquals(null, dataImports[1].HouseholdAccountImported__c);
        System.assertEquals(label.bdiCreated, dataImports[0].Contact1ImportStatus__c);
        System.assertEquals(label.bdiCreated, dataImports[1].Contact1ImportStatus__c);        
    }

    /*********************************************************************************************************
    * @description operation
    *        import new contacts into existing household accounts  
    * verify: 
    *        provided household account used
    **********************************************************************************************************/            
    static testMethod void TwoDINewContactsExistingsHousehold() {
        // existing contacts
        List<Contact> listConExisting = new List<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com'));
        listConExisting.add(new Contact(Firstname='c2', Lastname='C2', Email='c2@C2.com'));
        insert listConExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);
        
        // get their households
        listConExisting = getContacts();
        System.assertEquals(2, listConExisting.size());
        
        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(new DataImport__c(Contact1_Firstname__c='a1', Contact1_Lastname__c='C1',
            HouseholdAccountImported__c=listConExisting[0].AccountId));
        dataImports.add(new DataImport__c(Contact1_Firstname__c='a2', Contact1_Lastname__c='C2', Contact2_Firstname__c='b2',
            HouseholdAccountImported__c=listConExisting[1].AccountId));
        insert dataImports;
          
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
        // existing contacts into the same household
        List<Contact> listConExisting = new List<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com', Salutation='Mr'));
        insert listConExisting;
        ID hhId = getContacts()[0].AccountId;
        listConExisting.add(new Contact(Firstname='c2', Lastname='C1', Email='c2@C2.com', Salutation='Mrs', AccountId=hhId));
        upsert listConExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@C1.com', Contact1_Salutation__c='Dr',
            Contact2_Firstname__c='c2', Contact2_Salutation__c='Prof'));
        insert dataImports;

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
    * @description operation
    *        import existing contact with names using different case, make sure matching is case insensitive
    * verify:
    *        c1 matched despite email case mismatch
    *        c2 matched in household despite firstname case mismatch
    *        no problems updating additional fields on C1 and C2
    **********************************************************************************************************/
    static testMethod void OneDIExistingContactsCaseInsensitive() {
        // existing contacts into the same household
        List<Contact> existingContacts = new List<Contact>();
        existingContacts.add(
            new Contact(
                FirstName='C1',
                LastName='C1',
                Email='c1@c1.com',
                Salutation='Mr'
            )
        );
        insert existingContacts;
        ID hhId = getContacts()[0].AccountId;
        existingContacts.add(
            new Contact(
                FirstName='C2',
                LastName='C1',
                Email='c2@c2.com',
                Salutation='Mrs',
                AccountId=hhId
            )
        );
        upsert existingContacts;

        UTIL_UnitTestData_TEST.setFixedSearchResults(existingContacts);

        List<DataImport__c> dataImports = new List<DataImport__c>();
        dataImports.add(
            new DataImport__c(
                Contact1_Firstname__c='c1',
                Contact1_Lastname__c='c1',
                Contact1_Personal_Email__c='C1@C1.com',
                Contact1_Salutation__c='Dr',
                Contact2_Firstname__c='c2',
                Contact2_Salutation__c='Prof'
            )
        );
        insert dataImports;

        //run batch data import
        Test.startTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();

        // verify expected results
        List<Contact> contacts = getContacts();
        System.assertEquals(2, contacts.size(), 'Contacts should be matched, despite case mismatch');
        System.assertEquals(hhId, contacts[0].AccountId, 'Contacts should be in same household.');
        System.assertEquals(hhId, contacts[1].AccountId, 'Contacts should be in same household.');
        System.assertEquals('Dr', contacts[0].Salutation, 'Contact should be updated with salutation from the data import.');
        System.assertEquals('Prof', contacts[1].Salutation, 'Contact should be updated with salutation from the data import.');
        System.assertEquals('C1', contacts[0].LastName, 'Contact should not be updated with the lowercase last name from the data import.');
        System.assertEquals('c1@c1.com', contacts[0].Email, 'Contact should not be updated with the uppercase email from the data import.');
        System.assertEquals('C2', contacts[1].FirstName, 'Contact should not be updated with the lowercase first name from the data import.');
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves data import records in the order they were created during the test. 
    * @return List<DataImport__c> All data import records in creation order
    **********************************************************************************************************/
    private static List<DataImport__c> getDataImports() {
        return [
                SELECT Account1Imported__c, Account1ImportStatus__c, Account1_Name__c,
                        Account2Imported__c, Account2ImportStatus__c, Account2_Name__c, Contact1_Preferred_Email__c, Contact1_Preferred_Phone__c,
                        Contact1Imported__c, Contact1ImportStatus__c, Contact1_Firstname__c, Contact1_Lastname__c, Contact1_Title__c,
                        Contact2Imported__c, Contact2ImportStatus__c, Contact2_Firstname__c, Contact2_Lastname__c,
                        DonationImported__c, DonationImportStatus__c, Donation_Campaign_Name__c, DonationCampaignImported__c, DonationCampaignImportStatus__c,
                        FailureInformation__c, Status__c, HomeAddressImported__c, HomeAddressImportStatus__c, HouseholdAccountImported__c,
                        Home_Street__c, Home_City__c, Home_State_Province__c, Home_Zip_Postal_Code__c, Home_Country__c
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
            SELECT Id, AccountId, Birthdate, HomePhone,  MobilePhone, Name, FirstName, LastName, Title, Salutation, Account.Phone,
                Account.npe01__System_AccountType__c, MailingState, MailingPostalCode, MailingCountry, MailingStreet, MailingCity,
                Primary_Affiliation__c, Email, npe01__HomeEmail__c, npe01__AlternateEmail__c, npe01__Preferred_Email__c,
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