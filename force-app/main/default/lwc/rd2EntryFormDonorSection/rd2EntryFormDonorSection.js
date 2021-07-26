import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { isNull } from 'c/utilCommon';

import getRecurringData from '@salesforce/apex/RD2_EntryFormController.getRecurringData';

import RECURRING_DONATION_OBJECT from '@salesforce/schema/npe03__Recurring_Donation__c';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import CONTACT_OBJECT from '@salesforce/schema/Contact';

import FIELD_DATE_ESTABLISHED from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Date_Established__c';
import FIELD_ACCOUNT from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Organization__c';
import FIELD_CONTACT from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Contact__c';

import donorTypeLabel from '@salesforce/label/c.RD2_EntryFormDonorTypeLabel';
import donorTypeHelpText from '@salesforce/label/c.RD2_EntryFormDonorTypeHelpText';

export default class rd2EntryFormDonorSection extends LightningElement {

    DEFAULT_DONOR_TYPE = 'Contact';

    customLabels = Object.freeze({
        donorTypeLabel,
        donorTypeHelpText
    });

    // These are exposed to the parent component
    @api parentId;
    @api recordId;
    @api parentSObjectType;

    @track isLoading = true;
    isRecordReady = false;

    @track contactId;
    @track accountId;

    @track donorType;
    @track accountRequired = true;
    @track contactRequired = true;

    @track fields = {};
    rdObjectInfo;
    accountLabel;
    contactLabel;

    /**
     * @description Init function
     */
    connectedCallback() {
        this.init();
    }

    /**
    * @description If editing an existing record retrieve the Donor Type from the record so it can default the custom
    * picklist field accordingly.
    */
    init() {
        if (!isNull(this.recordId)) {
            getRecurringData({ recordId: this.recordId })
                .then(response => {
                    this.changeDonorType(response.DonorType);
                })
                .catch((error) => {
                    this.dispatchEvent(new CustomEvent('errorevent', { detail: error }));
                });
        } else {
            this.changeDonorType(this.DEFAULT_DONOR_TYPE);
            this.handleParentIdType(this.parentSObjectType);
        }
    }

    /**
     * @description Set isLoading to false only after all wired actions have fully completed
     * @returns True (All Done) or False (Still Loading)
     */
    isEverythingLoaded() {
        return (this.isRecordReady === true && this.rdObjectInfo !== null);
    }

    /**
     * @description Determine the parentId Sobject Type if creating a new record from an Account or Contact
     */
    handleParentIdType(parentSObjType) {
        if (isNull(parentSObjType)) {
            return;
        }

        if (parentSObjType === ACCOUNT_OBJECT.objectApiName) {
            this.accountId = this.parentId;
            this.changeDonorType('Account');
            this.dispatchChangeEvent('accountchange', this.accountId);
        } else if (parentSObjType === CONTACT_OBJECT.objectApiName) {
            this.contactId = this.parentId;
            this.changeDonorType('Contact');
            this.dispatchChangeEvent('contactchange', this.contactId);
        }
    }

    /**
     * @description Retrieve Recurring Donation SObject info and configure fields for the UI
     */
    @wire(getObjectInfo, { objectApiName: RECURRING_DONATION_OBJECT.objectApiName })
    wiredRecurringDonationObjectInfo(response) {
        if (response.data) {
            this.rdObjectInfo = response.data;
            this.setFields(this.rdObjectInfo.fields);
            this.buildFieldDescribes(
                this.rdObjectInfo.fields,
                this.rdObjectInfo.apiName
            );
            this.isLoading = !this.isEverythingLoaded();

        } else if (response.error) {
            this.dispatchEvent(new CustomEvent('errorevent', { detail: { value: response.error } }));
        }
    }

    /**
     * @description Set the Account Object label for the Donor Type picklist
     */
    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    wiredAccountObjectInfo(response) {
        if (response.data) {
            this.accountLabel = response.data.label;
        }
    }

    /**
     * @description Set the Contact Object label for the Donor Type picklist
     */
    @wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
    wiredContactObjectInfo(response) {
        if (response.data) {
            this.contactLabel = response.data.label;
        }
    }

    /**
     * @description Donor Type picklist options
     */
    get donorTypeOptions() {
        return [
            { label: this.accountLabel, value: 'Account' },
            { label: this.contactLabel, value: 'Contact' },
        ];
    }

    /**
     * @description Returns true if the DonorType is set to Contact. Used to render the UI structure properly
     * @returns {boolean}
     */
    get isContactDonor() {
        return (this.donorType === 'Contact');
    }

    /**
     * @description Returns true if the DonorType is set to Account. Used to render the UI structure properly
     * @returns {boolean}
     */
    get isAccountDonor() {
        return (this.donorType === 'Account');
    }

    /**
     * @description Handles the page updates when the Donor Type picklist is updated
     */
    handleDonorTypeChange(event) {
        this.changeDonorType(event.target.value);
        this.updateDonorFields(this.donorType);
    }

    changeDonorType(donorType) {
        this.donorType = donorType;
        this.dispatchDonorTypeChange();
    }

    /**
     * @description Dispatches an event to the encompassing parent component 
     * when the contact value changes either due to the Donor Type change or
     * the contact lookup value change itself.
     */
    handleContactChange(event) {
        this.dispatchChangeEvent('contactchange', event.target.value);
    }

    handleAccountChange(event) {
        this.dispatchChangeEvent('accountchange', event.target.value);
    }

    dispatchDonorTypeChange() {
        this.dispatchChangeEvent('donortypechange', this.donorType);
    }

    dispatchChangeEvent(eventName, value) {
        this.dispatchEvent(new CustomEvent(
            eventName,
            { detail: value }
        ))
    }

    /**
     * @description Update the properties to configure the Donor Type fields visibility and requirement settings
     * based on the value of the DonorType picklist.
     */
    updateDonorFields() {
        if (this.donorType === 'Account') {
            this.accountRequired = true;
            this.contactRequired = false;
        } else {
            this.accountRequired = false;
            this.contactRequired = true;
        }
        this.dispatchChangeEvent('contactchange', null);
    }

    /**
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

    /**
     * @description Construct field describe info from the Recurring Donation SObject info
     */
    setFields(fieldInfos) {
        this.fields.dateEstablished = this.extractFieldInfo(fieldInfos, FIELD_DATE_ESTABLISHED.fieldApiName);
        this.fields.account = this.extractFieldInfo(fieldInfos, FIELD_ACCOUNT.fieldApiName);
        this.fields.contact = this.extractFieldInfo(fieldInfos, FIELD_CONTACT.fieldApiName);
        this.isRecordReady = true;
        this.isLoading = !this.isEverythingLoaded();
    }

    /**
     * @description Converts field describe info into a object that is easily accessible from the front end
     * Ignore errors to allow the UI to simply not render the layout-item if the field info doesn't exist
     * (i.e, the field isn't accessible).
     */
    extractFieldInfo(fieldInfos, fldApiName) {
        try {
            const field = fieldInfos[fldApiName];
            return {
                apiName: field.apiName,
                label: field.label,
                inlineHelpText: field.inlineHelpText,
                dataType: field.dataType
            };
        } catch (error) { }
    }

    /**
     * @description Checks if values specified on fields are valid
     * @return Boolean
     */
    @api
    isValid() {
        let isValid = true;
        this.template.querySelectorAll('lightning-input-field')
            .forEach(field => {
                if (!field.reportValidity()) {
                    isValid = false;
                }
            });
        return isValid;
    }

    /**
     * @description Returns fields displayed on the child component to the parent form
     * @return Object containing field API names and their values
     */
    @api
    returnValues() {
        let data = {};

        this.template.querySelectorAll('lightning-input-field')
            .forEach(field => {
                data[field.fieldName] = field.value;
            });

        return data;
    }

    /**
    * @description run init function 
    */
    @api
    forceRefresh() {
       this.init();
    }

    /**
    * @description reset all lighning-input-field value 
    */
    @api
    resetValues() {
    this.template.querySelectorAll('lightning-input-field')
        .forEach(field => {
            if (field.value) {
                field.reset();
            }
        });
    }
}