/*
    Copyright (c) 2014, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
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
* @author Salesforce.com Foundation
* @date 2014
* @description Install Script for the NPSP package. 
*/
global class STG_InstallScript implements InstallHandler {
    
    global void onInstall(InstallContext context) {
        try { 
            //First install of Cumulus. NPSP is a requirement to install Cumulus, so we don't need to check if it's installed
            if(context.previousVersion() == null) {
                runNewOrgScript();
                UTIL_MasterSchedulableHelper.abortOldScheduledJobs();
                UTIL_MasterSchedulableHelper.setSchedulableTable();    
            } else if(context.isUpgrade()) {
                List<Trigger_Handler__c> defaultHandlers = TDTM_DefaultConfig.getDefaultRecords(); 
                insertTdtmDefaults(defaultHandlers);
                UTIL_MasterSchedulableHelper.abortOldScheduledJobs();
                UTIL_MasterSchedulableHelper.setSchedulableTable(); 
            } else if(context.isPush()) {
                List<Trigger_Handler__c> defaultHandlers = TDTM_DefaultConfig.getDefaultRecords(); 
                insertTdtmDefaults(defaultHandlers);
                UTIL_MasterSchedulableHelper.abortOldScheduledJobs();
                UTIL_MasterSchedulableHelper.setSchedulableTable();
            }
        } catch(Exception e) {
            ERR_Notifier.sendEmailOnInstallError(e, context);
            //We cannot process the error because this hits the same "SetupOwnerId duplicates value on record" error
            //ERR_Handler.processError(e, ERR_Handler.Context.STTG);
            //We won't rethrow the exception, to avoid package failure installation due to install script error
            //throw e;
       }
    }

    /** Provides a global callable method for running the default install script to setup TDTM in new orgs **/
    global void runNewOrgScript() {      
        setTriggerConfig();

        //set default settings
        UTIL_CustomSettingsFacade.getContactsSettings(null, 'Household Account');
        UTIL_CustomSettingsFacade.getHouseholdsSettings(null, 'All New or Edited Contacts', 'All Individual Contacts', 'No Contacts');
        UTIL_CustomSettingsFacade.getRecurringDonationsSettings(null, 'Mark_Opportunities_Closed_Lost');
        UTIL_CustomSettingsFacade.getRelationshipSettings(null);
        UTIL_CustomSettingsFacade.getAffiliationsSettings(null);
        Error_Settings__c errorSettings = UTIL_CustomSettingsFacade.getErrorSettings('All Sys Admins');
        // The facade does not insert a new error settings to avoid duplicate id errors on setupOwnerId
        // when run in a test environment.  This code should always insert even if in a test
        if (errorSettings.id == null) {
            insert errorSettings;
        }
        
        UTIL_CustomSettingsFacade.getAddressValidationSettings();
        UTIL_CustomSettingsFacade.getBDESettings();        
    }
    
    public void setTriggerConfig() {
        //Get the mapping from old settings to the new TDTM default setup
        Map<String, String> npspToCumulusMap = TDTM_DefaultConfig.getNpspToCumulusMap();           
        //Read existing NPSP trigger configuration and turn off NPSP flags (so no work needs to be done next time) 
        Map<String, Boolean> existingTriggerConfig = getExistingNpspTriggerConfig(npspToCumulusMap);        
        //Setup the new configuration
        setupTdtmConfig(npspToCumulusMap, existingTriggerConfig);
    }

    private Map<String, Boolean> getExistingNpspTriggerConfig(Map<String, String> npspToCumulusMap) {
        
        Map<String, Boolean> npspExistingSettings = new Map<String, Boolean>();
        
        npe01__Contacts_And_Orgs_Settings__c npe01Settings = npe01__Contacts_And_Orgs_Settings__c.getOrgDefaults();
        npo02__Households_Settings__c npo02Settings = npo02__Households_Settings__c.getOrgDefaults();
        npe03__Recurring_Donations_Settings__c npe03Settings = npe03__Recurring_Donations_Settings__c.getOrgDefaults();
        npe4__Relationship_Settings__c npe04Settings = npe4__Relationship_Settings__c.getOrgDefaults();
        npe5__Affiliations_Settings__c npe05Settings = npe5__Affiliations_Settings__c.getOrgDefaults();
        
        for(String setting : npspToCumulusMap.keySet()) {
            if(setting.startsWith('npe01')) {
                if(npe01Settings.Id != null && npe01Settings.get(setting) != null) {
                    npspExistingSettings.put(setting, (Boolean)npe01Settings.get(setting));                 
                    if(npe01Settings.get(setting) == true)
                        npe01Settings.put(setting, false); //Deactivating flag
                    continue;
                }
            } else if(setting.startsWith('npo02')) {
                if(npo02Settings.Id != null && npo02Settings.get(setting) != null) {
                    npspExistingSettings.put(setting, (Boolean)npo02Settings.get(setting));            
                    if(npo02Settings.get(setting) == true)
                        npo02Settings.put(setting, false); //Deactivating flag
                    continue;
                }
            } else if(setting.startsWith('npe03')) {
                if(npe03Settings.Id != null && npe03Settings.get(setting) != null) {
                    npspExistingSettings.put(setting, (Boolean)npe03Settings.get(setting));                    
                    if(npe03Settings.get(setting) == true)
                        npe03Settings.put(setting, false); //Deactivating flag
                    continue;
                }
            } else if(setting.startsWith('npe4')) {
                if(npe04Settings.Id != null && npe04Settings.get(setting) != null) {
                    npspExistingSettings.put(setting, (Boolean)npe04Settings.get(setting));
                    if(npe04Settings.get(setting) == true)
                        npe04Settings.put(setting, false); //Deactivating flag
                    continue;
                }
            }
        }
        
        //Deactivate NPSP flags - getOrgDefaults returns an empty object if the custom setting has no records
        List<SObject> npspCustomSettings = new List<SObject>();
        if(npe01Settings.Id != null) npspCustomSettings.add(npe01Settings);
        if(npo02Settings.Id != null) npspCustomSettings.add(npo02Settings);
        if(npe03Settings.Id != null) npspCustomSettings.add(npe03Settings);
        if(npe04Settings.Id != null) npspCustomSettings.add(npe04Settings);
        if(npspCustomSettings.size() > 0) {
            System.debug('****Deactivating pre-cumulus flags');
            update npspCustomSettings;
        }
        
        return npspExistingSettings;
    }
    
    private void setupTdtmConfig(Map<String, String> npspToCumulusMap, Map<String, Boolean> existingTriggerConfig) {        
        List<Trigger_Handler__c> defaultHandlers = TDTM_DefaultConfig.getDefaultRecords();  
        //First we insert all TDTM records as active
        insertTdtmDefaults(defaultHandlers);   
        //Now we can deactive only those that were flagged as inactive in NPSP
        deactivateMatchingTdtm(npspToCumulusMap, existingTriggerConfig);
    }
    
    //Public just for testing purposes. Otherwise should be private
    public static void insertTdtmDefaults(List<Trigger_Handler__c> defaultHandlers) {
        List<Trigger_Handler__c> existingHandlers = [select Class__c, Object__c, Load_Order__c, Trigger_Action__c, User_Managed__c 
                                                       from Trigger_Handler__c];

        List<Trigger_Handler__c> handlersToInsert = new List<Trigger_Handler__c>();
        List<Trigger_Handler__c> handlersToUpdate = new List<Trigger_Handler__c>();
        
        //Insert those that are in the list of default handlers but aren't in the database
        for(Trigger_Handler__c defaultHandler : defaultHandlers) {
            Boolean alreadyExists = false;
            Boolean needsUpdate = false;
            for(Trigger_Handler__c existingHandler : existingHandlers) {
                if(defaultHandler.Class__c == existingHandler.Class__c && defaultHandler.Object__c == existingHandler.Object__c) {
                    alreadyExists = true;
                    //Determine if order or action has changed (compare old load order with new load order, old action with new action)
                    //Filter to only those that have not been flagged as user-managed
                    if(!existingHandler.User_Managed__c && (defaultHandler.Load_Order__c != existingHandler.Load_Order__c || 
                    defaultHandler.Trigger_Action__c != existingHandler.Trigger_Action__c)) {
                        existingHandler.Load_Order__c = defaultHandler.Load_Order__c;
                        existingHandler.Trigger_Action__c = defaultHandler.Trigger_Action__c;
                        handlersToUpdate.add(existingHandler);
                    }
                    break;
                }
            }
            if(!alreadyExists)
                handlersToInsert.add(defaultHandler); 
        }    
        if(handlersToInsert.size() > 0) insert handlersToInsert;
        if(handlersToUpdate.size() > 0) update handlersToUpdate;
    }
    
    private static void deactivateMatchingTdtm(Map<String, String> npspToCumulusMap, Map<String, Boolean> existingTriggerConfig) {
        List<String> handlerSettingsToUpdate = new List<String>();
        
        for(String flag : existingTriggerConfig.keySet()) {
            Boolean active = existingTriggerConfig.get(flag);           
            String mapsTo = npspToCumulusMap.get(flag);         
            if(active)
               handlerSettingsToUpdate.add(mapsTo);
        }
        
        List<Trigger_Handler__c> handlersToUpdate = [select Active__c, Class__c from Trigger_Handler__c where Class__c 
                                                     IN :handlerSettingsToUpdate];
        for(Trigger_Handler__c handler : handlersToUpdate) {
            //System.debug('****Deactivating class: ' + handler.Class__c);
            handler.Active__c = false;
        }
        if(handlersToUpdate.size() > 0) update handlersToUpdate; 
    }
}