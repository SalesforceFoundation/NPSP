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

        switch on triggerAction {
            when BeforeInsert {
                Addresses addresses = new Addresses(listNew);
                addresses.onBeforeInsert();
                return null;
            }
            when AfterDelete {
                Addresses addresses = new Addresses(listOld);
                addresses.onAfterDelete();
            }
            when BeforeUpdate {
                Addresses addresses2 = new Addresses(listNew, listOld);
                addresses2.onBeforeUpdate();
                return null;
            }
            when AfterInsert {
                Addresses addresses = new Addresses(listNew);
                addresses.onAfterInsert();
            }
            when AfterUpdate {
                Addresses addresses2 = new Addresses(listNew, listOld);
                addresses2.onAfterUpdate();
            }
        }

        // hack to detect empty addresses and delete them after we've propagated the change to all contacts and account
        if (isAfterInsert(triggerAction)) {
            Addresses addresses = new Addresses(listNew);
            addresses.deleteEmptyAddresses();
        }
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ADDR_hasRunTrigger, false);
        return null;
    }


    private Boolean isAfterInsert(Action triggerAction) {
        return triggerAction == TDTM_Runnable.Action.AfterInsert;
    }

    private Boolean isRecursive() {
        return TDTM_ProcessControl.isRecursive(TDTM_ProcessControl.flag.ADDR_hasRunTrigger);
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




}