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
private with sharing class RD2_VisualizeScheduleController_TEST {

    private static final Date DATE_ESTABLISHED = Date.newInstance(2019, 11, 1);

    /****
    * @description Creates data required for unit tests
    */
    @TestSetup
    private static void setUp() {
        insert UTIL_UnitTestData_TEST.getContact();
    }


    /****
    * @description Validates that AuraHandledException is thrown when RD Id is null
    */
    @IsTest
    private static void shouldThrowAuraHandledExceptionWhenRDIdIsNull() {
        Exception actualException;
        Integer numberOfInstallments = null;
        Id rdId = null;

        try {
            RD2_VisualizeScheduleController.getSchedule(rdId, numberOfInstallments);
        } catch (Exception e) {
            actualException = e;
        }

        assertScheduleVisualizerException(actualException);
    }

    /****
    * @description Validates that AuraHandledException is thrown when zero installments are requested
    */
    @IsTest
    private static void shouldThrowAuraHandledExceptionWhenZeroInstallmentsRequested() {
        Exception actualException;
        Integer numberOfInstallments = 0;
        npe03__Recurring_Donation__c rd = buildEnhancedRecurringDonation();

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Test.startTest();
        insert rd;
        Test.stopTest();

        try {
            RD2_VisualizeScheduleController.getSchedule(rd.Id, numberOfInstallments);        
        } catch (Exception e) {
            actualException = e;
        }

        assertScheduleVisualizerException(actualException);
    }

    /****
    * @description Validates that AuraHandledException is thrown when negative number of installments are requested
    */
    @IsTest
    private static void shouldThrowAuraHandledExceptionWhenNegativeNumberOfInstallmentsRequested() {
        Exception actualException;
        Integer numberOfInstallments = -5;
        npe03__Recurring_Donation__c rd = buildEnhancedRecurringDonation();

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Test.startTest();
        insert rd;
        Test.stopTest();
        
        try {
            RD2_VisualizeScheduleController.getSchedule(rd.Id, numberOfInstallments);        
        } catch (Exception e) {
            actualException = e;
        }

        assertScheduleVisualizerException(actualException);
    }


    /****
    * @description Validates that specified number of installments are returned as requested for a valid active RD
    */
    @IsTest
    private static void shouldReturnSpecifiedInstallmentsForValidActiveRD() {
        Integer numberOfInstallments = 12;
        npe03__Recurring_Donation__c rd = buildEnhancedRecurringDonation();

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Test.startTest();
        insert rd;
        List<RD2_VisualizeScheduleController.Installment> schedules = 
            RD2_VisualizeScheduleController.getSchedule(rd.Id, numberOfInstallments);
        Test.stopTest();

        System.assertEquals(numberOfInstallments, schedules.size(), 'Number of installments should match');
    }

    /****
    * @description Validates that AuraHandledException is thrown when Enhanced RD is not enabled
    */
    @IsTest
    private static void shouldThrowAuraHandledExceptionWhenEnhancedRDNotEnabled() {
        Exception actualException;
        Integer numberOfInstallments = 12;
        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withContact(getContact().Id)
            .withAmount(50)
            .withDateEstablished(DATE_ESTABLISHED)
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        try {
            RD2_VisualizeScheduleController.getSchedule(rd.Id, numberOfInstallments);  
        } catch (Exception e) {
            actualException = e;
        }

        assertScheduleVisualizerException(actualException);
    }

    /****
    * @description Validates that AuraHandledException is thrown when incorrect SObject Id is used
    */
    @IsTest
    private static void shouldThrowAuraHandledExceptionWhenNonRDSObjectUsed() {
        Exception actualException;
        Integer numberOfInstallments = 12;

        Account acc = UTIL_UnitTestData_TEST.buildHouseholdAccount();
        insert acc;
        
        try {
            RD2_VisualizeScheduleController.getSchedule(acc.Id, numberOfInstallments);  
        } catch (Exception e) {
            actualException = e;
        }

        assertScheduleVisualizerException(actualException);
    }


    //// Helpers

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

    /****
    * @description Builds Recurring Donation record in an enhanced formation
    * @return npe03__Recurring_Donation__c
    */
    private static npe03__Recurring_Donation__c buildEnhancedRecurringDonation() {
        return TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withContact(getContact().Id)
            .withAmount(50)
            .withPaymentMethod('Credit Card')
            .withInstallmentPeriod(RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH)
            .withInstallmentFrequency(1)
            .withDateEstablished(DATE_ESTABLISHED)
            .withStartDate(DATE_ESTABLISHED)
            .build();        
    }

    /****
    * @description Verifies exception has been generated and its type and message are as expected
    * @param actualException Actual exception (if any)
    * @return void
    */
    private static void assertScheduleVisualizerException(Exception actualException) {
        Exception expectedException = new AuraHandledException(System.Label.RD2_ScheduleVisualizerErrorEnhancedRDNot);

        System.assertNotEquals(null, actualException, 'An exception should be generated');
        System.assertEquals(expectedException.getTypeName(), actualException.getTypeName(),
            'Exception type should be System.AuraHandledException');
        System.assertEquals(expectedException.getMessage(), actualException.getMessage(),
            'Exception message should match');
    }
}