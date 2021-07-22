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
/**
* @description Test methods for the AN_AutoNumberService class.  Currently this class
* uses the DataImportBatch__c object and the Batch_Number__c field for testing.
*/
@IsTest
private class AN_AutoNumberService_TEST {

    static SObjectType sObjType = DataImportBatch__c.SObjectType;
    static SObjectField autoNumberField = DataImportBatch__c.Batch_Number__c;

    static String sObjTypeName {
        get {
            return String.valueOf(sObjType);
        }
    }
    static String autoNumberFieldName {
        get {
            return String.valueOf(autoNumberField);
        }
    }

    static AN_AutoNumberService ans =
            new AN_AutoNumberService(sObjType);
    static AN_AutoNumberService.TestUtility utility =
            new AN_AutoNumberService.TestUtility(sObjType, autoNumberField);

    @IsTest
    static void shouldSave() {
        ans.save(utility.autoNumberJSON);

        List<AutoNumber__c> autoNumbers = ans.getAutoNumbers(sObjType);
        System.assert(!autoNumbers.isEmpty(),
                'The AutoNumber should have been inserted.');
    }

    @IsTest
    static void shouldActivate() {
        Id autoNumberIdToActivate =
                utility.setupAutoNumber(false,
                        'ABCZZZ-{000}', 100, false);
        Id activeAutoNumberId = utility.setupAutoNumber(true,
                'INITIAL-ACTIVE-{000}', 0, false);

        System.assertEquals(false,
                utility.getAutoNumberById(
                        autoNumberIdToActivate).IsActive__c);
        System.assertEquals(true,
                utility.getAutoNumberById(
                        activeAutoNumberId).IsActive__c);

        System.assertEquals(false, ans.isTriggerHandlerEnabled,
                'The Trigger Handler table should not have an entry for AN_AutoNumber_TDTM if' +
                        'no AutoNumbers have been activated.');

        ans.activate(autoNumberIdToActivate);

        System.assertEquals(true,
                utility.getAutoNumberById(
                        autoNumberIdToActivate).IsActive__c,
                'The AutoNumber record should be active.');
        System.assertEquals(false,
                utility.getAutoNumberById(
                        activeAutoNumberId).IsActive__c,
                'The initially active AutoNumber record should now be inactive.');
        System.assertEquals(true, ans.isTriggerHandlerEnabled,
                'Activating an Auto Number should create an entry for ' +
                        'the AN_AutoNumber_TDTM class in the Trigger Handler table.');
    }

    @IsTest
    static void shouldDeactivate() {
        Id autoNumberId =
                utility.setupAutoNumber(true,
                        'ABCZZZ-{000}', 100,
                        false);

        System.assertEquals(true,
                utility.getAutoNumberById(autoNumberId).IsActive__c);

        ans.deactivate(autoNumberId);

        System.assertEquals(false,
                utility.getAutoNumberById(autoNumberId).IsActive__c,
                'The AutoNumber record should be inactive.');
    }

    @IsTest
    static void shouldApply() {
        utility.setupAutoNumber(true,
                'ABCZZZ-{000}', 100, true);

        SObject sobj = getSObjectInstance();
        insert sobj;

        sobj = utility.getSObjectsById(new List<Id>{
                sobj.Id
        })[0];

        System.assertNotEquals(null, sobj.get(autoNumberFieldName),
                'The SObject should have an AutoNumber applied.');
    }

    @IsTest
    static void shouldAllowStartingNumberZero() {
        utility.setupAutoNumber(true,
                'ABCZZZ-{000}', 0, true);

        SObject sobj = getSObjectInstance();
        insert sobj;

        sobj = utility.getSObjectsById(new List<Id>{
                sobj.Id
        })[0];

        System.assertNotEquals(null, sobj.get(autoNumberFieldName),
                'The SObject should have an AutoNumber applied.');
        System.assertEquals('ABCZZZ-000', sobj.get(autoNumberFieldName),
                'The starting number 0 should be used for the first record.');
    }

    @IsTest
    static void shouldIncrementStartingNumberZeroCorrectly() {
        Id autoNumberId = utility.setupAutoNumber(true,
                'ABCZZZ-{000}', 0, true);

        SObject sobj = getSObjectInstance();
        insert sobj;

        sobj = utility.getSObjectsById(new List<Id>{
                sobj.Id
        })[0];

        System.assertNotEquals(null, sobj.get(autoNumberFieldName),
                'The SObject should have an AutoNumber applied.');
        System.assertEquals('ABCZZZ-000', sobj.get(autoNumberFieldName),
                'The starting number 0 should be used for the first record.');
        System.assertEquals(0, utility.getAutoNumberById(autoNumberId).Max_Used_Number__c,
                'Max Used Number should be 0 after the first record is inserted when ' +
                        'the Starting Number was 0.');

        SObject sobj1 = getSObjectInstance();
        insert sobj1;

        sobj1 = utility.getSObjectsById(new List<Id>{
                sobj1.Id
        })[0];

        System.assertNotEquals(null, sobj1.get(autoNumberFieldName),
                'The SObject should have an AutoNumber applied.');
        System.assertEquals('ABCZZZ-001', sobj1.get(autoNumberFieldName),
                'The number 1 should be used for the next record.');
        System.assertEquals(1, utility.getAutoNumberById(autoNumberId).Max_Used_Number__c,
                'Max Used Number should be 1 after the second record is inserted when ' +
                        'the Starting Number was 0.');
    }

    /**
     * @description Verifies that the AutoNumberService writes a value into the
     * target field even if the running User does not have access to the target field.
     * For consistent setup, this test explicitly uses the Batch Number field on the
     * DataImportBatch object, which is inaccessible to the Standard User by default (before
     * provisioning access via org permissions).
     */
    @IsTest
    static void shouldApplyWithoutFieldAccess() {
        utility.setupAutoNumber(true,
                'ABCZZZ-{000}', 100, true);

        System.runAs(UTIL_UnitTestData_TEST.createUser(UTIL_Profile.PROFILE_STANDARD_USER)) {
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
                LIMIT 1
        ].Batch_Number__c,
                'The Batch should have a Batch Number applied. AutoNumbers should' +
                        'be written to the target field regardless of the running' +
                        'Users field-level access.');
    }

    @IsTest
    static void shouldApplyInBulk() {
        Integer startingNumber = 100;
        Id anId = utility.setupAutoNumber(true,
                'ABCZZZ-{000}', startingNumber, true);

        SObject sobj1 = getSObjectInstance();
        SObject sobj2 = getSObjectInstance();
        SObject sobj3 = getSObjectInstance();
        List<SObject> sObjects = new List<SObject>{
                sobj1, sobj2, sobj3
        };
        insert sObjects;

        Set<String> batchNumbers = new Set<String>();
        for (SObject sobj : utility.getSObjectsById(new List<Id>{
                sobj1.Id, sobj2.Id, sobj3.Id
        })) {
            batchNumbers.add(String.valueOf(sobj.get(autoNumberFieldName)));
        }

        List<Integer> numbersInSequence = new List<Integer>();
        for (Integer i = 0; i < sObjects.size(); i++) {
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
                    'Auto Numbers should be incremented by 1 from the Starting Number and' +
                            'use each number in the sequence without skipping any.');
        }

        Integer maxUsedNumber = numbersInSequence.get(numbersInSequence.size() - 1);
        System.assertEquals(maxUsedNumber,
                utility.getAutoNumberById(anId).Max_Used_Number__c,
                'The Auto Number record should be updated with the ' +
                        'Max Used Number after processing.');
    }

    @IsTest
    static void shouldPreventDuplicatePrefix() {
        ans.save(utility.autoNumberJSON);
        try {
            ans.save(utility.autoNumberJSON);
        } catch (AN_AutoNumberService.AutoNumberException ane) {
            System.assertNotEquals(null, ane,
                    'An exception should be thrown when attempting to insert a ' +
                            'duplicate Auto Number record.');
        }
    }

    @IsTest
    static void shouldPreventInvalidPattern() {
        try {
            utility.setupAutoNumber(true,
                    'ABCZZZ-000}', 100, false);
        } catch (AN_AutoNumberService.AutoNumberException ane) {
            System.assertNotEquals(null, ane,
                    'An exception should be thrown if the Display Format is invalid.');
        }
    }

    @IsTest
    static void shouldUseStartingNumber() {
        Integer startingNumber = 9877;
        utility.setupAutoNumber(true,
                'ABCZZZ-{000}', startingNumber, true);

        SObject sobj = getSObjectInstance();
        insert sobj;

        sobj = utility.getSObjectsById(new List<Id>{
                sobj.Id
        })[0];

        System.assert(String.valueOf(sobj.get(String.valueOf(autoNumberField)))
                .contains(String.valueOf(startingNumber)),
                'The Batch should have used the Starting Number from the active Auto ' +
                        'Number record.');
    }

    @IsTest
    static void shouldBeInvalidPatternBracesOnly() {
        String invalidDisplayFormatBracesOnly = '{}';

        JSONGenerator gen = JSON.createGenerator(false);
        gen.writeStartObject();
        gen.writeFieldName('fields');
        gen.writeStartObject();
        gen.writeStringField(
                String.valueOf(AutoNumber__c.Display_Format__c),
                invalidDisplayFormatBracesOnly);
        gen.writeEndObject();
        gen.writeEndObject();

        AN_AutoNumberService.AutoNumberException autoNumberException;
        try {
            AN_AutoNumberService.AutoNumber autoNumber = new AN_AutoNumberService.AutoNumber(
                    gen.getAsString(), new AN_AutoNumberService(sObjType)
            );
        } catch (AN_AutoNumberService.AutoNumberException ane) {
            autoNumberException = ane;
        }

        System.assertNotEquals(null, autoNumberException,
                'A valid display format should include at least one "0" in between the braces.');
    }

    @IsTest
    static void shouldBeInvalidPatternBlankDisplayFormat() {
        String invalidDisplayFormatBlank = '';

        JSONGenerator gen = JSON.createGenerator(false);
        gen.writeStartObject();
        gen.writeFieldName('fields');
        gen.writeStartObject();
        gen.writeStringField(
                String.valueOf(AutoNumber__c.Display_Format__c),
                invalidDisplayFormatBlank);
        gen.writeEndObject();
        gen.writeEndObject();

        AN_AutoNumberService.AutoNumberException autoNumberException;
        try {
            AN_AutoNumberService.AutoNumber autoNumber = new AN_AutoNumberService.AutoNumber(
                    gen.getAsString(), new AN_AutoNumberService(sObjType)
            );
        } catch (AN_AutoNumberService.AutoNumberException ane) {
            autoNumberException = ane;
        }

        System.assertNotEquals(null, autoNumberException,
                'A valid display format is required when creating an AutoNumber record.');
    }

    /**
     * @description Utility method used to instantiate a new instance of the SObject under
     * test.  If an SObject has required fields, they can be assigned here to use those
     * field values for all records created in the test methods in this class.
     */
    static SObject getSObjectInstance() {
        SObject sobj;
        sobj = (SObject) Type.forName(sObjTypeName).newInstance();
        sobj.put('Name', 'testSObjectRecord');
        return sobj;
    }

}