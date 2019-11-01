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
* @description Create Opportunities from Recurring Donations
*
*/
public with sharing class RD2_OpportunityService {

    private static npe03__Recurring_Donations_Settings__c rdSettings = UTIL_CustomSettingsFacade.getRecurringDonationsSettings();

    /***
    * @description return the oppStageName from the custom settings rdsettings if it exists or
    * from the label RecurringDonationStageName
    */
    @TestVisible
    private String oppStageName {
        get {
            if (oppStageName == null) {
                oppStageName = (rdSettings.InstallmentOppStageName__c != null
                    ? rdSettings.InstallmentOppStageName__c : System.Label.npe03.RecurringDonationStageName);
            }
            return oppStageName;
        } set;
    }

    /***
    * @description inserts one or more Opportunity records for a specified set of Recurring Donations
    * @param rdsWithCloseDates the Map of Recurring Donations with close dates
    */
    public void createInstallmentOpportunities(Map<npe03__Recurring_Donation__c, List<Date>> rdsWithCloseDates) {

        if (rdsWithCloseDates.isEmpty()) {
            return;
        }

        List<Opportunity> oppsToInsert;
        Set<Id> createdOppIds = new Set<Id>();
        Integer oppItem = 0;
        Map<Id,String> rdPaymentMethods = new Map<Id,String>();
        List<Database.SaveResult> badSRs = new List<Database.SaveResult>();
        List<Opportunity> badOpps = new List<Opportunity>();

        for (npe03__Recurring_Donation__c r : rdsWithCloseDates.keySet()) {
            rdPaymentMethods.put(r.Id,r.PaymentMethod__c);
        }

        oppsToInsert = createOpportunitiesForRecurringDonation(rdsWithCloseDates);

        if (oppsToInsert.size() > 0) {
            for (Database.SaveResult s : insertOpportunities(oppsToInsert)) {
                if (s.isSuccess() == true) {
                    //get all the new OppIds into a list
                    createdOppIds.add(s.getId());

                } else {//handle errors on insert
                    badSRs.add(s);
                    badOpps.add(oppsToInsert[oppItem]);
                }
                oppItem++;
            }
            //Error handling due to bulk operations
            if (!badSRs.isEmpty()) {
               ERR_Handler.Errors errors = ERR_Handler.getErrors(badSRs, badOpps);
               ERR_Handler.processErrors(errors.errorRecords, ERR_Handler_API.Context.RD.name());
            }
        }
        updatePaymentRecords(createdOppIds, rdPaymentMethods);
    }

    /***
    * @description Gets one or more Opportunity records for a specified set of Recurring Donations with close dates
    * @param rdsWithCloseDates the Map of Recurring Donations with close dates
    * @return the list of Opportunities to be created.
    */
    private List<Opportunity> createOpportunitiesForRecurringDonation(Map<npe03__Recurring_Donation__c, List<Date>> rdsWithCloseDates) {

        List<Opportunity> oppsToInsert = new List<Opportunity>();

        for (npe03__Recurring_Donation__c r : rdsWithCloseDates.keySet()) {
            for(Integer i = 0;i< rdsWithCloseDates.get(r).size();i++) {
                oppsToInsert.add(buildOpportunity(r, rdsWithCloseDates.get(r)[i]));

            }
          }
        return oppsToInsert;
    }

    /***
    * @description populate the opportunity's fields from recurring donation.
    * @param rd is the Recurring donation record.
    * @param closeDate is the next donation date on the recurring donation.
    * @return the opportunity record
    */
    private Opportunity buildOpportunity(npe03__Recurring_Donation__c rd, Date closeDate) {

        Opportunity opp = new Opportunity(
            AccountId = rd.npe03__Organization__c,
            Primary_Contact__c = rd.npe03__Contact__c,
            CloseDate = closeDate,
            StageName = oppStageName,
            Amount = rd.npe03__Amount__c,
            Name = buildOpportunityName(rd, closeDate),
            npe03__Recurring_Donation__c = rd.Id,
            Recurring_Donation_Installment_Number__c = (rd.npe03__Total_Paid_Installments__c != null ?
                rd.npe03__Total_Paid_Installments__c + 1 : 1)
        );

        if (rd.npe03__Recurring_Donation_Campaign__c != null && rdSettings.npe03__Add_Campaign_to_All_Opportunites__c ) {
            opp.CampaignId = rd.npe03__Recurring_Donation_Campaign__c;
        }
        return opp;
    }

    /***
    * @description build the opportunity name in specific format.
    * @param rd is the Recurring donation record
    * @param closeDate is the next donation date on the recurring donation.
    * @return the opportunity name
    */
    private String buildOpportunityName(npe03__Recurring_Donation__c rd, Date closeDate) {
        return rd.npe03__Donor_Name__c + ' ' +
            (rd.npe03__Amount__c != null ? rd.npe03__Amount__c.format() : '0') + ' ' +
            (closeDate != null ? closeDate.format() : '') + ' ' +
            UTIL_Describe.getObjectLabel('npe03__Recurring_Donation__c');
    }

    /***
    * @description Update payment method on the payment records for the created opportunities.
    * @param oppIds set of opportnity Ids
    * @param rdPaymentMethods is the map of Recurrding donation Ids with Payment method.
    */
    private void updatePaymentRecords(Set<Id> oppIds, Map<Id,String> rdPaymentMethods) {

        List<npe01__OppPayment__c> paymentForUpdates = new List <npe01__OppPayment__c> ();

        List<npe01__OppPayment__c> paymentRecords = new List <npe01__OppPayment__c> ([
            SELECT Id,npe01__Payment_Method__c,npe01__Payment_Date__c, npe01__Opportunity__c,
            npe01__Opportunity__r.npe03__Recurring_Donation__c
            FROM npe01__OppPayment__c
            WHERE npe01__Opportunity__c IN :oppIds
        ]);

        for (npe01__OppPayment__c payment : paymentRecords) {
            String rdPaymentMethod = rdPaymentMethods.get(payment.npe01__Opportunity__r.npe03__Recurring_Donation__c);

            if (String.isBlank(rdPaymentMethod)) {
                continue;
            }
            payment.npe01__Payment_Method__c = rdPaymentMethod;
            paymentForUpdates.add(payment);
        }

        Database.SaveResult[] saveResults = Database.update(paymentForUpdates, false);

    }

     /***
    * @description insert opportunities for the specified recurring donations.
    * @param oppsToInsert List of opportunities
    * @return the saveresults after the DML operation.
    */
    private static List<Database.SaveResult> insertOpportunities(List<Opportunity> oppsToInsert) {

        Set<Id> rdIds = new Set<Id>();
        Database.SaveResult[] saveResults;

        if (oppsToInsert.size() > 0) {
            for (Opportunity o : oppsToInsert) {
                rdIds.add(o.npe03__Recurring_Donation__c);
            }
            //Check if the Recurring donation is one or more to know if it gets saved from UI or from batch
            if (rdIds.size() == 1) {
                saveResults = Database.insert(oppsToInsert, true);

            } else {//otherwise, this is a bulk operation.
                saveResults = Database.insert(oppsToInsert, false);
            }
        }
        return saveResults;
    }
}