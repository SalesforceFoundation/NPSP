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
public with sharing class RD2_ValidationService_TEST {

    private static Account acc = getHHAccount();
    private static Contact conRecord = getContact();

    /***
    * @description Verifies if it displays error message when there is no account and contact
    */
    @isTest
    private static void shouldDisplayErrorMsgWhenNoAccountAndContact() {
        String errMessage = '';
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .build();

        try {
            insert rd;
        } catch (Exception e) {
            errMessage = e.getMessage();
        }
        System.assert(errMessage.contains(System.Label.RD_ValidateAccountAndContactMissing));

    }

    /***
    * @description Verifies if it displays error message when there is no contact for Household account
    */
    @isTest
    private static void shouldDisplayErrorMsgWhenNoContactForHHAccount() {
        String errMessage = '';
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        insert acc;

        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withAccount(acc.Id)
            .build();
        try {
            insert rd;
        } catch (Exception e) {
            errMessage = e.getMessage();
            System.debug('Error message is:'+ errMessage);
        }

        System.assert(errMessage.contains(System.Label.RD_ValidateContactMissingForAccount));

    }

    /***
    * @description Verifies if it displays error message when the contact is not associated with the
        selected HouseHold account.
    */
    @isTest
    private static void shouldDisplayErrorMsgWhenContactNotFoundInAccount() {
        String errMessage = '';
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();


        Contact con = UTIL_UnitTestData_TEST.getContact();
        insert con;
        System.debug('what is contact account id:' + con.accountid);
        insert conRecord;

        Account acc = [select id, npe01__SYSTEMIsIndividual__c, recordtypeid from Account limit 1 ];
        System.debug('Here is the value:' + acc.npe01__SYSTEMIsIndividual__c);
        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withAccount(acc.Id)
            .withContact(conRecord.Id)
            .build();
        try {
            insert rd;
        } catch (Exception e) {
            errMessage = e.getMessage();
            System.debug('Error message is:'+ errMessage);
        }
        System.assert(errMessage.contains(System.Label.RD_ValidateIfContactNotRelatedWithAccount));


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

    /***
    * @description Builds a Contact without related to an account
    * @return Contact Record
    */
    private static Contact getContact() {
        return new Contact(
            LastName = 'Smith'
        );
    }

}