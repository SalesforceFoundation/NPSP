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
* @description Virtual class that all Rollup Source Object Handlers will extend from. Implements only the specific
* methods defined in the IRollupHandler interface.
*/
public virtual class CRLP_VRollupHandler implements CRLP_Rollup_SVC.IRollupHandler {

    /* @description 'Name' of the object referenced in the rollup. Visible to classes that extend this virtual class. */
    protected final String oppObjectName = UTIL_Describe.getObjectDescribe('Opportunity').getName();
    /* @description 'Name' of the object referenced in the rollup. Visible to classes that extend this virtual class. */
    protected final String pmtObjectName = UTIL_Describe.getObjectDescribe('npe01__OppPayment__c').getName();

    /* @description The SObject record being rolled up to. Not visible to classes that extend this virtual class */
    private SObject record;

    /* @description The Id of the record being rolled up to. Visible to classes that extend this virtual class */
    protected Id objectId;

    /* @description The currency code of the target object if multi-currency is enabled. */
    protected String currCode;

    /** @description The default filter to apply to Rollups type records for the processing */
    protected CRLP_RollupProcessingOptions.RollupTypeFilter jobFilter = CRLP_RollupProcessingOptions.RollupTypeFilter.All;

    /**
     * @description Collection of all Rollups for the current instance of the Rollup Handler (by Summary Object record)
     * This collection may be saved in a stateful var in the LDV Batch Job to support calling the Handler multiple
     * times over multiple iterations of a batch job.
     */
    protected List<CRLP_Rollup> rollups = new List<CRLP_Rollup>();

    // ===================================================================================================
    // Class methods that must be overriden by classes that extend this class.
    // ===================================================================================================

    /**
    * @description Constructor: For a given summary object, prepopulates the rollupResults map by rollupId,
    * filtering the rollups to those from the Opportunity and/or OppPayment objects. Partial Soft Credits
    * are handled by a different service class.
    * Logic is implemented by the class that extends this virtual class
    */
    public CRLP_VRollupHandler() { }    // default constructor

    /**
     * @description These will be implemented by the class that extends this class
     * Logic is implemented by the class that extends this virtual class
     */
    public virtual void initRollup() { }
    public virtual void processRollups(List<SObject> details, Map<Id, List<SObject>> childRecordsByDetailId) { }

    // ===================================================================================================
    // Class methods that are NOT overriden by classes that extend this class.
    // ===================================================================================================

    /**
     * @description Since this class can't be instantiated with a constructor that passes parameters, the
     * constructor accepts no params, and this method is called with the record Id
     * @param objectId Id of the 'Summary' record being rolled up to
     */
    public void setRecordId(Id objectId) {
        this.objectId = objectId;
        this.processedOppIds.clear();
        if (this.rollups.size() == 0) {
            // This will call the method in the class that extends this class, not the empty virtual method above.
            initRollup();
        } else {
            // clear all the rolled up values in the current instances of any CRLP_Rollup objects
            resetAllRollups();
        }
    }

    public void setRollupTypeFilter(CRLP_RollupProcessingOptions.RollupTypeFilter jobFilter) {
        this.jobFilter = jobFilter;
    }

    /**
     * @description Rather than recreate the collection of Rollups to use, this sets the collection to a saved list of
     * CRLP_Rollup objects (used when a rollup for a single Id requires more than a single batch iteration).
     * @param rollups List<CRLP_Rollup>. If not provided, this collection is built by the class that extends
     * the VRollupHandler class.
     */
    public void setRollupsList(List<CRLP_Rollup> rollups) {
        this.rollups = rollups;
    }

    /**
     * @return Returns the current collection of List<CRLP_Rollup>
     */
    public List<CRLP_Rollup> getRollupsList() {
        return this.rollups;
    }

    /**
     * @description Set the currency code of the target (Summary) record. This will be used for converting the
     * detail record amount values to the currency of the target record.
     * @param currencyIsoCode
     */
    public void setCurrencyCode(String currCode) {
        this.currCode = currCode;
    }

    /**
     * @description Returns the SObject being rolled up with all target rollup fields filled with a value,
     * whether that value be null or an actual rolled-up value.
     */
    public SObject getPopulatedSObject() {
        this.record = CRLP_Rollup_SVC.createEmptyResultObject(this.objectId, this.rollups);
        Boolean debugMode = CRLP_Debug_UTIL.debuggingLevel == CRLP_Debug_UTIL.LEVEL_MAX;
        for (CRLP_Rollup rollup : this.rollups) {
            Map<String,Object> results = rollup.getFinalValues();
            CRLP_Debug_UTIL.setCurrentRollupState(this.objectId + ': ' + CRLP_Debug_UTIL.getRollupCurrentValues(rollup));
            for (String fld : results.keySet()) {
                if (debugMode) {
                    CRLP_Debug_UTIL.setCurrentRollupState('   ' + fld + ' = ' + results.get(fld));
                }
                this.record.put(fld, results.get(fld));
            }
        }
        return record;
    }

    /**
     * @description Returns a list of OpportunityId's that were "processed" by a rollup, meaning that the filter
     * evaluation succeeded.
     */
    protected Set<Id> processedOppIds = new Set<Id>();
    public Set<Id> getListOfOppIdsThatWereRolledUp() {
        return processedOppIds;
    }

    /**
     * @description Reset all counter vars for each instance of the rollups when the SummaryObject.Id
     * changes. This eliminates the need to reinstantiate RLLP_Rollup each time
     */
    public void resetAllRollups() {
        for (CRLP_Rollup r : this.rollups) {
            r.resetValues();
            r.setCurrencyCode(this.currCode);
        }
    }

    /**
     * @description Either add the passed Rollup__mdt defintion to the collection of CRLP_Rollup or if it's in the
     * same 'group' as existing Rollups, just add the mdt to the collection of rollups rollupsMdt the CRLP_Rollup
     * @param Rollup__mdt
     */
    public void addRollupDefinition(Rollup__mdt rlp) {
        // Should this Rollup__mdt record be added to an existing group of Rollup records?
        Boolean addNewRollup = true;
        for (CRLP_Rollup rollup : this.rollups) {
            if (rollup.isRollupInSameGroup(rlp)) {
                rollup.addNewMDTRecord(rlp);
                addNewRollup = false;
                break;
            }
        }
        if (addNewRollup) {
            CRLP_Rollup rollup = new CRLP_Rollup(rlp);
            rollup.setCurrencyCode(this.currCode);
            this.rollups.add(rollup);
        }
    }
}