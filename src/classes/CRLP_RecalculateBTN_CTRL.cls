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
* @description Controller Extension for the recalculate button on the Account, Contact, and GAU objects
*
*/
public with sharing class CRLP_RecalculateBTN_CTRL {

    private Id recordId;
    private SObjectType objType;
    public String returnLabel { get; private set; }

    /** @description Used by the VF page for the button to render an apex pages message if there is one */
    public Boolean hasError { get; set; }

    /**
     * @description Constructor. Saves the record Id for the current record
     */
    public CRLP_RecalculateBTN_CTRL(ApexPages.StandardController sc) {
        this.hasError = false;
        this.recordId = sc.getId();
        this.returnLabel = '';
        if (this.recordId != null) {
            this.objType = this.recordId.getSobjectType();
            this.returnLabel = String.format(Label.CRLP_Return, new List<String> {this.objType.getDescribe().getLabel()});
        }

        if (!Test.isRunningTest()) {
            sc.addFields(new List<String>{ 'Name', 'Id' });
        }

        // if the current User does not have permissions to modify the object (though not checking specific fields)
        // then prevent them from using the recalculate button.
        if (!this.objType.getDescribe().isUpdateable()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                String.format(System.Label.flsError, new List<String>{ 'the ' + this.objType.getDescribe().getLabel() })));
            this.hasError = true;
        }
    }

    /**
     * @description Launched from the action attribute on the page tag. Enqueues the async method to start the
     * rollup to the related object. Works with both the new Customizable Rollups engine as well as the older
     * legacy rollups future jobs.
     */
    public PageReference buttonClick() {
        if (hasError == true || recordId == null) {
            // do nothing if there is no record id or there is a permissions error

        } else if (CRLP_Rollup_SVC.isCustomizableRollupEngineEnabled) {

            CRLP_RollupProcessingOptions.RollupType jobType;
            CRLP_RollupProcessingOptions.BatchJobMode jobMode = CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode;

            // ------------------------------------------------
            // Hard Credit Rollups for Account, Contact or GAU
            // ------------------------------------------------
            if (this.objType == Account.SObjectType) {
                jobType = CRLP_RollupProcessingOptions.RollupType.AccountHardCredit;
            } else if (this.objType == Contact.SObjectType) {
                jobType = CRLP_RollupProcessingOptions.RollupType.ContactHardCredit;
            } else if (this.objType == General_Accounting_Unit__c.SObjectType) {
                jobType = CRLP_RollupProcessingOptions.RollupType.GAU;
            } else if (this.objType == npe03__Recurring_Donation__c.SObjectType) {
                jobType = CRLP_RollupProcessingOptions.RollupType.RecurringDonations;
            }

            // Is skew mode needed?
            if (CRLP_RollupBatch_SVC.doesRecordNeedSkewRollupMethod(recordId, jobType)) {
                jobMode = CRLP_RollupProcessingOptions.BatchJobMode.SkewMode;
            }

            if (jobMode != CRLP_RollupProcessingOptions.BatchJobMode.SkewMode) {
                System.enqueueJob(new CRLP_RollupQueueable(new List<Id>{ recordId }));
            } else {
                CRLP_RollupBatch_SVC.executeBatchRollupJob(jobType, jobMode, new List<Id>{ recordId }, null);
            }

            // ------------------------------------------------
            // Soft Credit Rollups for Contact or Account
            // ------------------------------------------------

            if (this.objType == Contact.SObjectType && CRLP_Rollup_SVC.hasActivePartialSoftCreditRollupsForSObject(this.objType)) {
                // Is skew mode needed?
                if (CRLP_RollupBatch_SVC.doesRecordNeedSkewRollupMethod(recordId, jobType)) {
                    jobMode = CRLP_RollupProcessingOptions.BatchJobMode.SkewMode;
                }
                CRLP_RollupBatch_SVC.executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit, jobMode, new List<Id>{ recordId }, null);
            } else if (this.objType == Account.SObjectType) {
                // Is skew mode needed?
                if (CRLP_RollupBatch_SVC.doesRecordNeedSkewRollupMethod(recordId, jobType)) {
                    jobMode = CRLP_RollupProcessingOptions.BatchJobMode.SkewMode;
                }
                // Do we have active PSC rollups to Account?
                if (CRLP_Rollup_SVC.hasActivePartialSoftCreditRollupsForSObject(this.objType)) {
                    CRLP_RollupBatch_SVC.executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit, jobMode, new List<Id>{ recordId }, null);
                }
                // Do we have active ASC rollups to Account?
                if (CRLP_Rollup_SVC.hasActiveAccountSoftCreditRollupsForSObject(this.objType)) {
                    CRLP_RollupBatch_SVC.executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit, jobMode, new List<Id>{ recordId }, null);
                }

            }

        } else {
            // Legacy Roll-Ups - async action
            if (this.objType == Contact.SObjectType) {
                calculateContactSoftCredit(recordId);
                RLLP_OppRollup.rollupContactsFuture(new Set<Id>{ recordId });
            } else if (this.objType == Account.SObjectType) {
                RLLP_OppRollup.rollupAccountsFuture(new Set<Id>{ recordId });

            } else if (this.objType == General_Accounting_Unit__c.SObjectType) {
                ALLO_Rollup_SCHED rollup = new ALLO_Rollup_SCHED(recordId);
                rollup.runRollups();
            } else if (this.objType == npe03__Recurring_Donation__c.SObjectType) {
                RD_RecurringDonations.updateRecurringDonationOnOppChangeFuture(new Set<Id>{ recordId });
            }

        }
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, String.format(System.Label.CRLP_BatchCalculating, new List<String>{this.objType.getDescribe().label})));
        return null;
    }

    /*********************************************************************************************************
    * @description Calculates the Soft Credit for the Contact.
    * @return void.
    */
    @future
    private static void calculateContactSoftCredit(Id recordId) {
        RLLP_OppRollup_UTIL oppRollupUtil = new RLLP_OppRollup_UTIL();
        String contactQuery = oppRollupUtil.buildContactQuery();
        contactQuery += ' WHERE Id = \'' + recordId + '\'';

        RLLP_OppRollup rollup = new RLLP_OppRollup();
        rollup.RollupSoftCreditsWithPartialSupport(Database.query(contactQuery));
    }
}
