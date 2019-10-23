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
* @description Data Migration Job to convert RD1 format records to RD2
*
*/
public class RD2_DataMigration_BATCH implements Database.Batchable<SObject> {

    private Boolean dryRunMode = false;

    private List<npe03__Recurring_Donation__c> rdsToUpdate = new List<npe03__Recurring_Donation__c>();
    private List<Opportunity> oppsToMarksForDeletion = new List<Opportunity>();
    private List<RecurringDonationSchedule__c> rdSchedules = new List<RecurringDonationSchedule__c>();

    /**
    * @description Batch size for Apex Job. Uses default of 200 if Custom Setting is null.
    */
    private Integer batchSize {
        get {
            if (batchSize == null) {
                Decimal batchSizeVal = UTIL_CustomSettingsFacade.getRecurringDonationsSettings().DataMigrationBatchSize__c;
                if (batchSizeVal == null) {
                    batchSizeVal = 200;
                }
                batchSize = batchSizeVal.intValue();
            }
            return batchSize;
        } set;
    }

    public RD2_DataMigration_BATCH() {
    }

    /**
    * @description Enables Dry Run Mode for the migration job
    */
    public RD2_DataMigration_BATCH enableDryRunMode() {
        dryRunMode = true;
        return this;
    }

    /**
    * @description Batch Start Method
    */
    public Database.QueryLocator start(Database.BatchableContext BC) {
        if (RD2_EnablementService.isRecurringDonations2Enabled) {
            return Database.getQueryLocator(getRDMigrationQuery());
        } else {
            throw new Rd2DataMigrationException(System.Label.RD2_ErrorDataMigrationJobCannotBeRun);
        }
    }

    /**
    * @description Batch Execute Method
    */
    public void execute(Database.BatchableContext BC, List<npe03__Recurring_Donation__c> scope) {
        Map<Id, List<Opportunity>> relatedOppsByRD = getRelatedOpportunities(scope);

        Savepoint sp = Database.setSavepoint();

        for (npe03__Recurring_Donation__c rd : scope) {
            handleConversion(rd, relatedOppsByRD.get(rd.Id));
        }

        handleDmlAndLogging(sp);
    }

    /**
    * @description Batch Finish Method
    */
    public void finish(Database.BatchableContext BC) {
    }

    /**
    * @description Process the Rd2 migration for a single Recurring Donation and its related opps
    * @param rd Recurring Donation
    * @param opps All Related Opportunities for this RD
    */
    private void handleConversion(npe03__Recurring_Donation__c rd, List<Opportunity> opps) {
        RD2_DataMigration migration = new RD2_DataMigration()
            .withRecurringDonation(rd)
            .withRelatedOpportunities(opps);

        npe03__Recurring_Donation__c updatedRd = migration.convertToRD2Format();

        if (updatedRd != null) {
            rdsToUpdate.add(updatedRd);

            oppsToMarksForDeletion.addAll(migration.updateOpportunities());
            rdSchedules.addAll(migration.getScheduleRecords());
        }
        // TODO Retrieve any validation errors that blocked the conversion
    }

    /**
    * @description When all RD's have been processed, handle any required DML and error/exception logging
    * @param sp SavePoint if a rollback is required for dry run mode
    */
    private void handleDmlAndLogging(Savepoint sp) {
        // TODO Rewrite this to capture and log dml exceptions in a new logging service
        Database.update(rdsToUpdate, false);

        // TODO If there is an error updating an RD, do not insert the schedule or update Opps for that RD
        Database.insert(rdSchedules, false);
        Database.update(oppsToMarksForDeletion, false);

        if (this.dryRunMode) {
            Database.rollback(sp);
        }

        // TODO Commit any logging records after the rollback
    }

    /**
    * @description Build the query of all standard RD fields to use for the batch query
    * @return SOQL
    */
    private String getRDMigrationQuery() {
        Set<String> rdFields = new Set<String>{
            'Id',
            'Name',
            'npe03__Open_ended_status__c',
            'npe03__Next_payment_date__c',
            'npe03__Paid_Amount__c',
            'npe03__Organization__c',
            'npe03__Contact__c',
            'npe03__Installment_amount__c',
            'npe03__Installments__c',
            'npe03__Amount__c',
            'npe03__Total__c',
            'npe03__Installment_period__c',
            'npe03__Date_established__c',
            'npe03__Schedule_type__c',
            'npe03__Recurring_donation_campaign__c',
            'npe03__Total_paid_installments__c',
            'Ownerid',
            'Always_use_last_day_of_month__c',
            'Day_of_Month__c',
            'StartDate__c',
            'InstallmentFrequency__c',
            'PaymentMethod__c',
            'Status__c',
            'RecurringType__c'
        };
        if (UserInfo.isMultiCurrencyOrganization()) {
            rdFields.add('CurrencyIsoCode');
        }

        UTIL_Query queryBuilder = new UTIL_Query()
            .withFrom(npe03__Recurring_Donation__c.SObjectType)
            .withSelectFields(rdFields)
            .withOrderBy('npe03__Last_Payment_Date__c');

        return queryBuilder.build();
    }

    /**
    * @description Build a map of related Opportunities for each recurring donation
    * @param rds Collection of Recurring Donations to retrieve related Opps for
    * @return Map<Id, List<Opportunity>>
    */
    public Map<Id, List<Opportunity>> getRelatedOpportunities(List<npe03__Recurring_Donation__c> rds) {
        Map<Id, List<Opportunity>> oppsByRdId = new Map<Id, List<Opportunity>>();

        for (Opportunity opp : [SELECT Id,
                    Name,
                    Amount,
                    CloseDate,
                    CreatedDate,
                    IsWon,
                    IsClosed,
                    npe03__Recurring_Donation__c
                FROM Opportunity
                WHERE npe03__Recurring_Donation__c IN :rds
                ORDER BY npe03__Recurring_Donation__c, CloseDate ASC
        ]) {

            if (!oppsByRdId.containsKey(opp.npe03__Recurring_Donation__c)) {
                oppsByRdId.put(opp.npe03__Recurring_Donation__c, new List<Opportunity>());
            }
            oppsByRdId.get(opp.npe03__Recurring_Donation__c).add(opp);
        }

        return oppsByRdId;
    }

    private class Rd2DataMigrationException extends Exception { }
}