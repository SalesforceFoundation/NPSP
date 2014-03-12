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
        	system.debug('DJH**** stop Addr Trigger recursion');
            return null;
        }
        
        // first go through all new/modified Addresses, and collect the list of HH Accounts to consider.
        map<Id, Address__c> mapAccIdAddr = new map<Id, Address__c>(); // map of HH Accounts, and their default Address 
        map<Id, Address__c> mapAddrIdAddr = new map<Id, Address__c>(); // map of changed Addresses who need to only update any contact overrides.     

        integer i = 0;        
        for (SObject so : listNew) {
            Address__c addr = (Address__c)so;
            Address__c addrOld = (listOld != null) ? (Address__c)listOld[i] : null;
            
            // BEFORE INSERT
	        if (triggerAction == TDTM_TriggerActionHelper.Action.BeforeInsert) {
	           // when an address is marked Default, we update its latest date fields
	           if (addr.Default_Address__c) { 
	               addr.Latest_Start_Date__c = system.today();
	               addr.Latest_End_Date__c = null;
	           }
	        }
	        
            // BEFORE UPDATE
            if (triggerAction == TDTM_TriggerActionHelper.Action.BeforeUpdate) {
                if (addr.Default_Address__c != addrOld.Default_Address__c) {
                   // when an address changes Default, we update its latest date fields
                    if (addr.Default_Address__c) {
	                   addr.Latest_Start_Date__c = system.today();
	                   addr.Latest_End_Date__c = null;
                    } else {
                       addr.Latest_End_Date__c = system.today();                    	
                    }
                }
            }

            // AFTER INSERT
            if (triggerAction == TDTM_TriggerActionHelper.Action.AfterInsert) {
            	// a new address that is marked default or seasonal needs to propogate to the household
                if (addr.Default_Address__c || isSeasonalAddr(addr)) 
                    mapAccIdAddr.put(addr.Household_Account__c, addr);
            }
            
            // AFTER UPDATE
            if (triggerAction == TDTM_TriggerActionHelper.Action.AfterUpdate) {
                // an address that is marked default needs to propogate to the household
                if ((addr.Default_Address__c && (addr.Default_Address__c != addrOld.Default_Address__c)) 
                    // any seasonal address also need to be considered
                    || isSeasonalChanged(addr, addrOld)) {
                    mapAccIdAddr.put(addr.Household_Account__c, addr);
                } else if (isAddressChanged(addr, addrOld, true)) {
                    if (addr.Default_Address__c)
                        mapAccIdAddr.put(addr.Household_Account__c, addr);
                    else    // address changed, but not default, still need to update any contacts using it as an override
                        mapAddrIdAddr.put(addr.Id, addr);      
                } 
            }
            
            // moving to the next item
            i++;            
        }

        // BEFORE INSERT & BEFORE UPDATE
        if (triggerAction == TDTM_TriggerActionHelper.Action.BeforeInsert ||
           triggerAction == TDTM_TriggerActionHelper.Action.BeforeUpdate) {
            // enforce only HH Accounts are being used
            verifyAddrHHAccOnly((list<Address__c>)listNew);
            return null;    
        }

        // AFTER INSERT & AFTER UPDATE
        // now we have which HH Accounts to consider, and which to only use for Address Override updates.
        hasRunAddrTrigger = true;
        DmlWrapper dmlWrapper = new DmlWrapper();        
        
        if (mapAccIdAddr.size() > 0)        
            refreshCurrentHHAddress(mapAccIdAddr, dmlWrapper);
       
        if (mapAddrIdAddr.size() > 0) 
            updateAddrOverrides(mapAddrIdAddr, dmlWrapper);        
        
        return dmlWrapper;
    }
    
    
    // the main routine for finding the appropriate address to currently use for the
    // household and its contacts.  Prioritizes the Optional mapped Address as the Default
    // address, as well as checking to see if there is a seasonal address that should be used instead.
    public static void refreshCurrentHHAddress(map<Id, Address__c> mapAccIdAddr, DmlWrapper dmlWrapper) {
    	
    	// assumptions:
    	// called after all modifications saved to db
    	// so either from a scheduled job,
    	// or in the Address AfterUpdate trigger, AFTER any related objects updated
    	//
        // strategy:
        // for each hh, get all its addresses (query)
        // for each hh, find all its contacts (query)
        // for each hh, find its current seasonal or default address (loop calculation)
        // for each hh, update its billing fields with seasonal current/default
        // for each hh addr, clear its Default field if it isn't default
        // for each hh contact, if no override, update mailing fields with seasonal current/default
        //

        // get all Addresses by HH, that might need updating
        list<Id> listAccId = new list<Id>(mapAccIdAddr.keySet());
        map<Id, list<Address__c>> mapAccIdListAddrHH = getMapAccIdListAddrHH(listAccId);
       
        // get all Contacts by HH, that might need updating
        map<Id, list<Contact>> mapAccIdListCon = new map<Id, list<Contact>>();  
        list<Contact> listCon = [select Id, Address_Override__c, AccountId from Contact where AccountId in :mapAccIdAddr.keySet()];
        for (Contact con : listCon) {
            list<Contact> listConHH = mapAccIdListCon.get(con.AccountId);
            if (listConHH == null) {
                listConHH = new list<Contact>();
                mapAccIdListCon.put(con.AccountId, listConHH);
            }
            listConHH.add(con);
        }
        
        // for each hh, find the current address to use (seasonal vs default)
        map<Id, HHInfo> mapAccIdHHInfo = new map<Id, HHInfo>();
        for (Id accId : listAccId) {
            // create a HHInfo for each household        
            HHInfo hhinfo = new HHInfo();
            hhinfo.accId = accId;
            mapAccIdHHInfo.put(accId, hhinfo);

            // if there is a provided Default address, use it over all other defaults.
            Address__c addr = mapAccIdAddr.get(accId);
            if (addr != null && addr.Default_Address__c) 
                hhinfo.addrDefault = addr;

            // go through the hh addresses storing the default and any seasonal            
            for (Address__c addrHH : mapAccIdListAddrHH.get(accId)) { 
            	
            	if (hhinfo.addrDefault == null && addrHH.Default_Address__c)
            	   hhinfo.addrDefault = addrHH;
            	
            	if (addrHH.Seasonal_Start_Month__c != null && addrHH.Seasonal_Start_Day__c != null &&      
                   addrHH.Seasonal_End_Day__c != null && addrHH.Seasonal_End_Day__c != null) {
                   	integer startMonth = integer.valueOf(addrHH.Seasonal_Start_Month__c);
                    integer startDay = integer.valueOf(addrHH.Seasonal_Start_Day__c);
                    integer endMonth = integer.valueOf(addrHH.Seasonal_End_Month__c);
                    integer endDay = integer.valueOf(addrHH.Seasonal_End_Month__c);
                    Date dtStart;
                    Date dtEnd;
                    Date dtToday = system.today();
                   	if (startMonth <= endMonth) { 
                        dtStart = date.newInstance(dtToday.year(), startMonth, startDay);
                        dtEnd = date.newInstance(dtToday.year(), endMonth, endDay);
                   	} else {
                        dtStart = date.newInstance(dtToday.year(), endMonth, endDay);                           
                        dtEnd = date.newInstance(dtToday.year()+1, startMonth, startDay);
                   	}
                   	if (dtToday >= dtStart && dtToday < dtEnd) {
                   	    hhinfo.addrSeasonal = addrHH;
                   	}                        
                }      
            }
        }

        // lists of objects to update
        list<Account> listAccUpdate = new list<Account>();
        list<Address__c> listAddrUpdate = new list<Address__c>();
        list<Contact> listConUpdate = new list<Contact>();
        
        // now go through each HH, and do all the work!
        for (Id accId : listAccId) {
        	
        	// pick the address to use
        	HHInfo hhinfo = mapAccIdHHInfo.get(accId);
            Address__c addrDefault = hhinfo.addrDefault;
            Address__c addr = hhinfo.addrSeasonal;
            if (addr == null) 
                addr = addrDefault;

            // update HH Account's Billing address fields
            Account acc = new Account(Id = accId);
            acc.BillingStreet = addr.MailingStreet__c;
            acc.BillingCity = addr.MailingCity__c;
            acc.BillingState = addr.MailingState__c;
            acc.BillingPostalCode = addr.MailingPostalCode__c;
            acc.BillingCountry = addr.MailingCountry__c;
            listAccUpdate.add(acc);

            // check other addresses on this household that are no longer the default
            for (Address__c addrHH : mapAccIdListAddrHH.get(accId)) {
                if (addrHH.Id == addrDefault.Id)
                    continue;
                if (addrHH.Default_Address__c) {
                    addrHH.Default_Address__c = false;
                    addrHH.Latest_End_Date__c = system.today();
                    listAddrUpdate.add(addrHH);
                }   
            }

            // check the Contacts on this household
            for (Contact con : mapAccIdListCon.get(accId)) {
                if (con.Address_Override__c == null || con.Address_Override__c == addr.Id) {
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
    }
    
    // helper class to keep track of the default and seasonal address for a household
    private class HHInfo {
    	Id accId;              
    	Address__c addrDefault;      
    	Address__c addrSeasonal;        
    }
    
    // utility to see if the address has seasonal fields set
    private boolean isSeasonalAddr(Address__c addr) {
    	return (addr.Seasonal_Start_Month__c != null && addr.Seasonal_Start_Day__c != null &&
    	   addr.Seasonal_End_Month__c != null && addr.Seasonal_End_Day__c != null);
    }
    
    // for the map of addresses, update any contact's mailing fields that are using the address as an override.
    private void updateAddrOverrides(map<Id, Address__c> mapAddrIdAddr, DmlWrapper dmlWrapper) {    	
    	list<Contact> listCon = [select Id, Address_Override__c from Contact where Address_Override__c in :mapAddrIdAddr.keyset()];
    	for (Contact con : listCon) {
    		Address__c addr = mapAddrIdAddr.get(con.Address_Override__c);
            con.MailingStreet = addr.MailingStreet__c;
            con.MailingCity = addr.MailingCity__c;
            con.MailingState = addr.MailingState__c;
            con.MailingPostalCode = addr.MailingPostalCode__c;
            con.MailingCountry = addr.MailingCountry__c;
            con.npe01__Primary_Address_Type__c = addr.Address_Type__c;
            dmlWrapper.objectsToUpdate.put(con.Id, con);    		
    	}
    }
    
    // utility to create a map of HH Account Id to a list of Addresses in that HH, given a list of HH Account Id.
    private static map<Id, list<Address__c>> getMapAccIdListAddrHH(list<Id> listAccId) {
        map<Id, list<Address__c>> mapAccIdListAddrHH = new map<Id, list<Address__c>>();  
        list<Address__c> listAddrOther = [select Id, Default_Address__c, Household_Account__c, Address_Type__c,
            MailingStreet__c, MailingCity__c, MailingState__c, MailingPostalCode__c, MailingCountry__c, 
            Seasonal_Start_Month__c, Seasonal_Start_Day__c, Seasonal_End_Month__c, Seasonal_End_Day__c 
            from Address__c 
            where Household_Account__c in :listAccId];
        for (Address__c addr : listAddrOther) {
            list<Address__c> listAddrHH = mapAccIdListAddrHH.get(addr.Household_Account__c);
            if (listAddrHH == null) {
                listAddrHH = new list<Address__c>();
                mapAccIdListAddrHH.put(addr.Household_Account__c, listAddrHH);
            }
            listAddrHH.add(addr);
        }
        return mapAccIdListAddrHH;
    }
 
    // utility to compare two address objects seasonal fields
    private boolean isSeasonalChanged(Address__c addrNew, Address__c addrOld) {
    	if (addrNew == null || addrOld == null) 
    	   return false;    	
    	return (
    	   addrNew.Seasonal_Start_Month__c != addrOld.Seasonal_Start_Month__c ||
           addrNew.Seasonal_Start_Day__c != addrOld.Seasonal_Start_Day__c ||
           addrNew.Seasonal_End_Month__c != addrOld.Seasonal_End_Month__c ||
           addrNew.Seasonal_End_Day__c != addrOld.Seasonal_End_Day__c);
    }
    
    // utility to compare two address objects address fields
    private static boolean isAddressChanged(Address__c addrNew, Address__c addrOld, boolean includeAddressType) {
        if (addrNew == null || addrOld == null) 
           return false;        
        return (
           addrNew.MailingStreet__c != addrOld.MailingStreet__c ||
           addrNew.MailingCity__c != addrOld.MailingCity__c ||
           addrNew.MailingState__c != addrOld.MailingState__c ||
           addrNew.MailingPostalCode__c != addrOld.MailingPostalCode__c ||
           addrNew.MailingCountry__c != addrOld.MailingCountry__c ||
           (includeAddressType && (addrNew.Address_Type__c != addrOld.Address_Type__c)));
    }

    // verify that the account for each Address is a HH account
    private void verifyAddrHHAccOnly(list<Address__c> listAddr) {    	
    	set<Id> setAccId = new set<Id>();
    	for (Address__c addr : listAddr) {
    		if (addr.Household_Account__c != null) {
    			setAccId.add(addr.Household_Account__c);
    		}
    	}    	
    	map<Id, Account> mapAccIdAcc = new map<Id, Account>([select Id, npe01__SYSTEM_AccountType__c from Account where Id in :setAccId]);
        for (Address__c addr : listAddr) {
            if (addr.Household_Account__c == null) {
                //throw(new MyException(Label.addrHHAccountOnly));
                // had to use addError, or Salesforce would not stop its DML.
                addr.addError(Label.addrHHAccountOnly);
            } else {
                Account acc = mapAccIdAcc.get(addr.Household_Account__c);
                if (acc.npe01__SYSTEM_AccountType__c != CAO_Constants.HH_ACCOUNT_TYPE) {
                	//throw(new MyException(Label.addrHHAccountOnly));
                	// had to use addError, or Salesforce would not stop its DML.
                    addr.addError(Label.addrHHAccountOnly);
                }
            }
        }    	
    }
    
    private class MyException extends Exception {}
    
    // routine the scheduled batch job calls to update households with the specified Seasonal addresses
    public static void batchSeasonalUpdate(list<Address__c> listAddr) {
        if (listAddr == null || listAddr.size() == 0) return;
        
        map<Id, Address__c> mapAccIdAddr = new map<Id, Address__c>();
        for (Address__c addr : listAddr) 
            mapAccIdAddr.put(addr.Household_Account__c, addr);
        
        // must manually set our semaphore, so when we update contacts and households, they don't try to create additional addresses
        ADDR_Addresses_TDTM.hasRunAddrTrigger = true;       

        Dmlwrapper dmlWrapper = new Dmlwrapper();
        refreshCurrentHHAddress(mapAccIdAddr, dmlWrapper);
        TDTM_TriggerHandler.processDML(dmlWrapper);
    }
    
    // create only unique addresses from their respective household, and mark any existing matches as Default.
    public static void createNonDuplicateDefaultAddresses(list<Address__c> listAddr, DmlWrapper dmlWrapper) {   	
    	// for each address, create a map of HHId to lists of Addresses
    	list<Id> listAccId = new list<Id>();
    	for (Address__c addr : listAddr)
    	   listAccId.add(addr.Household_Account__c);
        map<Id, list<Address__c>> mapAccIdListAddrHH = getMapAccIdListAddrHH(listAccId);
        
        // now compare our Addresses to the existing Addresses
        for (Address__c addr : listAddr) {
            list<Address__c> listAddrHH = mapAccIdListAddrHH.get(addr.Household_Account__c);
            boolean hasMatch = false;
            if (listAddrHH != null) {
	            for (Address__c addrHH : listAddrHH) {
	            	if (!isAddressChanged(addr, addrHH, false)) {
	            	   // found match, make sure it is Default, and then bail out
	            	   hasMatch = true;
	            	   if (!addrHH.Default_Address__c) {
	            	       addrHH.Default_Address__c = true;
	            	       dmlWrapper.objectsToUpdate.put(addrHH.Id, addrHH);
	            	   }
	            	   break;
	            	}
	            }
            }
            if (!hasMatch)
                dmlWrapper.objectsToInsert.add(addr);
        }    	    	
    }
    
}