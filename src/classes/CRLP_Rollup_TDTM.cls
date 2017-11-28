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

    /** TODO Build This!
     * @description Trigger Handler on Opportunity, Payment and Allocation
     * certain Tasks for sending emails.
     * @param listNew the list of records from trigger new.
     * @param listOld the list of recods from trigger old.
     * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.).
     * @param objResult the describe for the related object
     * @return dmlWrapper.
     */
    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist,
            TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        // Don't continue if the Customizable Rollups engine is not enabled
        if (!CRLP_Rollup_SVC.isCustomizableRollupEngineEnabled) {
            return null;
        }
        return null;
    }

    /**
     * @description Called by Update triggers to determine if a rollup recalculation is required for a given record
     * @param newRecord
     * @param oldRecord
     * @return Boolean
     */
    public static Boolean isRollupRecalcNeeded(SObject newRecord, SObject oldRecord) {

        // No old record, therefore always rolling up a new record
        if (oldRecord == null) {
            return true;
        }

        SObjectType objType = newRecord.getSObjectType();

        // Start by getting all the fields referenced by any Filter Group or active Rollup
        List<Schema.DescribeFieldResult> fieldsToCompare = new List<DescribeFieldResult>();
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

    // TODO Build This!
    public static void executeRollupsForSpecifiedRecords() {
        // get the Id's to roll up for
        // Queue the Queueable job; or start the batch process for LDV
    }
}