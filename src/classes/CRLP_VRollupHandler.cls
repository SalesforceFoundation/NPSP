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
* @group Rollups
* @group-content ../../ApexDocContent/Rollups2.htm
* @description Virtual class that all Rollup Source Object Handlers will extend from. Implements only the specific
* methods defined in the IRollupHandler interface.
*/
public virtual class CRLP_VRollupHandler implements CRLP_Rollup_SVC.IRollupHandler {

    /* @description 'Name' of the object referenced in the rollup. Visible to classes that extend this virtual class. */
    protected final String conObjectName = UTIL_Describe.getObjectDescribe('Contact').getName();
    /* @description 'Name' of the object referenced in the rollup. Visible to classes that extend this virtual class. */
    protected final String oppObjectName = UTIL_Describe.getObjectDescribe('Opportunity').getName();
    /* @description 'Name' of the object referenced in the rollup. Visible to classes that extend this virtual class. */
    protected final String pmtObjectName = UTIL_Describe.getObjectDescribe('npe01__OppPayment__c').getName();
    /* @description 'Name' of the object referenced in the rollup. Visible to classes that extend this virtual class. */
    protected final String ocrObjectName = UTIL_Describe.getObjectDescribe('OpportunityContactRole').getName();
    /* @description 'Name' of the object referenced in the rollup. Visible to classes that extend this virtual class. */
    protected final String gauObjectName = UTIL_Describe.getObjectDescribe('General_Accounting_Unit__c').getName();
    /* @description 'Name' of the object referenced in the rollup. Visible to classes that extend this virtual class. */
    protected final String allocObjectName = UTIL_Describe.getObjectDescribe('Allocation__c').getName();

    /* @description The SObject record being rolled up to. Not visible to classes that extend this virtual class */
    private SObject record;

    /* @description The Id of the record being rolled up to. Visible to classes that extend this virtual class */
    protected Id objectId;

    /* @description The currency code of the target object if multi-currency is enabled. */
    protected String currCode;

    /**
     * @description Collection of all Rollups for the current instance of the Rollup Handler (by Summary Object record)
     * This collection may be saved in a stateful var in the LDV Batch Job to support calling the Handler multiple
     * times over multiple iterations of a batch job.
     */
    public List<CRLP_Rollup> rollups = new List<CRLP_Rollup>();

    // ===================================================================================================
    // Class methods that must be overriden by classes that extend this class.
    // ===================================================================================================

    /**
    * @description Constructor: For a given summary object, prepopulates the rollupResults map by rollupId,
    * filtering the rollups to those from the Opportunity and/or OppPayment objects. Partial Soft Credits
    * are handled by a different service class.
    * Logic is implemented by the class that extends this virtual class
    * @param objectId The Id of the Summary record being rolled up to
    */
    public CRLP_VRollupHandler() { }    // default constructor

    /* @description This method is always overriden by classes that implement this Virtual class */
    public CRLP_VRollupHandler(Id objectId) {
        this.objectId = objectId;
        this.rollups.clear();
    }

    /**
     * @description Overloaded constructor that accepts a list of Rollup instances. This constructor
     * is used when instantiating a new handler service to process a new set of detail records.
     * @param objectId
     * @param rollups
     */
    public CRLP_VRollupHandler(Id objectId, List<CRLP_Rollup> rollups) {
        this.objectId = objectId;
        this.currCode = currCode;
    }

    /**
     * @description Will be implemented by the class that extends this class
     * Logic is implemented by the class that extends this virtual class
     */
    public virtual void processRollups(List<SObject> details) { }

    // ===================================================================================================
    // Class methods that are NOT overriden by classes that extend this class.
    // ===================================================================================================

    /**
     * @description Returns the SObject being rolled up with all target rollup fields filled with a value,
     * whether that value be null or an actual rolled-up value.
     */
    public SObject getPopulatedSObject() {
        this.record = CRLP_Rollup_SVC.createEmptyResultObject(this.objectId, this.rollups);
        for (CRLP_Rollup rollup : this.rollups) {
            Map<String,Object> results = rollup.getFinalValues();
            for (String fld : results.keySet()) {
                this.record.put(fld, results.get(fld));
            }
        }
        return record;
    }

    /**
     * @description Reset all counter vars for each instance of the rollups when the SummaryObject.Id
     * changes. This eliminates the need to reinstantiate RLLP_Rollup each time
     */
    public void resetAllRollups() {
        for (CRLP_Rollup r : this.rollups) {
            r.resetValues();
        }
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
     * @description Either add the passed Rollup__mdt defintion to the collection of RLLP_Rollup or if it's in the
     * same 'group' as existing Rollups, just add the mdt to the collection of rollups rollupsMdt the RLLP_Rollup
     * @param Rollup__mdt
     */
    public void addRollupDefinition(Rollup__mdt rlp) {
        // Should this Rollup__mdt record be added to an existing group of Rollup records?
        Boolean addNewRollup = true;
        for (CRLP_Rollup rollup : this.rollups) {
            if (rollup.isRollupInSameGroup(rlp)) {
                rollup.rollupsMdt.add(rlp);
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