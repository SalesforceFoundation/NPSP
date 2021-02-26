public with sharing class HouseholdNamingExclusions implements INamingExclusions {

    private Boolean isExcludedFromName;
    private Boolean isExcludedFromFormalGreeting;
    private Boolean isExcludedFromInformalGreeting;

    public HouseholdNamingExclusions(Contact con) {
        this.isExcludedFromName = con.Exclude_from_Household_Name__c;
        this.isExcludedFromFormalGreeting = con.Exclude_from_Household_Formal_Greeting__c;
        this.isExcludedFromInformalGreeting = con.Exclude_from_Household_Informal_Greeting__c;
    }

    public Boolean isExcludedFromName() {
        return isExcludedFromName;
    }

    public Boolean isExcludedFromFormalGreeting() {
        return isExcludedFromFormalGreeting;
    }

    public Boolean isExcludedFromInformalGreeting() {
        return isExcludedFromInformalGreeting;
    }

    public Boolean equals(INamingExclusions other) {
        return isExcludedFromName == other.isExcludedFromName()
                && isExcludedFromFormalGreeting == other.isExcludedFromFormalGreeting()
                && isExcludedFromInformalGreeting == other.isExcludedFromInformalGreeting();
    }

    public void synchronizeFrom(INamingExclusions other) {
        if (other.isExcludedFromName()) {
            isExcludedFromName = other.isExcludedFromName();
        }
        if (other.isExcludedFromFormalGreeting()) {
            isExcludedFromFormalGreeting = other.isExcludedFromFormalGreeting();
        }
        if (other.isExcludedFromInformalGreeting()) {
            isExcludedFromInformalGreeting = other.isExcludedFromInformalGreeting();
        }
    }

    public Boolean hasNamingExclusions() {
        return isExcludedFromName()
                || isExcludedFromInformalGreeting()
                || isExcludedFromFormalGreeting();
    }

    public void updateFrom(HouseholdNamingExclusionsString other) {
        isExcludedFromName = other.isExcludedFromName();
        isExcludedFromFormalGreeting = other.isExcludedFromFormalGreeting();
        isExcludedFromInformalGreeting = other.isExcludedFromInformalGreeting();
    }
}