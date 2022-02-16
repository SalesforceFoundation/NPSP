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
* @description Unit tests for the Enhanced RD Settings
*
*/
@IsTest(IsParallel=true)
public with sharing class RD2_Settings_TEST {

    /**
     * @description Verifies configured installment stage name is returned
     */
    @IsTest
    private static void shouldReturnConfiguredInstallmentStageName() {
        final String stageName = 'Pledged';

        setUpConfiguration(
            new Map<String, Object>{ 'InstallmentOppStageName__c' => stageName }
        );

        RD2_Settings settings = RD2_Settings.getInstance();
        System.assertEquals(stageName, settings.installmentStage, 'Installment Stage should match');
    }

    /**
     * @description Verifies RD custom label holding default stage name is returned when 
     * configured installment stage name is empty
     */
    @IsTest
    private static void shouldReturnCustomLabelWhenInstallmentStageNameIsNotConfigured() {
        setUpConfiguration(
            new Map<String, Object>{ 'InstallmentOppStageName__c' => null }
        );

        RD2_Settings settings = RD2_Settings.getInstance();
        System.assertEquals(System.Label.npe03.RecurringDonationStageName, settings.installmentStage, 
            'Installment Stage should match');
    }

    /**
     * @description Verifies configured installment record type Id is returned
     */
    @IsTest
    private static void shouldReturnConfiguredInstallmentRecordTypeId() {
        final Id recordTypeId = UTIL_RecordTypes_TEST.getRandomRecordTypeId(Opportunity.SObjectType);

        setUpConfiguration(new Map<String, Object>{
            'npe03__Record_Type__c' => recordTypeId
        });

        RD2_Settings settings = RD2_Settings.getInstance();
        System.assertEquals(recordTypeId, settings.installmentRecordTypeId, 
            'Installment Record Type Id should match');
    }

    /**
     * @description Verifies null is returned when configured installment record type Id is null
     */
    @IsTest
    private static void shouldReturnNullWhenInstallmentRecordTypeIdIsNotConfigured() {
        setUpConfiguration(new Map<String, Object>{
            'npe03__Record_Type__c' => null
        });

        RD2_Settings settings = RD2_Settings.getInstance();
        System.assertEquals(null, settings.installmentRecordTypeId, 
            'Installment Record Type Id should not be set');
    }

    /**
     * @description Verifies true is returned when Campaign should be propagated from RD to installment Opps
     */
    @IsTest
    private static void shouldReturnConfiguredInstallmentCampaignSettingsWhenTrue() {
        RD2_Settings settings = RD2_Settings.getInstance();

        setUpConfiguration(new Map<String, Object>{
            'npe03__Add_Campaign_to_All_Opportunites__c' => true
        });
        System.assertEquals(true, settings.shouldSetInstallmentCampaign, 
            'Installment Campaign should be propagated from RD to installment Opps');
    }

    /**
     * @description Verifies false is returned when Campaign should not be propagated from RD to installment Opps
     */
    @IsTest
    private static void shouldReturnConfiguredInstallmentCampaignSettingsWhenFalse() {
        RD2_Settings settings = RD2_Settings.getInstance();

        setUpConfiguration(new Map<String, Object>{
            'npe03__Add_Campaign_to_All_Opportunites__c' => false
        });
        System.assertEquals(false, settings.shouldSetInstallmentCampaign, 
            'Installment Campaign should not be propagated from RD to installment Opps');
    }

    /**
     * @description Verifies correct close action is set when configured action is No_Action
     */
    @IsTest
    private static void shouldReturnConfiguredCloseActionNoAction() {
        RD2_Settings settings = RD2_Settings.getInstance();
        String closeAction  = RD2_Constants.CloseActions.No_Action.name();

        setUpConfiguration(new Map<String, Object>{
            'npe03__Open_Opportunity_Behavior__c' => closeAction
        });

        System.assertEquals(true, settings.isCloseActionNoAction(), 'Action should be no action');
        System.assertEquals(false, settings.isCloseActionDeletion(), 'Action should not be deletion');
        System.assertEquals(false, settings.isCloseActionClosedLost(), 'Action should not be Closed Lost');
    }

    /**
     * @description Verifies correct close action is set when configured action is deletion
     */
    @IsTest
    private static void shouldReturnConfiguredCloseActionDeletion() {
        RD2_Settings settings = RD2_Settings.getInstance();
        String closeAction  = RD2_Constants.CloseActions.Delete_Open_Opportunities.name();

        setUpConfiguration(new Map<String, Object>{
            'npe03__Open_Opportunity_Behavior__c' => closeAction
        });
        
        System.assertEquals(false, settings.isCloseActionNoAction(), 'Action should not be no action');
        System.assertEquals(true, settings.isCloseActionDeletion(), 'Action should be deletion');
        System.assertEquals(false, settings.isCloseActionClosedLost(), 'Action should not be Closed Lost');
    }

    /**
     * @description Verifies correct close action is set when configured action is Closed Lost
     */
    @IsTest
    private static void shouldReturnConfiguredCloseActionClosedLost() {
        RD2_Settings settings = RD2_Settings.getInstance();
        String closeAction  = RD2_Constants.CloseActions.Mark_Opportunities_Closed_Lost.name();

        setUpConfiguration(new Map<String, Object>{
            'npe03__Open_Opportunity_Behavior__c' => closeAction
        });
        
        System.assertEquals(false, settings.isCloseActionNoAction(), 'Action should not be no action');
        System.assertEquals(false, settings.isCloseActionDeletion(), 'Action should not be deletion');
        System.assertEquals(true, settings.isCloseActionClosedLost(), 'Action should be Closed Lost');
    }

     /**
     * @description Verifies first and next installment creation are enabled
     * when installment auto-create option is Always Create Next Installment
     */
    @IsTest
    private static void shouldEnableFirstAndNextInstallmentWhenOptionIsAlwaysCreate() {
        RD2_Settings settings = RD2_Settings.getInstance();

        setUpConfiguration(new Map<String, Object>{
            'InstallmentOppAutoCreateOption__c' => RD2_Constants.InstallmentCreateOptions.Always_Create_Next_Installment.name()
        });
        
        System.assertEquals(true, settings.isFirstInstallmentEnabled, 'First installment should be enabled');
        System.assertEquals(true, settings.isNextInstallmentEnabled, 'Next installment should be enabled');
        System.assertEquals(false, settings.isDisableAllInstallments, 'All installments should not be disabled');
    }

    /**
     * @description Verifies first installment creation is disabled but the next is enabled
     * when installment auto-create option is Disable First Installment on Create
     */
    @IsTest
    private static void shouldDisableFirstButEnableNextInstallmentWhenOptionIsDisableFirst() {
        RD2_Settings settings = RD2_Settings.getInstance();

        setUpConfiguration(new Map<String, Object>{
            'InstallmentOppAutoCreateOption__c' => RD2_Constants.InstallmentCreateOptions.Disable_First_Installment.name()
        });

        System.assertEquals(false, settings.isFirstInstallmentEnabled, 'First installment should not be enabled');
        System.assertEquals(true, settings.isNextInstallmentEnabled, 'Next installment should be enabled');
        System.assertEquals(false, settings.isDisableAllInstallments, 'All installments should not be disabled');
    }

    /**
     * @description Verifies both first and next installment creation are disabled
     * when installment auto-create option is Disable All Installments
     */
    @IsTest
    private static void shouldDisableFirstAndNextInstallmentWhenOptionIsDisableAll() {
        RD2_Settings settings = RD2_Settings.getInstance();

        setUpConfiguration(new Map<String, Object>{
            'InstallmentOppAutoCreateOption__c' => RD2_Constants.InstallmentCreateOptions.Disable_All_Installments.name()
        });

        System.assertEquals(false, settings.isFirstInstallmentEnabled, 'First installment should not be enabled');
        System.assertEquals(false, settings.isNextInstallmentEnabled, 'Next installment should not be enabled');
        System.assertEquals(true, settings.isDisableAllInstallments, 'All installments should be disabled');
    }

    /**
     * @description Verifies both first and next installment creation are enabled
     * when installment auto-create option is unexpected text
     */
    @isTest
    private static void shouldEnableFirstAndNextInstallmentWhenOptionIsRandomString() {
        RD2_Settings settings = RD2_Settings.getInstance();
        String randomString = 'ABC';

        setUpConfiguration(new Map<String, Object>{
            'InstallmentOppAutoCreateOption__c' => randomString
        });
        
        System.assertEquals(true, settings.isFirstInstallmentEnabled, 'First installment should be enabled');
        System.assertEquals(true, settings.isNextInstallmentEnabled, 'Next installment should be enabled');
        System.assertEquals(false, settings.isDisableAllInstallments, 'All installments should not be disabled');
    }

    /**
     * @description Verifies configured installment Next Donation Date match day range is returned
     */
    @IsTest
    private static void shouldReturnConfiguredNextDonationDateMatchRangeDays() {
        final Integer nextDonationDateMatchDays = 5;

        setUpConfiguration(
            new Map<String, Object>{ 'NextDonationDateMatchRangeDays__c' => nextDonationDateMatchDays }
        );

        RD2_Settings settings = RD2_Settings.getInstance();
        System.assertEquals(nextDonationDateMatchDays, settings.nextDonationDateMatchDays, 
            'Installment Next Donation Date Match Range Days should match');
    }

    /**
     * @description Verifies default installment Next Donation Date match day range is returned
     * when the field value is not specified
     */
    @IsTest
    private static void shouldReturnDefaultNextDonationDateMatchRangeDaysWhenNull() {
        setUpConfiguration(
            new Map<String, Object>{ 'NextDonationDateMatchRangeDays__c' => null }
        );

        RD2_Settings settings = RD2_Settings.getInstance();
        System.assertEquals(3, settings.nextDonationDateMatchDays, 
            'Installment Next Donation Date Match Range Days default should be returned');
    }

    /**
     * @description Verifies default installment Next Donation Date match day range is returned
     * when the field value is not valid
     */
    @IsTest
    private static void shouldReturnDefaultNextDonationDateMatchRangeDaysWhenInvalid() {
        setUpConfiguration(
            new Map<String, Object>{ 'NextDonationDateMatchRangeDays__c' => -1 }
        );

        RD2_Settings settings = RD2_Settings.getInstance();
        System.assertEquals(3, settings.nextDonationDateMatchDays, 
            'Installment Next Donation Date Match Range Days default should be returned');
    }

    /**
     * @description Verifies configured fiscal year usage is returned
     */
    @IsTest
    private static void shouldReturnTrueWhenConfiguredUseFiscalYearIsChecked() {
        setUpConfiguration(
            new Map<String, Object>{ 'UseFiscalYearForRecurringDonationValue__c' => true }
        );

        RD2_Settings settings = RD2_Settings.getInstance();
        System.assertEquals(true, settings.useFiscalYear, 
            'Should use Fiscal Year (if configured) for the current/next year value calculations');
    }

    /**
     * @description Verifies configured fiscal year usage is returned
     */
    @IsTest
    private static void shouldReturnFalseWhenConfiguredUseFiscalYearIsUnchecked() {
        setUpConfiguration(
            new Map<String, Object>{ 'UseFiscalYearForRecurringDonationValue__c' => false }
        );

        RD2_Settings settings = RD2_Settings.getInstance();
        System.assertEquals(false, settings.useFiscalYear, 
            'Should use Calendar Year for the current/next year value calculations');
    }

    /**
     * @description Verifies fiscal year is not used when it is not configured
     */
    @IsTest
    private static void shouldReturnFalseWhenUseFiscalYearIsNotConfigured() {
        RD2_Settings settings = RD2_Settings.getInstance();
        System.assertEquals(false, settings.useFiscalYear, 
            'Should use Calendar Year for the current/next year value calculations');
    }



    // Helpers
    ////////////
    
    /***
    * @description Generic version of creating Recurring Donations Settings
    * Apply current date override for the Opp service.
    *
    * @param valueByField A map of field name to value
    * @return void
    */
    public static void setUpConfiguration(Map<String, Object> valueByField) {
        npe03__Recurring_Donations_Settings__c rdSetting = new npe03__Recurring_Donations_Settings__c(
            npe03__Add_Campaign_to_All_Opportunites__c = true,
            IsRecurringDonations2Enabled__c = true,
            npe03__Open_Opportunity_Behavior__c = RD2_Constants.CloseActions.Mark_Opportunities_Closed_Lost.name()
        );

        for (String field : valueByField.keySet()) {
            rdSetting.put(field, valueByField.get(field));
        }

        UTIL_CustomSettingsFacade.reloadCustomSettingsOnRecordTypeCleanup();
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(rdSetting);
    }

    public static void configureForASyncFirstOpportunityCreate() {
        setUpConfiguration(
            new Map<String, Object>{ 'InstallmentOppFirstCreateMode__c' => RD2_Constants.FirstInstallmentOppCreateOptions.ASynchronous.name() }
        );
    }
}
