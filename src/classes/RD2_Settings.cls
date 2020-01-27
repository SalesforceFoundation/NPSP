/*
    Copyright (c) 2020 Salesforce.org
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
* @date 2020
* @group Recurring Donations
* @description Recurring Donation settings wrapper
*
*/
public with sharing class RD2_Settings {
    
    /***
    * @description Recurring Donation custom settings
    */
    private npe03__Recurring_Donations_Settings__c settings {
        get {
            if (settings == null) {
                settings = UTIL_CustomSettingsFacade.getRecurringDonationsSettings();
            } 
            return settings;
        }
        set;
    }

    /***
    * @description The installment Opportunity Stage
    */
    public String installmentStage {
        get {
            if (installmentStage == null) {
                installmentStage = String.isNotBlank(settings.InstallmentOppStageName__c)
                    ? settings.InstallmentOppStageName__c
                    : System.Label.npe03.RecurringDonationStageName;
            }
            return installmentStage;
        } 
        private set;
    }

    /***
    * @description The installment Opportunity Record Type Id
    */
    public Id installmentRecordTypeId {
        get {            
            return (Id) settings.npe03__Record_Type__c;
        } 
        private set;
    }

    /***
    * @description Indicates if Campaign should be propagated from RD to the installment Opportunity
    */
    public Boolean shouldSetInstallmentCampaign {
        get {            
            return settings.npe03__Add_Campaign_to_All_Opportunites__c;
        } 
        private set;
    }

    /***
    * @description Indicates if open installment Opportunities should be deleted when RD is closed
    */
    public Boolean isCloseActionDeletion() {
        return settings.npe03__Open_Opportunity_Behavior__c == RD2_Constants.CloseActions.Delete_Open_Opportunities.name();
    }

    /***
    * @description Indicates if open installment Opportunities should be set to Closed Lost when RD is closed
    */
    public Boolean isCloseActionClosedLost() {
        return settings.npe03__Open_Opportunity_Behavior__c == RD2_Constants.CloseActions.Mark_Opportunities_Closed_Lost.name();
    }

    /***
    * @description Indicates if open installment Opportunities should be unchanged when RD is closed
    */
    public Boolean isCloseActionNoAction() {
        return settings.npe03__Open_Opportunity_Behavior__c == RD2_Constants.CloseActions.No_Action.name();
    }
    
    /***
    * @description Installment Opp Auto Creation Option,
    * If random string is input, the setting will be default to Always Create Next installment
    */
    public String installmentCreateOption {
        get {
            if (installmentCreateOption == null) {
                installmentCreateOption = String.isNotBlank(settings.installmentOppAutoCreateOption__c)
                    ? settings.installmentOppAutoCreateOption__c
                    : RD2_Constants.InstallmentCreateOptions.Always_Create_Next_Installment.name();
            }

            return installmentCreateOption;
        }
        private set;
    }

    /***
    * @description Indicates if the first installment can be created on a Recurring Donation
    */
    public Boolean isFirstInstallmentEnabled {
        get {
            if (isFirstInstallmentEnabled == null) {
                isFirstInstallmentEnabled =
                    installmentCreateOption != RD2_Constants.InstallmentCreateOptions.Disable_First_Installment.name()
                    && installmentCreateOption != RD2_Constants.InstallmentCreateOptions.Disable_All_Installments.name();
            }
            return isFirstInstallmentEnabled;
        } 
        private set;
    }

    /***
    * @description Indicates if the next installment can be created on a Recurring Donation
    */
    public Boolean isNextInstallmentEnabled {
        get {
            if (isNextInstallmentEnabled == null) {
                isNextInstallmentEnabled =
                    installmentCreateOption != RD2_Constants.InstallmentCreateOptions.Disable_All_Installments.name();
            }
            
            return isNextInstallmentEnabled;
        } 
        private set;
    }

    /***
    * @description Indicates if any installment creation on a Recurring Donation is disabled
    */
    public Boolean isDisableAllInstallments {
        get {
            if (isDisableAllInstallments == null) {
                isDisableAllInstallments =
                    installmentCreateOption == RD2_Constants.InstallmentCreateOptions.Disable_All_Installments.name();
            }
            return isDisableAllInstallments;
        } 
        private set;
    }

    /***
    * @description Saves latest Recurring Donation batch results
    */
    public void saveLatestBatchResults(Id jobId, Integer recordsProcessed, Integer recordsFailed) {
        AsyncApexJob job = new UTIL_BatchJobService().getAsyncApexJob(jobId);

        settings.npe03__Last_Batch_Run__c = job == null ? Datetime.now() : job.CompletedDate;
        settings.npe03__Number_of_Successes__c = recordsProcessed - recordsFailed;
        settings.npe03__Number_of_Failures__c = recordsFailed;

        if (!Test.isRunningTest()) {
            upsert settings;
        }
    }
}
