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

    HouseholdSettings settings = new HouseholdSettings();
    String nameReplacementText = System.Label.npo02.NameReplacementText;

    /*******************************************************************************************************
    * @description future method to update the household names for the specified households
    * @param hhids the list of household Id's (either Household__c or Account Id's)
    * @return void
    */
    @future
    public static void FutureUpdateNames(List<Id> hhids){
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
    public void UpdateNames(List<Id> hhids){

        // Skip automatic naming during Batch Data Import to improve performance
        if (isHouseholdNamingDisabled) {
            return;
        }

        //we need this turned on to prevent recursive triggering on household creation
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.HH, true);

        // handle two types of households by using an SObject
        List<SObject> householdsNeedingUpdates = getHouseholdsNeedingUpdates(hhids);
        Map<Id, List<Contact>> hhIdToContactsMap = getHhIDContactMap(hhids);

        //loop through the households needing name changes, if necessary, make them.
        for (SObject h : householdsNeedingUpdates) {
            List<Contact> listCon = getContactsForHousehold(h, hhIdToContactsMap);

            if (settings.isAdvancedHouseholdNaming()) {
                new HouseholdName(h, listCon)
                        .setNameFieldValuesOnHousehold();
            }

            // now we also store the number of members on the Household!
            h.put(UTIL_Namespace.StrTokenNSPrefix('Number_of_Household_Members__c'),
                    listCon != null ? listCon.size() : 0);
        }

        if (!householdsNeedingUpdates.isEmpty()) {
            // all or nothing, so errors not lost
            UTIL_DMLService.updateRecords(householdsNeedingUpdates);
        }

        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.HH, false);
    }

    private Map<Id, List<Contact>> getHhIDContactMap(List<Id> hhids) {
        return getHhIDContactMap(getHouseholdContacts(hhids));
    }

    private List<SObject> getHouseholdsNeedingUpdates(List<Id> hhids) {
        List<SObject> hhupdatelist = new List<SObject>();
        hhupdatelist.addAll(getListHHObj(hhids));
        hhupdatelist.addAll(getListHHAcct(hhids));
        return hhupdatelist;
    }

    private List<SObject> getListHHAcct(List<Id> hhids) {
        List<SObject> listHHAcct = [
                SELECT Id, Name, npo02__SYSTEM_CUSTOM_NAMING__c
                FROM Account
                WHERE Id IN :hhids
        ];
        return listHHAcct;
    }

    private List<SObject> getListHHObj(List<Id> hhids) {
        List<SObject> listHHObj = [
                SELECT Id, Name, npo02__SYSTEM_CUSTOM_NAMING__c
                FROM Npo02__Household__c
                WHERE Id IN :hhids
        ];
        return listHHObj;
    }

    private List<Contact> getContactsForHousehold(SObject h, Map<Id, List<Contact>> hhIDContactMap) {
        Id hhId = String.valueOf(h.get('Id'));
        List<Contact> listCon = hhIDContactMap.get(hhId);
        return listCon;
    }

    private Map<Id, List<Contact>> getHhIDContactMap(List<Contact> contactlist) {
        Map<Id, List<Contact>> hhIDContactMap = new Map<Id, List<Contact>>();
        for (Contact c : contactlist) {
            if (!hhIDContactMap.containskey(c.hhId__c)) {
                hhIDContactMap.put(c.hhId__c, new List<Contact>{
                        c
                });
            } else {
                List<Contact> clist = hhIDContactMap.get(c.hhId__c);
                clist.add(c);
            }
        }
        return hhIDContactMap;
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
        String strSoql = strContactSelectStmtAllNamingFields;
        String strHHId = UTIL_Namespace.StrTokenNSPrefix('HHId__c');

        strSoql += ' WHERE AccountId IN :queryHHIds OR npo02__Household__c IN :queryHHIds ' +
                ' ORDER BY ' + strHHId + ', npo02__Household_Naming_Order__c ASC NULLS LAST, Primary_Contact__c DESC, CreatedDate ';

        return Database.Query(strSoql);
    }


    /*******************************************************************************************************
    * @description turns off household naming in the current execution context.  provided for other
    * components, like Batch Data Import, to momentarily turn off the household naming logic.  there is no
    * direct way to do that by disabling TDTM trigger handlers, or using existing static flags.
    * @param disable True to disable, False to enable
    * @return void
    */
    public static void disableHouseholdNaming(Boolean disable) {
        isHouseholdNamingDisabled = disable;
    }
    private static Boolean isHouseholdNamingDisabled = false;

    /*******************************************************************************************************
    * @description Returns Contact fields specified in the Household Naming Settings format fields.
    * @return Set<String> If the Automatic Household Naming is enabled, return set of Contact field API names;
    * otherwise, an empty set
    */
    public Set<String> getHouseholdNamingContactFields() {
        if (!settings.isAdvancedHouseholdNaming()
                || namingService.setHouseholdNameFieldsOnContact() == null) {
            return new Set<String>();
        } else {
            return namingService.setHouseholdNameFieldsOnContact();
        }
    }

    /*******************************************************************************************************
    * @description the class object that supports the HH_INaming interface
    */
    HH_INaming namingService {
        get {
            if (namingService == null) {
                String implementingClass = new HouseholdSettings().getImplementingClass();

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
        Integer batchSize = 200;
        Id batchProcessId = database.executeBatch(batch, batchSize);
    }

    /*******************************************************************************************************
    * @description the soql select String to use which includes any fields we use or are referred to in
    * any of the naming specifications.
    */
    public String strContactSelectStmtAllNamingFields {
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
        List<Id> ids = new List<Id>();
        for (SObject sobj : records) {
            ids.add(sobj.Id);
        }
        Map<Id, List<Contact>> contactsByHouseholdId =
                getHhIDContactMap(ids);

        for (SObject h : records) {
            SObject oldRecord = oldMap.get(h.Id);
            HouseholdName householdName = new HouseholdName(h, oldRecord,
                    contactsByHouseholdId.get(h.Id), namingService);
            householdName.processReplacementText();
            h.put('npo02__SYSTEM_CUSTOM_NAMING__c', householdName.customNameString);
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

        if (accountIds.size() == 1 || System.isFuture() || System.isBatch() || System.isQueueable()) {
            HH_HouseholdNaming hhName = new HH_HouseholdNaming();
            hhName.UpdateNames(accountIds);
        } else {
            HH_HouseholdNaming.FutureUpdateNames(accountIds);
        }
    }
}