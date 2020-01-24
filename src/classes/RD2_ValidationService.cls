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
* @description Recurring Donations Validation Service
*
*/
public with sharing class RD2_ValidationService {
    /**
    * @description New rds during the dml process
    */
    private List<npe03__Recurring_Donation__c> rds = new List<npe03__Recurring_Donation__c>();

    /**
    * @description Old rds during the dml process. oldRds should have the same size and same index as the rds
    */
    private List<npe03__Recurring_Donation__c> oldRds = new List<npe03__Recurring_Donation__c>();

    /**
    * @description Accounts on the Rds
    */
    private Map<Id,Account> accountsById {
        get {
            if (accountsById == null) {
                accountsById = getaccountsById();
            }
            return accountsById;
        } set;
    }

    private Set<Id> adjustableRdIds {
        get {
            if (adjustableRdIds == null) {
                adjustableRdIds = getRdWithoutClosedOpp();
            }
            return adjustableRdIds;
        }
        set;
    }

    /**
    * @description Constructor for the RD2_ValidationService class
    * @param rds - New rds that will be validated
    * @param oldRds - Old rds that will be compared to
    */
    public RD2_ValidationService(List<npe03__Recurring_Donation__c> rds) {
        this.rds = rds;
    }

    public RD2_ValidationService withOldRecurringDonations(List<npe03__Recurring_Donation__c> oldRds) {
        this.oldRds = oldRds;
        return this;
    }

    /**
    * @description Validate RD data on before insert
    * @param rds - The Reucrring Donations to validate
    */
    public void validate() {
        for (npe03__Recurring_Donation__c rd : rds) {
            validateActiveRecurringDonation(rd);
            validateDonor(rd, accountsById.get(rd.npe03__Organization__c));
        }
    }

    /**
    * @description Validate RD data on before update
    * @param rds - The Reucrring Donations to validate
    * @param oldRds - The old list of Recurring Donations
    */
    public void validateOnChange() {
         for (Integer i = 0; i < rds.size(); i++) {
            npe03__Recurring_Donation__c rd = rds[i];
            npe03__Recurring_Donation__c oldRd = oldRds[i];

            validateActiveRecurringDonation(rd);
            validateDonor(rd, accountsById.get(rd.npe03__Organization__c));
            validateDonorChange(rd, oldRd);
        }
        
    }

    /**
    * @description Validate when contact or account is changed on update of rds
    * @param rds - The Reucrring Donations to validate
    * @param oldRds - The old list of Recurring Donations
    */
    private void validateDonorChange(npe03__Recurring_Donation__c rd, npe03__Recurring_Donation__c oldRd) {
        if (rd.npe03__Organization__c == oldRd.npe03__Organization__c
            && rd.npe03__Contact__c == oldRd.npe03__Contact__c) {
            return;
        }

        if (adjustableRdIds.contains(rd.Id)
            || isOrganizationChange(accountsById.get(rd.npe03__Organization__c), accountsById.get(oldRd.npe03__Organization__c))
        ) {
            return;
        }
        
        rd.addError(System.Label.RD2_CannotChangeContactOnRDWithClosedOpp);
        
    }

    /***
    * @description Return true when both new and old account on the RD are organization accounts.
    * @param newAcct - Account on the DML new RD
    * @param oldAcct - Acocunt on the DML old RD
    * @return - True when both new and old account are organization accounts
    */
    private Boolean isOrganizationChange(Account newAcct, Account oldAcct) {
        return 
            newAcct != null
            && oldAcct != null
            && newAcct.npe01__SYSTEMIsIndividual__c == false
            && oldAcct.npe01__SYSTEMIsIndividual__c == false;
    }

    /***
    * @description Validates missing account or contact data on Recurring Donation
    * @param rd - The Recurring Donation to validate
    * @param acct - The associated account for the Recurring Donation
    */
    private void validateDonor(npe03__Recurring_Donation__c rd, Account acct) {
        //either Account or Contact must be specified
        if (rd.npe03__Organization__c == null && rd.npe03__Contact__c == null) {
            rd.addError(System.Label.RD_DonorIsRequired);
            return;
        }

        //no further check is required if the Contact is specified only or the Account is an Organization
        if (acct == null || acct.npe01__SYSTEMIsIndividual__c != true) {
            return;
        }

        if (rd.npe03__Contact__c == null) {
            rd.addError(System.Label.RD_ContactMustBelongToAccount);
        } else if (!UTIL_SObject.extractIds(acct.Contacts).contains(rd.npe03__Contact__c)) {
            rd.addError(System.Label.RD_ContactMustBelongToAccount);
        }

    }

    /***
    * @description Validates installment data on Recurring Donation
    * @param rd - The Recurring Donation to validate
    */
    private void validateActiveRecurringDonation(npe03__Recurring_Donation__c rd) {
        if (rd.Status__c == RD2_Constants.STATUS_CLOSED) {
            return;
        }
        if (rd.npe03__Amount__c == null || rd.npe03__Amount__c == 0 || rd.npe03__Amount__c < 0) {
            rd.addError(System.Label.RD2_AmountMustBeValid);
        }

        if (!RD2_Constants.allInstallmentPeriods.contains(rd.npe03__Installment_Period__c)) {
            rd.addError(
                String.format(
                    System.Label.RD2_InstallmentPeriodMustBeValid,
                    new String[]{ rd.npe03__Installment_Period__c })
            );
        }

        validateDayOfMonth(rd);
    }

    /***
    * @description Validates Day of Month on Recurring Donation
    * @param rd - The Recurring Donation to validate
    */
    private void validateDayOfMonth(npe03__Recurring_Donation__c rd) {
        if (rd.npe03__Installment_Period__c != RD2_Constants.INSTALLMENT_PERIOD_MONTHLY) {
            return;
        }

        if (String.IsBlank(rd.Day_of_Month__c)) {
            rd.addError(System.Label.RD2_DayOfMonthIsRequiredForMonthlyInstallment);
            return;
        }

        if (rd.Day_of_Month__c != RD2_Constants.DAY_OF_MONTH_LAST_DAY) {
            Integer dayOfMonth;
            try {
                dayOfMonth = Integer.valueOf(rd.Day_of_Month__c);

            } catch (Exception e) {
            }

            Boolean isValid = dayOfMonth > 0 && dayOfMonth < 29;

            if (!isValid) {
                rd.addError(
                    String.format(
                        System.Label.RD2_DayOfMonthMustBeValid,
                        new String[]{ rd.Day_of_Month__c})
                );
            }
        }
    }

    /**
    * @description - Get account map on the RDs from both new and old recurring donation context
    */
    private Map<Id, account> getaccountsById() {
        Set<Id> accountIds = UTIL_SObject.extractId(rds, npe03__Recurring_Donation__c.npe03__Organization__c);
        Set<Id> contactIds = UTIL_SObject.extractId(rds, npe03__Recurring_Donation__c.npe03__Contact__c);

        accountIds.addAll(UTIL_SObject.extractId(oldRds, npe03__Recurring_Donation__c.npe03__Organization__c));
        contactIds.addAll(UTIL_SObject.extractId(oldRds, npe03__Recurring_Donation__c.npe03__Contact__c)); 

        accountIds.remove(null);
        contactIds.remove(null);

        return new Map<Id,Account>([
            SELECT Id, npe01__SYSTEMIsIndividual__c,
            (
                SELECT Id
                FROM Contacts
                WHERE Id IN :contactIds
            )
            FROM Account
            WHERE Id IN :accountIds
        ]);
    }

    /***
    * @description Get a Id group with RD that has no closed opportunity on it
    * @return - A set of RD Ids that does not have any closed opp on it
    */
    private Set<Id> getRdWithoutClosedOpp() {
        Set<Id> rdIds = new Set<Id>();

        for (npe03__Recurring_Donation__c rd : [
            SELECT (
                SELECT Id 
                FROM npe03__Donations__r
                WHERE IsClosed = true
                LIMIT 1
                )
            FROM npe03__Recurring_Donation__c
            WHERE Id IN : rds
        ]) {
            if (rd.npe03__Donations__r.isEmpty()) {
                rdIds.add(rd.Id);
            }
        }
        
        return rdIds;
    }
}