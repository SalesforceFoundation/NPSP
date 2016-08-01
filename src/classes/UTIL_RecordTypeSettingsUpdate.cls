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
 * @description Utility script to convert record type settings from old format
 * (where record types were stored by display name) to new format (where record
 * types are stored by id).
 *
 * This will handle the conversion of the following custom settings:
 *  Allocations_Settings__c.Excluded_Opp_RecTypes__c (Opportunity, Hierarchy)
 *  npe01__Contacts_And_Orgs_Settings__c.Opp_RecTypes_Excluded_for_Payments__c (Opportunity, Hierarchy)
 *  npo02__Households_Settings__c.npo02__Household_Creation_Excluded_Recordtypes__c (Contact, Hierarchy)
 *  npo02__Households_Settings__c.npo02__Household_OCR_Excluded_Recordtypes__c (Contact, Hierarchy)
 *  npo02__Households_Settings__c.npo02__Membership_Record_Types__c (Opportunity, Hierarchy)
 *  npo02__Households_Settings__c.npo02__Excluded_Account_Opp_Rectypes__c (Opportunity, Hierarchy)
 *  npo02__Households_Settings__c.npo02__Excluded_Contact_Opp_Rectypes__c (Opportunity, Hierarchy)
 *  Opportunity_Naming_Settings__c.Opportunity_Record_Types__c (Opportunity, List)
 */
public virtual class UTIL_RecordTypeSettingsUpdate {
    @TestVisible
    /** @description Private constructor for singleton pattern */
    private UTIL_RecordTypeSettingsUpdate() {}

    @TestVisible
    /** @description Static instance for singleton pattern */
    private static UTIL_RecordTypeSettingsUpdate instance;

    /**
     * @description get singleton instance of this class
     * @return UTIL_RecordTypeSettingsUpdate
     */
    public static UTIL_RecordTypeSettingsUpdate getInstance() {
        if (null == instance) {
            instance = new UTIL_RecordTypeSettingsUpdate();
        }
        return instance;
    }

    /**
     * @description Update custom settings from old format to new format
     */
    public virtual void updateSettings() {
        Map<String, Id> opportunityNameMap = getNameToRecordTypeIdMap(Opportunity.sObjectType);
        Map<String, Id> contactNameMap = getNameToRecordTypeIdMap(Contact.sObjectType);

        RecordTypeSettings settings = new RecordTypeSettings();

        settings.allocationsSettings = Allocations_Settings__c.getInstance();
        settings.contactsAndOrgsSettings = npe01__Contacts_And_Orgs_Settings__c.getInstance();
        settings.householdSettings = npo02__Households_Settings__c.getInstance();
        settings.opportunityNamingSettings = Opportunity_Naming_Settings__c.getAll();

        settings = updateSettings(settings, opportunityNameMap, contactNameMap);

        upsert settings.allocationsSettings;
        upsert settings.contactsAndOrgsSettings;
        upsert settings.householdSettings;
        if (settings.opportunityNamingSettings != null && !settings.opportunityNamingSettings.isEmpty()) {
            upsert settings.opportunityNamingSettings.values();
        }
    }

    @TestVisible
    /**
     * @description Update given custom settings from old format to new format,
     * using the given String -> Id maps to determine record type id from
     * record type display name
     *
     * @param settings The custom settings to be updated
     * @param opportunityNameMap A mapping of Opportunity record type display names to record type ids
     * @param contactNameMap A mapping of Contact record type display names to record type ids
     * @return RecordTypeSettings The settings after they have been converted
     */
    private virtual RecordTypeSettings updateSettings(RecordTypeSettings settings, Map<String, Id> opportunityNameMap, Map<String, Id> contactNameMap) {
        settings.allocationsSettings.Excluded_Opp_RecTypes__c = getIdsFromNames(
            settings.allocationsSettings.Excluded_Opp_RecTypes__c,
            opportunityNameMap
        );

        settings.contactsAndOrgsSettings.Opp_RecTypes_Excluded_for_Payments__c = getIdsFromNames(
            settings.contactsAndOrgsSettings.Opp_RecTypes_Excluded_for_Payments__c,
            opportunityNameMap
        );

        settings.householdSettings.npo02__Household_Creation_Excluded_Recordtypes__c = getIdsFromNames(
            settings.householdSettings.npo02__Household_Creation_Excluded_Recordtypes__c,
            contactNameMap
        );

        settings.householdSettings.npo02__Household_OCR_Excluded_Recordtypes__c = getIdsFromNames(
            settings.householdSettings.npo02__Household_OCR_Excluded_Recordtypes__c,
            contactNameMap
        );

        settings.householdSettings.npo02__Membership_Record_Types__c = getIdsFromNames(
            settings.householdSettings.npo02__Membership_Record_Types__c,
            opportunityNameMap
        );

        settings.householdSettings.npo02__Excluded_Account_Opp_Rectypes__c = getIdsFromNames(
            settings.householdSettings.npo02__Excluded_Account_Opp_Rectypes__c,
            opportunityNameMap
        );

        settings.householdSettings.npo02__Excluded_Contact_Opp_Rectypes__c = getIdsFromNames(
            settings.householdSettings.npo02__Excluded_Contact_Opp_Rectypes__c,
            opportunityNameMap
        );

        for (Opportunity_Naming_Settings__c ons : settings.opportunityNamingSettings.values()) {
            ons.Opportunity_Record_Types__c = getIdsFromNames(
                ons.Opportunity_Record_Types__c,
                opportunityNameMap
            );
        }

        return settings;
    }

    /**
     * @description Build a mapping of record type name to record type id for
     * all of the record types defined for the given SObjectType.  Note that
     * the keys in this map will include the untranslated record type name, as
     * well as all translated versions of the record type name.  The map will
     * *not* contain a mapping for the 'Master' record type.
     *
     * @param sot The sObjectType to use for determining record types
     * @return Map<String, Id>
     */
    private Map<String, Id> getNameToRecordTypeIdMap(Schema.SObjectType sot) {
        String sobjectTypeName = sot.getDescribe().getName();

        List<RecordType> recordTypes = [
            SELECT
                Name,
                (SELECT Value FROM Localization)
            FROM RecordType
            WHERE SobjectType = :sobjectTypeName
        ];

        Map<String, Id> nameMap = new Map<String, Id>();

        for (RecordType rt : recordTypes) {
            nameMap.put(rt.Name, rt.Id);
            for (RecordTypeLocalization rtl : rt.Localization) {
                // potentially overwrite existing entry due to ambiguity in naming-- fine
                nameMap.put(rtl.Value, rt.Id);
            }
        }

        return nameMap;
    }

    @TestVisible
    /**
     * @description Given a semicolon ';' separated string of record type
     * names, and a mapping of record type names to record type ids, return a
     * new semicolon separated string of record type ids for all of the known
     * record types in the original string.  Unknown or blank record type names
     * will be discarded.
     *
     * @param nameString A semicolon separated string of record type names
     * @param nameMap A mapping of record type names to record type ids
     * @return String
     */
    private virtual String getIdsFromNames(String nameString, Map<String, Id> nameMap) {
        if (nameString == null) {
            return null;
        }

        List<String> names = nameString.split(';', 0);

        Set<Id> ids = new Set<Id>();
        for (String name : names) {
            if (!nameMap.containsKey(name)) {
                // could not find record type by with this name!-- ignore
                continue;
            }
            ids.add(nameMap.get(name));
        }

        String idsString = String.join(new List<Id>(ids), ';');

        return idsString;
    }

    @TestVisible
    /**
     * @description A storage class for wrapping multiple related custom
     * setting objects
     */
    private class RecordTypeSettings {
        public Allocations_Settings__c allocationsSettings;
        public npe01__Contacts_And_Orgs_Settings__c contactsAndOrgsSettings;
        public npo02__Households_Settings__c householdSettings;
        public Map<String, Opportunity_Naming_Settings__c> opportunityNamingSettings;
    }
}