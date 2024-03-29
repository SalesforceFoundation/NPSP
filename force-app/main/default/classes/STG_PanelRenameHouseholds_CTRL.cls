/*
    Copyright (c) 2016, Salesforce.org
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
* @date 2016
* @group Settings
* @description Controller for the Batch Rename Households panel.
*/
public with sharing class STG_PanelRenameHouseholds_CTRL extends STG_Panel { 

    /**
    * @description The panel's constructor.
    */
    public STG_PanelRenameHouseholds_CTRL() {
        isRunningRenameHouseholdsBatch = false;
        isRunningAllMembersDeceasedBatch = false;
    }

    /**
    * @description Returns the string Id of the refresh household names panel. 
    */
    public override string idPanel() {
        return 'idPanelRefreshHouseholdData';
    }

    /**
    * @description Whether we are currently running the batch process 
    */
    public boolean isRunningRenameHouseholdsBatch { get; set; }
    public boolean isRunningAllMembersDeceasedBatch { get; set; }

    /**
    * @description Action Method to run the Refresh Household Names batch process
    * @return PageReference The PageReference is null regardless if an error occurs or the batch runs successfully
    */
    public PageReference runRenameHouseholdsBatch() {
        boolean isActivation = UTIL_CustomSettingsFacade.getHouseholdsSettings().npo02__Advanced_Household_Naming__c == false;

        if (isActivation) {
            if (!new STG_PanelHouseholds_CTRL().isValidSettings()) {
                return null;
            }

            STG_Panel.stgService.stgHH.npo02__Advanced_Household_Naming__c = true;
            super.saveSettings();
        }

        isRunningRenameHouseholdsBatch = true;
        isRunningAllMembersDeceasedBatch = false;
        HouseholdNamingService.refreshAllHouseholdNaming(isActivation);
        return null;
    }

    public PageReference runAllMembersDeceasedBatch() {
        isRunningAllMembersDeceasedBatch = true;
        isRunningRenameHouseholdsBatch = false;
        Database.executeBatch(new DeceasedBatch(), 200);
        return null;
    }
}