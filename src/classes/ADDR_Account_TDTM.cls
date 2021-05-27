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
* @description Trigger Handler on Account for Address management 
* @async_support this trigger handler has been tested with async=true, and appears to not cause problems.
*/
public class ADDR_Account_TDTM extends TDTM_Runnable {

    @TestVisible
    private OrgConfig orgConfig {
        get {
            if (orgConfig == null) {
                orgConfig = new OrgConfig();
            }
            return orgConfig;
        }
        set;
    }

    /*******************************************************************************************************
    * @description Trigger Handler on Account that handles Address management.
    * @param listNew the list of Accounts from trigger new. 
    * @param listOld the list of Accounts from trigger old. 
    * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.). 
    * @param objResult the describe for Accounts 
    * @return dmlWrapper.  
    ********************************************************************************************************/
    public override DmlWrapper run(List<SObject> listNew, List<SObject> listOld, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        DmlWrapper dmlWrapper = new DmlWrapper();

        // note that we detect whether the address change is coming from the address trigger,
        // in which case we don't want to create a new address.
        if (triggerAction == TDTM_Runnable.Action.AfterUpdate
            && TDTM_ProcessControl.isRecursive(TDTM_ProcessControl.flag.ADDR_hasRunTrigger)
        ) {
            UTIL_Debug.debug('**** RECURSION: Stop Addr Trigger recursion in ADDR_Account_TDTM');
            return dmlWrapper;
        }

        List<Account> listAccCreateAddr = new List<Account>();

        for (Integer i = 0; i < listNew.size(); i++) {
            Account newRecord = (Account) listNew[i];
            Account oldRecord = (listOld != null ? (Account) listOld[i] : null);
            NPSP_HouseholdAccount npspHousehold = new NPSP_HouseholdAccount(newRecord, oldRecord);

            if (isAddressManagementEnabled(newRecord)) {
                // BEFORE INSERT
                if (triggerAction == TDTM_Runnable.Action.BeforeInsert) {
                    UTIL_Address.normalizeLineBreak(newRecord);
                }

                // BEFORE UPDATE
                if (triggerAction == TDTM_Runnable.Action.BeforeUpdate
                        && npspHousehold.isAccountAddressChanged()) {
                    UTIL_Address.normalizeLineBreak(newRecord);
                }

                // AFTER INSERT
                if (triggerAction == TDTM_Runnable.Action.AfterInsert) {
                    if (isAccountAddressSpecified(newRecord)) {
                        listAccCreateAddr.add(newRecord);
                    }
                }

                // AFTER UPDATE
                if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
                    // if the address changed, remember the account we want to add a new address for
                    if (npspHousehold.isAccountAddressChanged()) {
                        listAccCreateAddr.add(newRecord);
                    }
                }
            }
        }

        // create any new Address objects
        if (listAccCreateAddr.size() > 0) {
            createAddrFromAcc(listAccCreateAddr, dmlWrapper);
        }
                    
        return dmlWrapper;    
    }

    /*******************************************************************************************************
    * @description utility to see if an address management is enabled
    * @param newRecord an Account
    * @return Boolean.  true if address management is enabled
    ********************************************************************************************************/
    private Boolean isAddressManagementEnabled(Account newRecord) {
        if (newRecord.npe01__SYSTEM_AccountType__c == CAO_Constants.HH_ACCOUNT_TYPE
                && !UTIL_CustomSettingsFacade.getContactsSettings().Household_Account_Addresses_Disabled__c) {
            return true;
        }
        if (!newRecord.npe01__SYSTEMIsIndividual__c
                && UTIL_CustomSettingsFacade.getContactsSettings().Organizational_Account_Addresses_Enabled__c) {
            return true;
        }
        return false;
    }

    /*******************************************************************************************************
    * @description utility to see if an address is specified
    * @param acc1 an Account
    * @return boolean.  true if an address is specified in any of the Account Billing fields
    ********************************************************************************************************/
    private Boolean isAccountAddressSpecified(Account acc1) {
        if (acc1 == null) {
            return false;
        }
        
        Boolean isSpecified =
           acc1.BillingStreet != null ||
           acc1.BillingCity != null ||
           acc1.BillingState != null ||
           acc1.BillingPostalCode != null ||
            // note that we decided to ignore country so that a default value won't create unnecessary address objects
           (acc1.BillingCountry != null && !orgConfig.isStateCountryPicklistsEnabled()) ||
           // only test StateCode if picklists enabled.
           (orgConfig.isStateCountryPicklistsEnabled() && acc1.get('BillingStateCode') != null);

        return isSpecified;   
    }

    /*******************************************************************************************************
    * @description for each Account, create a new default address and add it to dmlWrapper
    * @param listAcc a list of Accounts
    * @param dmlWrapper to hold the Addresses that need creating
    ********************************************************************************************************/
    private void createAddrFromAcc(List<Account> listAcc, DmlWrapper dmlWrapper) {
        List<Address__c> listAddr = new List<Address__c>();
        for (Account acc : listAcc) {
            NPSP_Address npspAddress = new NPSP_Address(acc);
            listAddr.add(npspAddress.getRecord());
        }
        // since coming from an account address, there is no Address Type, so exclude it from the match testing.
        Addresses.createNonDuplicateAddresses(listAddr, dmlWrapper, false);
    }
}