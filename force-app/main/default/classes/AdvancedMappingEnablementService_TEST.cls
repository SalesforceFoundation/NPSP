/*
    Copyright (c) 2022, Salesforce.org
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