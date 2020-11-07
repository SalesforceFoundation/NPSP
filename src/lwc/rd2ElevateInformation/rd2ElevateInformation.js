import { LightningElement, api, wire, track } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import { constructErrorMessage, buildFieldDescribes, extractFieldInfo } from 'c/utilCommon';

import RECURRING_DONATION_OBJECT from '@salesforce/schema/npe03__Recurring_Donation__c';
import FIELD_NAME from '@salesforce/schema/npe03__Recurring_Donation__c.Name';
import FIELD_COMMITMENT_ID from '@salesforce/schema/npe03__Recurring_Donation__c.CommitmentId__c';

import header from '@salesforce/label/c.RD2_ElevateInformationHeader';
import statusLabel from '@salesforce/label/c.RD2_ElevateInformationStatusLabel';
import insufficientPermissions from '@salesforce/label/c.commonInsufficientPermissions';

const FIELDS = [
    FIELD_NAME,
    FIELD_COMMITMENT_ID
]

export default class rd2ElevateInformation extends LightningElement {

    labels = Object.freeze({
        header,
        statusLabel,
        insufficientPermissions
    });

    @api recordId;
    @track rdRecord;
    @track fields = {};

    @track isLoading = true;
    @track permissions = {
        hasAccess: false,
        isBlocked: false,
        blockedReason: ''
    };
    @track error = {};


    /***
     * @description Initializes the component
     */
    connectedCallback() {
    }

    /***
    * @description Retrieve Recurring Donation Object and fields labels and help text
    */
    @wire(getObjectInfo, { objectApiName: RECURRING_DONATION_OBJECT.objectApiName })
    wiredRecurringDonationObjectInfo(response) {
        if (response.data) {
            let rdObjectInfo = response.data;

            this.setFields(rdObjectInfo.fields);
            this.fieldInfos = buildFieldDescribes(
                rdObjectInfo.fields,
                rdObjectInfo.apiName
            );
        }

        if (response.error) {
            this.handleError(response.error);
        }
    }

    /***
     * @description Track specified fields so when the Recurring Donation record is updated,
     * this method is called to force refresh of the data and the component.
     */
    @wire(getRecord, {
        recordId: '$recordId',
        fields: FIELDS
    })
    wiredRecurringDonation(response) {
        if (response.data) {
            this.rdRecord = response.data;
            this.isLoading = false;

        } else if (response.error) {
            this.handleError(response.error);
        }
    }

    /**
     * @description Construct field describe info from the Recurring Donation SObject info
     */
    setFields(fieldInfos) {
        this.fields.name = extractFieldInfo(fieldInfos, FIELD_NAME.fieldApiName);
        this.fields.commitmentId = extractFieldInfo(fieldInfos, FIELD_COMMITMENT_ID.fieldApiName);
    }

    /**
    * @description Clears the error notification
    */
    clearError() {
        this.error = {};
    }

    /***
    * @description Handle error
    * @param error: Error Event
    */
    handleError(error) {
        this.error = constructErrorMessage(error);

        const errorDetail = this.error.detail;

        const isApexClassDisabled = errorDetail && errorDetail.includes("RD2_EntryFormController");
        if (isApexClassDisabled) {
            this.permissions.hasAccess = false;
        }

        if (errorDetail && this.permissions.hasAccess === false) {
            this.error.header = this.labels.insufficientPermissions;
        }

        this.isLoading = false;
    }
}