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
* @description trigger handler on Address object to support propogating addresses 
*/
public with sharing class ADDR_Addresses_TDTM extends TDTM_Runnable {

    // static flags to prevent recursive call 
    public static boolean hasRunAddrTrigger = false;

    // the main entry point for TDTM to invoke our trigger handlers.
    public override DmlWrapper run(List<SObject> listNew, List<SObject> listOld, 
        TDTM_TriggerActionHelper.Action triggerAction, Schema.DescribeSObjectResult objResult) {
        	
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
        if (hasRunAddrTrigger) {
        	system.debug('**** stop Addr Trigger recursion');
            return null;
        }
        hasRunAddrTrigger = true;

        DmlWrapper dmlWrapper = new DmlWrapper();        
        
        // first go through all new/modified Addresses, and collect the list of HH Accounts to consider.
        map<Id, Id> mapAddrIdAccId = new map<Id, Id>(); // map of HH Account Id's we must consider
        set<Id> setAccIdConOverrideOnly = new set<Id>();  // set of HH Account Id's where we only need to update their contacts who use the address as an override       
        integer i = 0;        
        for (SObject so : listNew) {
            Address__c addr = (Address__c)so;

            // AFTER INSERT
            if (triggerAction == TDTM_TriggerActionHelper.Action.AfterInsert) {
                if (addr.Default_Address__c && addr.Household_Account__c != null) {
                    mapAddrIdAccId.put(addr.Id, addr.Household_Account__c);
                }        
            }
            
            // AFTER UPDATE
            if (triggerAction == TDTM_TriggerActionHelper.Action.AfterUpdate) {
                Address__c addrOld = (Address__c)listOld[i];
                if (addr.Default_Address__c && (addr.Default_Address__c != addrOld.Default_Address__c)) {
                    mapAddrIdAccId.put(addr.Id, addr.Household_Account__c);
                } else if (isAddressChanged(addr, addrOld)) {
                    mapAddrIdAccId.put(addr.Id, addr.Household_Account__c);      
                    if (!addr.Default_Address__c)
                        setAccIdConOverrideOnly.add(addr.Household_Account__c);          	
                } 
            }
            
        i++;            
        }
        // now we have which HH Accounts to consider, and which to only use for Address Override updates.
        system.debug('DJH**** mapAddrIdAccId: ' + mapAddrIdAccId);
        system.debug('DJH**** setAccIdConOverrideOnly: ' + setAccIdConOverrideOnly);
        
        // get all Addresses by HH, that might need updating
        list<Address__c> listAddrOther = [select Id, Default_Address__c, Household_Account__c from Address__c where 
            Household_Account__c in :mapAddrIdAccId.values()];
        map<Id, list<Address__c>> mapAccIdListAddrHH = new map<Id, list<Address__c>>();  
        for (Address__c addr : listAddrOther) {
        	list<Address__c> listAddrHH = mapAccIdListAddrHH.get(addr.Household_Account__c);
        	if (listAddrHH == null) {
        		listAddrHH = new list<Address__c>();
        		mapAccIdListAddrHH.put(addr.Household_Account__c, listAddrHH);
        	}
        	listAddrHH.add(addr);
        }
       
        // get all Contacts by HH, that might need updating
        list<Contact> listCon = [select Id, Address_Override__c, AccountId from Contact where 
            AccountId in :mapAddrIdAccId.values()];
        map<Id, list<Contact>> mapAccIdListCon = new map<Id, list<Contact>>();  
        for (Contact con : listCon) {
            list<Contact> listConHH = mapAccIdListCon.get(con.AccountId);
            if (listConHH == null) {
                listConHH = new list<Contact>();
                mapAccIdListCon.put(con.AccountId, listConHH);
            }
            listConHH.add(con);
        }

        // lists of objects to update
        list<Account> listAccUpdate = new list<Account>();
        list<Address__c> listAddrUpdate = new list<Address__c>();
        list<Contact> listConUpdate = new list<Contact>();
                
        for (SObject so : listNew) {
            Address__c addr = (Address__c)so;
            
            // get the Address's HH Account
            ID accId = mapAddrIdAccId.get(addr.Id);
            if (accId != null) {
            	boolean isOverrideOnly = setAccIdConOverrideOnly.contains(accId);
            	
            	if (!isOverrideOnly) {
                    // update HH Account's Billing address fields
	                Account acc = new Account(Id = accId);
	                acc.BillingStreet = addr.MailingStreet__c;
	                acc.BillingCity = addr.MailingCity__c;
	                acc.BillingState = addr.MailingState__c;
	                acc.BillingPostalCode = addr.MailingPostalCode__c;
	                acc.BillingCountry = addr.MailingCountry__c;
	                listAccUpdate.add(acc);
            	
	                // check other addresses on this household
	                for (Address__c addrHH : mapAccIdListAddrHH.get(accId)) {
	                    if (addrHH.Id == addr.Id)
	                        continue;
	                    if (addrHH.Default_Address__c) {
	                    	addrHH.Default_Address__c = false;
	                    	listAddrUpdate.add(addrHH);
	                    }	
	                }
                }

                // check other Contacts on this household
                for (Contact con : mapAccIdListCon.get(accId)) {
                    if ((!isOverrideOnly && con.Address_Override__c == null) || con.Address_Override__c == addr.Id) {
		                con.MailingStreet = addr.MailingStreet__c;
		                con.MailingCity = addr.MailingCity__c;
		                con.MailingState = addr.MailingState__c;
		                con.MailingPostalCode = addr.MailingPostalCode__c;
		                con.MailingCountry = addr.MailingCountry__c;
		                con.npe01__Primary_Address_Type__c = addr.Address_Type__c;
		                listConUpdate.add(con);
                    }   
                }
            }
        }
            
        if (listAccUpdate.size() > 0) {
        	system.debug('DJH**** listAccUpdate: ' + listAccUpdate);
            dmlWrapper.objectsToUpdate.putAll(listAccUpdate);
        }
        if (listAddrUpdate.size() > 0) {
            system.debug('DJH**** listAddrUpdate: ' + listAddrUpdate);
        	dmlWrapper.objectsToUpdate.putAll(listAddrUpdate);
        }
        if (listConUpdate.size() > 0) {
            system.debug('DJH**** listConUpdate: ' + listConUpdate);
            dmlWrapper.objectsToUpdate.putAll(listConUpdate);
        }
        return dmlWrapper;
    }
    
    // utility to compare two address objects
    private boolean isAddressChanged(Address__c addrNew, Address__c addrOld) {
    	if (addrNew == null || addrOld == null) 
    	   return false;
    	
    	return (
    	   addrNew.MailingStreet__c != addrOld.MailingStreet__c ||
           addrNew.MailingCity__c != addrOld.MailingCity__c ||
           addrNew.MailingState__c != addrOld.MailingState__c ||
           addrNew.MailingPostalCode__c != addrOld.MailingPostalCode__c ||
           addrNew.MailingCountry__c != addrOld.MailingCountry__c ||
           addrNew.Address_Type__c != addrOld.Address_Type__c);
    }
}