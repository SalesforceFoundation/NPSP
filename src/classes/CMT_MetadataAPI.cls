/*
    Copyright (c) 2017, Salesforce.org
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
* @date 2017
* @group Utilities
* @description Utility methods to handle manipulating CustomMetadataType objects through the Apex MD Api
*/
public class CMT_MetadataAPI {

    /**
     * @description Enum of supported MetadataType objects (without the __mdt suffix)
     */
    public enum MetadataObject {
        Rollup,
        Filter_Group,
        Filter_Rule
    }

    /**
     * @description Static list of queued metadata updates to submit in a single process rather than
     * one update at a time.
     */
    private static List<Metadata.CustomMetadata> cmtUpsertQueue = new List<Metadata.CustomMetadata>();

    /** ***************************************************************************************************
    * ==================  SAMPLE CODE THAT ILLUSTRATES HOW TO IMPLEMENT THIS CLASS  =======================
    *******************************************************************************************************
    * Notes:
    * - Can call upsertCustomMetadata() multiple times to add insert/updates to the queue so that a single
    *   call to commitPendingOperations() will insert/update multiple records at once.
    * - When handling FilterGroups and FilterRules, the FilterGroups would have to be inserted first
    *   and then after the async job completes, the data can be queried using CMT_FilterRule_SEL
    *   to get the Id's to use to insert the FilterRule records.
    * - When inserting/updating CMT's from a UI, Javascript can be used to poll the status of the operations
    *   showing status to the User while also waiting for the first operation to complete before calling
    *   secondary actions (i.e., Filter_Rules__mdt).
    * - If this is being done as a headless operation (i.e., from a PostInstall script or something like that)
    *   then the process probably has to be split into chained queuable jobs where the first job inserts the
    *   Filter_Groups. The callback method for that job could launch the second queueable job to insert the
    *   Filter_Rules and Rollup records (both of which are dependent upon FilterGroup.Id).
    ******************************************************************************************************* */
    public static void testMetadataTypes() {

        CMT_MetadataAPI.upsertCustomMetadata(MetadataObject.Filter_Rule, 'Rule_4', 'Rule 4: OCR.Role',
                new Map<String,Object>{
                    'Filter_Group__c' => 'm016A000000YXdG',
                    'Operation__c' => 'Equals',
                    'Constant__c' => 'Solicitor',
                    'Object__c' => SObjectType.OpportunityContactRole.getName(),
                    'Field__c' => SObjectType.OpportunityContactRole.Fields.Role.getName()
            });

        Id jobId = CMT_MetadataAPI.commitPendingOperations();
        System.Debug('*** JobId=' + jobId);
        // Can query AsyncApexJob to determine when the job has completed.
    }
    /* ==================================================================================================== */

    /**
     * @description Queue a Custom MetadataType upsert operation to be submitted later as an ASync operation.
     * @param mdObject MetadataObject name
     * @param recordName Unique record name of the record to insert/update. Required for both insert and update.
     * @param recordLabel Record label of the record to insert/udpate. Required for insert.
     * @param fldValues Map of field names/values to upsert for the specified record.
     */
    public static void upsertCustomMetadata(MetadataObject mdObject, String recordName, String recordLabel, Map<String,Object> fldValues) {

        String mdTypeName = mdObject.Name() + '__mdt';

        // Setup custom metadata to be created or udpated in the subscriber org.
        Metadata.CustomMetadata customMd = new Metadata.CustomMetadata();
        customMd.fullName = mdTypeName + '.' + recordName;
        if (recordLabel != null) {
            customMd.protected_x = false;
            customMd.label = recordLabel;
        }

        // add all the custom fields
        Metadata.CustomMetadataValue customField;
        for (String k : fldValues.keySet()) {
            customField = new Metadata.CustomMetadataValue();
            customField.field = k;
            customField.value = fldValues.get(k);
            customMd.values.add(customField);
        }

        cmtUpsertQueue.add(customMd);
    }

    /**
     * @description We can't actually delete CMT's through the Apex API yet, but we'll wrap deleting into
     * this method so it can easily be implemented at some future point in time. For now, just set the custom
     * 'IsDeleted' boolean value to true. The operation does not commit the changes, but only queues it for
     * a future asynchronous commit.
     * @param mdObject MetadataObject name
     * @param recordName Unique record name of the record to insert/update. Required for both insert and update.
     */
    public static void deleteCustomMetadataTypeRecord(MetadataObject mdObject, String recordName) {
        upsertCustomMetadata(mdObject, recordName, null, new Map<String,Object>{
                'IsDeleted__c' => True
        });
    }

    /**
    * @description Submit any queued up Custom MetadataType operations for deployment as a single aSync job
    * @returns jobId of the callback to know when the process is done. The calling method can monitor this JobId
    * and query the Error__c object for Context_Type__c = :jobId to find any generate error message.
    */
    public static Id commitPendingOperations() {
        if (cmtUpsertQueue.size() == 0) {
            return null;
        }

        // Add all queued up metadaa updates to the deployment container
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        for (Metadata.CustomMetadata md: cmtUpsertQueue) {
            mdContainer.addMetadata(md);
        }

        // Setup deploy callback
        MetadataCallBack callback = new MetadataCallBack();

        // clear the queue
        cmtUpsertQueue.clear();

        // Enqueue custom metadata deployment and return the Job Id
        if (!Test.isRunningTest()) {
            return Metadata.Operations.enqueueDeployment(mdContainer, callback);
        } else {
            return null;
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
        public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
            if (result != null && result.status != Metadata.DeployStatus.Succeeded) {
                String errMsg = '';
                for (Integer n=0; n < result.details.componentFailures.size(); n++) {
                    if (n > 0) {
                        errMsg += '\n';
                    }
                    errMsg += '* ' + result.details.componentFailures[n].fullName + ': ' + result.details.componentFailures[n].problem;
                }
                Error__c error = new Error__c(
                    Datetime__c = System.now(),
                    Error_Type__c = 'CustomMetadataType Upsert',
                    Stack_Trace__c = 'CMT_MetadataAPI.upsertCustomMetadata()',
                    Full_Message__c = errMsg,
                    Context_Type__c = result.Id,
                    Record_URL__c = URL.getSalesforceBaseUrl().toExternalForm() + '/changemgmt/monitorDeploymentsDetails.apexp?asyncId=' + result.Id
                );
                insert error;
                //ERR_Handler_API.Context.CMT.name()
//                ERR_Handler.processErrors(new List<Error__c>{error}, 'CMT');
            }
        }
    }
}