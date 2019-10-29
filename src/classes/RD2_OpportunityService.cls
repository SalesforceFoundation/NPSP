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

    /***
    * @description inserts one or more Opportunity records for a specified set of Recurring Donations
    * @param rdsWithCloseDates the Map of Recurring Donations with close dates
    */
    public void createInstallmentOpportunities(Map<npe03__Recurring_Donation__c, List<Date>> rdsWithCloseDates) {

        List<Opportunity> opportunityInserts;
        Set<Id> createdOppIds = new Set<Id>();
        Integer j = 0;
        //Create a list of ContactIds and contactmap used in these RecurringDonations
        List<Id> contactIds = new List<Id>();
        Map<Id,Contact> contactMap;
        Map<Id,String> rdPaymentMethod = new Map<Id,String>();
        List<Database.SaveResult> badSRs = new List<Database.SaveResult>();
        List<Opportunity> badOpps = new List<Opportunity>();

        for (npe03__Recurring_Donation__c r : rdsWithCloseDates.keyset()) {
            if (r.npe03__Contact__c != null) {
                contactIds.add(r.npe03__Contact__c);
            }
            rdPaymentMethod.put(r.Id,r.PaymentMethod__c);

        }
        contactMap = getContactMap(contactIds);

        opportunityInserts = getInstallmentOpportunities(rdsWithCloseDates, contactMap);

        if (opportunityInserts.size() > 0) {
            for (Database.SaveResult s : insertOpportunities(opportunityInserts)) {
                if (s.isSuccess() == true) {
                    //get all the new OppIds into a list
                    createdOppIds.add(s.getId());

                } else {//handle errors on insert
                    badSRs.add(s);
                    badOpps.add(opportunityInserts[j]);
                }
                j++;
            }
            //Confirm if the error handling is needed due to bulk operations
            if (!badSRs.isEmpty()) {
               ERR_Handler.Errors errors = ERR_Handler.getErrors(badSRs, badOpps);
               ERR_Handler.processErrors(errors.errorRecords, ERR_Handler_API.Context.RD.name());
            }
        }
        updatePaymentRecordOnCreatedOpp(createdOppIds, rdPaymentMethod);
    }

    /***
    * @description Gets one or more Opportunity records for a specified set of Recurring Donations with close dates
    * @param rdsWithCloseDates the Map of Recurring Donations with close dates
    * @param contactMap the Map of contact with account ids.
    * @return the list of Opportunities to be created.
    */
    private List<Opportunity> getInstallmentOpportunities(Map<npe03__Recurring_Donation__c, List<Date>> rdsWithCloseDates, Map<Id,Contact> contactMap) {

        List<Opportunity> opportunityInserts = new List<Opportunity>();
        Integer i = 0;
        npe03__Recurring_Donations_Settings__c rds = UTIL_CustomSettingsFacade.getRecurringDonationsSettings();

        for (npe03__Recurring_Donation__c r : rdsWithCloseDates.keySet()) {

            for(;i< rdsWithCloseDates.get(r).size();i++) {
                Opportunity opp = new Opportunity();
                opp.Name = r.npe03__Donor_Name__c + ' ' + r.npe03__Amount__c.format() + ' ' + rdsWithCloseDates.get(r)[i].format() + ' ' + System.Label.stgNavRecurringDonations;

                if ( r.npe03__Organization__c != null && String.isBlank(r.npe03__Contact__c)) {
                    opp.AccountId = r.npe03__Organization__c;

                } else if (contactMap.containsKey(r.npe03__Contact__c)) {
                    Contact c = contactMap.get(r.npe03__Contact__c);
                    opp.AccountId = c.AccountId;
                    opp.Primary_Contact__c = c.id;
                }
                opp.CloseDate = rdsWithCloseDates.get(r)[i];
                opp.StageName = rds.InstallmentOppStageName__c ;
                opp.Amount = r.npe03__Amount__c;
                opp.npe03__Recurring_Donation__c = r.Id;
                if (r.npe03__Recurring_Donation_Campaign__c != null && rds.npe03__Add_Campaign_to_All_Opportunites__c ) {
                    opp.CampaignId = r.npe03__Recurring_Donation_Campaign__c;
                }
                opportunityInserts.add(opp);
            }
          }

        return opportunityInserts;

    }

     /***
    * @description Update payment method on the payment records for the created opportunities.
    * @param oppIds set of opportnity Ids
    * @param rdPayment is the map of Recurrding donation Ids with Payment method.
    */
    private void updatePaymentRecordOnCreatedOpp(Set<Id> oppIds, Map<Id,String> rdPayment) {

        List<npe01__OppPayment__c> paymentForUpdates = new List <npe01__OppPayment__c> ();

        List<npe01__OppPayment__c> paymentRecForOpps = new List <npe01__OppPayment__c> ([
            SELECT Id,npe01__Payment_Method__c,npe01__Payment_Date__c, npe01__Opportunity__c
            FROM npe01__OppPayment__c
            WHERE npe01__Opportunity__c IN :oppIds
            ]);

        Map<Id,Id> OppIdRdId = new Map<Id,Id>();

        List<Opportunity> oppList = new List<Opportunity> ([
            SELECT ID,npe03__Recurring_Donation__c
            FROM Opportunity
            WHERE Id in :oppIds
            ]);

        for (Opportunity oppty: oppList) {
            OppIdRdId.put(oppty.id,oppty.npe03__Recurring_Donation__c);
        }
        for (npe01__OppPayment__c payment : paymentRecForOpps) {
            if (String.IsBlank(rdPayment.get(OppIdRdId.get(payment.npe01__Opportunity__c)))) {
              continue;
            }
            payment.npe01__Payment_Method__c = rdPayment.get(OppIdRdId.get(payment.npe01__Opportunity__c));
            paymentForUpdates.add(payment);
        }

        Database.SaveResult[] lsr = Database.update(paymentForUpdates, false);

    }

    /***
    * @description Get contact maps for the provided list of contacts
    * @param List of contact ids
    * @return Map<Id, Contact> containing the AccountId to Contact.
    */
    private Map<Id, Contact> getContactMap (List<Id> contactIds) {
        Map<Id,Contact> contactMap;

        if (contactIds.size() > 0) {
            contactMap = new Map<Id,Contact>([
              SELECT Id, AccountId
              FROM Contact
              WHERE Id IN :contactIds
              AND AccountId != null
            ]);

        }

        return contactMap;
    }

     /***
    * @description insert opportunities for the specified recurring donations.
    * @param opportunityInserts List of opportunities
    * @return the saveresults after the DML operation.
    */
    private static List<Database.SaveResult> insertOpportunities(List<Opportunity> opportunityInserts) {

        Set<Id> RDID = new Set<Id>();
        Database.SaveResult[] lsr;

        if (opportunityInserts.size() > 0) {
            for (Opportunity o : opportunityInserts) {
                RDID.add(o.npe03__Recurring_Donation__c);
            }
            //Check if the Recurring donation is one or more to know if it gets saved from UI or from batch
            if (RDID.size() == 1) {
                lsr = Database.insert(opportunityInserts, true);

            } else {//otherwise, this is a bulk operation.
                lsr = Database.insert(opportunityInserts, false);
            }
        }
        return lsr;
    }
}