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
* @group Rollups
* @group-content ../../ApexDocContent/Rollups2.htm
* @description Abstract base class for all Customizable Rollup batch jobs
*/
public abstract class CRLP_AbstractRollup_BATCH {

    /** @description Because Salesforce may call the execute method with sorted blocks of data out of sequence
     * it's necessary to store the working rollup data in a stateful map. Rather than write the current state to
     * the parent record multiple times, the code will keep uncommitted rollup data in the stateful var for up to
     * this number of batch iterations. After that number, the record will be committed to the database. There
     * are a couple of assumptions here: a) Salesforce will not likely put data so much out of sequence that there
     * are more than 30 batches of data between two batches for the same parent id; b) 30 is an acceptable number
     * for heap size.
     */
    private Integer MAX_BATCHES_TO_HOLD_BEFORE_COMMIT = 50;

    /** @description If a given ParentId has a element in the statefulRollupsById map that has not been updated
     * in over 500 batch iterations, assume that it will not appear in the collection again and remove it from
     * map entirely - to reduce heap usage.
     */
    private Integer MAX_BATCHES_TO_KEEP_ID_IN_STATEFUL_ROLLUPS_MAP = 500;

    /** @description Set to True if the batch job is of an LDV type; where the primary object is the detail */
    protected Boolean isLdvBatchJob = false;

    /** @description The default filter to apply to Rollups type records for the processing */
    protected CRLP_RollupProcessingOptions.RollupTypeFilter jobFilter = CRLP_RollupProcessingOptions.RollupTypeFilter.All;

    /** @description The job type for this batch job -- AccountHardCredit, AccountSoftCredit, etc. */
    protected CRLP_RollupProcessingOptions.RollupType jobType;

    /**
    * @description Stateful collection of Rollups used to hold Rollups for Contacts and Accounts that
    * span beyond a single batch iteration
    */
    protected Map<Id, List<CRLP_Rollup>> statefulRollupsById = new Map<Id, List<CRLP_Rollup>>();

    /** @description This is built one time at the start of the batch process and then re-used throughout
     * the rest of the batch processing logic. It's implemented as a Map<SObjectType> to support the Soft Credit
     * LDV job where both Account and Contact rollups are processed by the same job. This data is passed in the
     * ProcessingOptions collection to the processor. It's also used to pre-generate the SOQL used to retrieve
     * summary or detail records rather than build that in every single batch iteration. Basically this collection
     * is injected into the CRLP_Rollup_SEL cache to significantly simplify and narrow the pr
     */
    protected Map<SObjectType, List<Rollup__mdt>> statefulCacheOfRollupsToBeProcessed = new Map<SObjectType, List<Rollup__mdt>>();

    /**
     * @description This list is effectively the keyset of statefulRollupsById, but it's used to keep the list of
     * Id's in a specific sequence so that element 0 can be dropped when the 1000th element is added. When dropped,
     * that key is also removed from the statefulRollupsById map. The intent is to keep the heap size for the stateful
     * Map of CRLP_Rollup data limited to avoid a governor limit when dealing with millions of records.
     */
    protected List<Id> statefulListOfSavedIds;

    /**
     * @description Map of Opportunity Id's already processed by Account to avoid duplicating a donation amount
     * to the Account when rolling up soft credits by the Contact.AccountId
     */
    protected Map<Id,Set<Id>> statefulMapOfOppIdsByAcct;

    /** @description Rather than commit the parent record every time the lastParentIdProcessed is changed,
     * which can cause a single parent to be committed multiple times, this is used to track which parent records
     * have not yet been committed. This is useful when Salesforce calls the execute() method with blocks of data
     * out of sequence.
     */
    protected Map<Id, Integer> parentIdsNotCommittedWithBatch = new Map<Id, Integer>();
    protected Map<Id, Integer> lastBatchIterationByParentId = new Map<Id, Integer>();

    /** @description Simple counters used to track state */
    protected Integer batchIteration = 0;
    protected Integer totalRecordsModified = 0;
    protected Integer totalCommits=0;

    /** @description Are there Soft Credits to Contact-Account rollups to execute? */
    protected Boolean hasAccountSoftCreditRollups = false;

    /** @description Are there Soft Credits to Contact rollups to execute? */
    protected Boolean hasContactSoftCreditRollups = false;

    /** @description Specified list of Summary (Account, Contact or GAU) Id's to roll up */
    protected List<Id> recordIds;

    /** @description The Summary Object Type this batch job will process */
    protected SObjectType summaryObjectType;

    /*******************************************************************************************************
     * @description Constructs the class, inits the class instance vars used across all CRLP batch jobs
     */
    public CRLP_AbstractRollup_BATCH() {
        this.statefulRollupsById = new Map<Id, List<CRLP_Rollup>>();
        this.statefulMapOfOppIdsByAcct = new Map<Id, Set<Id>>();
        this.statefulListOfSavedIds = new List<Id>();
        initSoftCreditRollupTypes();
    }

    /*******************************************************************************************************
     * @description Constructs the class - rollup is for a specific Summary SObject
     */
    public CRLP_AbstractRollup_BATCH(SObjectType objType) {
        this();
        this.summaryObjectType = objType;
    }

    /*******************************************************************************************************
     * @description Constructs the class - Rollup is for a specific set of Summary Object Id's
     */
    public CRLP_AbstractRollup_BATCH(List<Id> recordIds) {
        this();
        this.summaryObjectType = recordIds[0].getSobjectType();
        this.recordIds = recordIds;
    }

    /**
     * @description Set the hasAccountSoftCreditRollups and hasContactSoftCreditRollups instance vars based on
     * the current active customizable rollups in the org
     */
    private void initSoftCreditRollupTypes() {
        this.hasContactSoftCreditRollups = CRLP_Rollup_SVC.hasActiveSoftCreditRollupsForSObject(Contact.SObjectType);
        this.hasAccountSoftCreditRollups = CRLP_Rollup_SVC.hasActiveSoftCreditRollupsForSObject(Account.SObjectType);
    }

    /**
     * @description Resequence the Parent (Summary) records to be in the exact order of the detail records
     * using the defined parent Id
     * @param parentIds
     * @param summaryRecords
     * @return a list of Parent (Summary) SObject records in the proper order
     */
    protected List<SObject> queryAndSequenceSummaryRecords(List<Id> parentIds, String soql) {
        // Resequence the Parent (Summary) records to be in the exact order of the detail records
        // using the defined parent Id
        List<SObject> reorderedSummaryRecords = new List<SObject>();
        Map<Id, SObject> mapOfSummaryRecords = new Map<Id, SObject>(database.query(soql));
        for (Id parentId : parentIds) {
            reorderedSummaryRecords.add(mapOfSummaryRecords.get(parentId));
        }
        return reorderedSummaryRecords;
    }

    /********************************************************************************************************
     * @description Create an instance of the CRLP_RollupProcessingOptions.ProcessingOptions class to use with the
     * CRLP_RollupProcessor_SVC.startRollupProcess() calls.
     * @return CRLP_RollupProcessingOptions.ProcessingOptions
     */
    protected CRLP_RollupProcessingOptions.ProcessingOptions initOptionsInstance() {
        CRLP_RollupProcessingOptions.ProcessingOptions options = new CRLP_RollupProcessingOptions.ProcessingOptions();
        options.mode = (this.isLdvBatchJob ? CRLP_RollupProcessingOptions.BatchJobMode.LDV : CRLP_RollupProcessingOptions.BatchJobMode.NonLDV);
        options.detailObjType = Opportunity.SObjectType;    // the default type
        options.parentObjType = this.summaryObjectType;
        options.rollupJobType = this.jobType;
        options.rollupTypesToProcess = this.jobFilter;

        // Start by cleaning up the stateful data
        cleanStatefulRollupsList();

        if (this.summaryObjectType == Account.SObjectType) {
            options.parentKeyField = SObjectType.Opportunity.fields.AccountId.getName();
        } else if (this.summaryObjectType == Contact.SObjectType) {
            options.parentKeyField = SObjectType.Opportunity.fields.Primary_Contact__c.getName();
        } else if (this.summaryObjectType == General_Accounting_Unit__c.SObjectType) {
            options.parentKeyField = SObjectType.Allocation__c.fields.General_Accounting_Unit__c.getName();
            options.detailObjType = Allocation__c.SObjectType;
        }

        // Retrieve and store the cached list of Rollup__mdt records into the Rollups Processor
        // so that the list never changes throughout the life of the batch job
        if (this.statefulCacheOfRollupsToBeProcessed.containsKey(this.summaryObjectType)) {
            CRLP_Rollup_SEL.stuffRollupsByTypeCache(this.jobType, this.jobFilter,
                    this.statefulCacheOfRollupsToBeProcessed.get(this.summaryObjectType));
        }

        return options;
    }

    /**
     * @description Retrieve a list of unique parent Id records from a set of detail records, taking into account
     * parent id records from previous batches that may be in the stateful collection of id's not yet committed.
     * @param objType
     * @param detailRecords
     * @param keyField
     * @return List of Unique Parent (Summary) record Id's
     */
    protected List<Id> getUniqueParentIds(SObjectType objType, List<SObject> detailRecords, String keyField) {
        // Get all parent records to be processed by this batch iteration
        List<Id> parentIds = getParentIdsFromDetailRecords(detailRecords, keyField);
        if (!this.parentIdsNotCommittedWithBatch.isEmpty()) {
            Set<Id> uniqueParentIds = new Set<Id>(parentIds);
            // Don't add the last parent Id to the list UNLESS at least four batches have gone by. This is way of
            // handling Salesforce's out of sequence baches while avoiding too many commits for a single record
            for (Id lastId : this.parentIdsNotCommittedWithBatch.keySet()) {
                if (lastId.getSobjectType() == objType) {
                    if (this.batchIteration - this.parentIdsNotCommittedWithBatch.get(lastId) > MAX_BATCHES_TO_HOLD_BEFORE_COMMIT) {
                        if (!uniqueParentIds.contains(lastId)) {
                            parentIds.add(lastId);
                            uniqueParentIds.add(lastId);
                            this.parentIdsNotCommittedWithBatch.remove(lastId);
                        }
                    }
                }
            }
        }
        return parentIds;
    }

    /**
     * @description For a given set of records, returns a Set<Id> of parent records using the passed field name as the parent
     * @param detailRecords List<SObject>
     * @param parentKeyField API Name of the parent field to use for the Id
     * @return List<Id>
     */
    protected List<Id> getParentIdsFromDetailRecords(List<SObject> detailRecords, String parentKeyField) {
        Set<Id> parentIdSet = new Set<Id>();
        List<Id> parentIds = new List<Id>();
        // If the parentKeyField is something like Contact.AccountId, then have to retrieve the parent SObject
        // first and then get the field value.
        String parentObjectField;
        if (parentKeyField.contains('.')) {
            parentObjectField = parentKeyField.split('\\.')[0];
            parentKeyField = parentKeyField.split('\\.')[1];
        }
        for (SObject dtl : detailRecords) {
            SObject dtlRecord = dtl;
            if (parentObjectField != null) {
                dtlRecord = dtl.getSObject(parentObjectField);
            }
            if (dtlRecord.get(parentKeyField) != null) {
                Id parentId = (Id)dtlRecord.get(parentKeyField);
                // Use a set to ensure that the parentId is only in the collection one time since there is no
                // contains() yet, but use a List to keep the parentId records in the exact same sequence
                // that they are in the details collection
                if (!parentIdSet.contains(parentId)) {
                    parentIds.add(parentId);
                    parentIdSet.add(parentId);
                }
            }
        }
        return parentIds;
    }

    /**
     * @description To prevent a heap size issue, no stateful List<Rollup> collection will be kept stateful
     * for more than a defined number of batch iterations (500). In testing, we're not seeing sorted data
     * being out of sequence by more than 150 batch iterations, therefore holding them for no more than
     * 500 should be sufficient to ensure the data isn't cleared too soon while avoiding a heap size error.
     */
    protected void cleanStatefulRollupsList() {
        Integer removeFromBeforeBatchNumber = this.batchIteration - MAX_BATCHES_TO_KEEP_ID_IN_STATEFUL_ROLLUPS_MAP;
        if (removeFromBeforeBatchNumber > 0) {
            for (Id parentId : this.statefulRollupsById.keySet()) {
                if (this.lastBatchIterationByParentId.get(parentId) < removeFromBeforeBatchNumber) {
                    this.statefulRollupsById.remove(parentId);
                    this.lastBatchIterationByParentId.remove(parentId);
                    if (this.parentIdsNotCommittedWithBatch != null && this.parentIdsNotCommittedWithBatch.containsKey(parentId)) {
                        this.parentIdsNotCommittedWithBatch.remove(parentId);
                    }
                    if (this.statefulMapOfOppIdsByAcct != null && this.statefulMapOfOppIdsByAcct.containsKey(parentId)) {
                        this.statefulMapOfOppIdsByAcct.remove(parentId);
                    }
                }
            }
        }
    }
}