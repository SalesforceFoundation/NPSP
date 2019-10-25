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
* @description Enhanced Recurring Donations Schedule Service unit tests
*
*/
@isTest(IsParallel=true)
private with sharing class RD2_ScheduleService_TEST {
    private static final TEST_SObjectGateway.RecurringDonationGateway rdGateway = new TEST_SObjectGateway.RecurringDonationGateway();
    private static final TEST_SObjectGateway.RecurringDonationScheduleGateway rdScheduleGateway = new TEST_SObjectGateway.RecurringDonationScheduleGateway();

    /****
    * @description Creates data required for unit tests
    */
    @TestSetup
    private static void setUp() {
        Account acc = new Account(Name = 'RD2 Trigger Handler Account');
        insert acc;

        Contact contact = UTIL_UnitTestData_TEST.getContact();
        contact.AccountId = acc.Id;
        insert contact;
    }

    /***
    * @description Verifies details of schedule creation
    */
    @isTest
    private static void shouldCreateNewRDScheduleOnInsert() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Contact contact = getContact();

        List<npe03__Recurring_Donation__c> rds = new List<npe03__Recurring_Donation__c>{
                TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                    .withMockId()
                    .withContact(contact.Id)
                    .withAmount(10)
                    .withInstallmentPeriodMonthly()
                    .withInstallmentFrequency(1)
                    .withDayOfMonth('20')
                    .withDateEstablished(Date.newInstance(2019, 9, 15))
                    .withStartDate(Date.newInstance(2019, 9, 15))
                    .build()
        };

        Test.startTest();
        insert rds;
        Test.stopTest();

        Map<Id, npe03__Recurring_Donation__c> actualRdById = new Map<Id, npe03__Recurring_Donation__c>(
                rdGateway.getRecords(rds)
        );
        System.assertEquals(rds.size(), actualRdById.size(), 'Number of RDs should match');

        List<RecurringDonationSchedule__c> rdSchedules = rdScheduleGateway.getRecords(rds);
        System.assertEquals(rds.size(), rdSchedules.size(), 'Number of RD schedule records should equal the number of RD records');

    }


    // Helpers
    ///////////////////

    /****
    * @description Returns contact record
    * @return Contact
    */
    private static Contact getContact() {
        return [
                SELECT FirstName, LastName, AccountId, Account.Name
                FROM Contact
                LIMIT 1
        ];
    }

}
