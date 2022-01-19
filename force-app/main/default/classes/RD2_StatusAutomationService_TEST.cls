/*
    Copyright (c) 2022, Salesforce.org
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
* @date 2022
* @group Recurring Donations
* @description Test class for RD2_StatusAutomationService
*/
@IsTest
private class RD2_StatusAutomationService_TEST {
    private static final Integer DAYS_FOR_LAPSED = 15;
    private static final Integer DAYS_FOR_CLOSED = 20;

    @IsTest
    private static void verifyCorrectViewIsRetrieve() {
        RD2_StatusAutomationService.statusMapper = (RD2_StatusMapper) Test.createStub(
            RD2_StatusMapper.Class,
            new RD2_StatusMapper_TEST.Stub().withDefaultMapping()
        );

        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
            new npe03__Recurring_Donations_Settings__c(
                    IsRecurringDonations2Enabled__c = true,
                    StatusAutomationDaysForLapsed__c = DAYS_FOR_LAPSED,
                    StatusAutomationDaysForClosed__c = DAYS_FOR_CLOSED,
                    StatusAutomationLapsedStatus__c = RD2_Constants.STATUS_LAPSED,
                    StatusAutomationClosedStatus__c = RD2_Constants.STATUS_CLOSED
            )
        );

        Test.startTest();
        RD2_StatusAutomationService service = new RD2_StatusAutomationService();
        RD2_StatusAutomationView view = service.getStatusAutomationView();
        Test.stopTest();
        
        System.assertEquals(true, view.rd2Enabled, 'RD2 should be enabled');
        System.assertEquals(DAYS_FOR_LAPSED, view.numberOfDaysForLapsed,
            'The view state should retrieve the correct number of days for Lapsed');
        System.assertEquals(DAYS_FOR_CLOSED, view.numberOfDaysForClosed,
            'The view state should retrieve the correct number of days for Closed');
        System.assertEquals(RD2_Constants.STATUS_LAPSED, view.lapsedStatus,
            'The view state should retrieve the correct Automation Lapsed Status');
        System.assertEquals(RD2_Constants.STATUS_CLOSED, view.closedStatus,
            'The view state should retrieve the correct Automation Closed Status');
        System.assertEquals( RD2_Constants.STATUS_LAPSED, view.lapsedStatusOption[0].label,
            'The Lapsed status picklist option should include Lapsed Status');
        System.assertEquals(RD2_Constants.STATUS_CLOSED, view.closedStatusOption[0].label,
            'The Closed status picklist option should include Closed Status');
    }

    @IsTest
    private static void verifyDaysForLapsedCannotBeLargerThanDaysForClosed() {
        RD2_StatusAutomationService service = new RD2_StatusAutomationService();

        Test.startTest();
        String errorMessage = service.validateSetting(5, 3, null, null);
        Test.stopTest();

        System.assertEquals(System.label.RD2_StatusAutomationInvalidNumberOfDays, errorMessage,
        'Invalid Number of Days message should be returned.');
    }

    @IsTest
    private static void verifyClosedStatusShouldMappedToClosedState() {
        RD2_StatusAutomationService.statusMapper = (RD2_StatusMapper) Test.createStub(
            RD2_StatusMapper.Class,
            new RD2_StatusMapper_TEST.Stub().withDefaultMapping()
        );
        RD2_StatusAutomationService service = new RD2_StatusAutomationService();

        Test.startTest();
        String errorMessage = service.validateSetting(null, 3, null, 'random');
        Test.stopTest();

        System.assertEquals(System.label.RD2_StatusAutomationInvalidClosedStatus, errorMessage,
        'Invalid Closed Status error message should be returned.');
    }

    @IsTest
    private static void verifyLapsedStatusShouldMappedToLapsedState() {
        RD2_StatusAutomationService.statusMapper = (RD2_StatusMapper) Test.createStub(
            RD2_StatusMapper.Class,
            new RD2_StatusMapper_TEST.Stub().withDefaultMapping()
        );
        RD2_StatusAutomationService service = new RD2_StatusAutomationService();

        Test.startTest();
        String errorMessage = service.validateSetting(2, null, 'random', null);
        Test.stopTest();

        System.assertEquals(System.label.RD2_StatusAutomationInvalidLapsedStatus, errorMessage,
        'Invalid Lapsed Status error message should be returned.');
    }

    @IsTest
    private static void verifyEmptyNumberOfDaysWillNotGetValidated() {
        RD2_StatusAutomationService.statusMapper = (RD2_StatusMapper) Test.createStub(
            RD2_StatusMapper.Class,
            new RD2_StatusMapper_TEST.Stub().withDefaultMapping()
        );
        RD2_StatusAutomationService service = new RD2_StatusAutomationService();

        Test.startTest();
        String errorMessage = service.validateSetting(null, null, 'random', 'random');
        Test.stopTest();

        System.assertEquals(null, errorMessage,
        'no error message should be returned because the feature is off when Number of Days is null.');
    }
}
