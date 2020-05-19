import { LightningElement, api, track, wire } from 'lwc';
import { fireEvent } from 'c/pubsubNoPageRef';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { getNestedProperty } from 'c/utilCommon';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord} from 'lightning/uiRecordApi';

import RECURRING_DONATION_INFO from '@salesforce/schema/npe03__Recurring_Donation__c';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import CONTACT_OBJECT from '@salesforce/schema/Contact';

import FIELD_NAME from '@salesforce/schema/npe03__Recurring_Donation__c.Name';
import FIELD_ACCOUNT from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Organization__c';
import FIELD_CONTACT from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Contact__c';
import FIELD_DATE_ESTABLISHED from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Date_Established__c';
import FIELD_STATUS from '@salesforce/schema/npe03__Recurring_Donation__c.Status__c';
import FIELD_RECURRING_TYPE from '@salesforce/schema/npe03__Recurring_Donation__c.RecurringType__c';
import FIELD_INSTALLMENT from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installments__c';
import FIELD_AMOUNT from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Amount__c';
import FIELD_PAYMENT_METHOD from '@salesforce/schema/npe03__Recurring_Donation__c.PaymentMethod__c';
import FIELD_INSTALLMENT_PERIOD from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installment_Period__c';
import FIELD_INSTALLMENT_FREQUENCY from '@salesforce/schema/npe03__Recurring_Donation__c.InstallmentFrequency__c';
import FIELD_DAY_OF_MONTH from '@salesforce/schema/npe03__Recurring_Donation__c.Day_of_Month__c';
import FIELD_START_DATE from '@salesforce/schema/npe03__Recurring_Donation__c.StartDate__c';
import FIELD_CAMPAIGN from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Recurring_Donation_Campaign__c';

import cancelButtonLabel from '@salesforce/label/c.stgBtnCancel';
import saveButtonLabel from '@salesforce/label/c.stgBtnSave';
import currencyFieldLabel from '@salesforce/label/c.RD2_EntryFormFieldLabelCurreny';
import donationSectionHeader from '@salesforce/label/c.RD2_EntryFormDonationSectionHeader';
import donorSectionHeader from '@salesforce/label/c.RD2_EntryFormDonorSectionHeader';
import otherSectionHeader from '@salesforce/label/c.RD2_EntryFormOtherSectionHeader';
import insertSuccessMessage from '@salesforce/label/c.RD2_EntryFormInsertSuccessMessage';
import updateSuccessMessage from '@salesforce/label/c.RD2_EntryFormUpdateSuccessMessage';

import getSetting from '@salesforce/apex/RD2_entryFormController.getSetting';

export default class rdEntryForm extends LightningElement {

    customLabels = Object.freeze({
        cancelButtonLabel,
        saveButtonLabel,
        donationSectionHeader,
        donorSectionHeader,
        otherSectionHeader
    });

    @track fields = {};

    recurringDonationInfo;
    fieldInfos
    @track record;

    @api parentId;
    @api recordId;

    @track isAutoNamingEnabled;
    @track isMultiCurrencyEnabled;

    @track header;

    @track contactId;
    @track accountId;

    @track isInitialize = false;
    @track isLoading = true;
    @track hasError = false;
    @track errorMessage = {};

    listenerEvent = 'rdEntryFormEvent';

    /*******************************************************************************
    * @description Dynamic render edit form CSS to show/hide the edit form 
    */
    get cssEditForm() {
        return (this.isLoading)
            ? 'slds-hide'
            : '';
    }

    /*******************************************************************************
    * @description Get Recurring Donation SObject API name 
    */
    get recurringDonationName() {
        return getNestedProperty(RECURRING_DONATION_INFO, 'objectApiName');
    }


    /*******************************************************************************
    * @description Retrieve Recurring Donation Object info
    */
    @wire(getObjectInfo, {objectApiName: '$recurringDonationName' })
    wiredRecurringDonationBatchInfo(response) {
        if (response.data) {
            this.recurringDonationInfo = response.data;
            this.buildDisplayedFields(this.recurringDonationInfo.fields);
            this.fieldInfos = this.buildFieldDescribesForWiredMethod(
                this.recurringDonationInfo.fields,
                this.recurringDonationInfo.apiName);

            this.isInitialize = true;
            this.isLoading = false;

        }
    }

    /*******************************************************************************
    * @description Method converts field describe info into objects that the
    * getRecord method can accept into its 'fields' parameter.
    */
    buildFieldDescribesForWiredMethod(fields, objectApiName) {
        return Object.keys(fields).map((fieldApiName) => {
            return {
                fieldApiName: fieldApiName,
                objectApiName: objectApiName
            }
        });
    }

    /*******************************************************************************
    * @description Contrcut any needed field info from the Sobject Info
    */ 
    buildDisplayedFields(fieldInfos) {
        this.fields.name = this.extractFieldInfo(fieldInfos[FIELD_NAME.fieldApiName]);
        this.fields.account = this.extractFieldInfo(fieldInfos[FIELD_ACCOUNT.fieldApiName]);
        this.fields.contact = this.extractFieldInfo(fieldInfos[FIELD_CONTACT.fieldApiName]);
        this.fields.recurringType = this.extractFieldInfo(fieldInfos[FIELD_RECURRING_TYPE.fieldApiName]);
        this.fields.dateEstablished = this.extractFieldInfo(fieldInfos[FIELD_DATE_ESTABLISHED.fieldApiName]);
        this.fields.status = this.extractFieldInfo(fieldInfos[FIELD_STATUS.fieldApiName]);
        this.fields.amount = this.extractFieldInfo(fieldInfos[FIELD_AMOUNT.fieldApiName]);
        this.fields.paymentMethod = this.extractFieldInfo(fieldInfos[FIELD_PAYMENT_METHOD.fieldApiName]);
        this.fields.period = this.extractFieldInfo(fieldInfos[FIELD_INSTALLMENT_PERIOD.fieldApiName]);
        this.fields.installmentFrequency = this.extractFieldInfo(fieldInfos[FIELD_INSTALLMENT_FREQUENCY.fieldApiName]);
        this.fields.dayOfMonth = this.extractFieldInfo(fieldInfos[FIELD_DAY_OF_MONTH.fieldApiName]);
        this.fields.startDate = this.extractFieldInfo(fieldInfos[FIELD_START_DATE.fieldApiName]);
        this.fields.campaign = this.extractFieldInfo(fieldInfos[FIELD_CAMPAIGN.fieldApiName]);
        this.fields.currency = {label: currencyFieldLabel, apiName: 'CurrencyIsoCode'};
        this.fields.installment = this.extractFieldInfo(fieldInfos[FIELD_INSTALLMENT.fieldApiName]);
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
        }
    }

    async connectedCallback() {
        getSetting({ recordId: this.recordId, parentId: this.parentId}).then(response => {
            this.isAutoNamingEnabled = response.isAutoNamingEnabled;
            this.isMultiCurrencyEnabled = response.isMultiCurrencyEnabled;
            this.header = response.header;
            this.handleParentIdType(response.parentSObjectType);
        });
    }

    /*******************************************************************************
    * @description Determine the parentId Sobject Type
    */
    handleParentIdType(parentSObjecType) {
        if (parentSObjecType == null) {
            return;
        }

        if (parentSObjecType === ACCOUNT_OBJECT.objectApiName) {
            this.account = this.parentId;
        } else if (parentSObjecType === CONTACT_OBJECT.objectApiName) {
            this.contactId = this.parentId;
        }
    }

    /*******************************************************************************
    * @description Override the standard submit. Add any fields before the submittion
    */
    handleSubmit(event){
        this.isLoading = true;
        event.preventDefault();
        const fields = event.detail.fields;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    /*******************************************************************************
    * @description Override standard error handling with custom error display
    */
    handleError(event) {
        this.isLoading = false
        this.hasError = true;
        this.errorMessage = event.detail;

    }

    /*******************************************************************************
    * @description Fires an event to utilDedicatedListener with the cancel action
    */
    handleCancel() {
        fireEvent(this.pageRef, this.listenerEvent, { action: 'cancel' });
    }

    /*******************************************************************************
    * @description Fires an event to utilDedicatedListener with the success action
    */
    handleSuccess(event) {
        this.showToast(event.detail.fields.Name.value);
        fireEvent(this.pageRef, this.listenerEvent, { action: 'success', recordId: event.detail.id});
    }

    /*******************************************************************************
    * @description Fires a toast event to display success message
    */
    showToast(recordName) {
        let succeedMessage = (this.recordId)
            ? updateSuccessMessage.replace("{0}", recordName)
            : insertSuccessMessage.replace("{0}", recordName);

        const event = new ShowToastEvent({
            title: succeedMessage,
            variant: 'success',
        });
        this.dispatchEvent(event);
    }
}