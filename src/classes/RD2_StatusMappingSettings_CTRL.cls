/*
    Copyright (c) 2020, Salesforce.org
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
* @date 2020
* @group Recurring Donations
* @description Stores and retrieves Recurring Donation status to status type mapping
*/
public with sharing class RD2_StatusMappingSettings_CTRL {
    /**
    * @description Custom data migration exception
    */
    private class MappingException extends Exception { }

    /**
     * @description Contains status to state mapping configuration
     */
    @TestVisible
    private static RD2_StatusMapper mapper {
        get {
            if (mapper == null) {
                mapper = new RD2_StatusMapper();
            }
            return mapper;
        }
        set;
    }

    /***
    * @description NPSP namespace: an empty string if unmanaged, or 'npsp' if managed
    */
    public String getNamespace() {
        return UTIL_Namespace.getNamespace();
    }

    /**
     * @description Retrieves status to state mapping records
     * @return List<Mapping>
     */
    @AuraEnabled
    public static List<Mapping> loadMapping() {
        List<Mapping> mappings = new List<Mapping>();

        try {
            Map<String, RD2_StatusMapper.Mapping> mappingByStatus = mapper.getAll();

            //get read-only mapping records first
            for (String status : RD2_StatusMapper.READ_ONLY_STATUS_VALUES) {
                RD2_StatusMapper.Mapping mapping = mappingByStatus.get(status);
                if (mapping != null) {
                    mappings.add(new Mapping(mapping));
                }
            }

            //get other mapping records next
            for (String status : mappingByStatus.keySet()) {
                if (!RD2_StatusMapper.READ_ONLY_STATUS_VALUES.contains(status)) {
                    mappings.add(new Mapping(mappingByStatus.get(status)));
                }
            }

        } catch (Exception e) {
            throwAuraHandledException(e.getMessage());
        }

        return mappings;
    }
    

    /**
     * @description Saves status to state mapping records
     * @param jsonMappings JSON representation of the admin defined mapping records
     * @return void
     */
    @AuraEnabled
    public static void saveMapping(String jsonMappings) {
        try {
            List<Mapping> mappings = (List<Mapping>) JSON.deserialize(
                jsonMappings, Mapping.class
            );
            
            saveMapping(mappings);

            //reset mapping record retrieval
            mapper = null;

        } catch (Exception e) {
            throwAuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Saves status to state mapping records
     * @param List<Mapping> Admin defined mapping records
     * @return void
     */
    public static void saveMapping(List<Mapping> mappings) {
        DeploymentHandler deploymentHandler = new DeploymentHandler();

        if (deploymentHandler.isDeploymentInProgress()) {
            throw new MappingException('Deployment is already in progress');//Use custom label//TODO
        } 

        List<Metadata.CustomMetadata> records = new List<Metadata.CustomMetadata>();
        for (Mapping mapping : mappings) {
            records.add(buildCustomMetadata(mapping));
        }

        deploymentHandler.save(records);
    }

    /**
     * @description Builds custom metadata type record for the status to state mapping
     * @return Metadata.CustomMetadata
     */
    public static Metadata.CustomMetadata buildCustomMetadata(Mapping mapping) {
        String sObjectName = RecurringDonationStatusMapping__mdt.getSObjectType().getDescribe().getName();

        Metadata.CustomMetadata cmt = new Metadata.CustomMetadata();
        cmt.label = mapping.masterLabel;//what if it is a new mapping?//TODO
        cmt.fullName = sObjectName + '.' + mapping.status;
        cmt.protected_x = false;

        String state = mapping.state == System.Label.RD2_StatusMappingUnmappedState ? null : mapping.state;

        Map<String, Object> fieldValues = new Map<String, Object>{
            'Status__c' => mapping.status,
            'State__c' => state
        };
        cmt = CMT_MetadataAPI.addFieldsToMetadataObject(cmt, fieldValues);

        return cmt;
    }

    /***
    * @description Throws AuraHandledException
    * @param errMessage
    * @return void
    */
    private static void throwAuraHandledException(String errMessage) {
        AuraHandledException e = new AuraHandledException(errMessage);
        e.setMessage(errMessage);
        throw e;
    }


    /**
     * @description Contains Mapping record details to be displayed and potentially updated if unmapped
     */
    public class Mapping {
        @AuraEnabled public String status;
        @AuraEnabled public String label;
        @AuraEnabled public String masterLabel;
        @AuraEnabled public String developerName;
        @AuraEnabled public String state;
        @AuraEnabled public Boolean isReadOnly;

        public Mapping(RD2_StatusMapper.Mapping mapping) {
            this.status = mapping.status;
            this.label = mapping.label;
            this.masterLabel = mapping.masterLabel;
            this.developerName = mapping.developerName;
            this.state = String.isBlank(mapping.state) ? System.Label.RD2_StatusMappingUnmappedState : mapping.state;
            this.isReadOnly = mapping.isReadOnly;
        }
    }

    /**
     * @description Handles custom metadata type deployment operations
     */
    public inherited sharing class DeploymentHandler {

        /**
        * @description Contains latest deployment Id
        */
        public String deploymentId {
            get {
                return STG_Panel.stgService.stgRD.StatusMappingDeploymentId__c;
            }
            set {
                STG_Panel.stgService.stgRD.StatusMappingDeploymentId__c = value;
            }
        }

        /**
        * @description Custom metadata deployment result
        */
        public Metadata.DeployResult deploymentResult { 
            get {
                if (deploymentResult == null) {
                    if (String.isNotBlank(deploymentId)) {
                        deploymentResult = CMT_MetadataAPI.getDeploymentResult(deploymentId);
                    }
                }
                return deploymentResult;
            }
            set; 
        }

        /**
         * @description Checks if deployment is in progress
         */
        public Boolean isDeploymentInProgress() {
            if (deploymentResult == null) {
                return false;
            }

            return deploymentResult.status == Metadata.DeployStatus.INPROGRESS
                || deploymentResult.status == Metadata.DeployStatus.PENDING
                || deploymentResult.status == Metadata.DeployStatus.CANCELING;
        }

        /**
         * @description Checks if deployment succeeded
         */
        public Boolean isDeploymentSuccess() {          
            return deploymentResult != null 
                && deploymentResult.status == Metadata.DeployStatus.SUCCEEDED;
        }

        /**
         * @description Checks if deployment failed
         */
        public Boolean isDeploymentFailed() {            
            return deploymentResult != null 
                && deploymentResult.status == Metadata.DeployStatus.FAILED;
        }

        /**
         * @description Deploys the custom metadata records 
         * @param records A list of custom metadata that will be created/updated
         * @return void
         */
        public void save(List<Metadata.CustomMetadata> records) {
            Id lastDeploymentId = deploymentId;

            Savepoint sp = Database.setSavepoint();
            try {            
                String deploymentId = deployMetadata(records);
                saveDeploymentId(deploymentId);

            } catch (Exception e) {
                Database.rollback(sp);

                //rollback data values due to STG settings being static var
                deploymentId = lastDeploymentId;

            } finally {
                //throw an error if deployment failed//TODO
            }
        }

        /**
         * @description Deploys the custom metadata records 
         * @param records A list of custom metadata that will be created/updated
         * @return String Deployment job Id
         */
        public String deployMetadata(List<Metadata.CustomMetadata> records) {
            String jobId = CMT_MetadataAPI.getUniqueJobId();
            
            CMT_MetadataAPI.MetadataCallBack callback = new CMT_MetadataAPI.MetadataCallBack(jobId);
            callback.callbackHandler = new DeploymentCallbackHandler();

            CMT_MetadataAPI.deployMetadata(records, callback);

            return jobId;
        }

        /**
         * @description Stores the custom metadata type deployment Id
         * @param deploymentId Deployment Id
         * @return void
         */
        public void saveDeploymentId(String deploymentId) {            
            STG_Panel.stgService.stgRD.StatusMappingDeploymentId__c = deploymentId;

            if (!Test.isRunningTest()) {
                upsert STG_Panel.stgService.stgRD;
            }
        }
    }


    /**
     * @description Metadata Call back handler class to execute actions when the metadata has successfully been deployed
     */
    public inherited sharing class DeploymentCallbackHandler implements CMT_MetadataAPI.MetadataCallbackHandler {

        /**
         * @description Actions to perform when custom metadata type deployment succeeds
         */
        public void performSuccessHandler(Map<String, Object> params, String status) {
        }

        /**
         * @description Actions to perform when custom metadata type deployment fails
         */
        public void performErrorHandler(Map<String, Object> params, String status) {
        }

    }
}
