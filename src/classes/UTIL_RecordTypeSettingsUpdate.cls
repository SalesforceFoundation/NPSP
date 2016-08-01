/*
  Allocations_Settings__c.Excluded_Opp_RecTypes__c (Opportunity, Hierarchy)
  npe01__Contacts_And_Orgs_Settings__c.Opp_RecTypes_Excluded_for_Payments__c (Opportunity, Hierarchy)
  npo02__Households_Settings__c.npo02__Household_Creation_Excluded_Recordtypes__c (Contact, Hierarchy)
  npo02__Households_Settings__c.npo02__Household_OCR_Excluded_Recordtypes__c (Contact, Hierarchy)
  npo02__Households_Settings__c.npo02__Membership_Record_Types__c (Opportunity, Hierarchy)
  npo02__Households_Settings__c.npo02__Excluded_Account_Opp_Rectypes__c (Opportunity, Hierarchy)
  npo02__Households_Settings__c.npo02__Excluded_Contact_Opp_Rectypes__c (Opportunity, Hierarchy)
  Opportunity_Naming_Settings__c.Opportunity_Record_Types__c (Opportunity, List)
*/
public virtual class UTIL_RecordTypeSettingsUpdate {
    @TestVisible
    private UTIL_RecordTypeSettingsUpdate() {}

    @TestVisible
    private static UTIL_RecordTypeSettingsUpdate instance;

    public static UTIL_RecordTypeSettingsUpdate getInstance() {
        if (null == instance) {
            instance = new UTIL_RecordTypeSettingsUpdate();
        }
        return instance;
    }

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
    private class RecordTypeSettings {
        public Allocations_Settings__c allocationsSettings;
        public npe01__Contacts_And_Orgs_Settings__c contactsAndOrgsSettings;
        public npo02__Households_Settings__c householdSettings;
        public Map<String, Opportunity_Naming_Settings__c> opportunityNamingSettings;
    }
}