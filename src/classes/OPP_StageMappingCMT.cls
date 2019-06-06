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
    * "Opportunity Stage when Fully Paid" field as the Opportunity stage for the finalized state. 
    ********************************************************************************************************/
    public static List<Metadata.CustomMetadata> createFinalizedOppStageToStateRecord(List<Metadata.CustomMetadata> metadataToInsert) {
        npe01__Contacts_And_Orgs_Settings__c contactAndOrgCustomSetting = UTIL_CustomSEttingsFacade.getOrgContactsSettings();

        // Only create the finalized opp stage to state record if there's no existing finalized record. 
        Integer finalizedCount = [SELECT Count() FROM Opportunity_Stage_To_State_Mapping__mdt Where Opportunity_State__c =: FINALIZED_STATE_VAL];
        
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
    ********************************************************************************************************/
    public static List<Metadata.CustomMetadata> createPledgedOppStageToStateRecord(List<Metadata.CustomMetadata> metadataToInsert) {
        npe01__Contacts_And_Orgs_Settings__c contactAndOrgCustomSetting = UTIL_CustomSEttingsFacade.getOrgContactsSettings();

        
        Integer overallCount = [SELECT Count() FROM Opportunity_Stage_To_State_Mapping__mdt];

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
        
        // Take the value, if there is one, and create a finalized Opp Stage to State custom metadata type record. 
        // Only create the pledged opp stage to state record if there's no existing opportunity stage to state records at all. 
        if (overallCount == 0 && hasPledgedValue) {
            metadataToInsert.add(createCustomMetadata(normalPledgeValue, COMMITTED_STATE_VAL));
        }

        return metadataToInsert;
    }

    /*******************************************************************************************************
    * @description Creates a custom metadata record based on the parameters provided to the method. 
    ********************************************************************************************************/
    public static Metadata.CustomMetadata createCustomMetadata(String oppStage, String oppState) {        
        Metadata.CustomMetadata customMd = new Metadata.CustomMetadata();
        String mdTypeName = UTIL_Namespace.StrTokenNSPrefix(OPP_STAGE_TO_STATE_METADATA_NAME);

        customMd.fullName =  mdTypeName + '.' + oppState + '_' + datetime.now().getTime();
        customMd.label = oppState + '_' + datetime.now().getTime();
        customMd.protected_x = false;

        Map<String, Object> fieldMapping = new Map<String, Object>();
        fieldMapping.put(OPP_STAGE_FIELD, oppStage);
        fieldMapping.put(OPP_STATE_FIELD, oppState);

        Metadata.CustomMetadata md = new Metadata.CustomMetadata();
        md = CMT_MetadataAPI.addFieldsToMetadataObject(customMd, fieldMapping);

        return md;
    }

    /*******************************************************************************************************
    * @description Deploys the Custom metadata records using the OppStageToStateMetadataHandler as the handler
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

    public class OppStageToStateMetadataHandler implements CMT_MetadataAPI.MetadataCallbackHandler {

        public Map<String, Object> params;


        /**************************************************************************************************************
        * @description success handler - No implementation as of right now, will be implemented later as needed. 
        /*************************************************************************************************************/
        public void performSuccessHandler(Map<String, Object> params, String status) {
            if (params == null || params.isEmpty()) {
                return;
            }

            try {
                // TODO: Implement if needed. 
                // Process a successful 
            } catch (Exception ex) {
                logError(ex);
            }
        }

        /**************************************************************************************************************
        * @description error handler - No implementation as of right now, will be implemented later as needed. 
        /*************************************************************************************************************/
        public void performErrorHandler(Map<String, Object> params, String status) {
            if (params == null || params.isEmpty()) {
                return;
            }

            try {
                // TODO: Implement if needed. 
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

            // TODO: Currently not in use, if we decide to use this in the future,
            // We will need to convert this into a custom label. 
            Error__c oppStageToStateHandlerError = new Error__c(
                Error_Type__c = 'Opportunity Stage to State Metadata Handler Error',
                Object_Type__c = 'CustomMetadata',
                Context_Type__c = ERR_Handler_API.Context.OPP.name(),
                Datetime__c = System.now(), 
                Full_Message__c = ex.getMessage()
            );

            Database.insert(oppStageToStateHandlerError, true);
        }
    }
}
