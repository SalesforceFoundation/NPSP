/*
    Copyright (c) 2017, Salesforce.org
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
* @date 2017
* @group
* @group-content
* @description Provides an adapter for Advancement package to be able to inject customizations into NPSP and provide API to inject to other project.
**/

global virtual with sharing class Advancement_Adapter {

    /**
     * @description To be called by the NPSP TDTM trigger dispatcher. Advancement will disable some NPSP trigger handlers records (since they conflict with HEDA version)
     * and return the rest
     *
     * @return List<Trigger_Handler__c> The TDTM configuration.
     */
    global virtual List<Trigger_Handler__c> getDefaultTdtmConfigNpspRecords(List<Trigger_Handler__c> listTH) {
        if(!Advancement_Info.useAdv()) {
            throw new AdapterException('Invalid call. This function is reserved for Salesforce use.');
        }

        return TDTM_Config_API.getDefaultRecords();
    }

    /**
     * @description Since Advancement will disable some NPSP trigger handler class, we need to fill in gap in HEDA.
     * Expose this API for Advancement to inject the rollup functionality into HEDA code base
     *
     * @return null
     */
    global void rollupAccounts(List<Id> listAccountId) {
        if(!Advancement_Info.useAdv()) {
            throw new AdapterException('Invalid call. This function is reserved for Salesforce use.');
        }

        ACCT_IndividualAccounts_TDTM.rollupAccounts(listAccountId);
    }

    /**
     * @description Since Advancement will disable some NPSP trigger handler class, we need to fill in gap in HEDA.
     * Expose this API for Advancement to inject the moving opportunity functionality into HEDA code base
     *
     * @return null
     */
    global void moveOppsToContactAccount(Map<Id,Id> mapContactIdAccountIdNew, Map<Id,Id> mapContactIdAccountIdOld) {
        if(!Advancement_Info.useAdv()) {
            throw new AdapterException('Invalid call. This function is reserved for Salesforce use.');
        }

        ACCT_IndividualAccounts_TDTM.moveOppsToContactAccount(mapContactIdAccountIdNew, mapContactIdAccountIdOld, null);
    }

    /**
     * @description Since Advancement will disable some NPSP trigger handler class, we need to fill in gap in HEDA.
     * Expose this API for Advancement to inject the setting NPSP's system Account fields functionality into HEDA code base
     *
     * @return null
     */
    global void configAccountForContact(Account a) {
        if(!Advancement_Info.useAdv()) {
            throw new AdapterException('Invalid call. This function is reserved for Salesforce use.');
        }

        a.npe01__SYSTEM_AccountType__c = CAO_Constants.isHHAccountModel() ? CAO_Constants.HH_ACCOUNT_TYPE : CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE;
        a.Type = CAO_Constants.isHHAccountModel() ? CAO_Constants.HH_TYPE : '';
        a.npe01__SYSTEMISINDIVIDUAL__c = true;
    }

    /**
     * @description Since Advancement will disable some NPSP trigger handler class, we need to fill in gap in HEDA.
     * Expose this API for Advancement to inject the setting NPSP's system Account fields functionality into HEDA code base
     *
     * @return null
     */
    global void configAccountTDTM(List<SObject> listNew, List<SObject> listOld, String action) {
        if(!Advancement_Info.useAdv()) {
            throw new AdapterException('Invalid call. This function is reserved for Salesforce use.');
        }

        TDTM_Runnable.Action triggerAction = TDTM_TriggerActionHelper.getTriggerActionFromName(action);
        ACCT_Accounts_TDTM accountsTDTM = new ACCT_Accounts_TDTM();
        accountsTDTM.configAccountForContact(listNew, listOld, triggerAction, new List<Account>(), new List<Account>());
    }

    /**
     * @description This is the expection class for Advancement Adapter class
     */
    global class AdapterException extends Exception{}
}