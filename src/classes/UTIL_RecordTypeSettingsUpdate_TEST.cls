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
private class UTIL_RecordTypeSettingsUpdate_TEST {
    @isTest
    private static void testNullSettingsRemainNull() {
        // if a setting is null, it should remain null after updating
        Test.startTest();

        UTIL_RecordTypeSettingsUpdate rtsu = new UTIL_RecordTypeSettingsUpdate();
        String ids = rtsu.getIdsFromNames(
            null,
            new Map<String, Id>()
        );

        Test.stopTest();

        System.assertEquals(null, ids);
    }

    @isTest
    public static void testBlankSettingsRemainBlank() {
        // if a setting is blank, it should remain blank after updating
        Test.startTest();

        UTIL_RecordTypeSettingsUpdate rtsu = new UTIL_RecordTypeSettingsUpdate();
        String ids = rtsu.getIdsFromNames(
            '',
            new Map<String, Id>()
        );

        Test.stopTest();

        System.assertEquals('', ids);
    }

    @isTest
    public static void testEmptyValuesAreDiscarded() {
        // After detokenizing, empty values should be discarded
        Test.startTest();

        UTIL_RecordTypeSettingsUpdate rtsu = new UTIL_RecordTypeSettingsUpdate();
        String ids = rtsu.getIdsFromNames(
            ';;   ;;   ; ',
            new Map<String, Id>()
        );

        Test.stopTest();

        System.assertEquals('', ids);
    }

    @isTest
    public static void testUnknownRecordTypeNamesAreDiscarded() {
        // Unknown record type names should be discarded
        Test.startTest();

        UTIL_RecordTypeSettingsUpdate rtsu = new UTIL_RecordTypeSettingsUpdate();
        String ids = rtsu.getIdsFromNames(
            'UnknownRecordTypeName',
            new Map<String, Id>()
        );

        Test.stopTest();

        System.assertEquals('', ids);
    }

    @isTest
    public static void testKnownRecordTypeNamesAreConverted() {
        // Unknown record type names should be discarded
        Id knownRecordTypeId = '012000000000001';

        Test.startTest();

        UTIL_RecordTypeSettingsUpdate rtsu = new UTIL_RecordTypeSettingsUpdate();
        String ids = rtsu.getIdsFromNames(
            'KnownRecordTypeName',
            new Map<String, Id>{
                'KnownRecordTypeName' => knownRecordTypeId
            }
        );

        Test.stopTest();

        System.assertEquals(knownRecordTypeId, ids);
    }

    @isTest
    public static void testKitchenSink() {
        // Combine multiple conditions in one test

        Id knownRecordTypeId1 = '012000000000001';
        Id knownRecordTypeId2 = '012000000000002';
        Test.startTest();

        UTIL_RecordTypeSettingsUpdate rtsu = new UTIL_RecordTypeSettingsUpdate();
        String ids = rtsu.getIdsFromNames(
            ';KnownRecordTypeName1; ;UnknownRecordTypeName;KnownRecordTypeName2;   ;',
            new Map<String, Id>{
                'KnownRecordTypeName1' => knownRecordTypeId1,
                'KnownRecordTypeName2' => knownRecordTypeId2
            }
        );

        Test.stopTest();

        String expectedRecordTypeIds = String.join(
            new List<String>{knownRecordTypeId1, knownRecordTypeId2},
            ';'
        );

        System.assertEquals(expectedRecordTypeIds, ids);
    }

    /**
     * @description A stub class that overrides behavior of getIdsFromNames so
     * that updateSettings can be verified to correctly call this method, and
     * to correctly handle values returned by this method
     */
    private class GetIdsFromNameStub extends UTIL_RecordTypeSettingsUpdate {
        public List<String> nameStrings = new List<String>();
        public List<Map<String, Id>> nameMaps = new List<Map<String, Id>>();
        public List<String> returnNameStrings;
        private override String getIdsFromNames(String names, Map<String, Id> nameMap) {
            nameStrings.add(names);
            nameMaps.add(nameMap);
            return returnNameStrings.remove(0);
        }
    }

    @isTest
    public static void testUpdateSettingsPopulatesSettings() {
        // verify that if we call updateSettings(...), that it properly
        // delegates to getIdsFromNames() and correctly assigns the results

        GetIdsFromNameStub stub = new GetIdsFromNameStub();

        List<String> returnNameStrings = new List<String>{
            'converted allocationsSettings.Excluded_Opp_RecTypes__c',
            'converted contactsAndOrgsSettings.Opp_RecTypes_Excluded_for_Payments__c',
            'converted householdSettings.npo02__Household_Creation_Excluded_Recordtypes__c',
            'converted householdSettings.npo02__Household_OCR_Excluded_Recordtypes__c',
            'converted householdSettings.npo02__Membership_Record_Types__c',
            'converted householdSettings.npo02__Excluded_Account_Opp_Rectypes__c',
            'converted householdSettings.npo02__Excluded_Contact_Opp_Rectypes__c',
            'converted opportunityNamingSettings.Opportunity_Record_Types__c'
        };

        stub.returnNameStrings = returnNameStrings.clone();

        // as getIdsFromName() gets called, these are the values for the
        // parameter `names` we expect to receive in this order:
        List<String> expectedNameStrings = new List<String>{
            'unconverted allocationsSettings.Excluded_Opp_RecTypes__c',
            'unconverted contactsAndOrgsSettings.Opp_RecTypes_Excluded_for_Payments__c',
            'unconverted householdSettings.npo02__Household_Creation_Excluded_Recordtypes__c',
            'unconverted householdSettings.npo02__Household_OCR_Excluded_Recordtypes__c',
            'unconverted householdSettings.npo02__Membership_Record_Types__c',
            'unconverted householdSettings.npo02__Excluded_Account_Opp_Rectypes__c',
            'unconverted householdSettings.npo02__Excluded_Contact_Opp_Rectypes__c',
            'unconverted opportunityNamingSettings.Opportunity_Record_Types__c'
        };

        UTIL_RecordTypeSettingsUpdate.RecordTypeSettings settings = new UTIL_RecordTypeSettingsUpdate.RecordTypeSettings();

        settings.allocationsSettings = new Allocations_Settings__c(
            Excluded_Opp_RecTypes__c = expectedNameStrings.get(0)
        );

        settings.contactsAndOrgsSettings = new npe01__Contacts_And_Orgs_Settings__c(
            Opp_RecTypes_Excluded_for_Payments__c = expectedNameStrings.get(1)
        );

        settings.householdSettings = new npo02__Households_Settings__c(
            npo02__Household_Creation_Excluded_Recordtypes__c = expectedNameStrings.get(2),
            npo02__Household_OCR_Excluded_Recordtypes__c = expectedNameStrings.get(3),
            npo02__Membership_Record_Types__c = expectedNameStrings.get(4),
            npo02__Excluded_Account_Opp_Rectypes__c = expectedNameStrings.get(5),
            npo02__Excluded_Contact_Opp_Rectypes__c = expectedNameStrings.get(6)
        );

        settings.opportunityNamingSettings = new Map<String, Opportunity_Naming_Settings__c>{
            'testOns' => new Opportunity_Naming_Settings__c(
                Name = 'testOns',
                Opportunity_Record_Types__c = expectedNameStrings.get(7)
            )
        };

        Map<String, Id> opportunityNameMap = new Map<String, Id>{'OpportunityRecordTypeName' => '000000000000001'};
        Map<String, Id> contactNameMap = new Map<String, Id>{'ContactRecordTypeName' => '000000000000002'};

        // as getIdsFromName() gets called, these are the values for the
        // parameter `nameMap` we expect to receive in this order:
        List<Map<String, Id>> expectedNameMaps = new List<Map<String, Id>>{
            opportunityNameMap,
            opportunityNameMap,
            contactNameMap,
            contactNameMap,
            opportunityNameMap,
            opportunityNameMap,
            opportunityNameMap,
            opportunityNameMap
        };

        Test.startTest();

        stub.updateSettings(settings, opportunityNameMap, contactNameMap);

        Test.stopTest();

        System.assertEquals(expectedNameStrings, stub.nameStrings);
        System.assertEquals(expectedNameMaps, stub.nameMaps);

        System.assertEquals(
            returnNameStrings.get(0),
            settings.allocationsSettings.Excluded_Opp_RecTypes__c
        );

        System.assertEquals(
            returnNameStrings.get(1),
            settings.contactsAndOrgsSettings.Opp_RecTypes_Excluded_for_Payments__c
        );

        System.assertEquals(
            returnNameStrings.get(2),
            settings.householdSettings.npo02__Household_Creation_Excluded_Recordtypes__c
        );

        System.assertEquals(
            returnNameStrings.get(3),
            settings.householdSettings.npo02__Household_OCR_Excluded_Recordtypes__c
        );

        System.assertEquals(
            returnNameStrings.get(4),
            settings.householdSettings.npo02__Membership_Record_Types__c
        );

        System.assertEquals(
            returnNameStrings.get(5),
            settings.householdSettings.npo02__Excluded_Account_Opp_Rectypes__c
        );

        System.assertEquals(
            returnNameStrings.get(6),
            settings.householdSettings.npo02__Excluded_Contact_Opp_Rectypes__c
        );

        System.assertEquals(
            returnNameStrings.get(7),
            settings.opportunityNamingSettings.values().get(0).Opportunity_Record_Types__c
        );
    }

    /**
     * @description Stub class to verify that updateSettings() passes correct
     * values to updateSettings(...) method and properly inserts converted
     * settings
     */
    private class UpdateSettingsStub extends UTIL_RecordTypeSettingsUpdate {
        public UTIL_RecordTypeSettingsUpdate.RecordTypeSettings givenSettings;
        public UTIL_RecordTypeSettingsUpdate.RecordTypeSettings returnedSettings;
        private override UTIL_RecordTypeSettingsUpdate.RecordTypeSettings updateSettings(
            UTIL_RecordTypeSettingsUpdate.RecordTypeSettings settings,
            Map<String, Id> opportunityNameMap,
            Map<String, Id> contactNameMap
        ) {
            givenSettings = settings;
            return returnedSettings;
        }
    }

    @isTest
    public static void testUpdateSettingsUpsertsRecords() {
        // insert some settings, then call updateSettings() using stub class to
        // verify that the correct settings are queried, and that the renamed
        // settings are correctly saved to the database

        UTIL_RecordTypeSettingsUpdate.RecordTypeSettings settings = new UTIL_RecordTypeSettingsUpdate.RecordTypeSettings();

        settings.allocationsSettings = new Allocations_Settings__c(
            Excluded_Opp_RecTypes__c = 'unconverted1'
        );

        settings.contactsAndOrgsSettings = new npe01__Contacts_And_Orgs_Settings__c(
            Opp_RecTypes_Excluded_for_Payments__c = 'unconverted2'
        );

        settings.householdSettings = new npo02__Households_Settings__c(
            npo02__Household_Creation_Excluded_Recordtypes__c = 'unconverted3',
            npo02__Household_OCR_Excluded_Recordtypes__c = 'unconverted4',
            npo02__Membership_Record_Types__c = 'unconverted5',
            npo02__Excluded_Account_Opp_Rectypes__c = 'unconverted6',
            npo02__Excluded_Contact_Opp_Rectypes__c = 'unconverted7'
        );

        settings.opportunityNamingSettings = new Map<String, Opportunity_Naming_Settings__c>{
            'testOns' => new Opportunity_Naming_Settings__c(
                Name = 'testOns',
                Opportunity_Record_Types__c = 'unconverted8'
            )
        };

        upsert settings.allocationsSettings;
        upsert settings.contactsAndOrgsSettings;
        upsert settings.householdSettings;
        upsert settings.opportunityNamingSettings.values();

        settings.allocationsSettings.Excluded_Opp_RecTypes__c = 'converted1';
        settings.contactsAndOrgsSettings.Opp_RecTypes_Excluded_for_Payments__c = 'converted2';
        settings.householdSettings.npo02__Household_Creation_Excluded_Recordtypes__c = 'converted3';
        settings.householdSettings.npo02__Household_OCR_Excluded_Recordtypes__c = 'converted4';
        settings.householdSettings.npo02__Membership_Record_Types__c = 'converted5';
        settings.householdSettings.npo02__Excluded_Account_Opp_Rectypes__c = 'converted6';
        settings.householdSettings.npo02__Excluded_Contact_Opp_Rectypes__c = 'converted7';
        settings.opportunityNamingSettings.get('testOns').Opportunity_Record_Types__c = 'converted8';

        UpdateSettingsStub stub = new UpdateSettingsStub();
        stub.returnedSettings = settings;

        Test.startTest();

        stub.updateSettings();

        Test.stopTest();

        System.assertEquals('unconverted1', stub.givenSettings.allocationsSettings.Excluded_Opp_RecTypes__c);
        System.assertEquals('unconverted2', stub.givenSettings.contactsAndOrgsSettings.Opp_RecTypes_Excluded_for_Payments__c);
        System.assertEquals('unconverted3', stub.givenSettings.householdSettings.npo02__Household_Creation_Excluded_Recordtypes__c);
        System.assertEquals('unconverted4', stub.givenSettings.householdSettings.npo02__Household_OCR_Excluded_Recordtypes__c);
        System.assertEquals('unconverted5', stub.givenSettings.householdSettings.npo02__Membership_Record_Types__c);
        System.assertEquals('unconverted6', stub.givenSettings.householdSettings.npo02__Excluded_Account_Opp_Rectypes__c);
        System.assertEquals('unconverted7', stub.givenSettings.householdSettings.npo02__Excluded_Contact_Opp_Rectypes__c);
        System.assertEquals('unconverted8', stub.givenSettings.opportunityNamingSettings.values().get(0).Opportunity_Record_Types__c);

        Allocations_Settings__c updatedAllocationsSettings = Allocations_Settings__c.getInstance();
        npe01__Contacts_And_Orgs_Settings__c updatedContactsAndOrgsSettings = npe01__Contacts_And_Orgs_Settings__c.getInstance();
        npo02__Households_Settings__c updatedHouseholdSettings = npo02__Households_Settings__c.getInstance();
        Map<String, Opportunity_Naming_Settings__c> updatedOpportunityNamingSettings = Opportunity_Naming_Settings__c.getAll();

        System.assertEquals('converted1', updatedAllocationsSettings.Excluded_Opp_RecTypes__c);
        System.assertEquals('converted2', updatedContactsAndOrgsSettings.Opp_RecTypes_Excluded_for_Payments__c);
        System.assertEquals('converted3', updatedHouseholdSettings.npo02__Household_Creation_Excluded_Recordtypes__c);
        System.assertEquals('converted4', updatedHouseholdSettings.npo02__Household_OCR_Excluded_Recordtypes__c);
        System.assertEquals('converted5', updatedHouseholdSettings.npo02__Membership_Record_Types__c);
        System.assertEquals('converted6', updatedHouseholdSettings.npo02__Excluded_Account_Opp_Rectypes__c);
        System.assertEquals('converted7', updatedHouseholdSettings.npo02__Excluded_Contact_Opp_Rectypes__c);
        System.assertEquals('converted8', updatedOpportunityNamingSettings.get('testOns').Opportunity_Record_Types__c);
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
        // when upgrading from v3.77, the updateSettings() method should be
        // called exactly once
        UpdateSettingsRunCount stub = new UpdateSettingsRunCount();
        UTIL_RecordTypeSettingsUpdate.instance = stub;

        Test.startTest();

        Test.testInstall(new STG_InstallScript(), new Version(3, 77));

        Test.stopTest();

        System.assertEquals(1, stub.runCount);
    }

    @isTest
    public static void testUpdateRunsOnUpgradeFrom354() {
        // when upgrading from v3.54, the updateSettings() method should be
        // called exactly once (this is to verify that if upgrading from a
        // version prior to 3.78 the update will run)
        UpdateSettingsRunCount stub = new UpdateSettingsRunCount();
        UTIL_RecordTypeSettingsUpdate.instance = stub;

        Test.startTest();

        Test.testInstall(new STG_InstallScript(), new Version(3, 54));

        Test.stopTest();

        System.assertEquals(1, stub.runCount);
    }

    @isTest
    public static void testUpdateDoesNotRunOnNewInstall() {
        // when new install, updateSettings() should not be called
        UpdateSettingsRunCount stub = new UpdateSettingsRunCount();
        UTIL_RecordTypeSettingsUpdate.instance = stub;

        Test.startTest();

        Test.testInstall(new STG_InstallScript(), null);

        Test.stopTest();

        System.assertEquals(0, stub.runCount);
    }

    @isTest
    public static void testUpdateDoesNotRunOnUpgradeFrom378() {
        // when upgrading from version 3.78 or later, update should not run
        UpdateSettingsRunCount stub = new UpdateSettingsRunCount();
        UTIL_RecordTypeSettingsUpdate.instance = stub;

        Test.startTest();

        Test.testInstall(new STG_InstallScript(), new Version(3, 78));

        Test.stopTest();

        System.assertEquals(0, stub.runCount);
    }

    @isTest
    public static void testUpdateDoesNotRunOnUpgradeFrom399() {
        // when upgrading from version 3.78 or later, update should not run
        // when new install, updateSettings() should not be called
        UpdateSettingsRunCount stub = new UpdateSettingsRunCount();
        UTIL_RecordTypeSettingsUpdate.instance = stub;

        Test.startTest();

        Test.testInstall(new STG_InstallScript(), new Version(3, 99));

        Test.stopTest();

        System.assertEquals(0, stub.runCount);
    }
}