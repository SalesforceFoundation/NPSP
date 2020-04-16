/*
    Copyright (c) 2019, Salesforce.org
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
* @description Services ready to feature enablement within NPSP via LmoToSubscriber Feature Parameters
*/
public without sharing class UTIL_FeatureEnablement {

    /**
     * @description Define the specific FeatureParameter ApiNames that are supported in FeatureEnablement
     */
    public enum FeatureName {
        PilotEnabled
    }

    @TestVisible
    private UTIL_FeatureManagement featureManagement = new UTIL_FeatureManagement();

    private static UTIL_FeatureEnablement featureEnablement;

    public static UTIL_FeatureEnablement getInstance() {
        if (featureEnablement == null) {
            featureEnablement = new UTIL_FeatureEnablement();
        }
        return featureEnablement;
    }

    /**
     * @description public implementation to determine if the PilotEnabled has been enabled 
     * in the License Management Org (Wilma) for the current org (by OrgId)
     * @return Boolean The PilotEnabled FeatureParameter value or its override on the scratch org (if any)
     */
    public static Boolean isPilotEnabled() {
        Boolean isPilotEnabled = UTIL_FeatureEnablement.getInstance().isEnabled(FeatureName.PilotEnabled.name());

        if (!isPilotEnabled && UTIL_FeatureEnablement.getInstance().isOverridePilotEnabled()) {
            isPilotEnabled = true;
        }

        return isPilotEnabled;
    }

    /**
     * @description Retrieve a boolean as "IsEnabled" for the specified Feature Parameter api name
     * @param apiName
     * @return Boolean
     */
    @TestVisible
    private Boolean isEnabled(String apiName) {
        return featureManagement.checkPackageBooleanValue(apiName);
    }

    /**
     * @description If the code is currently executing in a Scratch Org, it's possible to override
     * the PilotEnabled feature parameter using the Package_Settings protected custom settings object.
     * @return True if the PilotEnabled feature parameter is overridden
     */
    private Boolean isOverridePilotEnabled() {
        Boolean isPilotOverride = false;

        if (UTIL_Namespace.isScratchOrg()) {
            Error_Settings__c errSettings = UTIL_CustomSettingsFacade.getOrgErrorSettings();
            isPilotOverride = (errSettings.OverrideFeature_PilotEnabled__c == true);
        }

        return isPilotOverride;
    }
}