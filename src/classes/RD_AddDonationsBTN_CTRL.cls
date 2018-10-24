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
    
    /*******************************************************************************************************
    * @description Class constructor
    * @param controller The StandardController to the Recurring Donation 
    */ 
    public RD_AddDonationsBTN_CTRL(ApexPages.StandardController sc){
        this.sc = sc;
    }
    
    /*******************************************************************************************************
    * @description Action method to refresh the Recurring Donation with appropriate Opportunities
    * @return PageReference to the calling page
    */ 
    public PageReference buttonClick(){

        if (sc.getId() == null) { 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.RD_ErrorAddDonationMissingId));
            return null;
        }
        
        if (!Schema.SObjectType.Opportunity.isCreateable()) { 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, System.Label.RD_ErrorAddDonationPermissionDenied));
            return null;
        }

        Savepoint sp = Database.setSavepoint();
        try {
            String qString = RD_RecurringDonations.strQueryRDNoWhere();
            qString += ' where id = \'' + sc.getId() + '\'';
            npe03__Recurring_Donation__c recurringDonation = (npe03__Recurring_Donation__c)database.query(qString);
            // This recalculates Rollups only in Legacy mode. 
            RD_RecurringDonations.evaluateRecurringDonationsForNewOppInsert(new list<npe03__Recurring_Donation__c>{recurringDonation});
            //This recalculates Rollups only if Customizable Rollup is enabled.
            recalculateRollups(sc.getId());
            return redirectToRecurringDonationsPage();
        
        } catch(Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler_API.Context.PMT);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
    }
    
    /*******************************************************************************************************
    * @description Action method to redirect to the Recurring Donation calling page. Redirects to 
    * recurring donation list if the ID is missing.
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

    /*********************************************************************************************************
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
}