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
* @description Rollup Services unique to the Account roll-ups from Opportunity and Payment objects
*/
public class CRLP_RollupAccount_SVC extends CRLP_VRollupHandler {

    public CRLP_RollupAccount_SVC() { }    // default constructor

    /**
     * @description Called by the setRecordId() method in the parent (super) class, this configures the
     * CRLP_Rollup object instances that are used to do the actual rollup work for the target Account record.
     * For the given summary object, pre-populates the rollupResults map by rollupId,
     * filtering the rollups to those from the Opportunity and/or OppPayment objects. Partial Soft Credits
     * are handled by a different service class.
     */
    public override void initRollup() {
        for (Rollup__mdt r : CRLP_Rollup_SEL.getRollupDefinitionsToUse(
                CRLP_RollupProcessingOptions.RollupType.AccountHardCredit, this.jobFilter)) {
            addRollupDefinition(r);
        }
    }

    /**
     * @description Primary action method. Called for each record of summaryObject with a list of the detail objects
     * being rolled-up to that summary object. The instance of this class was instantiated with the Summary object.
     * The constructor created a list of Rollup instances for each rollup that will be calculated by this method.
     * This method loops through each Rollup, testing the detail records against the appropriate FilterGroup. If the
     * filter passes, then the detail record(s) are passed to the Rollup.doOperation() method to handle tha actual
     * rollup operations. The state of the rollup (across all detail records) is kept in the instace of the Rollup.
     * @param details List of detail records being rolled up to the Summary object defined in the constructor.
     * @param childRecordsByDetailId Payments for each Opportunity. Split out into a Map by Detail (Opp) Id to
     * support LDV orgs where querying the payments in an Opportunity sub-query might cause a CPU timeout
     * @return none
     */
    public override void processRollups(List<SObject> details, Map<Id, List<SObject>> childRecordsByDetailId) {
        // This service class is specific to Rollups from the Opportunity (or Opp+Payment) to the Account object

        for (Integer n=0, listSize = details.size(); n<listSize; n++) {
            Opportunity opp = (Opportunity)details[n];

            for (Integer nsr=0, rollupsListSize=this.rollups.size(); nsr<rollupsListSize; nsr++) {
                CRLP_Rollup rollup = this.rollups[nsr];
                Id filterGroupId = rollup.filterGroup;

                // Process rollups that are coming from the Opportunity only (not from Payment)
                if (rollup.detailObject == oppObjectName) { 
                    // Does this row pass the evaluation?
                    if (CMT_FilterRuleEvaluation_SVC.evaluateFilterGroup(new List<SObject>{ opp }, filterGroupId)) {
                        // YES -- now need to do the actual rollup!
                        CRLP_Operation_SVC.doRollupOperation(rollup, opp, opp);
                    }

                } else if (rollup.detailObject == pmtObjectName) {
                    // Process rollups from the Payment to the Account

                    if (childRecordsByDetailId.get(opp.Id) != null) {
                        List<npe01__OppPayment__c> payments = childRecordsByDetailId.get(opp.Id);
                        for (npe01__OppPayment__c pmt : payments) {
                            if (CMT_FilterRuleEvaluation_SVC.evaluateFilterGroup(new List<SObject>{ opp, pmt }, filterGroupId)) {
                                CRLP_Operation_SVC.doRollupOperation(rollup, opp, pmt);
                            }
                        }
                    }
                }
            }

            // There's no need to keep the filter group evaluation cache beyond the lifetime of a single detail record
            CMT_FilterRuleEvaluation_SVC.clearEvaluationCache();
        }
    }

}