/*
    Copyright (c) 2019 Salesforce.org
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
* @date 2022
* @group Payment and Refund
* @description Payment Validation Service
*
*/
public inherited sharing class PMT_ValidationService {

    private Boolean isEnforceAccountingDataConsistency {
        get {
            if (isEnforceAccountingDataConsistency == null) {
                isEnforceAccountingDataConsistency = UTIL_CustomSettingsFacade.getContactsSettings().Enforce_Accounting_Data_Consistency__c;
            }
            return isEnforceAccountingDataConsistency;
        }
        set;
    }

    @TestVisible
    private PaymentSelector paymentSelector {
        get {
            if (paymentSelector == null) {
                paymentSelector = new PaymentSelector();
            }
            return paymentSelector;
        }
        set;
    }

    private Map<Id, npe01__OppPayment__c> originalPaymentWithRefunds {
        get {
            if (originalPaymentWithRefunds == null) {
                originalPaymentWithRefunds = getPaymentsWithAdjustedRefunds();
            }
            return originalPaymentWithRefunds;
        }
        set;
    }

    @TestVisible
    private List<npe01__OppPayment__c> payments = new List<npe01__OppPayment__c>();
    private List<npe01__OppPayment__c> oldPayments = new List<npe01__OppPayment__c>();


    public PMT_ValidationService(List<npe01__OppPayment__c> payments) {
        this.payments = payments;
    }

    /**
    * @description Constructor for the PMT_ValidationService class for Update context
    * @param payments New payments that will be validated
    * @param oldPayments old payments which are available in the database, the size and Id should match payments
    */
    public PMT_ValidationService(List<npe01__OppPayment__c> payments, List<npe01__OppPayment__c> oldPayments) {
        this.payments = payments;
        this.oldPayments = oldPayments;
    }

    public List<ErrorRecord> validate(TDTM_Runnable.Action triggerAction) {
        List<ErrorRecord> errorRecords = new List<ErrorRecord>();
        Boolean isNew = oldPayments == null || oldPayments.isEmpty();

        for (Integer i = 0; i < payments.size(); i++) {
            npe01__OppPayment__c payment = payments[i];
            npe01__OppPayment__c oldPayment = isNew ? null : oldPayments[i];
            
            ErrorRecord errorCollection = new ErrorRecord(payment);

            validateAccountDataConsistency(payment, errorCollection, triggerAction);

            if (triggerAction == TDTM_Runnable.Action.BeforeInsert || triggerAction == TDTM_Runnable.Action.BeforeUpdate) {
                validateRefunds(payment, errorCollection);
            }

            if (errorCollection.hasError()) {
                errorRecords.add(errorCollection);
            }
        }

        return errorRecords;
    }

    private void validateAccountDataConsistency(npe01__OppPayment__c payment, ErrorRecord errorCollection, TDTM_Runnable.Action triggerAction) {
        if (triggerAction == TDTM_Runnable.Action.AfterInsert || triggerAction == TDTM_Runnable.Action.AfterUpdate) {
            if (this.isEnforceAccountingDataConsistency) {
                enforceAccountingDataConsistency(payment, errorCollection);
            }

            if (payment.npe01__Paid__c == true && payment.npe01__Written_Off__c == true) {
                errorCollection.addError(System.Label.pmtWriteOffPaidPayment);
            }
        }
    }

    /*******************************************************************************************************
    * @description If the custom setting to enforce account rules is enabled, it will validate that paid payments
    * have a payment date and unpaid payments have a scheduled date.
    * @param payment the Payment from trigger new.
    * @param errorCollection Collection of error
    ********************************************************************************************************/
    private void enforceAccountingDataConsistency(npe01__OppPayment__c payment, ErrorRecord errorCollection) {
        if ((payment.npe01__Paid__c == true || payment.npe01__Written_Off__c == true) && payment.npe01__Payment_Date__c == null) {

            if (payment.npe01__Paid__c == true) {
                errorCollection.addError(System.Label.pmtPaidPaymentDateRequired);

            } else {
                errorCollection.addError(System.Label.pmtWrittenOffPaymentDateRequired);

            }
        } else if (payment.npe01__Paid__c == false && payment.npe01__Written_Off__c == false && payment.npe01__Scheduled_Date__c == null) {
            errorCollection.addError(System.Label.pmtUnpaidPaymentScheduledDateRequired);
        }
    }

    private void validateRefunds(npe01__OppPayment__c payment, ErrorRecord errorCollection) {
        if (payment.DebitType__c != PMT_RefundService.FULL_REFUND) {
            return;
        }

        npe01__OppPayment__c originalPayment = originalPaymentWithRefunds.get(payment.originalPayment__c);

        if (originalPayment == null) {
            errorCollection.addError('Missing Original Payment');
        }

        originalPayment.npe01__Payment_Amount__c += payment.npe01__Payment_Amount__c;

        if (originalPayment.DebitType__c == PMT_RefundService.FULL_REFUND || originalPayment.npe01__Payment_Amount__c != 0) {
            errorCollection.addError(System.Label.pmtPaymentNotRefundable);
        }

    }

    private Map<Id, npe01__OppPayment__c> getPaymentsWithAdjustedRefunds() {
        Set<Id> originalPaymentIds = UTIL_SObject.extractId(this.payments, npe01__OppPayment__c.originalPayment__c);
        if (originalPaymentIds.isEmpty()) {
            return new Map<Id, npe01__OppPayment__c>();
        }

        List<npe01__OppPayment__c> originalPayments = paymentSelector.getPaymentsWithRefunds(originalPaymentIds);
        for (npe01__OppPayment__c originalPayment : originalPayments) {
            if (originalPayment.Refunds__r != null) {
                for (npe01__OppPayment__c refund : originalPayment.Refunds__r) {
                    originalPayment.npe01__Payment_Amount__c += refund.npe01__Payment_Amount__c;
                }
            }
        }

        return new Map<Id, npe01__OppPayment__c>(originalPayments);
    }
}
