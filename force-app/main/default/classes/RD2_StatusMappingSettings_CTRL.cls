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
     * @description Interface for the custom metadata type records deployment handler
     */
    public interface MetadataDeploymentHandler {
        String getDeploymentId();
        Boolean hasDeployResult();
        Boolean isInProgress();
        Boolean isSuccess();
        String getDeployErrorMessage();
        void save(List<Metadata.CustomMetadata> records);
        void saveDeploymentId();
    }

    /**
     * @description Contains RD Status Mapping custom metadata type name
     */
    private static String cmtObjectName {
        get {
            if (cmtObjectName == null) {
                cmtObjectName = RecurringDonationStatusMapping__mdt.getSObjectType().getDescribe().getName();
            } 
            return cmtObjectName;
        }
        set;
    }


    /**
     * @description Contains status to state mapping configuration
     */
    @TestVisible
    private static RD2_StatusMapper statusMapper {
        get {
            if (statusMapper == null) {
                statusMapper = new RD2_StatusMapper();
            }
            return statusMapper;
        }
        set;
    }

    /**
     * @description Contains state value to label mapping
     */
    private static final Map<String, String> stateLabelByValue {
        get {
            if (stateLabelByValue == null) {
                stateLabelByValue = mapStateLabelByValue();
            }
            return stateLabelByValue;
        }
        set;
    }

    /**
     * @description Returns the state value and label select options
     * @return List<Option>
     */
    @AuraEnabled(cacheable=true)
    public static List<Option> getStateOptions() {
        List<Option> options = new List<Option>();
        for (String value : stateLabelByValue.keySet()) {
            options.add(
                new Option()
                    .withValue(value)
                    .withLabel(stateLabelByValue.get(value))
            );
        }

        return options;
    }

    /***
    * @description Returns the state value (API name) and label mapping.
    * The state values and labels are sourced from the RD Status field picklist field
    * since state values are already contained in the Status field
    * so there is no need to create new custom labels to hold the state labels.
    @ @return Map<String, String>
    */
    private static Map<String, String> mapStateLabelByValue() {
        Map<String, String> stateLabelByValue = new Map<String, String>();
        SObjectType mappingSObjectType = RecurringDonationStatusMapping__mdt.SObjectType;
        SObjectField stateField = RecurringDonationStatusMapping__mdt.State__c;

        for (String value : new Set<String>{
            RD2_Constants.STATUS_ACTIVE,
            RD2_Constants.STATUS_LAPSED,
            RD2_Constants.STATUS_CLOSED
        }) {
            String label = UTIL_Describe.getTranslatedPicklistLabel(
                mappingSObjectType, stateField, value
            );

            stateLabelByValue.put(value, label);
        }

        return stateLabelByValue;
    }

    /***
    * @description NPSP namespace: an empty string if unmanaged, or 'npsp' if managed
    * @return String
    */
    public String getNamespace() {
        return UTIL_Namespace.getNamespace();
    }

    /***
    * @description Get the RD Status field label
    * @return String The Status field label
    */
    @AuraEnabled(cacheable=true)
    public static String getStatusFieldLabel() {
        return SObjectType.npe03__Recurring_Donation__c.fields.Status__c.getLabel();
    }

    /**
     * @description Retrieves status to state mapping records
     * @return List<Mapping>
     */
    @AuraEnabled
    public static List<Mapping> loadMapping() {
        List<Mapping> mappings = new List<Mapping>();

        try {
            Map<String, RD2_StatusMapper.Mapping> mappingByStatus = statusMapper.getAll();

            //get read-only mapping records first
            for (String status : RD2_StatusMapper.READ_ONLY_STATUS_TO_STATE.keySet()) {
                RD2_StatusMapper.Mapping mapping = mappingByStatus.get(status);
                if (mapping != null) {
                    mappings.add(new Mapping(mapping));
                }
            }

            //get other mapping records next
            for (String status : mappingByStatus.keySet()) {
                if (!RD2_StatusMapper.READ_ONLY_STATUS_TO_STATE.keySet().contains(status)) {
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
        return saveMapping(jsonMapping, new DeploymentHandler());
    }

    /**
     * @description Saves status to state mapping records
     * @param jsonMapping JSON representation of the admin defined mapping records
     * @param deploymentHandler Deployment handler used to deploy CMT records and return the deployment Id
     * @return String Deployment Id
     */
    @TestVisible
    private static String saveMapping(String jsonMapping, MetadataDeploymentHandler deploymentHandler) {
        try {
            if (deploymentHandler.isInProgress()) {
                throw new MappingException(System.Label.RD2_StatusMappingDeploymentAlreadyInProgress);
            }

            List<Metadata.CustomMetadata> records = buildCustomMetadataRecords(jsonMapping);
            deploymentHandler.save(records);

            //reset mapping record retrieval
            statusMapper = null;

        } catch (Exception e) {
            throwAuraHandledException(e.getMessage());
        }

        return deploymentHandler.getDeploymentId();
    }

    /**
     * @description Builds custom metadata records from status to state mapping records.
     * Only admin added Status field picklist values are saved while
     * Active, Lapsed, Paused and Closed read-only status mapping are not stored into the CMT.
     * @param jsonMapping JSON representation of mapping records
     * @return List<Metadata.CustomMetadata>
     */
    @TestVisible
    private static List<Metadata.CustomMetadata> buildCustomMetadataRecords(String jsonMapping) {
        List<Mapping> mappings = (List<Mapping>) JSON.deserialize(
            jsonMapping, List<Mapping>.class
        );

        List<Metadata.CustomMetadata> records = new List<Metadata.CustomMetadata>();
        for (Mapping mapping : mappings) {
            if (!RD2_StatusMapper.READ_ONLY_STATUS_TO_STATE.keySet().contains(mapping.status)) {
                records.add(buildCustomMetadata(mapping));
            }
        }

        return records;
    }

    /**
     * @description Builds custom metadata type record for the status to state mapping
     * @return Metadata.CustomMetadata
     */
    private static Metadata.CustomMetadata buildCustomMetadata(Mapping mapping) {
        Metadata.CustomMetadata cmt = new Metadata.CustomMetadata();
        //unique value determines if the record will be inserted or updated
        cmt.fullName = cmtObjectName + '.' + mapping.status.replaceAll(' ', '');
        cmt.protected_x = false;

        //update the label every time regardless if it is insert or update,
        //since the mapped state can change for the status
        cmt.label = mapping.status + ' -> ' + mapping.state;

        String state = mapping.state == System.Label.RD2_StatusMappingStateUnmapped ? null : mapping.state;

        Map<String, Object> fieldValues = new Map<String, Object>{
            'Status__c' => mapping.status,
            'State__c' => state
        };
        cmt = CMT_MetadataAPI.addFieldsToMetadataObject(cmt, fieldValues);

        return cmt;
    }

    /**
     * @description Retrieves status to state mapping records
     * @param deploymentId Deployment Id. If null, the RD Settings deployment Id result is retrieved.
     * @return List<Mapping>
     */
    @AuraEnabled
    public static String getDeployResult(String deploymentId) {
        return getDeployResult(deploymentId, new DeploymentHandler(deploymentId));
    }

    /**
     * @description Retrieves status to state mapping records
     * @param deploymentId Deployment Id. If null, the RD Settings deployment Id result is retrieved.
     * @param deploymentHandler Deployment handler used to retrieve deployment result for the specified deployment Id.
     * @return List<Mapping>
     */
    @TestVisible
    private static String getDeployResult(String deploymentId, MetadataDeploymentHandler deploymentHandler) {
        DeployResult response = new DeployResult();

        response.deploymentId = deploymentHandler.getDeploymentId();
        response.hasResult = deploymentHandler.hasDeployResult();
        response.isInProgress = deploymentHandler.isInProgress();
        response.isSuccess = deploymentHandler.isSuccess();
        response.errorMessage = deploymentHandler.getDeployErrorMessage();

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
     * @description Contains custom select option
     */
    public class Option {
        @AuraEnabled public String value;
        @AuraEnabled public String label;

        /**
         * @description Sets the option value
         * @param value The option value
         * @return Option This option instance
         */
        public Option withValue(String value) {
            this.value = value;
            return this;
        }

        /**
         * @description Sets the option label
         * @param label The option label
         * @return Option This option instance
         */
        public Option withLabel(String label) {
            this.label = label;
            return this;
        }
    }

    /**
     * @description Contains mapping record details to be displayed and potentially updated if unmapped
     */
    public class Mapping {
        @AuraEnabled public String status;
        @AuraEnabled public String label;
        @AuraEnabled public String masterLabel;
        @AuraEnabled public String state;
        @AuraEnabled public String stateLabel;
        @AuraEnabled public Boolean isReadOnly;

        /**
         * @description Constructor: Transforms mapping record into a record that can be displayed on a page
         * @param mapping Status to state mapping record
         */
        public Mapping(RD2_StatusMapper.Mapping mapping) {
            this.status = mapping.status;
            this.label = mapping.label;
            this.masterLabel = mapping.masterLabel;
            this.state = String.isBlank(mapping.state) ? System.Label.RD2_StatusMappingStateUnmapped : mapping.state;
            this.stateLabel = getStateLabel(this.state);
            this.isReadOnly = mapping.isReadOnly;
        }

        /**
         * @description Returns label for the specified state
         * @param state State value
         * @return String State label
         */
        private String getStateLabel(String state) {
            String stateLabel = stateLabelByValue.get(state);

            return String.isBlank(stateLabel) ? state : stateLabel;
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
    public inherited sharing class DeploymentHandler implements MetadataDeploymentHandler {

        /**
        * @description Contains latest deployment Id
        */
        private String deploymentId;

        /**
        * @description Custom metadata deployment result
        */
        @TestVisible
        private Metadata.DeployResult deployResult {
            get {
                if (deployResult == null) {
                    if (String.isNotBlank(deploymentId)) {
                        try {
                            deployResult = CMT_MetadataAPI.getDeploymentResult(deploymentId);
                        }
                        catch (Exception e) {
                            // deployResult should remain null if retrieval by deploymentId is unsuccessful
                            // there are known scenarios that result in an invalid deployment id
                            // - metadata deployments older than 30 days can no longer be retrieved
                            // - sandbox created/refreshed from org with RD2 and a status to state mapping
                            deployResult = null;
                        }
                    }
                }
                return deployResult;
            }
            set;
        }

        /**
        * @description Constructor
        */
        public DeploymentHandler() {
            this(STG_Panel.stgService.stgRD.StatusMappingDeploymentId__c);
        }

        /**
        * @description Constructor
        * @param deploymentId Deployment Id. If null, the Id is retrieved from the RD settings.
        */
        public DeploymentHandler(String deploymentId) {
            this.deploymentId = String.isBlank(deploymentId)
                ? STG_Panel.stgService.stgRD.StatusMappingDeploymentId__c
                : deploymentId;
        }

        /**
         * @description Returns deployment Id
         * @return String
         */
        public String getDeploymentId() {
            return deploymentId;
        }

        /**
         * @description Checks if deployment exists for the specified deployment Id
         * @return Boolean
         */
        public Boolean hasDeployResult() {
            return deployResult != null;
        }

        /**
         * @description Checks if deployment is in progress
         * @return Boolean
         */
        public Boolean isInProgress() {
            return hasDeployResult()
                && (
                    deployResult.status == Metadata.DeployStatus.INPROGRESS
                    || deployResult.status == Metadata.DeployStatus.PENDING
                    || deployResult.status == Metadata.DeployStatus.CANCELING
                );
        }

        /**
         * @description Checks if deployment succeeded
         * @return Boolean
         */
        public Boolean isSuccess() {
            return hasDeployResult()
                && deployResult.status == Metadata.DeployStatus.SUCCEEDED;
        }

        /**
         * @description Returns deployment error message
         * @return String
         */
        public String getDeployErrorMessage() {
            if (!hasDeployResult()
                || isInProgress()
                || isSuccess()
            ) {
                return '';
            }

            String errMessage = '';
            try {
                for (Metadata.DeployMessage msg : deployResult.details.componentFailures) {
                    errMessage += '\n* ' + msg.fullName + '> ' + msg.problem;
                }
            } catch (Exception e) {
                errMessage += ' ' + System.Label.stgUnknownError + ': ' + e.getMessage();
            }
            return errMessage;
        }

        /**
         * @description Deploys save action of the custom metadata records
         * @param records A list of custom metadata type records that will be created/updated
         * @return void
         */
        public void save(List<Metadata.CustomMetadata> records) {
            deploymentId = CMT_MetadataAPI.deployMetadata(records, new DeploymentCallbackHandler());
        }

        /**
         * @description Stores the custom metadata type deployment Id
         * @return void
         */
        public void saveDeploymentId() {
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
     * @description Metadata Callback handler class to execute actions when the metadata deployment completes
     */
    public inherited sharing class DeploymentCallbackHandler implements Metadata.DeployCallback {

        /**
         * @description Applies actions after deployment completes.
         * Deployment Id is saved into the RD settings so Status to State mapping page 
         * can check deployment status upon completion.
         * Platform event publishing DeploymentEvent__e could have been used as well to notify 
         * that deployment completed, however, platform events are not supported in Lightning Out
         * (the Status to State mapping LWC that is called from a Visualforce page).
         * @param result Deploy result
         * @param context Deploy callback context
         * @return void
         */
        public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
            if (result == null) {
                return;
            }

            new DeploymentHandler(result.Id).saveDeploymentId();
        }
    }
}
