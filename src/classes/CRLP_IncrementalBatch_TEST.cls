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
* @description Test Class of the Incremental Rollups Settings.
*/
@isTest
private class CRLP_IncrementalBatch_TEST {

    private static final Integer LAST_BATCH_RUN_DAYS_BACK = 10;
    private static final Integer ROLLUP_DAYS_BACK = 5;

    /*********************************************************************************************************
    * @description Creates the Incremental Account Hard Credit Settings, disable the Incremental Rollup Mode and 
    * Runs the Incremental Rollups Batch. Confirms the Where Clause and the Last Batch Run are blank.
    */
    static testMethod void testIncrementalAccountHardCredit_IncrementalModeNotEnabled() {
        String incrementalWhereClause = runIncrementalRollup(
            new Customizable_Rollup_Settings__c(
                Enable_Incremental_Rollups_Mode__c = false,
                Account_Hard_Credit_Last_Batch__c = null
            ),
            new List<Rollup__mdt>{createRollup('Account', ROLLUP_DAYS_BACK)},
            new CRLP_IncrementalBatch.AccountHardCredit()
        );

        System.assert(String.isBlank(incrementalWhereClause));
        System.assert(UTIL_CustomSettingsFacade.getCustomizableRollupSettings().Account_Hard_Credit_Last_Batch__c == null);
    }

    /*********************************************************************************************************
    * @description Creates the Incremental Account Hard Credit Settings, enable the Incremental Rollup Mode and 
    * Then configures the Incremental Account Rollup. Runs the Incremental Rollups, and confirms the Where Clause
    * is blank and the Last Batch Run is set to Today.
    */
    static testMethod void testIncrementalAccountHardCredit_WithoutLastBatchRun() {
        String incrementalWhereClause = runIncrementalRollup(
            new Customizable_Rollup_Settings__c(
                Enable_Incremental_Rollups_Mode__c = true,
                Account_Hard_Credit_Last_Batch__c = null
            ),
            new List<Rollup__mdt>{createRollup('Account', ROLLUP_DAYS_BACK)},
            new CRLP_IncrementalBatch.AccountHardCredit()
        );
        System.assert(String.isBlank(incrementalWhereClause));
        System.assertEquals(
            Date.today(), 
            UTIL_CustomSettingsFacade.getCustomizableRollupSettings().Account_Hard_Credit_Last_Batch__c
        );
    }

    /*********************************************************************************************************
    * @description Creates the Incremental Account Hard Credit Settings, enable the Incremental Rollup and 
    * sets the Last Batch Run set to not null. Then configures the Incremental Account Rollup. Runs the  
    * Incremental Rollups Batch and confirms the Where Clause is correct and the Last Batch Run is set to Today's date.
    */
    static testMethod void testIncrementalAccountHardCredit_WithLastBatchRun() {
        String incrementalWhereClause = runIncrementalRollup(
            new Customizable_Rollup_Settings__c(
                Enable_Incremental_Rollups_Mode__c = true,
                Account_Hard_Credit_Last_Batch__c = Date.today().addDays(-LAST_BATCH_RUN_DAYS_BACK)
            ),
            new List<Rollup__mdt>{createRollup('Account', ROLLUP_DAYS_BACK)},
            new CRLP_IncrementalBatch.AccountHardCredit()
        );
        System.assertEquals(
            String.format(
                CRLP_IncrementalBatch.ACCOUNT_HARD_CREDIT_WHERE_CLAUSE_TEMPLATE, 
                new List<String>{String.valueOf(LAST_BATCH_RUN_DAYS_BACK + ROLLUP_DAYS_BACK + 1)}
            ),
            incrementalWhereClause
        );
        System.assertEquals(
            Date.today(), 
            UTIL_CustomSettingsFacade.getCustomizableRollupSettings().Account_Hard_Credit_Last_Batch__c
        );
    }

    /*********************************************************************************************************
    * @description Creates the Incremental Contact Hard Credit Settings, disable the Incremental Rollup and 
    * Runs the Incremental Rollups, and confirms the Where Clause and the Last Batch Run are blank
    */
    static testMethod void testIncrementalContactHardCredit_IncrementalModeNotEnabled() {
        String incrementalWhereClause = runIncrementalRollup(
            new Customizable_Rollup_Settings__c(
                Enable_Incremental_Rollups_Mode__c = false,
                Contact_Hard_Credit_Last_Batch__c = null
            ),
            new List<Rollup__mdt>{createRollup('Contact', ROLLUP_DAYS_BACK)},
            new CRLP_IncrementalBatch.ContactHardCredit()
        );

        System.assert(String.isBlank(incrementalWhereClause));
        System.assert(UTIL_CustomSettingsFacade.getCustomizableRollupSettings().Contact_Hard_Credit_Last_Batch__c == null);
    }

    /*********************************************************************************************************
    * @description Creates the Incremental Contact Hard Credit Settings, enable the Incremental Rollup and 
    * Then defines an Contact Rollup. Runs the Incremental Rollups, and confirms the Where Clause is blank
    * and the Last Batch Run is set to Today's date.
    */
    static testMethod void testIncrementalContactHardCredit_WithoutLastBatchRun() {
        String incrementalWhereClause = runIncrementalRollup(
            new Customizable_Rollup_Settings__c(
                Enable_Incremental_Rollups_Mode__c = true,
                Contact_Hard_Credit_Last_Batch__c = null
            ),
            new List<Rollup__mdt>{createRollup('Contact', ROLLUP_DAYS_BACK)},
            new CRLP_IncrementalBatch.ContactHardCredit()
        );
        System.assert(String.isBlank(incrementalWhereClause));
        System.assertEquals(
            Date.today(), 
            UTIL_CustomSettingsFacade.getCustomizableRollupSettings().Contact_Hard_Credit_Last_Batch__c
        );
    }

    /*********************************************************************************************************
    * @description Creates the Incremental Contact Hard Credit Settings, enable the Incremental Rollup and 
    * sets the Last Batch Run set to not null. Then defines an Contact Rollup. Runs the Incremental Rollups, 
    * and confirms the Where Clause is correct and the Last Batch Run is set to Today's date.
    */
    static testMethod void testIncrementalContactHardCredit_WithLastBatchRun() {
        String incrementalWhereClause = runIncrementalRollup(
            new Customizable_Rollup_Settings__c(
                Enable_Incremental_Rollups_Mode__c = true,
                Contact_Hard_Credit_Last_Batch__c = Date.today().addDays(-LAST_BATCH_RUN_DAYS_BACK)
            ),
            new List<Rollup__mdt>{createRollup('Contact', ROLLUP_DAYS_BACK)},
            new CRLP_IncrementalBatch.ContactHardCredit()
        );
        System.assertEquals(
            String.format(
                CRLP_IncrementalBatch.CONTACT_HARD_CREDIT_WHERE_CLAUSE_TEMPLATE, 
                new List<String>{String.valueOf(LAST_BATCH_RUN_DAYS_BACK + ROLLUP_DAYS_BACK + 1)}
            ),
            incrementalWhereClause
        );
        System.assertEquals(
            Date.today(), 
            UTIL_CustomSettingsFacade.getCustomizableRollupSettings().Contact_Hard_Credit_Last_Batch__c
        );
    }

    /*********************************************************************************************************
    * @description Creates the Incremental Contact Soft Credit Settings, disable the Incremental Rollup and 
    * Runs the Incremental Rollups, and confirms the Where Clause and the Last Batch Run are blank
    */
    static testMethod void testIncrementalContactSoftCredit_IncrementalModeNotEnabled() {
        String incrementalWhereClause = runIncrementalRollup(
            new Customizable_Rollup_Settings__c(
                Enable_Incremental_Rollups_Mode__c = false,
                Contact_Soft_Credit_Last_Batch__c = null
            ),
            new List<Rollup__mdt>{createRollup('Contact', ROLLUP_DAYS_BACK)},
            new CRLP_IncrementalBatch.ContactSoftCredit()
        );

        System.assert(String.isBlank(incrementalWhereClause));
        System.assert(UTIL_CustomSettingsFacade.getCustomizableRollupSettings().Contact_Soft_Credit_Last_Batch__c == null);
    }

    /*********************************************************************************************************
    * @description Creates the Incremental Contact Soft Credit Settings, enable the Incremental Rollup and 
    * Then defines an Contact Rollup. Runs the Incremental Rollups, and confirms the Where Clause is blank
    * and the Last Batch Run is set to Today's date.
    */
    static testMethod void testIncrementalContactSoftCredit_WithoutLastBatchRun() {
        String incrementalWhereClause = runIncrementalRollup(
            new Customizable_Rollup_Settings__c(
                Enable_Incremental_Rollups_Mode__c = true,
                Contact_Soft_Credit_Last_Batch__c = null
            ),
            new List<Rollup__mdt>{createRollup('Contact', ROLLUP_DAYS_BACK)},
            new CRLP_IncrementalBatch.ContactSoftCredit()
        );
        System.assert(String.isBlank(incrementalWhereClause));
        System.assertEquals(
            Date.today(), 
            UTIL_CustomSettingsFacade.getCustomizableRollupSettings().Contact_Soft_Credit_Last_Batch__c
        );
    }

    /*********************************************************************************************************
    * @description Creates the Incremental Contact Soft Credit Settings, enable the Incremental Rollup and 
    * sets the Last Batch Run set to not null. Then defines an Contact Rollup. Runs the Incremental Rollups, 
    * and confirms the Where Clause is correct and the Last Batch Run is set to Today's date.
    */
    static testMethod void testIncrementalContactSoftCredit_WithLastBatchRun() {
        String incrementalWhereClause = runIncrementalRollup(
            new Customizable_Rollup_Settings__c(
                Enable_Incremental_Rollups_Mode__c = true,
                Contact_Soft_Credit_Last_Batch__c = Date.today().addDays(-LAST_BATCH_RUN_DAYS_BACK)
            ),
            new List<Rollup__mdt>{createRollup('Contact', ROLLUP_DAYS_BACK)},
            new CRLP_IncrementalBatch.ContactSoftCredit()
        );
        System.assertEquals(
            String.format(
                CRLP_IncrementalBatch.CONTACT_SOFT_CREDIT_WHERE_CLAUSE_TEMPLATE, 
                new List<String>{String.valueOf(LAST_BATCH_RUN_DAYS_BACK + ROLLUP_DAYS_BACK + 1)}
            ),
            incrementalWhereClause
        );
        System.assertEquals(
            Date.today(), 
            UTIL_CustomSettingsFacade.getCustomizableRollupSettings().Contact_Soft_Credit_Last_Batch__c
        );
    }

    /*********************************************************************************************************
    * @description Creates the Incremental Contact Soft Credit Settings, disable the Incremental Rollup and 
    * Runs the Incremental Rollups, and confirms the Where Clause and the Last Batch Run are blank
    */
    static testMethod void testIncrementalRecurringDonation_IncrementalModeNotEnabled() {
        String incrementalWhereClause = runIncrementalRollup(
            new Customizable_Rollup_Settings__c(
                Enable_Incremental_Rollups_Mode__c = false,
                Recurring_Donations_Last_Batch__c = null
            ),
            new List<Rollup__mdt>(),
            new CRLP_IncrementalBatch.RecurringDonations()
        );

        System.assert(String.isBlank(incrementalWhereClause));
        System.assert(UTIL_CustomSettingsFacade.getCustomizableRollupSettings().Recurring_Donations_Last_Batch__c == null);
    }

    /*********************************************************************************************************
    * @description Creates the Incremental Recurring Donations Settings, disable the Incremental Rollup
    * Runs the Incremental Rollups, and confirms the Where Clause is blank and the Last Batch Run is set 
    * to Today's date.
    */
    static testMethod void testIncrementalRecurringDonation_WithoutLastBatchRun() {
        String incrementalWhereClause = runIncrementalRollup(
            new Customizable_Rollup_Settings__c(
                Enable_Incremental_Rollups_Mode__c = true,
                Recurring_Donations_Last_Batch__c = null
            ),
            new List<Rollup__mdt>(),
            new CRLP_IncrementalBatch.RecurringDonations()
        );
        System.assert(String.isBlank(incrementalWhereClause));
        System.assertEquals(
            Date.today(), 
            UTIL_CustomSettingsFacade.getCustomizableRollupSettings().Recurring_Donations_Last_Batch__c
        );
    }

    /*********************************************************************************************************
    * @description Creates the Incremental Contact Soft Credit Settings, enable the Incremental Rollup and 
    * sets the Last Batch Run set to not null. Then defines an Contact Rollup. Runs the Incremental Rollups, 
    * and confirms the Where Clause is correct and the Last Batch Run is set to Today's date.
    */
    static testMethod void testIncrementalRecurringDonation_WithLastBatchRun() {
        String incrementalWhereClause = runIncrementalRollup(
            new Customizable_Rollup_Settings__c(
                Enable_Incremental_Rollups_Mode__c = true,
                Recurring_Donations_Last_Batch__c = Date.today().addDays(-LAST_BATCH_RUN_DAYS_BACK)
            ),
            new List<Rollup__mdt>(),
            new CRLP_IncrementalBatch.RecurringDonations()
        );
        System.assertEquals(
            String.format(
                CRLP_IncrementalBatch.RECURRING_DONATIONS_WHERE_CLAUSE_TEMPLATE, 
                new List<String>{String.valueOf(LAST_BATCH_RUN_DAYS_BACK + 1)}
            ),
            incrementalWhereClause
        );
        System.assertEquals(
            Date.today(), 
            UTIL_CustomSettingsFacade.getCustomizableRollupSettings().Recurring_Donations_Last_Batch__c
        );
    }

    /*********************************************************************************************************
    * @description Runs the Incremental Rollups.
    * @param settings. The Customizable Rollup Settings.
    * @param cachedRollups. The Rollups to cached.
    * @param incrementalRollup. The Incremental Rollup configuration.
    * @return Incremental Rollup Where Clause.
    */
    private static String runIncrementalRollup(Customizable_Rollup_Settings__c settings, List<Rollup__mdt> cachedRollups, CRLP_IncrementalBatch.Rollup incrementalRollup) {
        // Create the Account Hard Credit incremental Rollups settings.
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(settings);
        // Override the cached Rollups.
        CRLP_Rollup_SEL.cachedRollups = cachedRollups;
        
        String incrementalWhereClause = incrementalRollup.getWereClause();
        incrementalRollup.refreshLastBatchRun();

        return incrementalWhereClause;
    }

    /*******************************************************************************************************
    * @description Creates the Test Rollups.
    * @param sObjectName. The Rollup Object Name.
    * @param daysBack. The Rollup days back.
    * @return Rollup__mdt.
    ********************************************************************************************************/
    private static Rollup__mdt createRollup(String sObjectName, Integer daysBack) {
        String rollupsJSON = CMT_UnitTestData_TEST.buildCMTObjectJSON(
            'Rollup__mdt', 
            'Household Total Donations All Time',
            CMT_UnitTestData_TEST.getNewRecordId(), 
            new List<CMT_UnitTestData_TEST.CMT_Field>{
                new CMT_UnitTestData_TEST.CMT_Field('Active__c', CMT_UnitTestData_TEST.CMTFieldType.FldBoolean, True),
                new CMT_UnitTestData_TEST.CMT_Field('Summary_Object__c', CMT_UnitTestData_TEST.CMTFieldType.FldEntity, sObjectName),
                new CMT_UnitTestData_TEST.CMT_Field('Integer__c', CMT_UnitTestData_TEST.CMTFieldType.FldNumber, daysBack)
            }
        );

        return (Rollup__mdt) JSON.deserialize(rollupsJSON, Rollup__mdt.class);
    }
}