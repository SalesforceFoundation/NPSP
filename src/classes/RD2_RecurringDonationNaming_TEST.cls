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
* @description Recurring Donations Naming Trigger Handler tests
*
*/
@isTest
private with sharing class RD2_RecurringDonationNaming_TEST {
    private static final String TEST_NAME = 'RD Naming TDTM';
    private static final String ACCOUNT_RD_NAME = 'foo';
    private static final String CONTACT_RD_NAME = 'bar';

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
                .withName(ACCOUNT_RD_NAME)
                .withAccount(acc.Id)
                .withAmount(100)
                .withCurrencyIsoCode('USD')
                .build(),
            new TEST_RecurringDonationBuilder()
                .withName(CONTACT_RD_NAME)
                .withContact(contact.Id)
                .withAmount(200)
                .withCurrencyIsoCode('USD')
                .build()
        };
    }

    /***
    * @description Verifies Recurring Donation name is not updated 
    * when RD automatic naming is not enabled
    */
    @isTest
    private static void shouldNotUpdateRDNameWhenAutomaticNamingIsNotEnabled() { 
        Contact contact = getContact();

        Test.startTest();
        contact.FirstName += ' changed';
        update contact;
        Test.stopTest();    
        
        npe03__Recurring_Donation__c rd = rdGateway.getRecordsReferencingContacts(
            new Set<Id>{ contact.Id }
        )[0];

        System.assertEquals(CONTACT_RD_NAME, rd.Name, 'Recurring Donation name should be unchanged');        
    }

    /***
    * @description Verifies Recurring Donation name is not updated 
    * when RD automatic naming is enabled
    * and Contact name is unchanged. 
    */
    @isTest
    private static void shouldNotUpdateRDNameWhenContactNameIsUnchanged() {        
        Contact contact = getContact();

        Test.startTest();
        RD2_NamingService_TEST.enableAutomaticNaming();

        contact.npe01__Preferred_Email__c = 'test' + contact.npe01__Preferred_Email__c;
        update contact;
        Test.stopTest();    
        
        npe03__Recurring_Donation__c rd = rdGateway.getRecordsReferencingContacts(
            new Set<Id>{ contact.Id }
        )[0];

        System.assertEquals(CONTACT_RD_NAME, rd.Name, 'Recurring Donation name should be unchanged');       
    }

    /***
    * @description Verifies Recurring Donation name is updated 
    * when RD automatic naming is enabled
    * and Contact name is changed. 
    */
    @isTest
    private static void shouldUpdateRDNameWhenContactNameIsChanged() {
        Contact contact = getContact();

        Test.startTest();
        RD2_NamingService_TEST.enableAutomaticNaming();

        contact.FirstName += ' changed';
        update contact;
        Test.stopTest();    
        
        npe03__Recurring_Donation__c rd = rdGateway.getRecordsReferencingContacts(
            new Set<Id>{ contact.Id }
        )[0];

        System.assertEquals(RD2_NamingService_TEST.getExpectedName(contact, '200'), rd.Name, 'Recurring Donation name should be updated');        
    }

    /***
    * @description Verifies Recurring Donation name is updated 
    * when RD automatic naming is enabled
    * and Contact FirstName is null.
    */
    @isTest
    private static void shouldUpdateRDNameWhenContactFirstNameIsNull() {
        Contact contact = getContact();

        Test.startTest();
        RD2_NamingService_TEST.enableAutomaticNaming();

        contact.FirstName = null;
        update contact;
        Test.stopTest();    
        
        npe03__Recurring_Donation__c rd = rdGateway.getRecordsReferencingContacts(
            new Set<Id>{ contact.Id }
        )[0];

        System.assertEquals(RD2_NamingService_TEST.getExpectedName(contact, '200'), rd.Name, 'Recurring Donation name should be updated');        
    }

    /***
    * @description Verifies Recurring Donation name is updated 
    * when RD automatic naming is enabled
    * and Account name is changed. 
    */
    @isTest
    private static void shouldUpdateRDNameWhenAccountNameIsChanged() {
        Account acc = getAccount();      

        Test.startTest();
        RD2_NamingService_TEST.enableAutomaticNaming();

        acc.Name += ' changed';
        update acc;
        Test.stopTest();    
        
        npe03__Recurring_Donation__c rd = rdGateway.getRecordsReferencingAccounts(
            new Set<Id>{ acc.Id }
        )[0];

        System.assertEquals(RD2_NamingService_TEST.getExpectedName(acc, '100'), rd.Name, 'Recurring Donation name should be updated');
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
            SELECT FirstName, LastName, npe01__Preferred_Email__c
            FROM Contact
            WHERE FirstName = :TEST_NAME
        ];
    }  

}