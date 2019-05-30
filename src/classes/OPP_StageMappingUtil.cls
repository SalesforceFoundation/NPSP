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
* @group Opportunity
* @group-content ../../ApexDocContent/Opportunity.htm
* @description API Class to allow caller to determine Opportunity's State (Uncommitted, Committed. or Finalized) using the Opportunities Stage
*/
public with sharing class OPP_StageMappingUtil {

    /******************************************************************************************************
    * @description Represents the overall state of the Opportunity.
    * UNCOMMITTED -- Donor has not yet agreed to make the donation.  Donation is unpaid.  This is useful
    * for soliciting or staging gifts.
    * COMMITTED --  Donor has agreed to make a donation.  Donation can be unpaid or partially paid.
    * More money is still expected from the donor.
    * FINALIZED -- Donation is completely received.  Donation can be fully or partially paid.  No more
    * money is expected for the donation.
    */
    @testVisible private static final String UNCOMMITTED_STATE_VAL = 'UNCOMMITTED';
    @testVisible private static final String COMMITTED_STATE_VAL = 'COMMITTED';
    @testVisible private static final String FINALIZED_STATE_VAL = 'FINALIZED';
    private static final String OPP_STAGE_TO_STATE_METADATA_NAME = 'Opportunity_Stage_To_State_Mapping__mdt';
    private static final String OPP_STAGE_FIELD = 'Opportunity_Stage__c';
    private static final String OPP_STATE_FIELD = 'Opportunity_State__c';

    /******************************************************************************************************
    * @description Used to Cache Set of Opportunity Stages that mean Opportunity is in a Committed State.
    */
    private static Set<String> COMMITTED_STATE_SET = null;

    /******************************************************************************************************
    * @description Used to Cache Set of Opportunity Stages that mean Opportunity is in a Finalized State.
    */
    private static Set<String> FINALIZED_STATE_SET = null;

    /*******************************************************************************************************
    * @description Determines the Opportunity State (UNCOMMITTED, COMMITTED, or FINALIZED) from the
    * Opportunity Stage.  If the Opportunity Stage does not map to a FINALIZED or COMMITTED state,
    * based on the Household Settings, it will return UNCOMMITTED.  It will always return UNCOMMITTED
    * if the settings are not configured.  It first checks the Opportunity Stage is a FINALIZED stage.  If
    * it is, it returns FINALIZED.  If it is not, it checks to see if the Opportunity Stage is a COMMITTED
    * stage.  If it is, it returns COMMITTED.  Otherwise, it returns UNCOMMITTED.
    *
    * NOTE: Opportunity Stage is treated as Case Insensitive, so Closed Won CLOSED WON and closed won are
    * all the same for this purpose.
    * @param String opportunityStage The opportunity stage to check the state of
    * @return String value representing the current opportunity state
    ********************************************************************************************************/
    public static String determineOppStateFromOppStage(String opportunityStage) {

        initializeStates();

        String oppStageToCheck = String.isNotBlank(opportunityStage) ? opportunityStage.trim().toLowerCase() : null;

        if (FINALIZED_STATE_SET != null && FINALIZED_STATE_SET.contains(oppStageToCheck)) {
            return FINALIZED_STATE_VAL;
        }

        if (COMMITTED_STATE_SET != null && COMMITTED_STATE_SET.contains(oppStageToCheck)) {
            return COMMITTED_STATE_VAL;
        }

        return UNCOMMITTED_STATE_VAL;
    }

    /*******************************************************************************************************
    * @description initializes the Opportunity State Sets, used by other parts of this class, if
    * necessary.
    ********************************************************************************************************/
    @testVisible private static void initializeStates() {
        // These are temporary values to be used only during interim for internal development on Abacus project.
        // This will be updated in March 2019 timeframe with revised code to retrieve from Custom Metadata instead
        // COMMITTED_STATE_SET = new Set<String> {'closed won'};
        // FINALIZED_STATE_SET = new Set<String> {'finalized'};

        // If either the committed state set or the finalized state set is null, query for everything and 
        // reinitialize everything. 
        if (COMMITTED_STATE_SET == null || FINALIZED_STATE_SET == null) {
            COMMITTED_STATE_SET = new Set<String>();
            FINALIZED_STATE_SET = new Set<String>();

            List<Opportunity_Stage_To_State_Mapping__mdt> stageToStateRecords = [Select Id, Opportunity_Stage__c, Opportunity_State__c FROM Opportunity_Stage_To_State_Mapping__mdt];

            for (Opportunity_Stage_To_State_Mapping__mdt mappingRecord : stageToStateRecords) {
                String oppStage = mappingRecord.Opportunity_Stage__c.trim().toLowerCase();

                if (mappingRecord.Opportunity_State__c.trim().toLowerCase() == 'committed') {
                    COMMITTED_STATE_SET.add(oppStage);
                } else {
                    FINALIZED_STATE_SET.add(oppStage);
                }
            }
        }
    }

    public static void createFinalizedOppStageToStateRecord() {
        npe01__Contacts_And_Orgs_Settings__c contactAndOrgCustomSetting = UTIL_CustomSEttingsFacade.getOrgContactsSettings();

        // Only create the finalized opp stage to state record if there's no existing finalized record. 
        Integer finalizedCount = [Select Count() From Opportunity_Stage_To_State_Mapping__mdt Where Opportunity_State__c =: FINALIZED_STATE_VAL];
        
        // Take the value, if there is one, and create a finalized Opp Stage to State custom metadata type record. 
        if (finalizedCount == 0 && 
            (contactAndOrgCustomSetting.Payments_Auto_Close_Stage_Name__c != null && 
            contactAndOrgCustomSetting.Payments_Auto_Close_Stage_Name__c != '')) {
            
            String mdTypeName = UTIL_Namespace.StrTokenNSPrefix(OPP_STAGE_TO_STATE_METADATA_NAME);
            String recordName = FINALIZED_STATE_VAL;

            // Setup custom metadata to be created or updated in the subscriber org.
            Metadata.CustomMetadata customMd = new Metadata.CustomMetadata();
            customMd.fullName = mdTypeName + '.' + recordName;
            customMd.label = FINALIZED_STATE_VAL;
            customMd.protected_x = false;

            Map<String, Object> fieldMapping = new Map<String, Object>();
            Map<String, Object> params = new Map<String, Object>();
            fieldMapping.put(OPP_STAGE_FIELD, contactAndOrgCustomSetting.Payments_Auto_Close_Stage_Name__c);
            fieldMapping.put(OPP_STATE_FIELD, FINALIZED_STATE_VAL);

            Metadata.CustomMetadata md = new Metadata.CustomMetadata();
            md = CMT_MetadataAPI.addFieldsToMetadataObject(customMd, fieldMapping);

            List<Metadata.CustomMetadata> metadataToInsert = new List<Metadata.CustomMetadata>();
            metadataToInsert.add(md);
            
            // Deploy the metadata 
            String jobId = CMT_MetadataAPI.getUniqueJobId();
            CMT_MetadataAPI.MetadataCallbackHandler oppCallbackHandler = new OppStageToStateMetadataHandler();
            CMT_MetadataAPI.MetadataCallBack callback = new CMT_MetadataAPI.MetadataCallBack(jobId);
            callback.callbackHandler = oppCallbackHandler;
            callback.callbackParams = params;

            CMT_MetadataAPI.deployMetadata(metadataToInsert, callback);
        }
    }

    public class OppStageToStateMetadataHandler implements CMT_MetadataAPI.MetadataCallbackHandler {

        public Map<String, Object> params;


        /**************************************************************************************************************
        * @description success handler - will call the ApiService to set rollus as stale 
        /*************************************************************************************************************/
        public void performSuccessHandler(Map<String, Object> params) {
            if (params == null || params.isEmpty()) {
                return;
            }

            try {
                // Process a successful 
            } catch (Exception ex) {
                logError(ex);
            }
        }

        public void performErrorHandler(Map<String, Object> params) {
            if (params == null || params.isEmpty()) {
                return;
            }

            try {
                // Handle error 
            } catch (Exception ex) {
                logError(ex);
            }
        }


        /**
        * @description Inserts an error log into the Error table
        * @param ex Exception object that is to be logged
        */
        private void logError(Exception ex) {
            Error__c rollupHandlerError = new Error__c(
                Error_Type__c = 'Opportunity Stage to State Metadata Handler Error',
                Object_Type__c = 'CustomMetadata',
                Context_Type__c = ERR_Handler_API.Context.OPP.name(),
                Datetime__c = System.now(), 
                Full_Message__c = ex.getMessage()
            );

            Database.insert(rollupHandlerError, true);
        }
    }
}