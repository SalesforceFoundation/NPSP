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
* @description Rollup Services unique to the GUA rollups from Allocations
*/
public class CRLP_RollupGAU_SVC extends CRLP_VRollupHandler {

    public CRLP_RollupGAU_SVC() { }    // default constructor

    /**
     * @description Called by the setRecordId() method in the parent (super) class, this configures the
     * CRLP_Rollup object instances that are used to do the actual rollup work for the target Account record.
     */
    public override void initRollup() {
        buildGroupedRollups(CRLP_RollupProcessingOptions.RollupType.GAU);
    }

    /**
     * @description Primary action method. Called for each record of summaryObject with a list of the detail objects
     * being rolled-up to that summary object. The instance of this class was instantiated with the Summary object.
     * The constructor created a list of Rollup instances for each rollup that will be calculated by this method.
     * This method loops through each Rollup, testing the detail records against the appropriate FilterGroup. If the
     * filter passes, then the detail record(s) are passed to the Rollup.doOperation() method to handle tha actual
     * rollup operations. The state of the rollup (across all detail records) is kept in the instace of the Rollup.
     * @param details List of detail records being rolled up to the Summary object defined in the constructor.
     * @param childRecordsByDetailId Ignored for GAU rollups
     * @return none
     */
    public override void processRollups(List<SObject> details, Map<Id, List<SObject>> childRecordsByDetailId) {
        // This service class is specific to Rollups from the Allocation to the GAU object

        List<Allocation__c> allocs = (List<Allocation__c>)details;
        for (Integer n=0, listSize = allocs.size(); n<listSize; n++) {
            Allocation__c alloc = allocs[n];
            Boolean isOpportunityAllocation = alloc.Opportunity__c != null;
            Boolean isPaymentAllocation = alloc.Payment__c != null;
            Opportunity opp;
            npe01__OppPayment__c payment;
            List<SObject> detailRows;

            if (isOpportunityAllocation) {
                opp = alloc.Opportunity__r;
                detailRows = new List<SObject>{ opp, alloc };
            }
            if (isPaymentAllocation) {
                payment = alloc.Payment__r;
                opp = payment.npe01__Opportunity__r;
                detailRows = new List<SObject>{ opp, payment, alloc };
            } 

            for (Integer nsr=0, rollupsListSize=this.rollups.size(); nsr<rollupsListSize; nsr++) {
                CRLP_Rollup rollup = this.rollups[nsr];
                Id filterGroupId = rollup.filterGroup;
                Boolean isPaymentRollup = rollup.dateObject == pmtObjectName || rollup.detailObject == pmtObjectName;
                // Process rollups for opportunity allocations... this should only have two items: opp, alloc
                if (isOpportunityAllocation && !isPaymentRollup) {
                    // Does this row pass the evaluation?
                    if (CMT_FilterRuleEvaluation_SVC.evaluateFilterGroup(detailRows, filterGroupId)) {
                        // YES -- now need to do the actual rollup!
                        CRLP_Operation_SVC.doRollupOperation(rollup, opp, alloc);
                    }
                }
                
                // Process rollups for payment allocations... this should only have three items for filtering: opp, payment, and alloc
                if (isPaymentAllocation && isPaymentRollup) {
                    // Does this row pass the evaluation?
                    if (CMT_FilterRuleEvaluation_SVC.evaluateFilterGroup(detailRows, filterGroupId)) {
                        // YES -- now need to do the actual rollup!
                        CRLP_Operation_SVC.doRollupOperation(rollup, payment, alloc);
                    }
                }
            }

            // There's no need to keep the filter group evaluation cache beyond the lifetime of a single detail record
            CMT_FilterRuleEvaluation_SVC.clearEvaluationCache();
        }
    }

}