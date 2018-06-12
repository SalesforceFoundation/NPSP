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
* @description tests specific to the Batch Data Importer and error handling
*/

@isTest
private with sharing class BDI_DataImport_TEST2 {

    /*********************************************************************************************************
    * @description if you only want to run one test in this class, fill in its name here.
    * if you want to run all tests, then use '*'
    */
    private static string strTestOnly = '*';

    /*********************************************************************************************************
    * @description operation: 
    *    import matching contacts within multiple di records in the same batch, using different email fields 
    * verify: 
    *    only one contact created
    **********************************************************************************************************/            
    static testMethod void ManyDIDuplicateEmailNewContacts() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDIDuplicateEmailNewContacts') return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
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
        List<Contact> listCon = getContacts();
        System.assertEquals(1, listCon.size());
        System.assertEquals('c1 C1', listCon[0].Name);

        listDI = getDIs();
        System.assertEquals(3, listDI.size());
        System.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(listDI[1].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(listDI[2].Contact1Imported__c, listCon[0].Id);
        System.assertNotEquals(null, listDI[0].HouseholdAccountImported__c);
        System.assertNotEquals(null, listDI[1].HouseholdAccountImported__c);
        System.assertNotEquals(null, listDI[2].HouseholdAccountImported__c);
        System.assertEquals(label.bdiCreated, listDI[0].Contact1ImportStatus__c);
        System.assertEquals(label.bdiMatched, listDI[1].Contact1ImportStatus__c);        
        System.assertEquals(label.bdiMatched, listDI[1].Contact1ImportStatus__c);        
    }
    
    /*********************************************************************************************************
    * @description operation: 
    *    import matching contacts within multiple di records in the same batch, using different phone fields 
    * verify: 
    *    only one contact created
    **********************************************************************************************************/            
    static testMethod void ManyDIDuplicatePhoneNewContacts() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDIDuplicatePhoneNewContacts') return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Home_Phone__c='123-456-7890'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Work_Phone__c='123-456-7890'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Mobile_Phone__c='123-456-7890'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Other_Phone__c='123-456-7890'));
        insert listDI;
        
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Contact_Matching_Rule__c = 'Firstname,Lastname,Phone';
        
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
        System.assertEquals(4, listDI.size());
        System.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(listDI[1].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(listDI[2].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(listDI[3].Contact1Imported__c, listCon[0].Id);
        System.assertNotEquals(null, listDI[0].HouseholdAccountImported__c);
        System.assertNotEquals(null, listDI[1].HouseholdAccountImported__c);
        System.assertNotEquals(null, listDI[2].HouseholdAccountImported__c);
        System.assertNotEquals(null, listDI[3].HouseholdAccountImported__c);
        System.assertEquals(label.bdiCreated, listDI[0].Contact1ImportStatus__c);
        System.assertEquals(label.bdiMatched, listDI[1].Contact1ImportStatus__c);        
        System.assertEquals(label.bdiMatched, listDI[2].Contact1ImportStatus__c);        
        System.assertEquals(label.bdiMatched, listDI[3].Contact1ImportStatus__c);        
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import matching contacts within multiple di records in the same batch, updating different fields 
    * verify: 
    *    only one contact created
    **********************************************************************************************************/            
    static testMethod void ManyDIDuplicateNewContactManyFields() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDIDuplicateNewContactManyFields') return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@foo.com', 
            Contact1_Title__c='myTitle'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@foo.com', 
            Contact1_Birthdate__c=System.Today()));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@foo.com', 
            Contact1_Home_Phone__c='123-456-7890'));
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
        System.assertEquals('myTitle', listCon[0].Title);
        System.assertEquals(System.Today(), listCon[0].Birthdate);
        System.assertEquals('123-456-7890', listCon[0].HomePhone);

        listDI = getDIs();
        System.assertEquals(3, listDI.size());
        System.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(listDI[1].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(listDI[2].Contact1Imported__c, listCon[0].Id);
        System.assertNotEquals(null, listDI[0].HouseholdAccountImported__c);
        System.assertNotEquals(null, listDI[1].HouseholdAccountImported__c);
        System.assertNotEquals(null, listDI[2].HouseholdAccountImported__c);
        System.assertEquals(label.bdiCreated, listDI[0].Contact1ImportStatus__c);
        System.assertEquals(label.bdiMatched, listDI[1].Contact1ImportStatus__c);        
        System.assertEquals(label.bdiMatched, listDI[1].Contact1ImportStatus__c);        
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import existing contacts within multiple di records in the same batch, using different email fields 
    * verify: 
    *    all contacts matched
    **********************************************************************************************************/            
    static testMethod void ManyDIDuplicateEmailExistingContacts() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;
        
        if (strTestOnly != '*' && strTestOnly != 'ManyDIDuplicateEmailExistingContacts') return;
            
         // existing contacts
        List<Contact> listConExisting = new List<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com'));
        listConExisting.add(new Contact(Firstname='c2', Lastname='C2', npe01__HomeEmail__c='c2@C2.com'));
        listConExisting.add(new Contact(Firstname='c3', Lastname='C3', npe01__WorkEmail__c='c3@C3.com'));
        listConExisting.add(new Contact(Firstname='c4', Lastname='C4', npe01__AlternateEmail__c='c4@C4.com'));
        insert listConExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);
 
        List<DataImport__c> listDI = new List<DataImport__c>();
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
        List<Contact> listCon = getContacts();
        System.assertEquals(4, listCon.size());

        listDI = getDIs();
        System.assertEquals(4, listDI.size());
        System.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(listDI[1].Contact1Imported__c, listCon[1].Id);
        System.assertEquals(listDI[2].Contact1Imported__c, listCon[2].Id);
        System.assertEquals(listDI[3].Contact1Imported__c, listCon[3].Id);
        System.assertNotEquals(null, listDI[0].HouseholdAccountImported__c);
        System.assertNotEquals(null, listDI[1].HouseholdAccountImported__c);
        System.assertNotEquals(null, listDI[2].HouseholdAccountImported__c);
        System.assertEquals(label.bdiMatched, listDI[0].Contact1ImportStatus__c);
        System.assertEquals(label.bdiMatched, listDI[1].Contact1ImportStatus__c);        
        System.assertEquals(label.bdiMatched, listDI[2].Contact1ImportStatus__c);        
        System.assertEquals(label.bdiMatched, listDI[3].Contact1ImportStatus__c);        
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import existing contacts within multiple di records in the same batch, using overlapping email fields 
    * verify: 
    *    all contacts matched
    **********************************************************************************************************/            
    static testMethod void ManyDIOverlappingEmailExistingContacts() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'ManyDIOverlappingEmailExistingContacts') return;
            
         // existing contacts
        List<Contact> listConExisting = new List<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@c1.com'));
        insert listConExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);
 
        List<DataImport__c> listDI = new List<DataImport__c>();
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
        List<Contact> listCon = getContacts();
        System.assertEquals(1, listCon.size());
        System.assertEquals('c1@c1.com', listCon[0].npe01__HomeEmail__c);
        System.assertEquals('c1@alt.com', listCon[0].npe01__AlternateEmail__c);
        System.assertEquals('c1@alt.com', listCon[0].npe01__WorkEmail__c);
        
        
        listDI = getDIs();
        System.assertEquals(3, listDI.size());
        System.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(listDI[1].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(listDI[2].Contact1Imported__c, listCon[0].Id);
        System.assertNotEquals(null, listDI[0].HouseholdAccountImported__c);
        System.assertNotEquals(null, listDI[1].HouseholdAccountImported__c);
        System.assertNotEquals(null, listDI[2].HouseholdAccountImported__c);
        System.assertEquals(label.bdiMatched, listDI[0].Contact1ImportStatus__c);
        System.assertEquals(label.bdiMatched, listDI[1].Contact1ImportStatus__c);        
        System.assertEquals(label.bdiMatched, listDI[2].Contact1ImportStatus__c);        
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import existing contacts within multiple di records in the same batch, using overlapping phone fields 
    * verify: 
    *    all contacts matched
    **********************************************************************************************************/            
    static testMethod void ManyDIOverlappingPhoneExistingContacts() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'ManyDIOverlappingPhoneExistingContacts') return;
            
         // existing contacts
        List<Contact> listConExisting = new List<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Phone='123-456-7890'));
        insert listConExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);
 
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Home_Phone__c='123-456-7890'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Home_Phone__c='123-456-7890', Contact1_Mobile_Phone__c='999-888-7777'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Work_Phone__c='999-888-7777'));
        insert listDI;
          
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Contact_Matching_Rule__c = 'Firstname,Lastname,Phone';
        
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(1, listCon.size());
        System.assertEquals('123-456-7890', listCon[0].HomePhone);
        System.assertEquals('999-888-7777', listCon[0].MobilePhone);
        System.assertEquals('999-888-7777', listCon[0].npe01__WorkPhone__c);
        
        
        listDI = getDIs();
        System.assertEquals(3, listDI.size());
        System.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(listDI[1].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(listDI[2].Contact1Imported__c, listCon[0].Id);
        System.assertNotEquals(null, listDI[0].HouseholdAccountImported__c);
        System.assertNotEquals(null, listDI[1].HouseholdAccountImported__c);
        System.assertNotEquals(null, listDI[2].HouseholdAccountImported__c);
        System.assertEquals(label.bdiMatched, listDI[0].Contact1ImportStatus__c);
        System.assertEquals(label.bdiMatched, listDI[1].Contact1ImportStatus__c);        
        System.assertEquals(label.bdiMatched, listDI[2].Contact1ImportStatus__c);        
    }

   /*********************************************************************************************************
    * @description operation: 
    *    import existing contacts within multiple di records in the same batch, using Custom Unique Id matching 
    * verify: 
    *    all contacts matched
    **********************************************************************************************************/            
    static testMethod void ManyDIUniqueIdMatchingExistingContacts() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'ManyDIUniqueIdMatchingExistingContacts') return;

        //Since Data Import API does not have other non-encryptable fields to test matching on,
        //we need to exit the test if the matching is done on the encrypted field. 
        if (!Schema.sObjectType.Contact.fields.Title.isFilterable()) return;
            
         // existing contacts
        List<Contact> listConExisting = new List<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='foo@bar.com', Title='c1Title'));
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@c1.com', Title='c1PrimeTitle'));
        insert listConExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);
 
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@c1.com', Contact1_Title__c='c1Title'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@c1.com', Contact1_Title__c='c1PrimeTitle'));
        insert listDI;
        
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        // for testing, we need to use an existing contact field that exists on both Contact and the DI.
        diSettings.Contact_Custom_Unique_ID__c = 'Title';
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(2, listCon.size());
        
        listDI = getDIs();
        System.assertEquals(2, listDI.size());
        System.assertEquals(listDI[0].Contact1Imported__c, listConExisting[0].Id);
        System.assertEquals(listDI[1].Contact1Imported__c, listConExisting[1].Id);
        System.assertEquals(label.bdiMatched, listDI[0].Contact1ImportStatus__c);
        System.assertEquals(label.bdiMatched, listDI[1].Contact1ImportStatus__c);        
    }

   /*********************************************************************************************************
    * @description operation: 
    *    import existing contacts within multiple di records in the same batch, using Salesforce Id matching 
    * verify: 
    *    all contacts matched
    **********************************************************************************************************/            
    static testMethod void ManyDISalesforceIdMatchingExistingContacts() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'ManyDISalesforceIdMatchingExistingContacts') return;
            
         // existing contacts
        List<Contact> listConExisting = new List<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='foo@bar.com', Title='t1'));
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@c1.com', Title='t2'));
        insert listConExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);
        
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c=null, Contact1_Lastname__c=null, Contact1_Personal_Email__c=null, 
            Contact1_Title__c='t1Updated', Contact1Imported__c=listConExisting[0].Id));
        listDI.add(new DataImport__c(Contact1_Firstname__c=null, Contact1_Lastname__c=null, Contact1_Personal_Email__c=null, 
            Contact1_Title__c='t2Updated', Contact1Imported__c=listConExisting[1].Id));
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
        System.assertEquals(2, listDI.size());
        System.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(listDI[1].Contact1Imported__c, listCon[1].Id);
        System.assertEquals(listDI[0].Contact1_Title__c, listCon[0].Title);
        System.assertEquals(listDI[1].Contact1_Title__c, listCon[1].Title);
        System.assertEquals(label.bdiMatched, listDI[0].Contact1ImportStatus__c);
        System.assertEquals(label.bdiMatched, listDI[1].Contact1ImportStatus__c);        
    }

   /*********************************************************************************************************
    * @description operation: 
    *    import existing contacts by Id only, and specify new household member, using Salesforce Id matching 
    * verify: 
    *    all contacts matched or created
    **********************************************************************************************************/            
    static testMethod void ManyDISalesforceIdMatchingExistingAndNewContacts() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'ManyDISalesforceIdMatchingExistingAndNewContacts') return;
            
         // existing contacts
        List<Contact> listConExisting = new List<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='foo@bar.com', Title='t1'));
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@c1.com', Title='t2'));
        insert listConExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);
        
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c=null, Contact1_Lastname__c=null, Contact1_Personal_Email__c=null, 
            Contact1_Title__c='t1Updated', Contact1Imported__c=listConExisting[0].Id, 
            Contact2_Firstname__c='c3', Contact2_Title__c='t3'));
        listDI.add(new DataImport__c(Contact1_Firstname__c=null, Contact1_Lastname__c=null, Contact1_Personal_Email__c=null, 
            Contact1_Title__c='t2Updated', Contact1Imported__c=listConExisting[1].Id, 
            Contact2_Firstname__c='c4', Contact2_Lastname__c='C4', Contact2_Title__c='t4'));
        insert listDI;
        
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(4, listCon.size());
        
        // verify each c2 was created in existing c1's household
        System.assertEquals(listCon[0].AccountId, listCon[2].AccountId);
        System.assertEquals(listCon[1].AccountId, listCon[3].AccountId);
        
        listDI = getDIs();
        System.assertEquals(2, listDI.size());
        System.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(listDI[1].Contact1Imported__c, listCon[1].Id);
        System.assertEquals(listDI[0].Contact1_Title__c, listCon[0].Title);
        System.assertEquals(listDI[1].Contact1_Title__c, listCon[1].Title);
        System.assertEquals(label.bdiMatched, listDI[0].Contact1ImportStatus__c);
        System.assertEquals(label.bdiMatched, listDI[1].Contact1ImportStatus__c);        
        System.assertEquals(label.bdiCreated, listDI[0].Contact2ImportStatus__c);
        System.assertEquals(label.bdiCreated, listDI[1].Contact2ImportStatus__c);        
    }

   /*********************************************************************************************************
    * @description operation: 
    *    import existing contacts by Id only, and specify new household member, using Salesforce Id matching 
    * verify: 
    *    all contacts matched or created
    **********************************************************************************************************/            
    static testMethod void OneDISalesforceIdMatchingExistingAndNewContact() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'OneDISalesforceIdMatchingExistingAndNewContact') return;
            
         // existing contacts
        List<Contact> listConExisting = new List<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1'));
        insert listConExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);
        
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c=null, Contact1_Lastname__c=null, Contact1_Personal_Email__c=null, 
            Contact1Imported__c=listConExisting[0].Id, 
            Contact2_Firstname__c='c2', Contact2_Lastname__c='C2'));
        insert listDI;
        
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Contact_Matching_Rule__c = 'Firstname;Lastname';

        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(2, listCon.size());
        
        // verify each c2 was created in existing c1's household
        System.assertEquals(listCon[0].AccountId, listCon[1].AccountId);
        
        listDI = getDIs();
        System.assertEquals(1, listDI.size());
        System.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(listDI[0].Contact1_Title__c, listCon[0].Title);
        System.assertEquals(label.bdiMatched, listDI[0].Contact1ImportStatus__c);
        System.assertEquals(label.bdiCreated, listDI[0].Contact2ImportStatus__c);
    }

   /*********************************************************************************************************
    * @description operation: 
    *    import existing contact into a different existing household account 
    * verify: 
    *    contact moved to specified account
    **********************************************************************************************************/            
    static testMethod void SingleDISalesforceIdMatchingExistingHousehold() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'SingleDISalesforceIdMatchingExistingHousehold') return;
            
         // existing contacts
        List<Contact> listConExisting = new List<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@c1.com', Title='t1'));
        listConExisting.add(new Contact(Firstname='c2', Lastname='C2', Email='c2@c2.com', Title='t2'));
        insert listConExisting;
        
        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);

        listConExisting = getContacts();
        
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@c1.com', 
            Contact1_Title__c='t1Updated', HouseholdAccountImported__c=listConExisting[1].AccountId));
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
        System.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(listDI[0].Contact1_Title__c, listCon[0].Title);
        System.assertEquals(label.bdiMatched, listDI[0].Contact1ImportStatus__c);
        System.assertEquals(listDI[0].HouseholdAccountImported__c, listCon[1].AccountId);
        System.assertEquals(listCon[0].AccountId, listCon[1].AccountId);
    }

   /*********************************************************************************************************
    * @description operation: 
    *    import existing contacts within multiple di records in the same batch, using Custom Unique Id matching 
    * verify: 
    *    all contacts matched
    **********************************************************************************************************/            
    static testMethod void ManyDIUniqueIdNotMatchingExistingContacts() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDIUniqueIdNotMatchingExistingContacts') return;

        //Since Data Import API does not have other non-encryptable fields to test matching on,
        //we need to exit the test if the matching is done on the encrypted field. 
        if (!Schema.sObjectType.Contact.fields.Title.isFilterable()) return;
            
         // existing contacts
        List<Contact> listConExisting = new List<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@c1.com', Title='ID1'));
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@c1.com', Title='ID2'));
        insert listConExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);
 
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@c1.com', Contact1_Title__c='ID3'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@c1.com', Contact1_Title__c='ID4'));
        insert listDI;
        
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        // for testing, we need to use an existing contact field that exists on both Contact and the DI.
        diSettings.Contact_Custom_Unique_ID__c = 'Title';
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(4, listCon.size());
        
        listDI = getDIs();
        System.assertEquals(2, listDI.size());
        System.assertEquals(listDI[0].Contact1Imported__c, listCon[2].Id);
        System.assertEquals(listDI[1].Contact1Imported__c, listCon[3].Id);
        System.assertEquals(label.bdiCreated, listDI[0].Contact1ImportStatus__c);
        System.assertEquals(label.bdiCreated, listDI[1].Contact1ImportStatus__c);        
    }

   /*********************************************************************************************************
    * @description operation: 
    *    import new contacts within multiple di records in the same batch, using Custom Unique Id matching 
    * verify: 
    *    all contacts created, since unique Id's provided
    **********************************************************************************************************/            
    static testMethod void ManyDIUniqueIdNewContacts() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDIUniqueIdNewContacts') return;

        //Since Data Import API does not have other non-encryptable fields to test matching on,
        //we need to exit the test if the matching is done on the encrypted field. 
        if (!Schema.sObjectType.Contact.fields.Title.isFilterable()) return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@c1.com', Contact1_Title__c='ID1'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@c1.com', Contact1_Title__c='ID2'));
        insert listDI;
        
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        // for testing, we need to use an existing contact field that exists on both Contact and the DI.
        diSettings.Contact_Custom_Unique_ID__c = 'Title';
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results.
        List<Contact> listCon = getContacts();
        System.assertEquals(2, listCon.size());
        
        listDI = getDIs();
        System.assertEquals(2, listDI.size());
        System.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(listDI[1].Contact1Imported__c, listCon[1].Id);
        System.assertEquals(label.bdiCreated, listDI[0].Contact1ImportStatus__c);
        System.assertEquals(label.bdiCreated, listDI[1].Contact1ImportStatus__c);        
    }

   /*********************************************************************************************************
    * @description operation: 
    *    import existing & new contacts within multiple di records in the same batch, using Custom Unique Id matching 
    * verify: 
    *    all contacts matched
    **********************************************************************************************************/            
    static testMethod void ManyDIUniqueIdMatchingNewAndExistingContacts() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'ManyDIUniqueIdMatchingNewAndExistingContacts') return;

        //Since Data Import API does not have other non-encryptable fields to test matching on,
        //we need to exit the test if the matching is done on the encrypted field. 
        if (!Schema.sObjectType.Contact.fields.Title.isFilterable()) return;
            
         // existing contacts
        List<Contact> listConExisting = new List<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@foo.com', Title='id1'));
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@foo.com', Title='id2'));
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@foo.com', Title=null));
        listConExisting.add(new Contact(Firstname='c2', Lastname='C2', Email='c2@foo.com', Title='id4'));
        insert listConExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);
 
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@foo.com', Contact1_Title__c='id1'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@foo.com', Contact1_Title__c='id3'));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c1', Contact1_Lastname__c='C1', Contact1_Personal_Email__c='c1@foo.com', Contact1_Title__c=null));
        listDI.add(new DataImport__c(Contact1_Firstname__c='c2', Contact1_Lastname__c='C2', Contact1_Personal_Email__c='c2@foo.com', Contact1_Title__c=null));
        insert listDI;
        
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        // for testing, we need to use an existing contact field that exists on both Contact and the DI.
        diSettings.Contact_Custom_Unique_ID__c = 'Title';
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Contact> listCon = getContacts(); // Creation order
        System.assertEquals(6, listCon.size());
        
        listDI = getDIs();
        System.assertEquals(4, listDI.size());

        System.assertEquals(listDI[0].Contact1Imported__c, listCon[0].Id);
        System.assertEquals(listDI[0].Contact1ImportStatus__c, label.bdiMatched);

        System.assertEquals(listDI[1].Contact1Imported__c, listCon[4].Id);
        System.assertEquals(listDI[1].Contact1ImportStatus__c, label.bdiCreated);

        System.assertEquals(listDI[2].Contact1Imported__c, listCon[2].Id);
        System.assertEquals(listDI[2].Contact1ImportStatus__c, label.bdiMatched);        

        System.assertEquals(listDI[3].Contact1Imported__c, listCon[5].Id);
        System.assertEquals(listDI[3].Contact1ImportStatus__c, label.bdiCreated);        
    }

   /*********************************************************************************************************
    * @description operation: 
    *    import existing accounts within multiple di records in the same batch, using Custom Unique Id matching 
    * verify: 
    *    all accounts matched
    **********************************************************************************************************/            
    static testMethod void ManyDIUniqueIdMatchingExistingAccounts() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDIUniqueIdMatchingExistingAccounts') return;
            
         // existing Accounts
        List<Account> listAccExisting = new List<Account>();
        listAccExisting.add(new Account(Name='foo', Phone='415-111-4567'));
        listAccExisting.add(new Account(Name='a1', Phone='415-222-2222'));
        insert listAccExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listAccExisting);

        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(new DataImport__c(Account1_Name__c='z', Account1_Phone__c='415-111-4567'));
        listDI.add(new DataImport__c(Account1_Name__c='a1', Account1_Phone__c='415-333-3333'));
        insert listDI;
        
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        // for testing, we need to use an existing account field that exists on both Account and the DI.
        diSettings.Account_Custom_Unique_ID__c = 'Phone';
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Account> listAcc = getAccounts();
        System.assertEquals(3, listAcc.size());
        
        listDI = getDIs();
        System.assertEquals(2, listDI.size());
        System.assertEquals(listDI[0].Account1Imported__c, listAccExisting[0].Id);
        System.assertEquals(listDI[0].Account1_Name__c, listAcc[0].Name);
        System.assertNotEquals(listDI[1].Account1Imported__c, listAccExisting[1].Id);
        System.assertEquals(label.bdiMatched, listDI[0].Account1ImportStatus__c);
        System.assertEquals(label.bdiCreated, listDI[1].Account1ImportStatus__c);        
    }

   /*********************************************************************************************************
    * @description operation: 
    *    import new accounts within multiple di records in the same batch, using Custom Unique Id matching 
    * verify: 
    *    all accounts matched
    **********************************************************************************************************/            
    static testMethod void ManyDIUniqueIdNewAccounts() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDIUniqueIdNewAccounts') return;
            
 
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(new DataImport__c(Account1_Name__c='a1', Account1_Phone__c='415-111-4567'));
        listDI.add(new DataImport__c(Account1_Name__c='a1', Account1_Phone__c='415-222-4567'));
        insert listDI;
        
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        // for testing, we need to use an existing account field that exists on both Account and the DI.
        diSettings.Account_Custom_Unique_ID__c = 'Phone';
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Account> listAcc = getAccounts();
        System.assertEquals(2, listAcc.size());
        
        listDI = getDIs();
        System.assertEquals(2, listDI.size());
        System.assertEquals(label.bdiCreated, listDI[0].Account1ImportStatus__c);
        System.assertEquals(label.bdiCreated, listDI[1].Account1ImportStatus__c);        
    }

   /*********************************************************************************************************
    * @description operation: 
    *    import existing accounts within multiple di records in the same batch, using Custom Unique Id matching 
    * verify: 
    *    all accounts matched
    **********************************************************************************************************/            
    static testMethod void ManyDIUniqueIdMatchingNewAndExistingAccounts() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDIUniqueIdMatchingNewAndExistingAccounts') return;
            
         // existing Accounts
        List<Account> listAccExisting = new List<Account>();
        listAccExisting.add(new Account(Name='a1', Phone='415-111-4567'));
        listAccExisting.add(new Account(Name='a1', Phone='415-222-2222'));
        listAccExisting.add(new Account(Name='a1', Phone=null));
        listAccExisting.add(new Account(Name='a2', Phone='415-444-4444'));
        insert listAccExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listAccExisting);
 
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(new DataImport__c(Account1_Name__c='a1', Account1_Phone__c='415-111-4567'));
        listDI.add(new DataImport__c(Account1_Name__c='a1', Account1_Phone__c='415-333-4567'));
        listDI.add(new DataImport__c(Account1_Name__c='a1', Account1_Phone__c=null));
        listDI.add(new DataImport__c(Account1_Name__c='a2', Account1_Phone__c=null));
        insert listDI;
        
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        // for testing, we need to use an existing account field that exists on both Account and the DI.
        diSettings.Account_Custom_Unique_ID__c = 'Phone';
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Account> listAcc = getAccounts(); // Creation order
        System.assertEquals(6, listAcc.size());
        
        listDI = getDIs();
        System.assertEquals(4, listDI.size());
        
        System.assertEquals(listDI[0].Account1Imported__c, listAcc[0].Id);
        System.assertEquals(listDI[0].Account1ImportStatus__c, label.bdiMatched);

        System.assertEquals(listDI[1].Account1Imported__c, listAcc[4].Id);
        System.assertEquals(listDI[1].Account1ImportStatus__c, label.bdiCreated);

        System.assertEquals(listDI[2].Account1Imported__c, listAcc[2].Id);
        System.assertEquals(listDI[2].Account1ImportStatus__c, label.bdiMatched);

        System.assertEquals(listDI[3].Account1Imported__c, listAcc[5].Id);
        System.assertEquals(listDI[3].Account1ImportStatus__c, label.bdiCreated);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import new contacts with a variety of emails  
    * verify: 
    *    correct preferred email set for contacts with only one email specified
        preferred email left null for contants with multiple emails specified
    **********************************************************************************************************/            
    static testMethod void testPreferredEmailAutoSetting() {
        if (strTestOnly != '*' && strTestOnly != 'testPreferredEmailAutoSetting') return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(BDI_DataImport_TEST.newDI('c0', 'C0'));
        listDI.add(BDI_DataImport_TEST.newDI('c1', 'C1'));
        listDI.add(BDI_DataImport_TEST.newDI('c2', 'C2'));
        listDI.add(BDI_DataImport_TEST.newDI('c3', 'C3'));
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
        List<Contact> listCon = getContacts();
        System.assertEquals(4, listCon.size());
        System.assertEquals('Personal', listCon[0].npe01__Preferred_Email__c);
        System.assertEquals('Work', listCon[1].npe01__Preferred_Email__c);
        System.assertEquals('Alternate', listCon[2].npe01__Preferred_Email__c);
        // turns out we can't assume this, because the org may have a value specified as default!
        //System.assertEquals(null, listCon[3].npe01__Preferred_Email__c);
      
        listDI = getDIs();
        System.assertEquals(4, listDI.size());
        for (integer i = 0; i < 3; i++) {
            System.assertEquals(listDI[i].Contact1Imported__c, listCon[i].Id);
            System.assertEquals(label.bdiCreated, listDI[i].Contact1ImportStatus__c);
            System.assertEquals(listDI[i].Contact1_Preferred_Email__c, listCon[i].npe01__Preferred_Email__c);
        }
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import new contacts with a variety of phones  
    * verify: 
    *    correct preferred phone set for contacts with only one phone specified
        preferred Phone left null for contants with multiple Phones specified
    **********************************************************************************************************/            
    static testMethod void testPreferredPhoneAutoSetting() {
        if (strTestOnly != '*' && strTestOnly != 'testPreferredPhoneAutoSetting') return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(BDI_DataImport_TEST.newDI('c0', 'C0'));
        listDI.add(BDI_DataImport_TEST.newDI('c1', 'C1'));
        listDI.add(BDI_DataImport_TEST.newDI('c2', 'C2'));
        listDI.add(BDI_DataImport_TEST.newDI('c3', 'C3'));
        listDI.add(BDI_DataImport_TEST.newDI('c4', 'C4'));
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
        List<Contact> listCon = getContacts();
        System.assertEquals(5, listCon.size());
        System.assertEquals('Home', listCon[0].npe01__PreferredPhone__c);
        System.assertEquals('Work', listCon[1].npe01__PreferredPhone__c);
        System.assertEquals('Mobile', listCon[2].npe01__PreferredPhone__c);
        System.assertEquals('Other', listCon[3].npe01__PreferredPhone__c);
        // turns out we can't assume this, because the org may have a value specified as default!
        //System.assertEquals(null, listCon[4].npe01__PreferredPhone__c);
      
        listDI = getDIs();
        System.assertEquals(5, listDI.size());
        for (integer i = 0; i < 4; i++) {
            System.assertEquals(listDI[i].Contact1Imported__c, listCon[i].Id);
            System.assertEquals(label.bdiCreated, listDI[i].Contact1ImportStatus__c);
            System.assertEquals(listDI[i].Contact1_Preferred_Phone__c, listCon[i].npe01__PreferredPhone__c);
        }
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import contacts using different matching rules 
    * verify: 
    *    only one contact created
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
    static testMethod void ManyDIMultiContactMatchRules6() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDIMultiContactMatchRules6') return;
        ManyDIMultiContactMatchRules('Firstname,Lastname,Phone');
    }
    static testMethod void ManyDIMultiContactMatchRules7() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDIMultiContactMatchRules7') return;
        ManyDIMultiContactMatchRules('Firstname,Phone');
    }
    static testMethod void ManyDIMultiContactMatchRules8() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDIMultiContactMatchRules8') return;
        ManyDIMultiContactMatchRules('Lastname,Phone');
    }
    static testMethod void ManyDIMultiContactMatchRules9() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDIMultiContactMatchRules9') return;
        ManyDIMultiContactMatchRules('Phone');
    }
    static void ManyDIMultiContactMatchRules(string strRule) {            
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(new DataImport__c(Account1_Name__c='a0', Contact1_Firstname__c='c0', Contact1_Lastname__c='C0'));
        listDI.add(new DataImport__c(Account1_Name__c='a1', Contact1_Firstname__c=null, Contact1_Lastname__c='C1'));
        listDI.add(new DataImport__c(Account1_Name__c='a2', Contact1_Firstname__c='c2', Contact1_Lastname__c=null));
        listDI.add(new DataImport__c(Account1_Name__c='a3', Contact1_Firstname__c='c3', Contact1_Lastname__c='C3', 
            Contact1_Personal_Email__c='c3@C3.com', Contact1_Home_Phone__c='123-456-7890'));   
        
        // one additional di that will always match given the current rule.
        listDI.add(new DataImport__c(Account1_Name__c='a4', Contact1_Firstname__c='c3', Contact1_Lastname__c='C3', 
            Contact1_Personal_Email__c='c3@C3.com', Contact1_Home_Phone__c='123-456-7890'));                
        insert listDI;
          
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Contact_Matching_Rule__c = strRule;
 
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(3, listCon.size());
        
        listDI = getDIs();
        System.assertEquals(5, listDI.size());
        for (integer i = 0; i < listDI.size(); i++) {
            if (listDI[i].Account1_Name__c == 'a2') {
                System.assertEquals(label.bdiErrorInvalidLastname, listDI[i].Contact1ImportStatus__c);
                System.assertEquals(BDI_DataImport_API.bdiFailed, listDI[i].Status__c);
            } else if (listDI[i].Account1_Name__c == 'a4') {
                System.assertNotEquals(null, listDI[i].Contact1Imported__c);
                System.assertEquals(label.bdiMatched, listDI[i].Contact1ImportStatus__c);
                System.assertEquals(BDI_DataImport_API.bdiImported, listDI[i].Status__c);
            } else {
                System.assertNotEquals(null, listDI[i].Contact1Imported__c);
                System.assertEquals(label.bdiCreated, listDI[i].Contact1ImportStatus__c);
                System.assertEquals(BDI_DataImport_API.bdiImported, listDI[i].Status__c);
            }
            
        }
    }
    
    /*********************************************************************************************************
    * @description operation: 
    *    import contacts with some missing required fields 
    * verify: 
    *    contacts with errors not created, failures logged in di records
        contacts without errors are created
    **********************************************************************************************************/            
    static testMethod void ManyDISomeInvalidContactData() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDISomeInvalidContactData') return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(new DataImport__c(Contact1_Firstname__c='c0', Contact1_Lastname__c=null, Contact1_Personal_Email__c='c0@foo.com', Contact2_Firstname__c='c0b', Contact2_Lastname__c='C0b', Account1_Name__c='foo'));
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
        List<Contact> listCon = getContacts();
        System.assertEquals(4, listCon.size());
        System.assertEquals('c1 C1', listCon[0].Name);

        listDI = getDIs();
        System.assertEquals(5, listDI.size());
        integer cC1 = 0;
        integer cC2 = 0;
        for (integer i = 0; i < listDI.size(); i++) {
            if (listDI[i].Contact1Imported__c != null) {
                System.assertEquals(label.bdiCreated, listDI[i].Contact1ImportStatus__c);
                cC1++;
            } 
            
            // make sure when c1 fails, we don't incorrectly mark c2 as created
            if (listDI[i].Contact1_Firstname__c == 'c0') {
                System.assertEquals(null, listDI[i].Contact2ImportStatus__c);
                System.assertEquals(null, listDI[i].Account1ImportStatus__c);
            }
            
            if (listDI[i].Contact2Imported__c != null) {
                System.assertEquals(label.bdiCreated, listDI[i].Contact2ImportStatus__c);            
                cC2++;
            }
            if (listDI[i].Contact1Imported__c == null && listDI[i].Contact2Imported__c == null) {
                System.assertEquals(BDI_DataImport_API.bdiFailed, listDI[i].Status__c);
                System.assertNotEquals(null, listDI[i].FailureInformation__c);    
                System.assert(listDI[i].FailureInformation__c.contains(label.bdiErrorInvalidLastname));                 
            }
        }
        System.assertEquals(2, cC1);
        System.assertEquals(2, cC2);
    }
    
    /*********************************************************************************************************
    * @description operation: 
    *    import contacts with some data that forces commit errors 
    * verify: 
    *    contacts with errors not created, failures logged in di records
    *    contacts without errors are created
    **********************************************************************************************************/            
    static testMethod void ManyDITestContactDataErrorHandling() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDITestContactDataErrorHandling') return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
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
        List<Contact> listCon = getContacts();
        System.assertEquals(4, listCon.size());
        System.assertEquals('c1 C1', listCon[0].Name);

        listDI = getDIs();
        System.assertEquals(5, listDI.size());
        integer cC1 = 0;
        integer cC2 = 0;
        for (integer i = 0; i < listDI.size(); i++) {
            if (listDI[i].Contact1Imported__c != null) {
                System.assertEquals(label.bdiCreated, listDI[i].Contact1ImportStatus__c);
                cC1++;
            }
            if (listDI[i].Contact2Imported__c != null) {
                System.assertEquals(label.bdiCreated, listDI[i].Contact2ImportStatus__c);            
                cC2++;
            }
            if (listDI[i].Contact1Imported__c == null && listDI[i].Contact2Imported__c == null) {
                System.assertEquals(BDI_DataImport_API.bdiFailed, listDI[i].Status__c);
                System.assertNotEquals(null, listDI[i].FailureInformation__c);    
                System.assert(listDI[i].Contact1ImportStatus__c != null || listDI[i].Contact2ImportStatus__c != null);                 
            }
        }
        System.assertEquals(2, cC1);
        System.assertEquals(2, cC2);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import accounts with some data that forces commit errors 
    * verify: 
    *    accounts with errors not created, failures logged in di records
    *    accounts without errors are created
    **********************************************************************************************************/            
    static testMethod void ManyDITestAccountDataErrorHandling() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDITestAccountDataErrorHandling') return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
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
        List<Account> listAcc = getAccounts();
        System.assertEquals(6, listAcc.size());

        listDI = getDIs();
        System.assertEquals(10, listDI.size());
        integer cA1 = 0;
        integer cA2 = 0;
        for (integer i = 0; i < listDI.size(); i++) {
            if (listDI[i].Account1Imported__c != null) {
                System.assertEquals(label.bdiCreated, listDI[i].Account1ImportStatus__c);
                cA1++;
            }
            if (listDI[i].Account2Imported__c != null) {
                System.assertEquals(label.bdiCreated, listDI[i].Account2ImportStatus__c);            
                cA2++;
            }
            if (listDI[i].Account1Imported__c == null && listDI[i].Account2Imported__c == null) {
                System.assertEquals(BDI_DataImport_API.bdiFailed, listDI[i].Status__c);
                System.assertNotEquals(null, listDI[i].FailureInformation__c);    
                System.assert(listDI[i].Account1ImportStatus__c != null || listDI[i].Account2ImportStatus__c != null);                 
            }
        }
        System.assertEquals(3, cA1);
        System.assertEquals(3, cA2);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations with some data that forces commit errors 
    * verify: 
    *    donations with errors not created, failures logged in di records
    *    donations without errors are created
    **********************************************************************************************************/            
    static testMethod void ManyDITestDonationDataErrorHandling() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDITestDonationDataErrorHandling') return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
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
        list<Opportunity> listOpp = getOpps();
        System.assertEquals(2, listOpp.size());

        listDI = getDIs();
        System.assertEquals(6, listDI.size());
        integer cOpp = 0;
        for (integer i = 0; i < listDI.size(); i++) {
            if (listDI[i].DonationImported__c != null) {
                System.assertEquals(label.bdiCreated, listDI[i].DonationImportStatus__c);
                cOpp++;
            } else {
                System.assertEquals(BDI_DataImport_API.bdiFailed, listDI[i].Status__c);
                System.assertNotEquals(null, listDI[i].FailureInformation__c);    
                System.assertNotEquals(null, listDI[i].DonationImportStatus__c);    
            }
        }
        System.assertEquals(cOpp, listOpp.size());
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import donations with campaigns that have some data that forces commit errors 
    * verify: 
    *    campaigns with errors not created, failures logged in di records
    *    campaigns without errors are created
    **********************************************************************************************************/            
    static testMethod void ManyDITestCampaignDataErrorHandling() {
        if (strTestOnly != '*' && strTestOnly != 'ManyDITestCampaignDataErrorHandling') return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(new DataImport__c(Account1_Name__c='a0', Donation_Donor__c='Account1', Donation_Amount__c=10, Donation_Campaign_Name__c='cmp1'));
        listDI.add(new DataImport__c(Account1_Name__c='FailTest1', Donation_Donor__c='Account1', Donation_Amount__c=20, Donation_Campaign_Name__c='cmpNotCreated'));
        listDI.add(new DataImport__c(Account1_Name__c='a2', Donation_Donor__c='Account1', Donation_Amount__c=30, Donation_Campaign_Name__c='cmp1'));
        listDI.add(new DataImport__c(Account1_Name__c='a3', Donation_Donor__c='Account1', Donation_Amount__c=40, Donation_Campaign_Name__c='cmp2'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Opportunity> listOpp = getOpps();
        System.assertEquals(3, listOpp.size());
        List<Campaign> listCmp = getCampaigns();
        System.assertEquals(2, listCmp.size());

        listDI = getDIs();
        System.assertEquals(4, listDI.size());
        for (integer i = 0; i < listDI.size(); i++) {
            if (listDI[i].Donation_Campaign_Name__c == 'cmpNotCreated') {
                System.assertEquals(BDI_DataImport_API.bdiFailed, listDI[i].Status__c);
                System.assertNotEquals(label.bdiCreated, listDI[i].DonationImportStatus__c);
                System.assertEquals(null, listDI[i].DonationImported__c);
            } else {
                System.assertEquals(BDI_DataImport_API.bdiImported, listDI[i].Status__c);
                System.assertEquals(null, listDI[i].FailureInformation__c);    
                System.assertEquals(label.bdiCreated, listDI[i].DonationImportStatus__c);    
            }
        }
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import addresses with some data that forces commit errors 
    * verify: 
    *    addresses with errors not created, failures logged in di records
    *    addresses without errors are created
    **********************************************************************************************************/            
    static testMethod void ManyDITestAddressDataErrorHandling() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'ManyDITestAddressDataErrorHandling') return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
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
        List<Address__c> listAddr = getAddresses();
        System.assertEquals(2, listAddr.size());

        listDI = getDIs();
        System.assertEquals(3, listDI.size());
        integer cAddr = 0;
        for (integer i = 0; i < listDI.size(); i++) {
            if (listDI[i].HomeAddressImported__c != null) {
                System.assertEquals(label.bdiCreated, listDI[i].HomeAddressImportStatus__c);
                cAddr++;
            } else {
                System.assertEquals(BDI_DataImport_API.bdiFailed, listDI[i].Status__c);
                System.assertNotEquals(null, listDI[i].FailureInformation__c);    
                System.assertNotEquals(null, listDI[i].HomeAddressImportStatus__c);    
            }
        }
        System.assertEquals(cAddr, listAddr.size());
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import multiple di records with C2 not fully providing match critera, in the same batch 
    * verify: 
    *    duplicate C2's not created
    **********************************************************************************************************/            
    static testMethod void TwoDINewC2PartialMatch() {
        if (strTestOnly != '*' && strTestOnly != 'TwoDINewC2PartialMatch') return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
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
        Map<Id, Contact> contactById = new Map<Id, Contact>(getContacts());
        System.assertEquals(2, contactById.size());

        listDI = getDIs();
        System.assertEquals(2, listDI.size());

        System.assertEquals(listDI[0].Contact1Imported__c, listDI[1].Contact1Imported__c);
        System.assertEquals(listDI[0].Contact2Imported__c, listDI[1].Contact2Imported__c);
        System.assertNotEquals(listDI[1].Contact1ImportStatus__c, listDI[0].Contact1ImportStatus__c);
        System.assertNotEquals(listDI[1].Contact2ImportStatus__c, listDI[0].Contact2ImportStatus__c);
        // 1 set created, 1 set matched.
        System.assert(contactById.containsKey(listDI[0].Contact1Imported__c));
        System.assert(contactById.containsKey(listDI[0].Contact2Imported__c));
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import multiple di records with Existing C2 not fully providing match critera, in the same batch 
    * verify: 
    *    duplicate C2's not created
    **********************************************************************************************************/            
    static testMethod void TwoDIExistingC2PartialMatch() {
        if (strTestOnly != '*' && strTestOnly != 'TwoDIExistingC2PartialMatch') return;
            
         // existing contacts in same household
        Account hh = new Account(Name='household', npe01__SYSTEM_AccountType__c=CAO_Constants.HH_ACCOUNT_TYPE);
        insert hh;
        List<Contact> listConExisting = new List<Contact>();
        listConExisting.add(new Contact(Firstname='c1', Lastname='C1', Email='c1@C1.com', AccountId=hh.Id));
        listConExisting.add(new Contact(Firstname='c2', Lastname='C2', Email='c2@C2.com', AccountId=hh.Id));
        insert listConExisting;

        UTIL_UnitTestData_TEST.setFixedSearchResults(listConExisting);
 
        // data import records
        List<DataImport__c> listDI = new List<DataImport__c>();
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
        Map<Id, Contact> contactById = new Map<Id, Contact>(getContacts());
        System.assertEquals(2, contactById.size());

        listDI = getDIs();
        System.assertEquals(2, listDI.size());
        for (DataImport__c di : listDI) {
            System.assert(contactById.containsKey(di.Contact1Imported__c));
            System.assertEquals(di.Contact1_Firstname__c + ' ' + di.Contact1_Lastname__c, contactById.get(di.Contact1Imported__c).Name);
            System.assert(contactById.containsKey(di.Contact2Imported__c));
            System.assertEquals(di.Contact2_Firstname__c + ' ' + di.Contact2_Lastname__c, contactById.get(di.Contact2Imported__c).Name);
            System.assertNotEquals(null, di.HouseholdAccountImported__c);
            System.assertEquals(label.bdiMatched, di.Contact1ImportStatus__c);
            System.assertEquals(label.bdiMatched, di.Contact2ImportStatus__c);
        }
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import new contacts, but fail field level security  
    * verify: 
    *    nothing imported
    *    records marked with fls error
    **********************************************************************************************************/            
    static testMethod void testFieldLevelSecurity() {
        if (strTestOnly != '*' && strTestOnly != 'testFieldLevelSecurity') return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(BDI_DataImport_TEST.newDI('c0', 'C0'));
        listDI.add(BDI_DataImport_TEST.newDI('c1', 'C1'));
        listDI.add(BDI_DataImport_TEST.newDI('c2', 'C2'));
        listDI.add(BDI_DataImport_TEST.newDI('c3', 'C3'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        BDI_DataImportService.failFieldLevelSecurity = true;
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Contact> listCon = getContacts();
        System.assertEquals(0, listCon.size());
      
        listDI = getDIs();
        System.assertEquals(4, listDI.size());
        for (integer i = 0; i < 3; i++) {
            System.assertEquals(listDI[i].Contact1Imported__c, null);
            System.assertEquals(BDI_DataImport_API.bdiFailed, listDI[i].Status__c);
            string flsError = label.flsError;
            flsError = flsError.replace('{0}', '');
            flsError = flsError.replace('.', '');
            //System.assertEquals(listDI[i].FailureInformation__c, flsError);
            System.assert(listDI[i].FailureInformation__c.contains(flsError));
        }
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import contacts with invalid home addresses  
    * verify: 
    *    address objects created
    *    valid contacts' mailing address set
    *    valid hh accounts' billing address set
    *    error logged on correct data import record
    **********************************************************************************************************/            
    static testMethod void testInvalidAddressHandling() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (strTestOnly != '*' && strTestOnly != 'testInvalidAddressHandling') return;
            
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(BDI_DataImport_TEST.newDI('c1', 'C1'));
        listDI.add(BDI_DataImport_TEST.newDI('c2', 'C2'));
        listDI.add(BDI_DataImport_TEST.newDI('c3', 'C3'));
        listDI[0].Home_City__c = 'Seattle';
        listDI[1].Home_City__c = 'This is an invalid city because it is over 40 characters that Salesforce limits on Accounts and Contacts!';
        listDI[2].Home_City__c = 'Portland';
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        BDI_DataImport_BATCH bdi = new BDI_DataImport_BATCH();
        ID ApexJobId = Database.executeBatch(bdi, 10);
        Test.stopTest();
    
        // verify expected results
        List<Address__c> listAddr = getAddresses(); 
        System.assertEquals(2, listAddr.size());
        System.assertEquals('Seattle', listAddr[0].MailingCity__c);
        System.assertEquals('Portland', listAddr[1].MailingCity__c);
        
        listDI = getDIs();
        System.assertEquals(3, listDI.size());
        System.assertEquals(listDI[0].HomeAddressImported__c, listAddr[0].Id); 
        System.assertEquals(listDI[1].HomeAddressImported__c, null);
        System.assertEquals(listDI[2].HomeAddressImported__c, listAddr[1].Id);

        System.assertEquals(label.bdiCreated, listDI[0].HomeAddressImportStatus__c);
        System.assert(listDI[1].HomeAddressImportStatus__c.contains('Billing City'));
        System.assertEquals(label.bdiCreated, listDI[2].HomeAddressImportStatus__c);

        System.assertEquals(BDI_DataImport_API.bdiImported, listDI[0].Status__c);
        System.assertEquals(BDI_DataImport_API.bdiFailed, listDI[1].Status__c);
        System.assertEquals(BDI_DataImport_API.bdiImported, listDI[2].Status__c);

        System.assertEquals(null, listDI[0].FailureInformation__c);
        System.assert(listDI[1].FailureInformation__c.contains('Billing City'));
        System.assertEquals(null, listDI[2].FailureInformation__c);

        List<Account> listAcc = getAccounts();
        System.assertEquals(3, listAcc.size());
        System.assertEquals('Seattle', listAcc[0].BillingCity);
        System.assertEquals(null, listAcc[1].BillingCity);
        System.assertEquals('Portland', listAcc[2].BillingCity);
                
        List<Contact> listCon = getContacts();
        System.assertEquals(3, listCon.size());
        System.assertEquals('c1 C1', listCon[0].Name);
        System.assertEquals('c2 C2', listCon[1].Name);
        System.assertEquals('c3 C3', listCon[2].Name);
        System.assertNotEquals(null, listCon[0].AccountId);
        System.assertNotEquals(null, listCon[1].AccountId);
        System.assertNotEquals(null, listCon[2].AccountId);
        System.assertEquals('Seattle', listCon[0].MailingCity);
        System.assertEquals(null, listCon[1].MailingCity);
        System.assertEquals('Portland', listCon[2].MailingCity);
    }

    /*********************************************************************************************************
    * @description operation: 
    *    import contacts with the wrong account model  
    * verify: 
    *    importData fails
    **********************************************************************************************************/            
    static testMethod void testInvalidAccountModel() {
        if (strTestOnly != '*' && strTestOnly != 'testInvalidAccountModel') return;
            
        // set 1x1 account model
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR));
        System.assertEquals(false, CAO_Constants.isHHAccountModel());
        
        List<DataImport__c> listDI = new List<DataImport__c>();
        listDI.add(BDI_DataImport_TEST.newDI('c1', 'C1'));
        insert listDI;
          
        //run batch data import
        Test.StartTest();
        try {
            BDI_DataImport_API.importData();
            System.assert(false, 'importData should have thrown exception');
        } catch (exception ex) {
            System.assert(ex.getMessage().contains('Household Account model'));
        }
        Test.stopTest();
    }

    /*********************************************************************************************************
    * @description operation:
    *    unit test for UniqueID handling
    * verify:
    *    method returns expected results for various types of fields.
    **********************************************************************************************************/
    static testMethod void testUniqueIdHandling() {
        if (strTestOnly != '*' && strTestOnly != 'testUniqueIdHandling') return;

        Test.startTest();

        System.assertEquals(UTIL_Namespace.StrTokenNSPrefix('Contact1_Website__c'),
            BDI_DataImportService.strDICustomIDField('Contact1', 'Website'));

        System.assertEquals('Contact1_Foo__c', BDI_DataImportService.strDICustomIDField('Contact1', 'Foo__c'));

        if (UTIL_Namespace.getNamespace().equalsIgnoreCase('npsp')) {
            System.assertEquals('npsp__Contact1_Bar__c', BDI_DataImportService.strDICustomIDField('Contact1', 'npsp__Bar__c'));
        } else {
            System.assertEquals('Contact1_Bar__c', BDI_DataImportService.strDICustomIDField('Contact1', 'npsp__Bar__c'));
        }

        System.assertEquals('Contact1_Baz__c', BDI_DataImportService.strDICustomIDField('Contact1', 'randomNS__Baz__c'));

        System.assertEquals(UTIL_Namespace.StrTokenNSPrefix('Contact1_Buz__c'),
            BDI_DataImportService.strDICustomIDField('Contact1', UTIL_Namespace.StrTokenNSPrefix('Buz__c')));

        Test.stopTest();
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves contact records in the order they were created during the test. 
    * @return List<Contact> All contacts records in creation order
    **********************************************************************************************************/
    private static List<Contact> getContacts() {
        return [
            SELECT Id, AccountId, Birthdate, HomePhone, MailingCity, MobilePhone, Name, Title,
                npe01__HomeEmail__c, npe01__AlternateEmail__c, npe01__Preferred_Email__c, npe01__PreferredPhone__c,
                npe01__WorkEmail__c, npe01__WorkPhone__c
            FROM Contact ORDER BY Id
        ];
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
                DonationImported__c, DonationImportStatus__c, Donation_Campaign_Name__c, FailureInformation__c,
                HomeAddressImported__c, HomeAddressImportStatus__c, Home_City__c, HouseholdAccountImported__c, Status__c
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
        return [SELECT Id, BillingCity, Name FROM Account ORDER BY Id];
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves address records in the order they were created during the test. 
    * @return List<Address__c> All address records in creation order
    **********************************************************************************************************/
    private static List<Address__c> getAddresses() {
        return [SELECT Id, Household_Account__c, MailingCity__c FROM Address__c ORDER BY Id];
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves opportunity records in the order they were created during the test. 
    * @return List<Opportunity> All opportunity records in creation order
    **********************************************************************************************************/
    private static List<Opportunity> getOpps() {
        return [SELECT Id, Name, Amount FROM Opportunity ORDER BY Amount];
    }

    /*********************************************************************************************************
    * @description operation:
    *    Retrieves campaign records in the order they were created during the test. 
    * @return List<Campaign> All campaign records
    **********************************************************************************************************/
    private static List<Campaign> getCampaigns() {
        return [SELECT Id, Name FROM Campaign];
    }
}