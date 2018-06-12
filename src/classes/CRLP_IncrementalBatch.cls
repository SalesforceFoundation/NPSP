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
* @description Contains the Classes that manage the Incremental Rollups Batch
*/
public class CRLP_IncrementalBatch {

    /*******************************************************************************************************
    * @description Incremental Rollups Settings Base class.
    ********************************************************************************************************/
    public abstract class Settings {
        private Customizable_Rollup_Settings__c customizableRollupSettings;
        private Integer rollupsMaxDaysBack;

        public Settings() {
            customizableRollupSettings = UTIL_CustomSettingsFacade.getCustomizableRollupSettings();
            rollupsMaxDaysBack = getRollupsMaxDaysBack();
        }

        public Boolean isEnabled() {
            return customizableRollupSettings.Enable_Incremental_Rollups_Mode__c;
        }

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

        public void finishBatch() {
            upsert getUpdatedLastBatch(customizableRollupSettings);
        }

        protected abstract Date getLastBatch(Customizable_Rollup_Settings__c customizableRollupSettings);
        
        protected abstract Customizable_Rollup_Settings__c getUpdatedLastBatch(Customizable_Rollup_Settings__c customizableRollupSettings);

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

    public class AccountHardCreditSettings extends Settings {

        protected override Date getLastBatch(Customizable_Rollup_Settings__c customizableRollupSettings) {
            return customizableRollupSettings.Account_Hard_Credit_Last_Batch__c;
        }

        protected override Customizable_Rollup_Settings__c getUpdatedLastBatch(Customizable_Rollup_Settings__c customizableRollupSettings) {
            customizableRollupSettings.Account_Hard_Credit_Last_Batch__c = Date.today();
            return customizableRollupSettings;
        }
    }

    public class ContactHardCreditSettings extends Settings {

        protected override Date getLastBatch(Customizable_Rollup_Settings__c customizableRollupSettings) {
            return customizableRollupSettings.Contact_Hard_Credit_Last_Batch__c;
        }

        protected override Customizable_Rollup_Settings__c getUpdatedLastBatch(Customizable_Rollup_Settings__c customizableRollupSettings) {
            customizableRollupSettings.Contact_Hard_Credit_Last_Batch__c = Date.today();
            return customizableRollupSettings;
        }
    }

    public class ContactSoftCreditSettings extends Settings {

        protected override Date getLastBatch(Customizable_Rollup_Settings__c customizableRollupSettings) {
            return customizableRollupSettings.Contact_Soft_Credit_Last_Batch__c;
        }

        protected override Customizable_Rollup_Settings__c getUpdatedLastBatch(Customizable_Rollup_Settings__c customizableRollupSettings) {
            customizableRollupSettings.Contact_Soft_Credit_Last_Batch__c = Date.today();
            return customizableRollupSettings;
        }
    }

    public class RecurringDonationsSettings extends Settings {

        protected override Date getLastBatch(Customizable_Rollup_Settings__c customizableRollupSettings) {
            return customizableRollupSettings.Recurring_Donations_Last_Batch__c;
        }

        protected override Customizable_Rollup_Settings__c getUpdatedLastBatch(Customizable_Rollup_Settings__c customizableRollupSettings) {
            customizableRollupSettings.Recurring_Donations_Last_Batch__c = Date.today();
            return customizableRollupSettings;
        }
    }
}