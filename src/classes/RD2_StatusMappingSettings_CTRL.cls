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
    * @description Custom data mapping exception
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
     * @param jsonMapping JSON representation of the admin defined mapping records
     * @return String Deployment Id
     */
    @AuraEnabled
    public static String saveMapping(String jsonMapping) {
        DeploymentHandler deploymentHandler = new DeploymentHandler();

        try {
            if (deploymentHandler.isDeploymentInProgress()) {
                throw new MappingException(System.Label.RD2_StatusMappingDeploymentAlreadyInProgress);
            } 

            List<Metadata.CustomMetadata> records = buildCustomMetadataRecords(jsonMapping);
            deploymentHandler.save(records);

            //reset mapping record retrieval
            mapper = null;

        } catch (Exception e) {
            throwAuraHandledException(e.getMessage());
        }

        return deploymentHandler.deploymentId;
    }

    /**
     * @description Builds custom metadata records from status to state mapping records
     * @param jsonMapping JSON representation of mapping records
     * @return List<Metadata.CustomMetadata>
     */
    private static List<Metadata.CustomMetadata> buildCustomMetadataRecords(String jsonMapping) { 
        List<Mapping> mappings = (List<Mapping>) JSON.deserialize(
            jsonMapping, List<Mapping>.class
        );    

        List<Metadata.CustomMetadata> records = new List<Metadata.CustomMetadata>();
        for (Mapping mapping : mappings) {
            records.add(buildCustomMetadata(mapping));
        }  

        return records;
    }

    /**
     * @description Builds custom metadata type record for the status to state mapping
     * @return Metadata.CustomMetadata
     */
    public static Metadata.CustomMetadata buildCustomMetadata(Mapping mapping) {
        String sObjectName = RecurringDonationStatusMapping__mdt.getSObjectType().getDescribe().getName();

        Metadata.CustomMetadata cmt = new Metadata.CustomMetadata();
        cmt.label = String.isBlank(mapping.masterLabel) 
            ? (mapping.status + '_' + datetime.now().getTime()) 
            : mapping.masterLabel;
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

    /**
     * @description Retrieves status to state mapping records
     * @return List<Mapping>
     */
    @AuraEnabled
    public static String getDeploymentResult(String deploymentId) {
        DeploymentHandler deploymentHandler = new DeploymentHandler(deploymentId);
        DeployResult response = new DeployResult();

        response.deploymentId = deploymentHandler.deploymentId;
        response.hasResult = deploymentHandler.hasDeploymentResult();
        response.isInProgress = deploymentHandler.isDeploymentInProgress();
        response.isSuccess = deploymentHandler.isDeploymentSuccess();
        response.errorMessage = deploymentHandler.getDeploymentErrorMessage();

        return JSON.serialize(response);
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
     * @description Contains deployment result for the specified deployment Id
     */
    public class DeployResult {
        @AuraEnabled public String deploymentId;
        @AuraEnabled public Boolean hasResult = false;
        @AuraEnabled public Boolean isInProgress = false;
        @AuraEnabled public Boolean isSuccess = false;
        @AuraEnabled public String errorMessage = '';
    }


    /**
     * @description Handles custom metadata type deployment operations
     */
    public inherited sharing class DeploymentHandler {

        /**
        * @description Contains latest deployment Id
        */
        public String deploymentId { get; set; }

        /**
        * @description Constructor
        */
        public DeploymentHandler() {
            this(STG_Panel.stgService.stgRD.StatusMappingDeploymentId__c);
        }

        public DeploymentHandler(String deploymentId) {
            this.deploymentId = String.isBlank(deploymentId)
                ? STG_Panel.stgService.stgRD.StatusMappingDeploymentId__c
                : deploymentId;  
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
         * @description Checks if deployment exists for the specified deployment Id
         */
        public Boolean hasDeploymentResult() {
            return deploymentResult != null;
        }

        /**
         * @description Checks if deployment is in progress
         */
        public Boolean isDeploymentInProgress() {
            return hasDeploymentResult() 
                && (
                    deploymentResult.status == Metadata.DeployStatus.INPROGRESS
                    || deploymentResult.status == Metadata.DeployStatus.PENDING
                    || deploymentResult.status == Metadata.DeployStatus.CANCELING
                );
        }

        /**
         * @description Checks if deployment succeeded
         */
        public Boolean isDeploymentSuccess() {          
            return hasDeploymentResult()
                && deploymentResult.status == Metadata.DeployStatus.SUCCEEDED;
        }

        /**
         * @description Returns deployment error message
         */
        public String getDeploymentErrorMessage() {
            if (!hasDeploymentResult()
                || isDeploymentInProgress()
                || isDeploymentSuccess()
            ) {
                return '';
            }

            String errMessage = '';
            try {
                for (Metadata.DeployMessage msg : deploymentResult.details.componentFailures) {
                    errMessage += '\n* ' + msg.fullName + '> ' + msg.problem;
                }
            } catch (Exception e) {
                errMessage += ' Unexpected exception: ' + e.getMessage();
            }
            return errMessage;
        }

        /**
         * @description Deploys save action of the custom metadata records 
         * @param records A list of custom metadata that will be created/updated
         * @return void
         */
        public void save(List<Metadata.CustomMetadata> records) {
            Savepoint sp = Database.setSavepoint();
            try {          
                deploymentId = CMT_MetadataAPI.deployMetadata(records, new DeploymentCallbackHandler());

            } catch (Exception e) {
                Database.rollback(sp);
                
                throw e;
            }
        }

        /**
         * @description Stores the custom metadata type deployment Id
         * @param deploymentId Deployment Id
         * @return void
         */
        public void saveDeploymentId(String deploymentId) {   
            if (String.isBlank(deploymentId)) {
                return;
            } 

            STG_Panel.stgService.stgRD.StatusMappingDeploymentId__c = deploymentId;
            if (!Test.isRunningTest()) {
                upsert STG_Panel.stgService.stgRD;
            }
        }
    }

    /**
     * @description Metadata Call back handler class to execute actions when the metadata has successfully been deployed
     */
    public inherited sharing class DeploymentCallbackHandler implements Metadata.DeployCallback {

        public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
            if (result == null) {
                return;
            }

            new DeploymentHandler().saveDeploymentId(result.Id);
        }
    }
}
