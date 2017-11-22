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
* @description Customizable Rollups Batch for LDV-type Rollups
*/
public class CRLP_Rollup_BATCH_LDV implements Database.Batchable<SObject>, Database.Stateful {

    private static final Integer MAX_RELATED_OPPS = 500;

    /*******************************************************************************************************
    * @description Stateful collection of Rollups to process
    */
    public List<CRLP_Rollup> statefulRollups;
    public Id currentRecordId;
    private SObjectType batchObjectType;
    private List<Id> recordIds;
    private Map<Id, String> errors;

    /*******************************************************************************************************
    * @description Constructs the class, sets the properties
    */
    public CRLP_Rollup_BATCH_LDV(SObjectType objType) {
        this.batchObjectType = objType;

        // Init the stateful rollups collection
        this.statefulRollups = new List<CRLP_Rollup>();
        this.errors = new Map<Id, String>();
    }

    /*******************************************************************************************************
    * @description Constructs the class, sets the properties
    */
    public CRLP_Rollup_BATCH_LDV(List<Id> recordIds) {
        this.batchObjectType = recordIds[0].getSobjectType();
        this.recordIds = recordIds;
        this.statefulRollups = new List<CRLP_Rollup>();
        this.errors = new Map<Id, String>();
    }

    /*******************************************************************************************************
    * @description Query all Allocation records for the rollups. Using Allocations as the primary object to
    * fully support LDV orgs and data skew scenarios.
    * @param bc BatchableContext passed by the system call
    * @return database.Querylocator
    */
    public database.Querylocator start(Database.BatchableContext bc) {

        // Build a query string for the specified Summary object.
        SObjectType detailObjectType;
        String keyField;
        if (this.batchObjectType == General_Accounting_Unit__c.SObjectType) {
            detailObjectType = Allocation__c.SObjectType;
            keyField = SObjectType.Allocation__c.fields.General_Accounting_Unit__c.getName();
        } else if (this.batchObjectType == Account.SObjectType) {
            detailObjectType = Opportunity.SObjectType;
            keyField = SObjectType.Opportunity.fields.AccountId.getName();
        } else if (this.batchObjectType == Contact.SObjectType) {
            detailObjectType = Opportunity.SObjectType;
            keyField = SObjectType.Opportunity.fields.Primary_Contact__c.getName();
        }
        String query = CRLP_Query_SEL.getDetailsQuery(detailObjectType, new List<SObjectType>()) + ' WHERE ';

        // Add necessary filters to limit the LDV batch job to only the records that should be processed as LDV
        if (this.batchObjectType == General_Accounting_Unit__c.SObjectType) {
            query += ' ' + SObjectType.Allocation__c.fields.Opportunity__c.getName() + ' != null ';
        } else if (detailObjectType == Opportunity.SObjectType) {
            query += 'Account.' + SObjectType.Account.fields.Number_of_Opportunities__c.getName() + ' >= :MAX_RELATED_OPPS';
        }
        if (this.recordIds != null && this.recordIds.size() > 0) {
            query += ' AND ' + keyField + ' IN :recordIds';
        }
        UTIL_Debug.debug(LoggingLevel.WARN, '>> LDV Batch Query =' + query);

        // TODO Review the above query to ensure it's fully selective. Could consider using RecurringDonation = Null ...
        return Database.getQueryLocator(query);
    }

    /*******************************************************************************************************
    * @description Handle each group of Allocation records to roll-up. A Stateful collection of CRLP_Rollup
    * instances is used to allow for potentially more than 50k Allocation records attached to a single GAU.
    * @param bc BatchableContext passed by the system call
    * @param scope List of Allocation__c records
    * // TODO DON'T LIKE THE FACT THAT A SINGLE SUMMARY RECORD MAY BE UPDATED MANY TIMES IN LDV MODE
    */
    public void execute(Database.BatchableContext bc, List<Allocation__c> scope) {
        // Use this flag to tell batch items that aren't the LAST item to not write the last record
        // in that scope. Instead hold onto those rollups in the stateful var for the next batch iteration
        // to handle. Example: A single GAU may have 10000 Allocation records. If the batch job batch size
        // is only 500 records, this will prevent that GAU from being updated 20 times as all the related
        // Allocation records has rolled up through this method. The update will not happen until the GauId
        // changes on the Allocation records being processed.
        Boolean isLastBatchItem = CRLP_Rollup_BATCH_SVC.isLastBatchItem(bc.getJobId());

        CRLP_Rollup_BATCH_SVC.ldvCurrentParentId = this.currentRecordId;
        List<General_Accounting_Unit__c> gausToUpdate = CRLP_Rollup_BATCH_SVC.startRollupsForLDV(scope,
                General_Accounting_Unit__c.SObjectType, 'General_Accounting_Unit__c', this.statefulRollups);
        this.currentRecordId = CRLP_Rollup_BATCH_SVC.ldvCurrentParentId;
        if (gausToUpdate.size() > 0) {
            // TODO Implement AllOrNothing logic
            database.update(gausToUpdate);
        }
    }

    public void finish(Database.BatchableContext bc) {

    }

}