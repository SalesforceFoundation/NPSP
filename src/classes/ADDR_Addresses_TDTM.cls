/*
    Copyright (c) 2014, Salesforce.org
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
* @date 2014 
* @group Address Management
* @group-content ../../ApexDocContent/Addresses.htm
* @description trigger handler on Address object to support propagating addresses 
* @async_support this trigger handler has been tested with async=true, and appears to not cause problems.
*/
public class ADDR_Addresses_TDTM extends TDTM_Runnable {

    /*******************************************************************************************************
    * @description Trigger Handler on Address that handles address management.  Updates the appropriate
    * Accounts and Contacts when an Address is changed.
    * @param listNew the list of Addresses from trigger new. 
    * @param listOld the list of Addresses from trigger old. 
    * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.). 
    * @param objResult the describe for Addresses 
    * @return dmlWrapper.  
    ********************************************************************************************************/
    public override DmlWrapper run(List<SObject> listNew, List<SObject> listOld,
            TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        // STRATEGY
        // when an Address is created or modified, we need to consider three other objects we may need to update:
        // - the Address's HH Account, if it is marked Default_Address
        // - any other HH Addresses that should no longer be Default
        // - the HH Contacts, if the Address is Default, or a contact specifies it in Address_Override
        //
        // So a change to the Address to become Default, or a change in its Address fields
        // will require visiting all the HH Accounts, and deciding whether we are propagating the change
        // to all related objects, or just to Contacts who are using the Address as their override.
        //

        // prevent recursion
        if (isRecursive()) {
            UTIL_Debug.debug('**** RECURSION: Stop Addr Trigger recursion in ADDR_Addresses_TDTM');
            return null;
        }

        // first go through all new/modified Addresses, and collect the list of HH Accounts to consider.
        Map<Id, Address__c> mapAddressesById = new Map<Id, Address__c>(); // map of changed Addresses who need to only update any contact overrides.

        Map<Id, Address__c> mapAddressesByAcctId = new Map<Id, Address__c>(); // map of HH Accounts, and their default Address

        switch on triggerAction {
            when BeforeInsert {
                Addresses addresses = new Addresses(listNew);
                addresses.onBeforeInsert();
            }
        }

        switch on triggerAction {

            when AfterDelete {
                Addresses addresses = new Addresses(listOld);
                mapAddressesByAcctId = addresses.getMapAddressesByAcctId();
            }
            when else {
                // BEFORE UPDATE
                if (isBeforeUpdate(triggerAction)) {
                    Addresses addresses2 = new Addresses(listNew, listOld);
                    addresses2.onBeforeUpdate();
                }

                Addresses addresses = new Addresses(listNew);

                buildMapAfterInsert(addresses, triggerAction, mapAddressesByAcctId);

                buildMapAfterUpdate(addresses, listOld, triggerAction, mapAddressesByAcctId, mapAddressesById);

                // BEFORE INSERT & BEFORE UPDATE
                if (isBeforeInsert(triggerAction) || isBeforeUpdate(triggerAction)) {
                    // enforce only HH Accounts are being used
                    validate(listNew);

                    return null;
                }
            }
        }

        // AFTER INSERT & AFTER UPDATE & AFTER DELETE
        // now we have which HH Accounts to consider, and which to only use for Address Override updates.
        if (!mapAddressesByAcctId.isEmpty() || !mapAddressesById.isEmpty()) {
            TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ADDR_hasRunTrigger, true);
        }

        DmlWrapper dmlWrapper = new DmlWrapper();

        if (mapAddressesByAcctId.size() > 0) {
            refreshCurrentHHAddress(mapAddressesByAcctId, dmlWrapper, false);
        }

        if (mapAddressesById.size() > 0) {
            updateAddrOverrides(mapAddressesById, dmlWrapper);
        }

        // we must process dmlWrapper ourselves, so we can extract out the appropriate errors
        // that might occur updating contacts and accounts, and associating those errors with 
        // the correct addresses.
        ERR_Handler.Errors errors = TDTM_TriggerHandler.processDMLAllOrNothing(dmlWrapper, false);
        if (errors.errorsExist) {
            for (Error__c error : errors.errorRecords) {
                ID objId = ERR_Handler.getErrorObjectId(error);
                UTIL_Debug.debug(LoggingLevel.WARN, '**** Address TDTM error on object: ' + objId);
                if (UTIL_Describe.isObjectIdThisType(objId, 'Account')) {
                    Address__c addr = mapAddressesByAcctId.get(objId);
                    addr.addError(error.Full_Message__c);
                    UTIL_Debug.debug(LoggingLevel.WARN, '**** Address: ' + addr + ' message: ' + error.Full_Message__c);
                }
                else if (UTIL_Describe.isObjectIdThisType(objId, UTIL_Namespace.StrTokenNSPrefix('Address__c'))) {
                    Address__c addr = mapAddressesById.get(objId);
                    addr.addError(error.Full_Message__c);
                    UTIL_Debug.debug(LoggingLevel.WARN, '**** Address: ' + addr + ' message: ' + error.Full_Message__c);
                }
            }
            TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ADDR_hasRunTrigger, false);
            return null;
        }

        // hack to detect empty addresses and delete them after we've propagated the change to all contacts and account
        if (triggerAction == TDTM_Runnable.Action.AfterInsert) {
            list<Address__c> listAddr = new list<Address__c>();
            for (SObject so : listNew) {
                Address__c addr = (Address__c)so;
                if (isAddressEmpty(addr))
                    listAddr.add(new Address__c(Id = addr.Id));
            }
            if (listAddr.size() > 0)
                delete listAddr;
        }
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ADDR_hasRunTrigger, false);
        return null;
    }

    private void validate(List<SObject> listNew) {
        Addresses addresses = new Addresses(listNew);
        addresses.verifyAddrHHAccOnly();

        // enforce Seasonal Addresses don't overlap
        addresses.verifyAddrSeasonalNoOverlap();
    }

    private void buildMapAfterUpdate(Addresses addresses, List<SObject> listOld, Action triggerAction, Map<Id, Address__c> mapAddressesByAcctId, Map<Id, Address__c> mapAddressesById) {
        Integer i = 0;
        for (Address__c addr : (List<Address__c>) addresses.getRecords()) {
            Address__c addrOld = (listOld != null) ? (Address__c) listOld[i] : null;

            // AFTER UPDATE
            if (isAfterUpdate(triggerAction)) {
                // an address that is marked default needs to propagate to the household
                if ((isNewDefault(addr, addrOld))
                        // any seasonal address also need to be considered
                        || isSeasonalChanged(addr, addrOld)) {
                    mapAddressesByAcctId.put(householdAccountIdOf(addr), addr);
                } else if (isAddressChanged(addr, addrOld)) {
                    if (isDefault(addr)) {
                        mapAddressesByAcctId.put(householdAccountIdOf(addr), addr);
                    } else {   // address changed, but not default, still need to update any contacts using it as an override
                        mapAddressesById.put(idOf(addr), addr);
                    }
                }
            }

            // moving to the next item
            i++;
        }
    }

    private void buildMapAfterInsert(Addresses addresses, Action triggerAction, Map<Id, Address__c> mapAddressesByAcctId) {
        for (Address__c addr : (List<Address__c>) addresses.getRecords()) {
            // AFTER INSERT
            if (isAfterInsert(triggerAction)) {
                // a new address that is marked default or seasonal needs to propagate to the household
                if (isDefault(addr) || isSeasonal(addr)) {
                    mapAddressesByAcctId.put(householdAccountIdOf(addr), addr);
                }
            }
        }
    }

    private Boolean isSeasonal(Address__c addr) {
        return Addresses.isSeasonalAddr(addr);
    }

    private Boolean isBeforeInsert(Action triggerAction) {
        return triggerAction == TDTM_Runnable.Action.BeforeInsert;
    }

    private Boolean isBeforeUpdate(Action triggerAction) {
        return triggerAction == TDTM_Runnable.Action.BeforeUpdate;
    }

    private Boolean isAddressChanged(Address__c addr, Address__c addrOld) {
        return Addresses.isAddressChanged(addr, addrOld, true);
    }

    private Boolean isAfterUpdate(Action triggerAction) {
        return triggerAction == TDTM_Runnable.Action.AfterUpdate;
    }

    private Boolean isAfterInsert(Action triggerAction) {
        return triggerAction == TDTM_Runnable.Action.AfterInsert;
    }

    private Boolean isRecursive() {
        return TDTM_ProcessControl.isRecursive(TDTM_ProcessControl.flag.ADDR_hasRunTrigger);
    }

    private Id idOf(Address__c addr) {
        return addr.Id;
    }

    private Id householdAccountIdOf(Address__c addr) {
        return addr.Household_Account__c;
    }

    private Boolean isDefault(Address__c addr) {
        return addr.Default_Address__c;
    }
    private Boolean isNewDefault(Address__c addr, Address__c addrOld) {
        return addr.Default_Address__c && (addr.Default_Address__c != addrOld.Default_Address__c);
    }

    /*******************************************************************************************************
    * @description The main routine for finding the appropriate address to currently use for the
    * household and its contacts.  Prioritizes the Optional mapped Address as the Default
    * address, as well as checking to see if there is a seasonal address that should be used instead.
    * @param mapAccIdAddr a map of Account Id to the Account's default Address.
    * @param dmlWrapper to hold the objects that get updated
    * @param isCalcHHInfoOnly if set, then this routine will return the map of HHId to HHInfo,
    * and not do any changes to dmlWrapper. 
    * @return map<Id, HHInfo> a map of Account Id to the HHInfo object for the account  
    ********************************************************************************************************/
    public static Map<Id, Addresses.HHInfo> refreshCurrentHHAddress(Map<Id, Address__c>
            mapAccIdAddr, DmlWrapper dmlWrapper, Boolean isCalcHHInfoOnly) {

        return (Map<Id, Addresses.HHInfo>) Addresses.refreshCurrentHHAddress(mapAccIdAddr, dmlWrapper,
                isCalcHHInfoOnly);
    }

    /*******************************************************************************************************
    * @description for the map of addresses, update any contact's mailing fields that are using the address as an override.
    * @param mapAddrIdAddr a map of Address Id's to Addresses
    * @dmlWrapper to hold the Contacts to update
    * @return void
    */
    private void updateAddrOverrides(map<Id, Address__c> mapAddrIdAddr, DmlWrapper dmlWrapper) {
        list<Contact> listCon = [select Id, is_Address_Override__c, Current_Address__c from Contact where is_Address_Override__c = true and Current_Address__c in :mapAddrIdAddr.keyset()];
        for (Contact con : listCon) {
            Address__c addr = mapAddrIdAddr.get(con.Current_Address__c);
            Addresses.copyAddressAddrSObj(addr, con, 'Mailing',
            'npe01__Primary_Address_Type__c');
            dmlWrapper.objectsToUpdate.add(con);
        }
    }


    /*******************************************************************************************************
    * @description returns whether the Address's mailing fields are null
    * @param addr the Address
    * @return boolean. true if all of the Mailing fields are empty
    */
    public static Boolean isAddressEmpty(Address__c addr) {
        if (addr == null)
            return false;
        return (
                addr.MailingStreet__c == Null &&
                        addr.MailingStreet2__c == Null &&
                        addr.MailingCity__c == Null &&
                        addr.MailingState__c == Null &&
                        addr.MailingPostalCode__c == Null &&
                        addr.MailingCountry__c == Null);
    }

    /*******************************************************************************************************
    * @description utility to compare two address objects seasonal fields
    * @param addrNew the new version of the Address
    * @param addrOld the old version of the Address
    * @return boolean. true if any of the seasonal fields have changed on the Address
    */
    private boolean isSeasonalChanged(Address__c addrNew, Address__c addrOld) {
        if (addrNew == null || addrOld == null)
            return false;
        return (
                addrNew.Seasonal_Start_Month__c != addrOld.Seasonal_Start_Month__c ||
                        addrNew.Seasonal_Start_Day__c != addrOld.Seasonal_Start_Day__c ||
                        addrNew.Seasonal_End_Month__c != addrOld.Seasonal_End_Month__c ||
                        addrNew.Seasonal_End_Day__c != addrOld.Seasonal_End_Day__c);
    }

    /*******************************************************************************************************
    * @description Compare two address objects address fields and support fuzzy matching; our definition of 
    * fuzzy is: only one field has changed, ignoring whitespace and letter casing changes.
    * @param addrNew the new version of the Address
    * @param addrOld the old version of the Address
    * @param includeAddressType whether to include comparing the AddressType field
    * @return boolean true if no more than one of the fields have changed on the Address, ignoring whitespace and case changes
    */
    private static boolean isAddressMatchFuzzy(Address__c addrNew, Address__c addrOld, boolean includeAddressType) {
        if (addrNew == null || addrOld == null)
            return false;

        integer cChange = 0;
        if (strCleanup(addrNew.MailingStreet__c) != strCleanup(addrOld.MailingStreet__c) && addrOld.MailingStreet__c != null)
            cChange++;
        if (strCleanup(addrNew.MailingStreet2__c) != strCleanup(addrOld.MailingStreet2__c) && addrOld.MailingStreet2__c != null)
            cChange++;
        if (strCleanup(addrNew.MailingCity__c) != strCleanup(addrOld.MailingCity__c) && addrOld.MailingCity__c != null)
            cChange++;
        if (strCleanup(addrNew.MailingState__c) != strCleanup(addrOld.MailingState__c) && addrOld.MailingState__c != null)
            cChange++;
        if (strCleanup(addrNew.MailingPostalCode__c) != strCleanup(addrOld.MailingPostalCode__c) && addrOld.MailingPostalCode__c != null)
            cChange++;
        if (strCleanup(addrNew.MailingCountry__c) != strCleanup(addrOld.MailingCountry__c) && addrOld.MailingCountry__c != null)
            cChange++;
        if (includeAddressType && strCleanup(addrNew.Address_Type__c) != strCleanup(addrOld.Address_Type__c) && addrOld.Address_Type__c != null)
            cChange++;
        return cChange <= 1;
    }

    /*******************************************************************************************************
    * @description utility to remove all whitespace and to lowercase the string
    * @param str the string to clean up
    * @return string
    */
    private static string strCleanup(string str) {
        if (str != null) {
            str = str.replace(' ', '');
            str = str.toLowerCase();
        } else {
            str = '';
        }
        return str;
    }

    /*******************************************************************************************************
    * @description routine the scheduled batch job calls to update households with Seasonal addresses
    * @param listAcc a list of Accounts to see if their address needs to be updated
    * @return void
    */
    public static void batchSeasonalUpdate(list<Account> listAcc) {
        if (listAcc == null || listAcc.size() == 0)
            return;

        map<Id, Address__c> mapAccIdAddr = new map<Id, Address__c>();
        for (Account acc : listAcc)
            mapAccIdAddr.put(acc.Id, null);

        // get the default and seasonal address for each HH
        map<Id, Addresses.HHInfo> mapAccIdHHInfo = ADDR_Addresses_TDTM.refreshCurrentHHAddress(mapAccIdAddr, null, true);

        // now see which accounts actually had their address change, so we only update them.
        for (Account acc : listAcc) {
            Addresses.HHInfo hhinfo = mapAccIdHHInfo.get(acc.Id);
            if (hhinfo != null) {
                Address__c addr = hhinfo.addrSeasonal;
                if (addr == null)
                    addr = hhinfo.addrDefault;
                if (addr != null) {
                    Address__c addrCurrent = new Address__c();
                    ADDR_Addresses_TDTM.copyAddressStdSObjAddr(acc, 'Billing', addrCurrent, null);
                    // now see if the address has changed, and if not, we don't need to process it anymore
                    if (!Addresses.isAddressChanged(addr, addrCurrent, false)) {
                        mapAccIdAddr.remove(acc.Id);
                    }

                }
            }
        }

        // now mapAccIdAddr only contains those Accounts (and Contacts) who need updating.
        // we'll go thru refreshCurrentHHAddress() again, this time allowing it to do the updates    

        // must manually set our semaphore, so when we update contacts and households, they don't try to create additional addresses
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ADDR_hasRunTrigger, true);

        Dmlwrapper dmlWrapper = new Dmlwrapper();
        refreshCurrentHHAddress(mapAccIdAddr, dmlWrapper, false);
        TDTM_TriggerHandler.processDML(dmlWrapper);
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ADDR_hasRunTrigger, false);
    }

    /*******************************************************************************************************
    * @description For the list of Addresses, sees if there is already an existing Address in the Account that
    * matches. Creates only unique addresses from their respective household, and mark any existing matches 
    * as Default if the caller specifies it on the new address.
    * @param listAddr a list of Addresses to update
    * @param dmlWrapper the Addresses to update
    * @param includeAddressType whether to include comparing the AddressType field
    * @return void
    */
    public static void createNonDuplicateAddresses(list<Address__c> listAddr, DmlWrapper dmlWrapper, boolean includeAddressType) {

        map<Address__c, Address__c> mapAddrDupAddr= findDuplicateAddresses(listAddr);
        for (Address__c addrNew : listAddr) {
            Address__c addrDup = mapAddrDupAddr.get(addrNew);
            if (addrDup != null) {
                // if it is a fuzzy match, not exact, then we want to update the existing address.
                if (Addresses.isAddressChanged(addrNew, addrDup, includeAddressType)) {
                    copyAddressObj(addrNew, addrDup);
                    if (addrNew.Default_Address__c)
                        addrDup.Default_Address__c = true;
                    dmlWrapper.objectsToUpdate.add(addrDup);
                } else if (addrNew.Default_Address__c && !addrDup.Default_Address__c) {
                    addrDup.Default_Address__c = true;
                    dmlWrapper.objectsToUpdate.add(addrDup);
                }
            } else {
                dmlWrapper.objectsToInsert.add(addrNew);
            }
        }
    }

    /*******************************************************************************************************
    * @description for the given addresses, find if they have a match, and return a map that
    * has null for no match, and the matching address if there is a match.
    * @param listAddr a list of Addresses to update
    * @return map<Address__c, Address__c>
    */
    public static map<Address__c, Address__c> findDuplicateAddresses(list<Address__c> listAddr) {
        // for each address, create a map of HHId to lists of Addresses
        list<Id> listAccId = new list<Id>();
        for (Address__c addr : listAddr)
            listAccId.add(addr.Household_Account__c);
        map<Id, list<Address__c>> mapAccIdListAddrHH = Addresses.getMapAccIdListAddrHH
                (listAccId);
        boolean tryFuzzy = UTIL_CustomSettingsFacade.getContactsSettings().Simple_Address_Change_Treated_as_Update__c;

        // create our map for returning information in
        map<Address__c, Address__c> mapAddrDupAddr = new map<Address__c, Address__c>();

        // now compare our Addresses to the existing Addresses
        for (Address__c addr : listAddr) {
            list<Address__c> listAddrHH = mapAccIdListAddrHH.get(addr.Household_Account__c);
            boolean hasMatch = false;
            if (listAddrHH != null) {
                Address__c addrMatch = null;
                for (Address__c addrHH : listAddrHH) {
                    // only include address type in the test if the new one isn't empty.
                    if (!Addresses.isAddressChanged(addr, addrHH, addr.Address_Type__c != null)) {
                        // found exact match, record it and bail out
                        addrMatch = addrHH;
                        break;
                    }
                    if (tryFuzzy && isAddressMatchFuzzy(addr, addrHH, addr.Address_Type__c != null)) {
                        // found fuzzy match, remember it and continue searching
                        addrMatch = addrHH;
                        continue;
                    }
                }
                if (addrMatch != null) {
                    hasMatch = true;
                    mapAddrDupAddr.put(addr, addrMatch);
                }
            }
            if (!hasMatch)
                mapAddrDupAddr.put(addr, null);
        }

        return mapAddrDupAddr;
    }

    /*******************************************************************************************************
    * @description Cleanup the Addresses for the specified Accounts by removing any duplicate Addresses,
    * making sure only one is marked Default, and that the Default is propagated to the appropriate
    * Account and Contacts.
    *
    * @param listAccId a list of Account Id's to process
    * @return null
    */
    public static void cleanupAccountAddresses(list<ID> listAccId) {

        // use dmlWrapper to handle all of our database operations
        TDTM_Runnable.DmlWrapper dmlWrapper = new TDTM_Runnable.DmlWrapper();

        // for each Account, track its correct Default Address
        map<Id, Address__c> mapAccIdAddr = new map<Id, Address__c>();

        // for each Account, get its list of Addresses in oldest to newest order (of LastModifiedDate)
        map<Id, list<Address__c>> mapAccIdListAddrHH = Addresses.getMapAccIdListAddrHH(listAccId);

        // Construct Contact repository for Accounts having Addresses
        ContactRepository contactRepo = new ContactRepository(mapAccIdListAddrHH.keySet());

        for (ID accId : mapAccIdListAddrHH.keySet()) {
            if (mapAccIdListAddrHH.get(accId) != null) {
                map<string, list<Address__c>> mapAddrKeyToAddresses = new map<string, list<Address__c>>();
                Address__c addrDefault;

                for (Address__c addr : mapAccIdListAddrHH.get(accId)) {

                    // remember the oldest modified Default address
                    // this is the one from the winning account, since the losing account addresses get updated.
                    if (addr.Default_Address__c && addrDefault == null) {
                        addrDefault = addr;
                        mapAccIdAddr.put(accId, addrDefault);
                    }

                    // create our map of Address Keys to a list of one or more Addresses
                    string addrKey = getAddrKey(addr);
                    list<Address__c> listAddr = mapAddrKeyToAddresses.get(addrKey);
                    if (listAddr == null) {
                        listAddr = new list<Address__c>();
                        mapAddrKeyToAddresses.put(addrKey, listAddr);
                    }
                    listAddr.add(addr);
                }

                // now we have the Default Address to use and lists of potential duplicate addresses
                // remove the duplicates, updating any contacts that are using the duplicates
                // we delay getting the contacts until we know we have a duplicate.
                for (string addrKey : mapAddrKeyToAddresses.keySet()) {
                    list<Address__c> listAddr = mapAddrKeyToAddresses.get(addrKey);

                    for (integer i = 1, size = listAddr.size(); i < size; i++) {
                        Address__c addrDupe = listAddr[i];

                        replaceAddress(addrDupe, listAddr[0], contactRepo.getContacts(accId), dmlWrapper);
                        dmlWrapper.objectsToDelete.add(addrDupe);
                    }
                }

            }
        }

        // perform our updates & deletes for dealing with the duplicate addresses
        TDTM_TriggerHandler.processDml(dmlWrapper);

        // now make sure all contacts are using the correct default address
        dmlWrapper = new TDTM_Runnable.DmlWrapper();
        refreshCurrentHHAddress(mapAccIdAddr, dmlWrapper, false);
        TDTM_TriggerHandler.processDml(dmlWrapper);
    }

    /*******************************************************************************************************
    * @description replaces the losing address with the winning address in any contacts referring to the 
    * loser.  Note that it just updates the contact's Address lookup, and doesn't copy any Address data.
    * Any Contacts that are modified are put on dmlWrapper for later updating.
    * @param addrLoser the Address to look for
    * @param addrWinner the Address to replace with
    * @param listCon the list of Contacts to evaluate
    * @param dmlWrapper to hold any Contacts that need updating
    * @return null
    */
    private static void replaceAddress(Address__c addrLoser, Address__c addrWinner, list<Contact> listCon, TDTM_Runnable.DmlWrapper dmlWrapper) {
        for (Contact con : listCon) {
            if (con.Current_Address__c == addrLoser.Id) {
                con.Current_Address__c = addrWinner.Id;
                dmlWrapper.objectsToUpdate.add(con);
            }
        }
    }

    /*******************************************************************************************************
    * @description returns a unique key the represents the address object for address matching
    * @param addr the Address to look at
    * @return string The Address's unique Key
    */
    public static string getAddrKey(Address__c addr) {
        string strKey =
                strCleanup(addr.MailingStreet__c) +
                        strCleanup(addr.MailingStreet2__c) +
                        strCleanup(addr.MailingCity__c) +
                        strCleanup(addr.MailingState__c) +
                        strCleanup(addr.MailingPostalCode__c) +
                        strCleanup(addr.MailingCountry__c) +
                        strCleanup(addr.Address_Type__c) +
                        (addr.Seasonal_Start_Day__c != null ? addr.Seasonal_Start_Day__c : '') +
                        (addr.Seasonal_Start_Month__c != null ? addr.Seasonal_Start_Month__c : '') +
                        (addr.Seasonal_End_Day__c != null ? addr.Seasonal_End_Day__c : '') +
                        (addr.Seasonal_End_Month__c != null ? addr.Seasonal_End_Month__c : '');
        return strKey;
    }

    /*******************************************************************************************************
    * @description utility to see if the address has only a subset of its seasonal fields set
    * @param addr the Address to look at
    * @return boolean
    */
    public static void handleMultilineStreet(Address__c addr) {

        if (addr.MailingStreet__c == null)
            return;

        // handle CR NL
        integer ich = addr.MailingStreet__c.indexOf('\r\n');
        if (ich > -1) {
            addr.MailingStreet2__c = addr.MailingStreet__c.substring(ich+2);
            addr.MailingStreet__c = addr.MailingStreet__c.left(ich);
            return;
        }

        // handle just NL
        ich = addr.MailingStreet__c.indexOf('\n');
        if (ich > -1) {
            addr.MailingStreet2__c = addr.MailingStreet__c.substring(ich+1);
            addr.MailingStreet__c = addr.MailingStreet__c.left(ich);
            return;
        }
    }

    /*******************************************************************************************************
    * @description Utility to copy Address fields between two Address objects.
    * @param addrSrc the source Address
    * @param addrDst the destination Address
    * @return void
    */
    public static void copyAddressObj(Address__c addrSrc, Address__c addrDst) {
        addrDst.MailingStreet__c = addrSrc.MailingStreet__c;
        addrDst.MailingStreet2__c = addrSrc.MailingStreet2__c;
        addrDst.MailingCity__c = addrSrc.MailingCity__c;
        addrDst.MailingState__c = addrSrc.MailingState__c;
        addrDst.MailingPostalCode__c = addrSrc.MailingPostalCode__c;
        addrDst.MailingCountry__c = addrSrc.MailingCountry__c;
        addrDst.Geolocation__Latitude__s = addrSrc.Geolocation__Latitude__s;
        addrDst.Geolocation__Longitude__s = addrSrc.Geolocation__Longitude__s;
        if (addrSrc.Address_Type__c != null)
            addrDst.Address_Type__c = addrSrc.Address_Type__c;
    }

    /*******************************************************************************************************
    * @description Utility to copy Address fields between Contacts and Accounts (or vice-versa).
    * Handles instances where State and Country picklists are enabled, and multiline street addresses.
    * @param sobjSrc the source Contact or Account
    * @param strFieldPrefixSrc the address fields to copy from, ie., Mailing, Other, Shipping, Billing
    * @param sobjDst the destination Contact or Account
    * @param strFieldPrefixDst the address fields to copy to, ie., Mailing, Other, Shipping, Billing
    * @return void
    */
    public static void copyAddressStdSObj(sobject sobjSrc, string strFieldPrefixSrc, sobject sobjDst, string strFieldPrefixDst) {
        sobjDst.put(strFieldPrefixDst + 'Street', sobjSrc.get(strFieldPrefixSrc + 'Street'));
        sobjDst.put(strFieldPrefixDst + 'City', sobjSrc.get(strFieldPrefixSrc + 'City'));
        sobjDst.put(strFieldPrefixDst + 'PostalCode', sobjSrc.get(strFieldPrefixSrc + 'PostalCode'));
        sobjDst.put(strFieldPrefixDst + 'State', sobjSrc.get(strFieldPrefixSrc + 'State'));
        sobjDst.put(strFieldPrefixDst + 'Country', sobjSrc.get(strFieldPrefixSrc + 'Country'));
        sobjDst.put(strFieldPrefixDst + 'Latitude', sobjSrc.get(strFieldPrefixSrc + 'Latitude'));
        sobjDst.put(strFieldPrefixDst + 'Longitude', sobjSrc.get(strFieldPrefixSrc + 'Longitude'));

        if (Addresses.isStateCountryPicklistsEnabled) {
            sobjDst.put(strFieldPrefixDst + 'StateCode', sobjSrc.get(strFieldPrefixSrc + 'StateCode'));
            sobjDst.put(strFieldPrefixDst + 'CountryCode', sobjSrc.get(strFieldPrefixSrc + 'CountryCode'));
        }
    }

    /*******************************************************************************************************
    * @description utility to copy Address fields from a Contact or Account to an Address object.
    * Handles instances where State and Country picklists are enabled, and multiline street addresses.
    * @param sobjSrc the source Contact or Account
    * @param fieldPrefixSrc the address fields to copy from, ie., Mailing, Other, Shipping, Billing
    * @param addr the Address object to copy to
    * @param addrType if not null, copy to address.Address_Type__c
    * @return void
    */
    public static void copyAddressStdSObjAddr(sObject sobjSrc, String fieldPrefixSrc, Address__c addr, String addrType) {
        addr.MailingStreet__c = (String)sobjSrc.get(fieldPrefixSrc + 'Street');
        handleMultilineStreet(addr);
        addr.MailingCity__c = (String)sobjSrc.get(fieldPrefixSrc + 'City');
        addr.MailingPostalCode__c = (String)sobjSrc.get(fieldPrefixSrc + 'PostalCode');
        addr.MailingState__c = (String)sobjSrc.get(fieldPrefixSrc + 'State');
        addr.MailingCountry__c = (String)sobjSrc.get(fieldPrefixSrc + 'Country');
        addr.Geolocation__Latitude__s = (Decimal)sobjSrc.get(fieldPrefixSrc + 'Latitude');
        addr.Geolocation__Longitude__s = (Decimal)sobjSrc.get(fieldPrefixSrc + 'Longitude');

        if (Addresses.isStateCountryPicklistsEnabled) {
            populateAddressCountryFromCountryCode(sobjSrc, fieldPrefixSrc, addr);
            populateAddressStateFromStateCode(sobjSrc, fieldPrefixSrc, addr);
        }

        // if specified, also include Address Type
        if (addrType != null) {
            addr.Address_Type__c = addrType;
        } else {
            // A null value will force a newly created Address record to use its defined default value for
            // the picklist, which if not reflected here could cause isAddressChanged() to return true
            // in cases when it should not.
            addr.Address_Type__c = Addresses.defaultAddressType;
        }
    }


    /*******************************************************************************************************
    * @description Updates the Address record's MailingCountry field when it is empty
    *              with the Account's BillingCountryCode or Contact's MailingCountryCode value.
    * @param sobjSrc the source Account or Contact
    * @param fieldPrefixSrc the address field to copy from, ie., Mailing, Other, Billing, Shipping
    * @param addr the Address object to update accordingly
    * @return void
    */
    @testVisible
    private static void populateAddressCountryFromCountryCode(sObject sobjSrc, String fieldPrefixSrc, Address__c addr) {
        String countryCode = (String)sobjSrc.get(fieldPrefixSrc + 'CountryCode');
        if (String.isBlank(countryCode)) {
            return;
        }

        if (String.isEmpty(addr.MailingCountry__c)) {
            addr.MailingCountry__c = Addresses.validCountriesByCode.get(countryCode
                    .toUpperCase());
        }
    }


    /*******************************************************************************************************
    * @description Updates the Address record's MailingState field when it is empty
    *              or does not match the Account's BillingStateCode or Contact's MailingStateCode value.
    * @param sobjSrc the source Account or Contact
    * @param fieldPrefixSrc the address field to copy from, ie., Mailing, Other, Billing, Shipping
    * @param addr the Address object to update accordingly
    * @return void
    */
    @testVisible
    private static void populateAddressStateFromStateCode(sObject sobjSrc, String fieldPrefixSrc, Address__c addr) {
        String stateCode = (String)sobjSrc.get(fieldPrefixSrc + 'StateCode');
        if (String.isBlank(stateCode)) {
            return;
        }

        if (String.isEmpty(addr.MailingState__c) || !isMatchingStateCode(stateCode, addr.MailingState__c)) {

            // Assume it's a valid statecode
            addr.MailingState__c = stateCode;
        }
    }


    /*******************************************************************************************************
    * @description Determines if the Account's BillingStateCode or Contact's MailingStateCode matches the 
    *              Address record's Mailing State.
    * @param stateCode the BillingStateCode or MailingStateCode
    * @param addressMailingState the Address Mailing State
    * @return void
    */
    @testVisible
    private static Boolean isMatchingStateCode(String stateCode, String addressMailingState) {
        if (String.isBlank(addressMailingState)) {
            return false;
        }

        String mappedMailingState = (Addresses.validStatesByLabel == null)
            ? ''
            : Addresses.validStatesByLabel.get(addressMailingState.toUpperCase());

        return stateCode.equalsIgnoreCase(mappedMailingState);
    }



}