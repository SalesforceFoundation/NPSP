import { LightningElement, api, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { dispatch } from 'c/utilTemplateBuilder';
import { deepClone } from 'c/utilCommon';

import PAYMENT_OBJECT from '@salesforce/schema/npe01__OppPayment__c';
import PAYMENT_AMOUNT_INFO from '@salesforce/schema/npe01__OppPayment__c.npe01__Payment_Amount__c';
import PAYMENT_SCHEDULED_DATE_INFO from '@salesforce/schema/npe01__OppPayment__c.npe01__Scheduled_Date__c';
import PAYMENT_PAID_INFO from '@salesforce/schema/npe01__OppPayment__c.npe01__Paid__c';
import PAYMENT_NAME_INFO from '@salesforce/schema/npe01__OppPayment__c.Name';

export default class geDonationMatchingPaymentCard extends LightningElement {

    @api payment;

    @wire(getObjectInfo, { objectApiName: PAYMENT_OBJECT })
    wiredPaymentObject;

    get paymentAmountDetails() {
        return this.getFieldDetails(PAYMENT_AMOUNT_INFO);
    }

    get paymentScheduledDateDetails() {
        return this.getFieldDetails(PAYMENT_SCHEDULED_DATE_INFO);
    }

    get paymentPaidDetails() {
        return this.getFieldDetails(PAYMENT_PAID_INFO);
    }

    get paymentNameDetails() {
        return this.getFieldDetails(PAYMENT_NAME_INFO);
    }

    getFieldDetails(fieldInfo) {
        const fieldApiName = fieldInfo.fieldApiName;
        if (this.wiredPaymentObject.data) {
            const fields = this.wiredPaymentObject.data.fields;
            if (fields) {
                return { label: fields[fieldApiName].label, value: this.payment[fieldApiName] };
            }
        }
        return null;
    }

    handleUpdatePayment() {
        console.log('handleUpdatePayment: ', deepClone(this.payment), PAYMENT_OBJECT);
        const detail = { objectApiName: PAYMENT_OBJECT.objectApiName, fields: deepClone(this.payment) };
        dispatch(this, 'updatepayment', detail);
    }
}