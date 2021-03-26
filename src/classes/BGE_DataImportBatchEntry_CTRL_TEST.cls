/*
    Copyright (c) 2019, Salesforce.org
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
* @group BGE
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Unit Tests for the Data Import Batch Entry component.
*/

@isTest(IsParallel=true)
private class BGE_DataImportBatchEntry_CTRL_TEST {

    /*********************************************************************************************************
    * @description Sets up a new NPSP_Data_Import_Batch__c Record
    * @return Id of the new NPSP_Data_Import_Batch__c
    */
    private static Id createDataImportBatch() {
        DataImportBatch__c dataImportBatch = new DataImportBatch__c();
        dataImportBatch.Name = 'Batch 1';

        insert dataImportBatch;
        return (Id)dataImportBatch.Id;
    }

    /*********************************************************************************************************
    * @description Sets up a list of DataImport__c Records
    * @param numOfImports number of imports to create
    * @param batchId ID of the related NPSP_Data_Import_Batch__c
    * @return list of new DataImport__c records
    */
    private static List<DataImport__c> createDataImports(Integer numOfImports, Id batchId) {
        List<DataImport__c> dataImports = new List<DataImport__c>();

        for (Integer i=0; i < numOfImports; i++) {
            DataImport__c dataImport = new DataImport__c();
            dataImport.Account1_Name__c = 'Test Record ' + i;
            dataImport.NPSP_Data_Import_Batch__c = batchId;
            dataImports.add(dataImport);
        }

        insert dataImports;
        return dataImports;
    }

    /*********************************************************************************************************
    * @description Tests that updateDataImports() updates records and returns updated totals
    */

    @isTest
    static void testUpdateDataImports() {
        Id batchId = createDataImportBatch();
        String newName = 'New Name';
        Integer totalRecords = 2;
        Decimal totalAmount = 5.0;
        List<DataImport__c> dataImports = createDataImports(totalRecords, batchId);

        dataImports[0].Account1_Name__c = newName;
        dataImports[0].Donation_Amount__c = totalAmount;

        Test.startTest();
        BGE_DataImportBatchEntry_CTRL.updateAndDryRunRow(batchId, dataImports[0]);
        DataImport__c updatedDataImport = [SELECT Id, Account1_Name__c FROM DataImport__c WHERE Id =: dataImports[0].Id];
        BGE_DataImportBatchEntry_CTRL.DataImportModel model = BGE_DataImportBatchEntry_CTRL.getUpdatedTotals(batchId);
        Test.stopTest();

        System.assertEquals(newName, updatedDataImport.Account1_Name__c);
        System.assertEquals(model.totalCountOfRows, totalRecords);
        System.assertEquals(model.totalRowAmount, totalAmount);
    }

    /*********************************************************************************************************
    * @description Tests getDataImportModel() for a new record
    */

    @isTest
    static void testGetNewDataImport() {

        Boolean errorIsThrownForNullId = false;

        try {
            String jsonModel = BGE_DataImportBatchEntry_CTRL.getDataImportModel(null);
        } catch (AuraHandledException e) {
            errorIsThrownForNullId = true;
        }

        System.assert(true, errorIsThrownForNullId);
    }

    /*********************************************************************************************************
    * @description Tests getDataImportModel() for a new record
    */

    @isTest
    static void testGetExistingDataImport() {
        List<SObjectField> activeFields = new List<SObjectField>{
            DataImport__c.Donation_Amount__c
        };
        DataImportBatch__c batch = new DataImportBatch__c(
            Name = 'Test Batch 1',
            Active_Fields__c = JSON.serialize(getBGEFieldList(activeFields))
        );
        insert batch;

        List<DataImport__c> dataImports = createDataImports(1, batch.Id);

        Test.startTest();
        String jsonModel = BGE_DataImportBatchEntry_CTRL.getDataImportModel(batch.Id);
        BGE_DataImportBatchEntry_CTRL.DataImportModel dataImportModel = (BGE_DataImportBatchEntry_CTRL.DataImportModel) JSON.deserialize(jsonModel, BGE_DataImportBatchEntry_CTRL.DataImportModel.class);
        Test.stopTest();

        System.assertNotEquals(null, jsonModel, 'JSON string of entire model should be returned.');
        System.assertNotEquals(null, dataImportModel.columns, 'Data Import Model Columns should not be null');
        System.assertNotEquals(null, dataImportModel.labels, 'Data Import Model Labels should not be null');
        System.assertNotEquals(null, dataImportModel.dataImportRows, 'Data Import Model Rows should not be null');
        System.assertNotEquals(null, dataImportModel.id, 'Data Import ID should not be null');
    }

    /*********************************************************************************************************
    * @description Tests deleteDataImportRow() by creating 2 related DataImport__c records and deleting 1
    */

    @isTest
    static void testDeleteDataImportRow() {

        Id batchId = createDataImportBatch();
        List<DataImport__c> dataImports = createDataImports(2, batchId);

        Test.startTest();
        BGE_DataImportBatchEntry_CTRL.deleteDataImportRow(batchId, dataImports[0].Id);
        List<DataImport__c> updatedDataImports = [SELECT Name, Id FROM DataImport__c WHERE NPSP_Data_Import_Batch__c = :batchId];
        Test.stopTest();

        System.assertEquals(2, dataImports.size(), 'Data Imports should return 2 rows');
        System.assertEquals(1, updatedDataImports.size(), 'Updated Data Imports should return only 1 row');
    }

    /*********************************************************************************************************
     * @description Test attempting to delete a DI row when used does not have permission by mocking UTIL_Permissions
     */
    @isTest
    static void testDeleteDataImportRowNoPermissions() {

        Id batchId = createDataImportBatch();
        List<DataImport__c> dataImports = createDataImports(2, batchId);

        UTIL_PermissionsMock utilPermissionsMockInstance = new UTIL_PermissionsMock();
        utilPermissionsMockInstance.canDeleteDataImport = false;
        UTIL_Permissions utilPermissionsMock = (UTIL_Permissions) Test.createStub(
                UTIL_Permissions.class,
                utilPermissionsMockInstance);
        UTIL_Permissions.setInstance(utilPermissionsMock);

        Boolean exceptionCaught = false;

        Test.startTest();

        try {
            BGE_DataImportBatchEntry_CTRL.deleteDataImportRow(batchId, dataImports[0].Id);
        } catch (AuraHandledException ex) {
            exceptionCaught = true;
        }

        Test.stopTest();

       System.assert(exceptionCaught, 'Expected to catch an AuraHandledException.');
    }

    @isTest
    static void givenAccountHasMultipleOppsWhenCalledThenAssertReturnedInWrapper() {
        Account account = new Account(Name='TestAccount');
        insert account;

        Opportunity oppWithPmt = createOpportunity('MyOpenOpp1', null);
        oppWithPmt.AccountId = account.Id;

        Opportunity oppWithoutPmt = createOpportunity('MyOpenOpp2', null);
        oppWithoutPmt.AccountId = account.Id;
        oppWithoutPmt.npe01__Do_Not_Automatically_Create_Payment__c = true;

        Opportunity oppWithPaidAndUnpaidPmts = createOpportunity('MyOpenOpp3', null);
        oppWithPaidAndUnpaidPmts.AccountId = account.Id;

        Opportunity closedOppWithPaidAndUnpaidPmts = createOpportunity('MyClosedOpp', null);
        closedOppWithPaidAndUnpaidPmts.AccountId = account.Id;
        closedOppWithPaidAndUnpaidPmts.StageName = UTIL_UnitTestData_TEST.getClosedLostStage();
        insert new List<Opportunity>{
                oppWithPmt, oppWithoutPmt, oppWithPaidAndUnpaidPmts, closedOppWithPaidAndUnpaidPmts
        };

        //Set the appropriate Payments to Paid
        npe01__OppPayment__c pmt1 = getOppPayments(oppWithPmt.Id)[0];
        pmt1.npe01__Paid__c = true;
        npe01__OppPayment__c pmt2 = getOppPayments(oppWithPaidAndUnpaidPmts.Id)[0];
        pmt2.npe01__Paid__c = true;
        update new List<npe01__OppPayment__c>{
                pmt1, pmt2
        };

        //Insert additional open Payments
        npe01__OppPayment__c pmt3 = createPayment(oppWithPaidAndUnpaidPmts.Id);
        npe01__OppPayment__c pmt4 = createPayment(closedOppWithPaidAndUnpaidPmts.Id);
        insert new List<npe01__OppPayment__c>{
                pmt3, pmt4
        };

        Test.startTest();
        String oppWrappersJSON =
                BGE_DataImportBatchEntry_CTRL.getOpportunitiesWithOppPayments(account.Id);
        Test.stopTest();

        List<BGE_DataImportBatchEntry_CTRL.OpportunityWrapper> oppWrappers =
                createOppWrappers(oppWrappersJSON);

        //Assert closed Opp not included
        System.assertEquals(3, oppWrappers.size(),
                'The three open Opportunities should be returned in the list of Opp Wrappers.');

        Map<Id, BGE_DataImportBatchEntry_CTRL.OpportunityWrapper> oppWrappersByOppId = new
                Map<Id, BGE_DataImportBatchEntry_CTRL.OpportunityWrapper>();

        for (BGE_DataImportBatchEntry_CTRL.OpportunityWrapper opportunityWrapper : oppWrappers) {
            oppWrappersByOppId.put(opportunityWrapper.opportunity.Id, opportunityWrapper);
        }
        System.assertNotEquals(true, oppWrappersByOppId.containsKey(closedOppWithPaidAndUnpaidPmts.Id),
                'The closed Opportunity should not be returned in the Opp Wrappers.');

        System.assert(oppWrappersByOppId.containsKey(oppWithPmt.Id));
        System.assertEquals(0, oppWrappersByOppId.get(oppWithPmt.Id).unpaidPayments.size(),
                'This Opportunity should not have any unpaid Payments in the Opp Wrapper.');
        System.assertEquals(true, oppWrappersByOppId.get(oppWithPmt.Id).hasNonWrittenOffPayments,
                'This Opportunity should have a Payment in the Opp Wrapper.');

        System.assert(oppWrappersByOppId.containsKey(oppWithoutPmt.Id));
        System.assertEquals(0, oppWrappersByOppId.get(oppWithoutPmt.Id).unpaidPayments.size(),
                'This Opportunity should not have any unpaid Payment in the Opp Wrapper.');
        System.assertEquals(false, oppWrappersByOppId.get(oppWithoutPmt.Id).hasNonWrittenOffPayments,
                'This Opportunity should not have a Payment in the Opp Wrapper.');

        System.assert(oppWrappersByOppId.containsKey(oppWithPaidAndUnpaidPmts.Id));
        System.assertEquals(1, oppWrappersByOppId.get(oppWithPaidAndUnpaidPmts.Id).unpaidPayments.size(),
                'This Opportunity should not have any unpaid Payment in the Opp Wrapper.');
        System.assertEquals(true, oppWrappersByOppId.get(oppWithPaidAndUnpaidPmts.Id).hasNonWrittenOffPayments,
                'This Opportunity should not have a Payment in the Opp Wrapper.');
    }

    @isTest
    static void givenContactHasMultipleOppsWhenCalledThenAssertReturnedInWrapper() {
        List<Contact> donorContacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(1);
        insert donorContacts;

        Opportunity oppWithPmt = createOpportunity('MyOpenOpp1', donorContacts[0].Id);
        Opportunity oppWithoutPmt = createOpportunity('MyOpenOpp2', donorContacts[0].Id);
        oppWithoutPmt.npe01__Do_Not_Automatically_Create_Payment__c = true;
        insert new List<Opportunity>{
                oppWithPmt, oppWithoutPmt
        };

        //Set the auto-created Payment as Paid
        npe01__OppPayment__c pmt = getOppPayments(oppWithPmt.Id)[0];
        pmt.npe01__Paid__c = true;
        update pmt;

        Test.startTest();
        String oppWrappersJSON =
                BGE_DataImportBatchEntry_CTRL.getOpportunitiesWithOppPayments(donorContacts[0].Id);
        Test.stopTest();

        List<BGE_DataImportBatchEntry_CTRL.OpportunityWrapper> oppWrappers =
                createOppWrappers(oppWrappersJSON);

        Map<Id, BGE_DataImportBatchEntry_CTRL.OpportunityWrapper> oppWrappersByOppId = new
                Map<Id, BGE_DataImportBatchEntry_CTRL.OpportunityWrapper>();

        for (BGE_DataImportBatchEntry_CTRL.OpportunityWrapper opportunityWrapper : oppWrappers) {
            oppWrappersByOppId.put(opportunityWrapper.opportunity.Id, opportunityWrapper);
        }

        System.assertEquals(2, oppWrappers.size(),
                'Both of this Donors Opportunities should be returned in the list of Opp Wrappers.');

        System.assert(oppWrappersByOppId.containsKey(oppWithPmt.Id));
        System.assertEquals(0, oppWrappersByOppId.get(oppWithPmt.Id).unpaidPayments.size(),
                'This Opportunity should not have any unpaid Payments in the Opp Wrapper.');
        System.assertEquals(true, oppWrappersByOppId.get(oppWithPmt.Id).hasNonWrittenOffPayments,
                'This Opportunity should have a Payment in the Opp Wrapper.');

        System.assert(oppWrappersByOppId.containsKey(oppWithoutPmt.Id));
        System.assertEquals(0, oppWrappersByOppId.get(oppWithoutPmt.Id).unpaidPayments.size(),
                'This Opportunity should not have any unpaid Payment in the Opp Wrapper.');
        System.assertEquals(false, oppWrappersByOppId.get(oppWithoutPmt.Id).hasNonWrittenOffPayments,
                'This Opportunity should not have a Payment in the Opp Wrapper.');
    }

    @isTest
    static void givenOpenOppHasPaidAndUnpaidPmtsWhenCalledThenAssertReturnedInWrapper() {
        List<Contact> donorContacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(1);
        insert donorContacts;

        Opportunity oppWithPmts = createOpportunity('MyOpenOpp1', donorContacts[0].Id);
        insert oppWithPmts;

        //Mark the auto-created Payment as Paid
        npe01__OppPayment__c pmt = getOppPayments(oppWithPmts.Id)[0];
        pmt.npe01__Paid__c = true;
        update pmt;

        //Insert a new unpaid Payment on the Opp
        npe01__OppPayment__c openPmt = createPayment(oppWithPmts.Id);
        insert openPmt;

        Test.startTest();
        String oppWrappersJSON =
                BGE_DataImportBatchEntry_CTRL.getOpportunitiesWithOppPayments(donorContacts[0].Id);
        Test.stopTest();

        List<BGE_DataImportBatchEntry_CTRL.OpportunityWrapper> oppWrappers =
                createOppWrappers(oppWrappersJSON);

        System.assertEquals(oppWithPmts.Id, oppWrappers[0].opportunity.Id);
        System.assertEquals(1, oppWrappers[0].unpaidPayments.size(),
                'This Opportunity should have an unpaid Payments in the Opp Wrapper.');
        System.assertEquals(true, oppWrappers[0].hasNonWrittenOffPayments,
                'This Opportunity should have a Payment in the Opp Wrapper.');
    }

    @isTest
    static void givenOpenOppHasUnpaidPmtsWhenCalledThenAssertReturnedInWrapper() {
        List<Contact> donorContacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(1);
        insert donorContacts;

        Opportunity opp = createOpportunity('MyOpenOpp', donorContacts[0].Id);
        insert opp;

        Test.startTest();
        String oppWrappersJSON =
                BGE_DataImportBatchEntry_CTRL.getOpportunitiesWithOppPayments(donorContacts[0].Id);
        Test.stopTest();

        npe01__OppPayment__c pmt = getOppPayments(opp.Id)[0];

        List<BGE_DataImportBatchEntry_CTRL.OpportunityWrapper> oppWrappers =
                createOppWrappers(oppWrappersJSON);

        System.assertEquals(false, pmt.npe01__Paid__c);
        System.assertEquals(1, oppWrappers[0].unpaidPayments.size(),
                'The unpaid Payment should be returned in the OpportunityWrapper.');
        System.assertEquals(true, oppWrappers[0].hasNonWrittenOffPayments,
                'The auto-created Payment should be reflected in the OpportunityWrapper.');
    }

    @isTest
    static void givenOpenOppHasPaidPmtsWhenCalledThenAssertReturnedInWrapper() {
        List<Contact> donorContacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(1);
        insert donorContacts;

        Opportunity oppWithPmt = createOpportunity('MyOpenOpp1', donorContacts[0].Id);
        insert oppWithPmt;

        //Mark the auto-created Payment as Paid
        npe01__OppPayment__c pmt = getOppPayments(oppWithPmt.Id)[0];
        pmt.npe01__Paid__c = true;
        update pmt;

        Test.startTest();
        String oppWrappersJSON =
                BGE_DataImportBatchEntry_CTRL.getOpportunitiesWithOppPayments(donorContacts[0].Id);
        Test.stopTest();

        List<BGE_DataImportBatchEntry_CTRL.OpportunityWrapper> oppWrappers =
                createOppWrappers(oppWrappersJSON);

        System.assertEquals(oppWithPmt.Id, oppWrappers[0].opportunity.Id);
        System.assertEquals(0, oppWrappers[0].unpaidPayments.size(),
                'This Opportunity should not have any unpaid Payments in the Opp Wrapper.');
        System.assertEquals(true, oppWrappers[0].hasNonWrittenOffPayments,
                'This Opportunity should have a Payment in the Opp Wrapper.');
    }

    @isTest
    static void givenOpenOppHasWrittenOffPmtsWhenCalledThenAssertReturnedInWrapper() {
        List<Contact> donorContacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(1);
        insert donorContacts;

        Opportunity oppWithPmt = createOpportunity('MyOpenOpp1', donorContacts[0].Id);
        insert oppWithPmt;

        //Mark the auto-created Payment as Paid
        npe01__OppPayment__c pmt = getOppPayments(oppWithPmt.Id)[0];
        pmt.npe01__Written_Off__c = true;
        update pmt;

        Test.startTest();
        String oppWrappersJSON =
                BGE_DataImportBatchEntry_CTRL.getOpportunitiesWithOppPayments(donorContacts[0].Id);
        Test.stopTest();

        List<BGE_DataImportBatchEntry_CTRL.OpportunityWrapper> oppWrappers =
                createOppWrappers(oppWrappersJSON);

        System.assertEquals(oppWithPmt.Id, oppWrappers[0].opportunity.Id);
        System.assertEquals(0, oppWrappers[0].unpaidPayments.size(),
                'The written off Payment should not be included in unpaid Payments in the Opp Wrapper.');
        System.assertEquals(false, oppWrappers[0].hasNonWrittenOffPayments,
                'hasPayments should be true for this Opportunity since it has a related Payment.');
    }

    @isTest
    static void givenOpenOppHasNoPmtsWhenCalledThenAssertReturnedInWrapper() {
        List<Contact> donorContacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(1);
        insert donorContacts;

        Opportunity opp = createOpportunity('MyOpenOpp', donorContacts[0].Id);
        opp.npe01__Do_Not_Automatically_Create_Payment__c = true;
        insert opp;

        Test.startTest();
        String oppWrappersJSON =
                BGE_DataImportBatchEntry_CTRL.getOpportunitiesWithOppPayments(donorContacts[0].Id);
        Test.stopTest();

        List<BGE_DataImportBatchEntry_CTRL.OpportunityWrapper> oppWrappers =
                createOppWrappers(oppWrappersJSON);

        System.assertEquals(0, oppWrappers[0].unpaidPayments.size(),
                'This Opportunity should not have any unpaid payments.');
        System.assertEquals(false, oppWrappers[0].hasNonWrittenOffPayments,
                'This Opportunity should not have any payments.');
    }

    @isTest
    static void givenUnsupportedIdWhenCalledThenAssertExceptionThrown() {
        List<Contact> donorContacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(1);
        insert donorContacts;

        Opportunity opp = createOpportunity('MyOpenOpp', donorContacts[0].Id);
        insert opp;

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            //Pass an Opportunity Id as param
            String oppWrappersJSON =
                    BGE_DataImportBatchEntry_CTRL.getOpportunitiesWithOppPayments(opp.Id);
        } catch (AuraHandledException ahe) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown,
                'The getOpportunitiesWithOppPayments method only supports Account and Contact Ids.');
    }

    @isTest
    static void
    givenActiveFieldIsUnmappedWhenLoadedThenColumnNotIncludedOnBGEForm_AdvancedMapping
            () {
        UTIL_CustomSettingsFacade.enableAdvancedMapping();

        //Create a stub of BDI_MappingServiceAdvanced, to mock the scenario where some
        //active/selected fields on the Batch are not mapped.
        BDIFieldMappingMock mock = new BDIFieldMappingMock();
        BDI_MappingServiceAdvanced stub = (BDI_MappingServiceAdvanced) Test.createStub(
                BDI_MappingServiceAdvanced.class,
                mock
        );
        BDI_MappingServiceAdvanced.setInstance(stub);

        givenActiveFieldIsUnmappedWhenLoadedThenColumnNotIncludedOnBGEForm(mock);
    }

    @isTest
    static void
    givenActiveFieldIsUnmappedWhenLoadedThenColumnNotIncludedOnBGEForm_HelpTextMapping
            () {
        UTIL_CustomSettingsFacade.enableHelpTextMapping();

        //Create a stub of BDI_MappingServiceHelpText, to mock the scenario where some
        //active/selected fields on the Batch are not mapped.
        BDIFieldMappingMock mock = new BDIFieldMappingMock();
        BDI_MappingServiceHelpText stub = (BDI_MappingServiceHelpText) Test.createStub(
                BDI_MappingServiceHelpText.class,
                mock
        );
        BDI_MappingServiceHelpText.setInstance(stub);

        givenActiveFieldIsUnmappedWhenLoadedThenColumnNotIncludedOnBGEForm(mock);
    }

    static void givenActiveFieldIsUnmappedWhenLoadedThenColumnNotIncludedOnBGEForm(
            BDIFieldMappingMock mockInstance
    ) {
        //Set Active Fields on a Batch, some with mappings and some without
        List<SObjectField> unmappedFields = new List<SObjectField>{
                DataImport__c.Donation_Amount__c,
                DataImport__c.Payment_Check_Reference_Number__c
        };
        List<SObjectField> mappedFields = new List<SObjectField>(
                mockInstance.mappedFields
        );
        List<SObjectField> activeFields = new List<SObjectField>();
        activeFields.addAll(unmappedFields);
        activeFields.addAll(mappedFields);

        DataImportBatch__c batch = new DataImportBatch__c(
                Name = 'Test Batch 1',
                Active_Fields__c = JSON.serialize(getBGEFieldList(activeFields))
        );
        insert batch;

        //Test by calling setColumns() on a DataImportModel instance.
        BGE_DataImportBatchEntry_CTRL.DataImportModel dataImportModel = new
                BGE_DataImportBatchEntry_CTRL.DataImportModel();
        dataImportModel.id = batch.Id;
        dataImportModel.setColumns();

        //Assertions
        Set<String> columnFieldNames = new Set<String>();
        for (BGE_DataImportBatchEntry_CTRL.Column column : dataImportModel.columns) {
            columnFieldNames.add(column.fieldName);
        }
        for (SObjectField sObjectField : unmappedFields) {
            System.assert(!columnFieldNames.contains(sObjectField.getDescribe().getName()),
                    'Fields that do not have field mappings configured should not be ' +
                            'displayed on the Batch Gift Entry form.');
        }
        for (SObjectField sObjectField : mappedFields) {
            System.assert(columnFieldNames.contains(sObjectField.getDescribe().getName()),
                    'Fields that have field mappings configured should be ' +
                            'displayed on the Batch Gift Entry form.');
        }

        Boolean hasUnmappedFieldNotice = false;
        for (UTIL_LightningComponentSupport.Notice notice : dataImportModel.notices) {
            if (notice instanceof BGE_DataImportBatchEntry_CTRL.UnmappedFieldsNotice) {
                hasUnmappedFieldNotice = true;
            }
        }
        System.assert(hasUnmappedFieldNotice, 'The DataImportModel instance should have an ' +
                'UnmappedFieldNotice since at least one active field has no mapping.');
    }

    /**
     * @description StubProvider implementation used to mock a scenario where no target
     * fields are mapped.
     */
    private class BDIFieldMappingMock implements StubProvider {
        private Map<SObjectField, BDI_TargetFields> targetFieldsBySourceField = new
                Map<SObjectField, BDI_TargetFields>();
        public Set<SObjectField> mappedFields {
            get {
                return targetFieldsBySourceField.keySet();
            }
        }

        public BDIFieldMappingMock() {
            mapDefaultFields();
        }

        private void mapDefaultFields() {
            mapField(DataImport__c.Donation_Description__c, Opportunity.SObjectType,
                    Opportunity.Description);
            mapField(DataImport__c.Payment_Method__c, npe01__OppPayment__c.SObjectType,
                    npe01__OppPayment__c.npe01__Payment_Method__c);
        }

        @TestVisible
        private void mapField(SObjectField sourceField, SObjectType targetObjectType,
                SObjectField targetField) {
            BDI_TargetFields targetFields = targetFieldsBySourceField.get(sourceField);
            if (targetFields == null) {
                targetFields = new BDI_TargetFields();
            }
            targetFields.addTargetField(targetObjectType, targetField);
            targetFieldsBySourceField.put(sourceField, targetFields);
        }

        public Object handleMethodCall(
                Object stubbedObject,
                String stubbedMethodName,
                Type returnType,
                List<Type> listOfParamTypes,
                List<String> listOfParamNames,
                List<Object> listOfArgs) {
            switch on stubbedMethodName {
                when 'getTargetFieldsBySourceField' {
                    return targetFieldsBySourceField;
                }
            }
            return null;
        }
    }

    /******************************** Helper Methods *****************************/

    /**
    * @description Constructs a List of BGEFields from a List of SObjectFields.
    * @param fields The List of SObjectFields to use to create the List of BGEFields.
    * @return The new List of BGEFields.
    */
    private static List<BGE_ConfigurationWizard_CTRL.BGEField> getBGEFieldList
            (List<SObjectField>
                    fields) {
        List<BGE_ConfigurationWizard_CTRL.BGEField> bgeFields = new List<BGE_ConfigurationWizard_CTRL.BGEField>();
        for (SObjectField sObjectField : fields) {
            BGE_ConfigurationWizard_CTRL.BGEField bgeField = new
                    BGE_ConfigurationWizard_CTRL.BGEField();
            bgeField.name = sObjectField.getDescribe().getName();
            bgeFields.add(bgeField);
        }
        return bgeFields;
    }

    private static Opportunity createOpportunity(String oppName, Id primaryContactId) {
        Opportunity opp = new Opportunity(
                Name = oppName,
                Primary_Contact__c = primaryContactId,
                Amount = 100,
                CloseDate = System.today(),
                StageName = UTIL_UnitTestData_TEST.getOpenStage(),
                npe01__Do_Not_Automatically_Create_Payment__c = false
        );
        return opp;
    }

    private static npe01__OppPayment__c createPayment(Id oppId){
        npe01__OppPayment__c openPmt = new npe01__OppPayment__c(
                npe01__Opportunity__c = oppId,
                npe01__Payment_Amount__c = 5,
                npe01__Scheduled_Date__c = Date.today().addDays(1),
                npe01__Paid__c = false
        );
        return openPmt;
    }

    private static List<BGE_DataImportBatchEntry_CTRL.OpportunityWrapper> createOppWrappers(
            String jsonOppsWithPayments) {
        return (List<BGE_DataImportBatchEntry_CTRL.OpportunityWrapper>) JSON.deserialize(
                jsonOppsWithPayments,
                List<BGE_DataImportBatchEntry_CTRL.OpportunityWrapper>.class);
    }

    private static List<npe01__OppPayment__c> getOppPayments(Id oppId) {
        return [
                SELECT Id, npe01__Opportunity__c, npe01__Paid__c
                FROM npe01__OppPayment__c
                WHERE npe01__Opportunity__c = :oppId
        ];
    }

    /**
    * @description StubProvider implementation used to modify Data Import Permissions in a test context
    */
    private class UTIL_PermissionsMock implements StubProvider {

        public Boolean canDeleteDataImport = true;

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName,
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames,
                List<Object> listOfArgs) {

            if (stubbedMethodName == 'canDelete' && listOfArgs.size() == 1) {
                Schema.SObjectType sObjectType = (Schema.SObjectType)listOfArgs[0];
                if(sObjectType == DataImport__c.SObjectType) {
                    return canDeleteDataImport;
                }
            }
            return true;
        }
    }
}