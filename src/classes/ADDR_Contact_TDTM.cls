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
* @description Trigger Handler on Contact for Address management 
* @async_support this trigger handler has been tested with async=true, and appears to not cause problems.
*/
public class ADDR_Contact_TDTM extends TDTM_Runnable {

    /*******************************************************************************************************
    * @description Trigger Handler on Contact that handles Address Management.
    * 	Rules:
    * 		inserting new contact - make their address a new default address, unless they say it is an override
    * 		updating an existing contact - make their address a new default address, unless they say it is an override
    *       moving an existing contact to a new household or different household without an address - make their address
    *       a new default address, unless they say it is an override
    * @param listNew the list of Contacts from trigger new. 
    * @param listOld the list of Contacts from trigger old. 
    * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.). 
    * @param objResult the describe for Contacts 
    * @return dmlWrapper.  
    ********************************************************************************************************/
    DmlWrapper dmlWrapper = new DmlWrapper();
    list<Contact> useCurrentAddressQueue = new list<Contact>();
    Set<Contact> addressCreationQueue = new Set<Contact>();
    map<Id, boolean> isOverrideByAddressId = new map<Id, boolean>();
    list<Contact> addressRefreshQueue = new list<Contact>();

    public override DmlWrapper run(List<SObject> listNew, List<SObject> listOld,
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        boolean isBefore = (triggerAction == TDTM_Runnable.Action.BeforeUpdate || triggerAction == TDTM_Runnable.Action.BeforeInsert);

        // bail out if address mgmt turned off.
        if (UTIL_CustomSettingsFacade.getContactsSettings().Household_Account_Addresses_Disabled__c)
        	return dmlWrapper;

        Contacts contacts = new Contacts(listNew, listOld);
        switch on triggerAction {
            when BeforeInsert {
                contacts.normalizeLineBreaks();

                // we only support address management with HH Accounts being used
                for (SObject so : contacts.contactsInHouseholdAccounts().getRecords()) {
                    Contact con = (Contact) so;
                    NPSP_Contact npspContact=new NPSP_Contact(con);

                    if (npspContact.currentAddress() != null) {
                        // remember which contacts will need their address set
                        useCurrentAddressQueue.add(con);
                        if (npspContact.hasAddressOverride()) {
                            // track which address's need their dates updated
                            isOverrideByAddressId.put(npspContact.currentAddress(), true);
                        }
                    } else if (npspContact.isAddressEmpty() &&
                            contacts.accountHasAddresses(npspContact.getRecord())) {
                        // if the contact has no address specified and the household has a default address, pick up the hh default.
                        addressRefreshQueue.add(con);
                    }
                }
            }
            when BeforeUpdate {
                contacts.normalizeLineBreaksForContactsWithChangedAddresses();
            }
        }
        // Rules:
        // inserting new contact - make their address a new default address, unless they say it is an override
        // updating an existing contact - make their address a new default address, unless they say it is an override
        // moving an existing contact to a new household or different household without an address - make their address
        //     a new default address, unless they say it is an override

        // there can be four different types of changes we need to consider
        // A. changes to isAddressOverride
        // B. changes to CurrentAddress
        // C. changes to MailingAddress fields
        // D. changes to Account (ie switching accounts)
        //
        // that leads to 16 permutations!
        // (it's actually more permutations, since we need to take into account what
        // the change in isAddressOverride or CurrentAddress is).
        //
        // A,B,C       if (CurrentAddress) refill to it, else update/new address object
        // A,!B,!C     if !isAddrOverride, refill contact from Default Address
        // A,!B,C      if isAddrOverride, update/new addr object and refresh CurrentAddress, else update/new address object
        // A,B,!C      if (CurrentAddress) refill to it, else refill from Default Address
        // !A,B,C      if (CurrentAddress) refill to it, else update/new address object
        // !A,!B,C     update/new address object
        // !A,B,!C     if (CurrentAddress) refill to it, else refill from Default Address
        // !A,!B,!C    nothing!
        // *,*,*,D     if no override, refill from Default Address, else update/new address object
        //
        // simplifying this to some precedence rules:
        //     - if Account changes && no override && no MailingAddress field changes, refill from Default Address
        //     - if CurrentAddress changes to a new non-null value, refill to it.
        //     - if MailingAddress field changes, update/new address object
        //     - if isAddressOverride changes to false, refill from Default Address

        integer i = -1;
        // we only support address management with HH Accounts being used
        for (SObject so : contacts.contactsInHouseholdAccounts().getRecords()) {
            // new highest priority! if Account changes...
            if (isBeforeUpdate(triggerAction)) {
                i++;
                Contact con = (Contact) so;
                Contact conOld = (listOld != null ? (Contact) listOld[i] : null);
                NPSP_Contact npspContact = new NPSP_Contact(con, conOld);

                if (npspContact.accountChanged()) {
                    // if no override, refill from the Default Address
                    if (!npspContact.hasAddressOverride() && !npspContact.isAddressChanged()) {
                        if (contacts.accountHasAddresses(npspContact.getRecord())) { //
                            // refresh address if the contact does not have one and account does
                            addressRefreshQueue.add(con);
                        }
                    } else { // create a new address on the account
                        addressCreationQueue.add(con);
                    }
                } else {

                    // highest priority. if they are changing to a new Current Address, refill from it.
                    if (npspContact.currentAddressChanged() &&
                            npspContact.currentAddress() != null) {
                        useCurrentAddressQueue.add(con);
                        if (npspContact.hasAddressOverride())
                            // track which address's need their dates updated
                            isOverrideByAddressId.put(npspContact.currentAddress(), true);
                    }

                    // second priority.  if they are clearing isAddressOverride, and no address fields change, refill from the Default Address
                    if (npspContact.addressOverrideChanged() && !npspContact.hasAddressOverride() &&
                            !npspContact.isAddressChanged()) {
                        addressRefreshQueue.add(con);
                        NPSP_Contact npspContactOld = new NPSP_Contact(conOld);
                        if (npspContactOld.currentAddress() != null)
                            // track which address's need their dates updated
                            isOverrideByAddressId.put(npspContactOld.currentAddress(), false);
                    }

                    // third priority.  if MailingAddress fields changed, update the existing address object or create a new one.
                    // this is handled in the next block, since we do it for both new contacts and updated contacts.
                }
            }
        }

        integer j = -1;
        // we only support address management with HH Accounts being used
        for (SObject so : contacts.thatHaveAccounts().getRecords()) {
            j++;
            Contact con = (Contact) so;
            Contact conOld = (listOld != null ? (Contact) listOld[j] : null);
            NPSP_Contact npspContact = new NPSP_Contact(con, conOld);

            if (!isBefore && npspContact.householdAndAccountDiffer()) {
                continue;
            }


            if (isBefore) {
                Account a = contacts.accountsByIds().get(con.AccountId);
                if (a.npe01__SYSTEM_AccountType__c != CAO_Constants.HH_ACCOUNT_TYPE)
                    continue;
            }
            // BEFORE UPDATE & AFTER UPDATE & BEFORE INSERT && AFTER INSERT
            // our functionality for dealing with contact address changes requires some trickery!
            // if the contact doesn't have an address override, we create (or match) a default address,
            // which requires us to do the work in the AfterUpdate (or else we can't propagate the default address).
            // but if the contact has an address override, we are supposed to create (or match) a non default address override.
            // in order to update the contact with the new address override's Id, we have to do it in the BeforeUpdate.
            if (triggerAction == TDTM_Runnable.Action.BeforeUpdate ||
                    triggerAction == TDTM_Runnable.Action.BeforeInsert ||
                    triggerAction == TDTM_Runnable.Action.AfterInsert ||
                    triggerAction == TDTM_Runnable.Action.AfterUpdate
               ) {
                // note that we detect whether the address change is coming from the address trigger,
                // in which case we don't want to create a new address.
                if (TDTM_ProcessControl.isRecursive(TDTM_ProcessControl.flag.ADDR_hasRunTrigger)) {
                    UTIL_Debug.debug('**** RECURSION: Stop Addr Trigger recursion in ADDR_Contact_TDTM');
                    continue;
                }
                // If the Before Insert/Update trigger on the Contact has already executed and taken action
                // and this is an After Insert/Update trigger, simply reset the flag and exit out.
                if (TDTM_ProcessControl.isRecursive(TDTM_ProcessControl.flag.ADDR_hasRunContactOnBefore) &&
                (triggerAction == TDTM_Runnable.Action.AfterInsert || triggerAction == TDTM_Runnable.Action.AfterUpdate)) {
                    UTIL_Debug.debug('**** RECURSION: Stop BeforeContact Trigger recursion in ADDR_Contact_TDTM');
                    continue;
                }

                // if the contacts address changed or if the contact with an address moves to a new household remember the contact
                if (npspContact.isAddressChanged() || (npspContact.accountChanged() &&
                        !npspContact.isAddressEmpty())) {
                    addressCreationQueue.add(con);
                }
            }
        }


        if (useCurrentAddressQueue.size() > 0 || addressRefreshQueue.size() > 0) {
            // to avoid pushing these address changes to the HH.
            TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ADDR_hasRunTrigger, true);
            // set this flag to true to prevent the AfterUpdate trigger on the Contact from processing changes
            // to the Contact's address that are being made by this BeforeUpdate trigger.
            if (isBefore) {
                TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ADDR_hasRunContactOnBefore, true);
            }
        }

            // set the mailing address for contacts who specify an address lookup or override
        if (useCurrentAddressQueue.size() > 0) {
            contacts.setContactAddressFromCurrentAddress(useCurrentAddressQueue, dmlWrapper,
                    triggerAction);
        }
        
        // reset the mailing address for contacts who no longer have an address override
        if (addressRefreshQueue.size() > 0) {
            Contacts contactsForAddressRefresh = new Contacts(addressRefreshQueue);
            contactsForAddressRefresh.resetAddresses();
        }
        
        // update the Latest date fields on any address overrides
        if (isOverrideByAddressId.size() > 0) {
            Addresses.updateAddrIsOverride(isOverrideByAddressId, dmlWrapper);
        }

        // create any new Default Address objects
        if (addressCreationQueue.size() > 0) {
            contacts.createAddrFromCon(new List<Contact>(addressCreationQueue), dmlWrapper,
                    triggerAction);
        }

        TDTM_TriggerHandler.processDML(dmlWrapper);

        if (useCurrentAddressQueue.size() > 0 || addressRefreshQueue.size() > 0) {
            TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ADDR_hasRunTrigger, false);
        }

        // If the Before Insert/Update trigger on the Contact has already executed and taken action
        // and this is an After Insert/Update trigger, reset the hasAlreadyRunBeforeOnContact flag
        if (triggerAction == TDTM_Runnable.Action.AfterInsert || triggerAction == TDTM_Runnable.Action.AfterUpdate) {
            TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ADDR_hasRunContactOnBefore, false);
        }

        return null;
    }

    private Boolean isBeforeUpdate(Action triggerAction) {
        return triggerAction == TDTM_Runnable.Action.BeforeUpdate;
    }

}
