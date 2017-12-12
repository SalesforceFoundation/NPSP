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
* @description Customizable Rollups for TDTM
*
*/
public class CRLP_Rollup_TDTM extends TDTM_Runnable {

    /**
     * @description Trigger Handler on Opportunity, Payment and Allocation to determine if rollups to the parent
     * Account, Contact and/or GeneralAccountingUnit objects is necessary.
     * TODO Partial Soft Credits?
     * @param listNew the list of records from trigger new.
     * @param listOld the list of recods from trigger old.
     * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.).
     * @param objResult the describe for the related object
     * @return dmlWrapper (null because this method never performs dml)
     */
    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist,
            TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        // Don't continue if the Customizable Rollups engine is not enabled
        if (!CRLP_Rollup_SVC.isCustomizableRollupEngineEnabled) {
            return null;
        }

        List<SObject> recordsToRecalculate = new List<SObject>();
        for (Integer i=0; i < ((newlist == null ? oldlist.size() : newlist.size())); i++) {
            if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
                // Have any of the "key" fields on the record changed?
                if (isRollupRecalcNeeded(newlist[i], oldlist[i])) {
                    recordsToRecalculate.add(newlist[i]);
                }
            } else if (triggerAction == TDTM_Runnable.Action.AfterInsert || triggerAction == TDTM_Runnable.Action.AfterDelete ||
                    triggerAction == TDTM_Runnable.Action.AfterUndelete) {
                // Always recalculate after an Insert/Delete/Undelete
                recordsToRecalculate.add((newlist == null ? oldlist[i] : newlist[i]));
            }
        }

        // There are records to roll-up, so execute a queueable async process to start the work.
        if (!recordsToRecalculate.isEmpty()) {
            executeRollupsForSpecifiedRecords(recordsToRecalculate);
        }

        return null;
    }

    /**
     * @description Called by Update triggers to determine if a rollup recalculation is required for a given record
     * by examining only the specific fields referenced by rollups and filters for the specific SObject.
     * @param newRecord
     * @param oldRecord
     * @return Boolean
     */
    @TestVisible
    private static Boolean isRollupRecalcNeeded(SObject newRecord, SObject oldRecord) {

        // No old record, therefore always rolling up a new record
        if (oldRecord == null) {
            return true;
        }

        SObjectType objType = newRecord.getSObjectType();

        // Start by getting all the fields referenced by any Filter Group or active Rollup
        Set<Schema.DescribeFieldResult> fieldsToCompare = new Set<DescribeFieldResult>();
        fieldsToCompare.addAll(CMT_FilterRule_SEL.getReferencedFieldsByObject(objType));
        fieldsToCompare.addAll(CRLP_Rollup_SEL.getReferencedFieldsByObject(objType));

        // Loop through the FieldDescribeResults list and compare the value of each field between the
        // old and new objects.
        Boolean changed = false;
        for (DescribeFieldResult dfr : fieldsToCompare) {
            Object oldVal = oldRecord.get(dfr.name);
            Object newVal = newRecord.get(dfr.name);
            if (oldVal != newVal) {
                changed = true;
                break;
            }
        }
        return changed;
    }

    /**
     * @description For a give set of records that were inserted/updated/deleted/undeleted, determine the
     * parent Account/Contact/GAU Id's that require rolling up to and initiate the jobs that do those rollups
     * TODO - Add LDV support on the Account/Contact object
     * @param detailRecordsToRollup
     */
    private static void executeRollupsForSpecifiedRecords(List<SObject> detailRecordsToRollup) {
        SObjectType detailObjType = detailRecordsToRollup[0].getSObjectType();

        List<Id> accountIds = new List<Id>();
        List<Id> contactIds = new List<Id>();

        List<Opportunity> opps = new List<Opportunity>();
        if (detailObjType == Opportunity.SObjectType) {

            // Get all the Opportunities
            opps.addAll((List<Opportunity>) detailRecordsToRollup);

        } else if (detailObjType == npe01__OppPayment__c.SObjectType) {

            // If the payment records were modified, get the parent Opportunity records so that 
            // the linked AccountId and PrimaryContactId values can be retrieved for the rollups
            Set<Id> oppIds = new Set<Id>();
            for (SObject s  : detailRecordsToRollup) {
                npe01__OppPayment__c pmt = (npe01__OppPayment__c)s;
                if (pmt.npe01__Opportunity__c != null) {
                    oppIds.add(pmt.npe01__Opportunity__c);
                }
            }
            opps = [SELECT Id, AccountId, Primary_Contact__c FROM Opportunity WHERE Id IN :oppIds];

        } else if (detailObjType == Allocation__c.SObjectType) {

            // If the Allocation records were modified, get the parent GAU Id's to rollup
            List<Id> gauIds = new List<Id>();
            for (SObject s  : detailRecordsToRollup) {
                Allocation__c alloc = (Allocation__c)s;
                if (alloc.Opportunity__c != null) {
                    gauIds.add(alloc.General_Accounting_Unit__c);
                }
            }

            if (!accountIds.isEmpty()) {
                Integer batchSize = CRLP_Rollup_SVC.getLDVBatchSize(General_Accounting_Unit__c.SObjectType);
                Database.executeBatch(new CRLP_Rollup_BATCH_LDV(gauIds), batchSize);
            }
        }

        // If there are Opportunities, get the Account and/or Contact Ids to roll up to
        if (detailObjType != Allocation__c.SObjectType) {
            for (Opportunity opp : opps) {
                if (opp.AccountId != null) {
                    accountIds.add(opp.AccountId);
                }
                if (opp.Primary_Contact__c != null) {
                    contactIds.add(opp.Primary_Contact__c);
                }
            }

            // Account Rollup
            if (!accountIds.isEmpty()) {
                System.enqueueJob(new CRLP_RollupQueueable(accountIds));
            }
            // Contact Rollup
            if (!contactIds.isEmpty()) {
                System.enqueueJob(new CRLP_RollupQueueable(contactIds));
            }
        }
    }
}