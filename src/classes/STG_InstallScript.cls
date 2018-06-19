/*
    Copyright (c) 2014, Salesforce.org
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
* @date 2014
* @group Settings
* @description Install Script for the NPSP package. 
*/
global without sharing class STG_InstallScript implements InstallHandler {
    
    @TestVisible
    private enum InstallAction { 
        POPULATE_RD_INSTALLMENT_NUMBER, RUN_NEW_ORG_SCRIPT, 
        INSERT_TDTM_DEFAULTS, ABORT_OLD_SCHEDULED_JOBS, 
        CLEANUP_RECORD_TYPE_SETTINGS, UPDATE_CAMPAIGN_LIST_REPORT,
        CREATE_DEFAULT_SETTINGS
    }

    /*******************************************************************************************************
    * @description Runs on package install.
    * @param context The install context.
    * @return void
    */
    global void onInstall(InstallContext context) {
        ErrorLogger logger = new ErrorLogger(context, ERR_Handler_API.Context.STTG);
                     
        //First install of Cumulus. NPSP is a requirement to install Cumulus, so we don't need to check if it's installed
        if (context.previousVersion() == null) {
            //Populate Recurring Donation Installment Number on Opportunity for fresh installs; 
            //This also covers upgrades from v2
            executeAction(InstallAction.POPULATE_RD_INSTALLMENT_NUMBER, logger);
            
            executeAction(InstallAction.RUN_NEW_ORG_SCRIPT, logger);

        } else if (context.isUpgrade() || context.isPush()) {
            executeAction(InstallAction.CREATE_DEFAULT_SETTINGS, logger);

            executeAction(InstallAction.INSERT_TDTM_DEFAULTS, logger);
        }

        executeAction(InstallAction.ABORT_OLD_SCHEDULED_JOBS, logger);

        if (context.previousVersion() == null || context.previousVersion().compareTo(new Version(3, 79)) < 0) {
            executeAction(InstallAction.CLEANUP_RECORD_TYPE_SETTINGS, logger);
        }

        if (context.previousVersion() == null || context.previousVersion().compareTo(new Version(3, 112)) < 0) {
            executeAction(InstallAction.UPDATE_CAMPAIGN_LIST_REPORT, logger);
        }

        logger.log();
    }

    private void executeAction(InstallAction action, ErrorLogger logger) {

        Savepoint sp = Database.setSavepoint();  

        try {
            if (action == InstallAction.POPULATE_RD_INSTALLMENT_NUMBER) {
                database.executeBatch(new RD_InstallScript_BATCH(), 10);

            } else if (action == InstallAction.RUN_NEW_ORG_SCRIPT) {
                runNewOrgScript();

            } else if (action == InstallAction.INSERT_TDTM_DEFAULTS) {
                insertTdtmDefaults(null);

            } else if (action == InstallAction.ABORT_OLD_SCHEDULED_JOBS) {
                UTIL_MasterSchedulableHelper.abortOldScheduledJobs();

            } else if (action == InstallAction.CLEANUP_RECORD_TYPE_SETTINGS) {
                UTIL_RecordTypeSettingsUpdate.getInstance().updateSettings();

            } else if (action == InstallAction.UPDATE_CAMPAIGN_LIST_REPORT) {
                updateCampaignListReport();

            } else if (action == InstallAction.CREATE_DEFAULT_SETTINGS) {
                createNewDefaultCustomSettingRecords();

            }

        } catch(Exception e) {
            Database.rollback(sp);
            
            logger.add(e);
        } 
    }

    /*******************************************************************************************************
    * @description Sets up TDTM in new orgs. Also called by the NPSP Settings page on page load (i.e., this method
    * runs every single time the NPSP Settings page is loaded).
    * @return void
    */
    global void runNewOrgScript() {      
        //Get the mapping from old settings to the new TDTM default setup
        Map<String, String> npspToCumulusMap = TDTM_DefaultConfig.getNpspToCumulusMap();           
        //Read existing NPSP trigger configuration and turn off NPSP flags (so no work needs to be done next time) 
        Map<String, Boolean> existingTriggerConfig = getExistingNpspTriggerConfig(npspToCumulusMap);        
        //Setup the new configuration
        setupTdtmConfig(npspToCumulusMap, existingTriggerConfig);
    }

    /*******************************************************************************************************
    * @description NPSP Version 3.112 changed the report distributed and used for the Campaign Household Mailing
    * List report launched by the HH_CampaignDedupeBTN VF page (from a custom button). The old report previously
    * installed as part of the Households package is not Lightning compatible, requiring a new report.
    * @return void
    */
    private void updateCampaignListReport() {
        npo02__Households_Settings__c hs = UTIL_CustomSettingsFacade.getHouseholdsSettings();
        Report r;
        try{
            r = [SELECT Id FROM Report WHERE DeveloperName = 'NPSP_Campaign_Household_Mailing_List_V2'];
        } catch(QueryException e) {
            // Ignore this error
        }
        if (r != null && hs.npo02__Household_Mailing_List_ID__c != r.Id) {
            hs.npo02__Household_Mailing_List_ID__c = r.Id;
            update hs;
        }
    }

    /*******************************************************************************************************
     * @description Called only during a new install of v3 by runNewOrgScript() to configure the default NPSP TDTM
     * Trigger Configuration. This could involve removing legacy TDTM entries as well.
     * @param npspToCumulusMap
     * @return
     */
    private Map<String, Boolean> getExistingNpspTriggerConfig(Map<String, String> npspToCumulusMap) {
        
        Map<String, Boolean> npspExistingSettings = new Map<String, Boolean>();
        
        npe01__Contacts_And_Orgs_Settings__c npe01Settings = UTIL_CustomSettingsFacade.getOrgContactsSettings();
        npo02__Households_Settings__c npo02Settings = UTIL_CustomSettingsFacade.getOrgHouseholdsSettings();
        npe03__Recurring_Donations_Settings__c npe03Settings = UTIL_CustomSettingsFacade.getOrgRecurringDonationsSettings();
        npe4__Relationship_Settings__c npe04Settings = UTIL_CustomSettingsFacade.getOrgRelationshipSettings();
        npe5__Affiliations_Settings__c npe05Settings = UTIL_CustomSettingsFacade.getOrgAffiliationsSettings();
        UTIL_CustomSettingsFacade.getOrgHouseholdNamingSettings();
        UTIL_CustomSettingsFacade.getOrgErrorSettings();
        UTIL_CustomSettingsFacade.getOrgAddressVerificationSettings();
        UTIL_CustomSettingsFacade.getOrgBDESettings();
        UTIL_CustomSettingsFacade.getOrgAllocationsSettings();
        UTIL_CustomSettingsFacade.getOrgDataImportSettings();

        UTIL_Debug.debug('****NPSP-to-Cumulus Map: ' + JSON.serializePretty(npspToCumulusMap));
 
        for(String setting : npspToCumulusMap.keySet()) {
            if(setting.startsWith('npe01')) {
                if(npe01Settings != null && npe01Settings.get(setting) != null) {
                    //Storing the old setting as key and new setting as value
                    npspExistingSettings.put(setting, (Boolean)npe01Settings.get(setting));
                    if(npe01Settings.get(setting) == true)
                        npe01Settings.put(setting, false); //Deactivating flag
                    continue;
                }
            } else if(setting.startsWith('npo02')) {
                if(npo02Settings != null && npo02Settings.get(setting) != null) {
                    npspExistingSettings.put(setting, (Boolean)npo02Settings.get(setting));            
                    if(npo02Settings.get(setting) == true)
                        npo02Settings.put(setting, false); //Deactivating flag
                    continue;
                }
            } else if(setting.startsWith('npe03')) {
                if(npe03Settings != null && npe03Settings.get(setting) != null) {
                    npspExistingSettings.put(setting, (Boolean)npe03Settings.get(setting));
                    if(npe03Settings.get(setting) == true)
                        npe03Settings.put(setting, false); //Deactivating flag
                    continue;
                }
            } else if(setting.startsWith('npe4')) {
                if(npe04Settings != null && npe04Settings.get(setting) != null) {
                    npspExistingSettings.put(setting, (Boolean)npe04Settings.get(setting));
                    if(npe04Settings.get(setting) == true)
                        npe04Settings.put(setting, false); //Deactivating flag
                    continue;
                }
            }
        }
        
        //Deactivate NPSP flags - getInstance returns an empty object if the custom setting has no records
        List<SObject> npspCustomSettings = new List<SObject>();
        if(npe01Settings != null) npspCustomSettings.add(npe01Settings);
        if(npo02Settings != null) npspCustomSettings.add(npo02Settings);
        if(npe03Settings != null) npspCustomSettings.add(npe03Settings);
        if(npe04Settings != null) npspCustomSettings.add(npe04Settings);
        if(npspCustomSettings.size() > 0) {
            UTIL_Debug.debug('****Deactivating pre-cumulus flags');
            if(!Test.isRunningTest())
                update npspCustomSettings;
        }
        
        return npspExistingSettings;
    }
    
    private void setupTdtmConfig(Map<String, String> npspToCumulusMap, Map<String, Boolean> existingTriggerConfig) {        
        //First we insert all TDTM records as active
        insertTdtmDefaults(null);   
        //Now we can deactive only those that were flagged as inactive in NPSP
        deactivateMatchingTdtm(npspToCumulusMap, existingTriggerConfig);
    }
    
    /*******************************************************************************************************
    * @description Inserts the default TDTM records, if necessary. Updates those that need to be updated, since the last package
    * upgrade. Public just for testing purposes (it should otherwise be private).
    * @return void
    */
    public static void insertTdtmDefaults(List<Trigger_Handler__c> defaultHandlers) {
        if (defaultHandlers == null) defaultHandlers = TDTM_DefaultConfig.getDefaultRecords();  
        List<Trigger_Handler__c> existingHandlers = [select Class__c, Object__c, Load_Order__c, Trigger_Action__c, User_Managed__c 
                                                       from Trigger_Handler__c];

        List<Trigger_Handler__c> handlersToInsert = new List<Trigger_Handler__c>();
        List<Trigger_Handler__c> handlersToUpdate = new List<Trigger_Handler__c>();
        List<Trigger_Handler__c> handlersToDelete = new List<Trigger_Handler__c>();

        //First, find handlers to add them for deletion and remove them from the list
        Integer i = 0;
        while(i < existingHandlers.size()) {
            if (TDTM_DefaultConfig.deletedClasses.contains(existingHandlers[i].Class__c)) {
                handlersToDelete.add(existingHandlers[i]);
                existingHandlers.remove(i);
            } else {
                i++;
            }
        }
        
        //Insert those that are in the list of default handlers but aren't in the database
        for(Trigger_Handler__c defaultHandler : defaultHandlers) {
            Boolean alreadyExists = false;
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
        if(handlersToDelete.size() > 0) delete handlersToDelete;
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
            handler.Active__c = false;
        }
        if(handlersToUpdate.size() > 0) update handlersToUpdate; 
    }

    /*******************************************************************************************************
     * @description Ensure that any default Custom Settings Records are created for "new" custom settings objects
     * added
     */
    private static void createNewDefaultCustomSettingRecords() {
        UTIL_CustomSettingsFacade.getOrgCustomizableRollupSettings();
        updateDefaultOrgContactsSettings();
    }

    /*******************************************************************************************************
     * @description Ensure that any default Org Contacts Settings Records are updated for custom settings
     * objects accordingly.
     */
     public static void updateDefaultOrgContactsSettings() {
        npe01__Contacts_And_Orgs_Settings__c npe01Settings = UTIL_CustomSettingsFacade.getOrgContactsSettings();
        if (npe01Settings.Contact_Role_for_Organizational_Opps__c == null) {
            npe01Settings.Contact_Role_for_Organizational_Opps__c = UTIL_CustomSettingsFacade.DEFAULT_OPPORTUNITY_CONTACT_ROLE_SOFT_CREDIT;
            update npe01Settings;
        }
    }

    /*******************************************************************************************************
    * @description Collects exceptions. Logs exceptions by sending an email and processing error via ERR_Handler.
    */
    public class ErrorLogger {
        /** @description The install context. */
        InstallContext installContext;

        /** @description The error handler context. */
        ERR_Handler_API.Context errContext;

        /** @description The list of exceptions. */
        List<Exception> exceptions = new List<Exception>();

        /*******************************************************************************************************
        * @description The constructor
        * @param installContext The install context
        * @param errContext The error handler context
        */
        public ErrorLogger(InstallContext installContext, ERR_Handler_API.Context errContext) {
            this.installContext = installContext;
            this.errContext = errContext;
        }

        /*******************************************************************************************************
        * @description Returns true if the logger has at least one exception stored
        * @return Boolean
        */
        public Boolean hasErrors() {
            return !exceptions.isEmpty();
        }

        /*******************************************************************************************************
        * @description Adds the exception to the list of exceptions
        * @param e The Exception
        * @return void
        */
        public void add(Exception e) {
            if (e != null) {
                exceptions.add(e);
            }
        }

        /*******************************************************************************************************
        * @description Logs the exception by sending an email and processing the errors via ERR_Handler
        * @return void
        */
        public void log() {
            if (!hasErrors()) {
                return;
            }

            sendEmail();
            ERR_Handler.processErrors(exceptions, errContext);
        }

        /*******************************************************************************************************
        * @description Sends an email to the user installing the package notifying them about failed installation steps.
        * @return void
        */
        private void sendEmail() {
            try {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setUseSignature(false);
                mail.setReplyTo('donotreply@salesforce.org');
                mail.setSenderDisplayName('Nonprofit Success Pack');
                mail.setSubject('NPSP Install Errors');

                mail.setPlainTextBody(buildEmailBody());  

                mail.setToAddresses(new String[] { 'errors@salesforce.org', getUserEmail() });

                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

            } catch(Exception e) {
                //Nothing to do here, as we don't want the install script to fail because emails could not be sent.
            }

        }

        /*******************************************************************************************************
        * @description Retrieves the installing user email
        * @return String
        */
        private String getUserEmail() {
            String userEmail = [SELECT Id, Email FROM User WHERE Id =:installContext.installerID()].Email;  
            return UTIL_Namespace.sandboxEmailToRealEmail(userEmail);
        }

        /*******************************************************************************************************
        * @description Builds email body by displaying exception messages and stack traces.
        * @return String
        */
        @TestVisible
        private String buildEmailBody() {
            String bodyString = Label.stgInstallScriptError;

            bodyString += String.format(
                '\n\n==========================. \n\nError message{0}:',
                new String[] { exceptions.size() == 1 ? '' : 's'}
            );

            for (Exception e : exceptions) {
                bodyString += '\n' + e.getMessage() +
                    '\nError stack trace: \n' + e.getStackTraceString() + 
                    '\n\n';
            }

            return bodyString;
        }

    }
}
