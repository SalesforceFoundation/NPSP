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

    private static Date TODAY = Date.today();
    private static npe03__Recurring_Donations_Settings__c rdSettings = UTIL_CustomSettingsFacade.getRecurringDonationsSettings();

    /***
    * @description The installment Opportunity Stage
    */
    @TestVisible
    private String oppStageName {
        get {
            if (oppStageName == null) {
                oppStageName = String.isNotBlank(rdSettings.InstallmentOppStageName__c)
                    ? rdSettings.InstallmentOppStageName__c
                    : System.Label.npe03.RecurringDonationStageName;
            }
            return oppStageName;
        } set;
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
    * @description Creates Opportunities and updates payment records for specified Recurring Donations
    * @param rds Recurring Donations
    * @return void
    */
    public void createInstallmentOpportunities(List<npe03__Recurring_Donation__c> rds) {
        if (rds.isEmpty()) {
            return;
        }

        Integer numberOfInstallments = 1;
        Map<Id, List<RD2_ScheduleService.Installment>> installmentsByRDId = 
            scheduleService.getVisualizedInstallments(rds, TODAY, numberOfInstallments, null);

        Set<Id> createdOppIds = createOpportunities(rds, installmentsByRDId);

        updatePaymentRecords(createdOppIds, installmentsByRDId);
    }

    /***
    * @description Creates Opportunities for a specified set of Recurring Donations
    * @param rds Recurring Donations
    * @param installmentsByRDId
    * @return Set<Id> Created Opportunity Ids
    */
    private Set<Id> createOpportunities(List<npe03__Recurring_Donation__c> rds, Map<Id, List<RD2_ScheduleService.Installment>> installmentsByRDId) {
        List<Opportunity> opps = new List<Opportunity>();

        for (npe03__Recurring_Donation__c rd : rds) {
            for (RD2_ScheduleService.Installment installment : installmentsByRDId.get(rd.Id)) {
                opps.add(buildOpportunity(rd, installment));
            }
        }

        if (opps.isEmpty()) {
            return new Set<Id>();
        }

        List<Database.SaveResult> saveResults = Database.insert(opps, false);
        handleErrors(saveResults, opps);

        return getSuccessRecordIds(saveResults);
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
            StageName = oppStageName,
            Amount = installment.installmentAmount,
            npe03__Recurring_Donation__c = rd.Id
        );
        opp.Recurring_Donation_Installment_Number__c = rd.npe03__Total_Paid_Installments__c != null
            ? rd.npe03__Total_Paid_Installments__c + 1 
            : 1;
        opp.Name = buildOpportunityName(rd.npe03__Donor_Name__c, opp);

        if (rdSettings.npe03__Record_Type__c != null) {
            opp.RecordTypeId = rdSettings.npe03__Record_Type__c;
        }

        if (rd.npe03__Recurring_Donation_Campaign__c != null && rdSettings.npe03__Add_Campaign_to_All_Opportunites__c) {
            opp.CampaignId = installment.campaignId;
        }

        return opp;
    }

    /***
    * @description Updates related future open installment Opps
    * Assumptions:
    * - A Recurring Donation should have *at most one* installment Opp with Close Date >= today
    * - The installment Opp can be either open or closed 
    * - If the Close Date = today, then the Opp can be closed or open
    * - If the Close Date > today, the Opp would most probably be open
    *
    * @param rds Recurring Donations
    * @return void
    */
    public void updateInstallmentOpportunities(List<npe03__Recurring_Donation__c> rds) {
        if (rds.isEmpty()) {
            return;
        }

        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        Integer numberOfInstallments = 1;
        Map<Id, List<RD2_ScheduleService.Installment>> installmentsByRDId = 
            scheduleService.getVisualizedInstallments(rds, TODAY, numberOfInstallments, null);   

        for (npe03__Recurring_Donation__c rd : rds) {
            List<Opportunity> rdOpps = getCurrentOpps(rd);
            if (rdOpps.isEmpty()) {
                continue;
            }
            //verify at most one Opp exists//TODO

            //update future open Opp only
            if (rdOpps[0].CloseDate <= TODAY) {
                continue;
            }
            if (installmentsByRDId.get(rd.Id).isEmpty()) {
                //throw new exception 
            }

            RD2_ScheduleService.Installment installment = installmentsByRDId.get(rd.Id)[0];
            Boolean isChanged = syncOppWithSchedule(rdOpps[0], installment, rd.npe03__Donor_Name__c);
            if (isChanged) {
                oppsToUpdate.add(rdOpps[0]);
            }
        }

        List<Database.SaveResult> saveResults = Database.update(oppsToUpdate, false);
        handleErrors(saveResults, oppsToUpdate);

        //update payments for all Opps regardless if they were updated in the step above
        updatePaymentRecords(UTIL_SObject.extractIds(oppsToUpdate), installmentsByRDId);
    }

    /***
    * @description Returns Opp with Close Date = today (if any) and all future open Opps
    * @param rd Recurring Donation
    * @return List<Opportunity>
    */
    private List<Opportunity> getCurrentOpps(npe03__Recurring_Donation__c rd) {
        List<Opportunity> opps = new List<Opportunity>();

        if (rd.npe03__Donations__r.isEmpty()) {
            return opps;
        }
        
        for (Opportunity opp : rd.npe03__Donations__r) {
            if ((opp.IsClosed == false && opp.CloseDate > TODAY) || opp.CloseDate == TODAY) {
                opps.add(opp);
            }
        }

        return opps;
    }

    /***
    * @description Updates Opportunity if the related Recurring Donation Schedule installment has been changed
    * @param opp Opportunity
    * @param installment Recurring Donation Schedule installment
    * @param donorName Recurring Donation donor name
    * @return Boolean
    */
    private Boolean syncOppWithSchedule(Opportunity opp,  RD2_ScheduleService.Installment installment, String donorName) {  
        if (installment == null) {
            return false;
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

        if (opp.CampaignId != installment.campaignId && rdSettings.npe03__Add_Campaign_to_All_Opportunites__c) {
            opp.CampaignId = installment.campaignId;
            isChanged = true;
        }

        return isChanged;
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
    * @description Updates payment method on the payment records for the created opportunities.
    * @param oppIds Opportunity Ids
    * @param installmentsByRDId Schedule installments by a Recurring Donation Id
    * @return void
    */
    private void updatePaymentRecords(Set<Id> oppIds, Map<Id, List<RD2_ScheduleService.Installment>> installmentsByRDId) {
        if (oppIds.isEmpty()) {
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
            WHERE npe01__Opportunity__c IN :oppIds
        ]) {
            Id rdId = payment.npe01__Opportunity__r.npe03__Recurring_Donation__c;
            //if the Opportunity has been updated or created, 
            //the first schedule installment exists and it is the matching installment
            String paymentMethod = installmentsByRDId.get(rdId)[0].paymentMethod;

            if (!String.isBlank(paymentMethod) 
                && payment.npe01__Payment_Method__c != paymentMethod
            ) {                
                payment.npe01__Payment_Method__c = paymentMethod;
                payments.add(payment);
            }
        }

        if (!payments.isEmpty()) {
            Database.SaveResult[] saveResults = Database.update(payments, false);
            handleErrors(saveResults, payments);
        }
    }

    /***
    * @description Logs errors
    * @param saveResults Database save results upon insert/update DML
    * @param records SObject records attempted to save
    * @return void
    */
    private void handleErrors(List<Database.SaveResult> saveResults, List<SObject> records) {
        ERR_Handler.Errors errors = ERR_Handler.getErrors(saveResults, records);
        ERR_Handler.processErrorsOnly(errors, ERR_Handler_API.Context.RD.name());
    }

    /***
    * @description Return Ids of records that have been inserted/updated successfully
    * @param saveResults Database save results
    * @return Set<Id>
    */
    private Set<Id> getSuccessRecordIds(List<Database.SaveResult> saveResults) {
        Set<Id> ids = new Set<Id>();

        for (Database.SaveResult result : saveResults) {
            if (result.isSuccess()) {
                ids.add(result.getId());
            }
        }
        return ids;
    }

    /**
    * @description Custom Opportunity service exception
    */
    private class ServiceException extends Exception { }
}