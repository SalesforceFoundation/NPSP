/*
    Copyright (c) 2011, Salesforce.org
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
* @date 2011
* @group Households
* @description Controls generation of household names for lists of households
* NOTE: This class handles both household naming for the Household__c object
* as well as for HH Account objects.
*/
public without sharing class HouseholdNamingService {

    private HouseholdSettings settings = new HouseholdSettings();

    /*******************************************************************************************************
    * @description turns off household naming in the current execution context.  provided for other
    * components, like Batch Data Import, to momentarily turn off the household naming logic.  there is no
    * direct way to do that by disabling TDTM trigger handlers, or using existing static flags.
    * @param disable True to disable, False to enable
    * @return void
    */
    private static Boolean isHouseholdNamingDisabled = false;
    public static void disableHouseholdNaming(Boolean disable) {
        isHouseholdNamingDisabled = disable;
    }

    /*******************************************************************************************************
    * @description future method to update the household names for the specified households
    * @param hhids the list of household Id's (either Household__c or Account Id's)
    * @return void
    */
    @future
    public static void updateHouseholdNameAndMemberCountAsynchronously(List<Id> hhids) {
        //set our process control to avoid recursive updating on household records
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.HH, true);
        HouseholdNamingService householdNamingService = new HouseholdNamingService();
        householdNamingService.updateHouseholdNameAndMemberCount(hhids);
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.HH, false);
    }

    /*******************************************************************************************************
    * @description Sets Number_Of_Household_Members__c, and
    * it will be responsible for only updating names if the advanced household naming is true.
    * So any code that used to check for advanced household naming should no longer do so,
    * (unless it is only for a naming scenario that would possibly change number of household members.)
    * @param householdOrAccountIds the list of household Id's (either Household__c or Account Id's)
    * @return void
    */
    public void updateHouseholdNameAndMemberCount(List<Id> householdOrAccountIds) {
        if (isHouseholdNamingDisabled) {
            return;
        }
        //we need this turned on to prevent recursive triggering on household creation
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.HH, true);

        List<SObject> householdsOrAccounts = householdsOrAccountsFor(householdOrAccountIds);
        Map<Id, List<Contact>> membersByHouseholdId =
                getHouseholdMembersByHouseholdId(householdOrAccountIds);
        setHouseholdNameFieldValues(householdsOrAccounts, membersByHouseholdId);
        setNumberOfHouseholdMembers(householdsOrAccounts, membersByHouseholdId);
        save(householdsOrAccounts);

        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.HH, false);
    }

    private void save(List<SObject> householdsOrAccounts) {
        if (!householdsOrAccounts.isEmpty()) {
            UTIL_DMLService.updateRecords(householdsOrAccounts);
        }
    }

    private void setNumberOfHouseholdMembers(List<SObject> householdsOrAccounts, Map<Id, List<Contact>> membersByHouseholdId) {
        for (SObject household : householdsOrAccounts) {
            List<Contact> householdMembers = membersByHouseholdId.get(idFor(household));
            household.put(UTIL_Namespace.StrTokenNSPrefix('Number_of_Household_Members__c'),
                    householdMembers != null ? householdMembers.size() : 0);
        }
    }

    private void setHouseholdNameFieldValues(List<SObject> householdsOrAccounts,
            Map<Id, List<Contact>> membersByHouseholdId) {
        for (SObject household : householdsOrAccounts) {
            List<Contact> householdMembers =
                    membersByHouseholdId.get(idFor(household)) == null ?
                            new List<Contact>() :
                            membersByHouseholdId.get(idFor(household));
            if (settings.isAdvancedHouseholdNaming()) {
                setNameFieldValuesOnHousehold(
                        household,
                        new HouseholdName(
                                new Contacts(householdMembers),
                                householdNamingImpl));
            }
        }
    }

    private Map<Id, List<Contact>> getHouseholdMembersByHouseholdId(List<Id> householdOrAccountIds) {
        return householdMembersByHouseholdId(householdMembersFor(householdOrAccountIds));
    }

    private List<SObject> householdsOrAccountsFor(List<Id> householdOrAccountIds) {
        List<SObject> hhupdatelist = new List<SObject>();
        hhupdatelist.addAll(getHouseholdsFor(householdOrAccountIds));
        hhupdatelist.addAll(getAccountsFor(householdOrAccountIds));
        return hhupdatelist;
    }

    private List<SObject> getAccountsFor(List<Id> hhids) {
        return [
                SELECT Id, Name, npo02__SYSTEM_CUSTOM_NAMING__c
                FROM Account
                WHERE Id IN :hhids
        ];
    }

    private List<SObject> getHouseholdsFor(List<Id> hhids) {
        return [
                SELECT Id, Name, npo02__SYSTEM_CUSTOM_NAMING__c
                FROM Npo02__Household__c
                WHERE Id IN :hhids
        ];
    }

    private Id idFor(SObject household) {
        return String.valueOf(household.get('Id'));
    }

    private Map<Id, List<Contact>> householdMembersByHouseholdId(List<Contact> contacts) {
        Map<Id, List<Contact>> hhIDContactMap = new Map<Id, List<Contact>>();
        for (Contact con : contacts) {
            if (!hhIDContactMap.containskey(con.hhId__c)) {
                hhIDContactMap.put(con.hhId__c, new List<Contact>{
                        con
                });
            } else {
                List<Contact> clist = hhIDContactMap.get(con.hhId__c);
                clist.add(con);
            }
        }
        return hhIDContactMap;
    }

    /*******************************************************************************************************
    * @description Returns Contacts for specified Accounts or Households.
    * Private Contacts or records not belonging to the specified Accounts/Households are not selected.
    * @param householdOrAccountIds The list of Household Id's (either Household__c or Account Id's)
    * @return List<Contact>
    */
    @TestVisible
    private List<Contact> householdMembersFor(List<Id> householdOrAccountIds) {
        Set<Id> queryHHIds = householdOrAccountIds == null ? new Set<Id>() : new Set<Id>(householdOrAccountIds);
        queryHHIds.remove(null);

        if (queryHHIds.isEmpty()) {
            return new List<Contact>();
        }

        return Database.Query(householdMembersQueryFor(queryHHIds));
    }

    private String householdMembersQueryFor(Set<Id> queryHHIds) {
        //get all of the contacts and their associated households
        //return them in the order of household and then household naming order
        //we use dynamic soql so we can include all contact fields, since custom naming may refer to any field.
        String strSoql = getQueryForContactNamingFields();
        String strHHId = UTIL_Namespace.StrTokenNSPrefix('HHId__c');
        strSoql += ' WHERE AccountId IN :queryHHIds OR npo02__Household__c IN :queryHHIds ' +
                ' ORDER BY ' + strHHId + ', npo02__Household_Naming_Order__c ASC NULLS LAST, Primary_Contact__c DESC, CreatedDate ';
        return strSoql;
    }

    /*******************************************************************************************************
    * @description Returns Contact fields specified in the Household Naming Settings format fields.
    * @return Set<String> If the Automatic Household Naming is enabled, return set of Contact field API names;
    * otherwise, an empty set
    */
    public Set<String> getHouseholdNamingContactFields() {
        if (!settings.isAdvancedHouseholdNaming()
                || householdNamingImpl.setHouseholdNameFieldsOnContact() == null) {
            return new Set<String>();
        } else {
            return householdNamingImpl.setHouseholdNameFieldsOnContact();
        }
    }

    /*******************************************************************************************************
    * @description the class object that supports the HH_INaming interface
    */
    HH_INaming householdNamingImpl {
        get {
            if (householdNamingImpl == null) {
                String implementingClass = new HouseholdSettings().getImplementingClass();

                Type classType = Type.forName(implementingClass);
                if (classType != null) {
                    Object classInstance = classType.newInstance();
                    if (classInstance instanceof HH_INaming) {
                        householdNamingImpl = (HH_INaming) classInstance;
                    }
                }
            }
            return householdNamingImpl;
        }
        set;
    }

    /*******************************************************************************************************
    * @description executes the batch job to update all household names
    * @param isActivation whether this is being called when npo02__Advanced_Household_Naming__c is being turned on
    * @return void
    */
    public static void refreshAllHouseholdNaming(Boolean isActivation) {
        // the household batch expects a list of Contact's with just Id, LastName, HHId__c available.
        String strSoql = 'SELECT Id, LastName, ' + UTIL_Namespace.StrTokenNSPrefix('HHId__c') + ' FROM Contact WHERE ' +
                UTIL_Namespace.StrTokenNSPrefix('HHId__c') + ' != NULL ';
        HH_HouseholdNaming_BATCH batch = new HH_HouseholdNaming_BATCH(strSoql, isActivation);
        Id batchProcessId = database.executeBatch(batch, getBatchSize());
    }

    private static Integer getBatchSize() {
        return 200;
    }

    /*******************************************************************************************************
    * @description the soql select String to use which includes any fields we use or are referred to in
    * any of the naming specifications.
    */
    private String queryForContactNamingFields;
    @TestVisible
    private String getQueryForContactNamingFields() {
        if (queryForContactNamingFields == null) {
            //we use dynamic soql so we can include all contact fields, since custom naming may refer to any field.
            String[] selectFields = new String[]{
                    'Id', 'HHId__c', 'npo02__Naming_Exclusions__c'
            };
            selectFields.addAll(getHouseholdNamingContactFields());

            queryForContactNamingFields = new UTIL_Query()
                    .withSelectFields(selectFields)
                    .withToLabelSalutation()
                    .withFrom('Contact')
                    .build();
        }
        return queryForContactNamingFields;
    }

    private Boolean needsNamingFieldsUpdated(SObject household, SObject oldRecord) {
        if (needsNameReplaced(household)) {
            return true;
        } else if (needsInformalGreetingReplaced(household)) {
            return true;
        } else if (needsFormalGreetingReplaced(household)) {
            return true;
        } else if (isSystemCustomNamingChanged(household, oldRecord)) {
            return true;
        } else if (oneToOneAccountChanged(household, oldRecord)) {
            return true;
        }
        return false;
    }

    private Boolean oneToOneAccountChanged(SObject household, SObject oldRecord) {
        return isAccount(household) && isOneToOneContactChanged(household, oldRecord);
    }

    private Boolean isAccount(SObject household) {
        return household.getSObjectType() == Account.sObjectType;
    }

    private Boolean needsFormalGreetingReplaced(SObject household) {
        return formalGreetingFor(household) == nameReplacementText();
    }

    private Boolean needsInformalGreetingReplaced(SObject household) {
        return informalGreetingFor(household) == nameReplacementText();
    }

    private Boolean needsNameReplaced(SObject household) {
        return nameFor(household) == nameReplacementText();
    }

    private Object formalGreetingFor(SObject household) {
        return household.get('npo02__Formal_Greeting__c');
    }

    private Object informalGreetingFor(SObject household) {
        return household.get('npo02__Informal_Greeting__c');
    }

    private Object nameFor(SObject household) {
        return household.get('Name');
    }

    private Boolean isOneToOneContactChanged(SObject household, SObject oldRecord) {
        return household.get('npe01__One2OneContact__c') != oldRecord.get('npe01__One2OneContact__c');
    }

    private Boolean isSystemCustomNamingChanged(SObject household, SObject oldRecord) {
        return household.get('npo02__SYSTEM_CUSTOM_NAMING__c') !=
                oldRecord.get('npo02__SYSTEM_CUSTOM_NAMING__c');
    }

    public List<Id> getHouseholdsNeedingNameUpdates(List<SObject> records,
            Map<Id, SObject> oldMap) {
        List<Id> hhList = new List<Id>();
        for (SObject household : records) {
            if (needsNamingFieldsUpdated(household, oldMap.get(household.Id))) {
                hhList.add(household.Id);
            }
        }
        return hhList;
    }

    public void setCustomNamingField(List<SObject> records, Map<Id, SObject> oldMap) {
        for (SObject household : records) {
            SObject oldRecord = oldMap.get(household.Id);
            setCustomNamingStringValue(household, oldRecord);
        }
    }

    public void setNameAndGreetingsToReplacementText(List<SObject> records) {
        for (SObject household : records) {
            setNameAndGreetingsToReplacementText(household);
        }
    }

    /*******************************************************************************************************
    * @description for the list of Household or Account Ids, update their Household Names
    * @param accountIds the list of Household or Account Ids that need updating.
    * @return void
    */
    public void renameHouseholdAccounts(List<Id> accountIds) {
        renameHHAccounts(accountIds);
    }

    /*******************************************************************************************************
    * @description for the list of Household or Account Ids, update their Household Names
    * @param accountIds the list of Household or Account Ids that need updating.
    * @return void
    */
    public static void renameHHAccounts(List<Id> accountIds) {
        if (accountIds.isEmpty()) {
            return;
        }

        if (shouldProcessSynchronously(accountIds)) {
            HouseholdNamingService householdNamingService = new HouseholdNamingService();
            householdNamingService.updateHouseholdNameAndMemberCount(accountIds);
        } else {
            HouseholdNamingService.updateHouseholdNameAndMemberCountAsynchronously(accountIds);
        }
    }

    private static Boolean shouldProcessSynchronously(List<Id> accountIds) {
        return accountIds.size() == 1 || System.isFuture() || System.isBatch() || System.isQueueable();
    }

    public void setNameFieldValuesOnHousehold(SObject household, HouseholdName householdName) {
        HouseholdNamingUserControlledFields namingOverrides =
                new HouseholdNamingUserControlledFields(namingOverridesFor(household));
        if (!namingOverrides.isNameControlledByUser()) {
            setName(household, householdName);
        }
        if (!namingOverrides.isFormalGreetingControlledByUser()) {
            setFormalGreeting(household, householdName);
        }
        if (!namingOverrides.isInformalGreetingControlledByUser()) {
            setInformalGreeting(household, householdName);
        }
    }

    private void setInformalGreeting(SObject household, HouseholdName householdName) {
        household.put('npo02__Informal_Greeting__c', householdName.asInformalGreeting());
    }

    private void setFormalGreeting(SObject household, HouseholdName householdName) {
        household.put('npo02__Formal_Greeting__c', householdName.asFormalGreeting());
    }

    private void setName(SObject household, HouseholdName householdName) {
        household.put('Name', householdName.asName());
    }

    private void replaceHouseholdFormalGreeting(SObject household) {
        household.put('npo02__Formal_Greeting__c', nameReplacementText());
    }

    private void replaceHouseholdInformalGreeting(SObject household) {
        household.put('npo02__Informal_Greeting__c', nameReplacementText());
    }

    private void replaceHouseholdName(SObject household) {
        household.put('Name', nameReplacementText());
    }

    private void setNameAndGreetingsToReplacementText(SObject household) {
        if (isNameReplaceable(household)) {
            replaceHouseholdName(household);
        }

        if (isInformalGreetingReplaceable(household)) {
            replaceHouseholdInformalGreeting(household);
        }

        if (isFormalGreetingReplaceable(household)) {
            replaceHouseholdFormalGreeting(household);
        }
    }

    private Boolean isNameReplaceable(SObject household) {
        return isReplaceable(household, 'Name');
    }

    private Boolean isFormalGreetingReplaceable(SObject household) {
        return isReplaceable(household, 'npo02__Formal_Greeting__c');
    }

    private Boolean isInformalGreetingReplaceable(SObject household) {
        return isReplaceable(household, 'npo02__Informal_Greeting__c');
    }

    private Boolean isReplaceable(SObject household, String fieldApiName) {
        String fieldValue = (String) household.get(fieldApiName);
        return fieldValue == null || fieldValue == '' || fieldValue == nameReplacementText();
    }

    private void setCustomNamingStringValue(SObject household, SObject oldRecord) {
        HouseholdNamingUserControlledFields userControlledNamingFields =
                new HouseholdNamingUserControlledFields(household, oldRecord);
        household.put('npo02__SYSTEM_CUSTOM_NAMING__c',
                userControlledNamingFields.asConcatenatedString());
    }

    private String namingOverridesFor(SObject household) {
        return (String) household.get
                ('npo02__SYSTEM_CUSTOM_NAMING__c');
    }

    private String nameReplacementText() {
        return System.Label.npo02.NameReplacementText;
    }
}