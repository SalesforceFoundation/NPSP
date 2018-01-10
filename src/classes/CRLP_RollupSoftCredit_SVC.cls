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
* @description Rollup Services unique to the Contact Soft Credit roll-ups TO both Contact and Account.
* The Partial_Soft_Credit__c object is used for all Soft Credit Rollups as a Proxy for OpportunityContactRole
* which isn't supported as a selectable Entity in the Rollup__mdt object.
* A Single Instance of this class will be for EITHER the Account or the Contact, but NOT BOTH AT THE SAME TIME!
*/
public class CRLP_RollupSoftCredit_SVC extends CRLP_VRollupHandler {

    public CRLP_RollupSoftCredit_SVC() {
    }    // default constructor

    /**
     * @description Called by the setRecordId() method in the parent (super) class, this configures the
     * CRLP_Rollup object instances that are used to do the actual rollup work for the target Account
     * OR Contact records. Soft Credit rollups operate on both target objects at the same time using a
     * single LDV query in the batch job, but a single instance of this class is for EITHER the Account OR Contact.
     */
    public override void initRollup() {
        // Get Soft Credit Rollups to the Account OR Contact object, but NOT BOTH
        SObjectType targetObjType = this.objectId.getSobjectType();
        if (CRLP_Rollup_SEL.getRollupsBySummaryType().containsKey(targetObjType)) {
            for (Rollup__mdt r : CRLP_Rollup_SEL.getRollupsBySummaryType().get(targetObjType)) {
                // Due to how PartialSoftCredit and Opportunity interact with Rollups, the Detail Object
                // can still be set to Opportunity for some of the PartialSoftCredit rollups. As a result,
                // the only reliable ObjectField to check against is AmountObject since that will always point
                // to the PartialSoftCredit object for these types of rollups.
                if (r.Amount_Object__r.QualifiedApiName == pscObjectName) {
                    addRollupDefinition(r);
                }
            }
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
     * @return none
     */
    public override void processRollups(List<SObject> details) {
        // This service class is specific to Rollups from the PartialSoftCredit to the Account AND/OR Contact object

        for (Partial_Soft_Credit__c psc : (List<Partial_Soft_Credit__c>)details) {
            Opportunity opp = psc.Opportunity__r;
            for (CRLP_Rollup rollup : this.rollups) {
                Id filterGroupId = rollup.rollupsMdt[0].Filter_Group__c;

                // Does this row pass the evaluation?
                if (CMT_FilterRuleEvaluation_SVC.evaluateFilterGroup(new List<SObject>{ opp, psc }, filterGroupId)) {
                    // YES -- now need to do the actual rollup!
                    CRLP_Operation_SVC.doRollupOperation(rollup, opp, psc);
                }
            }
        }
    }
}