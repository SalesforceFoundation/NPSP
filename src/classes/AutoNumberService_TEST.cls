/*
    Copyright (c) 2020 Salesforce.org
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
private class AutoNumberService_TEST {

    @IsTest
    static void shouldSave() {
        AutoNumberService ans = new AutoNumberService(DataImportBatch__c.SObjectType);
        ans.save(AutoNumberService_TEST_Helper.autoNumberJSON);

        List<AutoNumber__c> autoNumbers = ans.getAutoNumbers(DataImportBatch__c.SObjectType);
        System.assert(!autoNumbers.isEmpty(),
                'The AutoNumber should have been inserted.');
    }

    @IsTest
    static void shouldActivate() {
        Id autoNumberIdToActivate =
                AutoNumberService_TEST_Helper.setupAutoNumber(false,
                        'ABCZZZ-{000}', 100, false);
        Id activeAutoNumberId = AutoNumberService_TEST_Helper.setupAutoNumber(true,
                'INITIAL-ACTIVE-{000}', 0, false);

        System.assertEquals(false,
                AutoNumberService_TEST_Helper.getAutoNumberById(
                        autoNumberIdToActivate).IsActive__c);
        System.assertEquals(true,
                AutoNumberService_TEST_Helper.getAutoNumberById(
                        activeAutoNumberId).IsActive__c);

        AutoNumberService ans = new AutoNumberService(DataImportBatch__c.SObjectType);
        System.assertEquals(false, ans.isTriggerHandlerEnabled,
                'The Trigger Handler table should not have an entry for AutoNumber_TDTM if' +
                        'no AutoNumbers have been activated.');
        ans.activate(autoNumberIdToActivate);

        System.assertEquals(true,
                AutoNumberService_TEST_Helper.getAutoNumberById(
                        autoNumberIdToActivate).IsActive__c,
                'The AutoNumber record should be active.');
        System.assertEquals(false,
                AutoNumberService_TEST_Helper.getAutoNumberById(
                        activeAutoNumberId).IsActive__c,
                'The initially active AutoNumber record should now be inactive.');
        System.assertEquals(true, ans.isTriggerHandlerEnabled,
                'Activating an Auto Number should create an entry for ' +
                        'the AutoNumber_TDTM class in the Trigger Handler table.');
    }

    @IsTest
    static void shouldDeactivate() {
        Id autoNumberId =
                AutoNumberService_TEST_Helper.setupAutoNumber(true,
                        'ABCZZZ-{000}', 100,
                        false);

        System.assertEquals(true,
                AutoNumberService_TEST_Helper.getAutoNumberById(autoNumberId).IsActive__c);

        AutoNumberService ans = new AutoNumberService(DataImportBatch__c.SObjectType);
        ans.deactivate(autoNumberId);

        System.assertEquals(false,
                AutoNumberService_TEST_Helper.getAutoNumberById(autoNumberId).IsActive__c,
                'The AutoNumber record should be inactive.');
    }

    @IsTest
    static void shouldApply() {
        AutoNumberService_TEST_Helper.setupAutoNumber(true,
                'ABCZZZ-{000}', 100, true);

        DataImportBatch__c b = new DataImportBatch__c();
        insert b;

        b = [SELECT Batch_Number__c FROM DataImportBatch__c WHERE Id = :b.Id];
        System.assertNotEquals(null, b.Batch_Number__c,
                'The Batch should have a Batch Number applied.');
    }

    @IsTest
    static void shouldApplyWithoutFieldAccess() {
        AutoNumberService_TEST_Helper.setupAutoNumber(true,
                'ABCZZZ-{000}', 100, true);

        System.runAs(UTIL_UnitTestData_TEST.createUser('Standard User')) {
            System.assertEquals(false, Schema.SObjectType.DataImportBatch__c.fields
                    .Batch_Number__c.isAccessible(),
                    'This Standard User created for the test should not have read access ' +
                            'to the Batch Number field.');
            System.assertEquals(false, Schema.SObjectType.DataImportBatch__c.fields
                    .Batch_Number__c.isUpdateable(),
                    'This Standard User created for the test should not have edit access ' +
                            'to the Batch Number field.');
            insert new DataImportBatch__c();
        }

        System.assertNotEquals(null, [
                SELECT Batch_Number__c
                FROM DataImportBatch__c
                LIMIT
                        1
        ].Batch_Number__c,
                'The Batch should have a Batch Number applied. AutoNumbers should' +
                        'be written to the target field regardless of the running' +
                        'Users field-level access.');
    }

    @IsTest
    static void shouldApplyInBulk() {
        Integer startingNumber = 100;
        Id anId = AutoNumberService_TEST_Helper.setupAutoNumber(true,
                'ABCZZZ-{000}', startingNumber, true);

        DataImportBatch__c b = new DataImportBatch__c();
        DataImportBatch__c b1 = new DataImportBatch__c();
        DataImportBatch__c b2 = new DataImportBatch__c();
        List<DataImportBatch__c> batches = new List<DataImportBatch__c>{
                b, b1, b2
        };
        insert batches;

        Set<String> batchNumbers = new Set<String>();
        for (DataImportBatch__c dataImportBatch : [
                SELECT Batch_Number__c
                FROM DataImportBatch__c
        ]) {
            batchNumbers.add(dataImportBatch.Batch_Number__c);
        }

        List<Integer> numbersInSequence = new List<Integer>();
        for (Integer i = 0; i < batches.size(); i++) {
            numbersInSequence.add(startingNumber + i);
        }

        for (Integer i : numbersInSequence) {
            Boolean isUsed = false;
            for (String batchNumber : batchNumbers) {
                if (batchNumber.contains(String.valueOf(i))) {
                    isUsed = true;
                }
            }
            System.assert(isUsed,
                    'Batch Numbers should be incremented by 1 from the Starting Number and' +
                            'use each number in the sequence without skipping any.');
        }

        Integer maxUsedNumber = numbersInSequence.get(numbersInSequence.size() - 1);
        System.assertEquals(maxUsedNumber,
                AutoNumberService_TEST_Helper.getAutoNumberById(anId).Max_Used_Number__c,
                'The Auto Number record should be updated with the ' +
                        'Max Used Number after processing.');
    }

    @IsTest
    static void shouldPreventDuplicatePrefix() {
        AutoNumberService ans = new AutoNumberService(DataImportBatch__c.SObjectType);
        ans.save(AutoNumberService_TEST_Helper.autoNumberJSON);
        try {
            ans.save(AutoNumberService_TEST_Helper.autoNumberJSON);
        } catch (AutoNumberService.AutoNumberException ane) {
            System.assertNotEquals(null, ane,
                    'An exception should be thrown when attempting to insert a ' +
                            'duplicate Auto Number record.');
        }
    }

    @IsTest
    static void shouldPreventInvalidPattern() {
        try {
            AutoNumberService_TEST_Helper.setupAutoNumber(true,
                    'ABCZZZ-000}', 100, false);
        } catch (AutoNumberService.AutoNumberException ane) {
            System.assertNotEquals(null, ane,
                    'An exception should be thrown if the Display Format is invalid.');
        }
    }

    @IsTest
    static void shouldUseStartingNumber() {
        Integer startingNumber = 9877;
        AutoNumberService_TEST_Helper.setupAutoNumber(true,
                'ABCZZZ-{000}', startingNumber, true);

        DataImportBatch__c b = new DataImportBatch__c();
        insert b;

        b = [SELECT Batch_Number__c FROM DataImportBatch__c WHERE Id = :b.Id];
        System.assert(b.Batch_Number__c.contains(String.valueOf(startingNumber)),
                'The Batch should have used the Starting Number from the active Auto ' +
                        'Number record.');
    }

}