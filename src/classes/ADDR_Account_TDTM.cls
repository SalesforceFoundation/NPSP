/*
    Copyright (c) 2014, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
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
* @author Salesforce.com Foundation
* @date 2014
* @description support needed on Account for Address management 
*/
public with sharing class ADDR_Account_TDTM extends TDTM_Runnable {

    // the main entry point for TDTM to invoke our trigger handlers.
    public override DmlWrapper run(List<SObject> listNew, List<SObject> listOld, 
        TDTM_TriggerActionHelper.Action triggerAction, Schema.DescribeSObjectResult objResult) {
            
        DmlWrapper dmlWrapper = new DmlWrapper();  
        list<Account> listAccCreateAddr = new list<Account>();      
       
        integer i = 0;        
        for (SObject so : listNew) {
            Account acc = (Account)so;

            // BEFORE INSERT
            if (triggerAction == TDTM_TriggerActionHelper.Action.BeforeInsert) {
            }
            
            // BEFORE UPDATE
            if (triggerAction == TDTM_TriggerActionHelper.Action.BeforeUpdate) {
            }
            
            // AFTER INSERT
            if (triggerAction == TDTM_TriggerActionHelper.Action.AfterInsert) {

            }
    
            // AFTER UPDATE
            if (triggerAction == TDTM_TriggerActionHelper.Action.AfterUpdate) {
                Account accOld = (Account)listOld[i];
                // note that we detect whether the address change is coming from the address trigger,
                // in which case we don't want to create a new address.
                if (ADDR_Addresses_TDTM.hasRunAddrTrigger)
                    continue;
                // we only support address management with HH Accounts
                if (acc.npe01__SYSTEM_AccountType__c != CAO_Constants.HH_ACCOUNT_TYPE)
                    continue;
                // if the address changed, remember the account we want to add a new address for    
                if (isAccountAddressChanged(acc, accOld)) 
                    listAccCreateAddr.add(acc);
            }    
        }

        // create any new Address objects
        if (listAccCreateAddr.size() > 0)
            createAddrFromAcc(listAccCreateAddr, dmlWrapper);
                    
        return dmlWrapper;    
    }

    // utility to compare two Accounts' (billing) addresses
    private boolean isAccountAddressChanged(Account acc1, Account acc2) {
        if (acc1 == null || acc2 == null) 
           return false;
        
        return (
           acc1.BillingStreet != acc2.BillingStreet ||
           acc1.BillingCity != acc2.BillingCity ||
           acc1.BillingState != acc2.BillingState ||
           acc1.BillingPostalCode != acc2.BillingPostalCode ||
           acc1.BillingCountry != acc2.BillingCountry);
    }

    // for each Account, create a new default address and add it to dmlWrapper
    private void createAddrFromAcc(list<Account> listAcc, DmlWrapper dmlWrapper) {
        for (Account acc : listAcc) {
            Address__c addr = new Address__c();
            addr.Household_Account__c = acc.Id;
            addr.Default_Address__c = true;
            addr.MailingStreet__c = acc.BillingStreet;
            addr.MailingCity__c = acc.BillingCity;
            addr.MailingState__c = acc.BillingState;
            addr.MailingPostalCode__c = acc.BillingPostalCode;
            addr.MailingCountry__c = acc.BillingCountry;
            
            dmlWrapper.objectsToInsert.add(addr);
        }
        system.debug('DJH**** addr to insert: ' + dmlWrapper.objectsToInsert);
    }

}