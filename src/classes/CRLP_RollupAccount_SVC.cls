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
* @description Rollup Services unique to the Account rollups from Opportunity and Opportunity+Payments
*/
public class CRLP_RollupAccount_SVC extends CRLP_VRollupHandler {

    /**
     * @description Constructor: For a given summary object, prepopulates the rollupResults map by rollupId,
     * filtering the rollups to those from the Opportunity and/or OppPayment objects. Partial Soft Credits
     * are handled by a different service class.
     * @param accountId The Id of the Summary Account record being rolled up to
     */
    public CRLP_RollupAccount_SVC(Id accountId) {
        super(accountId);
        for (Rollup__mdt r : CRLP_Rollup_SEL.getRollupsBySummaryType().get(Account.SObjectType)) {
            if (r.Detail_Object__r.QualifiedApiName == oppObjectName
                    || r.Detail_Object__r.QualifiedApiName == pmtObjectName) {
                addRollupDefinition(r);
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
        // This service class is specific to Rollups from the Opportunity (or Opp+Payment) to the Account object

        for (Sobject s : details) {

            Opportunity opp = (Opportunity)s;
            for (CRLP_Rollup rollup : this.rollups) {
                Id filterGroupId = rollup.rollupsMdt[0].Filter_Group__c;

                // Process rollups that are coming from the Opportunity only (not from Payment)
                if (rollup.detailObject == oppObjectName) { 
                    // Does this row pass the evaluation?
                    if (CMT_FilterRuleEvaluation_SVC.evaluateFilterGroup(new List<SObject>{ opp }, filterGroupId)) {
                        // YES -- now need to do the actual rollup!
                        CRLP_Operation_SVC.doRollupOperation(rollup, opp, opp);
                    }

                } else if (rollup.detailObject == pmtObjectName) {
                    // Process rollups from the Payment to the Account

                    for (npe01__OppPayment__c pmt : opp.npe01__OppPayment__r) {
                        if (CMT_FilterRuleEvaluation_SVC.evaluateFilterGroup(new List<SObject>{ opp, pmt }, filterGroupId)) {
                            CRLP_Operation_SVC.doRollupOperation(rollup, opp, pmt);
                        }
                    }
                }
            }
        }
    }

    /**
     * @description
     * // TODO -- NOT SURE WHETHER THIS METHOD WILL BE KEPT YET; MIGHT BE AN ENTRY POINT FOR A BUTTON ON THE ACCOUNT
     * @param acctId
     */
    public static void rollupSingleAccount(Id acctId) {
        String acctQuery = CRLP_Query_SEL.getResultsQuery(Account.SObjectType);
        acctQuery += ' WHERE Id = :acctId LIMIT 1';
        Account a = database.query(acctQuery);

        String detailsQuery = CRLP_Query_SEL.getDetailsQuery(Opportunity.SObjectType, new List<SObjectType>{ npe01__OppPayment__c.SObjectType });
        detailsQuery += ' WHERE AccountID = :acctId';
        List<Opportunity> details = database.query(detailsQuery);

        CRLP_RollupAccount_SVC handler = new CRLP_RollupAccount_SVC(acctId);
        handler.setCurrencyCode(null);
        handler.processRollups(details);

        Account updatedAcct = (Account)handler.getPopulatedSObject();
        System.debug(LoggingLevel.ERROR, '> Rollups.count=' + handler.rollups.size());
        if (CRLP_Rollup_SVC.resultsNeedUpdate(a, updatedAcct, handler.rollups)) {
            database.update(updatedAcct);
        } else {
            System.Debug(LoggingLevel.ERROR, '*** NO UPDATE IS NEEDED FOR ' + acctId + ' ***');
        }
    }

}