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
* @description Stores and retrieves Recurring Donation Status Automation Settings
*/
public with sharing class RD2_StatusAutomationSettings_CTRL {

    public String getNamespace() {
        return UTIL_Namespace.getComponentNamespace();
    }

    @AuraEnabled
    public static RD2_StatusAutomationView getAutomationSettings() {
        try {
            if (!STG_Panel.runningUserIsAdmin()) {
                throw new UTIL_Permissions.InsufficientPermissionException(System.Label.commonPermissionErrorMessage);
            }
            RD2_StatusAutomationService service = new RD2_StatusAutomationService();

            return service.getStatusAutomationView();

        } catch (Exception ex) {
            throwAuraHandledException(ex.getMessage());
        }

        return null;
    }

    @AuraEnabled
    public static RD2_StatusAutomationView saveStatusAutomationSettings(Integer daysForLapsed, Integer daysForClosed, String lapsedStatus, String closedStatus) {
        try {
            if (!STG_Panel.runningUserIsAdmin()) {
                throw new UTIL_Permissions.InsufficientPermissionException(System.Label.commonPermissionErrorMessage);
            }

            RD2_StatusAutomationService service = new RD2_StatusAutomationService();
            npe03__Recurring_Donations_Settings__c automationSettings = 
                service.buildStatusAutomationSettings(daysForLapsed, daysForClosed, lapsedStatus, closedStatus);

            String errorString = service.validateSetting(automationSettings);

            if (String.isNotBlank(errorString)) {
                throw new StatusAutomationException(errorString);
            }

            service.saveSetting(automationSettings);
            return getAutomationSettings();

        } catch (Exception ex) {
            throwAuraHandledException(ex.getMessage());
        }

        return null;
    }

    private static void throwAuraHandledException(String errMessage) {
        AuraHandledException e = new AuraHandledException(errMessage);
        e.setMessage(errMessage);
        throw e;
    }

    public class StatusAutomationException extends Exception {}
}
