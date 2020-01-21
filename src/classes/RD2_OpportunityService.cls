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
    public RD2_OpportunityEvaluationService.DatabaseService dbService {
        get {
            if (dbService == null) {
                dbService = new RD2_OpportunityEvaluationService.DatabaseService();
            }
            return dbService;
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
    */
    public RD2_OpportunityService(Date currentDate, RD2_OpportunityEvaluationService.DatabaseService dbService) {
        this.currentDate = currentDate;
        this.dbService = dbService;
    }

    /***
    * @description Creates Opportunities and updates payment records for specified Recurring Donations
    * @param rds Recurring Donations
    * @return void
    */
    public void createOpportunities(List<npe03__Recurring_Donation__c> rds) {
        List<Opportunity> oppsToCreate = new List<Opportunity>();
        Map<Id, List<RD2_ScheduleService.Installment>> installmentsByRDId = new Map<Id, List<RD2_ScheduleService.Installment>>();
        Integer numberOfInstallments = 1;

        for (npe03__Recurring_Donation__c rd : rds) {
            List<RD2_ScheduleService.Installment> installments = scheduleService.getVisualizedInstallments(
                currentDate, numberOfInstallments, rd.RecurringDonationSchedules__r
            );
            installmentsByRDId.put(rd.Id, installments);

            if (installments.isEmpty()) {
                continue;
            }

            RD2_OpportunityMatcher matcher = new RD2_OpportunityMatcher(currentDate)
                .filterCurrent(rd.npe03__Donations__r)
                .match(installments);

            for (RD2_OpportunityMatcher.Record record : matcher.getRecords()) {
                if (record.isNew()) {
                    oppsToCreate.add(buildOpportunity(rd, record.getInstallment()));
                }
            }
        }

        if (oppsToCreate.isEmpty()) {
            return;
        }

        Set<Id> createdOppIds = dbService.insertRecords(oppsToCreate);

        Map<Id, RD2_ScheduleService.Installment> installmentByOppId = new Map<Id, RD2_ScheduleService.Installment>();
        for (Opportunity opp : oppsToCreate) {
            if (createdOppIds.contains(opp.Id)) {
                installmentByOppId.put(opp.Id, installmentsByRDId.get(opp.npe03__Recurring_Donation__c)[0]);
            }
        }

        updatePaymentRecords(installmentByOppId);
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
        opp.Name = buildOpportunityName(rd.npe03__Donor_Name__c, opp);

        if (rdSettings.installmentRecordTypeId != null) {
            opp.RecordTypeId = rdSettings.installmentRecordTypeId;
        }

        if (rd.npe03__Recurring_Donation_Campaign__c != null && rdSettings.shouldSetInstallmentCampaign) {
            opp.CampaignId = installment.campaignId;
        }

        return opp;
    }

    /***
    * @description Constructs the opportunity name in a specific format.
    * @return String The Opportunity Name
    */
    private String buildOpportunityName(String donorName, Opportunity opp) {
        return
            donorName + ' '
            + System.Label.npe03.RecurringDonationPrefix
            + ' (' + opp.Recurring_Donation_Installment_Number__c +  ') '
            + opp.CloseDate.format();
    }

    /***
    * @description Updates related future open installment Opps
    * @param rds Recurring Donations
    * @return void
    */
    public void updateOpportunities(List<npe03__Recurring_Donation__c> rds) {
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        Map<Id, RD2_ScheduleService.Installment> installmentByOppId = new Map<Id, RD2_ScheduleService.Installment>();

        //Synchronize Opps with matching Schedule installments
        for (npe03__Recurring_Donation__c rd : rds) {
            RD2_OpportunityMatcher matcher = new RD2_OpportunityMatcher(currentDate)
                .filterCurrent(rd.npe03__Donations__r);

            List<RD2_ScheduleService.Installment> installments = scheduleService.getVisualizedInstallments(
                currentDate, matcher.size(), rd.RecurringDonationSchedules__r
            );

            matcher.match(installments);

            for (RD2_OpportunityMatcher.Record record : matcher.getRecords()) {
                if (record.isNew() || !record.isOpen() || !record.hasInstallment()) {
                    continue;
                }

                RD2_ScheduleService.Installment installment = record.getInstallment();
                Opportunity opp = record.getOpportunity();

                installmentByOppId.put(opp.Id, installment);

                Boolean isChanged = syncOppWithSchedule(opp, installment, rd.npe03__Donor_Name__c);
                if (isChanged) {
                    oppsToUpdate.add(opp);
                }
            }
        }

        dbService.updateRecords(oppsToUpdate);

        updatePaymentRecords(installmentByOppId);
    }

    /***
    * @description Updates Opportunity if it differs from the related Recurring Donation Schedule installment
    * @param opp Opportunity
    * @param installment Recurring Donation Schedule installment
    * @param donorName Recurring Donation donor name
    * @return Boolean
    */
    private Boolean syncOppWithSchedule(Opportunity opp, RD2_ScheduleService.Installment installment, String donorName) {
        //An installment Opportunity should always have a matching RD Schedule installment.
        //If the installment is null, this is most probably a programatic error.
        if (installment == null) {
            opp.addError(System.Label.RD2_ScheduleInstallmentIsRequired);
            return true;
        }

        Boolean isChanged = false;

        if (opp.Amount != installment.installmentAmount) {
            opp.Amount = installment.installmentAmount;
            isChanged = true;
        }

        if (opp.CloseDate != installment.nextDonationDate) {
            opp.CloseDate = installment.nextDonationDate;
            opp.name = buildOpportunityName(donorName, opp);
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
     * @return void
     */
    public void voidOpenOpportunities(List<npe03__Recurring_Donation__c> rds) {
        if (rds.isEmpty() || rdSettings.isCloseActionNoAction()) {
            return;
        }

        List<Opportunity> openOppsToVoid = new List<Opportunity>();
        for (npe03__Recurring_Donation__c rd : rds) {
            for (Opportunity opp : rd.npe03__Donations__r) {
                if (opp.IsClosed == false) {
                    openOppsToVoid.add(opp);
                }
            }
        }

        if (openOppsToVoid.isEmpty()) {
            return;
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
    }
}