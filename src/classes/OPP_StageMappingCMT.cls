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
* @description API Class to allow caller to create Custom Metadata Type record, which will be used to determine Opportunity's State (Uncommitted, Committed. or Finalized) using the Opportunities Stage
*/
public with sharing class OPP_StageMappingCMT {
    private static final String COMMITTED_STATE_VAL = 'COMMITTED';
    private static final String FINALIZED_STATE_VAL = 'FINALIZED';
    private static final String OPP_STAGE_TO_STATE_METADATA_NAME = 'Opportunity_Stage_To_State_Mapping__mdt';
    private static final String OPP_STAGE_FIELD = 'Opportunity_Stage__c';
    private static final String OPP_STATE_FIELD = 'Opportunity_State__c';
    private static final String PLEDGED_STAGE = 'PLEDGED';

    public OPP_StageMappingCMT() {

    }

    /*******************************************************************************************************
    * @description Creates the finalized state record if there are no finalized records. It utilizes the 
    * "Opportunity Stage when Fully Paid" field (If it's populated) as the Opportunity stage for the finalized state. 
    * @param List<Metadata.CustomMetadata> metadataToInsert A running list of custom metadata that is going to be inserted,
    * the created record will be added into this list. 
    * @return List<Metadata.CustomMetadata> A running list of custom metadata to be inserted. 
    ********************************************************************************************************/
    public static List<Metadata.CustomMetadata> createFinalizedOppStageToStateRecord(List<Metadata.CustomMetadata> metadataToInsert) {
        npe01__Contacts_And_Orgs_Settings__c contactAndOrgCustomSetting = UTIL_CustomSEttingsFacade.getOrgContactsSettings();

        // Only create the finalized opp stage to state record if there's no existing finalized record. 
        Integer finalizedCount = [SELECT Count() FROM Opportunity_Stage_To_State_Mapping__mdt Where Opportunity_State__c =: FINALIZED_STATE_VAL LIMIT 1];
        
        // Take the value, if there is one, and create a finalized Opp Stage to State custom metadata type record. 
        if (finalizedCount == 0 && 
            (contactAndOrgCustomSetting.Payments_Auto_Close_Stage_Name__c != null && 
            contactAndOrgCustomSetting.Payments_Auto_Close_Stage_Name__c != '')) {
            
            metadataToInsert.add(createCustomMetadata(contactAndOrgCustomSetting.Payments_Auto_Close_Stage_Name__c, FINALIZED_STATE_VAL));
        }

        return metadataToInsert;
    }

    /*******************************************************************************************************
    * @description Creates the initial Opportunity Stage to State record if there are no existing records. 
    * When there are no existing records, it will create a new "Committed" state record for a "Pledged" stage
    * if there is one. 
    * @param List<Metadata.CustomMetadata> metadataToInsert A running list of custom metadata that is going to be inserted,
    * the created record will be added into this list. 
    * @return List<Metadata.CustomMetadata> A running list of custom metadata to be inserted. 
    ********************************************************************************************************/
    public static List<Metadata.CustomMetadata> createPledgedOppStageToStateRecord(List<Metadata.CustomMetadata> metadataToInsert) {
        npe01__Contacts_And_Orgs_Settings__c contactAndOrgCustomSetting = UTIL_CustomSEttingsFacade.getOrgContactsSettings();

        
        Integer overallCount = [SELECT Count() FROM Opportunity_Stage_To_State_Mapping__mdt LIMIT 1];

        if (overallCount == 1) {
            return metadataToInsert;
        }

        // Get all opportunity stages to see if there is a pledged stage
        Schema.DescribeFieldResult fieldResult = Opportunity.StageName.getDescribe();
        List<Schema.PicklistEntry> picklistEntryList = fieldResult.getPicklistValues();
        Boolean hasPledgedValue = false;
        String normalPledgeValue = '';

        for (Schema.PicklistEntry picklistEntry : picklistEntryList) {
            if (picklistEntry.getValue().toUpperCase() == PLEDGED_STAGE) {
                normalPledgeValue = picklistEntry.getValue();
                hasPledgedValue = true;
                break;
            }
        }       
        
        // Take the value, if there is one, and create a Committed Opp Stage to State custom metadata type record. 
        // Only create the pledged opp stage to state record if there's no existing opportunity stage to state records at all. 
        if (overallCount == 0 && hasPledgedValue) {
            metadataToInsert.add(createCustomMetadata(normalPledgeValue, COMMITTED_STATE_VAL));
        }

        return metadataToInsert;
    }

    /*******************************************************************************************************
    * @description Creates a custom metadata record based on the parameters provided to the method. 
    * @param String oppStage The opportunity stage that will be mapped in the custom metadata record. 
    * @param String oppState The opportunity state that will be mapped in the custom metadata record. 
    * @return Metadata.CustomMetadata The created custom metadata record with the mapped Opportunity stage and state
    ********************************************************************************************************/
    public static Metadata.CustomMetadata createCustomMetadata(String oppStage, String oppState) {        
        Metadata.CustomMetadata customMd = new Metadata.CustomMetadata();
        String mdTypeName = UTIL_Namespace.StrTokenNSPrefix(OPP_STAGE_TO_STATE_METADATA_NAME);

        customMd.fullName =  mdTypeName + '.' + oppState + '_' + datetime.now().getTime();
        customMd.label = oppState + '_' + datetime.now().getTime();
        customMd.protected_x = false;

        Map<String, Object> fieldMapping = new Map<String, Object>();
        fieldMapping.put(UTIL_Namespace.StrTokenNSPrefix(OPP_STAGE_FIELD), oppStage);
        fieldMapping.put(UTIL_Namespace.StrTokenNSPrefix(OPP_STATE_FIELD), oppState);

        Metadata.CustomMetadata md = new Metadata.CustomMetadata();
        md = CMT_MetadataAPI.addFieldsToMetadataObject(customMd, fieldMapping);

        return md;
    }

    /*******************************************************************************************************
    * @description Deploys the Custom metadata records using the OppStageToStateMetadataHandler as the handler
    * @param List<Metadata.CustomMetadata> listOfMetadataToInsert A list of custom metadata that will be inserted
    * @param Map<String, Object> params A mapping of params for the callback to use. 
    ********************************************************************************************************/
    public static void deployOppStageToStateMetadata(List<Metadata.CustomMetadata> listOfMetadataToInsert, Map<String, Object> params) {
        // Deploy the metadata 
        String jobId = CMT_MetadataAPI.getUniqueJobId();
        CMT_MetadataAPI.MetadataCallbackHandler oppCallbackHandler = new OppStageToStateMetadataHandler();
        CMT_MetadataAPI.MetadataCallBack callback = new CMT_MetadataAPI.MetadataCallBack(jobId);
        callback.callbackHandler = oppCallbackHandler;
        callback.callbackParams = params;

        CMT_MetadataAPI.deployMetadata(listOfMetadataToInsert, callback);
    }

    /******************************************************************************************************************
     * @description Interface implementation of the Metadata Callback Handler
     * This is needed so that NPSP's implementation of the result handlers are not executed. 
     *****************************************************************************************************************/
    public class OppStageToStateMetadataHandler implements CMT_MetadataAPI.MetadataCallbackHandler {

        public Map<String, Object> params;


        /**************************************************************************************************************
        * @description success handler - No implementation as of right now, will be implemented later as needed. 
        * @param Map<String, Object> params Parameters for the handler to use. 
        * @param String status The status of the metadata callback for the handler to use. 
        /*************************************************************************************************************/
        public void performSuccessHandler(Map<String, Object> params, String status) {
            if (params == null || params.isEmpty()) {
                return;
            }

            try {
                // TODO: Implement if needed. 
                // Process a successful 
            } catch (Exception ex) {
                
            }
        }

        /**************************************************************************************************************
        * @description error handler - No implementation as of right now, will be implemented later as needed. 
        * @param Map<String, Object> params Parameters for the handler to use. 
        * @param String status The status of the metadata callback for the handler to use. 
        /*************************************************************************************************************/
        public void performErrorHandler(Map<String, Object> params, String status) {
            if (params == null || params.isEmpty()) {
                return;
            }

            try {
                // TODO: Implement if needed. 
                // Handle error 
            } catch (Exception ex) {
                
            }
        }
    }
}
