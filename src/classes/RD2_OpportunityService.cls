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
    * @description Determines the installment Opportunity Stage
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
    * @param rdsWithCloseDates The Map of Recurring Donations with close dates
    * @return void
    */
    public void createInstallmentOpportunities(Map<npe03__Recurring_Donation__c, List<Date>> rdsWithCloseDates) {
        if (rdsWithCloseDates.isEmpty()) {
            return;
        }

        Set<Id> createdOppIds = createOpportunities(rdsWithCloseDates);

        updatePaymentRecords(createdOppIds, rdsWithCloseDates.keySet());
    }

    /***
    * @description Creates Opportunities for a specified set of Recurring Donations
    * @param rdsWithCloseDates The Map of Recurring Donations with close dates
    * @return Set<Id> Created Opportunity Ids
    */
    private Set<Id> createOpportunities(Map<npe03__Recurring_Donation__c, List<Date>> rdsWithCloseDates) {
        Set<Id> createdOppIds = new Set<Id>();
        List<Database.SaveResult> errorSaveResults = new List<Database.SaveResult>();
        List<Opportunity> failedOpps = new List<Opportunity>();

        List<Opportunity> opps = buildOpportunities(rdsWithCloseDates);

        if (opps.isEmpty()) {
            return createdOppIds;
        }

        List<Database.SaveResult> saveResults = Database.insert(opps, false);

        for (Integer i = 0; i < saveResults.size(); i++) {
            Database.SaveResult result = saveResults[i];

            if (result.isSuccess()) {
                createdOppIds.add(result.getId());

            } else {
                errorSaveResults.add(result);
                failedOpps.add(opps[i]);
            }
        }

        //Process errors (if any)
        if (!errorSaveResults.isEmpty()) {
            ERR_Handler.Errors errors = ERR_Handler.getErrors(errorSaveResults, failedOpps);
            ERR_Handler.processErrors(errors.errorRecords, ERR_Handler_API.Context.RD.name());
        }

        return createdOppIds;
    }

    /***
    * @description Builds Opportunities for the specified Recurring Donation and Close Dates
    * @param rdsWithCloseDates the Map of Recurring Donations with various close dates
    * @return List<Opportunity>
    */
    private List<Opportunity> buildOpportunities(Map<npe03__Recurring_Donation__c, List<Date>> rdsWithCloseDates) {
        List<Opportunity> opps = new List<Opportunity>();

        for (npe03__Recurring_Donation__c rd : rdsWithCloseDates.keySet()) {
            List<Date> closeDates = rdsWithCloseDates.get(rd);

            for (Date closeDate : closeDates) {
                opps.add(buildOpportunity(rd, closeDate));
            }
        }

        return opps;
    }

    /***
    * @description Builds the opportunity and populates its fields from the recurring donation.
    * @param rd Recurring donation
    * @param closeDate The next donation date on the recurring donation.
    * @return Opportunity
    */
    private Opportunity buildOpportunity(npe03__Recurring_Donation__c rd, Date closeDate) {
        Opportunity opp = new Opportunity(
            AccountId = rd.npe03__Organization__c,
            Primary_Contact__c = rd.npe03__Contact__c,
            CloseDate = closeDate,
            StageName = oppStageName,
            Amount = rd.npe03__Amount__c,
            Recurring_Donation_Installment_Number__c = (rd.npe03__Total_Paid_Installments__c != null ?
                rd.npe03__Total_Paid_Installments__c + 1 : 1),
            npe03__Recurring_Donation__c = rd.Id
        );
        opp.Name = buildOpportunityName(rd.npe03__Donor_Name__c, opp);

        if (rdSettings.npe03__Record_Type__c != null) {
            opp.RecordTypeId = rdSettings.npe03__Record_Type__c;
        }

        if (rd.npe03__Recurring_Donation_Campaign__c != null && rdSettings.npe03__Add_Campaign_to_All_Opportunites__c) {
            opp.CampaignId = rd.npe03__Recurring_Donation_Campaign__c;
        }

        return opp;
    }



    public void updateInstallmentOpportunities(List<npe03__Recurring_Donation__c> rds) {
        if (rds.isEmpty()) {
            return;
        }

        Map<Id, List<RD2_ScheduleService.Installment>> rdsWithInstallments = scheduleService.getVisualizedInstallments(rds, TODAY, 1, null);    //TODO    

        List<Opportunity> opps = getModifiedOpps(rds, rdsWithInstallments);
        List<Database.SaveResult> saveResults = Database.update(opps, false);

        updatePaymentRecords(extractIds(opps), rdsWithInstallments);
    }

    private List<Opportunity> getModifiedOpps(List<npe03__Recurring_Donation__c> rds, Map<Id, List<RD2_ScheduleService.Installment>> rdsWithInstallments) {
        List<Opportunity> opps = new List<Opportunity>();

        for (npe03__Recurring_Donation__c rd : rds) {
            for (Opportunity opp : getFutureOpenOpps(rd)) {

                RD2_ScheduleService.Installment installment = getMatchingInstallment(opp, rdsWithInstallments.get(rd.id));
                syncOppWithSchedule(opp, installment, rd.npe03__Donor_Name__c, opps);
            }
        }

        return opps;
    }

    private RD2_ScheduleService.Installment getMatchingInstallment(Opportunity opp, List<RD2_ScheduleService.Installment> installments) {  
        return installments[0];//TODO
    }
    
    private List<Opportunity> getFutureOpenOpps(npe03__Recurring_Donation__c rd) {
        List<Opportunity> opps = new List<Opportunity>();

        if (rd.npe03__Donations__r.isEmpty()) {
            return opps;
        }
        
        for (Opportunity opp : rd.npe03__Donations__r) {
            if (opp.IsClosed == false && opp.CloseDate > TODAY) {
                opps.add(opp);
            }
        }

        return opps;
    }

    private void syncOppWithSchedule(Opportunity opp,  RD2_ScheduleService.Installment installment, String donorName, List<Opportunity> opps) {  
        if (installment == null) {
            return;
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

        if (installment.campaignId != null && opp.CampaignId != installment.campaignId && rdSettings.npe03__Add_Campaign_to_All_Opportunites__c) {
            opp.CampaignId = installment.campaignId;
            isChanged = true;
        }

        if (isChanged) {
            opps.add(opp);
        }
    }

    /***
    * @description Constructs the opportunity name in a specific format.
    * @return String The Opportunity Name
    */
    private String buildOpportunityName(String donorName, Opportunity opp) {
        return
            donorName + ' ' +
            System.Label.npe03.RecurringDonationPrefix + ' (' +
            opp.Recurring_Donation_Installment_Number__c.format() +  ') ' +
            opp.CloseDate.format();
    }

    /***
    * @description Updates payment method on the payment records for the created opportunities.
    * @param oppIds Opportunity Ids
    * @param rdsWithInstallments RD2_ScheduleService.Installments with rdids
    * @return void
    */
    private void updatePaymentRecords(Set<Id> oppIds, Map<Id, List<RD2_ScheduleService.Installment>> rdsWithInstallments) {
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
            RD2_ScheduleService.Installment installment = rdsWithInstallments.get(rdId)[0];
            String paymentMethod = installment.paymentMethod;

            if (String.isBlank(paymentMethod) || payment.npe01__Payment_Method__c == paymentMethod ) {
                continue;
            }
            payment.npe01__Payment_Method__c = paymentMethod;
            payments.add(payment);
        }

        if (!payments.isEmpty()) {
            Database.SaveResult[] saveResults = Database.update(payments, false);
        }

    }

    /***
    * @description Updates payment method on the payment records for the created opportunities.
    * @param oppIds Opportunity Ids
    * @param rds Recurring Donations
    * @return void
    */
    private void updatePaymentRecords(Set<Id> oppIds, Set<npe03__Recurring_Donation__c> rds) {
        List<npe01__OppPayment__c> payments = new List <npe01__OppPayment__c>();
        Map<Id, String> paymentMethodByRDId = new Map<Id, String>();

        for (npe03__Recurring_Donation__c r : rds) {
            paymentMethodByRDId.put(r.Id, r.PaymentMethod__c);
        }

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
            String paymentMethod = paymentMethodByRDId.get(rdId);

            if (String.isBlank(paymentMethod)) {
                continue;
            }

            payment.npe01__Payment_Method__c = paymentMethod;
            payments.add(payment);
        }

        if (!payments.isEmpty()) {
            Database.SaveResult[] saveResults = Database.update(payments, false);
        }
    }

    /***
    * @description Extracts record Ids from a list of SObject records.
    * @param records
    * @return Set<Id>
    */
    private Set<Id> extractIds(List<SObject> records) {
        if (records == null || records.isEmpty()) {
            return new Set<Id>();
        }
        return new Map<Id, SObject>(records).keySet();
    }

}