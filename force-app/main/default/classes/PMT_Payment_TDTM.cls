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
* @group Payments
* @group-content ../../ApexDocContent/Payments.htm
* @description trigger handler on Payment and Opportunity objects for supporting Payments
*/
public class PMT_Payment_TDTM extends TDTM_Runnable {

    /** @description Retrieve and cache the household settings the first time this class is loaded only */
    private static final npo02__Households_Settings__c householdSettings = UTIL_CustomSettingsFacade.getHouseholdsSettings();

    /** @description Identifies if the Custom Setting Enforce Accounting Data Consistency is enforced */
    private Boolean isEnforceAccountingDataConsistency {
        get {
            if (isEnforceAccountingDataConsistency == null) {
                isEnforceAccountingDataConsistency = UTIL_CustomSettingsFacade.getContactsSettings().Enforce_Accounting_Data_Consistency__c;
            }
            return isEnforceAccountingDataConsistency;
        }
        set;
    }

    /** @description  Identifies if the org has the CurrencyIsoField */
    private Boolean isCurrencyFieldAvailable {
        get {
            if (isCurrencyFieldAvailable == null) {
                isCurrencyFieldAvailable = UserInfo.isMultiCurrencyOrganization();
            }
            return isCurrencyFieldAvailable;
        }
        set;
    }


    /*******************************************************************************************************
    * @description Trigger Handler on on Opportunity or Payment related to the Payment object
    * @param newlist the list of Opportunity or Payments from trigger new.
    * @param oldlist the list of Opportunity or Payments from trigger old.
    * @param triggerAction  which trigger event (BeforeInsert, AfterInsert, etc.).
    * @param objResult the describe for related object
    * @return dmlWrapper.
    ********************************************************************************************************/
    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist,
            TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        DmlWrapper dmlWrapper = new DmlWrapper();
        if (objResult.getsObjectType() == Opportunity.sObjectType) {
            dmlWrapper = runForOpportunities(newlist, oldlist, triggerAction);
        } else if (objResult.getsObjectType() == npe01__OppPayment__c.sObjectType) {
            dmlWrapper = runForPayments(newlist, oldlist, triggerAction);
        }

        return dmlWrapper;
    }

    /*******************************************************************************************************
    * @description Trigger Handler on Payment for managing Payments.
    * @param newlist The list of Payments from trigger new.
    * @param oldlist The list of Payments from trigger old.
    * @param triggerAction Which trigger event (BeforeInsert, AfterInsert, etc.).
    * @return dmlWrapper Returns a dmlWrapper object if there were opportunity records modified
    *  otherwise returns null
    ********************************************************************************************************/
    public DmlWrapper runForPayments(
        List<npe01__OppPayment__c> newlist,
        List<npe01__OppPayment__c> oldlist,
        TDTM_Runnable.Action triggerAction) {

        DmlWrapper dmlWrapper = null;

        validatePayments(newList, oldList, triggerAction);

        if (UTIL_Currency.getInstance().isMultiCurrencyOrganization()) {
            return handleMultiCurrencyPayments(newlist, oldlist, triggerAction, dmlWrapper);
        }

        return dmlWrapper;
    }

    /*******************************************************************************************************
    * @description Trigger Handler on Opportunities for managing Payments
    * @param newlist the list of Opps from trigger new.
    * @param oldlist the list of Opps from trigger old.
    * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.).
    * @return dmlWrapper Returns a dmlWrapper object if there were opportunity records modified.
    ********************************************************************************************************/
    public DmlWrapper runForOpportunities(
        List<Opportunity> newlist,
        List<Opportunity> oldlist,
        TDTM_Runnable.Action triggerAction) {

        Map<Id, Opportunity> mapIdOppOld = (oldlist != null ? new Map<Id, Opportunity>(oldlist) : new Map<Id, Opportunity>());

        DmlWrapper dmlWrapper = new DmlWrapper();

        //Evaluate and create new paymnets as necessary. Auto close opportunity when toatl payments == Opp.Amount.
        //If ACM is enabled, changes to payment records will not cause the Opportunity trigger to execute, therefore,
        //decision to close the Opportunity is also handled in Payment Trigger handleMultiCurrencyPayments() method.
        new PMT_PaymentCreator()
            .run(triggerAction, newList, mapIdOppOld, dmlWrapper);

        //if currency has changed, reset payment currencies
        if (triggerAction == TDTM_Runnable.Action.AfterUpdate && isCurrencyFieldAvailable) {
            List<Opportunity> listOppsForProcessing = new List<Opportunity>();
            for (integer i = 0; i < newlist.size(); i++) {
                Opportunity opp = newlist[i];
                if (opp.get('CurrencyIsoCode') != oldlist[i].get('CurrencyIsoCode')) {
                    listOppsForProcessing.add(opp);
                }
            }
            if (listOppsForProcessing.size() > 0) {
                setPaymentCurrencyFromOpportunity(listOppsForProcessing, dmlWrapper);
            }
        }
        return dmlWrapper;
    }

    /*******************************************************************************************************
    * @description Updates an opportunity's payment record when currency on the Opportunity is changed.
    * @param opps A list of opportunities whose currency has changed.
    * @return void This method modifies the dmlWrapper var and does not return anything
    ********************************************************************************************************/
    private static void setPaymentCurrencyFromOpportunity(List<Opportunity> opps, DmlWrapper dmlWrapper){
        final String currencyIsoCodeField = UTIL_Currency.CURRENCY_ISO_CODE_FIELD;
        final String paymentAmountField = 'npe01__Payment_Amount__c';

        Set<Id> oppIds = (new Map<Id, Opportunity>(opps)).keySet();

        Map<Id, SObject> dmlWrapperSObjectById = dmlWrapper.objectsToUpdate == null || dmlWrapper.objectsToUpdate.isEmpty()
            ? new Map<Id, SObject>()
            : new Map<Id, SObject>(dmlWrapper.objectsToUpdate);

        // Get a list of the Payment records by Opportunity and update the CurrencyIsoCode value
        String soql =
            'SELECT Id, CurrencyIsoCode, npe01__Payment_Amount__c, npe01__Opportunity__r.CurrencyIsoCode ' +
            'FROM npe01__OppPayment__c ' +
            'WHERE npe01__Opportunity__c IN :oppIds ' +
            'ORDER BY npe01__Opportunity__c';

        for (npe01__OppPayment__c pmt : database.query(soql)) {
            Opportunity opp = (Opportunity)pmt.getSObject('npe01__Opportunity__r');

            if (dmlWrapperSObjectById.containsKey(pmt.Id)) {
                SObject existingPayment = dmlWrapperSObjectById.get(pmt.Id);
                existingPayment.put(currencyIsoCodeField, opp.get(currencyIsoCodeField));
                //do not update payment Amount if the SObject is in DmlWrapper already

            } else {
                pmt.put(currencyIsoCodeField, opp.get(currencyIsoCodeField));
                pmt.put(paymentAmountField, pmt.npe01__Payment_Amount__c);
                dmlWrapper.objectsToUpdate.add(pmt);
            }
        }
    }

    /*******************************************************************************************************
    * @description Retrieve a Id Map of Opportunties related to a Set of Ids
    * @param oppIds Set of Opportunity Ids to retrieve
    * @return Map<Id, Opp> This method returns a map of Id to opportunity
    ********************************************************************************************************/
    private Map<Id, Opportunity> getPaymentOpportunities(Set<Id> oppIds) {
        String soql = 'SELECT Id, Amount, IsClosed, IsWon, StageName, ';
        if (isCurrencyFieldAvailable) {
            soql += 'CurrencyIsoCode, ';
        }
        soql += ' (SELECT id, npe01__Paid__c, npe01__Payment_Amount__c, npe01__Payment_Date__c, npe01__Written_Off__c ' +
                ' FROM Opportunity.npe01__OppPayment__r)' +
                ' FROM Opportunity WHERE Id IN :oppIds';

        return new Map<Id, Opportunity>((List<Opportunity>)Database.query(soql));
    }

    /*******************************************************************************************************
    * @description For multicurrency orgs, validate the currencies and set the appropriate stages
    *  and currency fields
    * @param newlist The list of Payments from trigger new.
    * @param oldlist The list of Payments from trigger old.
    * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.).
    * @return dmlWrapper this method modifies dmlWrapper and returns it
    ********************************************************************************************************/
    private DmlWrapper handleMultiCurrencyPayments(
        List<npe01__OppPayment__c> newlist,
        List<npe01__OppPayment__c> oldlist,
        TDTM_Runnable.Action triggerAction,
        DmlWrapper dmlWrapper) {

        if (dmlWrapper == null) {
            dmlWrapper = new DmlWrapper();
        }

        Set<Id> oppIds = new Set<Id>();
        for (npe01__OppPayment__c pmt : newlist) {
            oppIds.add(pmt.npe01__Opportunity__c);
        }

        Map<Id, Opportunity> oppsById = getPaymentOpportunities(oppIds);

        // Validation and default the CurrencyIsoCode for new records for Before Insert/update
        if (isCurrencyFieldAvailable && (triggerAction == TDTM_Runnable.Action.BeforeInsert || triggerAction == TDTM_Runnable.Action.BeforeUpdate)) {
            for (Integer i = 0; i < newlist.size(); i++) {
                npe01__OppPayment__c pmt = newlist[i];
                String oldPmtCurrency = (oldList != null ? (String) oldlist[i].get('CurrencyIsoCode') : null);
                validateAndSetPaymentCurrency(oppsById, pmt, oldPmtCurrency, triggerAction);
            }
        }

        // For an After Insert/Update Payment action, when Advanced Curr Mgt is enabled and there is a defined
        // Closed stage name in settings, roll up the total paynents and compare to the Opp.Amount. If the
        // two values are equal then close the Opportunity by setting the stage name.
        if (triggerAction == TDTM_Runnable.Action.AfterInsert || triggerAction == TDTM_Runnable.Action.AfterUpdate) {

            npe01__Contacts_And_Orgs_Settings__c ContactSettings = UTIL_CustomSettingsFacade.getContactsSettings();
            String closedStageName = ContactSettings.Payments_Auto_Close_Stage_Name__c;

            Boolean isACMEnabled = UTIL_Currency.getInstance().isAdvancedCurrencyManagementEnabled();
            if (isACMEnabled && String.isNotEmpty(closedStageName)) {
                // Loop through all the queried Opps with the subquery on payments
                for (Opportunity opp : oppsById.values()) {
                   handleOppPaymentWithAdvancedCurrency(opp, closedStageName, dmlWrapper);
                }
            }
        }
        return dmlWrapper;
    }

    /*******************************************************************************************************
    * @description  For multicurrency orgs, set the currency of the payment to the currency of
    *  the opportunity and make sure that the payment currency was not modified
    * @param oppsById Map of Opportunities
    * @param pmt Payment Object
    * @param oldPmtCurrency String of old Payment Currency
    * @param triggerAction Action that triggered this execution
    * @return void Does not return anything
    ********************************************************************************************************/
    private void validateAndSetPaymentCurrency(Map<Id, Opportunity> oppsById, npe01__OppPayment__c pmt, String oldPmtCurrency, TDTM_Runnable.Action triggerAction) {
        String oppCurrency = (String) oppsById.get(pmt.npe01__Opportunity__c).get('CurrencyIsoCode');
        String pmtCurrency = (String) pmt.get('CurrencyIsoCode');

        // Prevent the Payment CurrencyCode from being modified directly
        if (triggerAction == TDTM_Runnable.Action.BeforeUpdate && pmtCurrency != oldPmtCurrency && pmtCurrency != oppCurrency) {
            pmt.addError(System.Label.pmtModifyCurrency);

        } else if (triggerAction == TDTM_Runnable.Action.BeforeInsert && pmtCurrency != oppCurrency && pmtCurrency != null) {
            // If the User is attempting to set the Payment Currency to something different than the Opp currency
            pmt.addError(System.Label.pmtModifyCurrency);

        } else if (triggerAction == TDTM_Runnable.Action.BeforeInsert) {
            // Otherwise default the Payment CurrencyIsoCode to the value from the parent Opportunity
            pmt.put('CurrencyIsoCode', oppCurrency);
        }
    }

    /*******************************************************************************************************
    * @description For multicurrency orgs with advanced currency management enabled,
    * Set the stageName if the amount is equal payments made and opp is not closed.
    * @param opp Opportunity object
    * @param closedStageName String of the stageName
    * @param dmlWrapper DmlWrapper Object
    * @return void Does not return anything
    ********************************************************************************************************/
    private void handleOppPaymentWithAdvancedCurrency(Opportunity opp, String closedStageName, DmlWrapper dmlWrapper) {
        Decimal paidAmount = PMT_PaymentCreator.getPaymentsMade(opp);

        if (opp.Amount > 0 && paidAmount >= opp.Amount && !opp.isClosed && !opp.IsWon) {
            opp.StageName = closedStageName;
            dmlWrapper.objectsToUpdate.add(opp);
        }
    }

    /*******************************************************************************************************
    * @description Validate that the payment has the appropriate values. Currency Code validation is handled
    * in a different function.  We are using after trigger validation to ensure that other before triggers
    * do not change the values.
    * @param newlist The list of Payments from trigger new.
    * @param oldlist The list of Payments from trigger old.
    * @param triggerAction  Which trigger event (BeforeInsert, AfterInsert, etc.).
    * @return void Does not return anything
    ********************************************************************************************************/
    private void validatePayments(
        List<npe01__OppPayment__c> newList,
        List<npe01__OppPayment__c> oldList,
        TDTM_Runnable.Action triggerAction
    ) {  
        PMT_ValidationService validationService = new PMT_ValidationService(newlist, oldList, triggerAction);
        List<ErrorRecord> errorRecords = validationService.validate().getErrors();

        for (ErrorRecord error : errorRecords) {
            if (error.hasError()) {
                error.getRecord().addError(error.getFirstError());
            }
        }
    }
}