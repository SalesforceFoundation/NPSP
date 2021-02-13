public inherited sharing class HouseholdSettings {

    npo02__Households_Settings__c settings;
    private static final String defaultNamingService = 'HH_NameSpec';

    public HouseholdSettings() {
        this(null);
    }

    @TestVisible
    private HouseholdSettings(npo02__Households_Settings__c settings) {
        if (settings == null) {
            this.settings = UTIL_CustomSettingsFacade.getHouseholdsSettings();
        } else {
            this.settings = settings;
        }
    }

    public Boolean isAsyncEnabled() {
        return settings.npo02__Async_Household_Naming__c;
    }

    public Boolean isAllIndividualsProcessor() {
        return settings.npo02__Household_Rules__c == HH_Households.ALL_INDIVIDUALS_PROCESSOR;
    }

    public Boolean isAllProcessor() {
        return settings.npo02__Household_Rules__c == HH_Households.ALL_PROCESSOR;
    }

    public Set<Id> contactRecordTypesToExclude() {
        if (hasRecordTypeExclusions()) {
            return getRecordTypeIdsToExclude();
        } else {
            return new Set<Id>();
        }
    }

    private Set<Id> getRecordTypeIdsToExclude() {
        return new Set<Id>(
                (List<Id>) settings.npo02__Household_Creation_Excluded_Recordtypes__c.split(';'));
    }

    private Boolean hasRecordTypeExclusions() {
        return settings.npo02__Household_Creation_Excluded_Recordtypes__c != null;
    }

    public Boolean isAdvancedHouseholdNaming() {
        return settings != null && settings.npo02__Advanced_Household_Naming__c == true;
    }

    public String getImplementingClass() {
        String implementingClass = namingSettings.Implementing_Class__c;
        return String.isBlank(implementingClass) ? defaultNamingService : implementingClass;
    }

    /*******************************************************************************************************
    * @description our cached copy of the Household Naming Settings
    */
    private Household_Naming_Settings__c namingSettings {
        get {
            if (namingSettings == null) {
                namingSettings =
                        UTIL_CustomSettingsFacade.getHouseholdNamingSettings();
            }
            return namingSettings;
        }
        set;
    }

}