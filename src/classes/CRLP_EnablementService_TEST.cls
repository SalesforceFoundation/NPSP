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
* @group Customizable Rollups
* @group-content ../../ApexDocContent/Rollups2.htm
* @description Enablement Services for Customizable Rollups
*/
@IsTest
private class CRLP_EnablementService_TEST {

    /**
    * @description Verify that calling the Enable() method returns back a Job Id. The rest of the process
    * is never actually executed in a unit test context
    */
    @IsTest
    private static void shouldEnableCustomizableRollupsWithoutSchedulingJobs() {
        Customizable_Rollup_Settings__c crlpSettings = UTIL_CustomSettingsFacade.getRollupSettingsForTests(
            new Customizable_Rollup_Settings__c()
        );
        upsert crlpSettings;

        CRLP_Rollup_SEL.cachedRollups.clear();

        CRLP_EnablementService.RollupMetadataHandler deploymentHandler = new CRLP_EnablementService.RollupMetadataHandler();

        Test.startTest();
        CRLP_EnablementService enablementService = new CRLP_EnablementService();
        String jobId = enablementService.enable(false);
        System.assertNotEquals(null, jobId, 'There should be a jobId returned');
        deploymentHandler.performSuccessHandler(
            new Map<String, Object> {
                CallableApiParameters.PARAM_SCHEDULE_JOBS => false
            },
            CMT_MetadataAPI.DEPLOYMENT_SUCCESS_TEXT
        );
        Test.stopTest();

        crlpSettings = Customizable_Rollup_Settings__c.getOrgDefaults();
        System.assertEquals(true, crlpSettings.Customizable_Rollups_Enabled__c, 'CRLP Should be Enabled');

        Integer scheduledJobCount = [SELECT COUNT()
            FROM AsyncApexJob
            WHERE JobType = 'ScheduledApex'
            LIMIT 1];
        System.assertEquals(0, scheduledJobCount, 'There should be no scheduled jobs');
    }

    /**
    * @description Verify that calling the Disable() properly disables CRLP
    */
    @IsTest
    private static void shouldDisableCustomizableRollups() {
        Customizable_Rollup_Settings__c crlpSettings = UTIL_CustomSettingsFacade.getRollupSettingsForTests(
            new Customizable_Rollup_Settings__c(
                Customizable_Rollups_Enabled__c = true
            )
        );
        upsert crlpSettings;

        Test.startTest();
        CRLP_EnablementService enablementService = new CRLP_EnablementService();
        enablementService.disable();
        Test.stopTest();

        crlpSettings = Customizable_Rollup_Settings__c.getOrgDefaults();
        System.assertEquals(false, crlpSettings.Customizable_Rollups_Enabled__c, 'CRLP Should be Disabled');
    }

    /**
    * @description Verify that calling the reset() properly enables CRLP
    */
    @IsTest
    private static void shouldResetCustomizableRollups() {
        Customizable_Rollup_Settings__c crlpSettings = UTIL_CustomSettingsFacade.getRollupSettingsForTests(
            new Customizable_Rollup_Settings__c()
        );
        upsert crlpSettings;

        CRLP_Rollup_SEL.cachedRollups.clear();

        CRLP_EnablementService.RollupMetadataHandler deploymentHandler = new CRLP_EnablementService.RollupMetadataHandler();

        Test.startTest();
        CRLP_EnablementService enablementService = new CRLP_EnablementService();
        String jobId = enablementService.reset();
        System.assertNotEquals(null, jobId, 'There should be a jobId returned');
        deploymentHandler.performSuccessHandler(
            new Map<String, Object> {
                CallableApiParameters.PARAM_SCHEDULE_JOBS => true
            },
            CMT_MetadataAPI.DEPLOYMENT_SUCCESS_TEXT
        );
        Test.stopTest();

        crlpSettings = Customizable_Rollup_Settings__c.getOrgDefaults();
        System.assertEquals(true, crlpSettings.Customizable_Rollups_Enabled__c, 'CRLP Should be Enabled');

        Integer scheduledJobCount = [SELECT COUNT()
            FROM AsyncApexJob
            WHERE JobType = 'ScheduledApex'
            LIMIT 1];
        System.assertEquals(1, scheduledJobCount, 'There should be scheduled jobs');
    }
}