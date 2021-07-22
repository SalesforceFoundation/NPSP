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

    public override DmlWrapper run(List<SObject> listNew, List<SObject> listOld,
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        // bail out if address mgmt turned off.
        if (UTIL_CustomSettingsFacade.getContactsSettings().Household_Account_Addresses_Disabled__c) {
            return dmlWrapper;
        }

        Contacts contacts = new Contacts(listNew, listOld);
        switch on triggerAction {
            when BeforeInsert {
                contacts.onBeforeInsert_FromAddrContactTDTM();
            }
            when AfterInsert {
                contacts.onAfterInsert();
            }
            when BeforeUpdate {
                contacts.onBeforeUpdate_FromAddrContactTDTM();
            }
            when AfterUpdate {
                contacts.onAfterUpdate();
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

        // If the Before Insert/Update trigger on the Contact has already executed and taken action
        // and this is an After Insert/Update trigger, reset the hasAlreadyRunBeforeOnContact flag
        return null;
    }
}
