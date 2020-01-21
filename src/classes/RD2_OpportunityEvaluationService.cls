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

    /**
     * @description Indicates if Opp evaluation service will be skipped.
     * The flag is currently applicable to migration since Opp evaluation service should not be executed on migration.
     * For example, if an active RD has no Opp, no new Opp should be created during migration.
     * If the RD is closed, close action on Open Opps should not be applied when data migration is executed.
     */
    public static Boolean skipEvaluationService = false;

    /**
    * @description Indicates if the Opportunity evaluation is invoked from a nightly batch job
    */   
    private Boolean isBatchContext = false;

    /***
    * @description Recurring Donation custom settings
    */
    private RD2_Settings rdSettings {
        get {
            if (rdSettings == null) {
                rdSettings = new RD2_Settings();
            } 
            return rdSettings;
        }
        set;
    }

    /**
     * @description Indicates if the first installment Opportunity on a Recurring Donation should be created.
     * If Opportunities are created from a batch, "Disable First Installment" is ignored and 
     * the first installment is not created only if the setting is "Disable All Installments".
     * @return Boolean
     */
    private Boolean isFirstInstallmentEnabled {
        get {
            if (isFirstInstallmentEnabled == null) {
                if (isBatchContext) {
                    isFirstInstallmentEnabled = !rdSettings.isDisableAllInstallments;
                } else {
                    isFirstInstallmentEnabled = rdSettings.isFirstInstallmentEnabled;
                }
            }
            return isFirstInstallmentEnabled;
        }
        set;
    }

    /**
     * @description Current date used as a cut off date to filter out and evaluate Opportunities 
     * and to determine if the next Opp should be created for a Recurring Donation.
     * It is also used to calculate projected RD schedule installments as of the current date.
     * It can be a date in past, today or a future date in testing. When executed from a scheduler,
     * the current date is always today.
    */   
    private Date currentDate {
        get {
            if (currentDate == null) {
                currentDate = RD2_ScheduleService.currentDate;
            }
            return currentDate;
        } set;
    }

    /***
    * @description Recurring Donation Opportunity service
    */
    private RD2_OpportunityService oppService {
        get {
            if (oppService == null) {
                oppService = new RD2_OpportunityService(currentDate, dbService);
            }
            return oppService;
        } 
        set;
    }

    /***
    * @description Applies DML operations on records and keeps track of errors
    */
    private DatabaseService dbService {
        get {
            if (dbService == null) {
                dbService = new DatabaseService();
            }
            return dbService;
        }
        set;
    }

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

    /**
     * @description Sets batch context
     * @return RD2_OpportunityEvaluationService The service instance
     */
    public RD2_OpportunityEvaluationService withBatchContext() {
        isBatchContext = true;
        return this;
    }

    /**
     * @description Sets current date.
     * It also synchronizes the passed in current date with the RD Schedule service date.
     *
     * @param currentDate Date considered as the current date
     * @return RD2_OpportunityEvaluationService The service instance
     */
    public RD2_OpportunityEvaluationService withCurrentDate(Date currentDate) {
        this.currentDate = currentDate;
        RD2_ScheduleService.currentDate = currentDate;
        return this;
    }

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
     * @description Returns number of failed Recurring Donation records
     * @return Integer
     */
    public Integer getRecordsFailed() {
        return dbService.getRecordsFailed();
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
     * @return RD2_OpportunityEvaluationService This service instance
     */
    public RD2_OpportunityEvaluationService evaluateOpportunities() {
        //do not evaluate Opps when override is set
        if (skipEvaluationService) {
            return this;
        }
        
        RD2_ScheduleService scheduleService = new RD2_ScheduleService();
        List<npe03__Recurring_Donation__c> newOppRDs = new List<npe03__Recurring_Donation__c>();
        List<npe03__Recurring_Donation__c> updateOppRDs = new List<npe03__Recurring_Donation__c>();
        List<npe03__Recurring_Donation__c> closedRDs = new List<npe03__Recurring_Donation__c>();
        List<npe03__Recurring_Donation__c> outdatedRDs = new List<npe03__Recurring_Donation__c>();

        for (npe03__Recurring_Donation__c rd : rds) {              
            RecurringDonation rdRecord = new RecurringDonation(rd)
                .revise(scheduleService); 

            if (rdRecord.isOutdated()) {
                outdatedRDs.add(rdRecord.getUpdate());
            }
            
            if (rdRecord.isClosed()) {
                closedRDs.add(rd);

            } else if (needNextInstallment(rdRecord)) {
                newOppRDs.add(rd);
            
            } else if (isUpdateContext(rdRecord)) {
                updateOppRDs.add(rd);
            } 

            // TODO Handle Past Due Installment
        }

        // TODO Support this method returning a collection of new Opps vs. inserting from within the Opp Service
        oppService.createOpportunities(newOppRDs);
        oppService.updateOpportunities(updateOppRDs);
        oppService.voidOpenOpportunities(closedRDs);

        if (!outdatedRDs.isEmpty()) {
            TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.RD, true);
            dbService.updateRecords(outdatedRDs);
        }

        dbService.processErrors();

        return this;
    }

    /**
     * @description Indicates if a Recurring Donation requires a new installment Opp to be created.
     * @param rd Recurring Donation SObject
     * @return Boolean
     */
    @TestVisible
    private Boolean needNextInstallment(npe03__Recurring_Donation__c rd) {
        return needNextInstallment(new RecurringDonation(rd));
    }

    /**
     * @description Indicates if the Recurring Donation require a new installment Opp to be created.
     * Schedules are inserted when the Recurring Donation is created and before Opp evaluation is done.
     * @param rd Recurring Donation record
     * @return Boolean
     */
    private Boolean needNextInstallment(RecurringDonation rd) {
        Boolean hasMandatoryConditions = rd.isActive()
            && rd.hasNextDonationDate()
            && rd.hasSchedule();
        
        if (!hasMandatoryConditions) {
            return false;
        }

        if (rd.isNew()) {
            return isFirstInstallmentEnabled;

        } else if (isBatchContext || !rd.hasOpenOpportunity(currentDate)) {
            return rdSettings.isNextInstallmentEnabled;
        }

        return false;
    }

    /**
     * @description Determines if the Recurring Donation open Opportunity should be updated
     * @param rd Recurring Donation record
     * @return Boolean
     */
    private Boolean isUpdateContext(RecurringDonation rd) {
        return !isBatchContext
            && rd.isActive()
            && rd.hasSchedule()
            && rd.hasOpenOpportunity(currentDate);
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

        //Return Recurring Donations' open Opps regardless of the Close Date
        //and Opps with Close Date >= current date regardless if closed or open
        String oppSubquery =
            '(SELECT Id, Name, AccountId, Primary_Contact__c, ' +
            'npe03__Recurring_Donation__c, ' +
            'Amount, CloseDate, ' +
            'StageName, IsClosed, IsWon, ' +
            'CampaignId, Recurring_Donation_Installment_Number__c ' +
            'FROM npe03__Donations__r ' +
            'WHERE IsClosed = false ' +	
            'OR CloseDate >= :currentDate ' +
            'ORDER BY npe03__Recurring_Donation__c, CloseDate ASC)';

        //Return all schedules for the RD Schedule visualization.
        //The RD Schedule will filter them out if not applicable within the time period.
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
            'FROM RecurringDonationSchedules__r)';

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


    /**
     * @description Recurring Donation SObject wrapper
     */
    public class RecurringDonation {
        npe03__Recurring_Donation__c rd;
        private Boolean hasOpenOpportunity;
        private Boolean isOutdated;

        /**
        * @description Constructor
        */
        public RecurringDonation(npe03__Recurring_Donation__c rd) {
            this.rd = rd;
        }

        /**
        * @description Revises and modifies the Recurring Donation so it is up to date
        * @param scheduleService RD Schedule Service
        * @return RecurringDonation This record instance
        */
        public RecurringDonation revise(RD2_ScheduleService scheduleService) {
            isOutdated = false;

            Date nextDonationDate = scheduleService.getNextDonationDate(rd.RecurringDonationSchedules__r);

            if (nextDonationDate != rd.npe03__Next_Payment_Date__c) {
                rd.npe03__Next_Payment_Date__c = nextDonationDate;
                isOutdated = true;
            }

            return this;
        }

        /**
        * @description Indicates if the Recurring Donation is outdated and requiring an update
        * @return Boolean
        */
        public Boolean isOutdated() {
            return isOutdated;
        }

        /**
        * @description Returns Recurring Donation fields that were modified
        * @return npe03__Recurring_Donation__c
        */
        public npe03__Recurring_Donation__c getUpdate() {
            return new npe03__Recurring_Donation__c(
                Id = rd.Id,
                npe03__Next_Payment_Date__c = rd.npe03__Next_Payment_Date__c
            );
        }

        /**
        * @description Indicates if the Recurring Donation is active
        * @return Boolean
        */
        public Boolean isActive() {
            return rd.Status__c == RD2_Constants.STATUS_ACTIVE;
        }

        /**
        * @description Indicates if the Recurring Donation is closed
        * @return Boolean
        */
        public Boolean isClosed() {
            return rd.Status__c == RD2_Constants.STATUS_CLOSED;
        }

        /**
        * @description Indicates if the Recurring Donation Next Donation Date is determined
        * @return Boolean
        */
        public Boolean hasNextDonationDate() {
            return rd.npe03__Next_Payment_Date__c != null;
        }

        /**
        * @description Indicates if the Recurring Donation has a Schedule
        * @return Boolean
        */
        public Boolean hasSchedule() {
            return !rd.RecurringDonationSchedules__r.isEmpty();
        }

        /**
        * @description Indicates if the Recurring Donation is new, ie the RD has no installment Opp
        * @return Boolean
        */
        public Boolean isNew() {
            return rd.npe03__Donations__r.isEmpty();
        }

        /**
        * @description Indicates if the Recurring Donation has an open Opportunity with Close Date >= current date
        * @param currentDate Current Date to compare the Close Date to
        * @return Boolean
        */
        public Boolean hasOpenOpportunity(Date currentDate) {
            if (hasOpenOpportunity != null) {
                return hasOpenOpportunity;
            }

            hasOpenOpportunity = false;
            
            for (Opportunity opp : rd.npe03__Donations__r) {
                if (opp.IsClosed == false && opp.CloseDate >= currentDate) {
                    hasOpenOpportunity = true;
                }
            }

            return hasOpenOpportunity;
        }
    }


    /**
     * @description Database DML service to insert/update/delete records and keep track of failed RD Ids
     */
    public class DatabaseService {
        private SObjectType rdSObjectType = npe03__Recurring_Donation__c.SObjectType;
        private SObjectType oppSObjectType = Opportunity.SObjectType;

        private ERR_Handler.Errors errorResult = new ERR_Handler.Errors();
        private Set<Id> failedRDIds = new Set<Id>();

        /***
        * @description Creates specified records
        * @param records Records to create
        * @return Set<Id> Ids of created records
        */
        public Set<Id> insertRecords(List<SObject> records) { 
            if (records == null || records.isEmpty()) {
                return new Set<Id>();
            }

            List<Database.SaveResult> saveResults = Database.insert(records, false);
            handleErrors(saveResults, records);

            return getSuccessIds(saveResults);
        }

        /***
        * @description Updates specified records
        * @param records Records to update
        * @return void
        */
        public void updateRecords(List<SObject> records) { 
            if (records == null || records.isEmpty()) {
                return;
            }

            List<Database.SaveResult> saveResults = Database.update(records, false);
            handleErrors(saveResults, records);
        }

        /***
        * @description Extracts Ids of records that were successfully created/update
        * @param saveResults Insert/update DML operation results
        * @return Set<Id> Ids of successfully created/updated records
        */
        private Set<Id> getSuccessIds(Database.SaveResult[] saveResults) {
            Set<Id> successIds = new Set<Id>();

            if (saveResults == null || saveResults.isEmpty()) {
                return successIds;
            }

            for (Database.SaveResult result : saveResults) {
                if (result.isSuccess()) {
                    successIds.add(result.getId());
                }
            }
            return successIds;
        }

        /***
        * @description Deletes specified records
        * @param records Records to delete
        * @return void
        */
        public void deleteRecords(List<SObject> records) { 
            if (records == null || records.isEmpty()) {
                return;
            }

            List<Database.DeleteResult> deleteResults = Database.delete(records, false);
            handleErrors(deleteResults, records);
        }

        /***
        * @description Keeps track of errors
        * @param dmlResults Database DML results upon insert/update/delete operation
        * @param records SObject records in DML operation
        * @return void
        */
        private void handleErrors(List<Object> dmlResults, List<SObject> records) {
            if (records == null || records.isEmpty()) {
                return;
            }

            //extract errors
            ERR_Handler.Errors dmlErrors = ERR_Handler.getErrorsOnly(dmlResults, records);
            if (dmlErrors.errorRecords.isEmpty()) {
                return;
            }

            errorResult.errorRecords.addAll(
                dmlErrors.errorRecords
            );

            //track failed Recurring Donation Ids
            SObjectType recordSObjectType = records[0].getSObjectType();
            if (recordSObjectType == oppSObjectType) {
                for (Integer i = 0; i < dmlResults.size(); i++) {
                    Boolean isSuccess = dmlResults[i] instanceof Database.SaveResult
                        ? ((Database.SaveResult)dmlResults[i]).isSuccess()
                        : ((Database.DeleteResult)dmlResults[i]).isSuccess();

                    if (!isSuccess) {
                        failedRDIds.add((Id) records[i].get('npe03__Recurring_Donation__c'));
                    }
                }

            } else if (recordSObjectType == rdSObjectType) {
                for (Error__c error : dmlErrors.errorRecords) {
                    failedRDIds.add(error.Related_Record_ID__c);
                }
            }
        }

        /**
        * @description Creates Error__c record for each errorResult.errorRecords
        * @return void
        */
        public void processErrors() {
            errorResult.errorsExist = !errorResult.errorRecords.isEmpty();

            ERR_Handler.processErrorsOnly(errorResult, ERR_Handler_API.Context.RD.name());
        }
        
        /***
        * @description Returns number of failed Recurring Donations
        * @return Integer
        */
        public Integer getRecordsFailed() {
            failedRDIds.remove(null);

            return failedRDIds.size();
        }
    }
}