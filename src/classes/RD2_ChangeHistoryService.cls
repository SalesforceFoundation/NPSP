/*
    Copyright (c) 2021 Salesforce.org
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
* @date 2021
* @group Recurring Donations
* @description All services specific to Enhanced Recurring Donation Change History
*
*/
public without sharing class RD2_ChangeHistoryService {

    private List<RecurringDonationChangeHistory__c> changeHistoryList = 
        new List<RecurringDonationChangeHistory__c>();

    /***
    * @description Determines if Change History is enabled for the org
    */
    public Boolean isChangeHistoryEnabled {
        get {
            if (isChangeHistoryEnabled == null) {
                isChangeHistoryEnabled = new RD2_Settings().isChangeHistoryEnabled();
            }
            return isChangeHistoryEnabled;
        }
        set;
    }

    /**
     * @description Returns true if any of the key fields used to create Change History has been changed.
     * @param rd Changed Recurring Donation
     * @param oldRd Old Recurring Donation
     * @return Boolean
     */
    public void handleHistoryFieldChanged(npe03__Recurring_Donation__c rd, npe03__Recurring_Donation__c oldRd) {

        // TODO: Need a map of RD field name to CH field name
        // Use describes to get API names

        // household.put(UTIL_Namespace.StrTokenNSPrefix('Number_of_Household_Members__c')

        Boolean isChanged =
            rd.npe03__Amount__c != oldRd.npe03__Amount__c ||
            rd.npe03__Installment_Period__c != oldRd.npe03__Installment_Period__c ||
            rd.InstallmentFrequency__c != oldRd.InstallmentFrequency__c ||
            rd.Status__c != oldRd.Status__c ||
            rd.ClosedReason__c != oldRd.ClosedReason__c ||
            rd.PaymentMethod__c != oldRd.PaymentMethod__c ||
            rd.npe03__Recurring_Donation_Campaign__c != oldRd.npe03__Recurring_Donation_Campaign__c;

        System.debug(' *** isChanged:'); 
        System.debug(isChanged); 

        if(isChanged){
            changeHistoryList.add(returnChangeHistory(rd, oldRd));
        }

    }

    private RecurringDonationChangeHistory__c returnChangeHistory(npe03__Recurring_Donation__c rd, npe03__Recurring_Donation__c oldRd){

        // Loop over fields

        return new RecurringDonationChangeHistory__c(
            RecurringDonation__c = oldRd.Id,
            EffectiveDate__c = rd.StartDate__c
        );

    }

    public List<RecurringDonationChangeHistory__c> getChangeHistoryRecords(){
        return changeHistoryList;
    }

    // public void insertChangeHistoryRecords(){

    //     System.debug('changeHistoryList'); 
    //     System.debug(changeHistoryList); 

    //     if(changeHistoryList.size() > 0){
    //         insert changeHistoryList;
    //     }

    // }

}
