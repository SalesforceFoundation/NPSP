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
* @group Recurring Donations
* @description Enhanced Recurring Donations Enablement Service class
*
*/
public with sharing class RD2_EnablementService {

    /**
     * @description Enhanced Recurring Donation enablement service instance
     */
    @TestVisible
    private static RD2_EnablementService enablementService;

    /**
     * @description Returns enhanced Recurring Donation enablement service instance
     * @return RD2_EnablementService Enhanced Recurring Donation enablement service
     */
    public static RD2_EnablementService getInstance() {
        if (enablementService == null) {
            enablementService = new RD2_EnablementService();
        }
        return enablementService;
    }

    /**
     * @description Returns true if enhanced Recurring Donations are enabled
     */
    public static Boolean isRecurringDonations2Enabled {
        get {
            return RD2_EnablementService.getInstance().isRecurringDonations2Enabled();
        }
        private set;
    }
    
    /**
     * @description Returns true if enhanced Recurring Donations are enabled regardless of configuration
     */
    public static Boolean isRecurringDonations2EnabledOverride = false;

    /***
    * @description Contains attribute confirming if LEX is enabled
    */
    @TestVisible
    private static Boolean isUserRunningLightning {
        get {
            if (isUserRunningLightning == null) {
                isUserRunningLightning = USER_UserService.isUserRunningLightning();
            }
            return isUserRunningLightning;
        }
        set;
    }
    /***
    * @description Contains attribute confirming if PilotEnabled feature parameter is enabled
    */
    public Boolean isPilotEnabled {
        get {
            if (isPilotEnabled == null) {
                isPilotEnabled = UTIL_FeatureEnablement.isRecurringDonations2PilotEnabled();
            }
            return isPilotEnabled;
        }
        set;
    }
    
    /***
    * @description Returns true if enhanced Recurring Donations can be enabled
    * @return Boolean
    */
    public Boolean isRecurringDonations2Ready() {
        return 
            STG_Panel.stgService.stgCRLP.Customizable_Rollups_Enabled__c == true
            && isUserRunningLightning
            && isPilotEnabled;
    }
    
    /***
    * @description Returns true if enhanced Recurring Donations are enabled
    * @return Boolean
    */
    public Boolean isRecurringDonations2Enabled() {
        if (isRecurringDonations2EnabledOverride) {
            return true;
        }

        return 
            UTIL_CustomSettingsFacade.getRecurringDonationsSettings().isRecurringDonations2Enabled__c == true
            && isPilotEnabled;
    }
}