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
* @description tests specific to the Batch Data Importer API class
*/

@isTest
public with sharing class BDI_DataImportAPI_TEST {

    /*********************************************************************************************************
    * @description utility to create a new DI record for the specified batch
    */
    public static DataImport__c newDI(ID batchId, String firstname, String lastname) {
        return new DataImport__c(
            Contact1_Firstname__c = firstname,
            Contact1_Lastname__c = lastname,
            Contact1_Personal_Email__c = firstname + '@' + lastname + '.com',
            NPSP_Data_Import_Batch__c = batchId
        );
    }

    /*********************************************************************************************************
    * @description utility to create a new DI record for the specified batch
    * @return data Import object
    */
    private static DataImport__c newDataImport(Id batchId,
        String firstName, String lastName, String donationName, 
        Decimal donationAmount, String stage) {

        DataImport__c dataImport = new DataImport__c(
            Contact1_Firstname__c = firstName,
            Contact1_Lastname__c = lastName,
            Donation_Amount__c = donationAmount,
            Donation_Name__c = donationName,
            Donation_Stage__c = stage,
            Donation_Date__c = Date.today(),
            NPSP_Data_Import_Batch__c = batchId
        );
        return dataImport;
    }
    /*********************************************************************************************************
    * @description utility to create & save a new DI batch
    */
    public static DataImportBatch__c newBatch(String name, boolean autoProcess) {
        DataImportBatch__c batch = new DataImportBatch__c();
        batch.Name = name;
        batch.Batch_Process_Size__c = 200;
        batch.Contact_Matching_Rule__c = 'Firstname,Lastname,Email';
        batch.Donation_Matching_Rule__c = UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + ';' +
            UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c');
        batch.Donation_Matching_Behavior__c = BDI_DataImport_API.BestMatchOrCreate;
        batch.Process_Using_Scheduled_Job__c = autoProcess;
        insert batch;
        return batch;
    }

    /*********************************************************************************************************
    * @description operation
    *     import di records that have no batch
    * verify:
    *     only that non-batch's di records processed
    *     other di records left alone
    **********************************************************************************************************/
    static testMethod void processNoBatch() {
        list<DataImport__c> listDI = new list<DataImport__c>();

        DataImportBatch__c batch1 = newBatch('b1', false);
        listDI.add(newDI(batch1.Id, 'c1', 'C1'));

        DataImportBatch__c batch2 = newBatch('b2', false);
        listDI.add(newDI(batch2.Id, 'c2', 'C2'));

        listDI.add(newDI(null, 'c3', 'C3'));

        insert listDI;

        //run batch data import
        Test.StartTest();
        list<BDI_DataImport_API.ProcessDataImportBatchesResult> listResult = BDI_DataImport_API.processDataImportBatches(new list<ID>{null});
        Test.stopTest();

        // verify expected results
        system.assertEquals(1, listResult.size());
        system.assertNotEquals(null, listResult[0].apexJobId);

        list<Contact> listCon = [select Id, Name from Contact];
        system.assertEquals(1, listCon.size());
        system.assertEquals('c3 C3', listCon[0].Name);

        listDI = [select Status__c from DataImport__c order by Id];
        system.assertEquals(3, listDI.size());
        system.assertEquals(null, listDI[0].Status__c);
        system.assertEquals(null, listDI[1].Status__c);
        system.assertEquals(BDI_DataImport_API.bdiImported, listDI[2].Status__c);

        list<DataImportBatch__c> listBatches = [SELECT Id, Last_Processed_On__c, Records_Failed__c, Records_Successfully_Processed__c FROM DataImportBatch__c];
        system.assertEquals(2, listBatches.size());
        for (DataImportBatch__c batch : listBatches) {
            system.assertEquals(null, batch.Last_Processed_On__c);
            system.assertEquals(null, batch.Records_Failed__c);
            system.assertEquals(null, batch.Records_Successfully_Processed__c);
        }
    }

    /*********************************************************************************************************
    * @description operation
    *     import di records for a single batch
    * verify:
    *     only that batch's di records processed
    *     other di records left alone
    **********************************************************************************************************/
    static testMethod void processSingleBatch() {
        list<DataImport__c> listDI = new list<DataImport__c>();

        DataImportBatch__c batch1 = newBatch('b1', false);
        listDI.add(newDI(batch1.Id, 'c1', 'C1'));

        DataImportBatch__c batch2 = newBatch('b2', false);
        listDI.add(newDI(batch2.Id, 'c2', 'C2'));

        listDI.add(newDI(null, 'c3', 'C3'));

        insert listDI;

        //run batch data import
        Test.StartTest();
        list<BDI_DataImport_API.ProcessDataImportBatchesResult> listResult = BDI_DataImport_API.processDataImportBatches(new list<ID>{batch1.Id});
        Test.stopTest();

        // verify expected results
        system.assertEquals(1, listResult.size());
        system.assertNotEquals(null, listResult[0].apexJobId);

        list<Contact> listCon = [select Id, Name from Contact];
        system.assertEquals(1, listCon.size());
        system.assertEquals('c1 C1', listCon[0].Name);

        listDI = [select Status__c from DataImport__c order by Id];
        system.assertEquals(3, listDI.size());
        system.assertEquals(BDI_DataImport_API.bdiImported, listDI[0].Status__c);
        system.assertEquals(null, listDI[1].Status__c);
        system.assertEquals(null, listDI[2].Status__c);

        list<DataImportBatch__c> listBatches = [SELECT Id, Last_Processed_On__c, Records_Failed__c, Records_Successfully_Processed__c FROM DataImportBatch__c];
        system.assertEquals(2, listBatches.size());
        for (DataImportBatch__c batch : listBatches) {
            if (batch.Id == batch1.Id) {
                system.assertNotEquals(null, batch.Last_Processed_On__c);
                system.assertEquals(0, batch.Records_Failed__c);
                system.assertEquals(1, batch.Records_Successfully_Processed__c);
            } else {
                system.assertEquals(null, batch.Last_Processed_On__c);
                system.assertEquals(null, batch.Records_Failed__c);
                system.assertEquals(null, batch.Records_Successfully_Processed__c);
            }
        }
    }

    /*********************************************************************************************************
    * @description operation
    *     import di records for two batches
    * verify:
    *     only that batch's di records processed
    *     other di records left alone
    **********************************************************************************************************/
    static testMethod void processTwoBatches() {
        list<DataImport__c> listDI = new list<DataImport__c>();

        DataImportBatch__c batch1 = newBatch('b1', false);
        listDI.add(newDI(batch1.Id, 'c1', 'C1'));

        DataImportBatch__c batch2 = newBatch('b2', false);
        listDI.add(newDI(batch2.Id, 'c2', 'C2'));

        listDI.add(newDI(null, 'c3', 'C3'));

        insert listDI;

        //run batch data import
        Test.StartTest();
        list<BDI_DataImport_API.ProcessDataImportBatchesResult> listResult = BDI_DataImport_API.processDataImportBatches(new list<ID>{batch1.Id, batch2.Id});
        Test.stopTest();

        // verify expected results
        system.assertEquals(2, listResult.size());
        system.assertNotEquals(null, listResult[0].apexJobId);
        system.assertNotEquals(null, listResult[1].apexJobId);

        list<Contact> listCon = [select Id, Name from Contact order by Id];
        system.assertEquals(2, listCon.size());
        system.assertEquals('c1 C1', listCon[0].Name);
        system.assertEquals('c2 C2', listCon[1].Name);

        listDI = [select Status__c from DataImport__c order by Id];
        system.assertEquals(3, listDI.size());
        system.assertEquals(BDI_DataImport_API.bdiImported, listDI[0].Status__c);
        system.assertEquals(BDI_DataImport_API.bdiImported, listDI[1].Status__c);
        system.assertEquals(null, listDI[2].Status__c);

        list<DataImportBatch__c> listBatches = [SELECT Id, Last_Processed_On__c, Records_Failed__c, Records_Successfully_Processed__c FROM DataImportBatch__c];
        system.assertEquals(2, listBatches.size());
        for (DataImportBatch__c batch : listBatches) {
            system.assertNotEquals(null, batch.Last_Processed_On__c);
            system.assertEquals(0, batch.Records_Failed__c);
            system.assertEquals(1, batch.Records_Successfully_Processed__c);
        }
    }

    /*********************************************************************************************************
    * @description operation
    *     try to import di records specifying an invalid batch
    * verify:
    *     error detected
    *     other di records left alone
    **********************************************************************************************************/
    static testMethod void processErrorBatch() {
        list<DataImport__c> listDI = new list<DataImport__c>();

        DataImportBatch__c batch1 = newBatch('b1', false);
        listDI.add(newDI(batch1.Id, 'c1', 'C1'));

        DataImportBatch__c batch2 = newBatch('b2', false);
        listDI.add(newDI(batch2.Id, 'c2', 'C2'));

        listDI.add(newDI(null, 'c3', 'C3'));

        insert listDI;

        //run batch data import
        Test.StartTest();
        try {
            list<BDI_DataImport_API.ProcessDataImportBatchesResult> listResult =
                BDI_DataImport_API.processDataImportBatches(new list<ID>{'123456789012345'});
            system.assert(false, 'exception should have been thrown');
        } catch (Exception ex) {

        }
        Test.stopTest();

        // verify expected results
        list<Contact> listCon = [select Id, Name from Contact];
        system.assertEquals(0, listCon.size());

        listDI = [select Status__c from DataImport__c order by Id];
        system.assertEquals(3, listDI.size());
        system.assertEquals(null, listDI[0].Status__c);
        system.assertEquals(null, listDI[1].Status__c);
        system.assertEquals(null, listDI[2].Status__c);

        list<DataImportBatch__c> listBatches = [SELECT Id, Last_Processed_On__c, Records_Failed__c, Records_Successfully_Processed__c FROM DataImportBatch__c];
        system.assertEquals(2, listBatches.size());
        for (DataImportBatch__c batch : listBatches) {
            system.assertEquals(null, batch.Last_Processed_On__c);
            system.assertEquals(null, batch.Records_Failed__c);
            system.assertEquals(null, batch.Records_Successfully_Processed__c);
        }
    }

    /*********************************************************************************************************
    * @description operation
    *     import di records directly without using a batch process
    * verify:
    *     only the provided di records processed
    *     other di records left alone
    **********************************************************************************************************/
    static testMethod void processRecordsImport() {
        // DI's to process
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(newDI(null, 'c1', 'C1'));
        listDI.add(newDI(null, 'c2', 'C2'));
        listDI.add(newDI(null, 'c3', 'C3'));
        insert listDI;

        // DI's to be left alone
        list<DataImport__c> listDI2 = new list<DataImport__c>();
        listDI2.add(newDI(null, 'c4', 'C4'));
        listDI2.add(newDI(null, 'c5', 'C5'));
        insert listDI2;

        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Contact_Matching_Rule__c = 'Firstname,Lastname,Phone';

        //run data import
        Test.startTest();
        BDI_DataImport_API.processDataImportRecords(diSettings, listDI, false);
        Test.stopTest();

        // verify expected results
        list<Contact> listCon = [select Id, Name from Contact];
        system.assertEquals(3, listCon.size());

        listDI = [SELECT Id FROM DataImport__c WHERE Status__c = :BDI_DataImport_API.bdiImported];
        system.assertEquals(3, listDI.size());
    }

    /*********************************************************************************************************
    * @description operation
    *     Dry Run di records directly without using a batch process
    * verify:
    *     only the provided di records processed
    *     other di records left alone
    **********************************************************************************************************/
    static testMethod void processRecordsDryRun() {
        // DI's to process
        list<DataImport__c> listDI = new list<DataImport__c>();
        listDI.add(newDI(null, 'c1', 'C1'));
        listDI.add(newDI(null, 'c2', 'C2'));
        listDI.add(newDI(null, 'c3', 'C3'));
        insert listDI;

        // DI's to be left alone
        list<DataImport__c> listDI2 = new list<DataImport__c>();
        listDI2.add(newDI(null, 'c4', 'C4'));
        listDI2.add(newDI(null, 'c5', 'C5'));
        insert listDI2;

        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Contact_Matching_Rule__c = 'Firstname,Lastname,Phone';

        //run data import
        Test.startTest();
        BDI_DataImport_API.processDataImportRecords(diSettings, listDI, true);
        Test.stopTest();

        // verify expected results
        list<Contact> listCon = [select Id, Name from Contact];
        system.assertEquals(0, listCon.size());

        listDI = [SELECT Id FROM DataImport__c WHERE Status__c = :BDI_DataImport_API.bdiDryRunValidated];
        system.assertEquals(3, listDI.size());
    }

    /*********************************************************************************************************
    * @description process di records selecting all the fields
    * verify:
    *     no errors occurred
    **********************************************************************************************************/
    @isTest
    private static void processRecordsWithAllFields() {
        // create the data import record
        DataImport__c dataImport = newDataImport(null, 'Jane', 'Doe', 'TestOpp', 1000, 'Closed Won');
        insert dataImport;
        Id diObjId = dataImport.Id;
    
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Donation_Matching_Behavior__c = BDI_DataImport_API.DoNotMatch;

        // get the list of existing di records with all the fields
        String allDIFields = String.join(BDI_DataImportService.listStrDataImportFields, ',');
        List<DataImport__c> listDI = 
            Database.query('SELECT ' + String.escapeSingleQuotes(allDIFields) 
                + ' FROM DataImport__c WHERE Id = :diObjId');

        // process no dry run
        Test.startTest();
        BDI_DataImport_API.processDataImportRecords(diSettings, listDI, false);
        Test.stopTest();

        // check the results
        dataImport = [
            SELECT DonationImported__c,
                    FailureInformation__c
            FROM DataImport__c
            WHERE Id = :diObjId
        ];

        System.assertEquals(null, 
            dataImport.FailureInformation__c, 'Data Import process errors.');
    }

    /*********************************************************************************************************
    * @description process di records and check if the opportunity is created
    * verify:
    *     no errors occurred
    **********************************************************************************************************/
    @isTest
    private static void processRecordsAndCreateOpportunity() {
        // create the data import record
        String donationName = 'TestOpp';
        DataImport__c dataImport = newDataImport(null, 'Jane', 'Doe', donationName, 1000, 'Closed Won');
        insert dataImport;
        Id diObjId = dataImport.Id;
    
        Data_Import_Settings__c diSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        diSettings.Donation_Matching_Behavior__c = BDI_DataImport_API.DoNotMatch;

        // get the list of existing di records with all the fields
        String allDIFields = String.join(BDI_DataImportService.listStrDataImportFields, ',');
        List<DataImport__c> listDI = 
            Database.query('SELECT ' + String.escapeSingleQuotes(allDIFields) 
                + ' FROM DataImport__c WHERE Id = :diObjId');

        // process no dry run
        Test.startTest();
        BDI_DataImport_API.processDataImportRecords(diSettings, listDI, false);
        Test.stopTest();

        List<Opportunity> opps = [
            SELECT Id
            FROM Opportunity 
            WHERE Name =: donationName
        ];
        System.assertEquals(1, opps.size(), 'Opportunity record was not created');

    }
}