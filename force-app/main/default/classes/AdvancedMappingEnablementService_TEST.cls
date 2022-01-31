@IsTest
private class AdvancedMappingEnablementService_TEST {

    @IsTest
    private static void shouldExecuteHelpTextMigrationOnEnable() {
        AdvancedMappingEnablementService mappingService = new AdvancedMappingEnablementService();
        BDI_MigrationMappingUtilityMock migrationMappingUtilityMock = new BDI_MigrationMappingUtilityMock();
        mappingService.migrationMappingUtility = stubFor(migrationMappingUtilityMock);
        mappingService.migrationMappingUtility.queuedMetadataTypesForDeploy = getMockMetadata();

        Test.startTest();
            mappingService.enable();
        Test.stopTest();

        System.assert(migrationMappingUtilityMock.migrateHelpTextCalled, 'The migration of help text to custom ' +
                'metadata should execute.');
    }

    @IsTest
    private static void shouldUpdateCustomSettingsForDataImportFieldMapping() {
        BDI_MigrationMappingUtility.DeploymentCallback callback = new BDI_MigrationMappingUtility.DeploymentCallback();
        TestingDeployCallbackContext context = new TestingDeployCallbackContext();

        Metadata.DeployResult deployResult = new Metadata.DeployResult();
        deployResult.status = Metadata.DeployStatus.Succeeded;

        Test.startTest();
            callback.handleResult(deployResult, context);
        Test.stopTest();

        Data_Import_Settings__c dataImportSettings = UTIL_CustomSettingsFacade.getDataImportSettings();

        System.assertNotEquals(Metadata.DeployStatus.Succeeded.name(), dataImportSettings.CMT_API_Status__c);


        System.assert(new AdvancedMappingEnablementService().isEnabled(), 'Advanced mapping should be enabled.');
    }

    private static List<Metadata.CustomMetadata> getMockMetadata() {
        List<Metadata.CustomMetadata> mockCustomMetadataRecords = new List<Metadata.CustomMetadata>();
        Metadata.CustomMetadata mockCustomMetadata1 = new Metadata.CustomMetadata();

        mockCustomMetadata1.description = 'test';
        mockCustomMetadata1.fullName = 'test_metadata';
        mockCustomMetadata1.label = 'test';
        mockCustomMetadataRecords.add(mockCustomMetadata1);

        return mockCustomMetadataRecords;
    }

    private static BDI_MigrationMappingUtility stubFor(BDI_MigrationMappingUtilityMock migrationMappingUtilityMock) {

        return (BDI_MigrationMappingUtility) Test.createStub(
                BDI_MigrationMappingUtility.class, migrationMappingUtilityMock);
    }

    private class BDI_MigrationMappingUtilityMock implements StubProvider {
        private Boolean migrateHelpTextCalled = false;

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, Type returnType,
                List<Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {

            switch on (stubbedMethodName) {
                when 'migrateHelpTextToCustomMetadata' {
                    migrateHelpTextCalled = true;
                }
            }

            return null;
        }
    }

    private class TestingDeployCallbackContext extends Metadata.DeployCallbackContext {
        public override Id getCallbackJobId() {
            return '000000000122345';
        }
    }
}