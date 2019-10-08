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
* @group Recurring Donations
* @description Controller extension for enhanced Recurring Donation enablement panel
*/
public with sharing class RD2_EnablementDelegate_CTRL extends STG_Panel {

    /***
    * @description 
    */
    public override String idPanel() { 
        return 'idPanelRD2Enablement'; 
    }

    /***
    * @description what is the namespace (an empty string if unmanaged, or 'npsp' if managed)
    */
    public string getNamespace() {
        return UTIL_Namespace.getNamespace();
    }

    /***
    * @description 
    */
    private static RD2_EnablementService service {
        get {
            if (service == null) {
                service = new RD2_EnablementService();
            }
            return service;
        }
        set;
    }

    /***
    * @description 
    */
    @AuraEnabled(cacheable=false)
    public static String loadState() {
        return JSON.serialize(getEnablementState());
    }

    /***
    * @description 
    */
    public static EnablementState getEnablementState() {
        EnablementState state = new EnablementState();

        String jsonState = UTIL_CustomSettingsFacade.getRecurringDonationsSettings().RecurringDonations2EnablementState__c;
        
        if (String.isNotBlank(jsonState)) {
            state = (EnablementState) JSON.deserialize(jsonState, EnablementState.class);
        }
        
        state.isReady = service.isRecurringDonations2Ready();
        state.isEnabled = service.isRecurringDonations2Enabled();
        state.isMetaDeployLaunched = state.isMetaDeployLaunched && state.isEnabled;
        state.isMetaDeployConfirmed = state.isMetaDeployConfirmed && state.isMetaDeployLaunched;
        state.isMigrationRun = state.isMigrationRun && state.isMetaDeployConfirmed;

        return state;
    }

    /***
    * @description 
    */
    @AuraEnabled
    public static void confirmEnablement() {
        EnablementState state = getEnablementState();
        state.isConfirmed = true;

        saveEnablementState(state);
    }

    /***
    * @description 
    */
    @AuraEnabled
    public static void launchMetaDeploy() {
        EnablementState state = getEnablementState();
        state.isMetaDeployLaunched = true;

        saveEnablementState(state);
    }

    /***
    * @description 
    */
    @AuraEnabled
    public static void confirmMetaDeploy() {
        EnablementState state = getEnablementState();
        state.isMetaDeployConfirmed = true;

        saveEnablementState(state);
    }

    /***
    * @description 
    */
    private static void saveEnablementState(EnablementState state) {  
        //do not save variables not being used from the saved enablement state   
        state.isReady = null;
        state.isEnabled = null;   

        //save the state
        STG_Panel.stgService.stgRD.RecurringDonations2EnablementState__c = JSON.serialize(state);
        upsert STG_Panel.stgService.stgRD;
    }

    /***
    * @description 
    */
    @AuraEnabled
    public static void enableEnhancement() {
        STG_Panel.stgService.stgRD.isRecurringDonations2Enabled__c = true;
        upsert STG_Panel.stgService.stgRD;
    }

    /***
    * @description 
    */
    public class EnablementState {
        public Boolean isReady = false;
        public Boolean isConfirmed = false;
        public Boolean isEnabled = false;
        public Boolean isMetaDeployLaunched = false;
        public Boolean isMetaDeployConfirmed = false;
        public Boolean isMigrationRun = false;
    }

}
