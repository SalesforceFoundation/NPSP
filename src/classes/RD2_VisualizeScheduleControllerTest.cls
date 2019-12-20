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
* @description Enhanced Recurring Donations Visualize Schedule Controller unit tests
*
*/
@IsTest(IsParallel=true)
private with sharing class RD2_VisualizeScheduleControllerTest {

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


    /****
    * @description Validates that AuraHandledException is thrown when RD Id is null
    */
    @IsTest
    private static void shouldThrowAuraHandledExceptionWhenRDIdIsNull() {
        try {
            RD2_VisualizeScheduleController.getSchedule(null, null);
        }
        catch(Exception e) {
            System.assertEquals(new AuraHandledException(System.Label.RD2_ScheduleVisualizerErrorEnhancedRDNot).getTypeName(), e.getTypeName(),
                    'Both exception types should be System.AuraHandledException');
        }
    }

    /****
    * @description Validates that AuraHandledException is thrown when zero installments are requested
    */
    @IsTest
    private static void shouldThrowAuraHandledExceptionWhenZeroInstallmentsRequested() {

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Contact contact = getContact();

        npe03__Recurring_Donation__c rd =
                TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                        .withContact(contact.Id)
                        .withAmount(50)
                        .withPaymentMethod('Credit Card')
                        .withInstallmentPeriod('1st and 15th')
                        .withInstallmentFrequency(1)
                        .withDateEstablished(Date.newInstance(2019, 11, 1))
                        .withStartDate(Date.newInstance(2019, 11, 1))
                        .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        try {
            RD2_VisualizeScheduleController.getSchedule(rd.Id, 0);
        }
        catch(Exception e) {
            System.assertEquals(new AuraHandledException(System.Label.RD2_ScheduleVisualizerErrorEnhancedRDNot).getTypeName(), e.getTypeName(),
                    'Both exception types should be System.AuraHandledException');
        }
    }

    /****
    * @description Validates that AuraHandledException is thrown when negative number of installments are requested
    */
    @IsTest
    private static void shouldThrowAuraHandledExceptionWhenNegativeNumberOfInstallmentsRequested() {

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Contact contact = getContact();

        npe03__Recurring_Donation__c rd =
                TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                        .withContact(contact.Id)
                        .withAmount(50)
                        .withPaymentMethod('Credit Card')
                        .withInstallmentPeriod('1st and 15th')
                        .withInstallmentFrequency(1)
                        .withDateEstablished(Date.newInstance(2019, 11, 1))
                        .withStartDate(Date.newInstance(2019, 11, 1))
                        .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        try {
            RD2_VisualizeScheduleController.getSchedule(null, -5);
        }
        catch(Exception e) {
            System.assertEquals(new AuraHandledException(System.Label.RD2_ScheduleVisualizerErrorEnhancedRDNot).getTypeName(), e.getTypeName(),
                    'Both exception types should be System.AuraHandledException');
        }
    }

    /****
    * @description Validates that 12 installments are returned when twelve are requested for a valid non-closed RD
    */
    @IsTest
    private static void shouldReturn12InstallmentsForValidNonClosedRD() {

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Contact contact = getContact();

        npe03__Recurring_Donation__c rd =
                TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                        .withContact(contact.Id)
                        .withAmount(50)
                        .withPaymentMethod('Credit Card')
                        .withInstallmentPeriod('1st and 15th')
                        .withInstallmentFrequency(1)
                        .withDateEstablished(Date.newInstance(2019, 11, 1))
                        .withStartDate(Date.newInstance(2019, 11, 1))
                        .build();

        Test.startTest();
        insert rd;
        List<RD2_VisualizeScheduleController.Installment> schedules = RD2_VisualizeScheduleController.getSchedule(rd.Id, 12);
        Test.stopTest();

        System.assertEquals(12, schedules.size(), 'There should be 12 installments.');

    }

    /****
    * @description Validates that AuraHandledException is thrown when Enhanced RD is not enabled
    */
    @IsTest
    private static void shouldThrowAuraHandledExceptionWhenEnhancedRDNotEnabled() {

        Contact contact = getContact();

        npe03__Recurring_Donation__c rd =
                TEST_RecurringDonationBuilder.constructLegacyBuilder()
                        .withContact(contact.Id)
                        .withAmount(50)
                        .withDateEstablished(Date.newInstance(2019, 11, 1))
                        .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        try {
            List<RD2_VisualizeScheduleController.Installment> schedules = RD2_VisualizeScheduleController.getSchedule(rd.Id, 12);
        }
        catch(Exception e) {
            System.assertEquals(new AuraHandledException(System.Label.RD2_ScheduleVisualizerErrorEnhancedRDNot).getTypeName(), e.getTypeName(),
                    'Both exception types should be System.AuraHandledException');
        }
    }

    /****
    * @description Validates that AuraHandledException is thrown when incorrect SObject Id is used
    */
    @IsTest
    private static void shouldThrowAuraHandledExceptionWhenNonRDSObjectUsed() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        try {
            RD2_VisualizeScheduleController.getSchedule(acc.Id, 12);
        }
        catch(Exception e) {
            System.assertEquals(new AuraHandledException(System.Label.RD2_ScheduleVisualizerErrorEnhancedRDNot).getTypeName(), e.getTypeName(),
                    'Both exception types should be System.AuraHandledException');
        }
    }


    //// Helpers

    /****
    * @description Returns contact record
    */
    private static Contact getContact() {
        return [
                SELECT FirstName, LastName, AccountId, Account.Name
                FROM Contact
                LIMIT 1
        ];
    }
}