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
public with sharing class RD2_CreateOpportunityService {

    public static final String CREDITCARD = 'Credit Card';
    public static final String ACH = 'ACH';

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
        Database.SaveResult[] lsr;
        List<Database.SaveResult> badSRs = new List<Database.SaveResult>();
        List<Opportunity> badOpps = new List<Opportunity>();

        for (npe03__Recurring_Donation__c r : rdsWithCloseDates.keyset()) {
            if (r.npe03__Contact__c != null) {
                contactIds.add(r.npe03__Contact__c);
            }
            rdPaymentMethod.put(r.Id,r.PaymentMethod__c);

        }
        //Create a Map of Contact Ids and Contact Records
        if (contactIds.size() > 0) {
            contactMap = new Map<Id,Contact>([
              SELECT Id, AccountId
              FROM Contact
              WHERE Id IN :contactIds
              AND AccountId != null
            ]);
        }

        opportunityInserts = getInstallmentOpportunities(rdsWithCloseDates, contactMap);

        if (opportunityInserts.size() > 0) {
            Set<Id> RDID = new Set<Id>();
            for (Opportunity o : opportunityInserts) {
                RDID.add(o.npe03__Recurring_Donation__c);
            }
            //Check if the Recurring donation is one or more to know if it gets saved from UI or from batch
            if (RDID.size() == 1) {
                lsr = Database.insert(opportunityInserts, true);

            } else {//otherwise, this is a bulk operation.
                lsr = Database.insert(opportunityInserts, false);
            }
            for (Database.SaveResult s : lsr) {
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
        System.debug('IDS:' + createdOppIds);
        System.debug('Payment method:' + rdPaymentMethod);


        updatePaymentRecordOnCreatedOpp(createdOppIds, rdPaymentMethod);
    }

    private List<Opportunity> getInstallmentOpportunities(Map<npe03__Recurring_Donation__c, List<Date>> rdsWithCloseDates, Map<Id,Contact> contactMap) {

        List<Opportunity> opportunityInserts = new List<Opportunity>();
        Integer i = 0;
        npe03__Recurring_Donations_Settings__c rds = UTIL_CustomSettingsFacade.getRecurringDonationsSettings();
        System.debug('Here are the settings value:' + rds.InstallmentOppStageName__c );
        System.debug('What are keys:' + rdsWithCloseDates.keySet());

        List<npe03__Recurring_Donation__c> rd = new List<npe03__Recurring_Donation__c>([
            SELECT Id, Name, npe03__Donor_Name__c, npe03__Amount__c, npe03__Organization__c,
            npe03__Contact__c, npe03__Recurring_Donation_Campaign__c
            FROM
            npe03__Recurring_Donation__c
            WHERE id in :rdsWithCloseDates.keySet()
        ]);
        for (npe03__Recurring_Donation__c r : rd) {

            for(;i< rdsWithCloseDates.get(r).size();i++) {
                Opportunity opp = new Opportunity();
                System.debug('Name in RD:'+ r.npe03__Donor_Name__c);
                opp.Name = r.npe03__Donor_Name__c + ' ' + r.npe03__Amount__c + ' ' + rdsWithCloseDates.get(r)[i] + ' Recurring Donation';
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
            System.debug('RD id here:' + OppIdRdId.get(payment.npe01__Opportunity__c));
            System.debug('Payment method--' + rdPayment.get(OppIdRdId.get(payment.npe01__Opportunity__c)));
            if (String.IsBlank(rdPayment.get(OppIdRdId.get(payment.npe01__Opportunity__c)))) {
              return;
            }
            payment.npe01__Payment_Method__c = rdPayment.get(OppIdRdId.get(payment.npe01__Opportunity__c));
            paymentForUpdates.add(payment);
        }

        Database.SaveResult[] lsr = Database.update(paymentForUpdates, false);

    }
}