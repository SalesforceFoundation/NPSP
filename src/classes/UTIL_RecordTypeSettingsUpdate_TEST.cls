/*
    Copyright (c) 2016, Salesforce.org
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
* @group Utilities
* @description Tests for UTIL_RecordTypeSettingsUpdate
*/
@isTest
public class UTIL_RecordTypeSettingsUpdate_TEST {

    /*******************************************************************************************************
    * @description An exception class used in UTIL_RecordTypeSettingsUpdate Mock class
    */
    private class RecordTypeSettingsUpdateException extends Exception {}

    /*******************************************************************************************************
    * @description An 18 char mock Id 
    */
    private static Id MOCK_ID_18CHAR = '012410000000RXlAAM';

    /*********************************************************************************************************
    * @description A 15 char mock Id 
    */
    private static Id MOCK_ID_15CHAR = '01241000000N0kX';

    /*********************************************************************************************************
    @description 
        Tests null Record Type name mapping to an Id 
    verify:
        Null Id should be returned    
    **********************************************************************************************************/ 
    @isTest
    private static void testNullSettingsRemainNull() {
        Test.startTest();

        UTIL_RecordTypeSettingsUpdate rtUpdate = new UTIL_RecordTypeSettingsUpdate();
        String ids = rtUpdate.getIdsFromNames(
            null,
            new Map<String, Id>()
        );

        Test.stopTest();

        System.assertEquals(null, ids, 'The null name value should be returned as null');
    }

    /*********************************************************************************************************
    @description 
        Tests blank Record Type name mapping to an Id 
    verify:
        Blank Id should be returned    
    **********************************************************************************************************/ 
    @isTest
    public static void testBlankSettingsRemainBlank() {
        Test.startTest();

        UTIL_RecordTypeSettingsUpdate rtUpdate = new UTIL_RecordTypeSettingsUpdate();
        String ids = rtUpdate.getIdsFromNames(
            '',
            new Map<String, Id>()
        );

        Test.stopTest();

        System.assertEquals('', ids, 'The blank name value should be returned as is');
    }

    /*********************************************************************************************************
    @description 
        Tests empty Record Type names mapping to an Id 
    verify:
        Empty Record Type names are discarded    
    **********************************************************************************************************/ 
    @isTest
    public static void testEmptyValuesAreDiscarded() {
        Test.startTest();

        UTIL_RecordTypeSettingsUpdate rtUpdate = new UTIL_RecordTypeSettingsUpdate();
        String ids = rtUpdate.getIdsFromNames(
            ';;   ;;   ; ',
            new Map<String, Id>()
        );

        Test.stopTest();

        System.assertEquals('', ids, 'After detokenizing, empty values should be discarded');
    }

    /*********************************************************************************************************
    @description 
        Tests unknown Record Type name mapping to an Id 
    verify:
        Unknown Record Type name is discarded
    **********************************************************************************************************/ 
    @isTest
    public static void testUnknownRecordTypeNamesAreDiscarded() {
        Test.startTest();

        UTIL_RecordTypeSettingsUpdate rtUpdate = new UTIL_RecordTypeSettingsUpdate();
        String ids = rtUpdate.getIdsFromNames(
            'UnknownRecordTypeName',
            new Map<String, Id>()
        );

        Test.stopTest();

        System.assertEquals('', ids, 'Unknown Record Type names should be discarded');
    }

    /*********************************************************************************************************
    @description 
        Tests Id Record Type name mapping to an Id 
    verify:
        Ids are returned as they are
    **********************************************************************************************************/ 
    @isTest
    public static void testIdsRemainIds() {
        Test.startTest();

        String names = MOCK_ID_18CHAR + ';' + MOCK_ID_15CHAR;

        UTIL_RecordTypeSettingsUpdate rtUpdate = new UTIL_RecordTypeSettingsUpdate();
        String ids = rtUpdate.getIdsFromNames(
            names,
            new Map<String, Id>()
        );

        Test.stopTest();

        System.assertEquals(names, ids, 'Valid Ids in the name should be returned as is regardless if they exist');
    }

    /*********************************************************************************************************
    @description 
        Tests known Record Type name mapping to an Id 
    verify:
        Known Record Type name is converted to an Id
    **********************************************************************************************************/ 
    @isTest
    public static void testKnownRecordTypeNamesAreConverted() {
        Id knownRecordTypeId = '012000000000001';
        String name = 'KnownRecordTypeName';

        Test.startTest();

        UTIL_RecordTypeSettingsUpdate rtUpdate = new UTIL_RecordTypeSettingsUpdate();
        String ids = rtUpdate.getIdsFromNames(
            name,
            new Map<String, Id>{
                name.toLowerCase() => knownRecordTypeId
            }
        );

        Test.stopTest();

        System.assertEquals(knownRecordTypeId, ids, 'The known record type Id should be returned');
    }

    /*********************************************************************************************************
    @description 
        Tests known Record Type name mapping to an Id 
    verify:
        Known Record Type names are converted to Ids. 
        Unknown Record Type names are discarded.
        Empty values are discarded.
    **********************************************************************************************************/ 
    @isTest
    public static void testKitchenSink() {
        Map<String, Id> rtIdsByLowerCaseName = new Map<String, Id>{
            'validname1' => '012000000000001',
            'validname2' => '012000000000002'
        };
        String names = String.format(
            ';{0}; ;UnknownRecordTypeName;{1};{2};{3};   ;',
            new String[] { 'validName1', 'validName2', MOCK_ID_18CHAR, MOCK_ID_15CHAR }
        );

        Test.startTest();

        UTIL_RecordTypeSettingsUpdate rtUpdate = new UTIL_RecordTypeSettingsUpdate();
        String ids = rtUpdate.getIdsFromNames(names, rtIdsByLowerCaseName);

        Test.stopTest();

        String expectedRecordTypeIds = String.join(
            new List<String>{ rtIdsByLowerCaseName.get('validname1'), rtIdsByLowerCaseName.get('validname2'), MOCK_ID_18CHAR, MOCK_ID_15CHAR },
            ';'
        );

        System.assertEquals(expectedRecordTypeIds, ids, 'Testing multiple conditions should create expected result');
    }

    /*********************************************************************************************************
    @description 
        Tests case insensitive Record Type names mapping to Ids
    verify:
        Record Type names are converted to Ids. 
    **********************************************************************************************************/
    @isTest
    private static void testRecordTypeNamesAreCaseInsensitive() {
        Map<String, Id> rtIdsByLowerCaseName = new Map<String, Id>{
            'validname1' => '012000000000001',
            'validname2' => '012000000000002'
        };

        String names = String.format(
            '{0};randomName;{1};;{2};{3};',
            new String[] { 'validNAME1', 'VaLiDName2', MOCK_ID_18CHAR, MOCK_ID_15CHAR }
        );

        UTIL_RecordTypeSettingsUpdate rtUpdate = new UTIL_RecordTypeSettingsUpdate();
        String ids = rtUpdate.getIdsFromNames(names, rtIdsByLowerCaseName);

        String expectedRecordTypeIds = String.join(
            new List<String>{ rtIdsByLowerCaseName.get('validname1'), rtIdsByLowerCaseName.get('validname2'), MOCK_ID_18CHAR, MOCK_ID_15CHAR },
            ';'
        );

        System.assertEquals(expectedRecordTypeIds, ids, 'Record Type names should be case insensitive');
    }

    /*********************************************************************************************************
    @description 
        Tests case insensitive Record Type name mapping to an Id 
    verify:
        Record Type name is converted to an Id 
    **********************************************************************************************************/
    @isTest
    private static void testRecordTypeNameIsCaseInsensitive() {
        Map<String, Id> rtIdsByLowerCaseName = new Map<String, Id>{
            'validname1' => '012000000000001',
            'validname2' => '012000000000002'
        };

        String name = 'validNAME1';

        UTIL_RecordTypeSettingsUpdate rtUpdate = new UTIL_RecordTypeSettingsUpdate();
        String rtId = rtUpdate.getIdFromName(name, rtIdsByLowerCaseName);

        String expectedRecordTypeId = rtIdsByLowerCaseName.get('validname1');

        System.assertEquals(expectedRecordTypeId, rtId, 'Record Type name should be case insensitive');
    }

    /*********************************************************************************************************
    @description 
        Tests Record Type name mapping to an Id when only one name is expected
    verify:
        Record Type names are discarded since they (combined) do not map to a valid Record Type name.
    **********************************************************************************************************/
    @isTest
    private static void testValidRecordTypeNamesAreDiscardedIfOneRecordTypeNameIsExpected() {
        Map<String, Id> rtIdsByLowerCaseName = new Map<String, Id>{
            'validname1' => '012000000000001',
            'validname2' => '012000000000002'
        };

        String name = 'validName1;validName2';

        UTIL_RecordTypeSettingsUpdate rtUpdate = new UTIL_RecordTypeSettingsUpdate();
        String rtId = rtUpdate.getIdFromName(name, rtIdsByLowerCaseName);

        String expectedRecordTypeId = '';

        System.assertEquals(expectedRecordTypeId, rtId, 'Record Type names should be discarded when one Record Type name is expected');
    }

    /**
     * @description A stub class to provide known record type name to record
     * type id mappings
     */
    private class NameMappingStub extends UTIL_RecordTypeSettingsUpdate {
        public Map<String, Id> opportunityNameMap;
        public Map<String, Id> contactNameMap;
        public Map<String, Id> accountNameMap;

        private Map<String, Id> getNameToRecordTypeIdMap(Schema.SObjectType sot) {
            if (sot == Contact.sObjectType) {
                return contactNameMap;
            } else if (sot == Opportunity.sObjectType) {
                return opportunityNameMap;
            } else if (sot == Account.sObjectType) {
                return accountNameMap;
            }
            return null;
        }
    }

    /*********************************************************************************************************
    @description 
        Tests Record Type Settings update
    verify:
        Record Type names are converted to Ids for each applicable Custom Setting.
    **********************************************************************************************************/
    @isTest
    private static void testUpdateSettings() {
        // we insert some settings with fake record type names and then test to
        // see if UTIL_RecordTypeSettingsUpdate correctly reads those settings,
        // converts the fake names to fake ids, and then rewrites the settings.
        // To control for a known set of record types, we will stub the
        // getNameToRecordTypeIdMap() method to return a set of test mappings.

        Allocations_Settings__c allocationsSettings = new Allocations_Settings__c(
            Excluded_Opp_RecTypes__c = 'FakeOppRTName1;FakeOppRTName2'
        );

        npe01__Contacts_And_Orgs_Settings__c contactsAndOrgsSettings = new npe01__Contacts_And_Orgs_Settings__c(
            Opp_RecTypes_Excluded_for_Payments__c = 'FakeOppRTName1;FakeOppRTName2',
            npe01__HH_Account_RecordTypeID__c = 'FakeAccRTName1',
            npe01__One_to_One_RecordTypeID__c = 'FakeAccRTName2'
        );

        npo02__Households_Settings__c householdsSettings = new npo02__Households_Settings__c(
            npo02__Household_Creation_Excluded_Recordtypes__c = 'FakeConRTName1;FakeConRTName2',
            npo02__Household_OCR_Excluded_Recordtypes__c = 'FakeConRTName1;FakeConRTName2',
            npo02__Membership_Record_Types__c = 'FakeOppRTName1;FakeOppRTName2',
            npo02__Excluded_Account_Opp_Rectypes__c = 'FakeOppRTName1;FakeOppRTName2',
            npo02__Excluded_Contact_Opp_Rectypes__c = 'FakeOppRTName1;FakeOppRTName2'
        );

        Opportunity_Naming_Settings__c opportunityNamingSettings = new Opportunity_Naming_Settings__c(
            Name = 'ons1',
            Opportunity_Record_Types__c = 'FakeOppRTName1;FakeOppRTName2'
        );

        npe03__Recurring_Donations_Settings__c rdSettings = new npe03__Recurring_Donations_Settings__c(
            npe03__Record_Type__c = 'FakeOppRTName2'
        );

        insert allocationsSettings;
        insert contactsAndOrgsSettings;
        insert householdsSettings;
        insert opportunityNamingSettings;
        insert rdSettings;

        Id opportunityRecTypeId1 = '012000000000001';
        Id opportunityRecTypeId2 = '012000000000002';
        Id contactRecTypeId1 = '012000000000003';
        Id contactRecTypeId2 = '012000000000004';
        Id accountRecTypeId1 = '012000000000005';
        Id accountRecTypeId2 = '012000000000006';

        NameMappingStub stub = new NameMappingStub();
        stub.opportunityNameMap = new Map<String, Id>{
            'FakeOppRTName1'.toLowerCase() => opportunityRecTypeId1,
            'FakeOppRTName2'.toLowerCase() => opportunityRecTypeId2
        };
        stub.contactNameMap = new Map<String, Id>{
            'FakeConRTName1'.toLowerCase() => contactRecTypeId1,
            'FakeConRTName2'.toLowerCase() => contactRecTypeId2
        };

        stub.accountNameMap = new Map<String, Id>{
            'FakeAccRTName1'.toLowerCase() => accountRecTypeId1,
            'FakeAccRTName2'.toLowerCase() => accountRecTypeId2
        };

        String expectedOpportunityIdString = String.join(new List<String>{opportunityRecTypeId1, opportunityRecTypeId2}, ';');
        String expectedContactIdString = String.join(new List<String>{contactRecTypeId1, contactRecTypeId2}, ';');

        Test.startTest();

        stub.updateSettings();

        Test.stopTest();

        Allocations_Settings__c allocationsSettingsActual = [
            SELECT Excluded_Opp_RecTypes__c
            FROM Allocations_Settings__c
            WHERE Id = :allocationsSettings.Id
        ];

        npe01__Contacts_And_Orgs_Settings__c contactsAndOrgsSettingsActual = [
            SELECT Opp_RecTypes_Excluded_for_Payments__c,
                npe01__HH_Account_RecordTypeID__c,
                npe01__One_to_One_RecordTypeID__c
            FROM npe01__Contacts_And_Orgs_Settings__c
            WHERE Id = :contactsAndOrgsSettings.Id
        ];

        npo02__Households_Settings__c householdsSettingsActual = [
            SELECT
                npo02__Household_Creation_Excluded_Recordtypes__c,
                npo02__Household_OCR_Excluded_Recordtypes__c,
                npo02__Membership_Record_Types__c,
                npo02__Excluded_Account_Opp_Rectypes__c,
                npo02__Excluded_Contact_Opp_Rectypes__c
            FROM npo02__Households_Settings__c
            WHERE Id = :householdsSettings.Id
        ];

        Opportunity_Naming_Settings__c opportunityNamingSettingsActual = [
            SELECT Opportunity_Record_Types__c
            FROM Opportunity_Naming_Settings__c
            WHERE Id = :opportunityNamingSettings.Id
        ];

        npe03__Recurring_Donations_Settings__c rdSettingsActual = [
            SELECT npe03__Record_Type__c
            FROM npe03__Recurring_Donations_Settings__c
            WHERE Id = :rdSettings.Id
        ];

        System.assertEquals(
            expectedOpportunityIdString,
            allocationsSettingsActual.Excluded_Opp_RecTypes__c
        );

        System.assertEquals(
            expectedOpportunityIdString,
            contactsAndOrgsSettingsActual.Opp_RecTypes_Excluded_for_Payments__c
        );

        System.assertEquals(
            accountRecTypeId1,
            contactsAndOrgsSettingsActual.npe01__HH_Account_RecordTypeID__c
        );

        System.assertEquals(
            accountRecTypeId2,
            contactsAndOrgsSettingsActual.npe01__One_to_One_RecordTypeID__c
        );

        System.assertEquals(
            expectedContactIdString,
            householdsSettingsActual.npo02__Household_Creation_Excluded_Recordtypes__c
        );

        System.assertEquals(
            expectedContactIdString,
            householdsSettingsActual.npo02__Household_OCR_Excluded_Recordtypes__c
        );

        System.assertEquals(
            expectedOpportunityIdString,
            householdsSettingsActual.npo02__Membership_Record_Types__c
        );

        System.assertEquals(
            expectedOpportunityIdString,
            householdsSettingsActual.npo02__Excluded_Account_Opp_Rectypes__c
        );

        System.assertEquals(
            expectedOpportunityIdString,
            householdsSettingsActual.npo02__Excluded_Contact_Opp_Rectypes__c
        );

        System.assertEquals(
            expectedOpportunityIdString,
            opportunityNamingSettingsActual.Opportunity_Record_Types__c
        );

        System.assertEquals(
            opportunityRecTypeId2,
            rdSettingsActual.npe03__Record_Type__c
        );
    }

    private static void testUpdateSettingsHandlesNoSettings() {
        // no settings in database, verify updateSettings() properly runs
        UTIL_RecordTypeSettingsUpdate.getInstance().updateSettings();
    }

    /**
     * @description Stub class to verify how many times updateSettings() method
     * is called
     */
    private class UpdateSettingsRunCount extends UTIL_RecordTypeSettingsUpdate {
        public Integer runCount = 0;
        public override void updateSettings() {
            runCount++;
        }
    }

    @isTest
    public static void testUpdateRunsOnUpgradeFrom377() {
        // when upgrading from v3.78, the updateSettings() method should be
        // called exactly once
        UpdateSettingsRunCount stub = new UpdateSettingsRunCount();
        UTIL_RecordTypeSettingsUpdate.instance = stub;

        Test.startTest();

        Test.testInstall(new STG_InstallScript(), new Version(3, 78));

        Test.stopTest();

        System.assertEquals(1, stub.runCount);
    }

    @isTest
    public static void testUpdateRunsOnUpgradeFrom354() {
        // when upgrading from v3.54, the updateSettings() method should be
        // called exactly once (this is to verify that if upgrading from a
        // version prior to 3.79 the update will run)
        UpdateSettingsRunCount stub = new UpdateSettingsRunCount();
        UTIL_RecordTypeSettingsUpdate.instance = stub;

        Test.startTest();

        Test.testInstall(new STG_InstallScript(), new Version(3, 54));

        Test.stopTest();

        System.assertEquals(1, stub.runCount);
    }

    @isTest
    public static void testUpdateRunsOnNewInstall() {
        // when new install, updateSettings() should be called, since this
        // will handle cases where users are updating from NPSP 2.0, and
        // otherwise be a noop.
        UpdateSettingsRunCount stub = new UpdateSettingsRunCount();
        UTIL_RecordTypeSettingsUpdate.instance = stub;

        Test.startTest();

        Test.testInstall(new STG_InstallScript(), null);

        Test.stopTest();

        System.assertEquals(1, stub.runCount);
    }

    @isTest
    public static void testUpdateDoesNotRunOnUpgradeFrom379() {
        // when upgrading from version 3.79 or later, update should not run
        UpdateSettingsRunCount stub = new UpdateSettingsRunCount();
        UTIL_RecordTypeSettingsUpdate.instance = stub;

        Test.startTest();

        Test.testInstall(new STG_InstallScript(), new Version(3, 79));

        Test.stopTest();

        System.assertEquals(0, stub.runCount);
    }

    @isTest
    public static void testUpdateDoesNotRunOnUpgradeFrom399() {
        // when upgrading from version 3.79 or later, update should not run
        // when new install, updateSettings() should not be called
        UpdateSettingsRunCount stub = new UpdateSettingsRunCount();
        UTIL_RecordTypeSettingsUpdate.instance = stub;

        Test.startTest();

        Test.testInstall(new STG_InstallScript(), new Version(3, 99));

        Test.stopTest();

        System.assertEquals(0, stub.runCount);
    }


    /*******************************************************************************************************
    * @description Mock for the UTIL_RecordTypeSettingsUpdate
    */
    public class UpdateSettingsMock extends UTIL_RecordTypeSettingsUpdate {
        /*******************************************************************************************************
        * @description updateSettings() execution counter
        */
        public Integer runCount = 0;
        /*******************************************************************************************************
        * @description Indicates if an exception should be thrown in updateSettings()
        */
        public Boolean throwException = false;
    
        /*******************************************************************************************************
        * @description Sets throwException to true
        * @return UpdateSettingsMock
        */
        public UpdateSettingsMock throwException() {
            throwException = true;
            return this;
        }

        /*******************************************************************************************************
        * @description Called when UTIL_RecordTypeSettingsUpdate.updateSettings() method is supposed to be called.
        * Updates counter of the method calls. Throws an exception if requested by the test.
        * @return void
        */
        public override void updateSettings() {
            runCount++;

            if (throwException) {
                throw new RecordTypeSettingsUpdateException('Test Exception');
            }
        }
    }

}