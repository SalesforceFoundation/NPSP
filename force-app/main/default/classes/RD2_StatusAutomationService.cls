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
* @description Status Automation Service
*/
public with sharing class RD2_StatusAutomationService {
    @TestVisible
    private static RD2_StatusMapper statusMapper {
        get {
            if (statusMapper == null) {
                statusMapper = new RD2_StatusMapper();
            }
            return statusMapper;
        }
        set;
    }

    @TestVisible
    private static RD2_Settings rd2Settings {
        get {
            if (rd2Settings == null) {
                rd2Settings = RD2_Settings.getInstance();
            }
            return rd2Settings;
        }
        set;
    }

    public RD2_StatusAutomationView getStatusAutomationView() {
        rd2Settings.reloadSetting();
        RD2_StatusAutomationView view = new RD2_StatusAutomationView();
        view.closedStatus = UTIL_Describe.getTranslatedPicklistLabel(
            npe03__Recurring_Donation__c.SObjectType, npe03__Recurring_Donation__c.Status__c, rd2Settings.statusAutomationClosedValue
        );

        view.lapsedStatus = UTIL_Describe.getTranslatedPicklistLabel(
            npe03__Recurring_Donation__c.SObjectType, npe03__Recurring_Donation__c.Status__c, rd2Settings.statusAutomationLapsedValue
        );

        view.numberOfDaysForClosed = rd2Settings.statusAutomationNumberOfDaysForClosed;
        view.numberOfDaysForLapsed = rd2Settings.statusAutomationNumberOfDaysForLapsed;
        view.closedStatusOption = createStatusOption(
            new List<String>(statusMapper.getClosedStatusValues())
        );
        view.lapsedStatusOption = createStatusOption(
            new List<String>(statusMapper.getLapsedStatusValues())
        );
        view.rd2Enabled = RD2_EnablementService.isRecurringDonations2Enabled;
        return view;
    }

    public npe03__Recurring_Donations_Settings__c buildStatusAutomationSettings(
        Integer daysForLapsed,
        Integer daysForClosed,
        String lapsedStatus,
        String closedStatus) {

        npe03__Recurring_Donations_Settings__c automationSettings = 
        UTIL_CustomSettingsFacade.getRecurringDonationsSettings();
    
        automationSettings.StatusAutomationDaysForLapsed__c = daysForLapsed;
        automationSettings.StatusAutomationDaysForClosed__c = daysForClosed;
        automationSettings.StatusAutomationLapsedValue__c = lapsedStatus;
        automationSettings.StatusAutomationClosedValue__c = closedStatus;

        return automationSettings;
    }
    public void saveSetting(npe03__Recurring_Donations_Settings__c automationSettings) {
        validateUpdatePermission();

        if (!Test.isRunningTest()) {
            update automationSettings;
        }
    }

    public Boolean isSettingValid() {
        return String.isBlank(validateSetting(UTIL_CustomSettingsFacade.getRecurringDonationsSettings()));
    }

    public String validateSetting(npe03__Recurring_Donations_Settings__c settings) {
        if (settings.StatusAutomationDaysForLapsed__c != null
            && settings.StatusAutomationDaysForClosed__c != null) {
            if (settings.StatusAutomationDaysForLapsed__c >= settings.StatusAutomationDaysForClosed__c) {
                return System.label.RD2_StatusAutomationInvalidNumberOfDays;
            }
        }

        if (settings.StatusAutomationDaysForLapsed__c != null) {
            if (statusMapper.getState(settings.StatusAutomationLapsedValue__c) != RD2_Constants.STATUS_LAPSED) {
                return System.label.RD2_StatusAutomationInvalidLapsedStatus;
            }

            if (settings.StatusAutomationDaysForLapsed__c < 0) {
                return System.label.RD2_StatusAutomationNegativeNumberOfDays;
            }
        }

        if (settings.StatusAutomationDaysForClosed__c != null) {
            if (statusMapper.getState(settings.StatusAutomationClosedValue__c) != RD2_Constants.STATUS_Closed) {
                return System.label.RD2_StatusAutomationInvalidClosedStatus;
            }

            if (settings.StatusAutomationDaysForClosed__c < 0) {
                return System.label.RD2_StatusAutomationNegativeNumberOfDays;
            }
        }

        return null;
    }

    private enum StatusAutomationMode {
        EVALUATE_LAPSED,
        EVALUATE_CLOSED
    }

    public Boolean shouldMarkRDAsClosed(RD2_RecurringDonation rdRecord, RD2_ScheduleService scheduleService) {
        return processStatusAutomation(StatusAutomationMode.EVALUATE_CLOSED,rdRecord, scheduleService);
     }

    public Boolean shouldMarkRDAsLapsed(RD2_RecurringDonation rdRecord, RD2_ScheduleService scheduleService) {
        return processStatusAutomation(StatusAutomationMode.EVALUATE_LAPSED, rdRecord, scheduleService);
    }

    private Boolean processStatusAutomation(StatusAutomationMode processMode, RD2_RecurringDonation rdRecord, RD2_ScheduleService scheduleService) {
        if (!new RD2_StatusAutomationService().isSettingValid()
            || rdRecord.isClosed() 
            || rdRecord.isPaused()
            || !rdRecord.hasSchedule()
            || (processMode == StatusAutomationMode.EVALUATE_CLOSED && !rd2Settings.isStatusAutomationForClosedEnabled())
            || (processMode == StatusAutomationMode.EVALUATE_LAPSED && !rd2Settings.isStatusAutomationForLapsedEnabled())
        ) {
            return false;
        }
    
        Integer thresholdDays = (processMode == StatusAutomationMode.EVALUATE_CLOSED)
            ? rd2Settings.statusAutomationNumberOfDaysForClosed
            : rd2Settings.statusAutomationNumberOfDaysForLapsed;

        Date expectedDonationDate = rdRecord.getExpectedDonationDate(scheduleService);
        Date thresholdDate = expectedDonationDate.addDays(thresholdDays);

        return thresholdDate < RD2_ScheduleService.currentDate;
    }

    private void validateUpdatePermission() {
        Boolean hasUpdatePermission = UTIL_Describe.getObjectDescribe(
            String.valueOf(npe03__Recurring_Donations_Settings__c.SObjectType)
        ).IsUpdateable();

        if (!hasUpdatePermission) {
            throw new DmlException(
                String.format(
                    System.Label.flsError,
                    new List<String>{System.Label.stgLabelRDSettings})
            );
        }
    }

    private List<PicklistOptionView> createStatusOption(List<String> statusApiValues) {
        List<PicklistOptionView> options = new List<PicklistOptionView>();
        for (String statusApiValue : statusApiValues) {
            String statusLabel =  UTIL_Describe.getTranslatedPicklistLabel(
                npe03__Recurring_Donation__c.SObjectType, npe03__Recurring_Donation__c.Status__c, statusApiValue
            );
              options.add(
                 new PicklistOptionView()
                    .withLabel(statusLabel)
                    .withValue(statusApiValue)
            );
        }
        return options;
    }


}
