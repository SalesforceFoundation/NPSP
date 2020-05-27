import { LightningElement, api, track, wire } from 'lwc';
import { fireEvent } from 'c/pubsubNoPageRef';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getRecord} from 'lightning/uiRecordApi';

import RECURRING_DONATION_OBJECT from '@salesforce/schema/npe03__Recurring_Donation__c';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import CONTACT_OBJECT from '@salesforce/schema/Contact';

import FIELD_NAME from '@salesforce/schema/npe03__Recurring_Donation__c.Name';
import FIELD_ACCOUNT from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Organization__c';
import FIELD_CONTACT from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Contact__c';
import FIELD_DATE_ESTABLISHED from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Date_Established__c';
import FIELD_RECURRING_TYPE from '@salesforce/schema/npe03__Recurring_Donation__c.RecurringType__c';
import FIELD_PLANNED_INSTALLMENTS from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installments__c';
import FIELD_AMOUNT from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Amount__c';
import FIELD_PAYMENT_METHOD from '@salesforce/schema/npe03__Recurring_Donation__c.PaymentMethod__c';
import FIELD_INSTALLMENT_PERIOD from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installment_Period__c';
import FIELD_INSTALLMENT_FREQUENCY from '@salesforce/schema/npe03__Recurring_Donation__c.InstallmentFrequency__c';
import FIELD_DAY_OF_MONTH from '@salesforce/schema/npe03__Recurring_Donation__c.Day_of_Month__c';
import FIELD_START_DATE from '@salesforce/schema/npe03__Recurring_Donation__c.StartDate__c';
import FIELD_CAMPAIGN from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Recurring_Donation_Campaign__c';

import cancelButtonLabel from '@salesforce/label/c.stgBtnCancel';
import saveButtonLabel from '@salesforce/label/c.stgBtnSave';
import unknownErrorLabel from '@salesforce/label/c.commonUnknownError';
import newHeaderLabel from '@salesforce/label/c.RD2_EntryFormHeader';
import editHeaderLabel from '@salesforce/label/c.commonEdit';
import currencyFieldLabel from '@salesforce/label/c.lblCurrency';
import donationSectionHeader from '@salesforce/label/c.RD2_EntryFormDonationSectionHeader';
import donorSectionHeader from '@salesforce/label/c.RD2_EntryFormDonorSectionHeader';
import otherSectionHeader from '@salesforce/label/c.RD2_EntryFormOtherSectionHeader';
import insertSuccessMessage from '@salesforce/label/c.RD2_EntryFormInsertSuccessMessage';
import updateSuccessMessage from '@salesforce/label/c.RD2_EntryFormUpdateSuccessMessage';

import getSetting from '@salesforce/apex/RD2_entryFormController.getSetting';

export default class rd2EntryForm extends LightningElement {

    @api parentId;
    @api recordId;
    listenerEvent = 'rd2EntryFormEvent';

    customLabels = Object.freeze({
        cancelButtonLabel,
        saveButtonLabel,
        donationSectionHeader,
        donorSectionHeader,
        otherSectionHeader
    });

    @track fields = {};
    @track record;
    recurringDonationInfo;
    fieldInfos;
    dayOfMonthPicklistValue;
    lastDayPicklistValue;

    @track header = newHeaderLabel;

    @track isAutoNamingEnabled;
    @track isMultiCurrencyEnabled;

    @track contactId;
    @track accountId;

    isNew = false;
    @track isLoading = true;
    @track isFieldInfoReady = false;
    isRecordReady = false;
    isSettingReady = false;

    @track hasError = false;
    @track errorMessage = {};

    /*******************************************************************************
    * @description Dynamic render edit form CSS to show/hide the edit form 
    */
    get cssEditForm() {
        return (!this.isLoading && this.isSettingReady && this.isFieldInfoReady && this.isRecordReady)
            ? ''
            : 'slds-hide';
    }

    /*******************************************************************************
    * @description Set Installment Frequency to 1 in New entry form
    */
    get defaultInstallmentFrequency() {
        return (this.isNew)
            ? '1'
            : undefined;
    }

    /*******************************************************************************
    * @description Set today's date as default Date of Month in New entry form
    */
    get defaultDayOfMonth() {
        return (this.isNew && this.dayOfMonthPicklistValue)
            ? this.getTodayDateOfMonth()
            : undefined;
    }

    /*******************************************************************************
    * @description Retrieve Recurring Donation Day of Month picklist values
    */
    @wire(getPicklistValues, {fieldApiName: FIELD_DAY_OF_MONTH, recordTypeId: '$recurringDonationInfo.defaultRecordTypeId' })
    wiredPicklistValues({error, data}) {
       if(data) {
          this.dayOfMonthPicklistValue = data.values;
       }
       if(error) {
           this.handleError(error);
       }
    }

   /*******************************************************************************
   * @description Matches today's calender day with the RD Day of Month picklist value.
   *    If the day does not match any picklist value(the case of 31), return api value 'Last_Day'
   * @return String Today's day in Day of Month picklist api value
   */
    getTodayDateOfMonth() {
        let currentDay = new Date().getDate().toString();
       
        let convertedPicklist = this.dayOfMonthPicklistValue.find(value => {
                return value.value == currentDay;
            });

        return (convertedPicklist) 
            ? convertedPicklist.value 
            : this.lastDayPicklistValue;
    }

    /*******************************************************************************
    * @description Retrieve Recurring Donation Object info
    */
    @wire(getObjectInfo, {objectApiName: RECURRING_DONATION_OBJECT.objectApiName })
    wiredRDObjectInfo(response) {
        if (response.data) {
            this.recurringDonationInfo = response.data;
            this.setFields(this.recurringDonationInfo.fields);
            this.fieldInfos = this.buildFieldDescribes(
                this.recurringDonationInfo.fields,
                this.recurringDonationInfo.apiName);
                this.isFieldInfoReady = true;
        }

        if (response.error) {
            this.isFieldInfoReady = true;
            handleError(response.error);
        }
    }

    /*******************************************************************************
    * @description Method converts field describe info into objects that the
    * getRecord method can accept into its 'fields' parameter.
    */
    buildFieldDescribes(fields, objectApiName) {
        return Object.keys(fields).map((fieldApiName) => {
            return {
                fieldApiName: fieldApiName,
                objectApiName: objectApiName
            }
        });
    }

    /*******************************************************************************
    * @description Construct field describe info from the Recurring Donation SObject info
    */ 
    setFields(fieldInfos) {
        this.fields.name = this.extractFieldInfo(fieldInfos[FIELD_NAME.fieldApiName]);
        this.fields.account = this.extractFieldInfo(fieldInfos[FIELD_ACCOUNT.fieldApiName]);
        this.fields.contact = this.extractFieldInfo(fieldInfos[FIELD_CONTACT.fieldApiName]);
        this.fields.recurringType = this.extractFieldInfo(fieldInfos[FIELD_RECURRING_TYPE.fieldApiName]);
        this.fields.dateEstablished = this.extractFieldInfo(fieldInfos[FIELD_DATE_ESTABLISHED.fieldApiName]);
        this.fields.amount = this.extractFieldInfo(fieldInfos[FIELD_AMOUNT.fieldApiName]);
        this.fields.paymentMethod = this.extractFieldInfo(fieldInfos[FIELD_PAYMENT_METHOD.fieldApiName]);
        this.fields.period = this.extractFieldInfo(fieldInfos[FIELD_INSTALLMENT_PERIOD.fieldApiName]);
        this.fields.installmentFrequency = this.extractFieldInfo(fieldInfos[FIELD_INSTALLMENT_FREQUENCY.fieldApiName]);
        this.fields.dayOfMonth = this.extractFieldInfo(fieldInfos[FIELD_DAY_OF_MONTH.fieldApiName]);
        this.fields.startDate = this.extractFieldInfo(fieldInfos[FIELD_START_DATE.fieldApiName]);
        this.fields.campaign = this.extractFieldInfo(fieldInfos[FIELD_CAMPAIGN.fieldApiName]);
        this.fields.currency = {label: currencyFieldLabel, apiName: 'CurrencyIsoCode'};
        this.fields.plannedInstallments = this.extractFieldInfo(fieldInfos[FIELD_PLANNED_INSTALLMENTS.fieldApiName]);
    }

    /*******************************************************************************
    * @description Method converts field describe info into a object that is easily accessiable from the front end
    */
    extractFieldInfo(field) {
        return {
            apiName : field.apiName,
            label : field.label,
            inlineHelpText : field.inlineHelpText,
            dataType : field.dataType
        };
    }

    /*******************************************************************************
    * @description Retrieve Recurring Donation record value
    */ 
    @wire(getRecord, { recordId: '$recordId', fields: '$fieldInfos' })
    wiredRecurringDonationRecord(response) {
        if (response.data) {
            this.record = response.data;
            this.modifyEditHeader();
            this.isRecordReady = true;
        }

        if (response.error) {
            this.isRecordReady = true;
            handleError(response.error);
        }
    }

    /*******************************************************************************
    * @description Modify edit modal header
    */
    modifyEditHeader() {
        this.header = editHeaderLabel + ' ' + this.record.fields.Name.value;
    }

    /*******************************************************************************
    * @description Get org setting on init of the component 
    */ 
    connectedCallback() {
        if (this.recordId === undefined) {
            this.isNew = true;
            this.isRecordReady = true;
        }

        getSetting({parentId: this.parentId})
        .then(response => {
            this.isAutoNamingEnabled = response.isAutoNamingEnabled;
            this.isMultiCurrencyEnabled = response.isMultiCurrencyEnabled;
            this.handleParentIdType(response.parentSObjectType);
            this.isSettingReady = true;
            this.isLoading = false;
            this.lastDayPicklistValue = response.dayOfMonthLastDay;
        })
        .catch((error) => {
            this.isSettingReady = true;
            this.handleError(error);
        });
    }

    /*******************************************************************************
    * @description Determine the parentId Sobject Type
    */
    handleParentIdType(parentSObjType) {
        if (parentSObjType == null) {
            return;
        }

        if (parentSObjType === ACCOUNT_OBJECT.objectApiName) {
            this.accountId = this.parentId;
        } else if (parentSObjType === CONTACT_OBJECT.objectApiName) {
            this.contactId = this.parentId;
        }
    }

    /*******************************************************************************
    * @description Override the standard submit. Add any fields before the submittion
    */
    handleSubmit(event){
        this.isLoading = true;
        this.template.querySelector("[data-id='submitButton']").disabled = true;

        event.preventDefault();
        const fields = event.detail.fields;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    /*******************************************************************************
    * @description Handle lwc when errors occur
    */
    handleError(error) {
        this.errorMessage = this.constructErrorMessage(error);
        this.hasError = true;
        this.isLoading = false;

        this.template.querySelector("[data-id='submitButton']").disabled = false;

        this.template.querySelector(".slds-modal__header").scrollIntoView();
    }

    /*******************************************************************************
    * @description Fires an event to utilDedicatedListener with the cancel action
    */
    handleCancel() {
        fireEvent(this.pageRef, this.listenerEvent, { action: 'cancel', recordId : this.recordId });
    }

    /*******************************************************************************
    * @description Fires an event to utilDedicatedListener with the success action
    */
    handleSuccess(event) {
        this.showSuccessToast(event.detail.fields.Name.value);
        fireEvent(this.pageRef, this.listenerEvent, { action: 'success', recordId: event.detail.id});
    }

    /*******************************************************************************
    * @description Contruct error wrapper from the error event 
    *   error.body is the error from apex calls
    *   error.body.output.errors is for AuraHandledException messages
    *   error.body.message errors is the error from wired service
    *   error.detail.output.errors is the error from record-edit-forms
    */
   constructErrorMessage(error) {
        let header;
        let message;

        if (typeof error === 'string' || error instanceof String) {
            message = error;

        } else if (error.message) {
            message = error.message;

        } else if ((error.body && error.body.output)) {
            if (Array.isArray(error.body) &&
                !error.body.output.errors) {
                message = error.body.map(e => e.message).join(', ');

            } else if (typeof error.body.message === 'string' &&
                !error.body.output.errors) {
                message = error.body.message;

            } else if (error.body.output &&
                Array.isArray(error.body.output.errors)) {
                message = error.body.output.errors.map(e => e.message).join(', ');
            }

        } else if (error.detail && error.detail.output && Array.isArray(error.detail.output.errors)) {
            header = error.detail.message;
            message = error.detail.output.errors.map(e => e.message).join(', ');

        } else if (error.body && error.body.message) {
            message = error.body.message;
        }

        return {
            header: header || unknownErrorLabel,
            detail: message || unknownErrorLabel
        };
    }

    /*******************************************************************************
    * @description Fires a toast event to display success message
    */
    showSuccessToast(recordName) {
        let message = (this.recordId)
            ? updateSuccessMessage.replace("{0}", recordName)
            : insertSuccessMessage.replace("{0}", recordName);

        const event = new ShowToastEvent({
            title: message,
            variant: 'success',
        });
        this.dispatchEvent(event);
    }
}