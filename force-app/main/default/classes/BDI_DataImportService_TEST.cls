/*
    Copyright (c) 2018 Salesforce.org
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
* @date 2018
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Tests for BDI_DataImportService
*/
@isTest
private with sharing class BDI_DataImportService_TEST {
    
    
    /*******************************************************************************************************************
    * @description Verifies UniqueID handling.
    * The method returns expected results for various types of fields.
    */
    @isTest
    private static void testUniqueIdHandling() {
        System.assertEquals(
            UTIL_Namespace.StrTokenNSPrefix('Contact1_Website__c'),
            BDI_DataImportService.strDICustomIDField('Contact1', 'Website')
        );

        System.assertEquals('Contact1_Foo__c', BDI_DataImportService.strDICustomIDField('Contact1', 'Foo__c'));

        String expectedCustomIdField = UTIL_Namespace.getNamespace().equalsIgnoreCase(UTIL_Namespace.HARDCODED_NPSP_NAMESPACE)
            ? 'npsp__Contact1_Bar__c'
            : 'Contact1_Bar__c';
        System.assertEquals(expectedCustomIdField, BDI_DataImportService.strDICustomIDField('Contact1', 'npsp__Bar__c'));

        System.assertEquals('Contact1_Baz__c', BDI_DataImportService.strDICustomIDField('Contact1', 'randomNS__Baz__c'));

        System.assertEquals(
            UTIL_Namespace.StrTokenNSPrefix('Contact1_Buz__c'),
            BDI_DataImportService.strDICustomIDField('Contact1', UTIL_Namespace.StrTokenNSPrefix('Buz__c'))
        );
    }

    /*******************************************************************************************************************
    * @description Verifies rollup trigger handlers are not deactivated if the data import settings to process rollups
    * is checked.
    */
    @isTest
    private static void rollupTriggersAreNotDeactivatedWhenRunRollupSettingsIsChecked() {
        Data_Import_Settings__c diSettings = getDataImportSettings();
        diSettings.Run_Opportunity_Rollups_while_Processing__c = true;

        Boolean isDryRun = false;
        BDI_DataImportService service = new BDI_DataImportService(isDryRun, BDI_MappingServiceHelpText.getInstance());
        service.injectDataImportSettings(diSettings);

        List<Trigger_Handler__c> expectedHandlers = TDTM_Config_API.getCachedRecords();

        service.disableAllOppRollups();

        System.assertEquals(expectedHandlers, TDTM_Config_API.getCachedRecords());
    }

    /*******************************************************************************************************************
    * @description Verifies rollup trigger handlers are deactivated if the data import settings to process rollups
    * is not checked.
    */
    @isTest
    private static void rollupTriggersAreDeactivatedWhenRunRollupSettingsIsNotChecked() {
        Data_Import_Settings__c diSettings = getDataImportSettings();
        diSettings.Run_Opportunity_Rollups_while_Processing__c = false;

        Boolean isDryRun = false;
        BDI_DataImportService service = new BDI_DataImportService(isDryRun, BDI_MappingServiceHelpText.getInstance());
        service.injectDataImportSettings(diSettings);

        Map<String, Trigger_Handler__c> handlerByKey = new Map<String, Trigger_Handler__c>();
        for (Trigger_Handler__c handler : TDTM_Config_API.getCachedRecords()) {
            handlerByKey.put(handler.Object__c + handler.Class__c, handler);
        }

        service.disableAllOppRollups();

        for (Trigger_Handler__c handler : TDTM_Config_API.getCachedRecords()) {
            Boolean isActive = isRollupTriggerHandler(handler) 
                ? false 
                : handlerByKey.get(handler.Object__c + handler.Class__c).Active__c;

            System.assertEquals(isActive, handler.Active__c, 'Only rollup trigger handlers should be deactivated: ' + handler);
        }
    }

    /*******************************************************************************************************************
    * @description If any custom criteria is set that all data imports must satisfy, if that criteria is not met then
     * BDI should not process those data import records.
    */
    @isTest
    private static void shouldBypassDataImportsWithFailedCriteria() {
        Data_Import_Settings__c diSettings = getDataImportSettings();

        BDI_DataImportService service = new BDI_DataImportService(false,
                BDI_MappingServiceAdvanced.getInstance());
        service.injectDataImportSettings(diSettings);

        List<DataImport__c> testDataImports = UTIL_UnitTestData_TEST.createDIRecordsInANewGEBatch(50);
        insert testDataImports;

        for (DataImport__c dataImport : testDataImports) {
            dataImport.Payment_Status__c = 'Bad Request';
        }

        Test.startTest();
            service.process(null, diSettings, testDataImports);
        Test.stopTest();

        for (DataImport__c dataImport : [SELECT Status__c FROM DataImport__c]) {
            System.assertEquals(null, dataImport.Status__c, 'Data Import should not have been processed.');
        }
    }

    /*******************************************************************************************************************
    * @description Tests that BDI correctly processes all data import records that meet custom criteria.
    */
    @isTest
    private static void shouldProcessDataImportsWithCapturedStatus() {
        Data_Import_Settings__c diSettings = getDataImportSettings();

        BDI_DataImportService service = new BDI_DataImportService(false,
                BDI_MappingServiceAdvanced.getInstance());
        service.injectDataImportSettings(diSettings);

        List<DataImport__c> testDataImports = UTIL_UnitTestData_TEST.createDIRecordsInANewGEBatch(10);
        insert testDataImports;

        for (DataImport__c dataImport : testDataImports) {
            dataImport.Payment_Status__c = ElevateTransactionStatus.CAPTURED.name();
        }

        Test.startTest();
            service.process(null, diSettings, testDataImports);
        Test.stopTest();

        for (DataImport__c dataImport : [SELECT Status__c FROM DataImport__c]) {
            System.assert(String.isNotBlank(dataImport.Status__c), 'The data import should have been' +
                'processed by BDI.');
            System.assertEquals(BDI_DataImport_API.bdiImported, dataImport.Status__c,
                'The data import was not successfully processed.');
        }
    }

    /*******************************************************************************************************************
    * @description Tests that BDI correctly processes all data import records that meet custom criteria.
    */
    @isTest
    private static void shouldProcessDryRunDataImportsWhenAuthorized() {
        Data_Import_Settings__c diSettings = getDataImportSettings();

        BDI_DataImportService service = new BDI_DataImportService(true,
                BDI_MappingServiceAdvanced.getInstance());
        service.injectDataImportSettings(diSettings);

        List<DataImport__c> testDataImports = UTIL_UnitTestData_TEST.createDIRecordsInANewGEBatch(10);
        insert testDataImports;

        for (DataImport__c dataImport : testDataImports) {
            dataImport.Payment_Status__c = ElevateTransactionStatus.AUTHORIZED.name();
        }

        Test.startTest();
            service.process(null, diSettings, testDataImports);
        Test.stopTest();

        for (DataImport__c dataImport : [SELECT Status__c FROM DataImport__c]) {
            System.assert(String.isNotBlank(dataImport.Status__c), 'The data import should have been' +
                    'processed by BDI.');
            System.assertEquals(BDI_DataImport_API.bdiDryRunValidated, dataImport.Status__c,
                    'The data import was not successfully processed.');
        }
    }

    /*******************************************************************************************************************
    * @description Tests utility methods that determine whether any fields for a given object mapping are populated with
    * a value.
    */
    @isTest
    private static void shouldReturnWhetherFieldsArePopulated (){
        DataImport__c testDI1 = new DataImport__c(Donation_Amount__c = 10, 
                                                    Donation_Date__c = System.Date.today(), 
                                                    Account1_name__c = null);
        DataImport__c testDI2 = new DataImport__c(Contact1_lastname__c = 'TestGuy');

        // Using varied capitalizations for the test data to make sure the forcing to lowercase is working correctly.
        Map<String,String> testFieldMap = new Map<String,String>{'donation_amount__c' =>'amount',
                                                                'Donation_Date__c' => 'closedate',
                                                                'donation_stage__c' => 'stagename',
                                                                'account1_Name__c' => 'Name'};
        String[] fieldsToIgnore1 = new String[]{'Donation_Amount__c'};
        String[] fieldsToIgnore2 = new String[]{'Donation_Amount__c','Donation_Date__c'};

        // Should be true since two fields are populated
        System.assertEquals(true, BDI_DataImportService.anyFieldsPopulatedForObjectMapping(testDI1, testFieldMap));

        // Should be false since none of the fields specified is populated
        System.assertEquals(false, BDI_DataImportService.anyFieldsPopulatedForObjectMapping(testDI2, testFieldMap));

        // Should still be true since one of the fields not being igorned is populated
        System.assertEquals(true, 
                    BDI_DataImportService.anyFieldsPopulatedForObjectMapping(testDI1, testFieldMap, fieldsToIgnore1));

        // Should be false since populated field is not in the field map
        System.assertEquals(false, 
                    BDI_DataImportService.anyFieldsPopulatedForObjectMapping(testDI2, testFieldMap, fieldsToIgnore1));

        // Should be false because both populated fields are now being ignored
        System.assertEquals(false, 
                    BDI_DataImportService.anyFieldsPopulatedForObjectMapping(testDI1, testFieldMap, fieldsToIgnore2));
    }

    @isTest
    private static void testImportAccounts() {
        // Create test Data Import Settings
        Data_Import_Settings__c diSettings = new Data_Import_Settings__c(
            Field_Mapping_Method__c = 'Data Import Field Mapping',
            Donation_Matching_Rule__c = 'Donation_Amount__c;Donation_Date__c',
            Donation_Matching_Behavior__c = 'ExactMatchOrCreate'
        );
        insert diSettings;
    
        // Create test data imports using UTIL_UnitTestData_TEST
        List<DataImport__c> testDataImports = UTIL_UnitTestData_TEST.createDIRecordsInANewGEBatch(50);
        for (Integer i = 0; i < testDataImports.size(); i++) {
            testDataImports[i].Account1_Name__c = 'Test Account ' + i;
            testDataImports[i].Contact1_Firstname__c = 'FirstName' + i;
            testDataImports[i].Contact1_Lastname__c = 'LastName' + i;
            testDataImports[i].Contact1_Personal_Email__c = 'email' + i + '@example.com';
            testDataImports[i].Account2_Name__c = 'Test Account 2 ' + i;
            testDataImports[i].Contact2_Firstname__c = 'FirstName2' + i;
            testDataImports[i].Contact2_Lastname__c = 'LastName2' + i;
            testDataImports[i].Contact2_Personal_Email__c = 'email2' + i + '@example.com';
            testDataImports[i].Contact2_Work_Email__c = 'workemail2' + i + '@example.com';
            testDataImports[i].Contact2_Alternate_Email__c = 'alt2' + i + '@example.com';
            testDataImports[i].Contact2_Mobile_Phone__c = '222-333-4444';
            testDataImports[i].Contact2_Other_Phone__c = '555-666-7777';
            testDataImports[i].Contact2_Personal_Email__c = 'email2' + i + '@example.com';
            testDataImports[i].Contact1_Firstname__c = 'FirstName2' + i;
            testDataImports[i].Contact1_Lastname__c = 'LastName2' + i;
            testDataImports[i].Contact1_Personal_Email__c = 'email2' + i + '@example.com';
            testDataImports[i].Contact1_Work_Email__c = 'workemail2' + i + '@example.com';
            testDataImports[i].Contact1_Alternate_Email__c = 'alt2' + i + '@example.com';
            testDataImports[i].Contact1_Mobile_Phone__c = '222-333-4444';
            testDataImports[i].Contact1_Other_Phone__c = '555-666-7777';
            testDataImports[i].Contact1_Personal_Email__c = 'email2' + i + '@example.com';
        }
        insert testDataImports;
    
        // Extract batch ID from the first DataImport record
        Id batchId = testDataImports[0].NPSP_Data_Import_Batch__c;
    
        // Create an instance of BDI_PerfLogger with required parameters
        Integer countRecords = testDataImports.size();
        BDI_PerfLogger perfLogger = new BDI_PerfLogger(batchId, countRecords);
    
        // Create an instance of BDI_DataImportService
        BDI_DataImportService service = new BDI_DataImportService(false, BDI_MappingServiceAdvanced.getInstance());
        service.listDI = testDataImports;
    
        // Inject the data import settings and performance logger
        service.injectDataImportSettings(diSettings);
        BDI_DataImportService.injectPerfLogger(perfLogger);
    
        // Create test Data Import records
        List<DataImport__c> testDataImportss = new List<DataImport__c>();
        for (Integer i = 0; i < 5; i++) {
            DataImport__c dataImport = new DataImport__c(
                NPSP_Data_Import_Batch__c = testDataImports[0].NPSP_Data_Import_Batch__c,
                Account1_Name__c = 'Test Account ' + i,
                Contact1_Firstname__c = 'FirstName' + i,
                Contact1_Lastname__c = 'LastName' + i,
                Contact1_Personal_Email__c = 'email' + i + '@example.com',
                Account2_Name__c = 'Test Account 2 ' + i,
                Contact2_Firstname__c = 'FirstName2' + i,
                Contact2_Lastname__c = 'LastName2' + i,
                Contact2_Personal_Email__c = 'email2' + i + '@example.com',
                Status__c = 'Ready' // Adding a status to avoid null status
            );
            testDataImportss.add(dataImport);
        }
        insert testDataImportss;
    
        service.listDI = testDataImportss;
    
        // Create Accounts to ensure matching
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            Account acc = new Account(
                Name = 'Test Account ' + i
            );
            accounts.add(acc);
        }
        insert accounts;
    
        // Create Contacts to ensure matching
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            Contact con1 = new Contact(
                FirstName = 'FirstName' + i,
                LastName = 'LastName' + i,
                Email = 'email' + i + '@example.com',
                AccountId = accounts[i].Id
            );
            Contact con2 = new Contact(
                FirstName = 'FirstName2' + i,
                LastName = 'LastName2' + i,
                Email = 'email2' + i + '@example.com',
                AccountId = accounts[i].Id
            );
            contacts.add(con1);
            contacts.add(con2);
        }
        insert contacts;

        // Assign created contact IDs to the data import records
        for (Integer i = 0; i < 5; i++) {
            testDataImportss[i].Contact1Imported__c = contacts[i*2].Id;
            testDataImportss[i].Contact2Imported__c = contacts[i*2+1].Id;
        }
        update testDataImportss;
        
        // Ensure the service has the necessary contact service
        BDI_ContactService contactService = new BDI_ContactService(service);
        service.contactService = contactService;

        // Explicitly set mapDIIdToC1 to ensure contacts are available
        for (DataImport__c dataImport : testDataImportss) {
            for (Contact con : contacts) {
                if (con.Id == dataImport.Contact1Imported__c) {
                    contactService.mapDIIdToC1.put(dataImport.Id, con);
                }
                if (con.Id == dataImport.Contact2Imported__c) {
                    contactService.mapDIIdToC2.put(dataImport.Id, con);
                }
            }
        }

        // Call the method to be tested
        Test.startTest();
        service.importAccounts();
        Test.stopTest();
    
        // Add assertions to verify the Account and Contact records were created/updated as expected
        List<Account> accounts1 = [SELECT Id, Name, Phone FROM Account WHERE Name LIKE 'Test Account%'];
        System.assert(accounts1.size() > 0, 'Accounts should be created');
    
        List<Contact> contactList = [SELECT Id, FirstName, LastName, Email FROM Contact WHERE LastName LIKE 'LastName%'];
        System.assert(contactList.size() > 0, 'Contacts should be created');
    }

    // Helpers
    ////////////

    /*******************************************************************************************************************
    * @description Retrieves and sets default on the data import settings
    */
    private static Data_Import_Settings__c getDataImportSettings() {
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();

        diSettings.Donation_Matching_Rule__c = UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c');
        diSettings.Donation_Matching_Behavior__c = BDI_DataImport_API.ExactMatchOrCreate;

        return diSettings;
    }


    /*******************************************************************************************************************
    * @description Returns true if the trigger handler calculates rollups
    */
    private static Boolean isRollupTriggerHandler(Trigger_Handler__c handler) {
         return (handler.Object__c == 'Opportunity' && handler.Class__c == 'RLLP_OppRollup_TDTM') ||
            (handler.Object__c == 'Opportunity' && handler.Class__c == 'CRLP_Rollup_TDTM') ||
            (handler.Object__c == 'npe01__OppPayment__c' && handler.Class__c == 'CRLP_Rollup_TDTM'); 
    }
}