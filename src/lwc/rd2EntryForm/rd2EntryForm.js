import { LightningElement, wire, track, api } from 'lwc';
import { getRecord, getRecordUi, getFieldValue } from 'lightning/uiRecordApi';

import SOBJECT_ACCOUNT from '@salesforce/schema/Account';
import SOBJECT_CONTACT from '@salesforce/schema/Contact';

import FIELD_NAME from '@salesforce/schema/npe03__Recurring_Donation__c.Name';
import FIELD_ACCOUNT from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Organization__c';
import FIELD_CONTACT from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Contact__c';
import FIELD_DATE_ESTABLISHED from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Date_Established__c';
import FIELD_STATUS from '@salesforce/schema/npe03__Recurring_Donation__c.Status__c';
import FIELD_AMOUNT from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Amount__c';
import FIELD_PAYMENT_METHOD from '@salesforce/schema/npe03__Recurring_Donation__c.PaymentMethod__c';
import FIELD_INSTALLMENT_PERIOD from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installment_Period__c';
import FIELD_INSTALLMENT_FREQUENCY from '@salesforce/schema/npe03__Recurring_Donation__c.InstallmentFrequency__c';
import FIELD_DAY_OF_MONTH from '@salesforce/schema/npe03__Recurring_Donation__c.Day_of_Month__c';
import FIELD_START_DATE from '@salesforce/schema/npe03__Recurring_Donation__c.StartDate__c';
import FIELD_CAMPAIGN from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Recurring_Donation_Campaign__c';

import cancel from '@salesforce/label/c.stgBtnCancel';
import save from '@salesforce/label/c.stgBtnSave';

export default class rd2EntryForm extends LightningElement {

    fields = {
        FIELD_NAME,
        FIELD_ACCOUNT,
        FIELD_CONTACT,
        FIELD_DATE_ESTABLISHED,
        FIELD_STATUS,
        FIELD_AMOUNT,
        FIELD_PAYMENT_METHOD,
        FIELD_INSTALLMENT_PERIOD,
        FIELD_INSTALLMENT_FREQUENCY,
        FIELD_DAY_OF_MONTH,
        FIELD_START_DATE,
        FIELD_CAMPAIGN
    };

    @track labels = {
        cancel,
        save
    }


    @api recordId;
    @api objectApiName;

    @track title;
    @track record;
    @track selectedDonorType;
    @track contactId;
    @track accountId;


    /***
    * @description Initializes the component
    */
    connectedCallback() {
        this.selectedDonorType = this.record === undefined || this.contactId !== null
            ? SOBJECT_CONTACT.objectApiName
            : SOBJECT_ACCOUNT.objectApiName;
    }
    /*
        renderedCallback() {
            this.handleShowModal();
        }
    */
    handleOnLoad(event) {
        this.handleShowModal();

        if (this.recordId === undefined || this.recordId === null) {
            this.title = 'New Recurring Donation';
            return;
        }

        this.record = event.detail.records[this.recordId];
        this.contactId = this.record.fields[FIELD_CONTACT.fieldApiName].value;
        this.accountId = this.record.fields[FIELD_ACCOUNT.fieldApiName].value;
        this.title = 'Edit ' + this.record.fields[FIELD_NAME.fieldApiName].value;
    }

    get donorTypes() {
        return [
            { label: 'Contact', value: SOBJECT_CONTACT.objectApiName, isSelected: this.selectedDonorType === SOBJECT_CONTACT.objectApiName },
            { label: 'Account', value: SOBJECT_ACCOUNT.objectApiName, isSelected: this.selectedDonorType === SOBJECT_ACCOUNT.objectApiName },
        ];
    }

    @api
    get isDonorContact() {
        return this.selectedDonorType === SOBJECT_CONTACT.objectApiName;
    }

    @api
    get isDonorAccount() {
        return this.selectedDonorType === SOBJECT_ACCOUNT.objectApiName;
    }

    handleDonorTypeChange(event) {
        this.selectedDonorType = event.target.value;

        //clear fields
        this.contactId = null;
        this.accountId = null;
    }

    handleSubmit(event) {
        this.template.querySelector('lightning-record-edit-form').submit();
    }

    handleCancel(event) {
        this.handleCloseModal();
    }

    handleShowModal() {
        const modal = this.template.querySelector('c-modal');
        modal.show();
    }

    handleCloseModal() {
        const modal = this.template.querySelector('c-modal');
        modal.hide();
    }

    handleKeypress(event) {
        if (event.which === 13) {
            event.preventDefault();
            this.handleSubmit();
        }
    }

}