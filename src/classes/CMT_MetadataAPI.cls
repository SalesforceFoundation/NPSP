/*
    Copyright (c) 2018, Salesforce.org
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
* @date 2018
* @group Utilities
* @description Utility methods to handle manipulating CustomMetadataType objects through the Apex MD Api
* The flow for this is somewhat complex due to the asynchronous nature of these 'deployments'
* Notes:
*   - The logic is built to support nested deployments to handle inserting parent / child relationship records
*   - A Queuable inner class is used to chain nested deployments
*   - The final status of a metadata deployment can be obtained through SOQL or an Apex metadata call.
* Flow:
* 1. deployMetadata() is called with two parameters: A unique "jobId" (some unique string) and List<List<CustomMetaDataObject>>
* 2. An instance of the MetadataCallBack() inner class is constructed passing the first paramter and element 1+ of the List<List
* 3. Call Metadata.Operations.enqueueDeployment() with the first element from the List<List>>
* 4. Salesforce will call MetadataCallBack() asynchronously with the deployment result.
* 5. If the result is Success and there is more metadata to deploy, return to step 1 passing the two parms included in the
*       MetadataCallBack() construction.
* 6. If the result is Success and there is no more metadata to deploy, write the Result.Status to a Custom Settings object
* 7. If the result is Failure, write the Result.Status and Error Message to a Custom Settings object
*/
public class CMT_MetadataAPI {

    /**
     * @description Static list of queued metadata updates to submit in a single process rather than
     * one update at a time.
     */
    public static List<Metadata.CustomMetadata> cmtUpsertQueue = new List<Metadata.CustomMetadata>();

    /**
     * @description Queue a Custom MetadataType upsert operation to be submitted later as an ASync operation.
     * @param mdObject MetadataObject name
     * @param recordName Unique record name of the record to insert/update. Required for both insert and update.
     * @param recordLabel Record label of the record to insert/udpate. Required for insert.
     * @param fldValues Map of field names/values to upsert for the specified record.
     */
    public static void upsertCustomMetadata(CRLP_RollupCMT.MetadataObject mdObject, String recordName, String recordLabel, Map<String,Object> fldValues) {

        String mdTypeName = mdObject.Name() + '__mdt';

        // Setup custom metadata to be created or udpated in the subscriber org.
        Metadata.CustomMetadata customMd = new Metadata.CustomMetadata();
        customMd.fullName = mdTypeName + '.' + recordName;
        if (recordLabel != null) {
            customMd.protected_x = false;
            customMd.label = recordLabel;
        }

        addFieldsToMetadataObject(customMd, fldValues);
        cmtUpsertQueue.add(customMd);
    }

    /**
     * @description Set field values on the specified Custom Metadata Type record
     * @param md CustomMetadata instance
     * @param fldValues Key-Value pair map of fields/values
     * @return Updated CustomMetadata object instance with the fields added to the values collection
     */
    public static Metadata.CustomMetadata addFieldsToMetadataObject(Metadata.CustomMetadata md, Map<String,Object> fldValues) {
        Metadata.CustomMetadataValue customField;
        for (String k : fldValues.keySet()) {
            customField = new Metadata.CustomMetadataValue();
            customField.field = k;
            customField.value = fldValues.get(k);
            md.values.add(customField);
        }
        return md;
    }

    /**
     * @description We can't actually delete CMT's through the Apex API yet, but we'll wrap deleting into
     * this method so it can easily be implemented at some future point in time. For now, just set the custom
     * 'IsDeleted' boolean value to true. The operation does not commit the changes, but only queues it for
     * a future asynchronous commit.
     * @param mdObject MetadataObject name
     * @param recordName Unique record name of the record to insert/update. Required for both insert and update.
     */
    public static void deleteCustomMetadataTypeRecord(CRLP_RollupCMT.MetadataObject mdObject, String recordName) {
        upsertCustomMetadata(mdObject, recordName, null, new Map<String,Object>{
                'IsDeleted__c' => True
        });
    }

    /**
    * @description Submit any queued up Custom MetadataType operations for deployment as a single aSync job
    * @param jobId Unique string to act as a "jobId" when writing the final deployment status to the Custom
    * Settings object
    * @returns jobId of the callback to know when the process is done. The calling method can monitor this JobId
    * and query the Error__c object for Context_Type__c = :jobId to find any generate error message.
    */
    public static void commitPendingOperations(String jobId) {
        if (cmtUpsertQueue.size() == 0) {
            return;
        }

        List<List<Metadata.CustomMetadata>> nestedMetadata = new List<List<Metadata.CustomMetadata>>();
        nestedMetadata.add(cmtUpsertQueue);

        deployMetadata(jobId, nestedMetadata);

        // clear the queue
        cmtUpsertQueue.clear();
    }

    /**
     * @description Initiate a deployment of nested custom metadata type records. This allows for dependent metadata
     * as well as just the ability to split the deployments into smaller chunks. The final status isn't written to
     * the Custom Settings object until the final deployment or if one of the deployments fail with an error.
     * @param jobId Unique string to act as a "jobId" when writing the final deployment status to the Custom Settings
     * @param nestedMetadata List of a List of CustomMetadata objects to deploy
     */
    public static void deployMetadata(String jobId, List<List<Metadata.CustomMetadata>> nestedMetadata) {

        // Add all queued up metadata updates to the deployment container
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        for (Metadata.CustomMetadata md: nestedMetadata[0]) {
            system.debug('deployMetadata > ' + md.fullName);
            mdContainer.addMetadata(md);
        }
        nestedMetadata.remove(0);

        // Setup deploy callback
        MetadataCallBack callback = new MetadataCallBack(jobId, nestedMetadata);

        // Enqueue custom metadata deployment and return the Job Id
        if (!Test.isRunningTest()) {
            Metadata.Operations.enqueueDeployment(mdContainer, callback);
        }
    }

    /**
     * @description Inserting or Updating CMT's through the Apex Metadata API is an asynchronous process. This callback
     * class is used to handle the async response from the call to Metadata.Operations.enqueueDeployment().
     * If there is call is not successfull, an Error__c record is created an passed to the NPSP error handling
     * class for processing. The Context_Type__c field is used to hold the jobId that was returned by the
     * upsertCustomMetadata() method. This can be used by the calling method to query the Error__c record to retrieve
     * any error messages returned by the api call.
     */
    public class MetadataCallBack implements Metadata.DeployCallBack {

        private String jobId;
        private List<List<Metadata.CustomMetadata>> nextOperation;

        /**
         * @description Constructor for Callback Class
         * @param jobId Some unique string value to use when writing the deployment status to the Custom Settings object
         * @param nextOperation List<CustomMetadata> for next operation if there are any child records to deploy.
         */
        public MetadataCallBack(String jobId, List<List<Metadata.CustomMetadata>> nextOperation) {
            this.jobId = jobId;
            this.nextOperation = nextOperation;
        }

        /**
         * @description Method called by salesforce with the result of the Metadata deployment operation status.
         * This will either write the status to a CustomSettings object, or queue up the next chained deployment operation.
         */
        public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {

            Boolean isSuccess = (result != null ? result.status == Metadata.DeployStatus.Succeeded : false);
            Map<String, String> statusMap = new Map<String, String>{ this.jobId => (result != null ? result.status.name() : 'Unknown') };
            // If the status is not Success, collect all errors into a string that can be written as the status
            if (result != null && result.status != Metadata.DeployStatus.Succeeded) {
                String errMsg = '';
                for (Integer n=0; n < result.details.componentFailures.size(); n++) {
                    errMsg += (n > 0 ? '\n' : '') + '* ' + result.details.componentFailures[n].fullName +
                            ': ' + result.details.componentFailures[n].problem;
                }
                // The custom settings field is a max of 255 characters, but need space for the serialized json overhead
                statusMap.put(this.jobId, errMsg.left(220));
                isSuccess = false;
            }

            // If there are more records to deploy, chain the Queuable class to continue the deployment
            if (isSuccess && this.nextOperation != null && this.nextOperation.size() > 0 && !Test.isRunningTest()) {
                System.enqueueJob(new QueueableDeployMetadata(this.jobId, this.nextOperation));

            } else {
                // Otherwise, write the deployment status to the custom settings object
                Customizable_Rollup_Settings__c crlpSettings = UTIL_CustomSettingsFacade.getCustomizableRollupSettings();
                crlpSettings.CMT_API_Status__c = JSON.serializePretty(statusMap).left(255);
                if (!Test.isRunningTest()) {
                    upsert crlpSettings;
                }
            }
        }
    }

    /**
     * @description Queueable interface to use with chaining nested custom metadata deployments
     */
    public class QueueableDeployMetadata implements System.Queueable {
        private String jobId;
        private List<List<Metadata.CustomMetadata>> nextOperation;

        /**
         * @description Constructor to set up the chained deployment operation
         * @param jobId Unique string to act as a "jobId" when writing the final deployment status to the Custom Settings
         * @param nextOperation List of a List of CustomMetadata objects to deploy
         */
        public QueueableDeployMetadata(String jobId, List<List<Metadata.CustomMetadata>> nextOperation) {
            this.jobId = jobId;
            this.nextOperation = nextOperation;
        }

        /**
         * @description Execute the next deployment process by calling back to the custom deployment method in this class
         */
        public void execute(QueueableContext qc) {
            if (this.nextOperation.size() > 0) {
                CMT_MetadataAPI.deployMetadata(this.jobId, this.nextOperation);
            }
        }
    }
}