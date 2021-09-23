/*
    Copyright (c) 2021 Salesforce.org
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
* @date 2021
* @description Domain to cover the responsibilities related to a Contact's
* Household Naming exclusion status.
*/
public inherited sharing class NamingExclusions {

    List<Contact> contacts;
    public Map<Id, Contact> oldMap;
    public NamingExclusions(List<Contact> contacts){
       this.contacts = contacts;
    }

    public NamingExclusions(List<Contact> records, Map<Id, Contact> oldMap) {
        this.contacts = records;
        this.oldMap = oldMap != null ?
                new Map<Id, Contact>(oldMap) : new Map<Id, Contact>();
    }

    public void synchronize() {
        for (Contact con : contacts) {
            INamingExclusionsString exclusionsAsString =
                    new HouseholdNamingExclusionsString(con);
            INamingExclusions exclusionsAsBooleans =
                    new HouseholdNamingExclusionsCheckboxes(con);
            if (!exclusionsAsString.equals(exclusionsAsBooleans)) {
                mergeExclusions(exclusionsAsBooleans, exclusionsAsString);
                setExclusionsStringFor(con, exclusionsAsString.value());
                setExclusionsCheckboxes(con, exclusionsAsBooleans);
            }
        }
    }

    private void setExclusionsStringFor(Contact contact, String val) {
        contact.npo02__Naming_Exclusions__c = val;
    }

    /**
     * @param exclusionsAsBooleans Checkbox implemenation of Household Naming Exclusions
     * @param exclusionsAsString Concatenated string implementation of Household Naming
     * Exclusions
     * @description Checks any exclusions checkboxes to true that are included in the
     * concatenated string, and then updates the string to include exclusions (field names)
     * for any Exclusion checkboxes that are marked TRUE for the Contact.
     */
    private void mergeExclusions(INamingExclusions exclusionsAsBooleans,
            INamingExclusions exclusionsAsString) {
        // Prioritize booleans by syncing from picklists first
        exclusionsAsBooleans.synchronizeFrom(exclusionsAsString);
        exclusionsAsString.synchronizeFrom(exclusionsAsBooleans);
    }

    private void setExclusionsCheckboxes(Contact con, INamingExclusions exclusions) {
        con.Exclude_from_Household_Name__c = exclusions.isExcludedFromName();
        con.Exclude_from_Household_Formal_Greeting__c = exclusions.isExcludedFromFormalGreeting();
        con.Exclude_from_Household_Informal_Greeting__c = exclusions.isExcludedFromInformalGreeting();
    }

    public void synchronizeNamingExclusionsBeforeInsert() {
        for (Contact con : contacts) {
            HouseholdNamingExclusionsString namingExclusionsString =
                    new HouseholdNamingExclusionsString(con);

            HouseholdNamingExclusionsCheckboxes exclusionsAsCheckboxes =
                    new HouseholdNamingExclusionsCheckboxes(con);

            if (namingExclusionsString.hasNamingExclusions()) {
                exclusionsAsCheckboxes.updateFrom(namingExclusionsString);
                setExclusionsCheckboxes(con, exclusionsAsCheckboxes);
            }

            if (exclusionsAsCheckboxes.hasNamingExclusions()) {
                namingExclusionsString.synchronizeFrom(exclusionsAsCheckboxes);
                setExclusionsStringFor(con, namingExclusionsString.value());
            }
        }
    }

    public void synchronizeNamingExclusionsBeforeUpdate() {
        for (Contact con : contacts) {
            HouseholdNamingExclusionsCheckboxes exclusionsAsCheckboxes =
                    new HouseholdNamingExclusionsCheckboxes(con);
            HouseholdNamingExclusionsCheckboxes oldExclusionsAsCheckboxes =
                    new HouseholdNamingExclusionsCheckboxes(oldVersionOf(con));
            HouseholdNamingExclusionsString householdNamingExclusionsString =
                    new HouseholdNamingExclusionsString(con);
            HouseholdNamingExclusionsString oldHouseholdNamingExclusionsString =
                    new HouseholdNamingExclusionsString(oldVersionOf(con));

            if (!exclusionsAsCheckboxes.equals(oldExclusionsAsCheckboxes)) {
                householdNamingExclusionsString.synchronizeFrom(exclusionsAsCheckboxes);
                setExclusionsStringFor(con, householdNamingExclusionsString.value());
            } else if (!householdNamingExclusionsString.equals
                    (oldHouseholdNamingExclusionsString)) {
                exclusionsAsCheckboxes.updateFrom(householdNamingExclusionsString);
                setExclusionsCheckboxes(con, exclusionsAsCheckboxes);
            }
        }
    }

    public Contact oldVersionOf(Contact con) {
        return oldMap.get(con.Id);
    }
}