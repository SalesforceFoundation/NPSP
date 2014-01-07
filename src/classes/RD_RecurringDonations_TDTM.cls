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
	
    // the main entry point for TDTM to invoke our trigger handlers.
    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_TriggerActionHelper.Action triggerAction, Schema.DescribeSObjectResult objResult) {
    
        // dispatch to the correct handler
        if (objResult == Schema.Sobjecttype.Opportunity)
            return runOpportunityTriggerHandler(newlist, oldlist, triggerAction, objResult);
        else if (objResult == Schema.Sobjecttype.npe03__Recurring_Donation__c)
            return runRDTriggerHandler(newlist, oldlist, triggerAction, objResult);
        else
            return null;
    }
	
	// trigger handler for Recurring Donations called on an Opportunity trigger AfterUpdate.
	// needs to see if the Opp is changing to closed, and if it has open RD's, update them.
    private DmlWrapper runOpportunityTriggerHandler(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_TriggerActionHelper.Action triggerAction, Schema.DescribeSObjectResult objResult) {
        	
        // DJH:UNDONE previous trigger checked this, but we will do differently with TDTM?
        npe03__Recurring_Donations_Settings__c rds = RD_RecurringDonations.getRecurringDonationsSettings();
        if (rds.npe03__DISABLE_Donations_trigger__c || system.isFuture()) 
            return null;
        	
        RD_ProcessControl.hasRun = true;
        DmlWrapper dmlWrapper = new DmlWrapper();
        
        set<id> rdIDs = new set<id>();        
        if (triggerAction == TDTM_TriggerActionHelper.Action.AfterUpdate) {
        	integer i = 0;       
            for (SObject sobj : newlist) {
            	Opportunity o = (Opportunity)sobj;
                //does it have a recurring donation reference?
                //has it moved into a closed state?
                Opportunity oppOld = (Opportunity)oldlist[i];
                if (o.npe03__Recurring_Donation__c != null && o.isClosed && !oppOld.isClosed) {
                    rdIds.add(o.npe03__Recurring_Donation__c);
                }
                i++;
            }                  
        }           
        
        //Get the open label for opps
        string openLabel = system.label.npe03.RecurringDonationOpenStatus;
        Integer rdcount = 0;
        rdcount = [select count() from npe03__Recurring_Donation__c where npe03__Open_Ended_Status__c = :openLabel and id IN :RDids];
                                                                                          
        //recurring donations that need to be updated      
        if (rdcount > 0){
            if (rdcount == 1 || system.isBatch() || RD_ProcessControl.batchButton)
                RD_RecurringDonations.updateRecurringDonationOnOppChange(rdIds, dmlWrapper); 
            else
                RD_RecurringDonations.updateRecurringDonationOnOppChangeFuture(rdIds);                                        
        }
        
        return dmlWrapper;            
    }
    


    // trigger handler for Recurring Donations called on an Opportunity trigger AfterUpdate.
    // needs to see if the Opp is changing to closed, and if it has open RD's, update them.
    private DmlWrapper runRDTriggerHandler(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_TriggerActionHelper.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        list<npe03__Recurring_Donation__c> listRDDeletes = new list<npe03__Recurring_Donation__c>();
        map<id, npe03__Recurring_Donation__c> mapIdRDInserts = new map<id, npe03__Recurring_Donation__c>(); 
        list<npe03__Recurring_Donation__c> listRDUpdates = new list<npe03__Recurring_Donation__c>();

        // DJH:UNDONE remove trigger check when handled by TDTM.
        npe03__Recurring_Donations_Settings__c rds = RD_RecurringDonations.getRecurringDonationsSettings();
        if (rds.npe03__DISABLE_RecurringDonations_trigger__c || RD_ProcessControl.hasRun) 
            return null;
            
        if (triggerAction == TDTM_TriggerActionHelper.Action.AfterInsert) {
        	set<Id> setRDId = new set<Id>();
        	for (SObject s : newlist) 
        	   setRDId.add(s.Id);
        	newlist = RD_RecurringDonations.requeryListRD(setRDId);
        	// since we recreate newlist, we can't assume it is same order as oldlist.
        	// luckily we don't need oldlist for the AfterInsert scenario.
        	oldlist = null; 
        } else if (triggerAction == TDTM_TriggerActionHelper.Action.BeforeDelete) {
        	// newlist will be null.  copy over oldlist, so we can use common loop below.
        	newlist = oldlist;
        }

        if (triggerAction != TDTM_TriggerActionHelper.Action.BeforeInsert)
            RD_ProcessControl.hasRun = true;
        DmlWrapper dmlWrapper = new DmlWrapper();

        //Get the open label for opps
        string openLabel = system.label.npe03.RecurringDonationOpenStatus;
        
        for (SObject sobj : newlist) {
            npe03__Recurring_Donation__c r = (npe03__Recurring_Donation__c)sobj;                   

            if (triggerAction == TDTM_TriggerActionHelper.Action.BeforeInsert) {
                if (r.npe03__Organization__c == null && r.npe03__Contact__c == null) {
                    r.addError(system.label.npe03.RecurringDonationMissingDataError);
                }
                if (r.npe03__Installments__c > rds.npe03__Maximum_Donations__c) {
                    r.addError(system.label.npe03.RecurringDonationTooManyInstallmentsError);
                }            
            } else if (triggerAction == TDTM_TriggerActionHelper.Action.AfterInsert) {
                mapIdRDInserts.put(r.id, r);
            } else if (triggerAction == TDTM_TriggerActionHelper.Action.BeforeDelete) {
                listRDDeletes.add(r);
            } else if (triggerAction == TDTM_TriggerActionHelper.Action.AfterUpdate) {
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
            if (mapIdRDInserts.keySet().size() == 1 || system.isBatch())            
                RD_RecurringDonations.insertOppsOnRecurringDonationInsert(mapIdRDInserts.values());
            else
                RD_RecurringDonations.insertOppsOnRecurringDonationInsertFuture(mapIdRDInserts.keySet());
        }
        
    return dmlWrapper;        
    }
            
}