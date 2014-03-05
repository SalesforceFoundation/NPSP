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
       
        integer i = 0;        
        for (SObject so : listNew) {
            Contact con = (Contact)so;

            // BEFORE INSERT
            if (triggerAction == TDTM_TriggerActionHelper.Action.BeforeInsert) {
            	if (con.Address_Override__c != null)
            	   listConAddrSet.add(con);
            }
            
            // BEFORE UPDATE
            if (triggerAction == TDTM_TriggerActionHelper.Action.BeforeUpdate) {
            	Contact conOld = (Contact)listOld[i];
                if (con.Address_Override__c != null && con.Address_Override__c != conOld.Address_Override__c) 
                    listConAddrSet.add(con);
            }
            
            // AFTER INSERT
            if (triggerAction == TDTM_TriggerActionHelper.Action.AfterInsert) {

            }
    
            // AFTER UPDATE
            if (triggerAction == TDTM_TriggerActionHelper.Action.AfterUpdate) {
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
        }
        
        // set the mailing address for contacts who specify an address override
        if (listConAddrSet.size() > 0) {
            setConAddrFromOverride(listConAddrSet);
            // to avoid pushing these address changes to the HH.
            ADDR_Addresses_TDTM.hasRunAddrTrigger = true;
        }
            
        // create any new Address objects
        if (listConCreateAddr.size() > 0)
            createAddrFromCon(listConCreateAddr, dmlWrapper);
            
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

    // for each contact, create a new default address and add it to dmlWrapper
    private void createAddrFromCon(list<Contact> listCon, DmlWrapper dmlWrapper) {
        for (Contact con : listCon) {
        	Address__c addr = new Address__c();
        	addr.Household_Account__c = con.AccountId;
        	addr.Default_Address__c = true;
        	addr.MailingStreet__c = con.MailingStreet;
        	addr.MailingCity__c = con.MailingCity;
        	addr.MailingState__c = con.MailingState;
        	addr.MailingPostalCode__c = con.MailingPostalCode;
        	addr.MailingCountry__c = con.MailingCountry;
        	addr.Address_Type__c = con.npe01__Primary_Address_Type__c;
        	
        	dmlWrapper.objectsToInsert.add(addr);
        }
        system.debug('DJH**** addr to insert: ' + dmlWrapper.objectsToInsert);
    }

}