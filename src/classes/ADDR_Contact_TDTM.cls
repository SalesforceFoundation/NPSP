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
* @description support needed on Contact for Address management 
*/
public with sharing class ADDR_Contact_TDTM extends TDTM_Runnable {

    // the main entry point for TDTM to invoke our trigger handlers.
    public override DmlWrapper run(List<SObject> listNew, List<SObject> listOld, 
        TDTM_TriggerActionHelper.Action triggerAction, Schema.DescribeSObjectResult objResult) {
        	
        DmlWrapper dmlWrapper = new DmlWrapper();        
        list<Contact> listConAddrSet = new list<Contact>(); 
        list<Contact> listConCreateAddr = new list<Contact>();
        map<Id, boolean> mapAddrIdIsOverride = new map<Id, boolean>();
        list<Contact> listConAddrReset = new list<Contact>();
       
        integer i = 0;        
        for (SObject so : listNew) {
            Contact con = (Contact)so;

            // BEFORE INSERT
            if (triggerAction == TDTM_TriggerActionHelper.Action.BeforeInsert) {
                if (con.Address_Override__c != null) {
                    listConAddrSet.add(con);
                    mapAddrIdIsOverride.put(con.Address_Override__c, true);
                }
            }
            
            // BEFORE UPDATE
            if (triggerAction == TDTM_TriggerActionHelper.Action.BeforeUpdate) {
            	Contact conOld = (Contact)listOld[i];
                if (con.Address_Override__c != conOld.Address_Override__c) {
                	if (con.Address_Override__c != null) {
                        listConAddrSet.add(con);
                        mapAddrIdIsOverride.put(con.Address_Override__c, true);
                	}
                	if (conOld.Address_Override__c != null) {
                        mapAddrIdIsOverride.put(conOld.Address_Override__c, false);
                        listConAddrReset.add(con);
                	}                        
                }
            }
            
            // AFTER INSERT
            if (triggerAction == TDTM_TriggerActionHelper.Action.AfterInsert) {

            }
    
            // BEFORE UPDATE & AFTER UPDATE
            // our functionality for dealing with contact address changes requires some trickery!
            // if the contact doesn't have an address override, we create (or match) a default address,
            // which requires us to do the work in the AfterUpdate (or else we can't propagate the default address).
            // but if the contact has an address override, we are supposed to create (or match) a non default address override.
            // in order to update the contact with the new address override's Id, we have to do it in the BeforeUpdate.
            if (triggerAction == TDTM_TriggerActionHelper.Action.BeforeUpdate ||
               triggerAction == TDTM_TriggerActionHelper.Action.AfterUpdate) {
                Contact conOld = (Contact)listOld[i];
                // note that we detect whether the address change is coming from the address trigger,
                // in which case we don't want to create a new address.
                if (ADDR_Addresses_TDTM.hasRunAddrTrigger)
                    continue;
                // we only support address management with HH Accounts being used
                if (con.HHId__c == null || con.HHId__c != con.AccountId)
                    continue;
                // if the address changed, remember the contact we want to add a new address for    
                if (isContactAddressChanged(con, conOld)) 
                    listConCreateAddr.add(con);
            }  
           
            // moving to the next item
            i++;  
        }
        
        // set the mailing address for contacts who specify an address override
        if (listConAddrSet.size() > 0) {
            setConAddrFromOverride(listConAddrSet);
            // to avoid pushing these address changes to the HH.
            ADDR_Addresses_TDTM.hasRunAddrTrigger = true;
        }
        
        // reset the mailing address for contacts who no longer have an address override
        if (listConAddrReset.size() > 0) {
        	resetConAddr(listConAddrReset);
            // to avoid pushing these address changes to the HH.
            ADDR_Addresses_TDTM.hasRunAddrTrigger = true;
        }
        
        // update the Latest date fields on any address overrides
        if (mapAddrIdIsOverride.size() > 0) 
            updateAddrIsOverride(mapAddrIdIsOverride, dmlWrapper);
            
        // create any new Address objects
        if (listConCreateAddr.size() > 0)
            createAddrFromCon(listConCreateAddr, dmlWrapper, triggerAction == TDTM_TriggerActionHelper.Action.BeforeUpdate);
            
        return dmlWrapper;    
    }

    // for each contact, refresh its mailing address from its Address Override
    private void setConAddrFromOverride(list<Contact> listCon) {
    	set<Id> setAddrId = new set<Id>();
    	for (Contact con : listCon) {
    		if (con.Address_Override__c != null)
    		  setAddrId.add(con.Address_Override__c);
    	}
    
        map<Id, Address__c> mapAddrIdAddr = new map<Id, Address__c>([select Id, Address_Type__c, MailingStreet__c, MailingCity__c, MailingState__c, 
            MailingPostalCode__c, MailingCountry__c from Address__c where Id in :setAddrId]);
        system.debug('DJH**** mapAddrIdAddr: ' + mapAddrIdAddr);
            
        for (Contact con : listCon) {
            Address__c addr = mapAddrIdAddr.get(con.Address_Override__c);
            if (addr != null) {
            	con.npe01__Primary_Address_Type__c = addr.Address_Type__c;
            	con.MailingStreet = addr.MailingStreet__c;
            	con.MailingCity = addr.MailingCity__c;
            	con.MailingState = addr.MailingState__c;
            	con.MailingPostalCode = addr.MailingPostalCode__c;
            	con.MailingCountry = addr.MailingCountry__c;
            }
        }     	
        system.debug('DJH**** listCon: ' + listCon);
    }

    // utility to compare two contacts' addresses
    private boolean isContactAddressChanged(Contact con1, Contact con2) {
        if (con1 == null || con2 == null) 
           return false;
        
        return (
           con1.MailingStreet != con2.MailingStreet ||
           con1.MailingCity != con2.MailingCity ||
           con1.MailingState != con2.MailingState ||
           con1.MailingPostalCode != con2.MailingPostalCode ||
           con1.MailingCountry != con2.MailingCountry ||
           con1.npe01__Primary_Address_Type__c != con2.npe01__Primary_Address_Type__c);
    }

    // for each contact, create a new address (or match an existing one).
    // BeforeUpdate: if they did have an override, create a new non-default address and update the override.
    // AfterUpdate: if they didn't have an address override, create a new default address.
    // due to this dual behavior, this routine is called both by BeforeUpdate and AfterUpdate.
    private void createAddrFromCon(list<Contact> listConAll, DmlWrapper dmlWrapper, boolean isBeforeUpdate) {
    	
    	// Strategy:
    	// create a new (unsaved) address for each contact.
    	// see if there is an existing address that matches each new address.
    	// for contacts who currently have an override (BeforeUpdate), 
    	//     if there is a match, set the contact's address override
    	//     if no match, create the addr NOW, set the contact's address override
    	// for contacts who have no override (AfterUpdate),
    	//     if there is a match, make sure it is marked default, and put it on dmlWrapper
    	//     if there is no match, make the new address default, and put it on dmlWrapper
    	
    	map<Id, Address__c> mapConIdAddr = new map<Id, Address__c>();
    	list<Contact> listCon = new list<Contact>();
    	
        for (Contact con : listConAll) {
        	boolean hasOverride = con.Address_Override__c != null;
        	
        	// during BeforeUpdate, only deal with Contacts with address overrides.
        	// during AfterUpdate, only deal with Contacts without address overrides.
        	if (isBeforeUpdate == hasOverride) {
	            listCon.add(con);
	        	Address__c addr = new Address__c();
	        	addr.Household_Account__c = con.AccountId;
	        	addr.Default_Address__c = !hasOverride;
	        	addr.Latest_Start_Date__c = system.today();
	        	addr.Latest_End_Date__c = null;
	        	addr.MailingStreet__c = con.MailingStreet;
	        	addr.MailingCity__c = con.MailingCity;
	        	addr.MailingState__c = con.MailingState;
	        	addr.MailingPostalCode__c = con.MailingPostalCode;
	        	addr.MailingCountry__c = con.MailingCountry;
	        	addr.Address_Type__c = con.npe01__Primary_Address_Type__c;
	            mapConIdAddr.put(con.Id, addr);
        	}        	
        }

        // look for duplicates for our proposed new addresses        
        map<Address__c, Address__c> mapAddrDupAddr= ADDR_Addresses_TDTM.findDuplicateAddresses(mapConIdAddr.values());
        
        // map to keep track of the new addresses we create that we need to set as address overrides.
        map<Contact, Address__c> mapConAddrNew = new map<Contact, Address__c>();
        
        for (Contact con : listCon) {
            Address__c addrNew = mapConIdAddr.get(con.Id);
            Address__c addrDup = mapAddrDupAddr.get(addrNew);
            
            // if no override, create/use a default address
            if (con.Address_Override__c == null) {
            	if (addrDup != null) {
            	   if (!addrDup.Default_Address__c) {
            	       addrDup.Default_Address__c = true;
            	       dmlWrapper.objectsToUpdate.put(addrDup.Id, addrDup);
            	   }
            	} else {
            		addrNew.Default_Address__c = true;
            		dmlWrapper.objectsToInsert.add(addrNew);
            	}
            // contact has an override, create/use a non-default address and update the override
            } else {
                if (addrDup != null) {
                	con.Address_Override__c = addrDup.Id;
                } else {
                    mapConAddrNew.put(con, addrNew);
                }
            }            
        }
        
        // create any needed new addresses 
        insert mapConAddrNew.values();
        
        // update any contact address overrides
        for (Contact con : mapConAddrNew.keySet()) {
        	Address__c addr = mapConAddrNew.get(con);
        	con.Address_Override__c = addr.Id;
        }        
    }

    // update the Latest date fields on any address overrides
    private void updateAddrIsOverride(Map<Id, boolean> mapAddrIdIsOverride, DmlWrapper dmlWrapper) {

        for (ID id : mapAddrIdIsOverride.keySet()) {
            Address__c addr = new Address__c();
            addr.Id = id;
            if (mapAddrIdIsOverride.get(id) == true) {
            	addr.Latest_Start_Date__c = system.today();
            	addr.Latest_End_Date__c = null;
            } else {
                addr.Latest_End_Date__c = system.today();
            }
            dmlWrapper.objectsToUpdate.put(id, addr);
        }        
    }

    // for each Contact, find its HH current address (either Default or Seasonal) and update the contact's address fields
    private void resetConAddr(list<Contact> listCon) {
        if (listCon == null || listCon.size() == 0) return;
        
        map<Id, Address__c> mapAccIdAddr = new map<Id, Address__c>();
        for (Contact con : listCon) 
            mapAccIdAddr.put(con.AccountId, null);
            
        // get the default and seasonal address for each HH
        map<Id, ADDR_Addresses_TDTM.HHInfo> mapAccIdHHInfo = ADDR_Addresses_TDTM.refreshCurrentHHAddress(mapAccIdAddr, null, true);
        
        // reset the Contact's address fields with the appropriate address
        for (Contact con : listCon) {
        	ADDR_Addresses_TDTM.HHInfo hhinfo = mapAccIdHHInfo.get(con.AccountId);
        	if (hhinfo != null) {
        		Address__c addr = hhinfo.addrSeasonal;
        		if (addr == null)
        		  addr = hhinfo.addrDefault;
                if (addr != null) {
                	con.MailingStreet = addr.MailingStreet__c;
                	con.MailingCity = addr.MailingCity__c;
                	con.MailingState = addr.MailingState__c;
                	con.MailingPostalCode = addr.MailingPostalCode__c;
                	con.MailingCountry = addr.MailingCountry__c;
                	con.npe01__Primary_Address_Type__c = addr.Address_Type__c;
                }        	   
        	}
        }         
    }

}