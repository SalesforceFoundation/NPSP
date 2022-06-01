/*
    Copyright (c) 2022 Salesforce.org
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
* @date 2022
* @description Recurring Donations Service class.
*/
public with sharing class RD2_ERecurringDonationsService {
    
    private final String MONTHLY = 'Monthly';
    private final String WEEKLY = 'Weekly';
    private final String YEARLY = 'Yearly';

    @TestVisible
    private UTIL_Permissions permissions {
        get {
            if(permissions == null) {
                permissions = UTIL_Permissions.getInstance();
            }
            return permissions;
        }
        set;
    }
    
    @TestVisible
    private RD2_ERecurringDonationsSelector selector {
        get {
            if(selector == null) {
                selector = new RD2_ERecurringDonationsSelector();
            }
            return selector;
        }
        set { 
            this.selector = value;
        }
    }
    
    /** 
    * @author Salesforce.org
    * @date 2022
    * @description method to check recurring donation permissions.
    * @return Boolean returns access to Recurring Donations.
    */
    private Boolean hasAccessToRecurringDonation() {
        return permissions.canRead(npe03__Recurring_Donation__c.SObjectType, new Set<SObjectField>{
            npe03__Recurring_Donation__c.npe03__Amount__c,
            npe03__Recurring_Donation__c.npe03__Installment_Period__c,
            npe03__Recurring_Donation__c.InstallmentFrequency__c,
            npe03__Recurring_Donation__c.Day_of_Month__c
        });
    }

    /** 
    * @author Salesforce.org
    * @date 2022
    * @description method to return Recurring Donation list.
    * @return List<RD2_ERecurringDonationsController.RecurringDonationView> returns processed Recurring Donations.
    */
    public List<RD2_ERecurringDonationsController.RecurringDonationView> getData() {
        if(hasAccessToRecurringDonation()) {
            List<RD2_ERecurringDonationsController.RecurringDonationView> recurringDonations = new List<RD2_ERecurringDonationsController.RecurringDonationView>();
            for(npe03__Recurring_Donation__c recDonation : selector.getRecurringDonations()) {
                recurringDonations.add( new RD2_ERecurringDonationsController.RecurringDonationView( recDonation,
                                                                                            getFrequency(recDonation),
                                                                                            ''));

            }

            return recurringDonations;
        } else {
            throw new UTIL_Permissions.InsufficientPermissionException(Label.commonInsufficientPermissions);
        }
    }

    /** 
    * @author Salesforce.org
    * @date 2022
    * @description process Recurring Donation record to build the frequency string.
    * @return String returns the frequency string.
    */
    private String getFrequency(npe03__Recurring_Donation__c recurringDonation) {

        String frequency = '';

        Map<String, String> mapDayOfMonth = new Map<String, String>();
        for(Schema.PicklistEntry ple : Schema.SObjectType.npe03__Recurring_Donation__c.fields.Day_of_Month__c.getPicklistValues()){
            mapDayOfMonth.put(ple.getValue(), ple.getLabel());
        }

        if(recurringDonation.InstallmentFrequency__c == 1) {
            if(recurringDonation.npe03__Installment_Period__c.isAlpha()) {
                if(recurringDonation.npe03__Installment_Period__c == 'Monthly') {
                    frequency = String.format(System.Label.frequencyPeriodOnTheDayOfTheMonth, new List<String>{recurringDonation.npe03__Installment_Period__c, mapDayOfMonth.get(recurringDonation.Day_of_Month__c).ToLowerCase()});
                } else {
                    frequency = recurringDonation.npe03__Installment_Period__c;
                }
            } else {
                frequency = String.format(System.Label.frequencyOnThePeriod, new List<String>{recurringDonation.npe03__Installment_Period__c});
            }
        } else {
            if(recurringDonation.npe03__Installment_Period__c == MONTHLY) {
                frequency = String.format(System.Label.frequencyMonthly, new List<String>{String.valueOf(recurringDonation.InstallmentFrequency__c), mapDayOfMonth.get(recurringDonation.Day_of_Month__c).ToLowerCase()});
            } else if(recurringDonation.npe03__Installment_Period__c == YEARLY) {
                frequency = String.format(System.Label.frequencyYearly, new List<String>{String.valueOf(recurringDonation.InstallmentFrequency__c)});
            } else if(recurringDonation.npe03__Installment_Period__c == WEEKLY) {
                frequency = String.format(System.Label.frequencyWeekly, new List<String>{String.valueOf(recurringDonation.InstallmentFrequency__c)});
            }
        }

        if(frequency.right(1).isNumeric()) {
            switch on frequency.right(1) {
                when '1' {
                    frequency += System.Label.firstOrdinalNumber;
                }
                when '2' {
                    frequency += System.Label.secondOrdinalNumber;
                }
                when '3' {
                    frequency += System.Label.thirdOrdinalNumber;
                }
                when else {
                    frequency += System.Label.otherOrdinalNumber;
                }
            }
        }
        
        return frequency;
    }
}