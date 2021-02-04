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
* @date 2011 (2.3)
* @group Households
* @description Controls generation of household names for lists of households
* NOTE: This class handles both household naming for the Household__c object
* as well as for HH Account objects.
*/
public without sharing class HH_HouseholdNaming {

    private static final String defaultNamingService = 'HH_NameSpec';

    /*******************************************************************************************************
    * @description future method to update the household names for the specified households
    * @param hhids the list of household Id's (either Household__c or Account Id's)
    * @return void
    */
    @future
    public static void FutureUpdateNames(list<id> hhids){
        //set our process control to avoid recursive updating on household records
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.HH, true);

        //create a new instance of the HH_HouseholdNaming class -
        //and pass in our param
        //this is b/c of the public visibility
        HH_HouseholdNaming hn = new HH_HouseholdNaming();

        hn.UpdateNames(hhids);

        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.HH, false);    
    }

    /*******************************************************************************************************
    * @description Sets Number_Of_Household_Members__c, and
    * it will be responsible for only updating names if the advanced household naming is true.
    * So any code that used to check for advanced household naming should no longer do so,
    * (unless it is only for a naming scenario that would possibly change number of household members.)
    * @param hhids the list of household Id's (either Household__c or Account Id's)
    * @return void
    */
    public void UpdateNames(list<id> hhids){

        // Skip automatic naming during Batch Data Import to improve performance
        if (isHouseholdNamingDisabled) {
            return;
        }

        //we need this turned on to prevent recursive triggering on household creation
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.HH, true);

        list<Contact> contactlist = getHouseholdContacts(hhids);

        list<SObject> listHHObj = [select Id, Name, npo02__SYSTEM_CUSTOM_NAMING__c from npo02__Household__c where id IN : hhids];
        list<SObject> listHHAcct = [select Id, Name, npo02__SYSTEM_CUSTOM_NAMING__c from Account where id IN : hhids];

        // handle two types of households by using an SObject
        list<SObject> hhupdatelist = new list<SObject>();
        hhupdatelist.addAll(listHHObj);
        hhupdatelist.addAll(listHHAcct);

        map<id, list<Contact>> hhIDContactMap = new map<id, list<Contact>>();
        buildHHIdtoContactsMap(contactlist, hhIDContactMap);

        //loop through the households needing name changes, if necessary, make them.
        for (SObject h : hhupdatelist){
            ID hhId = string.valueOf(h.get('Id'));
            list<Contact> listCon = hhIDContactMap.get(hhId);

            if (isAutomaticNaming()) {
                setHouseholdNameFields(h, listCon);
            }

            // now we also store the number of members on the Household!
            h.put(UTIL_Namespace.StrTokenNSPrefix('Number_of_Household_Members__c'),
                    listCon != null ? listCon.size() : 0);
        }

        if (!hhupdatelist.isEmpty()) {
            // all or nothing, so errors not lost
            UTIL_DMLService.updateRecords(hhupdatelist);
        }

        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.HH, false);
    }

    private void buildHHIdtoContactsMap(List<Contact> contactlist, Map<Id, List<Contact>> hhIDContactMap) {
        for (Contact c : contactlist) {
            if (!hhIDContactMap.containskey(c.hhId__c)) {
                hhIDContactMap.put(c.hhId__c, new list<Contact>{
                        c
                });
            } else {
                list<Contact> clist = hhIDContactMap.get(c.hhId__c);
                clist.add(c);
            }
        }
    }

    private void setHouseholdNameFields(SObject h, List<Contact> listCon) {
        string customnameparam = '';
	            if (h.get('npo02__SYSTEM_CUSTOM_NAMING__c') != null){
            customnameparam = string.valueOf(h.get('npo02__SYSTEM_CUSTOM_NAMING__c'));
        }

        if (!customnameparam.contains('Name'))
            h.put('Name', getHHName(listCon));

        if (!customnameparam.contains('Formal_Greeting__c'))
            h.put('npo02__Formal_Greeting__c', getFormalName(listCon));

        if (!customnameparam.contains('Informal_Greeting__c'))
            h.put('npo02__Informal_Greeting__c', getInformalName(listCon));
    }

    /*******************************************************************************************************
    * @description Returns Contacts for specified Accounts or Households.
    * Private Contacts or records not belonging to the specified Accounts/Households are not selected.
    * @param hhIds The list of Household Id's (either Household__c or Account Id's)
    * @return List<Contact>
    */
    @TestVisible
    private List<Contact> getHouseholdContacts(List<Id> hhIds) {
        Set<Id> queryHHIds = hhIds == null ? new Set<Id>() : new Set<Id>(hhIds);
        queryHHIds.remove(null);

        if (queryHHIds.isEmpty()) {
            return new List<Contact>();
        }

        //get all of the contacts and their associated households
        //return them in the order of household and then household naming order
        //we use dynamic soql so we can include all contact fields, since custom naming may refer to any field.
        string strSoql = strContactSelectStmtAllNamingFields;
        string strHHId = UTIL_Namespace.StrTokenNSPrefix('HHId__c');

        strSoql += ' WHERE AccountId IN :queryHHIds OR npo02__Household__c IN :queryHHIds ' +
                ' ORDER BY ' + strHHId + ', npo02__Household_Naming_Order__c ASC NULLS LAST, Primary_Contact__c DESC, CreatedDate ';

        return Database.Query(strSoql);
    }


    /*******************************************************************************************************
    * @description Returns Automatic Household Naming setting
    * @return Boolean True if the Automatic Household Naming is checked, false otherwise
    */
    public Boolean isAutomaticNaming() {
        npo02__Households_Settings__c settings = UTIL_CustomSettingsFacade.getHouseholdsSettings();

        return settings == null
            ? false
            : settings.npo02__Advanced_Household_Naming__c == true;
    }

    /*******************************************************************************************************
    * @description our cached copy of the Household Naming Settings
    */
    private static Household_Naming_Settings__c namingSettings {
        get {
            if (namingSettings == null) {
                namingSettings =
                        UTIL_CustomSettingsFacade.getHouseholdNamingSettings();
            }
            return namingSettings;
        }
        set;
    }

    /*******************************************************************************************************
    * @description the class object that supports the HH_INaming interface
    */
    static HH_INaming namingService {
        get {
            if (namingService == null) {
                String implementingClass = getImplementingClass();

                Type classType = Type.forName(implementingClass);
                if (classType != null) {
                    Object classInstance = classType.newInstance();
                    if (classInstance instanceof HH_INaming) {
                        namingService = (HH_INaming) classInstance;
                    }
                }
            }
            return namingService;
        }
        set;
    }

    private static String getImplementingClass() {
        String implementingClass = namingSettings.Implementing_Class__c;
        if (implementingClass == null || implementingClass == '') {
            implementingClass = defaultNamingService;
        }
        return implementingClass;
    }

    /*******************************************************************************************************
    * @description turns off household naming in the current execution context.  provided for other
    * components, like Batch Data Import, to momentarily turn off the household naming logic.  there is no
    * direct way to do that by disabling TDTM trigger handlers, or using existing static flags.
    * @param disable True to disable, False to enable
    * @return void
    */
    public static void disableHouseholdNaming(boolean disable) {
        isHouseholdNamingDisabled = disable;
    }
    private static boolean isHouseholdNamingDisabled = false;


    /*******************************************************************************************************
    * @description returns the Household Name for the list of Contacts
    * @param ContactList the list of Contacts in the same Household
    * @return string
    */
    public string getHHName(list<Contact> ContactList){
        if (ContactList == null)
            ContactList = new list<Contact>();
    	list<Contact> listCon = new list<Contact>();
    	for (Contact con : ContactList) {
            if (con.npo02__Naming_Exclusions__c == null || !con.npo02__Naming_Exclusions__c.contains('Name'))
                listCon.add(con);
    	}
        return namingService.getHouseholdName(listCon);
    }

    /*******************************************************************************************************
    * @description returns the Informal Greeting for the list of Contacts
    * @param ContactList the list of Contacts in the same Household
    * @return string
    */
    public  string getInformalName(list<Contact> ContactList){
        if (ContactList == null)
            ContactList = new list<Contact>();
        list<Contact> listCon = new list<Contact>();
        for (Contact con : ContactList) {
            if (con.npo02__Naming_Exclusions__c == null || !con.npo02__Naming_Exclusions__c.contains('Informal_Greeting__c'))
                listCon.add(con);
        }
        return namingService.getHouseholdInformalGreeting(listCon);
    }

    /*******************************************************************************************************
    * @description returns the Formal Greeting for the list of Contacts
    * @param ContactList the list of Contacts in the same Household
    * @return string
    */
    public  string getFormalName(list<Contact> ContactList){
        if (ContactList == null)
            ContactList = new list<Contact>();
        list<Contact> listCon = new list<Contact>();
        for (Contact con : ContactList) {
            if (con.npo02__Naming_Exclusions__c == null || !con.npo02__Naming_Exclusions__c.contains('Formal_Greeting__c'))
                listCon.add(con);
        }
        return namingService.getHouseholdFormalGreeting(listCon);
    }

    /*******************************************************************************************************
    * @description Returns Contact fields specified in the Household Naming Settings format fields.
    * @return Set<String> If the Automatic Household Naming is enabled, return set of Contact field API names; 
    * otherwise, an empty set
    */
    public Set<String> getHouseholdNamingContactFields() {

        if (!isAutomaticNaming()) {
            return new Set<String>();
        }

        Set<String> fieldNames = namingService.setHouseholdNameFieldsOnContact();
        return fieldNames == null ? new Set<String>() : fieldNames;
    }

    /*******************************************************************************************************
    * @description executes the batch job to update all household names
    * @param isActivation whether this is being called when npo02__Advanced_Household_Naming__c is being turned on
    * @return void
    */
    public static void refreshAllHouseholdNaming(boolean isActivation) {
        // the household batch expects a list of Contact's with just Id, LastName, HHId__c available.
        string strSoql = 'SELECT Id, LastName, ' + UTIL_Namespace.StrTokenNSPrefix('HHId__c') + ' FROM Contact WHERE ' +
            UTIL_Namespace.StrTokenNSPrefix('HHId__c') + ' != NULL ';
        HH_HouseholdNaming_BATCH batch = new HH_HouseholdNaming_BATCH(strSoql, isActivation);
        integer batchSize = 200;
        id batchProcessId = database.executeBatch(batch, batchSize);
    }

    /*******************************************************************************************************
    * @description list of all Contact fields for using in soql's
    */
    private static list<string> listStrContactFields {
        get {
            if (listStrContactFields == null) {
                Map<String, Schema.SObjectField> mapS = Schema.SObjectType.Contact.fields.getMap().clone();
                // due to a Salesforce bug, we get these new fields if our caller is api 30 or greater,
                // but we will hit an error if we soql for them since we are api 28.
                // this workaround will no longer be needed when we move up to version 30 or greater.
                mapS.remove('mailingaddress');
                mapS.remove('otheraddress');
                listStrContactFields = new list<string>();
                listStrContactFields.addAll(mapS.keySet());
            }
            return listStrContactFields;
        }
        set;
    }

    /*******************************************************************************************************
    * @description the soql select string to use which includes any fields we use or are referred to in
    * any of the naming specifications.
    */
    public string strContactSelectStmtAllNamingFields {
        get {
            if (strContactSelectStmtAllNamingFields == null) {
                //we use dynamic soql so we can include all contact fields, since custom naming may refer to any field.
                String[] selectFields = new String[]{
                        'Id', 'HHId__c', 'npo02__Naming_Exclusions__c'
                };
                selectFields.addAll(getHouseholdNamingContactFields());

                strContactSelectStmtAllNamingFields = new UTIL_Query()
                        .withSelectFields(selectFields)
                        .withToLabelSalutation()
                        .withFrom('Contact')
                        .build();
            }
            return strContactSelectStmtAllNamingFields;
        }
        private set;
    }

    String nameReplacementText = System.Label.npo02.NameReplacementText;
    public Boolean needsNamingFieldsUpdated(SObject h, SObject oldRecord) {
        if (h.get('Name') == nameReplacementText) {
            return true;
        } else if (h.get('npo02__Informal_Greeting__c') == nameReplacementText) {
            return true;
        } else if (h.get('npo02__Formal_Greeting__c') == nameReplacementText) {
            return true;
        } else if (isSystemCustomNamingChanged(h, oldRecord)) {
            return true;
        } else if (h.getSObjectType() == Account.sObjectType &&
                isOneToOneContactChanged(h, oldRecord)) {
            return true;
        }
        return false;
    }

    private Boolean isOneToOneContactChanged(SObject h, SObject oldRecord) {
        return h.get('npe01__One2OneContact__c') != oldRecord.get('npe01__One2OneContact__c');
    }

    private Boolean isSystemCustomNamingChanged(SObject h, SObject oldRecord) {
        return h.get('npo02__SYSTEM_CUSTOM_NAMING__c') !=
                oldRecord.get('npo02__SYSTEM_CUSTOM_NAMING__c');
    }

    public List<Id> getHouseholdsNeedingNameUpdates(List<SObject> records,
            Map<Id, SObject> oldMap) {
        List<Id> hhList = new List<Id>();
        for (SObject h : records) {
            if (needsNamingFieldsUpdated(h, oldMap.get(h.Id))) {
                hhList.add(h.Id);
            }
        }
        return hhList;
    }

    public void setHouseholdNameFields(List<SObject> records, Map<Id, SObject> oldMap) {
        for (SObject h : records) {
            SObject oldRecord = oldMap.get(h.Id);

            CustomFormat customName = new CustomFormat(h);

            if (isReplaceable(h, 'Name')) {
                customName.replace('Name;', ';');
                h.put('Name', nameReplacementText);
            } else if (isFieldValueChanged(h, 'Name', oldRecord)) {
                customName.append('Name');
            }

            if (isReplaceable(h, 'npo02__Informal_Greeting__c')) {
                customName.replace('Informal_Greeting__c;', ';');
                h.put('npo02__Informal_Greeting__c', nameReplacementText);
            } else if (isFieldValueChanged(h, 'npo02__Informal_Greeting__c', oldRecord)) {
                customName.append('Informal_Greeting__c');
            }

            if (isReplaceable(h, 'npo02__Formal_Greeting__c')) {
                customName.replace('Formal_Greeting__c;', ';');
                h.put('npo02__Formal_Greeting__c', nameReplacementText);
            } else if (isFieldValueChanged(h, 'npo02__Formal_Greeting__c', oldRecord)) {
                customName.append('Formal_Greeting__c');
            }

            h.put('npo02__SYSTEM_CUSTOM_NAMING__c', customName.value);
        }
    }

    private Boolean isFieldValueChanged(SObject h, String fieldApiName, SObject oldRecord) {
        return (String) h.get(fieldApiName) != oldRecord.get(fieldApiName);
    }

    private Boolean isReplaceable(SObject household, String fieldApiName) {
        String fieldValue = (String) household.get(fieldApiName);
        return fieldValue == null || fieldValue == '' || fieldValue == nameReplacementText;
    }

    private class CustomFormat {
        String value { get; private set; }
        Set<String> customNameSet {
            get {
                return new Set<String>(
                        new List<String>(
                                value.split(';')));
            }
        }
        public CustomFormat(SObject h) {
            this.value = getCustomName(h);
        }

        private String getCustomName(SObject h) {
            return h.get('npo02__SYSTEM_CUSTOM_NAMING__c') == null ? ';' :
                    h.get('npo02__SYSTEM_CUSTOM_NAMING__c') + ';';
        }

        public void replace(String searchVal, String newVal) {
            if (customNameSet.contains(searchVal)) {
                value = value.replace(searchVal, newVal);
            }
        }

        public void append(String val) {
            if (!customNameSet.contains(val)) {
                value += val + ';';
            }
        }

        public Boolean contains(String val) {
            return this.customNameSet.contains(val);
        }
    }

    npo02__Households_Settings__c hs = UTIL_CustomSettingsFacade.getHouseholdsSettings();
    public Boolean isAdvancedHouseholdNaming() {
        return hs != null && hs.npo02__Advanced_Household_Naming__c == true;
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

        if (accountIds.size() == 1 || System.isFuture() || System.isBatch() || System.isQueueable()) {
            HH_HouseholdNaming hhName = new HH_HouseholdNaming();
            hhName.UpdateNames(accountIds);
        } else {
            HH_HouseholdNaming.FutureUpdateNames(accountIds);
        }
    }
}