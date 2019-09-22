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
* @description Recurring Donations Gateway tests
*
*/
@isTest
private with sharing class RD2_RecurringDonationsGateway_TEST {
    private static final String TEST_NAME = 'Recurring Donation Gateway';

    private static final RD2_RecurringDonationsGateway rdGateway = new RD2_RecurringDonationsGateway();
    
    /***
     * Creates test data
     */
    @TestSetup
    private static void setUp() {
        Account acc = new Account(Name = TEST_NAME);
        insert acc;

        Contact contact = UTIL_UnitTestData_TEST.getContact();
        contact.FirstName = TEST_NAME;
        insert contact;

        insert new List<npe03__Recurring_Donation__c>{
            new TEST_RecurringDonationBuilder()
                .withName('foo')
                .withAccount(acc.Id)
                .withAmount(100)
                .withCurrencyIsoCode('USD')
                .build(),
            new TEST_RecurringDonationBuilder()
                .withName('bar')
                .withContact(contact.Id)
                .withAmount(200)
                .withCurrencyIsoCode('USD')
                .build()
        };
    }

    /***
    * @description Verifies Recurring Donations are returned for specified Account
    */
    @isTest
    private static void shouldReturnRecordsForSpecifiedAccount() {
        Account acc = getAccount();
        List<npe03__Recurring_Donation__c> rds = rdGateway.getRecordsReferencingAccounts(
            new Set<Id>{ acc.Id, getContact().Id, null, acc.Id }
        );

        System.assertEquals(1, rds.size(), 'Number of returned records should match');
        System.assertNotEquals(null, rds[0].npe03__Organization__c, 'Recurring Donation associated with the Account should be returned');
    }

    /***
    * @description Verifies Recurring Donations are returned for specified Contact
    */
    @isTest
    private static void shouldReturnRecordsForSpecifiedContact() {
        List<npe03__Recurring_Donation__c> rds = rdGateway.getRecordsReferencingContacts(
            new Set<Id>{ getContact().Id, null }
        );

        System.assertEquals(1, rds.size(), 'Number of returned records should match');
        System.assertNotEquals(null, rds[0].npe03__Contact__c, 'Recurring Donation associated with the Contact should be returned');
    }

    /***
    * @description Verifies Recurring Donations are returned for specified Ids
    */
    @isTest
    private static void shouldReturnRecords() {
        List<npe03__Recurring_Donation__c> rds = [SELECT Id FROM npe03__Recurring_Donation__c];

        npe03__Recurring_Donation__c rd = rdGateway.getRecord(rds[0].Id);
        System.assertNotEquals(null, rd, 'Record should be returned');
        System.assertEquals(rds[0].Id, rd.Id, 'Recurring Donation Id should match');

        List<npe03__Recurring_Donation__c> actualRds = rdGateway.getRecords(rds);
        System.assertEquals(actualRds.size(), rds.size(), 'Number of returned records should match');
    }


    // Helpers
    ///////////////

    /***
     * @description Returns Account created as the test data in this class
     */
    private static Account getAccount() {
        return [
            SELECT Name
            FROM Account
            WHERE Name = :TEST_NAME
        ];
    }

    /***
     * @description Returns Contact created as the test data in this class
     */
    private static Contact getContact() {
        return [
            SELECT FirstName, LastName
            FROM Contact
            WHERE FirstName = :TEST_NAME
        ];
    }   

}