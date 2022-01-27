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
                rd2Settings = new RD2_Settings();
            }
            return rd2Settings;
        }
        set;
    }

    public RD2_StatusAutomationView getStatusAutomationView() {
        rd2Settings.reloadSetting();
        RD2_StatusAutomationView view = new RD2_StatusAutomationView();

        view.closedStatus = rd2Settings.statusAutomationClosedValue;
        view.lapsedStatus = rd2Settings.statusAutomationLapsedValue;
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

    public void saveSetting(Integer daysForLapsed, Integer daysForClosed, String lapsedStatus, String closedStatus) {
        validateUpdatePermission();
        npe03__Recurring_Donations_Settings__c settings = 
            UTIL_CustomSettingsFacade.getRecurringDonationsSettings();
        
        settings.StatusAutomationDaysForLapsed__c = daysForLapsed;
        settings.StatusAutomationDaysForClosed__c = daysForClosed;
        settings.StatusAutomationLapsedValue__c = lapsedStatus;
        settings.StatusAutomationClosedValue__c = closedStatus;

        if (!Test.isRunningTest()) {
            update settings;
        }
    }

    public Boolean isSettingValid() {
        Boolean isSettingValid = true;
        if (rd2Settings.isStatusAutomationForClosedEnabled() && rd2Settings.isStatusAutomationForLapsedEnabled()) {
            isSettingValid = isSettingValid
                && rd2Settings.statusAutomationNumberOfDaysForLapsed < rd2Settings.statusAutomationNumberOfDaysForClosed;
        }

        if (rd2Settings.isStatusAutomationForClosedEnabled()) {
            isSettingValid = isSettingValid
                && statusMapper.getState(rd2Settings.statusAutomationClosedValue) == RD2_Constants.STATUS_Closed 
                && rd2Settings.statusAutomationNumberOfDaysForClosed > 0;
        }

        if (rd2Settings.isStatusAutomationForLapsedEnabled()) {
            isSettingValid = isSettingValid
                && statusMapper.getState(rd2Settings.statusAutomationLapsedValue) != RD2_Constants.STATUS_LAPSED
                && rd2Settings.statusAutomationNumberOfDaysForLapsed > 0;
        }
        return isSettingValid;
    }

    public String validateSetting(Integer daysForLapsed, Integer daysForClosed, String lapsedStatus, String closedStatus) {
        if (daysForLapsed != null && daysForClosed != null) {
            if (daysForLapsed >= daysForClosed) {
                return System.label.RD2_StatusAutomationInvalidNumberOfDays;
            }
        }

        if (daysForLapsed != null) {
            if (statusMapper.getState(lapsedStatus) != RD2_Constants.STATUS_LAPSED) {
                return System.label.RD2_StatusAutomationInvalidLapsedStatus;
            }

            if (daysForLapsed < 0) {
                return System.label.RD2_StatusAutomationNegativeNumberOfDays;
            }
        }

        if (daysForClosed != null) {
            if (statusMapper.getState(closedStatus) != RD2_Constants.STATUS_Closed) {
                return System.label.RD2_StatusAutomationInvalidClosedStatus;
            }

            if (daysForClosed < 0) {
                return System.label.RD2_StatusAutomationNegativeNumberOfDays;
            }
        }

        return null;
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

    private List<PicklistOptionView> createStatusOption(List<String> statusValues) {
        List<PicklistOptionView> options = new List<PicklistOptionView>();
        for (String status : statusValues) {
              options.add(
                 new PicklistOptionView()
                    .withLabel(status)
                    .withValue(status)
            );
        }
        return options;
    }


}
