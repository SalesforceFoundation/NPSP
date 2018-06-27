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
* @description Contains the Classes that manage the Incremental Rollups Batches.
*/
public class CRLP_IncrementalBatch {

    @TestVisible private static final String ACCOUNT_HARD_CREDIT_WHERE_CLAUSE_TEMPLATE = (
        'Id IN (SELECT AccountId FROM Opportunity ' +
        'WHERE SystemModStamp = LAST_N_DAYS:{0} ' +
        'OR CloseDate = LAST_N_DAYS:{0} ALL ROWS)'
    );

    @TestVisible private static final String CONTACT_HARD_CREDIT_WHERE_CLAUSE_TEMPLATE = (
        'Id IN (SELECT ' + SObjectType.Opportunity.fields.Primary_Contact__c.getName() + ' ' +
        ' FROM Opportunity WHERE SystemModStamp = LAST_N_DAYS:{0} ' +
        'OR CloseDate = LAST_N_DAYS:{0} ALL ROWS)'
    );

    @TestVisible private static final String CONTACT_SOFT_CREDIT_WHERE_CLAUSE_TEMPLATE = (
        'Id IN (SELECT ContactId FROM OpportunityContactRole ' +
        'WHERE Opportunity.SystemModStamp = LAST_N_DAYS:{0} ' +
        'OR Opportunity.CloseDate = LAST_N_DAYS:{0} ALL ROWS)'
    );

    @TestVisible private static final String RECURRING_DONATIONS_WHERE_CLAUSE_TEMPLATE = (
        'Id IN (SELECT npe03__Recurring_Donation__c FROM Opportunity ' +
        'WHERE SystemModStamp = LAST_N_DAYS:{0} ' +
        'OR CloseDate = LAST_N_DAYS:{0} ALL ROWS)'
    );

    /*******************************************************************************************************
    * @description Incremental Rollups Settings Base class.
    ********************************************************************************************************/
    public abstract class Rollup {
        protected Customizable_Rollup_Settings__c customizableRollupSettings;

        /******************************************************************************************************
        * @description The Constructor of Rollup Base Class.
        */
        public Rollup() {
            customizableRollupSettings = UTIL_CustomSettingsFacade.getCustomizableRollupSettings();
        }

        /*******************************************************************************************************
        * @description Gets the SOQL Where Clause of the Incremental Rollup. This method needs to be overridden
        * to return the related Rollups Where Clause for the Incremental Mode.
        * @return String.
        ********************************************************************************************************/
        public abstract String getWereClause();

        /*******************************************************************************************************
        * @description Updates the Last Batch Run settings field. This method needs to be overridden to update the
        * the related last run date field.
        * @return void.
        ********************************************************************************************************/
        public abstract void refreshLastBatchRun();

        /*******************************************************************************************************
        * @description Checks if the Incremental Mode is enabled.
        * @return Boolean.
        ********************************************************************************************************/
        public Boolean isEnabled() {
            return customizableRollupSettings.Enable_Incremental_Rollups_Mode__c;
        }

        /*******************************************************************************************************
        * @description Calculates the maximum Days Back for a given Last Batch Run Date.
        * @param lastBatch. The last time the Batch run successfully.
        * @return Integer.
        ********************************************************************************************************/
        protected Integer getLastRunMaxDaysBack(Date lastBatch) {
            if (lastBatch.year() != Date.today().year()) {
                return lastBatch.daysBetween(Date.today()) + 366;
            }
            else {
                return lastBatch.daysBetween(Date.today()) + 1;
            }
        }

        /*******************************************************************************************************
        * @description Calculates the maximum Days Back for a given list of Rollups definition.
        * @param rollups. The Rollups definition.
        * @return Integer.
        ********************************************************************************************************/
        protected Integer getRollupsMaxDaysBack(SObjectType rollupSObjectType) {
            Integer result = 0;

            List<Rollup__mdt> rollups = CRLP_Rollup_SEL.getRollupsBySummaryType().get(rollupSObjectType);
            if (rollups == null) {
                return result;
            }

            for (Rollup__mdt rollup : rollups) {
                if (rollup.Integer__c != null && result < rollup.Integer__c) {
                    result = (Integer) rollup.Integer__c;
                }
            }

            return result;
        }
    }

    /*******************************************************************************************************
    * @description Account Hard Credit Incremental Rollups.
    ********************************************************************************************************/
    public class AccountHardCredit extends Rollup {

        /*******************************************************************************************************
        * @description  Gets the SOQL Where Clause of the Account Hard Credit Incremental Rollup.
        * @return String.
        ********************************************************************************************************/
        public override String getWereClause() {
            if (super.isEnabled() == false || super.customizableRollupSettings.Account_Hard_Credit_Last_Batch__c == null) {
                return '';
            }

            Integer maxDaysBack = (
                super.getLastRunMaxDaysBack(super.customizableRollupSettings.Account_Hard_Credit_Last_Batch__c) + 
                super.getRollupsMaxDaysBack(Account.SObjectType)
            );

            return String.format(
                ACCOUNT_HARD_CREDIT_WHERE_CLAUSE_TEMPLATE,
                new List<String>{String.valueOf(maxDaysBack)}
            );
        }

        /*******************************************************************************************************
        * @description Updates the Account Hard Credit Last Batch Run field.
        * @return void.
        ********************************************************************************************************/
        public override void refreshLastBatchRun() {
            if (super.isEnabled() == false) {
                return;
            }
            super.customizableRollupSettings.Account_Hard_Credit_Last_Batch__c = Date.today();
            upsert super.customizableRollupSettings;
        }
    }

    /*******************************************************************************************************
    * @description Contact Hard Credit Incremental Rollups.
    ********************************************************************************************************/
    public class ContactHardCredit extends Rollup {

        /*******************************************************************************************************
        * @description  Gets the SOQL Where Clause of the Contact Hard Credit Incremental Rollup.
        * @return String.
        ********************************************************************************************************/
        public override String getWereClause() {
            if (super.isEnabled() == false || super.customizableRollupSettings.Contact_Hard_Credit_Last_Batch__c == null) {
                return '';
            }

            Integer maxDaysBack = (
                super.getLastRunMaxDaysBack(super.customizableRollupSettings.Contact_Hard_Credit_Last_Batch__c) + 
                super.getRollupsMaxDaysBack(Contact.SObjectType)
            );

            return String.format(
                CONTACT_HARD_CREDIT_WHERE_CLAUSE_TEMPLATE,
                new List<String>{String.valueOf(maxDaysBack)}
            );
        }

        /*******************************************************************************************************
        * @description Updates the Contact Hard Credit Last Batch Run field.
        * @return void.
        ********************************************************************************************************/
        public override void refreshLastBatchRun() {
            if (super.isEnabled() == false) {
                return;
            }
            super.customizableRollupSettings.Contact_Hard_Credit_Last_Batch__c = Date.today();
            upsert super.customizableRollupSettings;
        }
    }

    /*******************************************************************************************************
    * @description Contact Soft Credit Incremental Rollups.
    ********************************************************************************************************/
    public class ContactSoftCredit extends Rollup {

        /*******************************************************************************************************
        * @description  Gets the SOQL Where Clause of the Contact Soft Credit Incremental Rollup.
        * @return String.
        ********************************************************************************************************/
        public override String getWereClause() {
            if (super.isEnabled() == false || super.customizableRollupSettings.Contact_Soft_Credit_Last_Batch__c == null) {
                return '';
            }

            Integer maxDaysBack = (
                super.getLastRunMaxDaysBack(super.customizableRollupSettings.Contact_Soft_Credit_Last_Batch__c) + 
                super.getRollupsMaxDaysBack(Contact.SObjectType)
            );

            return String.format(
                CONTACT_SOFT_CREDIT_WHERE_CLAUSE_TEMPLATE,
                new List<String>{String.valueOf(maxDaysBack)}
            );
        }

        /*******************************************************************************************************
        * @description Updates the Contact Soft Credit Last Batch Run field.
        * @return void.
        ********************************************************************************************************/
        public override void refreshLastBatchRun() {
            if (super.isEnabled() == false) {
                return;
            }
            super.customizableRollupSettings.Contact_Soft_Credit_Last_Batch__c = Date.today();
            upsert super.customizableRollupSettings;
        }
    }

    /*******************************************************************************************************
    * @description Recurring Donations Incremental Rollups.
    ********************************************************************************************************/
    public class RecurringDonations extends Rollup {

        /*******************************************************************************************************
        * @description  Gets the SOQL Where Clause of the Recurring Donations Incremental Rollup.
        * @return String.
        ********************************************************************************************************/
        public override String getWereClause() {
            if (super.isEnabled() == false || super.customizableRollupSettings.Recurring_Donations_Last_Batch__c == null) {
                return '';
            }

            return String.format(
                RECURRING_DONATIONS_WHERE_CLAUSE_TEMPLATE,
                new List<String>{
                    String.valueOf(super.getLastRunMaxDaysBack(super.customizableRollupSettings.Recurring_Donations_Last_Batch__c))
                }
            );
        }

        /*******************************************************************************************************
        * @description Updates the Recurring Donations Last Batch Run field.
        * @return void.
        ********************************************************************************************************/
        public override void refreshLastBatchRun() {
            if (super.isEnabled() == false) {
                return;
            }
            super.customizableRollupSettings.Recurring_Donations_Last_Batch__c = Date.today();
            upsert super.customizableRollupSettings;
        }
    }
}