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
* @description Recurring Donations Validation Service tests
*
*/
@isTest(IsParallel=true)
private with sharing class RD2_ValidationService_TEST {

    /***
    * @description Verifies if it displays error message when there is no account and contact
    */
    @isTest
    private static void shouldFailWhenNoDonorIsSpecified() {
        String errMessage = '';
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .build();

        try {
            insert rd;
        } catch (Exception e) {
            errMessage = e.getMessage();
        }
        System.assert(errMessage.contains(System.Label.RD_DonorIsRequired));

    }

    /***
    * @description Verifies if it displays error message when there is no contact for Household account
    */
    @isTest
    private static void shouldFailWhenNoContactIsSpecifiedForHHAccount() {
        String errMessage = '';
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Account acc = getHHAccount();
        insert acc;

        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withAccount(acc.Id)
            .build();
        try {
            insert rd;
        } catch (Exception e) {
            errMessage = e.getMessage();
        }

        System.assert(errMessage.contains(System.Label.RD_ContactMustBelongToAccount));

    }

    /***
    * @description Verifies if it displays error message when the contact is not associated with the
        selected HouseHold account. It also verifies if no error message when the contact is associated
        with the account in this method.
    */
    @isTest
    private static void shouldFailWhenContactDoesNotBelongToHHAccount() {
        String errMessage = '';
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Account acc = getHHAccount();
        insert acc;

        Contact con = UTIL_UnitTestData_TEST.getContact();
        insert con;

        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withAccount(acc.Id)
            .withContact(con.Id)
            .build();
        try {
            insert rd;
        } catch (Exception e) {
            errMessage = e.getMessage();
        }
        System.assert(errMessage.contains(System.Label.RD_ContactMustBelongToAccount));
    }

    /**
    * @description Should fail when there is an invalid contact for the account in the
        Recurring Donations list.
    */
    @isTest
    private static void shouldFailOnlyInvalidRecurringDonations() {

        String errMessage ='';
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        List<Contact> contacts = new List<Contact>{
            UTIL_UnitTestData_TEST.getContact(),
            UTIL_UnitTestData_TEST.getContact()
        };
        insert contacts;

        contacts = [SELECT AccountId FROM Contact WHERE Id IN :contacts];

        List<npe03__Recurring_Donation__c> rds = new TEST_RecurringDonationBuilder()
        .withAccount(contacts[0].AccountId)//only RD for one Contact will be valid
        .withAmount(100)
        .build(contacts);

        List<Database.SaveResult> results = Database.insert(rds, false);
        ERR_Handler.Errors errors = ERR_Handler.getErrors(results, rds);
        System.assertEquals(true, errors.errorsExist);
        System.assertEquals(1, errors.errorRecords.size());

    }

    /***
    * @description Verifies if it creates Recurring donations for a single household contact
        without an account.
    */
    @isTest
    private static void shouldCreateRDSForHouseholdContact() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Contact con = UTIL_UnitTestData_TEST.getContact();
        insert con;

        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withContact(con.Id)
            .build();

        insert rd;

        System.assert([select id from npe03__Recurring_Donation__c].size()>0 );

    }

    /***
    * @description Should create Recurring donations for organization accounts without validaiton errors
    */
    @isTest
    private static void shouldCreateRDSForOrganizationAccounts() {

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        Account account = new Account(Name = 'TEST_ACCOUNT');
        insert account;

        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withAccount(account.Id)
            .withAmount(100)
            .build();

        insert rd;

        System.assert([select id from npe03__Recurring_Donation__c].size()>0 );
    }

    /***
    * @description Builds an HouseHold Account
    * @return HouseHold Account record
    */
    private static Account getHHAccount() {
        return new Account(
            Name = 'HH Account',
            npe01__SYSTEM_AccountType__c = CAO_Constants.HH_ACCOUNT_TYPE,
            npe01__SYSTEMIsIndividual__c = true

        );
    }

}