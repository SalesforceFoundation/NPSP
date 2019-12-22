/*
    Copyright (c) 2019 Salesforce.org
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
* @date 2019
* @group Recurring Donations
* @description Installment Opportunity Evaluation and Processing
*
*/
public inherited sharing class RD2_OpportunityEvaluationService {

    private npe03__Recurring_Donations_Settings__c rdSettings = UTIL_CustomSettingsFacade.getRecurringDonationsSettings();

    /**
     * @description Recurring Donation Id's to be processed
     */
    public Set<Id> rdIds {
        get {
            if (rdIds == null && rds != null) {
                rdIds = (new Map<Id, npe03__Recurring_Donation__c>(rds)).keySet();
            }
            return rdIds;
        } set;
    }

    /**
     * @description Queried Recurring Donation records with subqueries to be processed.
     */
    @TestVisible
    private List<npe03__Recurring_Donation__c> rds {
        get {
            if (rds == null && rdIds != null) {
                rds = getRecurringDonations(this.rdIds);
            }
            return rds;
        } set;
    }

    @TestVisible
    private RD2_OpportunityService oppService {
        get {
            if (oppService == null) {
                oppService = new RD2_OpportunityService();
            }
            return oppService;
        } set;
    }

    /**
     * @description Indicates if Recurring Donation Settings close action on Open Opportunities
     * is overriden when Recurring Donation is Closed
     */
    public static Boolean overrideVoidOfOpenOpps = false;


    /**
     * @description Pass the set of Recurring Donation Id's to be processed
     * @param rdIds Recurring Donation Ids
     * @return RD2_OpportunityEvaluationService The service instance
     */
    public RD2_OpportunityEvaluationService withRds(Set<Id> rdIds) {
        this.rdIds = rdIds;
        return this;
    }

    /**
     * @description Returns true if any of the key fields used to create or manage installment
     * Opportunities has been changed.
     * @param rd Changed Recurring Donation
     * @param oldRd Old Recurring Donation
     * @return Boolean
     */
    public Boolean hasKeyFieldChanged(npe03__Recurring_Donation__c rd, npe03__Recurring_Donation__c oldRd) {
        return
            rd.npe03__Contact__c != oldRd.npe03__Contact__c ||
            rd.npe03__Organization__c != oldRd.npe03__Organization__c ||
            rd.npe03__Amount__c != oldRd.npe03__Amount__c ||
            rd.npe03__Installment_Period__c != oldRd.npe03__Installment_Period__c ||
            rd.InstallmentFrequency__c != oldRd.InstallmentFrequency__c ||
            rd.StartDate__c != oldRd.StartDate__c ||
            rd.Day_of_Month__c != oldRd.Day_of_Month__c ||
            rd.Status__c != oldRd.Status__c ||
            rd.PaymentMethod__c != oldRd.PaymentMethod__c ||
            rd.npe03__Recurring_Donation_Campaign__c != oldRd.npe03__Recurring_Donation_Campaign__c;
    }

    /**
     * @description Primary processor
     * @return RD2_OpportunityEvaluationService The service instance
     */
    public RD2_OpportunityEvaluationService evaluateOpportunities() {
        List<npe03__Recurring_Donation__c> newRDs = new List<npe03__Recurring_Donation__c>();
        List<Opportunity> openOppsToVoid = new List<Opportunity>();
        List<npe03__Recurring_Donation__c> rdsWithOpenOpps = new List<npe03__Recurring_Donation__c>();

        for (npe03__Recurring_Donation__c rd : rds) {

            // TODO Recalculate NextDonationDate before doing anything

            if (isNew(rd)) {
                newRDs.add(rd);
                continue;
            }

            if (isActive(rd) && hasOpportunities(rd)) {
                rdsWithOpenOpps.add(rd);

            } else if (isClosed(rd)) {
                handleClosedRecurringDonation(rd, openOppsToVoid);
            }

            // TODO Schedule Visualizer
            // TODO Handle Past Due Installment
        }

        // TODO Support this method returning a collection of new Opps vs. inserting from within the Opp Service
        oppService.createInstallmentOpportunities(newRDs);

        oppService.updateInstallmentOpportunities(rdsWithOpenOpps);

        voidOpportunities(openOppsToVoid);

        return this;
    }

    /**
     * @description Is this a new Recurring Donation that was just inserted and
     * has not yet had an Installment Opportunity created?
     * Schedules are inserted upon the Recurring Donation insert.
     * @param rd Recurring Donation
     * @return Boolean
     */
    @TestVisible
    private Boolean isNew(npe03__Recurring_Donation__c rd) {
        return
            isActive(rd)
            && rd.npe03__Next_Payment_Date__c != null
            && rd.npe03__Donations__r.isEmpty()
            && !rd.RecurringDonationSchedules__r.isEmpty();
    }

    /**
     * @description Indicates if the Recurring Donation is active
     * @param rd Recurring Donation
     * @return Boolean
     */
    @TestVisible
    private Boolean isActive(npe03__Recurring_Donation__c rd) {
        return rd.Status__c == RD2_Constants.STATUS_ACTIVE;
    }

    /**
     * @description Indicates if the Recurring Donation is closed
     * @param rd Recurring Donation
     * @return Boolean
     */
    @TestVisible
    private Boolean isClosed(npe03__Recurring_Donation__c rd) {
        return rd.Status__c == RD2_Constants.STATUS_CLOSED;
    }

    /**
     * @description Is this a new Recurring Donation that has not yet had an Installment Opp created?
     * @param rd Recurring Donation
     * @return Boolean
     */
    @TestVisible
    private Boolean hasOpportunities(npe03__Recurring_Donation__c rd) {
        return
            !rd.npe03__Donations__r.isEmpty()
            && !rd.RecurringDonationSchedules__r.isEmpty();
    }

    /**
     * @description Extracts open installment Opportunities for the specified Recurring Donation
     * @param rd Recurring donation containing list of all related Opportunities
     * @param openOppsToVoid Open Opportunities to void from other Recurring Donations
     * @return void
     */
    private void handleClosedRecurringDonation(npe03__Recurring_Donation__c rd, List<Opportunity> openOppsToVoid) {
        if (overrideVoidOfOpenOpps) {
            return;
        }

        for (Opportunity opp : rd.npe03__Donations__r) {
            if (opp.IsClosed == false) {
                openOppsToVoid.add(opp);
            }
        }
    }

    /**
     * @description Updates or deletes closed RD open Installment Opportunities based on the settings
     * @param opps Opportunities
     * @return void
     */
    private void voidOpportunities(List<Opportunity> opps) {
        if (opps.isEmpty()) {
            return;
        }

        if (rdSettings.npe03__Open_Opportunity_Behavior__c == RD2_Constants.CloseActions.Delete_Open_Opportunities.name()) {
            UTIL_DMLService.deleteRecordsAndLogErrors(opps, ERR_Handler_API.Context.RD.name());

        } else if (rdSettings.npe03__Open_Opportunity_Behavior__c == RD2_Constants.CloseActions.Mark_Opportunities_Closed_Lost.name()) {
            List<Opportunity> oppsToUpdate = new List<Opportunity>();

            for (Opportunity opp : opps) {
                oppsToUpdate.add(new Opportunity(
                    Id = opp.Id,
                    StageName = System.Label.npe03.RecurringDonationClosedLostOpportunityStage
                ));
            }

            UTIL_DMLService.updateRecordBatchAndLogErrors(oppsToUpdate, ERR_Handler_API.Context.RD.name());
        }
    }

    /**
     * @description Populate the collection of Recurring Donation records, querying ALL fields,
     * with the related Installment Opportunities and Active Schedule Records. Due to a core KI (W-2503825)
     * this query needs to exclude CLOB fields. Since there is no pure definition of that for a Describe, the
     * query excludes Large Text Area fields larger than 4KB. These would only be custom fields.
     * @param rdIds Recurring Donation Ids
     * @return List<RecurringDonation> Recurring Donations with related installment Opportunities and active Schedules
     */
    @TestVisible
    private List<npe03__Recurring_Donation__c> getRecurringDonations(Set<Id> rdIds) {
        final String parentAccountField = 'npe03__Contact__r.AccountId';

        Map<String, Schema.DescribeFieldResult> allRdFields =
            UTIL_Describe.getAllFieldsDescribe(npe03__Recurring_Donation__c.SObjectType.getDescribe().name);

        Set<String> queryFields = new Set<String>();
        for (String fld : allRdFields.keySet()) {
            DescribeFieldResult fldResult = allRdFields.get(fld);
            if (fldResult.getType() == DisplayType.BASE64 ||
                    fldResult.getType() == DisplayType.ENCRYPTEDSTRING ||
                    (fldResult.getSoapType() == SoapType.STRING && fldResult.getLength() > 4096)) {
                continue;
            }
            queryFields.add(fld);
        }

        String oppSubquery =
            '(SELECT Id, Name, AccountId, Primary_Contact__c, ' +
            'npe03__Recurring_Donation__c, ' +
            'Amount, CloseDate, ' +
            'StageName, IsClosed, IsWon, ' +
            'CampaignId, Recurring_Donation_Installment_Number__c ' +
            'FROM npe03__Donations__r ' +
            'WHERE IsClosed = false ' +
            'OR CloseDate >= TODAY ' +
            'ORDER BY npe03__Recurring_Donation__c, CloseDate ASC)';

        String scheduleSubquery =
            '(SELECT Id, InstallmentAmount__c, ' +
            'Campaign__c, ' +
            'Campaign__r.Name, ' +
            'InstallmentFrequency__c, ' +
            'InstallmentPeriod__c, ' +
            'DayOfMonth__c, ' +
            'PaymentMethod__c, ' +
            'StartDate__c, ' +
            'EndDate__c ' +
            'FROM RecurringDonationSchedules__r ' +
            'WHERE Active__c = true)';

        queryFields.add(parentAccountField);
        queryFields.add(oppSubquery);
        queryFields.add(scheduleSubquery);

        String soql = new UTIL_Query()
            .withFrom(npe03__Recurring_Donation__c.SObjectType)
            .withSelectFields(queryFields)
            .withWhere('Id IN :rdIds')
            .build();

        return Database.query(soql);
    }

}