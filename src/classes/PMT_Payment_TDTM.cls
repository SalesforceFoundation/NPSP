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

    /*******************************************************************************************************
    * @description Trigger Handler on on Opportunity or Payment related to the Paymetn object
    * @param newlist the list of Opportunity or Payments from trigger new.
    * @param oldlist the list of Opportunity or Payments from trigger old.
    * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.).
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
    * @param newlist the list of Payments from trigger new.
    * @param oldlist the list of Payments from trigger old.
    * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.).
    * @return dmlWrapper.
    ********************************************************************************************************/
    public static DmlWrapper runForPayments(List<npe01__OppPayment__c> newlist, List<npe01__OppPayment__c> oldlist,
            TDTM_Runnable.Action triggerAction) {

        if (!UTIL_Currency.getInstance().isMultiCurrencyOrganization()) {
            return null;
        }

        DmlWrapper dmlWrapper = new DmlWrapper();

        Set<Id> oppIds = new Set<Id>();
        for (npe01__OppPayment__c pmt : newlist) {
            oppIds.add(pmt.npe01__Opportunity__c);
        }

        // Query the Opportunity with a sub-query on Payments
        String soql = 'SELECT Id, Amount, IsClosed, IsWon, StageName, ';
        if (UserInfo.isMultiCurrencyOrganization()) {
            soql += 'CurrencyIsoCode, ';
        }
        soql += ' (SELECT id, npe01__Paid__c, npe01__Payment_Amount__c, npe01__Payment_Date__c, npe01__Written_Off__c ' +
                ' FROM Opportunity.npe01__OppPayment__r)' +
                ' FROM Opportunity WHERE Id IN :oppIds';
        Map<Id, Opportunity> mapOfOpps = new Map<Id, Opportunity>((List<Opportunity>)database.query(soql));

        // Validation and default the CurrencyIsoCode for new records for Before Insert/update
        if (UserInfo.isMultiCurrencyOrganization() && (triggerAction == TDTM_Runnable.Action.BeforeInsert || triggerAction == TDTM_Runnable.Action.BeforeUpdate)) {
            for (integer i = 0; i < newlist.size(); i++) {
                npe01__OppPayment__c pmt = newlist[i];

                String oppCurrency = (String) mapOfOpps.get(pmt.npe01__Opportunity__c).get('CurrencyIsoCode');
                String pmtCurrency = (String) pmt.get('CurrencyIsoCode');
                String oldPmtCurrency = (oldList != null ? (String) oldlist[i].get('CurrencyIsoCode') : null);

                // Prevent the Payment CurrencyCode from being modified directly
                if (triggerAction == TDTM_Runnable.Action.BeforeUpdate && pmtCurrency != oldPmtCurrency && pmtCurrency != oppCurrency) {
                    pmt.addError(Label.pmtModifyCurrency);

                } else if (triggerAction == TDTM_Runnable.Action.BeforeInsert && pmtCurrency != oppCurrency && pmtCurrency != null) {
                    // If the User is attempting to set the Payment Currency to something different than the Opp currency
                    pmt.addError(Label.pmtModifyCurrency);

                } else if (triggerAction == TDTM_Runnable.Action.BeforeInsert) {
                    // Otherwise default the Payment CurrencyIsoCode to the value from the parent Opportunity
                    pmt.put('CurrencyIsoCode', oppCurrency);
                }
            }
        }

        // For an After Insert/Update Payment action, when Advanced Curr Mgt is enabled and there is a defined
        // Closed stage name in settings, roll up the total paynents and compare to the Opp.Amount. If the
        // two values are equal then close the Opportunity by setting the stage name.
        if (triggerAction == TDTM_Runnable.Action.AfterInsert || triggerAction == TDTM_Runnable.Action.AfterUpdate) {

            npe01__Contacts_And_Orgs_Settings__c ContactSettings = UTIL_CustomSettingsFacade.getContactsSettings();
            String closedStageName = ContactSettings.Payments_Auto_Close_Stage_Name__c;

            Boolean isACMEnabled = UTIL_Currency.getInstance().isAdvancedCurrencyManagementEnabled();
            if (isACMEnabled && !String.isEmpty(closedStageName)) {
                // Loop through all the queried Opps with the subquery on payments
                for (Opportunity opp : mapOfOpps.values()) {
                    // If the Opp Amount is greater than zero and the Opp is not currently closed
                    // and the amount paid is equal to the total opportunity amount
                    Decimal paidAmount = PMT_PaymentCreator.getPaymentsMade(opp);
                    if (opp.Amount > 0 && paidAmount == opp.Amount && !opp.isClosed && !opp.IsWon) {
                        opp.StageName = closedStageName;
                        dmlWrapper.objectsToUpdate.add(opp);
                    }
                }
            }
        }

        return dmlWrapper;
    }

    /*******************************************************************************************************
    * @description Trigger Handler on Opportunities for managing Payments
    * @param newlist the list of Opps from trigger new. 
    * @param oldlist the list of Opps from trigger old. 
    * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.). 
    * @return dmlWrapper.
    ********************************************************************************************************/
    public static DmlWrapper runForOpportunities(List<Opportunity> newlist, List<Opportunity> oldlist,
            TDTM_Runnable.Action triggerAction) {

        Map<Id, Opportunity> mapIdOppNew = (newlist != null ? new Map<Id, Opportunity>(newlist) : new Map<Id, Opportunity>());
        Map<Id, Opportunity> mapIdOppOld = (oldlist != null ? new Map<Id, Opportunity>(oldlist) : new Map<Id, Opportunity>());

        DmlWrapper dmlWrapper = new DmlWrapper();

        // Create new Payments as necessary. Also (when Advanced Curr Mgt is not enabled), auto close the
        // Opportunity if that is enabled in settings and the total Payments == Opp.Amount.
        // If ACM is enabled, changes to payment records will not cause the Opportunity trigger to execute, so
        // the decision to close the Opportunity is handled in the runForPayments() method.
        // However, even if ACM is enabled, if the Opportunity.Amount is updated to match the total Payments
        // the Opportunity should still be marked as closed.
        PMT_PaymentCreator pc = new PMT_PaymentCreator(mapIdOppNew, mapIdOppOld, triggerAction, dmlWrapper);

        //if currency has changed, reset payment currencies
        if (triggerAction == TDTM_Runnable.Action.AfterUpdate && UserInfo.isMultiCurrencyOrganization()) {
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
    * @param listOpps A list of opportunities whose currency has changed.
    * @return void This method modifies the dmlWrapper var and does not return anything
    ********************************************************************************************************/
    private static void setPaymentCurrencyFromOpportunity(list<Opportunity> listOpps, DmlWrapper dmlWrapper){

        // Get a list of the Opportunity Id's
        Set<Id> oppIds = (new Map<Id, Opportunity>(listOpps)).keySet();

        // Get a list of the Payment records by Opportunity and update the CurrencyIsoCode value
        String soql = 'SELECT Id, CurrencyIsoCode, npe01__Payment_Amount__c, npe01__Opportunity__r.CurrencyIsoCode FROM npe01__OppPayment__c ' +
            'WHERE npe01__Opportunity__c IN :oppIds ORDER BY npe01__Opportunity__c';
        for (npe01__OppPayment__c pmt : database.query(soql)) {
            Opportunity opp = (Opportunity)pmt.getSObject('npe01__Opportunity__r');
            pmt.put('CurrencyIsoCode', opp.get('CurrencyIsoCode'));
            pmt.put('npe01__Payment_Amount__c', pmt.npe01__Payment_Amount__c);
            dmlWrapper.objectsToUpdate.add(pmt);
        }
    }

}