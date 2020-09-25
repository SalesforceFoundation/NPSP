/*
    Copyright (c) 2020, Salesforce.org
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
 * @description Controller for getting the org status(is trial? when it expires?, did customer applied for the licenses?).
 */
public with sharing class GS_ApplicationStatusController {
    private static final String APPLICATION_DATE = 'P10_Application_Date';
    /**
     * 
     */
     @AuraEnabled
    public static ApplicationStatus getApplicationStatus() { 
        ApplicationStatus status = new ApplicationStatus();
        
        GS_ApplicationStatusController controller = new GS_ApplicationStatusController();
        Organization org = controller.getOrgInformation();
        if (org != null) {
            status.isSandbox = org.IsSandbox;
            status.trialExpirationDate = org.TrialExpirationDate;
        }
        Date applicationDate = controller.getApplicationDate();
        System.debug('applicationDate -> ' + applicationDate);
        status.applicationDate = applicationDate;
        return status;
    }

    private Date getApplicationDate() {
        try {
            return System.FeatureManagement.checkPackageDateValue(APPLICATION_DATE);
        } catch (System.NoDataFoundException ex) {
            return Date.Today();
        }
        
    }
    private Organization getOrgInformation() {
        return [SELECT TrialExpirationDate,
                       IsSandbox
                FROM   Organization
                WITH_SECURITY_ENFORCED];
    }
    /**
     * @description Internal class used for returning the current status of the org. 
     */
    public class ApplicationStatus {
        
        @AuraEnabled
        public boolean isSandbox {get; set;}
        
        @AuraEnabled
        public DateTime applicationDate {get; set;}
        
        @AuraEnabled
        public DateTime trialExpirationDate {get; set;}
    }
}
