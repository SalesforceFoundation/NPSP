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
* @group Utilities
* @group-content
* @description Test for UTIL_FeatureManagement class. Mainly for code coverage since you can't assert on
* System.FeatureManagement method execution
*
*/
@isTest
public class UTIL_FeatureEnablement_TEST {

    /**
     * @description Validates that the FeatureEnablement.FeatureManagement class can be mocked to
     * force the isPilotEnabled() static method to return true
     */
    @isTest
    private static void shouldReturnTrueWhenPilotIsEnabled() {
        setPilotEnabledParameter(true);

        System.assertEquals(true, UTIL_FeatureEnablement.isPilotEnabled());
    }

    /**
     * @description Validates that the isPilotEnabled() method can be forced
     * to return True by using the OverrideFeature_PilotEnabled__c field on the Package_Settings
     * object.
     */
    @isTest
    private static void shouldReturnTrueWhenPilotIsEnabledWithOverride() {
        if (!UTIL_Namespace.isScratchOrg()) {
            return;
        }

        UTIL_CustomSettingsFacade.getErrorSettingsForTests(
            new Error_Settings__c(OverrideFeature_PilotEnabled__c = true)
        );

        System.assertEquals(true,
            UTIL_FeatureEnablement.isPilotEnabled(),
            'The Pilot should be enabled if this test is running in a scratch org');
    }

    /**
     * @description Validates that the isPilotEnabled() method can be forced
     * to return True by using the OverrideFeature_PilotEnabled__c field on the Package_Settings
     * object.
     */
    @isTest
    private static void shouldReturnFalseWhenPilotIsEnabledWithOverride() {
        if (!UTIL_Namespace.isScratchOrg()) {
            return;
        }

        System.assertEquals(false,
            UTIL_FeatureEnablement.isPilotEnabled(),
            'The Pilot should be disabled if this test is running in a scratch org');
    }

    /**
     * @description Validates that the default for the isPilotEnabled() static method is false
     */
    @isTest
    private static void shouldReturnFalseWhenPilotNotEnabled() {
        System.assertEquals(false, UTIL_FeatureEnablement.isPilotEnabled());
    }


    // Helpers
    ///////////////////

    /***
    * @description Stubs PilotEnabled feature parameter enablement
    * @param isEnabled Indicates if the PilotEnabled should be enabled using a Mock feature management
    * @return none
    */
    public static void setPilotEnabledParameter(Boolean isEnabled) {
        UTIL_FeatureEnablement featureEnablement = UTIL_FeatureEnablement.getInstance();

        featureEnablement.featureManagement = (UTIL_FeatureManagement) Test.createStub(
            UTIL_FeatureManagement.class, new UTIL_FeatureManagement_TEST.Mock()
        );

        featureEnablement.featureManagement.setPackageBooleanValue(
            UTIL_FeatureEnablement.FeatureName.PilotEnabled.name(), isEnabled
        );
    }
}