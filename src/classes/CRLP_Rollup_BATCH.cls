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
* @description Customizable Rollups Batch for non-LDV-type Rollups
*/
public class CRLP_Rollup_BATCH implements Database.Batchable<SObject>, Database.Stateful {

    private SObjectType summaryObjectType;
    private List<Id> recordIds;
    private Map<Id, String> errors;

    /*******************************************************************************************************
    * @description Constructs the class, sets the properties
    */
    public CRLP_Rollup_BATCH(SObjectType objType) {
        this.summaryObjectType = objType;
        this.errors = new Map<Id, String>();
    }

    /*******************************************************************************************************
    * @description Constructs the class, sets the properties
    */
    public CRLP_Rollup_BATCH(List<Id> recordIds) {
        this.summaryObjectType = recordIds[0].getSobjectType();
        this.recordIds = recordIds;
        this.errors = new Map<Id, String>();
    }

    /*******************************************************************************************************
    * @description Query all Summary records for the rollups.
    * @param bc BatchableContext passed by the system call
    * @return database.Querylocator
    */
    public database.Querylocator start(Database.BatchableContext bc) {
        Integer maxRelatedOppsForNonLDVMode = CRLP_Rollup_SVC.getMaxRelatedOppsForNonLDVMode();

        // Build a query string of the Allocation__c object. By default this query will include all Opportunity
        // fields referred to by any rollup against the Allocation object.
        String query = CRLP_Query_SEL.getResultsQuery(this.summaryObjectType) +
            ' WHERE ' + (this.summaryObjectType == Contact.SObjectType ? 'Account.' : '') +
            UTIL_Namespace.StrAllNSPrefix('Number_of_Opportunities__c') + ' < :maxRelatedOppsForNonLDVMode';
        if (this.recordIds != null && this.recordIds.size() > 0) {
            query += ' AND Id IN :recordIds';
        }

        return Database.getQueryLocator(query);
    }

    /*******************************************************************************************************
    * @description Handle each group of Summary records to roll-up.
    * @param bc BatchableContext passed by the system call
    * @param scope List of Summary records
    */
    public void execute(Database.BatchableContext bc, List<SObject> summaryRecords) {

        // Get the detail records for the current set of Summary Records
        List<SObject> detailsRecords = CRLP_RollupProcessor_SVC.getDetailRecordsFromParentRecords(summaryRecords);

        // Build the processing options instance
        CRLP_RollupProcessor_SVC.ProcessingOptions options = new CRLP_RollupProcessor_SVC.ProcessingOptions();
        options.mode = CRLP_RollupProcessor_SVC.ProcessingMode.NonLDV;
        options.parentObjType = this.summaryObjectType;
        if (this.summaryObjectType == Account.SObjectType) {
            options.parentKeyField = SObjectType.Opportunity.fields.AccountId.getName();
        } else if (this.summaryObjectType == Contact.SObjectType) {
            options.parentKeyField = SObjectType.Opportunity.fields.Primary_Contact__c.getName();
        }

        // Call the method to do the actual rollups. This returns only records that require updating
        List<SObject> updatedRecords = CRLP_RollupProcessor_SVC.startRollupProcess(summaryRecords, detailsRecords, options);

        // Handle dml on the records
        Map<Id, String> dmlErrors = CRLP_RollupProcessor_SVC.updateChangedRecordsWithLogging(updatedRecords);
        this.errors.putAll(dmlErrors);
    }

    /********************************************************************************************************
     * @description Log any captured DML errors.
     */
    public void finish(Database.BatchableContext bc) {
        // Log DML errors
        CRLP_RollupProcessor_SVC.logDmlErrors(this.errors);
    }

}