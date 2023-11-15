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
* @date 2016
* @group Households
* @group-content ../../ApexDocContent/Households.htm
* @description Lightning Component Server Controller for the Manage Household UI page's HH_Container LC.
*/
public with sharing class HH_Container_LCTRL {

    /** @description our exception object for Field Level & Object Security errors. */
    private class permsException extends Exception {}

    private static final String accountObject = Schema.SObjectType.Account.getName();
    private static final String contactObject = Schema.SObjectType.Contact.getName();
    private static final String addressObject = Schema.SObjectType.Address__c.getName();
    private static final String undeliverableField = UTIL_Namespace.StrTokenNSPrefix('Undeliverable__c');
    private static final String undeliverableAddressField = UTIL_Namespace.StrTokenNSPrefix('Undeliverable_Address__c');

    private static Boolean canReadContactUndeliverable = 
        UTIL_Permissions.canRead(contactObject, undeliverableAddressField, false);
    private static Boolean canReadAccountUndeliverable = 
        UTIL_Permissions.canRead(accountObject, undeliverableAddressField, false);
    private static Boolean canUpdateAddressUndeliverable = 
        UTIL_Permissions.canRead(addressObject, undeliverableField, false)
            && UTIL_Permissions.canUpdate(addressObject, undeliverableField, false);
    private static Boolean selectedAddressIsUndeliverable = false;

    /*******************************************************************************************************
    * @description trick the packaging spider to pickup references to custom labels only used by our
    * lightning components.
    */
    public static void packageLabels() {
        String str;
        str = Label.lblAddressOverride;
        str = Label.lblCCardExcludeFrom;
        str = Label.lblHouseholdName;
        str = Label.lblFormalGreeting;
        str = Label.lblInformalGreeting;
        str = Label.lblHousehold;
        str = Label.lblDeleteContact;
        str = Label.lblDeleteContactPrompt;
        str = Label.lblStreet;
        str = Label.lblCity;
        str = Label.lblState;
        str = Label.lblPostalCode;
        str = Label.lblCountry;
        str = Label.lblSalutation;
        str = Label.lblFirstName;
        str = Label.lblLastName;
        str = Label.stgBtnCancel;
        str = Label.stgBtnSave;
        str = Label.bdiBtnClose;
        str = Label.lblMergeHHTitle;
        str = Label.lblMergeHHPrompt;
        str = Label.lblBtnAddContact;
        str = Label.lblBtnAddAllHHMembers;
        str = Label.lblFindOrAddContact;
        str = Label.lblFindInContacts;
        str = Label.lblNoHHMergePermissions;
        str = Label.btnRemove;
    }

    /*******************************************************************************************************
    * @description returns the Household object (Account or Custom Object) given the Id
    * @param householdId The Household's Id
    * @return SObject The Household Account or Custom Object
    */
    @AuraEnabled
    public static SObject getHousehold(Id householdId) {
        try {
            if (householdId == null) {
                return null;
            }
            Boolean isHousehold = UTIL_Describe.isObjectIdThisType(householdId, 'Account');
            String soqlFromObject = getHouseholdObjectToUseForQuery(isHousehold);

            UTIL_Query query = new UTIL_Query()
                .withSelectFields(getHouseholdSelectFields(isHousehold, soqlFromObject))
                .withFrom(soqlFromObject)
                .withWhere('Id = :householdId');
            return Database.query(query.build());

        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    private static String getHouseholdObjectToUseForQuery(Boolean isHousehold) {
        return String.valueOf(isHousehold ? Account.SObjectType : npo02__Household__c.SObjectType);
    }

    private static Set<String> getHouseholdSelectFields(Boolean isHousehold, String soqlFromObject) {
        Set<String> householdSelectFields = new Set<String>();
        householdSelectFields.addAll(getHouseholdFieldsToEdit(isHousehold, soqlFromObject));

        return householdSelectFields;
    }

    /*******************************************************************************************************
    * @description returns a list of Fields (developer name) that must be editable on the Household
    * @return Set<String> the set of Fields
    */
    private static Set<String> getHouseholdFieldsToEdit(Boolean isHousehold, String soqlFromObject) {
        Set<String> householdFieldsToEdit = new Set<String>{
            'Name',
            'npo02__SYSTEM_CUSTOM_NAMING__c', 
            'npo02__Formal_Greeting__c', 
            'npo02__Informal_Greeting__c',
            UTIL_Namespace.StrTokenNSPrefix('Number_of_Household_Members__c')};

        if (isHousehold) {
            householdFieldsToEdit.addAll(new Set<String>{
                'BillingStreet', 'BillingCity', 'BillingState', 'BillingPostalCode',
                'BillingCountry', 'BillingLatitude', 'BillingLongitude'});
            if (canReadAccountUndeliverable) {
                householdFieldsToEdit.add(undeliverableAddressField);
            }
        } else {
            householdFieldsToEdit.addAll(new Set<String>{
                'npo02__MailingStreet__c', 'npo02__MailingCity__c', 'npo02__MailingState__c', 
                'npo02__MailingPostalCode__c', 'npo02__MailingCountry__c'});
        }
        // check field level security and construct our soql
        checkFieldPermissions(householdFieldsToEdit, soqlFromObject);
        return householdFieldsToEdit;
    }

    private static void checkFieldPermissions(Set<String> householdFieldsToEdit, String account) {
        for (String householdField : householdFieldsToEdit) {
            DescribeFieldResult dfr = UTIL_Describe.getFieldDescribe(account, householdField);
            if (dfr == null || !dfr.isAccessible() || !dfr.isUpdateable()) {
                throw (new permsException(String.format(Label.flsError, new String[]{
                        account + '.' + householdField
                })));
            }
        }
    }

    /*******************************************************************************************************
    * @description returns the Contacts for the given Household
    * @param householdId The Household's Id
    * @return list<Contact> The Contacts in the Household
    */
    @AuraEnabled
    public static List<Contact> getContacts(Id householdId) {
        try {
            if (householdId == null) {
                return null;
            }
            // conSelect does the FLS check
            String strSoql = getContactSelectQueryWithFls();

            // don't use contact.HHId in one soql since it can't use an index
            // and won't work in LDV orgs.
            if (UTIL_Describe.isObjectIdThisType(householdId, 'Account')) {
                strSoql += ' where AccountId = :householdId ';
            } else {
                strSoql += ' where npo02__Household__c = :householdId WITH SECURITY_ENFORCED ';
            }

            strSoql += ' order by npo02__Household_Naming_Order__c ASC NULLS LAST, ' +
                'Primary_Contact__c DESC, CreatedDate ';

            List<Contact> listCon = Database.query(strSoql);
            // let's update household naming order so the client doesn't have to worry about nulls.
            for (Integer i = 0; i < listCon.size(); i++) {
                listCon[i].npo02__Household_Naming_Order__c = i;
            }
            return listCon;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /*******************************************************************************************************
    * @description returns the soql string to use to query contacts and their appropriate fields, and ensures
    * field level security that the user has permissions to read and modify those fields.
    * @return String The soql select string to use for Contacts
    */
    public static String getContactSelectQueryWithFls() {
        //we use dynamic soql so we can include all contact fields, since custom naming may refer to any field.
        Set<String> selectFields = getContactFields();
        Set<String> setCheckUpdate = setUpdateableContactFields();
        
        for (String strF : selectFields) {

            if (!strF.contains('.')) {
                // check field level security (but not on compound lookup fields)
                DescribeFieldResult dfr = UTIL_Describe.getFieldDescribe('Contact', strF);
                if (dfr == null || !dfr.isAccessible() || ((setCheckUpdate.contains(strF) && !dfr.isUpdateable()))) {
                    throw (new permsException(String.format(Label.flsError, new String[]{'Contact' + '.' + strF})));
                }

            }
        }
        // add a few fields we need for contact merge and standard code that
        // we don't have these in our set of fields, because we want to avoid FLS on them,
        // since we want to support both HH Accounts and Objects, but we expect customers might
        // only grant permissions on the model they are currently using, but we may have data in both models.
        // the find autocomplete lookup also uses this code, so it needs to see both types of households.
        selectFields.add('npo02__Household__c'); 
        selectFields.add('Account.Number_of_Household_Members__c');
        selectFields.add('npo02__Household__r.Number_of_Household_Members__c');
        selectFields.add('Account.Name');
        selectFields.add('npo02__Household__r.Name');

        return new UTIL_Query()
            .withSelectFields(selectFields)
            .withFrom('Contact')
            .build();
    }

    /*******************************************************************************************************
    * @description Returns Contact Fields (developer name)
    * @return Set<String> Set of Contact Fields
    */
    @TestVisible
    private static Set<String> getContactFields() {
        try {
            Set<String> contactFields = new Set<String>{
                'Id', 
                'npo02__Household_Naming_Order__c', 
                'FirstName', 
                'LastName', 
                'Salutation', 
                'Name',
                'npo02__Naming_Exclusions__c', 
                'AccountId', 
                UTIL_Namespace.StrTokenNSPrefix('HHId__c'),
                UTIL_Namespace.StrTokenNSPrefix('Exclude_from_Household_Name__c'), 
                UTIL_Namespace.StrTokenNSPrefix('Exclude_from_Household_Formal_Greeting__c'), 
                UTIL_Namespace.StrTokenNSPrefix('Exclude_from_Household_Informal_Greeting__c'),
                UTIL_Namespace.StrTokenNSPrefix('is_Address_Override__c'), 
                UTIL_Namespace.StrTokenNSPrefix('Current_Address__c'), 
                'npe01__Primary_Address_Type__c',
                'MailingStreet', 
                'MailingCity', 
                'MailingState', 
                'MailingPostalCode', 
                'MailingCountry', 
                'MailingLatitude', 
                'MailingLongitude', 
                'CreatedDate'
            };

            addContactMiddleNameField(contactFields);
            addContactUndeliverableAddressField(contactFields);

                /*** until we support these, we don't want them to interfere with what the user specifies.
                if (OrgSettings.isStateCountryPicklistsEnabled)
                    strSoql += ', MailingCountryCode, MailingStateCode ';
                ******/
            
            contactFields.addAll(new HouseholdNamingService().getHouseholdNamingContactFields());

            return contactFields;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }


    /*******************************************************************************************************
    * @description returns a set of Contact Fields (developer name) that must be editable
    * @return set<String> the set of Contact Fields
    */
    private static Set<String> setUpdateableContactFields() {
        Set<String> setContactFields = new Set<String>{
            'AccountId',
            'FirstName',
            'LastName',
            'Salutation',
            'npo02__Household_Naming_Order__c', 
            'npo02__Naming_Exclusions__c', 
            UTIL_Namespace.StrTokenNSPrefix('Exclude_from_Household_Name__c'), 
            UTIL_Namespace.StrTokenNSPrefix('Exclude_from_Household_Formal_Greeting__c'), 
            UTIL_Namespace.StrTokenNSPrefix('Exclude_from_Household_Informal_Greeting__c'),
            'MailingStreet', 
            'MailingCity', 
            'MailingState',
            'MailingPostalCode', 
            'MailingCountry', 
            'MailingLatitude', 
            'MailingLongitude'
        };

        addContactMiddleNameField(setContactFields);
        addContactUndeliverableAddressField(setContactFields);

        return setContactFields;
    }

    /*******************************************************************************************************
    * @description Adds Undeliverable Address field into the set of field names
    * @param fieldNames Set of field names 
    * @return void
    */
    private static void addContactUndeliverableAddressField(Set<String> fieldNames) {   
        if (canUpdateAddressUndeliverable && canReadContactUndeliverable) {
            fieldNames.add(undeliverableAddressField);
        }
    }

    /*******************************************************************************************************
    * @description Adds MiddleName field into the set of field names
    * @param fieldNames Set of field names 
    * @return void
    */
    private static void addContactMiddleNameField(Set<String> fieldNames) {        
        if (UTIL_Describe.isMiddleNameEnabled()) {
            fieldNames.add('MiddleName');
        }        
    }

    /*******************************************************************************************************
    * @description checks whether the user has delete permissions on the specified object
    * @param strSObject the object
    * @return Boolean whether the object can be deleted
    */
    @AuraEnabled
    public static Boolean isDeletable(String strSObject) {
        try {
            // Check object permissions
            Schema.DescribeSObjectResult dresult = UTIL_Describe.getObjectDescribe(strSObject);
            return dresult.isDeletable();
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    /*******************************************************************************************************
    * @description saves any changes to the Contacts in the database
    * @param listCon The list of Contacts to save
    * @return void
    */
    @TestVisible
    private static void upsertContacts(List<Contact> listCon) {
        // Even though we are given a list of Contacts from the lightning component,
        // apex seems to treat them as generic sObjects, and thus we can't do upsert.
        // thus we will split the list into update and insert lists.
        List<Contact> listInsert = new List<Contact>();
        List<Contact> listUpdate = new List<Contact>();
        List<String> listStrFld = new List<String>(setUpdateableContactFields());
        
        Savepoint sp = Database.setSavepoint(); 
        try {
            // check object permissions
            if (!Contact.SObjectType.getDescribe().isCreateable() || !Contact.SObjectType.getDescribe().isUpdateable()) {
                 throw new System.NoAccessException();    
            }
            
            for (Contact con : listCon) {
                Contact con2 = new Contact(Id=con.Id);
                // do FLS and only copy the fields we allow to be touched in our UI
                UTIL_Describe.copyObjectFLS('Contact', con, con2, listStrFld);
                // Due to the complexity of working in both the Household and Account Household models,
                // we need to skip the security check on the Household field.
                con2.npo02__Household__c = con.npo02__Household__c;
                // To perform data syncing, we need to skip the security check on Undeliverable Address
                // We only want to do this for Contacts without Address Override that are still part of the Household
                if (!con2.is_Address_Override__c && con2.AccountId != null) {
                    con2.Undeliverable_Address__c = selectedAddressIsUndeliverable;
                }
                if (con.Id != null) {
                    listUpdate.add(con2);
                } else {
                    listInsert.add(con2);
                }
            }
            
            // avoid saving of contacts from updating household names
            // to avoid record lock errors.  let the household be responsible
            // for updating its name.
            TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.HH, true);
            
            // allow potential duplicates when rules to warn are turned on.
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.duplicateRuleHeader.allowSave = true;
            List<Database.SaveResult> listSR = UTIL_DMLService.insertRecords(listInsert, dml);
            for (Database.SaveResult sr : listSR) {
                if (!sr.isSuccess()) {
                    throw new DmlException(sr.getErrors()[0].getMessage());
                }
            }

            UTIL_DMLService.updateRecords(listUpdate);

        } catch (Exception ex) {
            Database.rollback(sp);

            throw new AuraHandledException(ex.getMessage());

        } finally {
            TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.HH, false);
        }
    }

    /*******************************************************************************************************
    * @description saves any changes to the Household in the database
    * @param hh The Household
    * @return void
    */
    @TestVisible
    private static void updateHousehold(SObject hh) {
        try {
            // Check object permissions
            Boolean isHHAccount = UTIL_Describe.isObjectIdThisType(hh.Id, 'Account');
            String strObject;
            SObject hhCopy;
            if (isHHAccount) {
                strObject = 'Account';
                hhCopy = new Account(Id=hh.Id);
                if (!Account.SObjectType.getDescribe().isUpdateable()) {
                    throw new System.NoAccessException(); 
                }
            } else {
                strObject = 'npo02__Household__c';
                hhCopy = new npo02__Household__c(Id=hh.Id);
                if (!npo02__Household__c.SObjectType.getDescribe().isUpdateable()) {
                    throw new System.NoAccessException(); 
                }
            }
            
            // do FLS and only copy the fields we allow to be touched in our UI
            Set<String> householdFieldsToEdit = getHouseholdFieldsToEdit(isHHAccount, strObject);
            UTIL_Describe.copyObjectFLS(strObject, hh, hhCopy, new List<String>(householdFieldsToEdit));

            // Update Undeliverable field on Account to ensure correct syncing
            if (isHHAccount) {
                hhCopy.put(undeliverableAddressField, selectedAddressIsUndeliverable);
            }
            // we've already saved the data for the contacts in the household.
            // now we only need to save the account fields an update, and we don't want
            // any of the normal account trigger work to run again.  specifically,
            // we may have updated the names and greetings, because the contacts have changed,
            // but the user still may want auto-naming turned on.  our normal trigger flow
            // would think the user updated the name from what it was, and thus it should be
            // excluded from auto-naming!
            TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.HH, true);
            UTIL_DMLService.updateRecord(hhCopy);

        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
            
        } finally {
            TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.HH, false);
        }
    }

    /*******************************************************************************************************
    * @description merge the list of household Accounts into the winning household
    * @param hh The winning Household
    * @param listHHMerge the list of Households to merge into the winner
    * @return void
    */
    @TestVisible
    private static void mergeHouseholds(Account hhWinner, List<Account> listHHMerge) {
        try {
            // Check object permissions
            if (!Account.SObjectType.getDescribe().isMergeable()) {
                    throw new System.NoAccessException(); 
               }

            for (Account loser : listHHMerge) {
                merge hhWinner loser;
            }
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /*******************************************************************************************************
    * @description saves all changes from the Manage Household UI page to the database
    * @param hh The Household
    * @param listCon The list of Contacts to save (update and insert)
    * @param listConRemove The list of Contacts to remove from the household
    * @param listHHMerge the list of Households to merge into the winner
    */
    @AuraEnabled
    public static void saveHouseholdPage(SObject hh, List<Contact> listCon, List<Contact> listConRemove, List<Account>listHHMerge) {
        try {
            // We need to determine if the new Default Address is Undeliverable
            Address__c defaultAddress = getAddressFromAccount(hh.Id, hh);
            defaultAddress.Household_Account__c = hh.Id;

            if (!canReadAddress()) {
                throw new UTIL_Permissions.InsufficientPermissionException(System.Label.commonAccessErrorMessage);
            }
            Map<Address__c, Address__c> addressMatch = Addresses.getExistingAddresses(new List<Address__c>{
                    defaultAddress
            });
            if (addressMatch.containsKey(defaultAddress) && addressMatch.get(defaultAddress) != null) {
                selectedAddressIsUndeliverable = addressMatch.get(defaultAddress)?.Undeliverable__c;
            }

            updateHousehold(hh);

            // need to merge any households (Accounts only) before we save contacts
            // so we avoid deleting a household if that contact was the last one in the hh.
            if (isNotEmpty(listHHMerge)) {
                mergeHouseholds((Account) hh, listHHMerge);
                updateWinnerHouseholdSustainerAfterMerge((Account) hh);
            }

            List<Contact> contacts = new List<Contact>(listCon);
            contacts.addAll(listConRemove);
            upsertContacts(contacts);

            if (isNotEmpty(listHHMerge)) {
                cleanupAddresses(new List<Id>{
                        (Id) hh.get('Id')
                });
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static Boolean canReadAddress() {
        if (Test.isRunningTest()) {
            return true;
        }

        Set<String> addressFields = new Set<String>{
                'Default_Address__c',
                'Household_Account__c',
                'Address_Type__c',
                'MailingStreet__c',
                'MailingStreet2__c',
                'MailingCity__c',
                'MailingState__c',
                'MailingPostalCode__c',
                'MailingCountry__c',
                'Seasonal_Start_Month__c',
                'Seasonal_Start_Day__c',
                'Seasonal_End_Month__c',
                'Seasonal_End_Day__c',
                'Geolocation__Latitude__s',
                'Geolocation__Longitude__s'
        };

        for (String addressField : addressFields) {
            if (!UTIL_Permissions.canRead(UTIL_Namespace.StrAllNSPrefix('Address__c'),
                    UTIL_Namespace.StrAllNSPrefix(addressField), false)) {
                return false;
            }
        }

        return true;
    }

    private static void updateWinnerHouseholdSustainerAfterMerge(Account winnerHousehold) {
        DescribeFieldResult sustainerFieldDescribeResult = Account.Sustainer__c.getDescribe();

        if (UTIL_Permissions.canRead(sustainerFieldDescribeResult, false)
            && UTIL_Permissions.canUpdate(sustainerFieldDescribeResult, false)
        ) {
            List<Account> winnerWithSustainerChanged = new RD2_SustainerEvaluationService()
            .withAccounts(new List<Account>{winnerHousehold})
            .getAccountsWithSustainerChanged();

            if (winnerWithSustainerChanged.size() != 0) {
                RD2_SustainerEvaluationService.setSustainerUpdateEnabled(true);
                UTIL_DMLService.updateRecords(winnerWithSustainerChanged);
                RD2_SustainerEvaluationService.setSustainerUpdateEnabled(false);
            }
        }
    }

    /*******************************************************************************************************
    * @description Checks if the Account list is not empty
    * @param accounts The list of Accounts
    * @return Boolean True is the list is not empty, false if the list is null or empty
    */
    private static Boolean isNotEmpty(List<Account> accounts) {
        return accounts != null && !accounts.isEmpty();
    }

    /*******************************************************************************************************
    * @description Cleans up/refreshes the Addresses for specified Account Ids
    * @param accountIds List of Account Ids
    */
    private static void cleanupAddresses(List<Id> accountIds) {
        Id[] cleanupAccountIds = new Id[0];
        
        for (Account acc : [SELECT npe01__SYSTEM_AccountType__c FROM Account WHERE Id IN :accountIds]) {
            if (isHouseholdOrOrganization(acc)) {
                cleanupAccountIds.add(acc.Id);
            }           
        }

        Addresses.cleanupAccountAddresses(cleanupAccountIds);
    }

    @AuraEnabled
    public static Map<String, String> getFieldLabels() {
        Map<String, String> fieldLabelsBySObject = new Map<String, String> {
            undeliverableAddressField => UTIL_Describe.getFieldLabel(contactObject, undeliverableAddressField),
            undeliverableField => UTIL_Describe.getFieldLabel(addressObject, undeliverableField)
        };

        return fieldLabelsBySObject;
    }

    /*******************************************************************************************************
    * @description Verifies the Account Type
    * @param acc An Account
    * @return Boolean True if the Account Type is Household Account or another type 
    * except One-to-One Individual and Bucket Individual Account types
    */
    private static Boolean isHouseholdOrOrganization(Account acc) {
        return acc.npe01__SYSTEM_AccountType__c == CAO_Constants.HH_ACCOUNT_TYPE ||
            (
                acc.npe01__SYSTEM_AccountType__c != CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE &&
                acc.npe01__SYSTEM_AccountType__c != CAO_Constants.BUCKET_ORGANIZATION_TYPE
            );
    } 

    /*******************************************************************************************************
    * @description sets the Household Name and Greetings on the Household object, given the list of Contacts
    * @param hh The Household Object (Account or Custom Object) to set the names on
    * @param listCon The list of Contacts to use
    * @return SObject the Household object
    */
    @AuraEnabled
    public static SObject getHHNamesGreetings(SObject hh, List<Contact> listCon) {
        try {
            // update naming exclusions field based on exclusion checkboxes
            NamingExclusions namingExclusions = new NamingExclusions(listCon);
            namingExclusions.synchronize();

            HouseholdSettings householdSettings = new HouseholdSettings();
            if (!householdSettings.isAdvancedHouseholdNaming()) {
                return hh;
            }

            HouseholdNamingService householdNamingService = new HouseholdNamingService();
            householdNamingService.setNameFieldValuesOnHousehold(
                    hh,
                    new HouseholdName(new HouseholdMembers(listCon)));

            return hh;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /*******************************************************************************************************
    * @description Return an Address record with fields copied from the Account
    * @param householdId The Household Id
    * @param household An SObject representing the Household
    * @return Address__c
    */
    private static Address__c getAddressFromAccount(Id householdId, SObject household) {
        Address__c address = new Address__c();
        if (UTIL_Describe.isObjectIdThisType(householdId, 'Account')) {
            // can't use our utility routine, because we specifically are not querying for StateCode & CountryCode
            // to avoid those saved codes from interfering with the user's changes (that won't include the codes)
            //Addresses.copyAddressStdSObjAddr(household, 'Billing', address, null);
            address.MailingStreet__c = (String)household.get('BillingStreet');
            Addresses.handleMultilineStreet(address);
            address.MailingCity__c = (String)household.get('BillingCity');
            address.MailingState__c = (String)household.get('BillingState');
            address.MailingPostalCode__c = (String)household.get('BillingPostalCode');
            address.MailingCountry__c = (String)household.get('BillingCountry');
            if (canUpdateAddressUndeliverable && canReadAccountUndeliverable) {
                address.Undeliverable__c = (Boolean)household.get(undeliverableAddressField);
            }
        } else {
            address.MailingStreet__c = (String)household.get('npo02__MailingStreet__c');
            address.MailingCity__c = (String)household.get('npo02__MailingCity__c');
            address.MailingState__c = (String)household.get('npo02__MailingState__c');
            address.MailingPostalCode__c = (String)household.get('npo02__MailingPostalCode__c');
            address.MailingCountry__c = (String)household.get('npo02__MailingCountry__c');
        }
        return address;
    }

    /*******************************************************************************************************
    * @description returns the Addresses for the given Household.  note that it returns Address objects,
    * even when dealing with Household Objects (in which case it creates in memory address objects for each
    * contact's mailing address).
    * @param householdId The Household's Id
    * @param existingAddresses the list of existing addresses
    * @return list<Address__c> The addresses in the household and contacts
    */
    @AuraEnabled
    public static List<Address__c> getAddresses(Id householdId, List<Address__c> existingAddresses) {
        try {
            if (householdId == null) {
                return null;
            }

            // keep unique list of addresses in temp Address objects
            List<Address__c> listAddr = new List<Address__c>();
            Set<String> setAddrKey = new Set<String>();

            // if they provide existing addresses, do our initialization
            if (existingAddresses != null) {
                for (Address__c address : existingAddresses) {
                    listAddr.add(address);
                    NPSP_Address npspAddress = new NPSP_Address(address);
                    setAddrKey.add(npspAddress.getAddrKey());
                }
            }

            // load our Household and Contacts
            // CONSIDER: since the client also loads the household and contacts, we could
            // put in a static cache to avoid requerying if they are already loaded.
            // ie, track a static household and with householdId it came from, and use it in getHH()
            // if the householdId matches.  Same with listCon.
            SObject household = getHousehold(householdId);
            List<Contact> listCon = getContacts(householdId);
            Address__c defaultAddress;

            // copy the household's address
            Address__c address = getAddressFromAccount(householdId, household);

            if (existingAddresses == null || existingAddresses.size() == 0) {
                address.Default_Address__c = true;
                defaultAddress = address;
            }  // the HH address is the default.
            String strKey = new NPSP_Address(address).getAddrKey();
            if (setAddrKey.add(strKey)) {
                listAddr.add(address);
            }

            // copy the contacts' addresses
            for (Contact con : listCon) {
                address = new Address__c();
                // can't use our utility routine, because we specifically are not querying for StateCode & CountryCode
                // to avoid those saved codes from interfering with the user's changes (that won't include the codes)
                //Addresses.copyAddressStdSObjAddr(con, 'Mailing', address, null);
                address.MailingStreet__c = con.MailingStreet;
                Addresses.handleMultilineStreet(address);
                address.MailingCity__c = con.MailingCity;
                address.MailingState__c = con.MailingState;
                address.MailingPostalCode__c = con.MailingPostalCode;
                address.MailingCountry__c = con.MailingCountry;
                if (canUpdateAddressUndeliverable && canReadContactUndeliverable) {
                    address.Undeliverable__c = con.Undeliverable_Address__c;
                }
                strKey = new NPSP_Address(address).getAddrKey();
                if (setAddrKey.add(strKey)) {
                    listAddr.add(address);
                }
            }

            // copy any address objects
            if (UTIL_Describe.isObjectIdThisType(householdId, 'Account')) {

                Set<String> setFields = new Set<String>{'MailingStreet__c', 'MailingStreet2__c',
                        'MailingCity__c', 'MailingState__c', 'MailingPostalCode__c', 
                        'MailingCountry__c', 'Default_Address__c'};
                if (canUpdateAddressUndeliverable) {
                    setFields.add('Undeliverable__c');
                }
                String strSoql = 'select ';
                String strComma = '';
                
                for (String strF : setFields) {
                    // check field level security
                    DescribeFieldResult dfr = UTIL_Describe.getFieldDescribe(addressObject, UTIL_Namespace.StrTokenNSPrefix(strF));
                    if (dfr == null || !dfr.isAccessible()) {
                        throw (new permsException(String.format(Label.flsError, new string[]{
                                'Address__c' + '.' + strF
                        })));
                    }
                    
                    strSoql += strComma + strF;
                    strComma = ',';
                }
                strSoql += ' from Address__c where Household_Account__c = :householdId';
                List<Address__c> listAddrHH = Database.query(strSoql);
                for (Address__c addrT : listAddrHH) {
                    // init other values we don't want to query for that the key might use.
                    addrT.Seasonal_Start_Day__c = null;
                    addrT.Seasonal_Start_Month__c = null;
                    addrT.Seasonal_End_Day__c = null;
                    addrT.Seasonal_End_Month__c = null;
                    addrT.Address_Type__c = null;
                    strKey = new NPSP_Address(addrT).getAddrKey();
                    if (setAddrKey.add(strKey)) {
                        listAddr.add(addrT);
                    } else if (defaultAddress != null && canUpdateAddressUndeliverable && addrT.Default_Address__c) {
                        // Since the Default address was set via the Household, we need to update it
                        // directly in case the User only has access to the Address Undeliverable field
                        defaultAddress.Undeliverable__c = addrT.Undeliverable__c;
                    }
                }
            }

            return listAddr;
        } catch (AuraHandledException aex) {
            throw aex;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /*******************************************************************************************************
    * @description adds the Contact's addresses to the provided list, ensuring uniqueness. note that it returns Address objects,
    * even when dealing with Household Objects (in which case it creates in memory address objects for each
    * contact's mailing address).
    * @param listCon the list of Contacts
    * @param listAddrExisting the list of existing addresses
    * @return list<Address__c> The addresses in the household and contacts
    */
    @AuraEnabled
    public static List<Address__c> addContactAddresses(List<Contact> listCon, List<Address__c> listAddrExisting) {
        try {
            if (listCon == null) {
                return null;
            }

            // keep unique list of addresses in temp Address objects
            List<Address__c> listAddr = new List<Address__c>();
            Set<String> setAddrKey = new Set<String>();

            // if they provide existing addresses, do our initialization
            if (listAddrExisting != null) {
                for (Address__c addr : listAddrExisting) {
                    listAddr.add(addr);
                    setAddrKey.add(new NPSP_Address(addr).getAddrKey());
                }
            }

            // copy the contacts' addresses
            for (Contact con : listCon) {
                Address__c addr = new Address__c();
                // can't use our utility routine, because we specifically are not querying for StateCode & CountryCode
                // to avoid those saved codes from interfering with the user's changes (that won't include the codes)
                //Addresses.copyAddressStdSObjAddr(con, 'Mailing', addr, null);
                addr.MailingStreet__c = con.MailingStreet;
                Addresses.handleMultilineStreet(addr);
                addr.MailingCity__c = con.MailingCity;
                addr.MailingState__c = con.MailingState;
                addr.MailingPostalCode__c = con.MailingPostalCode;
                addr.MailingCountry__c = con.MailingCountry;
                String strKey = new NPSP_Address(addr).getAddrKey();
                if (setAddrKey.add(strKey)) {
                    listAddr.add(addr);
                }
            }

            return listAddr;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /*******************************************************************************************************
    * @description returns the Salutation choices on Contact
    * @return list<SelectOption> The Salutations
    */
    @AuraEnabled
    public static List<SelectOption> getSalutations() {
        try {

            List<Schema.PicklistEntry> picklistSalutations = Contact.Salutation.getDescribe().getPicklistValues();
            List<SelectOption> listSalutations = new List<SelectOption>();

            listSalutations.add(new SelectOption(Label.stgLabelNone, null));
            for (Schema.PicklistEntry entry : picklistSalutations) {
                listSalutations.add(new SelectOption(entry.getLabel(), entry.getValue()));
            }
            return listSalutations;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /*******************************************************************************************************
    * @description represents a select option, providing members for label and value.
    */
    public class SelectOption {

        public SelectOption(String strLabel, String strValue) {
            label = strLabel;
            value = strValue;
        }

        @AuraEnabled
        public String label { get; set; }

        @AuraEnabled
        public String value { get; set; }
    }

}