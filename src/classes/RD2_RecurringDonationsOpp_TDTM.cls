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

        matchOppsToRecurringDonations(opps, triggerAction);
        evaluateOpportunities(opps, oldOpps, triggerAction);

        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.RD, false);
        return null;
    }

    /**
    * @description Match new Opportunities not referencing any Recurring Donation and originated from Elevate 
    * with a Recurring Donation having the same Commitment Id.
    * @param opps Opportunities to be created
    * @param triggerAction BeforeInsert, AfterInsert, etc.
    * @return void
    */
    private void matchOppsToRecurringDonations(List<Opportunity> opps, TDTM_Runnable.Action triggerAction) {
        if (triggerAction != TDTM_Runnable.Action.BeforeInsert) {
            return;
        }

        new RD2_ElevateIntegrationService()
            .matchOppsToRecurringDonations(opps);
    }

    /***
    * @description Updates Recurring Donation fields depending on Opportunities
    * @param rds Trigger.new records
    * @param oldRds Trigger.old records
    * @param triggerAction BeforeInsert, AfterInsert, etc.
    * @return void
    */
    public void evaluateOpportunities(List<SObject> opps, List<SObject> oldOpps, TDTM_Runnable.Action triggerAction) {
        if (RD2_OpportunityEvaluationService.skipEvaluationService) {
            return;
        }

        Set<Id> rdIds = new Set<Id>();
        if (triggerAction == TDTM_Runnable.Action.BeforeInsert
            || triggerAction == TDTM_Runnable.Action.BeforeUpdate
        ) {
            validateCurrency(opps);

        } else if (triggerAction == TDTM_Runnable.Action.AfterInsert) {
            rdIds = getRecurringDonationIds(opps);

        } else if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
            rdIds = getRecurringDonationIds(opps, oldOpps);

        } else if (triggerAction == TDTM_Runnable.Action.AfterDelete) {
            rdIds = getRecurringDonationIds(oldOpps);
        }

        if (rdIds.isEmpty()) {
            return;
        }

        RD2_QueueableService.enqueueOppEvalService(rdIds);
    }

    /***
    * @description Validates currency on provided Opportunities
    * @param opps Opportunities
    * @return void
    */
    public void validateCurrency(List<Opportunity> opps) {
        MultiCurrencyValidator validator = new MultiCurrencyValidator()
            .withOpportunities(opps);

        if (!validator.isEnabled() || !validator.hasRecurringDonationOpp()) {
            return;
        }

        for (Opportunity opp : opps) {
            if (validator.isCurrencyOutOfSync(opp)) {
                opp.addError(System.Label.RD2_CurrencyChangeIsRestrictedOnOpp);
            }
        }
    }

    /***
    * @description Returns all Recurring Donation Ids on related Opportunities
    * @param opps Opportunities
    * @return Set<Id> Related Recurring Donation Ids
    */
    public Set<Id> getRecurringDonationIds(List<Opportunity> opps) {
        return UTIL_SObject.extractId(opps, Opportunity.npe03__Recurring_Donation__c);
    }

    /***
    * @description Returns Recurring Donation Ids from valid updated Opportunities.
    * If the Opportunity change is not valid, an error is added to the record.
    * @param opps Opportunities
    * @param oldOpps Opportunities containing values before the update
    * @return Set<Id> Related Recurring Donation Ids
    */
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

    /***
    * @description Indicates if the updated Opportunity has changed
    * @param opp Opportunity
    * @param oldOpp Opportunity containing values before the update
    * @return Boolean
    */
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

    /***
    * @description Currency validator on Opportunities related to Recurring Donations
    * when multi-currency is enabled for the organization
    */
    public class MultiCurrencyValidator {
        /***
         * @description CurrencyIsoCode field name
         */
        private final String CURRENCY_ISO_CODE_FIELD = UTIL_Currency.CURRENCY_ISO_CODE_FIELD;

        /***
        * @description Determines if multi-currency is enabled for the org
        */
        private Boolean isMultiCurrencyEnabled {
            get {
                if (isMultiCurrencyEnabled == null) {
                    isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
                }
                return isMultiCurrencyEnabled;
            }
            set;
        }

        /***
        * @description Contains Recurring Donation by Id records
        */
        private Map<Id, npe03__Recurring_Donation__c> rdById {
            get {
                if (rdById == null) {
                    rdById = getRecurringDonations();
                }
                return rdById;
            }
            set;
        }
        
        /***
        * @description Contains Recurring Donation Ids
        */
        private Set<Id> rdIds = new Set<Id>();

        /***
        * @description Extracts Recurring Donation Ids from related Opportunities
        * @param opps Opportunities
        * @return MultiCurrencyValidator This validator instance
        */
        public MultiCurrencyValidator withOpportunities(List<Opportunity> opps) {
            this.rdIds = UTIL_SObject.extractId(opps, Opportunity.npe03__Recurring_Donation__c);
            return this;
        }

        /***
        * @description Indicates if the multi-currency is enabled
        * @return Boolean
        */
        public Boolean isEnabled() {
            return isMultiCurrencyEnabled;
        }

        /***
        * @description Indicates if at least one Opportunity is related to a Recurring Donation
        * @return Boolean
        */
        public Boolean hasRecurringDonationOpp() {
            return !rdById.isEmpty();
        }

        /***
        * @description Returns related Recurring Donations (if any) on Opportunities
        * @return Map<Id, npe03__Recurring_Donation__c>
        */
        private Map<Id, npe03__Recurring_Donation__c> getRecurringDonations() {
            if (!isMultiCurrencyEnabled || rdIds.isEmpty()) {
                return new Map<Id, npe03__Recurring_Donation__c>();
            }

            String soql = new UTIL_Query()
                .withFrom(npe03__Recurring_Donation__c.SObjectType)
                .withSelectFields(new Set<String>{
                    'Id', 
                    CURRENCY_ISO_CODE_FIELD
                })
                .withWhere('Id IN :rdIds')
                .build();

            List<npe03__Recurring_Donation__c> rds = (List<npe03__Recurring_Donation__c>) Database.query(soql);

            return new Map<Id, npe03__Recurring_Donation__c>(rds);            
        }

        /***
        * @description Indicates if currency on the Opportunity is out sync 
        * with the currency on the related Recurring Donation.
        * @param opp Opportunity
        * @return Boolean
        */
        public Boolean isCurrencyOutOfSync(Opportunity opp) {
            Id rdId = opp.npe03__Recurring_Donation__c;

            if (rdId == null || !rdById.containsKey(rdId)) {
                return false;
            }
            
            return (String) opp.get(CURRENCY_ISO_CODE_FIELD) != (String) rdById.get(rdId).get(CURRENCY_ISO_CODE_FIELD);
        }
    }
}