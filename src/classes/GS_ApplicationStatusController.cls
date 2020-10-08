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
    private static final String SANDBOX_PARAMETER = 'Sandbox';
    private static final String APPLICATION_PARAMETER = 'Application';
    private static final String TRIAL_EXPIRATION_PARAMETER = 'TrialExpiration';
    private static final Date DEFAULT_NON_APPLICATED_DATE = Date.parse('01/01/1970');
    private static final String STATIC_RESOURCE_NAME = 'gsApplicationConfiguration';
    
    @TestVisible
    private static Map<String, Object> testingConfiguration {
        get {
            if (testingConfiguration != null) {
                return testingConfiguration;
            } else {
                testingConfiguration = new GS_ApplicationStatusController().getTestingConfiguration();
                return testingConfiguration;
            }
        }
        set {
            testingConfiguration = value;
        }
    }
    /**
     * @description Aura enabled method for retrieving Organization Expiration date, if its running on a sandbox instance and the application date.
     * The Expiration Date and The is sandbox is queried from Organization Object. The application date is gotten from the P10_Application_Date FeatureParameter.
     * As this is using some Values that cannot be written and are dependable from the org and application status which we dont control,
     * for a better testeability, all the returning values can be overriden using creating a new StaticResource called 'gsApplicationConfiguration'
     * which contains a json file. For more information please refer to GS_ApplicationStatusController.getTestingConfiguration documentation.
     * @return ApplicationStatus: Object with the status of the application for licenses of the org.
     */
     @AuraEnabled
    public static ApplicationStatus getApplicationStatus() { 
        
        GS_ApplicationStatusController controller = new GS_ApplicationStatusController();
        
        Boolean overrideValuesForTesting = UTIL_Namespace.isScratchOrg() && testingConfiguration != null;
        
        Organization org = controller.getOrgInformation();
        
        ApplicationStatus status = new ApplicationStatus();
        status.isSandbox = controller.isSandbox(overrideValuesForTesting, testingConfiguration, org);
        status.trialExpirationDate = controller.getExpirationDate(overrideValuesForTesting, testingConfiguration, org);
        Date applicationDate = controller.getApplicationDate(testingConfiguration);
        status.applicationDate = applicationDate;
        return status;
    }

    /**
     * @description Return if the org is a Sandbox(Sandbox or Scratch).
     * @param  overrideValuesForTesting true if using custom setting is required for overriding Org information
     * @param  testingConfiguration     testingConfiguration Map<String, Object> with the parameters of the org
     * @param  org                      org Organization object(for this method it is required to query the IsSandbox field or it is going to fail)
     * @return                          return true if org is a sandbox or scratch or the value in the field "Sandbox" of the Static Resource gsApplicationConfiguration.
     */
    private Boolean isSandbox(Boolean overrideValuesForTesting, Map<String,Object> testingConfiguration, Organization org) {
        return overrideValuesForTesting ? (Boolean) testingConfiguration.get(SANDBOX_PARAMETER) 
                                                    : org.IsSandbox;
    }
    /**
     * @description Retrieves the application date.
     * On prod this is populated using the FeatureParameter "P10_Application_Date"
     * For QA purpose this values can be overriden if this is running on a Scratch org and there is a value in the Static Resource gsApplicationConfiguration
     * @param testingConfiguration Map<String, Object> Map of string, object with the testing configuration for overriden the returning values.
     * @return   return Application date gotten of the P10_Application_Date FeatureParameter OR the testing configuration object.
     */
    private Date getApplicationDate(Map<String, Object> testingConfiguration) {
        
        if (UTIL_Namespace.isScratchOrg() && testingConfiguration != null) { 
            return testingConfiguration.get(APPLICATION_PARAMETER) == null ? null: Date.parse(testingConfiguration.get(APPLICATION_PARAMETER).toString());
        }

        try {
            Date featureParameterDate = System.FeatureManagement.checkPackageDateValue(APPLICATION_DATE);
            return featureParameterDate == null || DEFAULT_NON_APPLICATED_DATE == featureParameterDate ? null : featureParameterDate;
        } catch (System.NoDataFoundException ex) {
            return null;
        }
    }

    /**
     * @description Retrieves the Trial expiration date.
     * On prod this is populated quering the Organization object.
     * For QA purpose this values can be overriden if this is running on a Scratch org and there is static resource called gsApplicationConfiguration
     * @param  overrideValuesForTesting Boolean true if usage of Static Resource gsApplicationConfiguration is desired
     * @param  testingConfiguration     Map<String, Object> parsed TestingConfiguration object
     * @param  org                      Organization the Organization object, the query should have included the TrialExpiration field 
     * @return                          DateTime with the expirationDate.
     */
    private DateTime getExpirationDate(Boolean overrideValuesForTesting,Map<String,Object> testingConfiguration, Organization org) {
        if (overrideValuesForTesting) {
            return  (testingConfiguration.get(TRIAL_EXPIRATION_PARAMETER) == null ? null : 
                    DateTime.parse(testingConfiguration.get(TRIAL_EXPIRATION_PARAMETER).toString()));
        } else {
            return org.TrialExpirationDate;
        }
        
    }

    /**
     * @description Returns a Map<String,Object> retrieved from a Static Resource called 'gsApplicationConfiguration'
     * @return   Map<String, Object> testing configuration after parsing the Static Resource Json
     * Examples: 
     * {"Sandbox":false} simulates an Active org.
     * {"Sandbox":false,"TrialExpiration":"10/15/2020, 00:01 am”} simulates a trial org which is not applied for licenses.
     * {"Sandbox":false,"TrialExpiration":"10/15/2020","Application":"10/02/2020"} Simulates a trial org which has applied for licenses.
     */
    private Map<String, Object> getTestingConfiguration() {
        List<StaticResource> staticResources = [SELECT Body
                                                FROM StaticResource
                                                WHERE Name = :STATIC_RESOURCE_NAME
                                               ];
        if (!staticResources.isEmpty()) {
            return (Map<String, Object>) JSON.deserializeUntyped(staticResources[0].Body.toString());
        }
        return null;
    }

    /** 
     * @description Queries the Organization object to get the TrialExpirationDate and the IsSandbox field
     * @returns Organization with TrialExpirationDate and IsSandbox queried.
     */
    private Organization getOrgInformation() {
        return [SELECT TrialExpirationDate,
                       IsSandbox
                FROM   Organization
                WITH_SECURITY_ENFORCED];
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
