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
 * @description Service class for getting the Licensing Status of the org
 */
public with sharing class GS_NonprofitTrialOrgService {

    private static final String STATIC_RESOURCE_NAME = 'GettingStartedTestingConfigurationJSON';
    private static final String APPLICATION_DATE = 'P10_Application_Date';
    private static final Date DEFAULT_NON_APPLICATED_DATE = Date.newInstance(1970,01,01);

    /**
     * @description Property for asking if the returned values has to be overriden for testing
     */
    private static Boolean overrideValuesForTesting {
        get {
            overrideValuesForTesting = shouldOverrideValuesWithTestData();
            return overrideValuesForTesting;
        } 
        private set;
    }

    /**
     * @description Property to get the testing configuration from Static Resource.
     * @return TestingConfig object with the parsed test configuration loaded from the Static Resource.
     */
    @TestVisible
    private static TestingConfig testingConfiguration {
        get {
            if (testingConfiguration != null) {
                return testingConfiguration;
            } else {
                testingConfiguration = getTestingConfiguration();
                return testingConfiguration;
            }
        }
        set {
            testingConfiguration = value;
        }
    }

    /**
     * @description Read-only property with the Org queried with the fields: IsSandbox and TrialExpirationDate.
     * @return Organization object with fields IsSandbox and TrialExpirationDate.
     */ 
    private static Organization org { 
        get {
            org = getOrgInformation();
            return org;
        }
        private set;
    }

     /**
     * @description Private Constructor. This class is not expected to be instantiated.
     */
    private GS_NonprofitTrialOrgService() {
    }

    /**
     * @description Return if the org is a Sandbox(Sandbox or Scratch).
     * @return return true if org is a sandbox or scratch or the value in the field "Sandbox" of the Static Resource GettingStartedTestingConfigurationJSON.
     */
    public static Boolean isSandbox() {
        return overrideValuesForTesting ? testingConfiguration.isSandbox : org.IsSandbox;
    }

    /**
     * @description Retrieves the application date.
     * On prod this is populated using the FeatureParameter "P10_Application_Date"
     * For QA purpose this values can be overriden if this is running on a Scratch org and there is a value in the Static Resource GettingStartedTestingConfigurationJSON
     * @return   return Application date gotten of the P10_Application_Date FeatureParameter OR the testing configuration object.
     */
    public static Date getApplicationDate() {
        
        if (UTIL_Namespace.isScratchOrg() && testingConfiguration != null) { 
            return testingConfiguration.applicationDate;
        }

        try {
            Date featureParameterDate = new UTIL_FeatureManagement().checkPackageDateValue(APPLICATION_DATE);
            return featureParameterDate == null || DEFAULT_NON_APPLICATED_DATE == featureParameterDate ? null : featureParameterDate;
        } catch (System.NoDataFoundException ex) {
            return null;
        }
    }

    /**
     * @description Retrieves the Trial expiration date.
     * On prod this is populated quering the Organization object.
     * For QA purpose this values can be overriden if this is running on a Scratch org and there is static resource called GettingStartedTestingConfigurationJSON
     * @return   DateTime with the expirationDate.
     */
    public static DateTime getExpirationDate() {
        if (overrideValuesForTesting) {
            return  testingConfiguration.trialExpiration;
        } else {
            return org.TrialExpirationDate;
        }
    }

    /**
     * @description Returns a TestingConfig object retrieved from a Static Resource called 'GettingStartedTestingConfigurationJSON'
     * @return   TestingConfig testing configuration after parsing the Static Resource Json
     * Examples: 
     * {"Sandbox":false} simulates an Active org.
     * {"Sandbox":false,"TrialExpiration":"2020-11-29T00:00:00.000Z"} simulates a trial org which is not applied for licenses.
     * {"Sandbox":false,"TrialExpiration":"2020-11-29T00:00:00.000Z", "applicationDate":"2020-10-20"} Simulates a trial org which has applied for licenses.
     */
    private static TestingConfig getTestingConfiguration() {
        List<StaticResource> staticResources = [SELECT Body
                                                FROM StaticResource
                                                WHERE Name = :STATIC_RESOURCE_NAME
                                               ];
        if (!staticResources.isEmpty()) {
            return (TestingConfig) JSON.deserialize(staticResources[0].Body.toString(), TestingConfig.class);
        }
        return null;
    }

    /**
     * @description For better testeability, we allow to override some values if the Org is a scratch org and there is an static resource called GettingStartedTestingConfigurationJSON.
     * @return   true if org is sandbox and there is a static resource GettingStartedTestingConfigurationJSON which could be deserialized as an instance of TestingConfig class.
     */
    private static Boolean shouldOverrideValuesWithTestData() { 
         return UTIL_Namespace.isScratchOrg() && testingConfiguration != null;
    }

    /** 
     * @description Queries the Organization object to get the TrialExpirationDate and the IsSandbox field
     * @return Organization with TrialExpirationDate and IsSandbox queried.
     */
    private static Organization getOrgInformation() {
        return [SELECT TrialExpirationDate,
                       IsSandbox
                FROM   Organization];
    }

    /**
     * Class used for serializing the testing configuration.
     * Which is needed to simulate several testing scenarios
     */
    public class TestingConfig {
        /**
         * Simulates the P10 licenses application date.
         */
        public Date applicationDate;
        /**
         * Indicates if a sandbox org is being simulated.
         */
        public Boolean isSandbox;
        /**
         * Simulates the trial expiration date.
         */
        public DateTime trialExpiration;

        public TestingConfig() {}

        /**
         * @description Constructor with properties. It is meant to be used in 
         * @param  applicationDate P10 application date(if it has not applied could be null)
         * @param  isSandbox       true if simulates a Sandbox, false otherwise.
         * @param  trialExpiration Simulates the trial expiration date
         * @return                 TestingConfig instance.
         */
        @TestVisible
        private TestingConfig(Date applicationDate, Boolean isSandbox, DateTime trialExpiration) {
            this.applicationDate = applicationDate;
            this.isSandbox = isSandbox;
            this.trialExpiration = trialExpiration;
        }
    }
}
