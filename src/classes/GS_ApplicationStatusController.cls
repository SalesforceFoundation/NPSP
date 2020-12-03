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
 * @date 2020
 * @group Get Started Page
 * @author Salesforce.org
 * @description Controller for getting the org status(is trial? when it expires?, did customer applied for the licenses?).
 */
public with sharing class GS_ApplicationStatusController {
   
   /**
    * @description Aura enabled method for knowing if Organization is Active
    * @return true if Organization is Active(no TrialExpirationDate presented), false otherwise
    */
    @AuraEnabled(Cacheable=true)
    public static Boolean isActiveOrg(){
        
        return !GS_NonprofitTrialOrgService.isSandbox() && GS_NonprofitTrialOrgService.getExpirationDate() == null;
    }

    /**
     * @description Aura enabled method for retrieving Organization Expiration date, if its running on a sandbox instance and the application date.
     * The Expiration Date and The is sandbox is queried from Organization Object. The application date is gotten from the P10_Application_Date FeatureParameter.
     * As this is using some Values that cannot be written and are dependable from the org and application status which we dont control,
     * for a better testeability, all the returning values can be overriden using creating a new StaticResource called 'gsApplicationConfiguration'
     * which contains a json file. For more information please refer to GS_NonprofitTrialOrgService.getTestingConfiguration documentation.
     * @return ApplicationStatus: Object with the status of the application for licenses of the org.
     */
    @AuraEnabled(Cacheable=true)
    public static ApplicationStatus getApplicationStatus() { 
                
        ApplicationStatus status = new ApplicationStatus();
        status.isSandbox = GS_NonprofitTrialOrgService.isSandbox();
        status.trialExpirationDate = GS_NonprofitTrialOrgService.getExpirationDate();
        status.applicationDate = GS_NonprofitTrialOrgService.getApplicationDate();
        return status;
    }
    
    /**
     * @description Internal class used to wrap the Status of the Org.
     */
    public class ApplicationStatus {
        
        /**
         * @description Returns if the org is a sandbox
         */
        @AuraEnabled
        public boolean isSandbox {get; set;}
        
        /**
         * @description Returns the application date
         */
        @AuraEnabled
        public Date applicationDate {get; set;}
        
        /**
         * @description Returns the trialExpirationDate
         */
        @AuraEnabled
        public DateTime trialExpirationDate {get; set;}
    }
}
