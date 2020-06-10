import { LightningElement, api, track, wire } from 'lwc';
import { fireEvent } from 'c/pubsubNoPageRef';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { handleError } from 'c/utilTemplateBuilder'
import { isNull } from 'c/utilCommon';

import getSetting from '@salesforce/apex/RD2_entryFormController.getSetting';

import RECURRING_DONATION_OBJECT from '@salesforce/schema/npe03__Recurring_Donation__c';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import CONTACT_OBJECT from '@salesforce/schema/Contact';

import FIELD_ACCOUNT from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Organization__c';
import FIELD_CONTACT from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Contact__c';

export default class rd2EntryFormDonorSection extends LightningElement {

    @api recordId;
    @track isLoading = true;
    isNew = false;

    @track contactId;
    @track accountId;
    @track donorType;
    @track showContactInput = true;
    @track showAccountInput = true;

    @track fields = {};
    rdObjectInfo;

    /***
     * @description Get settings required to enable or disable fields and populate their values
     */
    connectedCallback() {
        if (isNull(this.recordId)) {
            this.isNew = true;
        }

        getSetting({ parentId: null })
            .then(response => {
                this.handleParentIdType(response.parentSObjectType);
            })
            .catch((error) => {
                handleError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /***
     * @description Determine the parentId Sobject Type
     */
    handleParentIdType(parentSObjType) {
        if (isNull(parentSObjType)) {
            return;
        }

        if (parentSObjType === ACCOUNT_OBJECT.objectApiName) {
            this.accountId = this.parentId;
        } else if (parentSObjType === CONTACT_OBJECT.objectApiName) {
            this.contactId = this.parentId;
        }
    }

    /**
     * @description Retrieve Recurring Donation SObject info
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
            this.isLoading = false;

        } else if (response.error) {
            this.isLoading = false;
            handleError(response.error);
        }
    }

    /**
     *
     */
    handleDonorTypeChange(event) {
        this.donorType = event.target.value;
        if (this.donorType === 'Organization') {
            this.showAccountInput = true;
            this.showContactInput = true;
        } else {
            this.showAccountInput = false;
            this.showContactInput = true;
        }
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
        this.fields.account = this.extractFieldInfo(fieldInfos[FIELD_ACCOUNT.fieldApiName]);
        this.fields.contact = this.extractFieldInfo(fieldInfos[FIELD_CONTACT.fieldApiName]);
    }

    /**
     * @description Converts field describe info into a object that is easily accessible from the front end
     */
    extractFieldInfo(field) {
        return {
            apiName: field.apiName,
            label: field.label,
            inlineHelpText: field.inlineHelpText,
            dataType: field.dataType
        };
    }

    /**
     * Resets the Donor fields as they were upon the initial load
     */
    @api
    reset() {
        this.template.querySelectorAll('lightning-input-field')
            .forEach(field => {
                field.reset();
            });
    }

    /**
     * Populates the Donor form fields based on provided data
     */
    @api
    load(data) {
        //TODO, what is the format of "data"?
    }

    /**
     * Checks if values specified on fields are valid
     * @return Boolean
     */
    @api
    isValid() {
        const donorFields = this.template.querySelectorAll('lightning-input-field');

        for (const field of donorFields) {
            if (!field.isValid()) {
                return false;
            }
        }
        return true;
    }

    /**
     * @description Returns fields displayed on the Recurring Donation Donor section
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

}