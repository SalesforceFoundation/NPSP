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
* @description trigger handler on Address object to support propagating addresses 
*/
public with sharing class ADDR_Addresses_TDTM extends TDTM_Runnable {

    // static flags to prevent recursive call 
    public static boolean hasRunAddrTrigger = false;

    public static Boolean isStateCountryPicklistsEnabled = false;
    public static Map<Id, String> addressErrors = new Map<Id, String>();

    // the main entry point for TDTM to invoke our trigger handlers.
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
        if (hasRunAddrTrigger) {
        	//UTIL_Debug.debug('DJH**** stop Addr Trigger recursion');
            return null;
        }

        // If State & Country Picklists are enabled in the org, build sets of the
        // valid Labels and Codes for each field to use for validation
        isStateCountryPicklistsEnabled = UTIL_Describe.initValidStateCountryCodes();

        // first go through all new/modified Addresses, and collect the list of HH Accounts to consider.
        map<Id, Address__c> mapAccIdAddr = new map<Id, Address__c>(); // map of HH Accounts, and their default Address 
        map<Id, Address__c> mapAddrIdAddr = new map<Id, Address__c>(); // map of changed Addresses who need to only update any contact overrides.     

        integer i = 0;        
        for (SObject so : listNew) {
            Address__c addr = (Address__c)so;
            Address__c addrOld = (listOld != null) ? (Address__c)listOld[i] : null;
            
            // BEFORE INSERT
	        if (triggerAction == TDTM_Runnable.Action.BeforeInsert) {
	           // when an address is marked Default, we update its latest date fields
	           if (addr.Default_Address__c) { 
	               addr.Latest_Start_Date__c = system.today();
	               addr.Latest_End_Date__c = null;
	           }
	        }
	        
            // BEFORE UPDATE
            if (triggerAction == TDTM_Runnable.Action.BeforeUpdate) {
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
            if (triggerAction == TDTM_Runnable.Action.AfterInsert) {
            	// a new address that is marked default or seasonal needs to propogate to the household
                if (addr.Default_Address__c || isSeasonalAddr(addr)) 
                    mapAccIdAddr.put(addr.Household_Account__c, addr);
            }
            
            // AFTER UPDATE
            if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
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
        if (triggerAction == TDTM_Runnable.Action.BeforeInsert ||
           triggerAction == TDTM_Runnable.Action.BeforeUpdate) {
            // enforce only HH Accounts are being used
            verifyAddrHHAccOnly((list<Address__c>)listNew);
            
            // enforce Seasonal Addresses don't overlap
            verifyAddrSeasonalNoOverlap((list<Address__c>)listNew);
            
            return null;    
        }

        // AFTER INSERT & AFTER UPDATE
        // now we have which HH Accounts to consider, and which to only use for Address Override updates.
        hasRunAddrTrigger = true;
        DmlWrapper dmlWrapper = new DmlWrapper();        
        
        if (mapAccIdAddr.size() > 0)        
            refreshCurrentHHAddress(mapAccIdAddr, dmlWrapper, false);
       
        if (mapAddrIdAddr.size() > 0) 
            updateAddrOverrides(mapAddrIdAddr, dmlWrapper);        
        
        return dmlWrapper;
    }
    
    
    // the main routine for finding the appropriate address to currently use for the
    // household and its contacts.  Prioritizes the Optional mapped Address as the Default
    // address, as well as checking to see if there is a seasonal address that should be used instead.
    // if the flag isCalcHHInfoOnly is set, then this routine will return the map of HHId to HHInfo,
    // and not do any changes to dmlWrapper. 
    public static map<Id, HHInfo> refreshCurrentHHAddress(map<Id, Address__c> mapAccIdAddr, DmlWrapper dmlWrapper, boolean isCalcHHInfoOnly) {
    	
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
            if (mapAccIdListAddrHH.get(accId) != null) {         
	            for (Address__c addrHH : mapAccIdListAddrHH.get(accId)) { 
	            	
	            	if (hhinfo.addrDefault == null && addrHH.Default_Address__c)
	            	   hhinfo.addrDefault = addrHH;
	            	
	            	if (isSeasonalAddr(addrHH)) {
	                    Date dtStart = dtStartOrEndOfAddrSeasonal(addrHH, true);
	                    Date dtEnd = dtStartOrEndOfAddrSeasonal(addrHH, false);
	                    Date dtToday = system.today();
	                   	if (dtToday >= dtStart && dtToday < dtEnd) {
	                   	    hhinfo.addrSeasonal = addrHH;
	                   	}                        
	                }      
	            }
            }
        }
        
        // some callers just need the HHInfo for each HH Account.
        if (isCalcHHInfoOnly)
            return mapAccIdHHInfo;

        // get all Contacts by HH, that might need updating
        // note that if we have an organizational account, our query will not pick up any contacts (by design!)
        map<Id, list<Contact>> mapAccIdListCon = new map<Id, list<Contact>>();  
        list<Contact> listCon = [select Id, is_Address_Override__c, Current_Address__c, AccountId from Contact where HHId__c in :mapAccIdAddr.keySet()];
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
            acc.BillingStreet = getMultilineStreet(addr);
            acc.BillingCity = addr.MailingCity__c;
            acc.BillingPostalCode = addr.MailingPostalCode__c;

            if (!isStateCountryPicklistsEnabled) {
                acc.BillingState = addr.MailingState__c;
                acc.BillingCountry = addr.MailingCountry__c;
            } else {
                if (addr.MailingCountry__c != null) {
                    if (UTIL_Describe.validCountriesByLabel.containsKey(addr.MailingCountry__c)) {
                        acc.BillingCountry = addr.MailingCountry__c;
                        acc.put('BillingCountryCode', UTIL_Describe.validCountriesByLabel.get(addr.MailingCountry__c));
                    } else if (UTIL_Describe.validCountriesByCode.containsKey(addr.MailingCountry__c)) {
                        acc.put('BillingCountryCode', addr.MailingCountry__c);
                        acc.BillingCountry = UTIL_Describe.validCountriesByCode.get(addr.MailingCountry__c);
                    } else {
                        addressErrors.put(addr.Id, 
                            Label.Address_StateCountry_Invalid_Error.replace('{0}', addr.MailingCountry__c));
                    }
                }
                if (addr.MailingState__c != null) {
                    if (UTIL_Describe.validStatesByLabel.containsKey(addr.MailingState__c)) {
                        acc.BillingState = addr.MailingState__c;
                        acc.put('BillingStateCode', UTIL_Describe.validStatesByLabel.get(addr.MailingState__c));
                    } else if (UTIL_Describe.validStatesByCode.containsKey(addr.MailingState__c)) {
                        acc.put('BillingStateCode', addr.MailingState__c);
                        acc.BillingState = UTIL_Describe.validStatesByCode.get(addr.MailingState__c);
                    } else {
                        addressErrors.put(addr.Id, 
                            Label.Address_StateCountry_Invalid_Error.replace('{0}', addr.MailingState__c));
                    }
                }
            }

            listAccUpdate.add(acc);

            
	        // check other addresses on this household that are no longer the default
	        if (mapAccIdListAddrHH != null && mapAccIdListAddrHH.size() > 0) {
	            for (Address__c addrHH : mapAccIdListAddrHH.get(accId)) {
	                if (addrHH.Id == addrDefault.Id)
	                    continue;
	                if (addrHH.Default_Address__c) {
	                    addrHH.Default_Address__c = false;
	                    addrHH.Latest_End_Date__c = system.today();
	                    listAddrUpdate.add(addrHH);
	                }   
	            }
            }

            // check the Contacts on this household
            if (mapAccIdListCon != null && mapAccIdListCon.size() > 0) {
	            for (Contact con : mapAccIdListCon.get(accId)) {
	                if (con.is_Address_Override__c == false || con.Current_Address__c == addr.Id) {
	                    con.MailingStreet = getMultilineStreet(addr);
	                    con.MailingCity = addr.MailingCity__c;
	                    con.MailingPostalCode = addr.MailingPostalCode__c;
	                    con.npe01__Primary_Address_Type__c = addr.Address_Type__c;
	                    con.Current_Address__c = addr.Id;

                        if (!isStateCountryPicklistsEnabled) {
                            con.MailingState = addr.MailingState__c;
                            con.MailingCountry = addr.MailingCountry__c;
                        } else {
                            if (addr.MailingCountry__c != null) {
                                if (UTIL_Describe.validCountriesByLabel.containsKey(addr.MailingCountry__c)) {
                                    con.MailingCountry = addr.MailingCountry__c;
                                    con.put('MailingCountryCode', UTIL_Describe.validCountriesByLabel.get(addr.MailingCountry__c));
                                } else if (UTIL_Describe.validCountriesByCode.containsKey(addr.MailingCountry__c)) {
                                    con.put('MailingCountryCode', addr.MailingCountry__c);
                                    con.MailingCountry = UTIL_Describe.validCountriesByCode.get(addr.MailingCountry__c);
                                } else {
                                    addressErrors.put(addr.Id, 
                                        Label.Address_StateCountry_Invalid_Error.replace('{0}', addr.MailingCountry__c));
                                }
                            }
                            if (addr.MailingState__c != null) {
                                if (UTIL_Describe.validStatesByLabel.containsKey(addr.MailingState__c)) {
                                    con.MailingState = addr.MailingState__c;
                                    con.put('MailingStateCode', UTIL_Describe.validStatesByLabel.get(addr.MailingState__c));
                                } else if (UTIL_Describe.validStatesByCode.containsKey(addr.MailingState__c)) {
                                    con.put('MailingStateCode', addr.MailingState__c);
                                    con.MailingState = UTIL_Describe.validStatesByCode.get(addr.MailingState__c);
                                } else {
                                    addressErrors.put(addr.Id, 
                                        Label.Address_StateCountry_Invalid_Error.replace('{0}', addr.MailingState__c));
                                }
                            }
                        }
	                    listConUpdate.add(con);
	                }   
	            }
            }
        }  
                    
        if (listAccUpdate.size() > 0) {
            //UTIL_Debug.debug('DJH**** listAccUpdate: ' + listAccUpdate);
            dmlWrapper.objectsToUpdate.addAll((List<SObject>)listAccUpdate);
        }
        if (listAddrUpdate.size() > 0) {
            //UTIL_Debug.debug('DJH**** listAddrUpdate: ' + listAddrUpdate);
            dmlWrapper.objectsToUpdate.addAll((List<SObject>)listAddrUpdate);
        }
        if (listConUpdate.size() > 0) {
            //UTIL_Debug.debug('DJH**** listConUpdate: ' + listConUpdate);
            dmlWrapper.objectsToUpdate.addAll((List<SObject>)listConUpdate);
        }
        
        if (addressErrors.size() > 0) {
            ERR_Handler errHandler = new ERR_Handler();
            for (Id addrId : addressErrors.keySet()) {
                errHandler.queueError('Address__c', addrId, addressErrors.get(addrId), 
                    'Address Update Error', 'ADDR_Address_TDTM');
            }
            errHandler.storeErrors();
        }

        return mapAccIdHHInfo;
    }
    
    // helper class to keep track of the default and seasonal address for a household
    public class HHInfo {
    	public Id accId;              
    	public Address__c addrDefault;      
    	public Address__c addrSeasonal;        
    }

    // utility to return the current StartDate or EndDate of a Seasonal Address 
    private static Date dtStartOrEndOfAddrSeasonal(Address__c addr, boolean fStart) {    
        integer startMonth = integer.valueOf(addr.Seasonal_Start_Month__c);
        integer startDay = integer.valueOf(addr.Seasonal_Start_Day__c);
        integer endMonth = integer.valueOf(addr.Seasonal_End_Month__c);
        integer endDay = integer.valueOf(addr.Seasonal_End_Day__c);
        Date dtStart;
        Date dtEnd;
        Date dtToday = system.today();
        if (startMonth <= endMonth) { 
            dtStart = date.newInstance(dtToday.year(), startMonth, startDay);
            dtEnd = date.newInstance(dtToday.year(), endMonth, endDay);
        } else {
            dtStart = date.newInstance(dtToday.year(), startMonth, startDay);                           
            dtEnd = date.newInstance(dtToday.year()+1, endMonth, endDay);
        }
        return (fStart ? dtStart : dtEnd);
    }
    
    // utility to see if the address has seasonal fields set
    private static boolean isSeasonalAddr(Address__c addr) {
    	return (addr.Seasonal_Start_Month__c != null && addr.Seasonal_Start_Day__c != null &&
    	   addr.Seasonal_End_Month__c != null && addr.Seasonal_End_Day__c != null);
    }
    
    // utility to see if the address has only a subset of its seasonal fields set
    private static boolean isPartialSeasonalAddr(Address__c addr) {
        integer cParts = 0;
        if (addr.Seasonal_Start_Month__c != null) cParts++;
        if (addr.Seasonal_Start_Day__c != null) cParts++;
        if (addr.Seasonal_End_Month__c != null) cParts++;
        if (addr.Seasonal_End_Day__c != null) cParts++;
        return (cParts > 0 && cParts < 4);
    }
    
    // for the map of addresses, update any contact's mailing fields that are using the address as an override.
    private void updateAddrOverrides(map<Id, Address__c> mapAddrIdAddr, DmlWrapper dmlWrapper) {    	
    	list<Contact> listCon = [select Id, is_Address_Override__c, Current_Address__c from Contact where is_Address_Override__c = true and Current_Address__c in :mapAddrIdAddr.keyset()];
    	for (Contact con : listCon) {
    		Address__c addr = mapAddrIdAddr.get(con.Current_Address__c);
            con.MailingStreet = getMultilineStreet(addr);
            con.MailingCity = addr.MailingCity__c;
            con.MailingPostalCode = addr.MailingPostalCode__c;

            if (!isStateCountryPicklistsEnabled) {
                con.MailingState = addr.MailingState__c;
                con.MailingCountry = addr.MailingCountry__c;
            } else {
                if (addr.MailingCountry__c != null) {
                    if (UTIL_Describe.validCountriesByLabel.containsKey(addr.MailingCountry__c)) {
                        con.MailingCountry = addr.MailingCountry__c;
                        con.put('MailingCountryCode', UTIL_Describe.validCountriesByLabel.get(addr.MailingCountry__c));
                    } else if (UTIL_Describe.validCountriesByCode.containsKey(addr.MailingCountry__c)) {
                        con.put('MailingCountryCode', addr.MailingCountry__c);
                        con.MailingCountry = UTIL_Describe.validCountriesByCode.get(addr.MailingCountry__c);
                    } else {
                        addressErrors.put(addr.Id, 
                            Label.Address_StateCountry_Invalid_Error.replace('{0}', addr.MailingCountry__c));
                    }
                }
                if (addr.MailingState__c != null) {
                    if (UTIL_Describe.validStatesByLabel.containsKey(addr.MailingState__c)) {
                        con.MailingState = addr.MailingState__c;
                        con.put('MailingStateCode', UTIL_Describe.validStatesByLabel.get(addr.MailingState__c));
                    } else if (UTIL_Describe.validStatesByCode.containsKey(addr.MailingState__c)) {
                        con.put('MailingStateCode', addr.MailingState__c);
                        con.MailingState = UTIL_Describe.validStatesByCode.get(addr.MailingState__c);
                    } else {
                        addressErrors.put(addr.Id, 
                            Label.Address_StateCountry_Invalid_Error.replace('{0}', addr.MailingState__c));
                    }
                }
            }

            con.npe01__Primary_Address_Type__c = addr.Address_Type__c;
            dmlWrapper.objectsToUpdate.add(con);    		
    	}
    }
    
    // utility to create a map of HH Account Id to a list of Addresses in that HH, given a list of HH Account Id.
    private static map<Id, list<Address__c>> getMapAccIdListAddrHH(list<Id> listAccId) {
        map<Id, list<Address__c>> mapAccIdListAddrHH = new map<Id, list<Address__c>>();  
        list<Address__c> listAddrOther = [select Id, Default_Address__c, Household_Account__c, Address_Type__c,
            MailingStreet__c, MailingStreet2__c, MailingCity__c, MailingState__c, MailingPostalCode__c, MailingCountry__c, 
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
           addrNew.MailingStreet2__c != addrOld.MailingStreet2__c ||
           addrNew.MailingCity__c != addrOld.MailingCity__c ||
           addrNew.MailingState__c != addrOld.MailingState__c ||
           addrNew.MailingPostalCode__c != addrOld.MailingPostalCode__c ||
           addrNew.MailingCountry__c != addrOld.MailingCountry__c ||
           (includeAddressType && (addrNew.Address_Type__c != addrOld.Address_Type__c)));
    }

    // utility to create the month and day strings to a decimal we can use in comparisons.
    private static decimal decimalOfMonthDay(string m, string d) {
        if (integer.valueOf(d) < 10)
            return decimal.valueOf(m + '.0' + d);
        else
            return decimal.valueOf(m + '.' + d);
    }
    
    // utility to see if two seasonal addresses overlap
    public static boolean isSeasonalOverlap(Address__c addr1, Address__c addr2) {
        if (addr1 == null || addr2 == null) 
            return false;        
        if (!isSeasonalAddr(addr1) || !isSeasonalAddr(addr2))
            return false;
            
        // we don't need to know what year or month we are currently in, but
        // we need to take into account days (since we could be in the same month).
        // to make this easy to compare, we convert month & day to be a decimal of month.day.  
        // eg., 3.01 for Feb 1st and 3.28 for Feb 28th.
        decimal start1 = decimalOfMonthDay(addr1.Seasonal_Start_Month__c, addr1.Seasonal_Start_Day__c);
        decimal end1 = decimalOfMonthDay(addr1.Seasonal_End_Month__c, addr1.Seasonal_End_Day__c);
        decimal start2 = decimalOfMonthDay(addr2.Seasonal_Start_Month__c, addr2.Seasonal_Start_Day__c);
        decimal end2 = decimalOfMonthDay(addr2.Seasonal_End_Month__c, addr2.Seasonal_End_Day__c);
                
        // now we see if the ranges are increasing (Jan '14 - March '14), or decreasing (Nov 14' - Feb '15),
        boolean range1Increases = start1 < end1;
        boolean range2Increases = start2 < end2;

        // we can now tell if there is overlap simply by looking at three scenarios: 
        // 1. both ranges increase, make sure start1 not in range2, and start2 not in range1.
        if (range1Increases && range2Increases) {
            return (start1 >= start2 && start1 <= end2) || (start2 >= start1 && start2 <= end1);
        }    
        // 2. one range increases, one range decreases, make sure end1 not in range2, and end2 not in range1.
        else if (range1Increases != range2Increases) {
            return (end1 >= start2 && end1 <= end2) || (end2 >= start1 && end2 <= end1);
        }
        // 3. both ranges decrease, always implies an overlap of the new year!
        else {
            return true;
        }
    }

    // verify that the account for each Address is a HH account
    // or an Organizational account if enabled.
    private void verifyAddrHHAccOnly(list<Address__c> listAddr) {    	
    	set<Id> setAccId = new set<Id>();
    	for (Address__c addr : listAddr) {
    		if (addr.Household_Account__c != null) {
    			setAccId.add(addr.Household_Account__c);
    		}
    	}    	
    	map<Id, Account> mapAccIdAcc = new map<Id, Account>([select Id, npe01__SYSTEM_AccountType__c, npe01__SYSTEMIsIndividual__c 
    	   from Account where Id in :setAccId]);
        for (Address__c addr : listAddr) {
            if (addr.Household_Account__c == null) {
                //throw(new MyException(Label.addrHHAccountOnly));
                // had to use addError, or Salesforce would not stop its DML.
                addr.addError(Label.addrHHAccountOnly);
            } else {
                Account acc = mapAccIdAcc.get(addr.Household_Account__c);
                if ( (acc.npe01__SYSTEM_AccountType__c != CAO_Constants.HH_ACCOUNT_TYPE) &&
                    (acc.npe01__SYSTEMIsIndividual__c || !UTIL_CustomSettingsFacade.getContactsSettings().Organizational_Account_Addresses_Enabled__c)) {
                	//throw(new MyException(Label.addrHHAccountOnly));
                	// had to use addError, or Salesforce would not stop its DML.
                    addr.addError(Label.addrHHAccountOnly);
                }
            }
        }    	
    }
    
    // verify that any seasonal addresses don't overlap
    private void verifyAddrSeasonalNoOverlap(list<Address__c> listAddr) { 
    	
    	// first get just the seasonal addresses
    	list<Address__c> listAddrS = new list<Address__c>();
    	for (Address__c addr : listAddr) {
            if (isSeasonalAddr(addr)) {
                listAddrS.add(addr);
            } else if (isPartialSeasonalAddr(addr)) {
                addr.addError(Label.addrSeasonalPartial);                
            }
    	}      
    	
    	// if none are seasonal, we can bail out
    	if (listAddrS.size() == 0)
    	   return;

        // protect against overlaps within the set being inserted or updated
        for (Address__c addr : listAddrS) {
            for (Address__c addr2 : listAddrS) {
                if (addr == addr2)
                    continue;
                if (addr.Household_Account__c != addr2.Household_Account__c)
                    continue;  
                if (isSeasonalOverlap(addr, addr2)) {
                    addr.addError(Label.addrSeasonalOverlap);
                }
            }
        }

        // now check for overlaps within each household's saved addresses
        list<Id> listAccId = new list<Id>();
        for (Address__c addr : listAddrS) {
            listAccId.add(addr.Household_Account__c);
        }        
        map<Id, list<Address__c>> mapAccIdListAddrHH = getMapAccIdListAddrHH(listAccId);        
        
        for (Address__c addr : listAddrS) {
            for (Address__c addr2 : mapAccIdListAddrHH.get(addr.Household_Account__c)) {
            	if (addr.id == addr2.id)
            	   continue;
                if (isSeasonalOverlap(addr, addr2)) {
                    addr.addError(Label.addrSeasonalOverlap);
                    break;
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
        refreshCurrentHHAddress(mapAccIdAddr, dmlWrapper, false);
        TDTM_TriggerHandler.processDML(dmlWrapper);
    }
    
    // create only unique addresses from their respective household, and mark any existing matches 
    // as Default if the caller specifies it on the new address.
    public static void createNonDuplicateAddresses(list<Address__c> listAddr, DmlWrapper dmlWrapper) {  
    	
    	map<Address__c, Address__c> mapAddrDupAddr= ADDR_Addresses_TDTM.findDuplicateAddresses(listAddr);
    	for (Address__c addrNew : listAddr) {
            Address__c addrDup = mapAddrDupAddr.get(addrNew);
            if (addrDup != null) {
               if (addrNew.Default_Address__c && !addrDup.Default_Address__c) {
                   addrDup.Default_Address__c = true;
                   dmlWrapper.objectsToUpdate.add(addrDup);
               }
            } else {
                dmlWrapper.objectsToInsert.add(addrNew);
            }    	
    	}	
    }
    
    // for the given addresses, find if they have a match, and return a map that
    // has null for no match, and the matching address if there is a match.
    public static map<Address__c, Address__c> findDuplicateAddresses(list<Address__c> listAddr) {      
        // for each address, create a map of HHId to lists of Addresses
        list<Id> listAccId = new list<Id>();
        for (Address__c addr : listAddr)
           listAccId.add(addr.Household_Account__c);
        map<Id, list<Address__c>> mapAccIdListAddrHH = getMapAccIdListAddrHH(listAccId);
        
        // create our map for returning information in
        map<Address__c, Address__c> mapAddrDupAddr = new map<Address__c, Address__c>();
        
        // now compare our Addresses to the existing Addresses
        for (Address__c addr : listAddr) {
            list<Address__c> listAddrHH = mapAccIdListAddrHH.get(addr.Household_Account__c);
            boolean hasMatch = false;
            if (listAddrHH != null) {
                for (Address__c addrHH : listAddrHH) {
                    if (!isAddressChanged(addr, addrHH, false)) {
                       // found match, record it and bail out
                       hasMatch = true;
                       mapAddrDupAddr.put(addr, addrHH);
                       break;
                    }
                }
            }
            if (!hasMatch)
                mapAddrDupAddr.put(addr, null);
        }
        
        return mapAddrDupAddr;               
    }
    
    public static void handleMultilineStreet(Address__c addr) {
    
        if (addr.MailingStreet__c == null)
            return;
        integer ich = addr.MailingStreet__c.indexOf('\n');
        if (ich > -1) {
            addr.MailingStreet2__c = addr.MailingStreet__c.substring(ich+1);
            addr.MailingStreet__c = addr.MailingStreet__c.left(ich);
        }
    }
    
    public static string getMultilineStreet(Address__c addr) {
        string str = addr.MailingStreet__c;
        if (addr.MailingStreet2__c != null && addr.MailingStreet2__c.length() > 0)
            str += '\n' + addr.MailingStreet2__c;
        return str;
    }
}