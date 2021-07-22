import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import { handleError } from 'c/utilTemplateBuilder';
import { deepClone } from 'c/utilCommon';
import geLabelService from 'c/geLabelService';

import PAYMENT_OBJECT from '@salesforce/schema/npe01__OppPayment__c';
import PAYMENT_AMOUNT_FIELD from '@salesforce/schema/npe01__OppPayment__c.npe01__Payment_Amount__c';
import PAYMENT_SCHEDULED_DATE_FIELD from '@salesforce/schema/npe01__OppPayment__c.npe01__Scheduled_Date__c';
import PAYMENT_PAID_FIELD from '@salesforce/schema/npe01__OppPayment__c.npe01__Paid__c';
import PAYMENT_NAME_FIELD from '@salesforce/schema/npe01__OppPayment__c.Name';
import ELEVATE_PAYMENT_STATUS_FIELD
    from '@salesforce/schema/npe01__OppPayment__c.Elevate_Payment_API_Status__c';

const FIELDS = [
    PAYMENT_AMOUNT_FIELD,
    PAYMENT_SCHEDULED_DATE_FIELD,
    PAYMENT_PAID_FIELD,
    PAYMENT_NAME_FIELD,
    ELEVATE_PAYMENT_STATUS_FIELD,
]

export default class geDonationMatchingPaymentCard extends LightningElement {

    // Expose custom labels to template
    CUSTOM_LABELS = geLabelService.CUSTOM_LABELS;

    @api payment;
    @api selectedDonationId;

    @track paymentObject;
    @track wiredPaymentRecord;

    @wire(getObjectInfo, { objectApiName: PAYMENT_OBJECT })
    wiredPaymentObject(response) {
        if (response.data) {
            this.paymentObject = response.data;
        }

        if (response.error) {
            handleError(response.error);
        }
    }

    get paymentId() {
        return this.payment.Id;
    }

    @wire(getRecord, { recordId: '$paymentId', fields: FIELDS })
    wiredPayment(response) {
        if (response.data) {
            this.wiredPaymentRecord = response.data;
        }

        if (response.error) {
            handleError(response.error);
        }
    }

    get isLoading() {
        return this.paymentObject && this.wiredPaymentRecord ? false : true;
    }

    get paymentComputedName() {
        if (this.wiredPaymentRecord) {
            return geLabelService.format(this.CUSTOM_LABELS.geHeaderMatchingPayment,
                [
                    this.paymentAmountDetails.value,
                    this.paymentScheduledDateDetails.value
                ]);
        }
        return '';
    }

    get isSelectedDonation() {
        return this.selectedDonationId &&
            this.payment &&
            this.payment.Id === this.selectedDonationId ?
            true :
            false;
    }

    get computedCardCssClass() {
        return this.isSelectedDonation ? 'slds-card_extension_active' : '';
    }

    get paymentObjectApiName() {
        return PAYMENT_OBJECT.objectApiName ? PAYMENT_OBJECT.objectApiName : undefined;
    }

    get paymentAmountDetails() {
        return this.getFieldDetails(PAYMENT_AMOUNT_FIELD, this.wiredPaymentRecord);
    }

    get paymentScheduledDateDetails() {
        return this.getFieldDetails(PAYMENT_SCHEDULED_DATE_FIELD, this.wiredPaymentRecord);
    }

    get paymentPaidDetails() {
        return this.getFieldDetails(PAYMENT_PAID_FIELD, this.wiredPaymentRecord);
    }

    get paymentNameDetails() {
        return this.getFieldDetails(PAYMENT_NAME_FIELD, this.wiredPaymentRecord);
    }

    get paymentPaidComputedValue() {
        return this.payment[PAYMENT_PAID_FIELD.fieldApiName] === true ?
            this.CUSTOM_LABELS.commonYes :
            this.CUSTOM_LABELS.commonNo;
    }

    getFieldDetails(fieldInfo, wiredPaymentRecord) {
        const fieldApiName = fieldInfo.fieldApiName;
        const fieldDescribes = this.paymentObject.fields;

        if (fieldDescribes && wiredPaymentRecord) {
            const value =
                wiredPaymentRecord.fields[fieldApiName].displayValue ||
                wiredPaymentRecord.fields[fieldApiName].value ||
                '';

            return {
                label: fieldDescribes[fieldApiName].label,
                fieldApiName: fieldApiName,
                value: value,
            };
        }
        return { fieldApiName: fieldApiName };
    }

    /*******************************************************************************
    * @description Method dispatches an event to notify geDonationMatching that an
    * payment donation has been selected.
    */
    handleUpdatePayment() {
        const detail = { objectApiName: PAYMENT_OBJECT.objectApiName, fields: deepClone(this.payment) };
        this.dispatchEvent(new CustomEvent('updatepayment', { detail }));
    }

    // ================================================================================
    // AUTOMATION LOCATOR GETTERS
    // ================================================================================

    get qaLocatorUpdatePayment() {
        return `button ${this.CUSTOM_LABELS.geButtonMatchingUpdatePayment} ${this.paymentNameDetails.value}`;
    }
}