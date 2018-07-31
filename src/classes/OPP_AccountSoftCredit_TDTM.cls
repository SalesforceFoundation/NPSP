/*
    Copyright (c) 2018 Salesforce.org
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
* @group Opportunity
* @description Trigger Handler on Account Soft Credit for AccSC management
*/
public class OPP_AccountSoftCredit_TDTM extends TDTM_Runnable {

    /** @Description Allows PSC_Opportunity_TDTM (shared with AccSC) to modify AccSC currency while blocking user requests to change currency.*/
    public static boolean blockCurrencyChange = true;

    /*******************************************************************************************************
    * @description Trigger Handler on Account Soft Credit that handles AccSC sychronization with OCR's.
    * The scenarios to support are:
    *   Before Insert - sync CurrencyIsoCode with Opportunity
    *
    * @param listNew the list of PSCs from trigger new.
    * @param listOld the list of PSCs from trigger old.
    * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.).
    * @param objResult the describe for PSC
    * @return dmlWrapper.
    ********************************************************************************************************/
    public override DmlWrapper run(List<SObject> listNew, List<SObject> listOld,
            TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        // BEFORE INSERT
        if (triggerAction == TDTM_Runnable.Action.BeforeInsert) {
            synchronizeCurrencyIsoCode(listNew);
        }

        // BEFORE UPDATE
        else if (triggerAction == TDTM_Runnable.Action.BeforeUpdate) {
            blockManualCurrencyChange(listNew, listOld);
        }

        return null;
    }


    /*******************************************************************************************************
    * @description For the Account Soft Credits, sync their Iso code with the Opportunity.
    * @param listAccSC the list of AccSCs from trigger new.
    * @return void.
    ********************************************************************************************************/
    private void synchronizeCurrencyIsoCode(List<Account_Soft_Credit__c> listAccSC) {

        // collect all our Opps and Contacts referenced by the PSC's
        Set<Id> setOppId = new set<Id>();
        for (Account_Soft_Credit__c accSC : listAccSC) {
            setOppId.add(accSC.Opportunity__c);
        }

        //copy opportunity currency if multicurrency is enabled
        if (userInfo.isMultiCurrencyOrganization()) {
            String oppQuery = 'SELECT Id, CurrencyIsoCode FROM Opportunity WHERE Id IN :setOppId';
            Map<Id, Opportunity> mapOppIdOpp = new Map<Id, Opportunity>((List<Opportunity>) Database.query(oppQuery));

            for (Account_Soft_Credit__c accSC : listAccSC)
                accSC.put('CurrencyIsoCode', mapOppIdOpp.get(accSC.Opportunity__c).get('CurrencyIsoCode'));
        }
    }

    /*******************************************************************************************************
    * @description Block manual Currency Iso Code changes directly to the Account Soft Credit
    * @param listAccSCNew the list of AccSCs from trigger new.
    * @param listAccSCOld the list of AccSCs from trigger old.
    * @return void.
    ********************************************************************************************************/
    private void blockManualCurrencyChange(List<Account_Soft_Credit__c> listAccSCNew, List<Account_Soft_Credit__c> listAccSCOld) {

        for (Integer i = 0; i < listAccSCNew.size(); i++) {
            Account_Soft_Credit__c accSCNew = listAccSCNew[i];
            Account_Soft_Credit__c accSCOld = listAccSCOld[i];

            // don't allow manually changing the AccSC currency: it must be changed through the parent opportunity
            if (userInfo.isMultiCurrencyOrganization() && accSCNew.get('CurrencyIsoCode') != accSCOld.get('CurrencyIsoCode') && OPP_AccountSoftCredit_TDTM.blockCurrencyChange) {
                accSCNew.addError(Label.pscManageSoftCreditsCantChangeCurrency);
            }
        }
    }

}