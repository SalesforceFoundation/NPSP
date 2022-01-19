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
* @description Test class for RD2_StatusAutomationSettings_CTRL
*/
@IsTest
private class RD2_StatusAutomationSettings_TEST {
    private static final Integer DAYS_FOR_LAPSED = 15;
    private static final Integer DAYS_FOR_CLOSED = 20;

    @IsTest
    private static void verifyStatusAutomationSettingsRetrieveCorrectData() {
        RD2_enablementService_TEST.setRecurringDonations2Enabled();
        RD2_StatusAutomationService.statusMapper = (RD2_StatusMapper) Test.createStub(
            RD2_StatusMapper.Class,
            new RD2_StatusMapper_TEST.Stub().withDefaultMapping()
        );

        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
            new npe03__Recurring_Donations_Settings__c(
                    IsRecurringDonations2Enabled__c = true,
                    StatusAutomationDaysForLapsed__c = DAYS_FOR_LAPSED,
                    StatusAutomationDaysForClosed__c =DAYS_FOR_CLOSED,
                    StatusAutomationLapsedValue__c = RD2_Constants.STATUS_LAPSED,
                    StatusAutomationClosedValue__c = RD2_Constants.STATUS_CLOSED
            )
        );

        RD2_StatusAutomationView view = RD2_StatusAutomationSettings_CTRL.getAutomationSettings();

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
    private static void verifyStatusAutomationIsCorrectlySave() {
        RD2_enablementService_TEST.setRecurringDonations2Enabled();
        RD2_StatusAutomationService.statusMapper = (RD2_StatusMapper) Test.createStub(
            RD2_StatusMapper.Class,
            new RD2_StatusMapper_TEST.Stub().withDefaultMapping()
        );

        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
            new npe03__Recurring_Donations_Settings__c(
                    IsRecurringDonations2Enabled__c = true,
                    StatusAutomationDaysForLapsed__c = DAYS_FOR_LAPSED,
                    StatusAutomationDaysForClosed__c =DAYS_FOR_CLOSED,
                    StatusAutomationLapsedValue__c = RD2_Constants.STATUS_LAPSED,
                    StatusAutomationClosedValue__c = RD2_Constants.STATUS_CLOSED
            )
        );
        
        String errorMessage;
        try {
            RD2_StatusAutomationView view = RD2_StatusAutomationSettings_CTRL.saveStatusAutomationSettings(
                DAYS_FOR_LAPSED,
                DAYS_FOR_CLOSED,
                RD2_Constants.STATUS_LAPSED,
                RD2_Constants.STATUS_CLOSED
            );
        } catch (Exception ex) {
            errorMessage = ex.getMessage();
        }

        System.assert(String.isBlank(errorMessage), 'The save operation should go through successfully without any exception');
    }

    @IsTest
    private static void userWithoutAdminPermissionCannotRetrieveStatusAutomationSettings() {
        User standardUser = UTIL_UnitTestData_TEST.createUserWithoutInsert(UTIL_Profile.PROFILE_READ_ONLY);

        System.runAs(standardUser) {
            String errorMessage;
           try {
                RD2_StatusAutomationView automationView = RD2_StatusAutomationSettings_CTRL.getAutomationSettings();
            } catch (AuraHandledException ex) {
                errorMessage = ex.getMessage();
            }
            
            System.assertEquals(System.Label.commonPermissionErrorMessage, errorMessage,
                'Insufficient Permission error should be thrown when non admin user tries to access the settings.');
        }
    }

    @IsTest
    private static void userWithoutAdminPermissionCannotUpdateStatusAutomationSettings() {
        User standardUser = UTIL_UnitTestData_TEST.createUserWithoutInsert(UTIL_Profile.PROFILE_READ_ONLY);

        System.runAs(standardUser) {
            String errorMessage;
           try {
                RD2_StatusAutomationView automationView =
                    RD2_StatusAutomationSettings_CTRL.saveStatusAutomationSettings(null, null, null, null);
            } catch (AuraHandledException ex) {
                errorMessage = ex.getMessage();
            }
            
            System.assertEquals(System.Label.commonPermissionErrorMessage, errorMessage,
                'Insufficient Permission error should be thrown when non admin user tries to update the settings.');
        }
    }
}
