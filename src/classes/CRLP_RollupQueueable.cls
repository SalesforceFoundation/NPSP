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
* @description Service class for Queueable (ASynchronous) roll-up operations on any supported Object.
* Basically hands control off to the CRLP_RollupProcessor_SVC.startRollupProcess() method.
*/
public class CRLP_RollupQueueable implements System.Queueable {

    private List<Id> summaryRecordIds;

    /**
     * @description Constructor
     * @param recordIds List<Id> list of Summary Record Id's to roll up for
     */
    public CRLP_RollupQueueable(List<Id> summaryRecordIds) {
        this.summaryRecordIds = summaryRecordIds;
    }

    public void execute(QueueableContext qc) {
        try {
            SObjectType objType = summaryRecordIds[0].getSobjectType();

            CRLP_RollupProcessor_SVC.ProcessingOptions options = new CRLP_RollupProcessor_SVC.ProcessingOptions();
            options.mode = CRLP_RollupProcessor_SVC.ProcessingMode.NonLDV;
            options.parentObjType = objType;
            if (objType == Account.SObjectType) {
                options.parentKeyField = SObjectType.Opportunity.fields.AccountId.getName();
            } else if (objType == Contact.SObjectType) {
                options.parentKeyField = SObjectType.Opportunity.fields.Primary_Contact__c.getName();
            }

            // Query the parent records
            Set<Id> parentIds = new Set<Id>(this.summaryRecordIds);
            String soql = CRLP_Query_SEL.getResultsQuery(objType) + ' WHERE Id IN :parentIds';
            List<SObject> summaryRecords = database.query(soql);

            // Get the detail records for the current set of Summary Records
            List<SObject> detailsRecords = CRLP_RollupProcessor_SVC.getDetailRecordsFromParentRecords(summaryRecords);


            // Call the method to do the actual rollups. This returns only records that require updating
            List<SObject> updatedRecords = CRLP_RollupProcessor_SVC.startRollupProcess(summaryRecords, detailsRecords, options);

            // DML and capture any returned DML errors into a Map by Summary Record Id
            CRLP_RollupProcessor_SVC.updateChangedRecordsWithLogging(updatedRecords);
        }  catch (Exception ex) {
            ERR_Handler.processError(ex, ERR_Handler_API.Context.CRLP);
        }
    }
}