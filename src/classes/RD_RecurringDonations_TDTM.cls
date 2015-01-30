/*
    Copyright (c) 2012,2013,2014 Salesforce.com Foundation
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
* @date 2012 (2.0)
* @description The main class for controlling the behavior of Recurring Donations, both open ended and standard 
*/
public with sharing class RD_RecurringDonations_TDTM extends TDTM_Runnable {
	
    // trigger handler for Recurring Donations called on an Opportunity trigger AfterUpdate.
    // needs to see if the Opp is changing to closed, and if it has open RD's, update them.
    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, 
    TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        list<npe03__Recurring_Donation__c> listRDDeletes = new list<npe03__Recurring_Donation__c>();
        map<id, npe03__Recurring_Donation__c> mapIdRDInserts = new map<id, npe03__Recurring_Donation__c>();
        list<npe03__Recurring_Donation__c> listRDUpdates = new list<npe03__Recurring_Donation__c>();

        npe03__Recurring_Donations_Settings__c rds = UTIL_CustomSettingsFacade.getRecurringDonationsSettings();
        if (RD_ProcessControl.hasRun) 
            return null;
            
        if (triggerAction == TDTM_Runnable.Action.AfterInsert) {
        	set<Id> setRDId = new set<Id>();
        	for (SObject s : newlist) 
        	   setRDId.add(s.Id);
        	newlist = RD_RecurringDonations.requeryListRD(setRDId);
        	// since we recreate newlist, we can't assume it is same order as oldlist.
        	// luckily we don't need oldlist for the AfterInsert scenario.
        	oldlist = null; 
        } else if (triggerAction == TDTM_Runnable.Action.BeforeDelete) {
        	// newlist will be null.  copy over oldlist, so we can use common loop below.
        	newlist = oldlist;
        }

        if (triggerAction != TDTM_Runnable.Action.BeforeInsert && triggerAction != TDTM_Runnable.Action.BeforeUpdate)
            RD_ProcessControl.hasRun = true;
        DmlWrapper dmlWrapper = new DmlWrapper();

        for (SObject sobj : newlist) {
            npe03__Recurring_Donation__c r = (npe03__Recurring_Donation__c)sobj;                   

            if (triggerAction == TDTM_Runnable.Action.BeforeInsert || triggerAction == TDTM_Runnable.Action.BeforeUpdate) {
                if (r.npe03__Organization__c == null && r.npe03__Contact__c == null) {
                    r.addError(system.label.npe03.RecurringDonationMissingDataError);
                }
                if (r.npe03__Organization__c != null && r.npe03__Contact__c != null) {
                    r.addError(system.label.RecurringDonationAccountAndContactError);
                }
                if (r.npe03__Installments__c > rds.npe03__Maximum_Donations__c && 
                    (r.npe03__Open_Ended_Status__c != system.label.npe03.RecurringDonationOpenStatus && 
                     r.npe03__Open_Ended_Status__c != system.label.npe03.RecurringDonationClosedStatus)) {
                    r.addError(system.label.npe03.RecurringDonationTooManyInstallmentsError);
                }            
            } else if (triggerAction == TDTM_Runnable.Action.AfterInsert) {
                mapIdRDInserts.put(r.id, r);
            } else if (triggerAction == TDTM_Runnable.Action.BeforeDelete) {
                listRDDeletes.add(r);
            } else if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
                listRDUpdates.add(r);
            }            
        }
        
        if (listRDDeletes.size() > 0) {
            RD_RecurringDonations.approveDeleteRecDonations(listRDDeletes);
        }
        
        if (listRDUpdates.size() > 0) {
            RD_RecurringDonations.handleRecurringDonationUpdate(listRDUpdates, new map<Id,npe03__Recurring_Donation__c>((list<npe03__Recurring_Donation__c>)oldlist), dmlWrapper); 
        }
        
        if (!mapIdRDInserts.isEmpty()) {
            if (mapIdRDInserts.keySet().size() == 1 || system.isFuture() || system.isBatch())            
                RD_RecurringDonations.insertOppsOnRecurringDonationInsert(mapIdRDInserts.values());
            else
                RD_RecurringDonations.insertOppsOnRecurringDonationInsertFuture(mapIdRDInserts.keySet());
        }
        
    return dmlWrapper;        
    }
            
}