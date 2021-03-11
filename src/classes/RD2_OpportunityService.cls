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
* @description Create Installment Opportunities for specified Recurring Donations
*
*/
public with sharing class RD2_OpportunityService {

    /***
     * @description CurrencyIsoCode field name
     */
    private static final String CURRENCY_ISO_CODE_FIELD = UTIL_Currency.CURRENCY_ISO_CODE_FIELD;


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

    /***
    * @description Recurring Donation Schedule service
    */
    @TestVisible
    private RD2_ScheduleService scheduleService {
        get {
            if (scheduleService == null) {
                scheduleService = new RD2_ScheduleService();
            }
            return scheduleService;
        } set;
    }

    /***
    * @description Applies DML operations on records and keeps track of errors
    */
    public RD2_DatabaseService dbService {
        get {
            if (dbService == null) {
                dbService = new RD2_DatabaseService();
            }
            return dbService;
        }
        private set;
    }

    /***
    * @description Contains custom field mapping from Recurring Donation into related Opportunity records
    */
    private RD2_CustomFieldMapper customFieldMapper{
        get {
            if (customFieldMapper == null) {
                customFieldMapper = new RD2_CustomFieldMapper();
            }
            return customFieldMapper;
        }
        private set;
    }

    /**
    * @description Current date used as a cut off date to filter out and evaluate Opportunities
     * with projected RD schedule installments as of the current date.
     * It can be a date in past, today or a future date in testing. When executed from a scheduler,
     * the current date is always today.
    */
    private Date currentDate;


    /***
    * @description Constructor
    * @param currentDate Current Date (that can be overwritten for testing purposes)
    * @param dbService Database service used to create, update and delete Opportunities, Payments, etc.
    * @param customFieldMapper Custom field mapper containing RD -> Opportunity field mapping
    */
    public RD2_OpportunityService(Date currentDate,
        RD2_DatabaseService dbService,
        RD2_CustomFieldMapper customFieldMapper
    ) {
        this.currentDate = currentDate;
        this.dbService = dbService;
        this.customFieldMapper = customFieldMapper;
    }

    /***
    * @description Creates Opportunities for the next donation date if it does not exist already 
    * and updates payment records for specified Recurring Donations
    * @param rds Recurring Donations
    * @return RD2_OpportunityService This Opportunity Service instance
    */
    public RD2_OpportunityService createOpportunities(List<npe03__Recurring_Donation__c> rds) {
        List<Opportunity> oppsToCreate = new List<Opportunity>();
        Map<Id, List<RD2_ScheduleService.Installment>> installmentsByRDId = new Map<Id, List<RD2_ScheduleService.Installment>>();

        Integer numberOfInstallments = 1;
        for (npe03__Recurring_Donation__c rd : rds) {
            RD2_OpportunityMatcher.Record nextDonationDateRecord = scheduleService.getNextDonationDateRecord(
                new RD2_RecurringDonation(rd), rd.RecurringDonationSchedules__r
            );

            if (nextDonationDateRecord == null
                || !nextDonationDateRecord.isNew()
                || nextDonationDateRecord.getInstallment().nextDonationDate < currentDate
            ) {
                continue;
            }

            oppsToCreate.add(buildOpportunity(rd, nextDonationDateRecord.getInstallment()));
            installmentsByRDId.put(rd.Id, new List<RD2_ScheduleService.Installment>{ nextDonationDateRecord.getInstallment() });
        }

        Set<Id> createdOppIds = dbService.insertRecords(oppsToCreate);

        Map<Id, RD2_ScheduleService.Installment> installmentByOppId = new Map<Id, RD2_ScheduleService.Installment>();

        for (Opportunity opp : oppsToCreate) {
            if (createdOppIds.contains(opp.Id)
                && installmentsByRDId.containsKey(opp.npe03__Recurring_Donation__c)
            ) {
                installmentByOppId.put(opp.Id, installmentsByRDId.get(opp.npe03__Recurring_Donation__c)[0]);
            }
        }

        updatePaymentRecords(installmentByOppId);
        return this;
    }

    /***
    * @description Builds the opportunity and populates its fields from the recurring donation.
    * @param rd Recurring donation
    * @param installment Recurring Donation Schedule installment
    * @return Opportunity
    */
    private Opportunity buildOpportunity(npe03__Recurring_Donation__c rd, RD2_ScheduleService.Installment installment) {
        Opportunity opp = new Opportunity(
            AccountId = rd.npe03__Organization__c,
            Primary_Contact__c = rd.npe03__Contact__c,
            CloseDate = installment.nextDonationDate,
            StageName = rdSettings.installmentStage,
            Amount = installment.installmentAmount,
            npe03__Recurring_Donation__c = rd.Id
        );
        opp.Recurring_Donation_Installment_Number__c = rd.npe03__Total_Paid_Installments__c != null
            ? rd.npe03__Total_Paid_Installments__c + 1
            : 1;

        if (rdSettings.installmentRecordTypeId != null) {
            opp.RecordTypeId = rdSettings.installmentRecordTypeId;
        }

        if (rd.npe03__Recurring_Donation_Campaign__c != null && rdSettings.shouldSetInstallmentCampaign) {
            opp.CampaignId = installment.campaignId;
        }

        syncOppCurrency(opp, rd);

        customFieldMapper.populateOpportunityFields(opp, rd);

        opp.Name = buildOpportunityName(rd, opp);

        return opp;
    }

    /***
    * @description Constructs the opportunity name in a specific format.
    * @return String The Opportunity Name
    */
    private String buildOpportunityName(npe03__Recurring_Donation__c rd, Opportunity opp) {
        String oppName = rd.npe03__Donor_Name__c + ' '
            + System.Label.npe03.RecurringDonationPrefix;

        if (new RD2_RecurringDonation(rd).isFixedLength()) {
            oppName += ' (' + opp.Recurring_Donation_Installment_Number__c +  ')';
        }
        oppName += ' ' + opp.CloseDate.format();        
        return oppName;
    }

    /***
    * @description Updates related future open installment Opps
    * @param rds Recurring Donations
    * @return RD2_OpportunityService This Opportunity Service instance
    */
    public RD2_OpportunityService updateOpportunities(List<npe03__Recurring_Donation__c> rds) {
        return updateOpportunities(rds, new Set<Id>());
    }

    /***
    * @description Updates related future open installment Opps
    * @param rds Recurring Donations
    * @param rdIdsWhereScheduleChanged Recurring Donation Ids for which a schedule has been changed
    * schedule has changed
    * @return RD2_OpportunityService This Opportunity Service instance
    */
    public RD2_OpportunityService updateOpportunities(List<npe03__Recurring_Donation__c> rds, Set<Id> rdIdsWhereScheduleChanged) {
        Map<Id, Opportunity> updatedOppById = new Map<Id, Opportunity>();
        Map<Id, RD2_ScheduleService.Installment> installmentByOppId = new Map<Id, RD2_ScheduleService.Installment>();

        //Synchronize Opps with matching Schedule installments
        for (npe03__Recurring_Donation__c rd : rds) {
            RD2_OpportunityMatcher matcher = new RD2_OpportunityMatcher(currentDate)
                .includeCurrentOrOpen(rd.npe03__Donations__r);

            Integer numberOfInstallments = matcher.getNumberOfOpportunities();
            matcher.match(scheduleService.getVisualizedInstallments(
                currentDate, numberOfInstallments, rd.RecurringDonationSchedules__r
            ));

            // Track unmatched matcher records so we can connect Opps and RDs from RDs with altered schedules
            Boolean isOpenOppMatched = false;
            Opportunity earliestUnmatchedOpp;
            RD2_ScheduleService.Installment earliestUnmatchedInstallment;

            for (RD2_OpportunityMatcher.Record record : matcher.getRecords()) {

                if (record.hasInstallment() && record.isNew()) {
                    earliestUnmatchedInstallment = getEarliestInstallment(record.getInstallment(), earliestUnmatchedInstallment);
                }

                if (record.isNew() || !record.isOpen()) {
                    continue;
                }

                Opportunity opp = record.getOpportunity();
                if (record.hasInstallment()) {
                    installmentByOppId.put(opp.Id, record.getInstallment());
                    isOpenOppMatched = true;

                } else {
                    earliestUnmatchedOpp = getEarliestOpportunity(record.getOpportunity(), earliestUnmatchedOpp);
                }

                Opportunity updatedOpp = updateOpportunity(opp, record.getInstallment(), rd);
                if (updatedOpp != null) {
                    updatedOppById.put(updatedOpp.Id, updatedOpp);
                }
            }

            if (!isOpenOppMatched && rdIdsWhereScheduleChanged.contains(rd.Id)) {
                if (earliestUnmatchedOpp == null || earliestUnmatchedInstallment == null) {
                    continue;
                }

                Opportunity updatedOpp = updateOpportunity(earliestUnmatchedOpp, earliestUnmatchedInstallment, rd);
                if (updatedOpp != null) {
                    updatedOppById.put(updatedOpp.Id, updatedOpp);
                }
            }
        }

        dbService.updateRecords(updatedOppById.values());

        RD2_QueueableService.enqueueOppNamingService(updatedOppById.values());

        updatePaymentRecords(installmentByOppId);
        return this;
    }

    /***
    * @description Compares two installments and returns the earliest of the two
    * @param currentInstallment Installment
    * @param earliestInstallment Installment
    * @return RD2_ScheduleService.Installment Earlier of the two installments
    */
    private RD2_ScheduleService.Installment getEarliestInstallment(RD2_ScheduleService.Installment currentInstallment, RD2_ScheduleService.Installment earliestInstallment) {
        Boolean isEarlier = earliestInstallment == null
            || currentInstallment.nextDonationDate < earliestInstallment.nextDonationDate;

        if (isEarlier) {
            earliestInstallment = currentInstallment;
        }

        return earliestInstallment;
    }

    /***
    * @description Compares two Opportunities and returns the earliest of the two
    * @param currentOpp Opportunity
    * @param earliestUnmatchedOpp Opportunity
    * @return Opportunity Earlier of the two Opportunities
    */
    private Opportunity getEarliestOpportunity(Opportunity currentOpp, Opportunity earliestUnmatchedOpp) {
        Boolean isEarlier = earliestUnmatchedOpp == null ||
            currentOpp.CloseDate < earliestUnmatchedOpp.CloseDate;
        Boolean isPast = currentOpp.CloseDate < currentDate;

        if (isEarlier && !isPast) {
            earliestUnmatchedOpp = currentOpp;
        }

        return earliestUnmatchedOpp;
    }

    /***
    * @description Updates Opportunity if it differs from the installment passed in
    * @param opp Opportunity
    * @param installment RD2_ScheduleService.Installment
    * @param rd Recurring Donation
    * @return Opportunity Updated Opportunity or null if no update
    */
    private Opportunity updateOpportunity(Opportunity opp, RD2_ScheduleService.Installment installment, npe03__Recurring_Donation__c rd) {
        Boolean isChanged = syncOppWithRecurringDonation(opp, rd);
        isChanged = syncOppWithInstallment(opp, installment) || isChanged;

        if (isChanged) {
            opp.Name = buildOpportunityName(rd, opp);
            return opp;
        }
        return null;
    }

    /***
    * @description Updates Opportunity if it differs from the related Recurring Donation Schedule installment
    * @param opp Opportunity
    * @param rd Recurring Donation
    * @return Boolean Indicates if the Opportunity has been changed
    */
    private Boolean syncOppWithRecurringDonation(Opportunity opp, npe03__Recurring_Donation__c rd) {
        Boolean isDonorChanged = syncOppDonorInfo(opp, rd);

        Boolean isCurrencyChanged = syncOppCurrency(opp, rd);

        Boolean isCustomFieldChanged = customFieldMapper.syncOpportunityFields(opp, rd);

        return isDonorChanged || isCurrencyChanged || isCustomFieldChanged;
    }

    /***
    * @description Updates Opportunity with the projected installment (if any)
    * @param opp Opportunity
    * @param installment Recurring Donation Schedule installment
    * @return Boolean Indicates if the Opportunity has been changed
    */
    private Boolean syncOppWithInstallment(Opportunity opp, RD2_ScheduleService.Installment installment) {
        if (installment == null || opp.CloseDate < currentDate) {
            return false;
        }

        Boolean isChanged = false;

        if (opp.Amount != installment.installmentAmount) {
            opp.Amount = installment.installmentAmount;
            isChanged = true;
        }

        if (opp.CloseDate != installment.nextDonationDate) {
            opp.CloseDate = installment.nextDonationDate;
            isChanged = true;
        }

        if (installment.campaignId != null
            && opp.CampaignId != installment.campaignId
            && rdSettings.shouldSetInstallmentCampaign
        ) {
            opp.CampaignId = installment.campaignId;
            isChanged = true;
        }

        return isChanged;
    }

    /***
    * @description Updates Opportunity Account and/or Primary Contact if it differs
    * from the related Recurring Donation. Past open Opportunities are not updated.
    * @param opp Opportunity
    * @param rd Recurring Donation
    * @return Boolean Indicates if the donor info on the Opportunity has been changed
    */
    private Boolean syncOppDonorInfo(Opportunity opp, npe03__Recurring_Donation__c rd) {
        if (opp.CloseDate < currentDate) {
            return false;
        }

        Boolean isChanged = false;

        if (opp.AccountId != rd.npe03__Organization__c) {
            opp.AccountId = rd.npe03__Organization__c == null
                ? rd.npe03__Contact__c != null ? rd.npe03__Contact__r.AccountId : null
                : rd.npe03__Organization__c;

            isChanged = true;
        }

        if (opp.Primary_Contact__c != rd.npe03__Contact__c) {
            opp.Primary_Contact__c = rd.npe03__Contact__c;
            isChanged = true;
        }

        return isChanged;
    }

    /***
    * @description Updates Opportunity CurrencyIsoCode if it differs from the related Recurring Donation
    * @param opp Opportunity
    * @param rd Recurring Donation
    * @return Boolean Indicates if the currency on the Opportunity has been changed
    */
    private Boolean syncOppCurrency(Opportunity opp, npe03__Recurring_Donation__c rd) {
        if (!isMultiCurrencyEnabled || opp.IsClosed) {
            return false;
        }

        String rdCurrency = (String) rd.get(CURRENCY_ISO_CODE_FIELD);
        if ((String) opp.get(CURRENCY_ISO_CODE_FIELD) != rdCurrency) {
            opp.put(CURRENCY_ISO_CODE_FIELD, rdCurrency);
            return true;
        }

        return false;
    }

    /***
    * @description Updates payment method on the payment records for the created opportunities.
    * @param installmentByOppId Schedule installment by an Opp Id
    * @return void
    */
    private void updatePaymentRecords(Map<Id, RD2_ScheduleService.Installment> installmentByOppId) {
        if (installmentByOppId.isEmpty()) {
            return;
        }

        List<npe01__OppPayment__c> payments = new List <npe01__OppPayment__c>();
        for (npe01__OppPayment__c payment : [
            SELECT
                npe01__Payment_Method__c,
                npe01__Payment_Date__c,
                npe01__Opportunity__c,
                npe01__Opportunity__r.npe03__Recurring_Donation__c
            FROM npe01__OppPayment__c
            WHERE npe01__Opportunity__c IN :installmentByOppId.keySet()
        ]) {
            RD2_ScheduleService.Installment installment = installmentByOppId.get(payment.npe01__Opportunity__c);

            if (installment != null
                && String.isNotBlank(installment.paymentMethod)
                && payment.npe01__Payment_Method__c != installment.paymentMethod
            ) {
                payment.npe01__Payment_Method__c = installment.paymentMethod;
                payments.add(payment);
            }
        }

        dbService.updateRecords(payments);
    }

    /**
     * @description Updates or deletes closed RD open Installment Opportunities based on the settings
     * @param opps Opportunities
     * @return RD2_OpportunityService This Opportunity Service instance
     */
    public RD2_OpportunityService voidOpenOpportunities(List<npe03__Recurring_Donation__c> rds) {
        if (rds.isEmpty() || rdSettings.isCloseActionNoAction()) {
            return this;
        }

        List<Opportunity> openOppsToVoid = new List<Opportunity>();
        for (npe03__Recurring_Donation__c rd : rds) {
            for (Opportunity opp : rd.npe03__Donations__r) {
                if (opp.IsClosed == false) {
                    openOppsToVoid.add(opp);
                }
            }
        }

        if (rdSettings.isCloseActionDeletion()) {
            dbService.deleteRecords(openOppsToVoid);

        } else if (rdSettings.isCloseActionClosedLost()) {
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            for (Opportunity opp : openOppsToVoid) {
                oppsToUpdate.add(new Opportunity(
                    Id = opp.Id,
                    npe03__Recurring_Donation__c = opp.npe03__Recurring_Donation__c,
                    StageName = System.Label.npe03.RecurringDonationClosedLostOpportunityStage
                ));
            }

            dbService.updateRecords(oppsToUpdate);
        }

        return this;
    }
}