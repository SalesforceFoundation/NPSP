/*
    Copyright (c) 2020 Salesforce.org
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
* @date 2020
* @group Recurring Donations
* @description Trigger on Recurring Donation Opportunities when enhanced Recurring Donations are enabled
*
*/
public class RD2_RecurringDonationsOpp_TDTM extends TDTM_Runnable {

    

    /***
    * @description Trigger handler on Opportunities when Recurring Donation enhancement is enabled
    * @param rds Trigger.new records
    * @param oldRds Trigger.old records
    * @param triggerAction BeforeInsert, AfterInsert, etc.
    * @param objResult Opportunity SObject describe
    * @return dmlWrapper
    */
    public override DmlWrapper run(
        List<SObject> opps, List<SObject> oldOpps,
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult
    ) {
        if (!RD2_EnablementService.isRecurringDonations2Enabled
            || TDTM_ProcessControl.isRecursive(TDTM_ProcessControl.flag.RD)
        ) {
            return null;
        }
        
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.RD, true);
        updateRecurringDonations(opps, oldOpps, triggerAction);
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.RD, false);

        return null;
    }

    /***
    * @description Extracts Opps
    * @param rds Trigger.new records
    * @param oldRds Trigger.old records
    * @param triggerAction BeforeInsert, AfterInsert, etc.
    */
    public void updateRecurringDonations(List<SObject> opps, List<SObject> oldOpps, TDTM_Runnable.Action triggerAction) {
        if (RD2_OpportunityEvaluationService.skipEvaluationService) {
            return;
        }

        Set<Id> rdIds = new Set<Id>();

        if (triggerAction == TDTM_Runnable.Action.AfterInsert) {
            rdIds = getRecurringDonationIds(opps);

        } else if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
            rdIds = getRecurringDonationIds(opps, oldOpps);            
        }//before delete//todo

        updateRecurringDonations(rdIds);
    }

    public Set<Id> getRecurringDonationIds(List<Opportunity> opps) {
        Set<Id> rdIds = new Set<Id>();

        for (Opportunity opp : opps) {
            rdIds.add(opp.npe03__Recurring_Donation__c);
        }

        rdIds.remove(null);
        return rdIds;
    }

    public Set<Id> getRecurringDonationIds(List<Opportunity> opps, List<Opportunity> oldOpps) {
        Map<Id, Opportunity> oldOppById = new Map<Id, Opportunity>(oldOpps);
        Set<Id> rdIds = new Set<Id>();

        for (Opportunity opp : opps) {
            Opportunity oldOpp = oldOppById.get(opp.Id);

            if (hasChanged(opp, oldOpp)) {
                rdIds.add(opp.npe03__Recurring_Donation__c);
                rdIds.add(oldOpp.npe03__Recurring_Donation__c);
            }
        }

        rdIds.remove(null);
        return rdIds;
    }

    private Boolean hasChanged(Opportunity opp, Opportunity oldOpp) {
        Boolean isAssignedToRD = opp.npe03__Recurring_Donation__c != null 
            || oldOpp.npe03__Recurring_Donation__c != null;

        if (!isAssignedToRD) {
            return false;
        }
            
        return opp.IsClosed != oldOpp.IsClosed 
            || opp.IsWon != oldOpp.IsWon 
            || opp.Amount != oldOpp.Amount
            || opp.CloseDate != oldOpp.CloseDate
            || opp.npe03__Recurring_Donation__c != oldOpp.npe03__Recurring_Donation__c;
    }

    private void updateRecurringDonations(Set<Id> rdIds) {
        if (rdIds.isEmpty()) {
            return;
        }

        RD2_OpportunityEvaluationService evalService = new RD2_OpportunityEvaluationService()
            .withRds(rdIds);
                                           
        if (System.isBatch() || System.isFuture()) {
            evalService.updateRecurringDonations();
        }
        else {
            evalService.updateRecurringDonations();//TODO                                       
        }
    }
}