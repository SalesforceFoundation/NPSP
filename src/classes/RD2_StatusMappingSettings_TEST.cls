/*
    Copyright (c) 2020, Salesforce.org
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
* @date 2020
* @group Recurring Donations
* @description Tests to save and retrieve Recurring Donation status to status type mapping
*/
@IsTest
private with sharing class RD2_StatusMappingSettings_TEST {
    private static final String STATUS_NEW = 'New';
    private static final String STATUS_CANCELED = 'Canceled';
    private static final String MOCK_DEPLOYMENT_ID = '000000000122345AAA';


    /**
     * @description Verifies default Status picklist field mapping records are returned
     */
    @IsTest
    private static void shouldReturnDefaultStatusMapping() {
        RD2_StatusMappingSettings_CTRL.statusMapper = (RD2_StatusMapper) Test.createStub(
            RD2_StatusMapper.Class,
            new RD2_StatusMapper_TEST.Stub().withDefaultMapping()
        );

        List<RD2_StatusMappingSettings_CTRL.Mapping> records = RD2_StatusMappingSettings_CTRL.loadMapping();
        System.assertEquals(3, records.size(), 'Default status values should be returned: ' + records);

        Set<String> statusValues = new Set<String>();
        for (RD2_StatusMappingSettings_CTRL.Mapping mapping: records) {
            statusValues.add(mapping.status);
            System.assertEquals(mapping.status, mapping.state, 'Status should be the same as the state');
        }

        RD2_StatusMapper_TEST.assertDefaultStatusValues(statusValues);
    }

    /**
     * @description Verifies default Status picklist field mapping records are returned first
     * when admin creates custom picklist status values
     */
    @IsTest
    private static void shouldReturnDefaultStatusMappingFirstWhenCustomValuesExist() {
        String nullState = null;
        RD2_StatusMappingSettings_CTRL.statusMapper = (RD2_StatusMapper) Test.createStub(
            RD2_StatusMapper.Class,
            new RD2_StatusMapper_TEST.Stub()
                .withMapping(STATUS_NEW, RD2_Constants.STATUS_ACTIVE)
                .withMapping(STATUS_CANCELED, nullState)
                .withDefaultMapping()
        );

        List<RD2_StatusMappingSettings_CTRL.Mapping> records = RD2_StatusMappingSettings_CTRL.loadMapping();
        System.assertEquals(5, records.size(), 'All status values should be returned: ' + records);

        System.assertEquals(RD2_Constants.STATUS_ACTIVE, records[0].status, 'First Status should be Active status');
        System.assertEquals(RD2_Constants.STATUS_LAPSED, records[1].status, 'Second Status should be Lapsed status');
        System.assertEquals(RD2_Constants.STATUS_CLOSED, records[2].status, 'Third Status should be Closed status');

        Integer newStatusIndex = records[3].status == STATUS_NEW ? 3 : 4;
        Integer canceledStatusIndex = records[3].status == STATUS_CANCELED ? 3 : 4;

        System.assertEquals(RD2_Constants.STATUS_ACTIVE, records[newStatusIndex].state,
            'State for the New Status should match');
        System.assertEquals(System.Label.RD2_StatusMappingStateUnmapped, records[canceledStatusIndex].state,
            'State for the Canceled Status should be unmapped state');
    }

    /**
     * @description Verifies custom metadata type (CMT) records are built as expected
     */
    @IsTest
    private static void shouldBuildCustomMetadataRecordsOnSave() {
        RD2_StatusMappingSettings_CTRL.statusMapper = (RD2_StatusMapper) Test.createStub(
            RD2_StatusMapper.Class,
            new RD2_StatusMapper_TEST.Stub()
                .withMapping(STATUS_NEW, RD2_Constants.STATUS_ACTIVE)
                .withMapping(STATUS_CANCELED, RD2_Constants.STATUS_CLOSED)
                .withDefaultMapping()
        );
        List<RD2_StatusMappingSettings_CTRL.Mapping> records = RD2_StatusMappingSettings_CTRL.loadMapping();

        //change the state for the Canceled status
        Integer index = records[3].status == STATUS_CANCELED ? 3 : 4;
        records[index].state = RD2_Constants.STATUS_LAPSED;

        String jsonMapping = JSON.serialize(records);
        List<Metadata.CustomMetadata> cmtRecords = RD2_StatusMappingSettings_CTRL.buildCustomMetadataRecords(jsonMapping);
        System.assertEquals(5, cmtRecords.size(), 'All CMT records should be returned: ' + records);

        String sObjectName = RecurringDonationStatusMapping__mdt.getSObjectType().getDescribe().getName();
        for (Integer i = 0; i < cmtRecords.size(); i++) {
            Metadata.CustomMetadata cmt = cmtRecords[i];
            String status = records[i].status;

            System.assertEquals(sObjectName + '.' + status, cmt.fullName, 'CMT Full Name should match');
            System.assert(cmt.label.startsWith(status), 'CMT Label should start with the status value: ' + cmt.label);

            System.assertEquals(2, cmt.values.size(), 'CMT fields should be set: ' + cmt.values);

            for (Metadata.CustomMetadataValue field : cmt.values) {
                if (field.field.endsWith('Status__c')) {
                    System.assertEquals(status, field.value, 'CMT Status should match');
                } else {
                    System.assertEquals(records[i].state, field.value, 'CMT State should match');
                    if (status == STATUS_CANCELED) {
                        System.assertEquals(RD2_Constants.STATUS_LAPSED, field.value, 'State for the Canceled Status should match');
                    }
                }
            }
        }
    }

    /**
     * @description Verifies deployment handler save method is called with expected CMT records
     */
    @IsTest
    private static void shouldSaveMappingRecords() {
        RD2_StatusMappingSettings_CTRL.statusMapper = (RD2_StatusMapper) Test.createStub(
            RD2_StatusMapper.Class,
            new RD2_StatusMapper_TEST.Stub().withDefaultMapping()
        );
        String jsonMapping = JSON.serialize(RD2_StatusMappingSettings_CTRL.loadMapping());

        TestDeploymentHandler deploymentHandler = new TestDeploymentHandler()
            .withDeploymentId(MOCK_DEPLOYMENT_ID);

        String deploymentId = RD2_StatusMappingSettings_CTRL.saveMapping(jsonMapping, deploymentHandler);

        System.assertEquals(true, deploymentHandler.isSaveCalled, 'The method to save records should be called');
        System.assertEquals(3, deploymentHandler.records.size(), 'CMT records should be passed to the save method');
        System.assertEquals(MOCK_DEPLOYMENT_ID, deploymentId, 'Deployment Id should match');
    }

    /**
     * @description Verifies an exception is generated when the "save" method is called
     * and another status to state mapping records deployment is in progress
     */
    @IsTest
    private static void shouldThrowExceptionWhenAnotherDeploymentIsInProgressOnSave() {
        RD2_StatusMappingSettings_CTRL.statusMapper = (RD2_StatusMapper) Test.createStub(
            RD2_StatusMapper.Class,
            new RD2_StatusMapper_TEST.Stub().withDefaultMapping()
        );
        String jsonMapping = JSON.serialize(RD2_StatusMappingSettings_CTRL.loadMapping());

        Metadata.DeployResult deployResult = new Metadata.DeployResult();
        deployResult.status = Metadata.DeployStatus.INPROGRESS;

        TestDeploymentHandler deploymentHandler = new TestDeploymentHandler()
            .withDeploymentId(MOCK_DEPLOYMENT_ID)
            .withDeployResult(deployResult);

        Exception actualException;
        try {
            RD2_StatusMappingSettings_CTRL.saveMapping(jsonMapping, deploymentHandler);
        } catch (Exception e) {
            actualException = e;
        }

        System.assertNotEquals(null, actualException, 'An exception should be generated');
        System.assertEquals(System.Label.RD2_StatusMappingDeploymentAlreadyInProgress, actualException.getMessage(),
            'The exception message should match');

        System.assertEquals(false, deploymentHandler.isSaveCalled,
            'The method to save CMT records should not be called');
    }

    /**
     * @description Verifies deployment result is returned for the specified deployment Id
     */
    @IsTest
    private static void shouldReturnDeployResultForTheSpecifiedDeploymentId() {
        String errorMessage = 'foo';

        Metadata.DeployResult deployResult = new Metadata.DeployResult();
        deployResult.status = Metadata.DeployStatus.INPROGRESS;

        TestDeploymentHandler deploymentHandler = new TestDeploymentHandler()
            .withDeploymentId(MOCK_DEPLOYMENT_ID)
            .withDeployResult(deployResult)
            .withDeployErrorMessage(errorMessage);

        String jsonDeployResult = 
            RD2_StatusMappingSettings_CTRL.getDeployResult(MOCK_DEPLOYMENT_ID, deploymentHandler);

        RD2_StatusMappingSettings_CTRL.DeployResult result = 
            (RD2_StatusMappingSettings_CTRL.DeployResult) JSON.deserialize(
                jsonDeployResult, RD2_StatusMappingSettings_CTRL.DeployResult.class
            );

        System.assertNotEquals(null, result, 'Deploy Result should be returned');
        System.assertEquals(MOCK_DEPLOYMENT_ID, result.deploymentId, 'Deployment Id should match');
        System.assertEquals(true, result.hasResult, 'Deploy result should exist');
        System.assertEquals(true, result.isInProgress, 'Deployment should be in progress');
        System.assertEquals(false, result.isSuccess, 'Deployment success status is false currently');
        System.assertEquals(errorMessage, result.errorMessage, 'Deployment error message should match');
    }

    /**
     * @description Verifies deployment handler determines deploy result properties correctly
     */
    @IsTest
    private static void shouldDetermineDeployResultProperties() {
        STG_Panel.stgService.stgRD.StatusMappingDeploymentId__c = MOCK_DEPLOYMENT_ID;

        RD2_StatusMappingSettings_CTRL.DeploymentHandler deploymentHandler = new RD2_StatusMappingSettings_CTRL.DeploymentHandler();

        Metadata.DeployResult deployResult = new Metadata.DeployResult();
        deployResult.status = Metadata.DeployStatus.PENDING;
        deploymentHandler.deployResult = deployResult;

        System.assertEquals(MOCK_DEPLOYMENT_ID, deploymentHandler.getDeploymentId(), 'Deployment Id should match');
        System.assertEquals(true, deploymentHandler.isInProgress(), 'Deployment should be in progress');
        System.assertEquals(false, deploymentHandler.isSuccess(), 'Deployment should not be set to success yet');
        System.assertEquals('', deploymentHandler.getDeployErrorMessage(), 'Deployment error message should not be set');
    }

    /**
     * @description Verifies deployment Id is saved in the RD settings when deployment completes
     */
    @IsTest
    private static void shouldSaveDeploymentIdInRDSettingsWhenDeploymentCompletes() {
        STG_Panel.stgService.stgRD.StatusMappingDeploymentId__c = null;

        RD2_StatusMappingSettings_CTRL.DeploymentCallbackHandler callback = new RD2_StatusMappingSettings_CTRL.DeploymentCallbackHandler();
        TestDeployCallbackContext callbackContext = new TestDeployCallbackContext();

        Metadata.DeployResult deployResult = new Metadata.DeployResult();
        deployResult.status = Metadata.DeployStatus.SUCCEEDED;
        deployResult.Id = MOCK_DEPLOYMENT_ID;

        callback.handleResult(deployResult, callbackContext);

        System.assertEquals(MOCK_DEPLOYMENT_ID, STG_Panel.stgService.stgRD.StatusMappingDeploymentId__c, 
            'Deployment Id should be saved in the RD settings');
    }



    // Helpers
    //////////////////

    /**
     * @description Deployment Handler implementing the deployment interface so the "save" method can be verified
     */
    public class TestDeploymentHandler implements RD2_StatusMappingSettings_CTRL.MetadataDeploymentHandler {
        private String deploymentId;
        private Metadata.DeployResult deployResult;
        private String deploymentMessage;

        public List<Metadata.CustomMetadata> records = new List<Metadata.CustomMetadata>();
        public Boolean isSaveCalled = false;
        public Boolean isSaveDeploymentIdCalled = false;

        public TestDeploymentHandler withDeploymentId(String deploymentId) {
            this.deploymentId = deploymentId;
            return this;
        }

        public TestDeploymentHandler withDeployResult(Metadata.DeployResult deployResult) {
            this.deployResult = deployResult;
            return this;
        }

        public TestDeploymentHandler withDeployErrorMessage(String message) {
            this.deploymentMessage = message;
            return this;
        }

        public String getDeploymentId() {
            return deploymentId;
        }

        public Boolean hasDeployResult() {
            return deployResult != null;
        }

        public Boolean isInProgress() {
            return deployResult != null && deployResult.status == Metadata.DeployStatus.INPROGRESS;
        }

        public Boolean isSuccess() {
            return deployResult != null && deployResult.status == Metadata.DeployStatus.SUCCEEDED;
        }

        public String getDeployErrorMessage() {
            return deploymentMessage;
        }

        public void save(List<Metadata.CustomMetadata> records) {
            this.records = records;
            isSaveCalled = true;
        }

        public void saveDeploymentId() {
            this.deploymentId = deploymentId;
            isSaveDeploymentIdCalled = true;
        }
    }

    /**
     * @description Deployment callback context returning a deployment Id
     */
    public class TestDeployCallbackContext extends Metadata.DeployCallbackContext {
        public override Id getCallbackJobId() {
            return MOCK_DEPLOYMENT_ID;
        }
    }

}
