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

        List<Database.SaveResult> saveResults = insertOpportunities(opps);

        for (Integer i = 0; i < saveResults.size(); i++) {
            Database.SaveResult result = saveResults[i];

            if (result.isSuccess() == true) {
                //get all the new OppIds into a list
                createdOppIds.add(result.getId());

            } else {//handle errors on insert
                errorSaveResults.add(result);
                failedOpps.add(opps[i]);
            }
        }

        //Error handling due to bulk operations
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
        opp.Name = buildOpportunityName(rd, opp);

        if (rd.npe03__Recurring_Donation_Campaign__c != null && rdSettings.npe03__Add_Campaign_to_All_Opportunites__c) {
            opp.CampaignId = rd.npe03__Recurring_Donation_Campaign__c;
        }

        return opp;
    }

    /***
    * @description Constructs the opportunity name in a specific format.
    * @param rd Recurring donation 
    * @param opp The new Opportunity on the recurring donation.
    * @return String The Opportunity Name
    */
    private String buildOpportunityName(npe03__Recurring_Donation__c rd, Opportunity opp) {
        return
            rd.npe03__Donor_Name__c + ' ' +
            System.Label.npe03.RecurringDonationPrefix + ' (' +
            opp.Recurring_Donation_Installment_Number__c +  ') ' +
            opp.CloseDate.format();
    }

    /***
    * @description Creates opportunities
    * @param opps Opportunities
    * @return List<Database.SaveResult> SaveResult records after the DML operation.
    */
    private static List<Database.SaveResult> insertOpportunities(List<Opportunity> opps) {
        Set<Id> rdIds = new Set<Id>();
        Database.SaveResult[] saveResults;

        for (Opportunity o : opps) {
            rdIds.add(o.npe03__Recurring_Donation__c);
        }

        //Check if the Recurring donation is one or more to know if it gets saved from UI or from batch
        if (rdIds.size() == 1) {
            saveResults = Database.insert(opps, true);

        } else {//otherwise, this is a bulk operation.
            saveResults = Database.insert(opps, false);
        }

        return saveResults;
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

}