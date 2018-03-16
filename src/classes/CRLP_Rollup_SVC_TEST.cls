/*
    Copyright (c) 2018, Salesforce.org
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
* @group Customizable Rollups Operations Services
* @description Unit Test for the Rollup Operation Services Classes
*/
@isTest(IsParallel=true)
private class CRLP_Rollup_SVC_TEST {

    /**
     * @description Simple tests for static methods to retrieve customizable rollup settings
     */
    static testMethod void test_get_batch_sizes() {
        // Start by enabling Customizable Rollups (which disables all legacy rollup operations)
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
                        Customizable_Rollups_Enabled__c = true,
                        Rollups_Limit_on_Attached_Opps_for_Skew__c = 200,
                        Rollups_Account_SkewMode_Batch_Size__c = 200,
                        Rollups_Contact_SkewMode_Batch_Size__c = 200,
                        Rollups_Contact_Soft_Credit_Batch_Size__c = 200,
                        Rollups_GAU_Batch_Size__c = 400,
                        Rollups_Account_Batch_Size__c = 20,
                        Rollups_Contact_Batch_Size__c = 20
                ));

        system.assertEquals(20, CRLP_RollupBatch_SVC.getBatchSize(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit, CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode));
        system.assertEquals(20, CRLP_RollupBatch_SVC.getBatchSize(CRLP_RollupProcessingOptions.RollupType.ContactHardCredit, CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode));
        system.assertEquals(200, CRLP_RollupBatch_SVC.getBatchSize(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit, CRLP_RollupProcessingOptions.BatchJobMode.SkewMode));
        system.assertEquals(200, CRLP_RollupBatch_SVC.getBatchSize(CRLP_RollupProcessingOptions.RollupType.ContactHardCredit, CRLP_RollupProcessingOptions.BatchJobMode.SkewMode));
        system.assertEquals(400, CRLP_RollupBatch_SVC.getBatchSize(CRLP_RollupProcessingOptions.RollupType.GAU, CRLP_RollupProcessingOptions.BatchJobMode.SkewMode));

        system.assertEquals(200, CRLP_Rollup_SVC.getMaxRelatedOppsForNonSkewMode());
        system.assertEquals(true, CRLP_Rollup_SVC.isCustomizableRollupEngineEnabled);
        system.assertNotEquals(null, CRLP_Rollup_SVC.getSObjectFieldDescribe('Account', 'Name'));
    }

    /**
     * @description Test the CRLP_Rollup_TDTM.isRollupRecalcNeeded() method against various versions of
     * changed and similar SObjects
     */
    static testMethod void test_isRecalcNeeded() {

        // Dummy Rollups CMT data to work with
        String filterGroupId1 = CMT_UnitTestData_TEST.getNewRecordId();
        String rollupsJSON = '[' +
                CMT_UnitTestData_TEST.createRollupRecord('Numberic Field', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToAcct,
                        'npo02__TotalOppAmount__c', CRLP_Operation.RollupType.SUM, 'Amount') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('String Field', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToAcct,
                        'BillingState', CRLP_Operation.RollupType.AVERAGE, 'Amount') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Date Field', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToAcct,
                        'npo02__FirstCloseDate__c', CRLP_Operation.RollupType.AVERAGE, 'Amount') + ',' +

                CMT_UnitTestData_TEST.createRollupRecord('Id Field', filterGroupId1,
                        CMT_UnitTestData_TEST.RollupRecordType.OppToAcct,
                        'ParentId', CRLP_Operation.RollupType.AVERAGE, 'Amount') +

                ']';

        // Deserialize the rollups to use for testing
        CRLP_Rollup_SEL.cachedRollups = (List<Rollup__mdt>) JSON.deserialize(rollupsJSON, List<Rollup__mdt>.class);

        // Create two test Account records
        Account a1 = new Account(Name = 'UNITTEST-123');
        insert a1;
        Account a2 = new Account(Name = 'UNITTEST-456');
        insert a2;
        Id a1Id = a1.Id, a2Id = a2.Id;

        Test.startTest();

        // Requery these with the needed fields
        String acctQuery = CRLP_Query_SEL.buildObjectQueryForRollup(Account.SObjectType);
        a1 = database.query(acctQuery + ' WHERE Id = :a1Id LIMIT 1');
        a2 = database.query(acctQuery + ' WHERE Id = :a2Id LIMIT 1');

        system.assertEquals(false, CRLP_Rollup_TDTM.isRollupRecalcNeeded(a1, a2), 'Objects should be identical');

        // Change fields on one of the object instances and validate that the method detects the changed field
        a1.npo02__TotalOppAmount__c = 1000;
        system.assertEquals(true, CRLP_Rollup_TDTM.isRollupRecalcNeeded(a1, a2), 'Number Field Value Changed!');
        a1.npo02__TotalOppAmount__c = a2.npo02__TotalOppAmount__c;

        a1.npo02__FirstCloseDate__c = Date.today();
        system.assertEquals(true, CRLP_Rollup_TDTM.isRollupRecalcNeeded(a1, a2), 'Date Field Value Changed!');
        a1.npo02__FirstCloseDate__c = a2.npo02__FirstCloseDate__c;

        a1.BillingState = 'NJ';
        system.assertEquals(true, CRLP_Rollup_TDTM.isRollupRecalcNeeded(a1, a2), 'String Field Value Changed!');
        a1.BillingState = a2.BillingState;

        a1.ParentId = a2.Id;
        system.assertEquals(true, CRLP_Rollup_TDTM.isRollupRecalcNeeded(a1, a2), 'Id Field Value Changed!');
        a1.ParentId = a2.ParentId;

        // Change fields that are not referenced by the rollups to ensure that these aren't recognized as requiring a recalc
        a1.Description = 'This is field that doesn\'t matter';
        a2.Description = 'This field should be ignored';
        system.assertEquals(false, CRLP_Rollup_TDTM.isRollupRecalcNeeded(a1, a2), 'Objects should be identical again');
    }
}