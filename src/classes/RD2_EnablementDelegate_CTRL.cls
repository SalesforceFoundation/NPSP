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

    /** @description what is the namespace (an empty string if unmanaged, or 'npsp' if managed) */
    public string getNamespace() {
        return UTIL_Namespace.getNamespace();
    }

    /***
    * @description 
    */
    @AuraEnabled
    public static String loadState() {
		RD2_EnablementService service = new RD2_EnablementService();
        EnablementState state = new EnablementState();
		
        state.isEnablementReady = service.isRecurringDonations2Ready();
        state.isEnabled = service.isRecurringDonations2Enabled();
        state.isMetaDeployCompleted = false && state.isEnabled;
        state.isMigrationCompleted = false && state.isMigrationCompleted;

        return JSON.serialize(state);
    }


    /***
    * @description 
    */
    @TestVisible private class EnablementState {
		public Boolean isEnablementReady;
		public Boolean isEnabled;
		public Boolean isMetaDeployCompleted;
		public Boolean isMigrationCompleted;
    }
}
