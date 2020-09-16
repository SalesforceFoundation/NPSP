@isTest
private with sharing class GE_GiftEntryController_TEST {

    /*********************************************************************************************************
    * @description Sets up a new NPSP_Data_Import_Batch__c Record
    * @return Id of the new NPSP_Data_Import_Batch__c
    */
    private static Id createDataImportBatch( String batchName ) {
        DataImportBatch__c dataImportBatch = new DataImportBatch__c();
        dataImportBatch.Name = batchName;

        insert dataImportBatch;
        return (Id)dataImportBatch.Id;
    }

    /*******************************************************************************************************
    * @description creates a new di record for tests
    * @param firstname the firstname to specify for Contact1
    * @param lastname the lastname to specify for Contact1
    * @return DataImport__c the new Data Import record
    */
    public static DataImport__c newDI(String firstname, String lastname, Id batchId) {
        return new DataImport__c(
                Contact1_Firstname__c = firstname,
                Contact1_Lastname__c = lastname,
                Contact1_Personal_Email__c = firstname + '@' + lastname + '.com',
                NPSP_Data_Import_Batch__c = batchId
        );
    }

    /*******************************************************************************************************
     * @description Confirm that the Data Import upsert method inserts and updates correctly.
     */
    @isTest
    private static void shouldUpsertDataImportRecord() {
        DataImport__c inMemoryDataImport = BDI_DataImport_TEST.newDI('First', 'Last', 100);
        DataImport__c dataImportRecord = GE_GiftEntryController.upsertDataImport(inMemoryDataImport);
        System.assert(dataImportRecord.Id != null);

        dataImportRecord.Payment_Authorization_Token__c = 'TEST_TOKEN';
        DataImport__c updatedDataImportRecord = GE_GiftEntryController.upsertDataImport(dataImportRecord);
        System.assertEquals(dataImportRecord.Id, updatedDataImportRecord.Id);
        System.assertEquals('TEST_TOKEN', updatedDataImportRecord.Payment_Authorization_Token__c);
    }

    /*******************************************************************************************************
     * @description Confirm that the Data Import processes correctly and returns an Opportunity id.
     */
    @isTest
    private static void shouldProcessDataImportRecord() {
        DataImport__c inMemoryDataImport = BDI_DataImport_TEST.newDI('First', 'Last', null);
        inMemoryDataImport.Donation_Amount__c = 10;
        DataImport__c dataImportRecord = GE_GiftEntryController.upsertDataImport(inMemoryDataImport);

        System.assert(dataImportRecord.Id != null);
        System.assert(dataImportRecord.Donation_Amount__c == 10);

        Test.StartTest();
        Boolean matchToExistingDonation = false;
        String opportunityId = GE_GiftEntryController.submitDataImportToBDI(dataImportRecord, matchToExistingDonation);
        Test.stopTest();

        System.assert(opportunityId != null);
    }

    /*******************************************************************************************************
     * @description Saves the data import record, dry runs the record, and returns updated
     * totals with the new row.
     */
    @isTest
    private static void testShouldSaveAndDryRunDataImport() {

        // required setting
        UTIL_CustomSettingsFacade.getDataImportSettings();
        // aux vars
        String firstName = 'fooName';
        String lastName = 'fooLastName';
        String batchName = 'fooBatch';
        // test data
        Id batchId = createDataImportBatch( batchName );
        DataImport__c di = newDI( firstName, lastName, batchId );

        Test.startTest();
        GE_GiftEntryController.saveAndDryRunDataImport(batchId,di);
        Test.stopTest();

        List<DataImportBatch__c> result = [SELECT Id FROM DataImportBatch__c];
        System.assertEquals( result.size(), 1 );

    }

    /*******************************************************************************************************
     * @description Confirm that a default RenderWrapper is correctly returned
     */
    @isTest
    private static void createAndReturnDefaultFormTemplate() {
        Gift_Entry_Settings__c giftEntryCustomSetting = new Gift_Entry_Settings__c();
        Form_Template__c defaultTemplate = returnFormTemplate();

        FORM_Template template = UTIL_UnitTestData_TEST.createSampleTemplate();

        String templateJSON = JSON.serialize(template);
        defaultTemplate.Template_JSON__c = templateJSON;

        insert defaultTemplate;

        giftEntryCustomSetting.Default_Gift_Entry_Template__c = defaultTemplate.Id;

        UTIL_CustomSettingsFacade.getGiftEntrySettingsForTests(giftEntryCustomSetting);

        GE_GiftEntryController.RenderWrapper frw = GE_GiftEntryController.getDefaultSGERenderWrapper();
        System.assert(frw.formTemplate != null);
        System.assert(frw.formTemplate.name == template.name);

        frw = GE_GiftEntryController.getRenderWrapperById(defaultTemplate.Id);
        System.assert(frw.formTemplate != null);
        System.assert(frw.formTemplate.name == template.name);

    }

    private static Form_Template__c returnFormTemplate(){
        return new Form_Template__c(
                Name = 'Test',
                Format_Version__c = '1.0'
        );
    }

    /*******************************************************************************************************
     * @description Tests that widget data can be properly coverted to the BDI_DynamicSourceGroup format required
     * by BDI for N number of objects processing.
     */
    @isTest
    private static void widgetDataShouldBeConvertedIntoDynamicSources() {
        General_Accounting_Unit__c gau1 = new General_Accounting_Unit__c(Name = 'TestGroupA GAU 1',
                Active__c = true);

        General_Accounting_Unit__c gau2 = new General_Accounting_Unit__c(Name = 'TestGroupA GAU 2',
                Active__c = true);
        General_Accounting_Unit__c[] testGAUs = new General_Accounting_Unit__c[]{gau1,gau2};
        insert testGAUs;

        SObject sourceObjA1 = UTIL_Describe.getPrototypeObject(SObjectType.Allocation__c.getName());
        sourceObjA1.put(Allocation__c.General_Accounting_Unit__c.getDescribe().getName(),
                gau1.Id);
        sourceObjA1.put(Allocation__c.Percent__c.getDescribe().getName(),75);

        SObject sourceObjA2 = UTIL_Describe.getPrototypeObject(SObjectType.Allocation__c.getName());
        sourceObjA2.put(Allocation__c.General_Accounting_Unit__c.getDescribe().getName(),
                gau2.Id);
        sourceObjA2.put(Allocation__c.Percent__c.getDescribe().getName(),25);

        Sobject[] testWidgetRecords = new Sobject[]{sourceObjA1,sourceObjA2};

        Map<String,SObject[]> widgetData = new Map<String,SObject[]>();

        widgetData.put('GAU_Allocation_1',testWidgetRecords);

        String widgetDataString = JSON.serialize(widgetData);

        DataImport__c testDI = new DataImport__c();
        Test.startTest();
        testDI.Additional_Object_JSON__c = GE_GiftEntryController.convertWidgetDataToObjectJSON(widgetDataString);
        Test.stopTest();

        System.assertNotEquals(null,testDI.Additional_Object_JSON__c);

        BDI_DynamicSourceGroup testDSG =
                (BDI_DynamicSourceGroup)JSON.deserialize(testDI.Additional_Object_JSON__c, BDI_DynamicSourceGroup.class);

        System.assertNotEquals(null,testDSG);
        System.assertEquals(2,testDSG.dynamicSourceByObjMappingDevName.size());

        BDI_DynamicSource dynSource1;
        BDI_DynamicSource dynSource2;

        for (String objMappingDevName : testDSG.dynamicSourceByObjMappingDevName.keySet()) {
            BDI_DynamicSource tempDS = testDSG.dynamicSourceByObjMappingDevName.get(objMappingDevName);
            if (tempDS.sourceObj.get('GAU_Allocation_1_GAU__c') == gau1.Id) {
                dynSource1 = tempDS;
            } else if (tempDS.sourceObj.get('GAU_Allocation_1_GAU__c')  == gau2.Id) {
                dynSource2 = tempDS;
            }
        }

        System.assertNotEquals(null, dynSource1);
        System.assertNotEquals(null, dynSource2);
        System.assertEquals(75,dynSource1.sourceObj.get('GAU_Allocation_1_Percent__c'));
        System.assertEquals(25,dynSource2.sourceObj.get('GAU_Allocation_1_Percent__c'));
    }

}