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
* @group Rollups
* @group-content ../../ApexDocContent/Rollups2.htm
* @description Processor Class for the actual rollup operations. Effectively pass in the rollup type, rollup definitions,
* summary object, detail object, related objects. Returns an updated SObject if there are changed fields.
*
*/
public inherited sharing class CRLP_RollupProcessor {

    /** @description Type of rollup being performed */
    public CRLP_RollupProcessingOptions.RollupType rollupType;

    /** @description Define the type of batch job mode - LDV or NonLDV mode */
    public CRLP_RollupProcessingOptions.BatchJobMode mode = CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode;

    /** @description Support filtering the specific types of Rollup definitions that will be processed */
    private CRLP_RollupProcessingOptions.RollupTypeFilter rollupTypesToProcess = CRLP_RollupProcessingOptions.RollupTypeFilter.All;

    /** @description Optional processing options for the rollup operation */
    @TestVisible
    private CRLP_RollupProcessingOptions.ProcessingOptions options {
        get {
            if (options == null) {
                options = new CRLP_RollupProcessingOptions.ProcessingOptions();
            }
            return options;
        } set;
    }

    /** @description List of Parent (Summary) records being rolled up to */
    @TestVisible
    private List<SObject> parentRecords;

    /** @description List of detail records being rolled up to the Parent Summary record grouped by Parent.Id */
    @TestVisible
    private Map<Id, List<SObject>> detailRecordsByParentId = new Map<Id, List<SObject>>();

    /** @description List of detail related records grouped by the Detail Id */
    @TestVisible
    private Map<Id, List<SObject>> relatedRecordsByDetailId;

    /** @description Rollup Definition Collections grouped by ParentId. Only injected if needed for a 'starting' point */
    @TestVisible
    private Map<Id, List<CRLP_Rollup>> rollupsDefsByParentId = new Map<Id, List<CRLP_Rollup>>();

    /**
    * @description used to receive and return the last Parent record id processed by startRollupProcessing().
    * The value is saved as a stateful var in the calling batch process
    */
    private Id lastParentIdProcessed;

    /**
     * @description Used to return a true to the calling LDV class when the last parent Id was removed from
     * the list of updated SObjects
     */
    private Boolean lastParentIdRemovedFromUpdatesList = false;

    /**
     * @description When working with Account Soft Credit Rollups, this var is used to hold a list
     * of Opportunity Id's that have been rolled up to a given Account. The data is retained in a stateful var
     * in the batch job to support scenarios where a given Account's rollups straddle multiple batch operations
     */
    private Map<Id,Set<Id>> processedOppIdsByParentId = new Map<Id,Set<Id>>();

    private Boolean shouldRetrieveExternalRollupStateData = true;

    @TestVisible
    private CRLP_ApiService apiService {
        get {
            if (apiService == null) {
                apiService = new CRLP_ApiService();
            }
            return apiService;
        }
        set;
    }

    /**
     * @description API name for force skew mode field, including namespace prefix
     */
    private String qualifiedSkewField;

    /**
     * @description Boolean set true if parent record should use the force skew mode field on Account & Contact
     */
    private Boolean useForceSkewModeField;

    /** *************************************************************************************************************
    * @description Constructor
    */
    public CRLP_RollupProcessor() { }

    /**
     * @description Inject the Batch Job Mode. Required.
     * @param jobMode
     */
    public CRLP_RollupProcessor withBatchJobMode(CRLP_RollupProcessingOptions.BatchJobMode jobMode) {
        this.mode = jobMode;
        return this;
    }

    /**
     * @description Inject the Job Options. Optional
     * @param jobMode
     */
    public CRLP_RollupProcessor withJobOptions(CRLP_RollupProcessingOptions.ProcessingOptions options) {
        this.options = options;
        return this;
    }

    /**
     * @description Inject the Batch Job Mode. Required.
     * @param jobMode
     */
    public CRLP_RollupProcessor withRollupType(CRLP_RollupProcessingOptions.RollupType rollupType) {
        this.rollupType = rollupType;
        return this;
    }

    /**
     * @description Inject a single Sobject parent record. Optional.
     */
    public CRLP_RollupProcessor withSummaryRecord(SObject sumRecord) {
        this.parentRecords = new List<SObject>{ sumRecord };
        return this;
    }

    /**
     * @description Inject a collection of parent SObject records. Optional
     */
    public CRLP_RollupProcessor withSummaryRecords(List<SObject> sumRecords) {
        this.parentRecords = sumRecords;
        return this;
    }

    /**
     * @description Inject the collection of Detail records to roll up for the Parent record. Required.
     */
    public CRLP_RollupProcessor withDetailRecords(List<SObject> detailRecords) {
        this.detailRecordsByParentId = new Map<Id, List<SObject>>();

        for (SObject dtl : detailRecords) {
            Id parentId = CRLP_Rollup_SVC.getParentIdFromRecord(dtl, parentKeyField, parentRelationshipObject);
            if (!this.detailRecordsByParentId.containsKey(parentId)) {
                this.detailRecordsByParentId.put(parentId, new List<SObject>());
            }
            this.detailRecordsByParentId.get(parentId).add(dtl);
        }
        return this;
    }

    /**
     * @description Inject the map of related record linked to each Detail record. Optional.
     */
    public CRLP_RollupProcessor withRelatedRecords(Map<Id, List<SObject>> relatedRecords) {
        this.relatedRecordsByDetailId = relatedRecords;
        return this;
    }

    /**
     * @description Inject a previously defined set of RollupIds for a collection of Parent Ids. Optional
     * Note that this method completely clones the rollup definitions so that the updated references
     * do not overwrite the original references, which can create issues when there are multiple instances
     * of these collections for multiple parent records. When called with a non-empty map, also turns of fetching
     * of external data to prevent external data from overriding this injection
     */
    public CRLP_RollupProcessor withRollupDefinitions(Map<Id, List<CRLP_Rollup>> rollupDefsByParentId) {
        this.rollupsDefsByParentId = new Map<Id, List<CRLP_Rollup>>();

        for (Id parentId : rollupDefsByParentId.keySet()) {
            if (rollupDefsByParentId.get(parentId) != null) {
                List<CRLP_Rollup> clonedList = CRLP_RollupProcessor_SVC.fullyCloneList(rollupDefsByParentId.get(parentId));
                this.rollupsDefsByParentId.put(parentId, clonedList);
            }
        }

        return this;
    }

    /**
     * @description Determines if existing rollup data is present in the passed in map
     */
    private Boolean hasExistingRollups(Map<Id, List<CRLP_Rollup>> rollupDefsByParentId) {
        if (rollupDefsByParentId == null || rollupDefsByParentId.isEmpty()) {
            return false;
        }

        for (Id parentId : rollupDefsByParentId.keySet()) {
            if (rollupDefsByParentId.get(parentId) != null && !rollupDefsByParentId.get(parentId).isEmpty()) {
                return true;
            }
        }

        return false;
    }

    /**
     * @description Inject a previously defined set of RollupIds for a single Parent Id. Optional
     * Requires that the withSummaryRecord() method be called first to set the parent record Id.
     */
    public CRLP_RollupProcessor withRollupDefinitions(List<CRLP_Rollup> rollupDefs) {
        return withRollupDefinitions(new Map<Id, List<CRLP_Rollup>>{
            parentRecords[0].Id => rollupDefs
        });
    }

    /**
     * @description Inject a map of previously processed Opportunity Id's by Parent Id. Optional
     * This is needed in SkewMode to support rollups that span multiple batch iterations.
     */
    public CRLP_RollupProcessor withPreviouslyProcessedOppIdsMap(Map<Id,Set<Id>> processedOppIdsByParentId) {
        this.processedOppIdsByParentId = processedOppIdsByParentId;
        return this;
    }

    /**
     * @description Specifies that external data should not be used at all with this processor. Necessary when
     * external package is using this processor to calculate rollups in order to not recursively include external data
     */
    public CRLP_RollupProcessor withoutRetrieveExternalRollupStateData() {
        shouldRetrieveExternalRollupStateData = false;
        return this;
    }

    /**
     * @description Determine the SObjectType of the Detail Records based on the current rollup type
     */
    @TestVisible
    private SObjectType detailObjectType {
        get {
            if (detailObjectType == null) {
                detailObjectType = CRLP_Rollup_SVC.getDetailObjectType(rollupType);
            }
            return detailObjectType;
        } set;
    }

    /**
     * @description Determine the SObjectType of the Detail Records based on the current rollup type
     */
    @TestVisible
    private String parentRelationshipField {
        get {
            if (String.isBlank(parentRelationshipField)) {
                parentRelationshipField = CRLP_Rollup_SVC.getParentFieldNameForProcessing(rollupType);
            }
            return parentRelationshipField;
        } set;
    }

    // ================================================================================================

    /** *************************************************************************************************************
    * @description Returns the Parent Object Field by parsing the parentKeyFieldFull property
    */
    @TestVisible
    private String parentRelationshipObject {
        get {
            if (String.isBlank(parentRelationshipObject)) {
                // The parentKeyField field may be have dot-notation (ex: Contact__r.AccountId)
                // If this is the case, need to parse out the two components to use
                if (parentRelationshipField.contains('.')) {
                    parentRelationshipObject = parentRelationshipField.split('\\.')[0];
                }
            }
            return parentRelationshipObject;
        } set;
    }

    /**
    * @description Returns the Parent Key Field portion by parsing the parentKeyFieldFull property
    **/
    @TestVisible
    private String parentKeyField {
        get {
            if (String.isBlank(parentKeyField)) {
                // The parentKeyField field may be have dot-notation (ex: Contact__r.AccountId)
                // If this is the case, need to parse out the two components to use
                parentKeyField = parentRelationshipField;
                if (parentKeyField.contains('.')) {
                    parentKeyField = parentKeyField.split('\\.')[1];
                }
            }
            return parentKeyField;
        } set;
    }

    /**
    * @description Return true if running in Skew Mode
    */
    @TestVisible
    private Boolean isSkewMode {
        get {
            return (mode == CRLP_RollupProcessingOptions.BatchJobMode.SkewMode);
        }
    }

    /**
     * @description Returns the last parent id processed by the RollupsProcessor logic for the given execution scope
     */
    public Id getLastParentIdProcessed() {
        return lastParentIdProcessed;
    }

    /**
     * @description Returns the last parent id processed by the RollupsProcessor logic for the given execution scope
     */
    public Set<Id> getPreviouslyProcessedOppIds(Id parentId) {
        return processedOppIdsByParentId.get(parentId);
    }

    /**
     * @description Returns the last parent id processed by the RollupsProcessor logic for the given execution scope
     */
    public Boolean hasLastParentIdCompleted() {
        return lastParentIdRemovedFromUpdatesList;
    }

    /**
     * @description Validate that any required properties have been configured in this class before starting the operation
     */
    @TestVisible
    private void validateProcessSettingsBeforeStarting() {
        List<String> errors = new List<String>();
        if (rollupType == null) {
            errors.add('A RollupType is required to start the rollup process');
        }
        if (parentRecords == null || parentRecords.size() == 0) {
            errors.add('At least one Parent (Summary) record is required');
        }
        if (!errors.isEmpty()) {
            throw new CRLP_RollupException(String.join(errors, '\n'));
        }
    }

    /** *************************************************************************************************************
     * @description The main work engine for roll-up activities. This method is called from both batch jobs
     * as well as from queuable jobs (via a trigger operation).
     * @return List<SObject> Records that require updating.
     */
    public List<SObject> startRollupProcessing() {

        validateProcessSettingsBeforeStarting();

        initializeExternalRollupStateData();

        // Loop through each of the detail records and call the appropriate handler processing method
        Map<Id, SObject> recordsToUpdate = new Map<Id, SObject>();
        Id previousParentIdProcessed = null;

        for (Integer n = 0, parentListSize = parentRecords.size(); n < parentListSize; n++) {
            Id parentId = parentRecords[n].Id;

            List<SObject> detailsForParent = detailRecordsByParentId.get(parentId);

            if (detailsForParent != null && isOppContactRoleSoftCreditRollup) {
                detailsForParent = cleanDetailOppsListForSoftCreditMode(parentId, detailsForParent);
                detailRecordsByParentId.put(parentId, detailsForParent);
            }

            // Heap size is precious. There's no need to keep anything other than the first and last
            // collection of CRLP_Rollup instances in the stateful options var. The completeRollupForParent()
            // methods stores everything in this var because it's not sure of which is the first or last.
            // The block below removes everything from this map that is not the first summary record id.
            if (n > 1 && previousParentIdProcessed != null) {
                rollupsDefsByParentId.remove(previousParentIdProcessed);
            }

            // Call the method to complete the actual rollup operation for this parent.
            // The resulting SObject record is returned.
            // The options.rollups collection will contain the list of CRLP_Rollup records
            // that were processed for this rollup operation. This is needed to determine if the
            // resulting record requires an update.
            SObject updatedRecord = completeRollupForSingleSummaryRecord(parentRecords[n]);

            // Does the resulting record require an update?
            if (updatedRecord != null) {
                recordsToUpdate.put(parentId, updatedRecord);
            }

            if (parentListSize > 1) {
                CRLP_Debug_UTIL.clearCurrentRollupState();
            }
            previousParentIdProcessed = parentId;
        }

        // Need to ensure the last record isn't removed it if needs to be written. Just not sure
        // how to know that yet.

        // When running in LDV mode, the last ParentId process should NOT be updated yet (in the batch iteration).
        // This is necessary to handle the situation when a single Parent record may have thousands of detail records
        // passed through multiple batch iterations. The 'final' record will be handled by the finish() method of
        // the LDV Batch job.
        lastParentIdRemovedFromUpdatesList = false;
        if (isSkewMode
                && lastParentIdProcessed != null
                && recordsToUpdate.containsKey(lastParentIdProcessed)
        ) {
            recordsToUpdate.remove(lastParentIdProcessed);
            lastParentIdRemovedFromUpdatesList = true;
        }

        return recordsToUpdate.values();
    }

    /**
    * @description When PreventDupesInRollup is true, this method will purge the list of detail Opps in the detailsForParent
    * collection to remove any that were previously processed. This is used in AccountContactSoftCredit rollups to
    * prevent an Account from both getting soft credit for the same opportunity more than one - when there is more than
    * one Household Contact that got soft credit for that Opportunity.
    */
    @TestVisible
    private List<SObject> cleanDetailOppsListForSoftCreditMode(Id parentId, List<SObject> detailsForParent) {
        List<SObject> oppsToRollup = new List<SObject>();
        for (Integer n = 0, detailListSize = detailsForParent.size(); n < detailListSize; n++) {
            SObject detail = detailsForParent[n];

            Id oppId = (Id)detail.get(Partial_Soft_Credit__c.Opportunity__c);
            if (!isOppAlreadyProcessedForParent(parentId, oppId)) {
                oppsToRollup.add(detail);
            }
        }
        return oppsToRollup;
    }

    /**
     * @description Returns true if executing a SoftCredit rollup type
     */
    @TestVisible
    private Boolean isOppContactRoleSoftCreditRollup {
        get {
            return CRLP_Rollup_SVC.isOppContactRoleSoftCreditRollup(this.rollupType);
        }
    }

    /**
     * @description Returns true if the specified OpportunityId has already been processed for the specified
     * Parent record id
     */
    @TestVisible
    private Boolean isOppAlreadyProcessedForParent(Id parentId, Id oppId) {
        return processedOppIdsByParentId.containsKey(parentId) &&
                processedOppIdsByParentId.get(parentId).contains(oppId);
    }

    /**
     * @description Retrieve the rollup definitions for the specified parent record
     */
    public List<CRLP_Rollup> getRollupDefsForParent(Id parentId) {
        if (rollupsDefsByParentId.containsKey(parentId)) {
            return rollupsDefsByParentId.get(parentId);
        }

        // otherwise need to build these dynamically
        return new List<CRLP_Rollup>();
    }

    /**
     * @description For a given Parent (Summary) record, and set of detail records, complete the rollup of the
     * details to the parent. The List<CRLP_Rollup> collection in ProcessingOptions is used for the actual rollup
     * accumulations. This method is called by all of the entry points for Rollup Calculations -- Batch, LDV, Queueable
     * @param parent Summary SObject record (i.e., the target being rolled up to)
     * @return an updated Summary SObject if it differs from the parent; otherwise it returns null.
     */
    public SObject completeRollupForSingleSummaryRecord(SObject parent) {
        // The Parent record Id has changed, so initiate the rollup and determine if the Summary record
        // has changed or not.
        Id parentId = parent.Id;

        // Determine status of force skew mode field
        initForceSkewModeValues(parent.getSObjectType());
        Boolean isForceSkewModeTrue = false;
        if (this.useForceSkewModeField && parent.isSet(this.qualifiedSkewField))
        {
            isForceSkewModeTrue = (Boolean) parent.get(this.qualifiedSkewField);
        }

        CRLP_VRollupHandler handler = initHandlerClass(parent);

        List<CRLP_Rollup> rollupDefs = doFinalRollup(handler, parentId);
        if (options.doSummaryObjectComparison == false) {
            return null;
        }

        // Build an updated SObject parent record with the calculated rollups
        SObject updatedRecord = handler.getPopulatedSObject();

        // Determine if the updated SObject record is different than the parent.
        Boolean needsUpdate = CRLP_Rollup_SVC.resultsNeedUpdate(parent, updatedRecord, rollupDefs);

        // Unconditionally set force skew flag if parent is Account/Contact and running in skew mode
        if (mode == CRLP_RollupProcessingOptions.BatchJobMode.SkewMode && this.useForceSkewModeField && !isForceSkewModeTrue) {
            updatedRecord.put(this.qualifiedSkewField, true);
            needsUpdate = true;
        }

        if (!needsUpdate) {
            updatedRecord = null;
        }

        return updatedRecord;
    }

    /**
     * @description Set variables associated with handling force skew mode checkbox on Account and Contact
     * @param parentObjType Base SObject type for the dynamically generated query
     */
    private void initForceSkewModeValues(SObjectType parentObjType) {
        if (this.qualifiedSkewField == null) {
            this.qualifiedSkewField = UTIL_Namespace.StrTokenNSPrefix('CustomizableRollups_UseSkewMode__c');
            this.useForceSkewModeField = (parentObjType == Account.SObjectType || parentObjType == Contact.SObjectType);
        }
    }

    /**
     * @description Call the instantiated handler with the parent and details
     * @param handler
     * @param parentId
     * @return Updated Rollup definitions
     */
    private List<CRLP_Rollup> doFinalRollup(CRLP_VRollupHandler handler, Id parentId) {

        // Don't both calling the processRollups() method if there are no details to roll up
        List<SObject> detailRecords = detailRecordsByParentId.get(parentId);
        if (detailRecords != null && !detailRecords.isEmpty()) {

            handler.processRollups(detailRecords, relatedRecordsByDetailId);

            if (isOppContactRoleSoftCreditRollup) {
                Set<Id> previousIds = processedOppIdsByParentId.get(parentId);
                if (previousIds == null) {
                    previousIds = new Set<Id>();
                }
                previousIds.addAll(handler.getListOfOppIdsThatWereRolledUp());
                processedOppIdsByParentId.put(parentId, previousIds);
            }

            // only set the lastParentId when there are actually detail records
            lastParentIdProcessed = parentId;

            // Save the rollup data from the Handler instance into the processing options instance
            if (options.useRollupDefsByParentIdMap == true) {
                rollupsDefsByParentId.put(parentId, CRLP_RollupProcessor_SVC.fullyCloneList(handler.getRollupsList()));
            }
        }

        return handler.getRollupsList();
    }

    /**
     * @description Saved instance of the instantiated handler class to avoid recreating each time. Because the soft credit
     * rollups summary both Account and Contact soft credits at the same time, it's necessary to use a map to separate the
     * instances by the Summary Object Type. It's still much faster than instantiating on every summary record.
     */
    private static Map<CRLP_RollupProcessingOptions.RollupType, CRLP_VRollupHandler> cachedHandlerInstanceByRollupType =
            new Map<CRLP_RollupProcessingOptions.RollupType, CRLP_VRollupHandler>();


    /**
     * @description Instantiate and configure the Rollup Handler class as appropriate for the rollup type.
     * @param parent SObject
     * @return Instantiated handler
     */
    private CRLP_VRollupHandler initHandlerClass(SObject parent) {
        Id parentId = parent.Id;

        CRLP_VRollupHandler handler = cachedHandlerInstanceByRollupType.get(rollupType);
        if (handler == null) {
            Type handlerClassType = CRLP_RollupProcessor_SVC.getHandlerClassType(rollupType);
            CRLP_Debug_UTIL.setCurrentRollupState('Instantiate Handler Class: ' + handlerClassType.getName() + ' for ' + parentId);
            handler = (CRLP_VRollupHandler) handlerClassType.newInstance();
            cachedHandlerInstanceByRollupType.put(rollupType, handler);
        }

        if (UserInfo.isMultiCurrencyOrganization()) {
            handler.setCurrencyCode((String)parent.get('CurrencyIsoCode'));
        }

        // Set the Id of the summary object. This method will also reset and load the appropriate rollup mdt records
        handler.setRollupTypeFilter(rollupTypesToProcess);
        handler.setRecordId(parentId);

        // If the map of Rollups by Parent Id contains this parentId, use that List<CRLP_Rollup> rather than
        // create a new fresh list.
        if (options.useRollupDefsByParentIdMap == true || shouldRetrieveExternalRollupStateData) {
            List<CRLP_Rollup> rollupDefs = getRollupDefsForParent(parentId);
            if (!rollupDefs.isEmpty()) {
                CRLP_Debug_UTIL.setCurrentRollupState('Set stateful rollups collection in Handler Class');
                handler.setRollupsList(rollupDefs);
            }
        }

        return handler;
    }

    /**
     * @description Initializes rollupsDefsByParentId with external rollup data
     */
    private void initializeExternalRollupStateData() {
        if (!shouldRetrieveExternalRollupStateData) {
            return;
        }

        Set<Id> recordIds = new Set<Id>();
        for (SObject parentRecord : parentRecords) {
            if (!rollupsDefsByParentId.containsKey(parentRecord.Id) || rollupsDefsByParentId.get(parentRecord.Id).isEmpty()) {
                recordIds.add(parentRecord.Id);
            }
        }

        if (recordIds.isEmpty()) {
            return;
        }

        Map<Id,List<CRLP_Rollup>> externalRollupStatesById = apiService.getBaseRollupStateForRecords(recordIds, rollupType);
        for (Id parentId : externalRollupStatesById.keySet()) {
            rollupsDefsByParentId.put(parentId, externalRollupStatesById.get(parentId));
        }
    }

    private class CRLP_RollupException extends Exception {}
}