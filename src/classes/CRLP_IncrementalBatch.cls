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

    /*******************************************************************************************************
    * @description Incremental Rollups Settings Base class.
    ********************************************************************************************************/
    public abstract class Settings {
        private Customizable_Rollup_Settings__c customizableRollupSettings;
        private Integer rollupsMaxDaysBack;

        /******************************************************************************************************
        * @description The Constructor of Settings Base Class.
        */
        public Settings() {
            customizableRollupSettings = UTIL_CustomSettingsFacade.getCustomizableRollupSettings();
            rollupsMaxDaysBack = getRollupsMaxDaysBack();
        }

        /*******************************************************************************************************
        * @description Checks if the Incremental Mode is enabled.
        * @return Boolean.
        ********************************************************************************************************/
        public Boolean isEnabled() {
            return customizableRollupSettings.Enable_Incremental_Rollups_Mode__c;
        }

        /*******************************************************************************************************
        * @description Gets the maximum Days Back to include in the WHERE Clause Query.
        * @return Integer.
        ********************************************************************************************************/
        public Integer getMaxDaysBack() {
            Date lastBatch = getLastBatch(customizableRollupSettings);
            if (lastBatch == null) {
                return null;
            }
            if (lastBatch.year() != Date.today().year()) {
                return lastBatch.daysBetween(Date.today()) + rollupsMaxDaysBack + 366;
            }
            else {
                return lastBatch.daysBetween(Date.today()) + rollupsMaxDaysBack + 1;
            }
        }

        /*******************************************************************************************************
        * @description Updates the settings Last Successful Run field.
        * @return void.
        ********************************************************************************************************/
        public void finishBatch() {
            upsert updateLastBatch(customizableRollupSettings);
        }

        /*******************************************************************************************************
        * @description Gets the last time the Batch runs successfully. This method needs to be overridden to return
        * the related settings last run date.
        * @param customizableRollupSettings The Customizable Rollups Settings.
        * @return Date.
        ********************************************************************************************************/
        protected abstract Date getLastBatch(Customizable_Rollup_Settings__c customizableRollupSettings);
        
        /*******************************************************************************************************
        * @description Updates the Last Batch Run settings field. This method needs to be overridden to update the
        * the related settings last run date field. 
        * @param customizableRollupSettings The Customizable Rollups Settings.
        * @return Customizable_Rollup_Settings__c.
        ********************************************************************************************************/
        protected abstract Customizable_Rollup_Settings__c updateLastBatch(Customizable_Rollup_Settings__c customizableRollupSettings);

        /*******************************************************************************************************
        * @description Gets the maximum Days Back from the Rollups definition.
        * @return Integer.
        ********************************************************************************************************/
        private Integer getRollupsMaxDaysBack() {
            Integer result = 0;

            List<Rollup__mdt> rollups = [
                SELECT Integer__c
                FROM Rollup__mdt
                WHERE Time_Bound_Operation_Type__c = 'Days Back'
            ];
            for (Rollup__mdt rollup : rollups) {
                if (rollup.Integer__c != null && result < rollup.Integer__c) {
                    result = (Integer) rollup.Integer__c;
                }
            }

            return result;
        }
    }

    /*******************************************************************************************************
    * @description Account Hard Credit Incremental Rollups Settings.
    ********************************************************************************************************/
    public class AccountHardCreditSettings extends Settings {

        /*******************************************************************************************************
        * @description Gets the last time the Account Hard Credit Batch runs successfully.
        * @param customizableRollupSettings The Customizable Rollups Settings.
        * @return Date.
        ********************************************************************************************************/
        protected override Date getLastBatch(Customizable_Rollup_Settings__c customizableRollupSettings) {
            return customizableRollupSettings.Account_Hard_Credit_Last_Batch__c;
        }

        /*******************************************************************************************************
        * @description Updates the Account Hard Credit Last Batch Run settings field.
        * @param customizableRollupSettings The Customizable Rollups Settings.
        * @return Customizable_Rollup_Settings__c.
        ********************************************************************************************************/
        protected override Customizable_Rollup_Settings__c updateLastBatch(Customizable_Rollup_Settings__c customizableRollupSettings) {
            customizableRollupSettings.Account_Hard_Credit_Last_Batch__c = Date.today();
            return customizableRollupSettings;
        }
    }

    /*******************************************************************************************************
    * @description Contact Hard Credit Incremental Rollups Settings.
    ********************************************************************************************************/
    public class ContactHardCreditSettings extends Settings {

        /*******************************************************************************************************
        * @description Gets the last time the Contact Hard Credit Batch runs successfully.
        * @param customizableRollupSettings The Customizable Rollups Settings.
        * @return Date.
        ********************************************************************************************************/
        protected override Date getLastBatch(Customizable_Rollup_Settings__c customizableRollupSettings) {
            return customizableRollupSettings.Contact_Hard_Credit_Last_Batch__c;
        }

        /*******************************************************************************************************
        * @description Updates the Contact Hard Credit Last Batch Run settings field.
        * @param customizableRollupSettings The Customizable Rollups Settings.
        * @return Customizable_Rollup_Settings__c.
        ********************************************************************************************************/
        protected override Customizable_Rollup_Settings__c updateLastBatch(Customizable_Rollup_Settings__c customizableRollupSettings) {
            customizableRollupSettings.Contact_Hard_Credit_Last_Batch__c = Date.today();
            return customizableRollupSettings;
        }
    }

    /*******************************************************************************************************
    * @description Contact Soft Credit Incremental Rollups Settings.
    ********************************************************************************************************/
    public class ContactSoftCreditSettings extends Settings {

        /*******************************************************************************************************
        * @description Gets the last time the Contact Soft Credit Batch runs successfully.
        * @param customizableRollupSettings The Customizable Rollups Settings.
        * @return Date.
        ********************************************************************************************************/
        protected override Date getLastBatch(Customizable_Rollup_Settings__c customizableRollupSettings) {
            return customizableRollupSettings.Contact_Soft_Credit_Last_Batch__c;
        }

        /*******************************************************************************************************
        * @description Updates the Contact Soft Credit Last Batch Run settings field.
        * @param customizableRollupSettings The Customizable Rollups Settings.
        * @return Customizable_Rollup_Settings__c.
        ********************************************************************************************************/
        protected override Customizable_Rollup_Settings__c updateLastBatch(Customizable_Rollup_Settings__c customizableRollupSettings) {
            customizableRollupSettings.Contact_Soft_Credit_Last_Batch__c = Date.today();
            return customizableRollupSettings;
        }
    }

    /*******************************************************************************************************
    * @description Recurring Donations Incremental Rollups Settings.
    ********************************************************************************************************/
    public class RecurringDonationsSettings extends Settings {

        /*******************************************************************************************************
        * @description Gets the last time the Recurring Donations Batch runs successfully.
        * @param customizableRollupSettings The Customizable Rollups Settings.
        * @return Date.
        ********************************************************************************************************/
        protected override Date getLastBatch(Customizable_Rollup_Settings__c customizableRollupSettings) {
            return customizableRollupSettings.Recurring_Donations_Last_Batch__c;
        }

        /*******************************************************************************************************
        * @description Updates the Recurring Donations Last Batch Run settings field.
        * @param customizableRollupSettings The Customizable Rollups Settings.
        * @return Customizable_Rollup_Settings__c.
        ********************************************************************************************************/
        protected override Customizable_Rollup_Settings__c updateLastBatch(Customizable_Rollup_Settings__c customizableRollupSettings) {
            customizableRollupSettings.Recurring_Donations_Last_Batch__c = Date.today();
            return customizableRollupSettings;
        }
    }
}