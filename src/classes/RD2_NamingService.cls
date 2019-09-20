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
* @description Recurring Donations Naming Service
*
*/
public with sharing class RD2_NamingService {

    private static final String CURRENCY_ISO_CODE_FIELD = UTIL_Currency.CURRENCY_ISO_CODE_FIELD;
    public static final Integer MAX_NAME_LENGTH = 80;

    /***
    * @description Checks if the Recurring Donation automatic naming is turned on
    */
    @TestVisible
    private static Boolean isAutomaticNamingEnabled {
        get {
            if (isAutomaticNamingEnabled == null) {
                isAutomaticNamingEnabled = UTIL_CustomSettingsFacade.getRecurringDonationsSettings().EnableAutomaticNaming__c == true;
            }
            return isAutomaticNamingEnabled;
        }
        set;
    }

    /***
    * @description Returns Donor (Account/Contact) records
    */
    @TestVisible
    private RD2_Donor.IGateway donorGateway {
        get {
            if (donorGateway == null) {
                donorGateway = new RD2_Donor.Gateway();
            }
            return donorGateway;
        }
        set;
    }

    /***
    * @description Returns Recurring Donation records
    */
    @TestVisible
    private RD2_RecurringDonationsGateway rdGateway {
        get {
            if (rdGateway == null) {
                rdGateway = new RD2_RecurringDonationsGateway();
            }
            return rdGateway;
        }
        set;
    }

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
    * @description Currency symbol for the user default currency
    */
    private String userDefaultCurrencySymbol {
        get {
            if (userDefaultCurrencySymbol == null) {
                userDefaultCurrencySymbol = UTIL_Currency.getInstance().getCurrencySymbol(UserInfo.getDefaultCurrency());
            }
            return userDefaultCurrencySymbol;
        }
        set;
    }    

    /***
    * @description Autogenerates recurring donation names 
    * @param rds Trigger.new records
    * @param oldRds Trigger.old records
    * @param triggerAction BeforeInsert, AfterInsert, etc.
    */
    public void autogenerateNames(List<SObject> rds, List<SObject> oldRds, TDTM_Runnable.Action triggerAction) {

        if (triggerAction == TDTM_Runnable.Action.BeforeInsert) {
            autogenerateNames(rds);
            
        } else if (triggerAction == TDTM_Runnable.Action.BeforeUpdate) {
            autogenerateNamesOnChange(rds, oldRds);
        }
    }

    /***
    * @description Autogenerates recurring donation names if Name construct fields have changed
    */
    public void autogenerateNamesOnChange(List<npe03__Recurring_Donation__c> rds, List<npe03__Recurring_Donation__c> oldRds) {
        if (!isAutomaticNamingEnabled) {
            return;
        }

        Map<Id, npe03__Recurring_Donation__c> oldRdById = new Map<Id, npe03__Recurring_Donation__c>(oldRds);
        List<npe03__Recurring_Donation__c> changedRds = new List<npe03__Recurring_Donation__c>();

        for (npe03__Recurring_Donation__c rd : rds) {
            if (hasChanged(rd, oldRdById.get(rd.Id))) {
                changedRds.add(rd);
            }
        }

        autogenerateNames(changedRds);
    }

    /***
    * @description Determines if Name construct fields have changed
    */
    @TestVisible
    private Boolean hasChanged(npe03__Recurring_Donation__c rd, npe03__Recurring_Donation__c oldRd) {
        Boolean hasChanged = rd.npe03__Organization__c != oldRd.npe03__Organization__c
            || rd.npe03__Contact__c != oldRd.npe03__Contact__c
            || rd.npe03__Amount__c != oldRd.npe03__Amount__c
            || rd.Name == System.Label.npo02.NameReplacementText;

        if (!hasChanged && isMultiCurrencyEnabled) {
            hasChanged = (String) rd.get(CURRENCY_ISO_CODE_FIELD) != (String) oldRd.get(CURRENCY_ISO_CODE_FIELD);
        }

        return hasChanged;
    }

    /***
    * @description Autogenerates recurring donation names for all specified records
    */
    public void autogenerateNames(List<npe03__Recurring_Donation__c> rds) {
        if (!isAutomaticNamingEnabled || rds == null || rds.isEmpty()) {
            return;
        }

        Map<Id, RD2_Donor.Record> donorById = donorGateway.getDonors(rds);

        for (npe03__Recurring_Donation__c rd : rds) {
            rd.Name = constructName(rd, donorById);
        }
    }   

    /***
    * @description Constructs recurring donation name
    * Name formatting: 
    *   If multi-currency, then "{!DonorName} {ISO Code} {!Amount} - Recurring".
    *   Otherwise, "{!DonorName} {User Default Currency Symbol}{!Amount} - Recurring".
    */
    private String constructName(npe03__Recurring_Donation__c rd,  Map<Id, RD2_Donor.Record> donorById) {
        RD2_Donor.Record donor = rd.npe03__Contact__c != null
            ? donorById.get(rd.npe03__Contact__c)
            : donorById.get(rd.npe03__Organization__c);

        String nameSuffix = ' ' + formatAmount(rd) + ' - ' + System.Label.RecurringDonationNameSuffix;

        String donorName = donor == null 
            ? '' 
            : donor.Name.abbreviate(MAX_NAME_LENGTH - nameSuffix.length());

        return donorName + nameSuffix;
    }

    /***
    * @description Formats amount used to construct the name
    */
    private String formatAmount(npe03__Recurring_Donation__c rd) {
        String formattedAmount = rd.npe03__Amount__c == null ? '' : rd.npe03__Amount__c.format();

        if (formattedAmount.endsWith('.00')) {
            formattedAmount = formattedAmount.removeEnd('.00');
        } else if (formattedAmount.endsWith('.0')) {
            formattedAmount = formattedAmount.removeEnd('.0');
        }

        if (isMultiCurrencyEnabled) {
            String code = (String) rd.get(CURRENCY_ISO_CODE_FIELD);

            if (String.isNotBlank(code)) {
                formattedAmount = code + ' ' + formattedAmount;
            }
        } else {
            formattedAmount = userDefaultCurrencySymbol + formattedAmount;
        }

        return formattedAmount;
    }
}