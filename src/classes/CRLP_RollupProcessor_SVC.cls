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
* @description Customizable Rollups service methods specific to Batch and Queueable rollup operations
*
*/
public class CRLP_RollupProcessor_SVC {

    /**
     * @description The main work engine for roll-up activities. This method is called from both batch jobs
     * as well as from queuable jobs (via a trigger operation). Accepts a collection of summary AND detail records
     * and a ProcessingOptions object instance that defines the parameters to use for the rollup work.
     * @param summaryRecords Summary Records
     * @param detailRecords Detail Records for the related Summary Records
     * @param childRecordsByDetailId Related child records for detail record (ex: Payments for an Opportunity)
     * @param options ProcessingOptions
     * @return List<SObject> Records that require updating.
     */
    public static List<SObject> startRollupProcess(List<SObject> summaryRecords, List<SObject> detailRecords,
            Map<Id, List<SObject>> childRecordsByDetailId, CRLP_RollupProcessingOptions.ProcessingOptions options) {

        // The parentKeyField field may be have dot-notation (ex: Contact__r.AccountId)
        // If this is the case, need to parse out the two components to use
        String parentObjectField, parentKeyField = options.parentKeyField;
        if (parentKeyField.contains('.')) {
            parentObjectField = parentKeyField.split('\\.')[0];
            parentKeyField = parentKeyField.split('\\.')[1];
        }

        // Convert the details list into a Map of details by ParentId
        Map<Id, List<SObject>> mapOfDetailsByParentId = new Map<Id, List<SObject>>();
        for (SObject dtl : detailRecords) {
            // Is there a parent object to retrieve?
            SObject dtlRecord = dtl;
            if (parentObjectField != null) {
                dtlRecord = dtl.getSObject(parentObjectField);
            }

            Id parentId = (Id) dtlRecord.get(parentKeyField);
            if (!mapOfDetailsByParentId.containsKey(parentId)) {
                mapOfDetailsByParentId.put(parentId, new List<SObject>());
            }
            mapOfDetailsByParentId.get(parentId).add(dtl);
        }

        // Loop through each of the detail records and call the appropriate handler processing method
        Map<Id, SObject> recordsToUpdate = new Map<Id, SObject>();
        Id previousParentIdProcessed = null;
        for (Integer ns=0, listSizeSum=summaryRecords.size(); ns<listSizeSum; ns++) {
            Id parentId = summaryRecords[ns].Id;

            List<SObject> detailsForParent = mapOfDetailsByParentId.get(parentId);

            // When PreventDupesInRollup is true, ensure the list of Opps in the detailsForParent
            // collection is unique by Opportunity Id
            if (detailsForParent != null && 
                (options.rollupJobType == CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit ||
                    options.rollupJobType == CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit)) {
                List<SObject> oppsToRollup = new List<SObject>();
                for (Integer nd=0, listSizeDtl=detailsForParent.size(); nd<listSizeDtl; nd++) {
                    SObject dtl = detailsForParent[nd];
                    Id dtlId = (Id)dtl.get(Partial_Soft_Credit__c.Opportunity__c);
                    if (!options.mapOfProcessedOppIdsByParentId.containsKey(parentId) ||
                            !options.mapOfProcessedOppIdsByParentId.get(parentId).contains(dtlId)) {
                        oppsToRollup.add(dtl);
                    }
                }
                detailsForParent = oppsToRollup;
            }

            // Heap size is precious. There's no need to keep anything other than the first and last
            // collection of CRLP_Rollup instances in the stateful options var. The completeRollupForParent()
            // methods stores everything in this var because it's not sure of which is the first or last.
            // The block below removes everything from this map that is not the first summary record id.
            if (ns > 1 && previousParentIdProcessed != null) {
                options.mapOfRollupsByParentId.remove(previousParentIdProcessed);
            }

            // Call the method to complete the actual rollup operation for this parent.
            // The resulting SObject record is returned.
            // The options.rollups collection will contain the list of CRLP_Rollup records
            // that were processed for this rollup operation. This is needed to determine if the
            // resulting record requires an update.
            SObject updatedRecord = completeRollupForParent(summaryRecords[ns], detailsForParent, childRecordsByDetailId, options);

            // Does the resulting record require an update?
            if (updatedRecord != null) {
                recordsToUpdate.put(parentId, updatedRecord);
            }

            if (listSizeSum > 1) {
                CRLP_Debug_UTIL.clearCurrentRollupState();
            }
            previousParentIdProcessed = parentId;
        }

        // Need to ensure the last record isn't removed it if needs to be written. Just not sure
        // how to know that yet.

        // When running in LDV mode, the last ParentId process should NOT be updated yet (in the batch iteration).
        // This is necessary to handle the situation when a single Parent record may have thousands of detail records
        // passed through multiple batch iterations. The 'final' record will be handled by the finish() method of
        // the LDV Batch job.
        options.lastParentIdRemovedFromUpdatesList = false;
        if (options.mode == CRLP_RollupProcessingOptions.BatchJobMode.SkewMode && options.lastParentIdProcessed != null &&
                recordsToUpdate.containsKey(options.lastParentIdProcessed)) {
            recordsToUpdate.remove(options.lastParentIdProcessed);
            options.lastParentIdRemovedFromUpdatesList = true;
        }

        return recordsToUpdate.values();
    }

    /**
     * @description Returns the Type of the appropriate CRLP_RollupXXXX_SVC class to use for handling the
     * rollups based on the SObjectType of the Summary object
     * @param summObjType Summary Object Type
     * @param detailObjType Detail Object Type
     * @return ApexClassType
     */
    private static Type getHanderClassType(CRLP_RollupProcessingOptions.ProcessingOptions options) {
        Type handlerClass;
        if (options.rollupJobType == CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit
                || options.rollupJobType == CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit) {
            handlerClass = CRLP_RollupSoftCredit_SVC.class;

        } else if (options.rollupJobType == CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit) {
            handlerClass = CRLP_RollupAccSoftCredit_SVC.class;

        } else if (options.rollupJobType == CRLP_RollupProcessingOptions.RollupType.AccountHardCredit) {
            // Opportunity and Payment to Account
            handlerClass = CRLP_RollupAccount_SVC.class;

        } else if (options.rollupJobType == CRLP_RollupProcessingOptions.RollupType.ContactHardCredit) {
            // Opportunity and Payment  to Contact
            handlerClass = CRLP_RollupContact_SVC.class;

        } else if (options.rollupJobType == CRLP_RollupProcessingOptions.RollupType.GAU) {
            // Allocation to GeneralAccountingUnit
            handlerClass = CRLP_RollupGAU_SVC.class;

        } else if (options.rollupJobType == CRLP_RollupProcessingOptions.RollupType.RecurringDonations) {
            // Opportunity to RecurringDonation
            handlerClass = CRLP_RollupRD_SVC.class;

        }
        return handlerClass;
    }

    /**
     * @description For given set of Summary records, returns a List of the related Detail records (always Opportunity?)
     * @param summaryRecords List<SObject>
     * @param includeChildPayments True if npe01__OppPayment__c child records should be included in the query
     * This is passed through to the getFullDetailsQueryForSummaryRecords() method
     * @return List<SObject> detailRecords to roll up to the summary records
     */
    public static List<SObject> getDetailOppRecordsForParentRecords(List<SObject> summaryRecords, Boolean includeChildPayments,
            CRLP_RollupProcessingOptions.ProcessingOptions options) {
        // Get the parent record Id's
        Set<Id> summaryRecordIds = new Set<Id>();
        SObjectType objType;
        for (SObject s : summaryRecords) {
            summaryRecordIds.add(s.Id);
            if (objType == null) {
                objType = s.Id.getSobjectType();
            }
        }

        npo02__Households_Settings__c householdSettings = UTIL_CustomSettingsFacade.getHouseholdsSettings();
        String detailsQuery = CRLP_Query_SEL.buildFullDetailsQueryForSummaryRecords(summaryRecordIds, includeChildPayments, options);

        String orderBy;
        List<String> whereClauses = new List<String>();

        if (detailsQuery.containsIgnoreCase('ORDER BY ')) {
            orderBy = detailsQuery.split('ORDER BY')[1];
            detailsQuery = detailsQuery.split('ORDER BY')[0];
        }

        if (detailsQuery.containsIgnoreCase(' WHERE ')) {
            whereClauses.add(detailsQuery.split(' WHERE ')[1]);
            detailsQuery = detailsQuery.split(' WHERE ')[0];
        }

        if (options.rollupJobType != CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit) {
            // Identify a common filter that can be applied to the main query to reduce the number of records queried
            String addlFilter = CRLP_Query_SEL.buildCommonQueryFilterOnOpportunity(summaryRecords[0].getSObjectType(),
                    Opportunity.SObjectType, CRLP_Rollup_SEL.getRollupDefinitionsToUse(options.rollupJobType, options.rollupTypesToProcess));
            if (!String.isEmpty(addlFilter)) {
                whereClauses.add(addlFilter);
            }
        }

        // Exclude Organization Donations from Contact Hard Credit rollups (where Opp.Account.SYSTEM_IsIndividual=false)
        // When the npo02__Always_Rollup_to_Primary_Contact__c is field is unchecked.
        if (objType == Contact.SObjectType && householdSettings.npo02__Always_Rollup_to_Primary_Contact__c == false) {
            whereClauses.add('Account.npe01__SYSTEMIsIndividual__c = True');
        }

        if (!whereClauses.isEmpty()) {
            detailsQuery += ' WHERE ' + String.join(whereClauses, ' AND ');
        }

        // Sort the records by the parent key field
        if (options.parentKeyField != null && orderBy == null) {
            orderBy = options.parentKeyField;
        }

        // Force the details query to sort by Ascending CreatedDate so that the records are process
        // in the order in which they were created in the database. Thus the 'first' is truly the first
        // and the last is truly the last.
        if (orderBy != null) {
            detailsQuery += ' ORDER BY ' + orderBy + ', CreatedDate ASC';
        } else {
            detailsQuery += ' ORDER BY CreatedDate ASC';
        }
        return database.query(detailsQuery);
    }

    /**
     * @description Saved instance of the instantiated handler class to avoid recreating each time. Because the soft credit
     * rollups summary both Account and Contact soft credits at the same time, it's necessary to use a map to separate the
     * instances by the Summary Object Type. It's still much faster than instantiating on every summary record.
     */
    private static Map<CRLP_RollupProcessingOptions.RollupType, CRLP_VRollupHandler> handlersMapByType =
            new Map<CRLP_RollupProcessingOptions.RollupType, CRLP_VRollupHandler>();

    /**
     * @description For a given Parent (Summary) record, and set of detail records, complete the rollup of the
     * details to the parent. The List<CRLP_Rollup> collection in ProcessingOptions is used for the actual rollup
     * accumulations. This method is called by all of the entry points for Rollup Calculations -- Batch, LDV, Queueable
     * @param parent Summary SObject record
     * @param detailRecords list of Detail SObject records for a given parent Summary record
     * @param childRecordsByDetailId Related child records for detail record (ex: Payments for an Opportunity)
     * @param options ProcessingOptions. Contains List<CRLP_Rollup> rollup instances passed by referenced and
     * modified within this method.
     * @return an updated Summary SObject if it differs from the parent; otherwise it returns null.
     */
    public static SObject completeRollupForParent(SObject parent, List<SObject> detailRecords,
            Map<Id, List<SObject>> childRecordsByDetailId, CRLP_RollupProcessingOptions.ProcessingOptions options) {
        // The Parent record Id has changed, so initiate the rollup and determine if the Summary record
        // has changed or not.
        Id parentId = parent.Id;

        CRLP_VRollupHandler handler = handlersMapByType.get(options.rollupJobType);
        if (handler == null) {
            Type handlerClassType = getHanderClassType(options);
            CRLP_Debug_UTIL.setCurrentRollupState('Instantiate Handler Class: ' + handlerClassType.getName() + ' for ' + parentId);
            handler = (CRLP_VRollupHandler) handlerClassType.newInstance();
            handlersMapByType.put(options.rollupJobType, handler);
        }

        if (UserInfo.isMultiCurrencyOrganization()) {
            handler.setCurrencyCode((String)parent.get('CurrencyIsoCode'));
        }

        // Set the Id of the summary object. This method will also reset and load the appropriate rollup mdt records
        handler.setRollupTypeFilter(options.rollupTypesToProcess);
        handler.setRecordId(parentId);

        // If the map of Rollups by Parent Id contains this parentId, use that List<CRLP_Rollup> rather than
        // create a new fresh list.
        if (options.mode == CRLP_RollupProcessingOptions.BatchJobMode.SkewMode && options.getUpdatedMapOfRollupsByParentId() != null &&
                options.getUpdatedMapOfRollupsByParentId().get(parentId) != null) {
            CRLP_Debug_UTIL.setCurrentRollupState('Set stateful rollups collection in Handler Class');
            handler.setRollupsList(options.getUpdatedMapOfRollupsByParentId().get(parentId));
        }

        // Don't both calling the processRollups() method if there are no details to roll up
        if (detailRecords != null && !detailRecords.isEmpty()) {

            handler.processRollups(detailRecords, childRecordsByDetailId);

            if (options.rollupJobType == CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit ||
                options.rollupJobType == CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit) {
                options.mapOfProcessedOppIdsByParentId.put(parentId, handler.getListOfOppIdsThatWereRolledUp());
            }

            // only set the lastParentId when there are actually detail records
            options.lastParentIdProcessed = parentId;

            // Save the rollup data from the Handler instance into the processing options instance
            if (options.mode == CRLP_RollupProcessingOptions.BatchJobMode.SkewMode) {
                options.mapOfRollupsByParentId.put(parentId, fullyCloneList(handler.getRollupsList()));
            }
        }

        // Build an updated SObject parent record with the calculated rollups
        SObject updatedRecord = handler.getPopulatedSObject();

        // Determine if the updated SObject record is different than the parent.
        // If not, set it to null
        if (CRLP_Rollup_SVC.resultsNeedUpdate(parent, updatedRecord, handler.getRollupsList()) == false) {
            updatedRecord = null;
        }

        return updatedRecord;
    }

    /**
     * @description Called by the same method that calls the startProcessing() method to handle any dml operations
     * and log any dml errors that were generated by the update
     * @param recordsToUpdate List<SObject>
     */
    public static void updateChangedRecordsWithLogging(List<SObject> recordsToUpdate, CRLP_RollupProcessingOptions.RollupType jobType) {
        Map<Id,String> dmlErrors = new Map<Id, String>();

        if (recordsToUpdate.isEmpty()) {
            return;
        }

        // Disable non-User Managed TDTM triggers before the DML operation to improve performance when
        // writing changes to rollups to the target objects.
        String targetObjectName = UTIL_Describe.getObjectDescribe(recordsToUpdate[0].getSObjectType()).getName();
        for (Trigger_Handler__c th : TDTM_Config_API.getCachedRecords()) {
            if (th.User_Managed__c == false && th.Object__c == targetObjectName) {
                th.Active__c = false;
            }
        }

        // Initiate the DML operation with allOrNone set to false (don't fail the entire batch if one record fails)
        UTIL_DMLService.updateRecordBatchAndLogErrors(recordsToUpdate, ERR_Handler_API.Context.CRLP.name() + '.' + jobType.name());
    }

    /**
     * @description If a query includes a sub-query of child records and that list of children is needed as a
     * separate collection (specifically with Payments), this will return a Map of list child records with the map
     * key of the parent record id.
     * @param details List<SObject>
     * @param relationshipName Name of the relationship field to use to split the child sub-query
     * @return Map<Id, List<SObject>>
     */
    public static Map<Id, List<SObject>> splitChildRecordsInMapByParentId(List<SObject> details, String relationshipName) {
        Map<Id, List<SObject>> childrenByParentId = new Map<Id, List<SObject>>();
        for (SObject d : details) {
            if (relationshipName != null && d.getSObjects(relationshipName) != null) {
                childrenByParentId.put(d.Id, d.getSObjects(relationshipName));
            }
        }
        return childrenByParentId;
    }

    /**
     * @description In order to ensure that the List<CRLP_Rollup> values that are created and saved, as well
     * as cached properly, the individual instances of CRLP_Rollup have to be cloned. Otherwise, Salesforce
     * treats each element by reference meaning that we always end up with a single collection of these that is
     * continually passed around by reference. Cloning the entire list simply creates a new reference to the List,
     * but each individual instance of CRLP_Rollup is still a reference to the original. The only way to work around
     * this is to clone each individual instance into a new list.
     * @param rollups List<CRLP_Rollup> to clone
     * @return Fully cloned list of CRLP_Rollup
     */
    private static List<CRLP_Rollup> fullyCloneList(List<CRLP_Rollup> rollups) {
        List<CRLP_Rollup> newList = new List<CRLP_Rollup>();
        for (CRLP_Rollup r : rollups) {
            newList.add(r.clone());
        }
        return newList;
    }
}