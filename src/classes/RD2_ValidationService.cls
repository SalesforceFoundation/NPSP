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

    /***
    * @description Validates missing data on Recurring Donation
    * @param rds the Recurring Donation to validate
    */
    public void validate(List<npe03__Recurring_Donation__c> rds) {

        Set<Id> accountIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();

        for (npe03__Recurring_Donation__c rd : rds) {
            if (rd.npe03__Organization__c != null) {
                accountIds.add(rd.npe03__Organization__c);
                contactIds.add(rd.npe03__Contact__c);
            }
        }
        accountIds.remove(null);
        contactIds.remove(null);

        Map<Id,Account> accountsById = new Map<Id,Account>([
            SELECT Id, npe01__SYSTEMIsIndividual__c,
            (
                SELECT Id
                FROM Contacts
                WHERE Id IN :contactIds
            )
            FROM Account
            WHERE Id IN :accountIds
            ]);

        for (npe03__Recurring_Donation__c rd : rds) {
            validateInstallmentFields(rd);
            validateAccountAndContact(rd, accountsById.get(rd.npe03__Organization__c));

        }
    }

    /***
    * @description Validates missing account or contact data on Recurring Donation
    * @param rd the Recurring Donation to validate
    * @param acct is the associated account for the Recurring Donation
    */
    private void validateAccountAndContact(npe03__Recurring_Donation__c rd, Account acct) {
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
        } else if (!extractIds(acct.Contacts).contains(rd.npe03__Contact__c)) {
            rd.addError(System.Label.RD_ContactMustBelongToAccount);
        }

    }

    /***
    * @description Validates installment data on Recurring Donation
    * @param rd the Recurring Donation to validate
    */
    private void validateInstallmentFields(npe03__Recurring_Donation__c rd) {
        if (rd.Status__c == RD2_Constants.STATUS_CLOSED) {
            return;
        }
        if (rd.npe03__Amount__c == null || rd.npe03__Amount__c == 0 || rd.npe03__Amount__c < 0) {
            rd.addError(System.Label.RD2_CheckValidAmountOnRD);
        }

        if (rd.npe03__Installment_Period__c == RD2_Constants.INSTALLMENT_PERIOD_MONTHLY && String.isBlank(rd.Day_of_Month__c) ) {
            rd.addError(System.Label.RD2_DayOfMonthIsReqForMonthlyInstallments);
        }
        if (!isValidInstallmentPeriod(rd)){
            rd.addError(
                String.format(
                    System.Label.RD2_CheckValidInstallmentPeriod,
                    new String[]{ rd.npe03__Installment_Period__c })
            );
        }
        if (rd.npe03__Installment_Period__c == RD2_Constants.INSTALLMENT_PERIOD_MONTHLY && !isValidDayOfMonth(rd)){
            rd.addError(
                String.format(
                    System.Label.RD2_CheckValidDayOfMonth,
                    new String[]{ rd.Day_of_Month__c})
            );
        }

    }

    /*******************************************************************************************************
    * @description gets the valid Installment period from hard-coded supported values in RD_Constants
    */
    private static List<String> getValidInstallmentPeriod() {
        List<String> InstallmentPeriod = new List <String>();
        InstallmentPeriod.add(RD2_Constants.INSTALLMENT_PERIOD_DAILY);
        InstallmentPeriod.add(RD2_Constants.INSTALLMENT_PERIOD_WEEKLY);
        InstallmentPeriod.add(RD2_Constants.INSTALLMENT_PERIOD_MONTHLY);
        InstallmentPeriod.add(RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH);
        InstallmentPeriod.add(RD2_Constants.INSTALLMENT_PERIOD_YEARLY);
        return InstallmentPeriod;
    }

    /*******************************************************************************************************
    * @description gets the valid list of Dayofmonth field in Recurring Donation
    */
    private static List<String> getValidDayOfMonth() {
        List<String> DayOfMonth = new List <String>();

        for (Integer day = 1; day < 29; day++) {
            DayOfMonth.add(String.valueOf(day));
        }
        DayOfMonth.add('Last_Day');

        System.debug('Values of Day of month are:' + DayOfMonth);
        return DayOfMonth;

    }

    /*******************************************************************************************************
    * @description Verify if installmentperiod is valid in the Recurring Donation
    */
    private static Boolean isValidInstallmentPeriod(npe03__Recurring_Donation__c rd) {
        List<String> validInstallmentPeriod = getValidInstallmentPeriod();
        if  (validInstallmentPeriod.contains(rd.npe03__Installment_Period__c)) {
            return true;
        }
        return false;
    }

    /*******************************************************************************************************
    * @description Verify if DayOfMonth is valid in the Recurring Donation
    */
    private static Boolean isValidDayOfMonth(npe03__Recurring_Donation__c rd) {
        List<String> validDayOfMonth = getValidDayOfMonth();
        if  (validDayOfMonth.contains(rd.Day_of_Month__c)) {
            return true;
        }
        return false;
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