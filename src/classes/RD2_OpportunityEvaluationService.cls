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
public class RD2_OpportunityEvaluationService {

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
                rds = getRecurringDonationRecords(this.rdIds);
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

    @TestVisible
    private RD2_ScheduleService scheduleService {
        get {
            if (scheduleService == null) {
                scheduleService = new RD2_ScheduleService();
            }
            return scheduleService;
        } set;
    }


    /**
     * @description Pass the set of Recurring Donation Id's to be processed
     * @param rdIds
     */
    public RD2_OpportunityEvaluationService withRds(Set<Id> rdIds) {
        this.rdIds = rdIds;
        return this;
    }

    /**
     * @description Primary processor
     */
    public RD2_OpportunityEvaluationService evaluateOpportunities() {

        Map<npe03__Recurring_Donation__c, List<Date>> rdsWithCloseDates = new Map<npe03__Recurring_Donation__c, List<Date>>();

        for (npe03__Recurring_Donation__c rd : rds) {
            if (!isCandidate(rd)) {
                continue;
            }

            if (isNewRecurringDonation(rd)) {
                rdsWithCloseDates.put(rd, getInstallmentOppCloseDates(rd) );
                continue;
            }
            // TODO Update the Future Installment Opportunity if needed
        }

        // TODO Recalculate NextDonationDate
        // Date nextDonationDate = scheduleService.calculateNextDonationDate(rd);

        oppService.createInstallmentOpportunities(rdsWithCloseDates);

        return this;
    }

    /**
     * @description Is this Recurring Donation eligible to have an Installment Opportunity created
     * for it?
     * @param rd
     * @return True if the NextDonationDate is not null and the Rd.Status is Active And there are
     * Active Schedule records.
     */
    @TestVisible
    private Boolean isCandidate(npe03__Recurring_Donation__c rd) {
        return (rd.npe03__Next_Payment_Date__c != null &&
            rd.Status__c == RD2_Constants.STATUS_ACTIVE &&
            !rd.RecurringDonationSchedules__r.isEmpty());
    }

    /**
     * @description Is this a new Recurring Donation that was just inserted and has not yet had
     * an Installment Opportunity created?
     * @param rd
     * @return True if the RD.Status is Active and there is an Active schedule and there are no
     * current installment opps attached.
     */
    @TestVisible
    private Boolean isNewRecurringDonation(npe03__Recurring_Donation__c rd) {
        return (rd.Status__c == RD2_Constants.STATUS_ACTIVE &&
                rd.npe03__Donations__r.isEmpty() &&
                !rd.RecurringDonationSchedules__r.isEmpty());
    }

    /**
     * @description It will eventually be possible to create more than one installment opportunity
     * for a recurring donation. This method returns a list of CloseDates to create installment
     * opportunities for based on the RD schedule and existing Installment Opps.
     * @param rd
     * @return List<Date>
     */
    @TestVisible
    private List<Date> getInstallmentOppCloseDates(npe03__Recurring_Donation__c rd) {
        return new List<Date>{ rd.npe03__Next_Payment_Date__c != null ? rd.npe03__Next_Payment_Date__c : Date.Today() };
    }

    /**
     * @description Populate the collection of Recurring Donation records, querying ALL fields,
     * with the related Installment Opportunities and Active Schedule Records
     * @return List<RecurringDonation>
     */
    @TestVisible
    private List<npe03__Recurring_Donation__c> getRecurringDonationRecords(Set<Id> rdIds) {
        String PARENT_ACCOUNT_ID = 'npe03__Contact__r.AccountId';

        Map<String, Schema.DescribeFieldResult> allRdFields =
            UTIL_Describe.getAllFieldsDescribe(npe03__Recurring_Donation__c.SObjectType.getDescribe().name);

        Set<String> queryFields = new Set<String>();
        for (String fld : allRdFields.keySet()) {
            DescribeFieldResult fldResult = allRdFields.get(fld);
            if (fldResult.isAccessible()) {
                queryFields.add(fld);
            }
        }

        String oppSubquery = '(SELECT Id, Name, AccountId, Primary_Contact__c, ' +
                        'npe03__Recurring_Donation__c, ' +
                        'Amount, CloseDate, ' +
                        'StageName, IsClosed, IsWon, ' +
                        'CampaignId ' +
                        'FROM npe03__Donations__r ' +
                        'WHERE IsClosed = False OR CloseDate >= TODAY ' +
                        'ORDER BY npe03__Recurring_Donation__c, CloseDate ASC)';
        String scheduleSubQuery = '(SELECT Id, InstallmentAmount__c, ' +
                        'Campaign__c, ' +
                        'InstallmentFrequency__c, ' +
                        'InstallmentPeriod__c, ' +
                        'DayOfMonth__c, ' +
                        'PaymentMethod__c, ' +
                        'StartDate__c, ' +
                        'EndDate__c ' +
                        'FROM RecurringDonationSchedules__r ' +
                        'WHERE Active__c = True)';

        queryFields.add(PARENT_ACCOUNT_ID);
        queryFields.add(oppSubquery);
        queryFields.add(scheduleSubQuery);

        String soql = new UTIL_Query()
            .withFrom(npe03__Recurring_Donation__c.SObjectType)
            .withSelectFields(queryFields)
            .withWhere('Id IN :rdIds')
            .build();

        return Database.query(soql);
    }
}