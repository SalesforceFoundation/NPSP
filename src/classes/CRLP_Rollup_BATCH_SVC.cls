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
* @description Customizable Rollups service methods specific to Batch and Queueable rollup operations
*
* REFACTOR TO CRLP_RollupPprocessor_SVC
* Will have a new class for CRLP_Rollup_TDTM (that will have the executeRollupsASync() method - with a different name)
*/
public class CRLP_Rollup_BATCH_SVC {

    /**
     * @description Returns true if the current batch iteration is the final batch for the overall batch job
     * @param jobId
     * @return true or false
     */
    public static Boolean isLastBatchItem(Id jobId) {
        AsyncApexJob job = [SELECT JobItemsProcessed, TotalJobItems FROM AsyncApexJob WHERE Id = :jobId];
        return (job.JobItemsProcessed +1 == job.TotalJobItems);
    }

    // TODO -- SEE IF WE CAN COMBINE THE NON-LDV AND LDV METHODS INTO A SINGLE METHOD SHARED BY BOTH
    // WOULD NEED SOME FLAGS TO KNOW WHICH MODE WE'RE IN AND TO ENSURE WE'RE HANDLING DETAILS PROPERLY

    /**
     * @description The main work engine for non-LDV roll-up activities. This method is called from both batch jobs
     * as well as from queuable jobs (via a trigger operation). Accepts a collection of record Id's to
     *
     * @param recordIds
     * @param doUpdate
     * @return List<SObject> Records that require updating.
     */
    public static List<SObject> startRollupsForNonLDV(List<Id> recordIds, Boolean doUpdate) {
        SObjectType objType = recordIds[0].getSobjectType();
        String soql = CRLP_Query_SEL.getResultsQuery(objType) + ' WHERE Id IN :recordIds';
        List<SObject> records = database.query(soql);

        return startRollupsForNonLDV(records, doUpdate);
    }

    public static List<SObject> startRollupsForNonLDV(List<SObject> records, Boolean doUpdate) {
        SObjectType objType = records[0].getSobjectType();

        // Get the parent record Id's
        List<Id> recordIds = new List<Id>();
        for (SObject s : records) {
            recordIds.add((Id)s.get('Id'));
        }

        SObjectType mainObject;
        String detailKeyField;
        CRLP_VRollupHandler handler;
        Type handlerClass;
        List<SObjectType> childObjects = new List<SObjectType>();

        // Determine which handler type to instantiate based on the Summary object
        if (objType == Account.SObjectType) {
            // Opportunity and Payment to Account
            handlerClass = CRLP_RollupAccount_SVC.class;
            mainObject = Opportunity.SObjectType;
            childObjects.add(npe01__OppPayment__c.SObjectType);
            detailKeyField = SObjectType.Opportunity.fields.AccountId.getName();

        } else if (objType == Contact.SObjectType) {
            // Opportunity and Payment to Contact
            handlerClass = CRLP_RollupContact_SVC.class;
            mainObject = Opportunity.SObjectType;
            childObjects.add(npe01__OppPayment__c.SObjectType);
            detailKeyField = SObjectType.Opportunity.fields.Primary_Contact__c.getName();
        }   // Allocations and PartialSoftCredits are handled as LDV processes

        String detailsQuery = CRLP_Query_SEL.getDetailsQuery(mainObject, childObjects);
        detailsQuery += ' WHERE ' + detailKeyField + ' IN :recordIds';
        if (objType == General_Accounting_Unit__c.SObjectType) {
            // In the specific case of the Allocation to GAU roll-up, explicitly filter out any
            // Allocation__c records where the Opportunity__c field is null.
            detailsQuery += ' AND ' + SObjectType.Allocation__c.fields.Opportunity__c.getName() + ' != null';
        }
        detailsQuery += ' LIMIT 49500'; // to avoid any governor limit issues, even in testing, limit the query to under 50K
        List<SObject> details = database.query(detailsQuery);

        // Loop through each of the detail records and call the appropriate handler processing method
        List<SObject> recordsToUpdate = new List<SObject>();
        for (SObject record : records) {
            // Instantiate the handler service
            handler = (CRLP_VRollupHandler) handlerClass.newInstance();
            handler.setRecordId(record.Id);
            if (UserInfo.isMultiCurrencyOrganization()) {
                handler.setCurrencyCode((String)record.get('CurrencyIsoCode'));
            }
            // TODO -- DETAILS HERE NEEDS TO BE BE LIMITED TO JUST THE SPECIFIC PARENT ID, NOT ALL RECORDS IN THIS LIST
            handler.processRollups(details);
            SObject updatedRecord = handler.getPopulatedSObject();
            if (CRLP_Rollup_SVC.resultsNeedUpdate(record, updatedRecord, handler.rollups)) {
                recordsToUpdate.add(updatedRecord);
            }
        }
        if (recordsToUpdate.size() > 0 && doUpdate == true) {
            // TODO Handle DML
            List<Database.SaveResult> srs = database.update(recordsToUpdate, false);
            for(Integer i=0; i<srs.size(); i++) {
                Database.SaveResult sr = srs[i];
                Id recordId = recordsToUpdate[i].Id;
            }
        }
        return recordsToUpdate;
    }

    /**
     * @description used to recieve and return the last Parent record id processed by startRollupsForLDV().
     * The value is saved as a stateful var in the calling batch process
     */
    public static Id ldvCurrentParentId;

    /*******************************************************************************************************
    * @description Does the actual work needed to roll-up a group of Detail Records to a Summary using the LDV
    * process that retains CRLP_Rollup instances throughout multiple batch iterations. The Stateful collection
    * of CRLP_Rollup instances is either reset or passed to a new instance of the LDV Handler Service class.
    * @param details List of Detail records
    * @param parentObjType SObjectType of the Summary parent object
    * @param parentObjField Field API name of the key field in the Detail object with the Id of the Summary parent record
    * @param statefulRollups List<CRLP_Rollup> rollup instances provided by the Batch class.
    * @return SObject[] Collection of Summary parent records to be committed to the database.
    */
    public static List<SObject> startRollupsForLDV(List<SObject> details, SObjectType parentObjType,
            String parentObjField, List<CRLP_Rollup> statefulRollups) {

        // Get the Parent GeneralAccountingUnit records referenced by the Allocation recors in the query scope
        Map<Id, List<SObject>> mapOfRecordsByParentId = new Map<Id, List<SObject>>();
        for (SObject dtl : details) {
            Id parentId = (Id)dtl.get(parentObjField);
            if (!mapOfRecordsByParentId.containsKey(parentId)) {
                mapOfRecordsByParentId.put(parentId, new List<SObject>());
            }
            mapOfRecordsByParentId.get(parentId).add(dtl);
        }
        Set<Id> parentIds = mapOfRecordsByParentId.keySet();
        String soql = CRLP_Query_SEL.getResultsQuery(parentObjType) + ' WHERE Id IN :parentIds';
        Map<Id, SObject> parentMap = new Map<Id, SObject>(database.query(soql) );

        // Loop through the batch of Allocations to handle
        List<SObject> recordsToUpdate = new List<SObject>();
        for (Id parentId : mapOfRecordsByParentId.keySet()) {
            // Clear the list of stateful rollups anytime the parent Id changes
            if (ldvCurrentParentId != parentId) {
                statefulRollups.clear();
            }
            ldvCurrentParentId = parentId;

            SObject updated = finalizeParentRollupForLDV(mapOfRecordsByParentId.get(parentId), parentMap.get(parentId), statefulRollups);
            if (updated != null) {
                recordsToUpdate.add(updated);
            }
        }

        return recordsToUpdate;
    }

    /**
     * @description
     *
     * @param details list of Detail SObject records for a given parent Summary record
     * @param parent Summary SObject record
     * @param statefulRollups List<CRLP_Rollup> rollup instances provided by the Batch class.
     * @return an updated Summary SObject (if there are changes to commit) else null
     */
    private static SObject finalizeParentRollupForLDV(List<SObject> details, SObject parent, List<CRLP_Rollup> statefulRollups) {
        // The Parent record Id has changed, so initiate the rollup and determine if the Summary record
        // has changed or not.
        Type handlerClass;

        // Determine which handler type to instantiate based on the Summary object
        if (parent.getSObjectType() == Account.SObjectType) {
            // Opportunity to Account
            handlerClass = CRLP_RollupAccount_SVC.class;

        } else if (parent.getSObjectType() == Contact.SObjectType) {
            // Opportunity to Contact
            handlerClass = CRLP_RollupContact_SVC.class;

        } else if (parent.getSObjectType() == General_Accounting_Unit__c.SObjectType) {
            // Allocation to GeneralAccountingUnit
            handlerClass = CRLP_RollupGAU_SVC.class;

        }

        CRLP_VRollupHandler handler = (CRLP_VRollupHandler) handlerClass.newInstance();
        handler.setRecordId(ldvCurrentParentId);
        if (statefulRollups != null && statefulRollups.size() > 0) {
            handler.setRollupsList(statefulRollups);
        }
        if (UserInfo.isMultiCurrencyOrganization()) {
            handler.setCurrencyCode((String)parent.get('CurrencyIsoCode'));
        }
        handler.processRollups(details);
        SObject updated = handler.getPopulatedSObject();
        if (CRLP_Rollup_SVC.resultsNeedUpdate(parent, updated, handler.rollups)) {
            return updated;
        } else {
            System.Debug(LoggingLevel.ERROR, '*** NO UPDATE IS NEEDED FOR ' + ldvCurrentParentId + ' ***');
            return null;
        }
    }
}