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
* @date 2012 (2.0)
* @group Settings
* @description The controller for the Recurring Donations Custom Installments panel
*/
public with sharing class STG_PanelRDCustomInstallment_CTRL extends STG_Panel {

    /*********************************************************************************************************
    * @description Returns the String Id of the RD Custom Installments panel.
    */
    public override String idPanel() { return 'idPanelRDInstPd'; }

    /*********************************************************************************************************
    * @description temporary ci used by the page for creating a new ci.
    */
    public npe03__Custom_Installment_Settings__c ciNew {
        get {
            if (ciNew == null)
              ciNew = new npe03__Custom_Installment_Settings__c();
            return ciNew;
        }
        private set;
    }

    /*********************************************************************************************************
    * @description Action Method for going into edit mode (to create a new ci)
    * @return null
    */
    public PageReference newCustomInstallment() {
        isEditMode = true;
        return null;
    }

    /*********************************************************************************************************
    * @description Action Method to save the new ci to the Database.
    * @return null
    */
    public PageReference createCustomInstallment() {
        Savepoint sp = Database.setSavepoint();
        try {
            insert ciNew;
            isEditMode = false;
            resetCustomInstallmentSettings();
            ciNew = null;
            String strPostSaveMessage = 'After saving the Installment Period record, you will also need to add your Installment Period Name to the Recurring Donation\'s Installment Period picklist. To edit the picklist, go to Setup, Create, Objects, then select Recurring Donations. Click on the Installment Period picklist, and then edit the picklist values.';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, strPostSaveMessage));
        } catch(Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler_API.Context.STTG);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }

    /*********************************************************************************************************
    * @description Action Method to cancel out of creating a new ci.
    * @return null
    */
    public PageReference cancelCustomInstallment() {
        isEditMode = false;
        ciNew = null;
        return null;
    }

    /*********************************************************************************************************
    * @description Resets custom installment settings so that they are reloaded and the cached version isn't used.
    */
    public void resetCustomInstallmentSettings() {
        UTIL_ListCustomSettingsFacade.mapCustomInstallmentSettings = null;
        STG_Panel.stgService.listRDCustomInstallment = null;
    }

    /*********************************************************************************************************
    * @description String to hold the Id of an existing ci to delete
    */
    public String ciIdDelete { get; set; }

    /*********************************************************************************************************
    * @description Action Method for deleting an existing ci.
    * @return null
    */
    public PageReference deleteCi() {
        if (!isRunningUserIsAdmin) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.stgDeletePermissionError));
            return null;
        }

        Savepoint sp = Database.setSavepoint();
        try {
            STG_SettingsManager_CTRL.idPanelCurrent = idPanel();
            if (ciIdDelete != null) {
                npe03__Custom_Installment_Settings__c ci = new npe03__Custom_Installment_Settings__c(Id = ciIdDelete);
                delete ci;
                // force reload.
                resetCustomInstallmentSettings();
                String strPostSaveMessage = 'After deleting the Installment Period record, you will also need to remove your Installment Period Name from the Recurring Donation\'s Installment Period picklist. To edit the picklist, go to Setup, Create, Objects, then select Recurring Donations. Click on the Installment Period picklist, and then edit the picklist values.  You will also need to update any open Recurring Donations that were using the Installment Period to use a new Installment Period value, and you will need to refresh the Recurring Donation\'s Opportunities.';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, strPostSaveMessage));
            }
        } catch(Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler_API.Context.STTG);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }

    /*********************************************************************************************************
    * @description List of SelectOptions for the periods we support for a ci
    */
    static public List<SelectOption> listSORDCustomPeriod {
        get {
            if (listSORDCustomPeriod == null) {
                listSORDCustomPeriod = new List<SelectOption>();
                listSORDCustomPeriod.add(new SelectOption('Days', 'Days'));
                listSORDCustomPeriod.add(new SelectOption('Weeks', 'Weeks'));
                listSORDCustomPeriod.add(new SelectOption('Months', 'Months'));
                listSORDCustomPeriod.add(new SelectOption('Years', 'Years'));
            }
            return listSORDCustomPeriod;
        }
        private set;
    }

}