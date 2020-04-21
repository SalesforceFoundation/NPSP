/*
    Copyright (c) 2012, Salesforce.org
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
* @date 2012 (2.2)
* @group Recurring Donations
* @description The controller for the VF page invoked by using the Refresh Opportunities button
*/
public with sharing class RD_AddDonationsBTN_CTRL {

    @TestVisible
    private ApexPages.StandardController sc;

    /**
     * @description Show the Continue button on the page when true
     */
    public Boolean showContinueBtn { get; set; }

    /***
    * @description Permissions class used to determine if the running user has permissions
    */
    @TestVisible
    private static UTIL_Permissions permissions {
        get {
            if (permissions == null) {
                permissions = new UTIL_Permissions();
            }
            return permissions;
        }
        set;
    }
    /***
    * @description Class constructor
    * @param controller The StandardController to the Recurring Donation
    */
    public RD_AddDonationsBTN_CTRL(ApexPages.StandardController sc){
        this.sc = sc;
        this.showContinueBtn = false;
        validate();
    }

    /**
    * @description Action method to refresh the legacy Recurring Donation with appropriate Opportunities
    * @return PageReference to the calling page
    */
    public PageReference buttonClick() {
        if (ApexPages.hasMessages()) {
            return null;
        }

        Savepoint sp = Database.setSavepoint();
        try {
            String soql = RD_RecurringDonations.strQueryRDNoWhere()
                + ' WHERE Id = \'' + sc.getId() + '\'';

            npe03__Recurring_Donation__c rd = (npe03__Recurring_Donation__c) Database.query(soql);

            // This recalculates Rollups only in Legacy mode.
            RD_RecurringDonations.evaluateRecurringDonationsForNewOppInsert(new List<npe03__Recurring_Donation__c>{ rd });
            //This recalculates Rollups only if Customizable Rollup is enabled.
            recalculateRollups(sc.getId());

            return redirectToRecurringDonationsPage();

        } catch (Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler_API.Context.RD);
            return addMessageAndReturn(ApexPages.Severity.ERROR, e.getMessage());
        }
    }

    /**
    * @description Action method to redirect to the Recurring Donation calling page.
    * Redirects to recurring donation list if the ID is missing.
    * @return PageReference to the calling page
    */
    public PageReference redirectToRecurringDonationsPage() {

        if (sc.getId() == null) {
            Schema.DescribeSObjectResult describeResult = npe03__Recurring_Donation__c.SObjectType.getDescribe();
            return new PageReference('/' + describeResult.getKeyPrefix());
        }

        PageReference pageRef = sc.view();
        pageRef.setRedirect(true);
        return pageRef;
    }

    /***
    * @description Recalculates the Rollup for Recurring Donation.
    * @return void.
    */
    private void recalculateRollups(Id recordId) {
        if (CRLP_Rollup_SVC.isCustomizableRollupEngineEnabled) {
            if (CRLP_RollupBatch_SVC.doesRecordNeedSkewRollupMethod(recordId, CRLP_RollupProcessingOptions.RollupType.RecurringDonations)) {
                CRLP_RollupBatch_SVC.executeBatchRollupJob(
                    CRLP_RollupProcessingOptions.RollupType.RecurringDonations,
                    CRLP_RollupProcessingOptions.BatchJobMode.SkewMode,
                    new List<Id>{ recordId },
                    null
                );

            } else {
                System.enqueueJob(new CRLP_RollupQueueable(new List<Id>{ recordId }));
            }
        }
        else {
            RD_RecurringDonations.updateRecurringDonationOnOppChangeFuture(new Set<Id>{ recordId });
        }
    }

    /***
    * @description Adds a message to the Visualforce page
    * and returns null to stay on the current page
    * @param severity Message severity (info, error, warning)
    * @param message Message to display
    * @return PageReference
    */
    private PageReference addMessageAndReturn(ApexPages.Severity severity, String message) {
        ApexPages.addMessage(
            new ApexPages.Message(severity, message)
        );

        return null;
    }

    /**
     * @description Validate that the current User has the appropriate permissions and that Legacy RD is enabled
     */
    public void validate() {
        SObjectType objType = Opportunity.sObjectType;

        if (RD2_EnablementService.isRecurringDonations2Enabled) {
            addMessageAndReturn(ApexPages.Severity.ERROR, System.Label.RD_ErrorAddDonationLimitedToLegacyMode);

        } else if (sc.getId() == null) {
            addMessageAndReturn(ApexPages.Severity.ERROR, System.Label.RD_ErrorAddDonationMissingId);

        } else if (!permissions.canCreate(objType)
            || !permissions.canUpdate(objType)
            || !permissions.canDelete(objType)
        ) {
            addMessageAndReturn(ApexPages.Severity.ERROR, System.Label.RD_ErrorAddDonationPermissionDenied);

        } else {
            this.showContinueBtn = true;
        }
    }
}