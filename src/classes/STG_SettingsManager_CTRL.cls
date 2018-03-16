/*
    Copyright (c) 2015 Salesforce.org
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
* @date 01/13/2014
* @group Settings
* @description controller for the Settings Manager page
*/

public with sharing class STG_SettingsManager_CTRL extends STG_Panel {
    
    /*********************************************************************************************************
    * @description The controller's constructor 
    */
    public STG_SettingsManager_CTRL() {
        String landingPage = System.currentPageReference().getParameters().get('panel');
        if (!String.isBlank(landingPage)) {
            idPanelCurrent = landingPage;
        } else {
            idPanelCurrent = 'idPanelHome';
        }
    }

    /*********************************************************************************************************
    * @description Returns the string Id of the current panel. 
    */
    public static string idPanelCurrent { get; set; }
   
    /*********************************************************************************************************
    * @description Action Method called by javascript when idPanelCurrent has been changed.
    * @return null 
    */
    public PageReference setPanelCurrent() {
        // javascript caller auto-assigns to idPanelCurrent,
        // so nothing to do in this method. 
        return null;
    }

    /*********************************************************************************************************
    * @description Action Method that runs the install script to setup TDTM, initializes the 
    * Schedulables configuration and fixes invalid Record Types. 
    * Called by the Settings page's action property when it first loads.
    * @return void 
    */
    public void onNpspSettingsLoad() {
        //Set TDTM config
        STG_InstallScript installScript = new STG_InstallScript();
        installScript.runNewOrgScript();

        UTIL_MasterSchedulableHelper.abortOldScheduledJobs();

       if (STG_Panel.runningUserIsAdmin()) {
            cleanupRecordTypeSettings();

            UTIL_MasterSchedulableHelper.setScheduledJobs();
        }
    }
    
    /*********************************************************************************************************
    * @description Clean up invalid Record Type Settings
    * @return void 
    */
    private void cleanupRecordTypeSettings() {
        try {
            UTIL_RecordTypeSettingsUpdate.getInstance().updateSettings();

        } catch(Exception e) {
            //Do not rollback the transaction so settings before the error are still fixed
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));

        } finally {
            //Not only refresh the custom settings  
            STG_Panel.stgService = null; 
            //but also refresh affected custom settings explicitly since all properties are static. 
            UTIL_CustomSettingsFacade.reloadCustomSettingsOnRecordTypeCleanup();
        }
    }

}