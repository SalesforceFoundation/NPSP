import { LightningElement, api, wire, track } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import { constructErrorMessage, buildFieldDescribes, extractFieldInfo, isNull, isUndefined } from 'c/utilCommon';

import RECURRING_DONATION_OBJECT from '@salesforce/schema/npe03__Recurring_Donation__c';
import FIELD_NAME from '@salesforce/schema/npe03__Recurring_Donation__c.Name';
import FIELD_COMMITMENT_ID from '@salesforce/schema/npe03__Recurring_Donation__c.CommitmentId__c';
import FIELD_STATUS from '@salesforce/schema/npe03__Recurring_Donation__c.Status__c';
import FIELD_STATUS_REASON from '@salesforce/schema/npe03__Recurring_Donation__c.ClosedReason__c';

import header from '@salesforce/label/c.RD2_ElevateInformationHeader';
import loadingMessage from '@salesforce/label/c.labelMessageLoading';
import statusSuccess from '@salesforce/label/c.RD2_ElevateInformationStatusSuccess';
import statusElevatePending from '@salesforce/label/c.RD2_ElevatePendingStatus';
import textSuccess from '@salesforce/label/c.commonAssistiveSuccess';
import textError from '@salesforce/label/c.AssistiveTextError';
import textWarning from '@salesforce/label/c.AssistiveTextWarning';
import textNewWindow from '@salesforce/label/c.AssistiveTextNewWindow';
import insufficientPermissions from '@salesforce/label/c.commonInsufficientPermissions';
import viewErrorLogLabel from '@salesforce/label/c.commonViewErrorLog';


import getData from '@salesforce/apex/RD2_ElevateInformation_CTRL.getData';

const FIELDS = [
    FIELD_NAME,
    FIELD_COMMITMENT_ID,
    FIELD_STATUS,
    FIELD_STATUS_REASON
]

export default class rd2ElevateInformation extends LightningElement {

    labels = Object.freeze({
        header,
        loadingMessage,
        statusSuccess,
        statusElevatePending,
        textSuccess,
        textError,
        textWarning,
        textNewWindow,
        insufficientPermissions,
        viewErrorLogLabel
    });

    @api recordId;
    @track rdRecord;
    @track fields = {};
    @track status = {
        message: this.labels.statusSuccess,
        isProgress: false,
        value: 'success',
        icon: 'utility:success',
        assistiveText: this.labels.textSuccess
    };

    @track isElevateCustomer;
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
        getData({ recordId: this.recordId })
            .then(response => {
                this.isElevateCustomer = response.isElevateCustomer;

                if (!isNull(response.errorMessage)) {
                    this.status.message = response.errorMessage;
                    this.status.value = 'error';
                    this.status.icon = 'utility:error';
                    this.status.assistiveText = this.labels.textError;
                }
            })
            .catch((error) => {
                this.handleError(error);
            })
            .finally(() => {
                this.checkLoading();
            });
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

            this.checkLoading();
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

            if (this.rdRecord && this.rdRecord.fields && this.rdRecord.fields.ClosedReason__c) {
                if (this.rdRecord.fields.ClosedReason__c.value === this.labels.statusElevatePending) {
                    this.status.isProgress = true;
                    this.status.message = this.labels.statusElevatePending;
                }
            }

            this.checkLoading();
        }
        
        if (response.error) {
            this.handleError(response.error);
        }
    }

    /**
     * @description Checks if the form is still loading all data required to be displayed
     */
    checkLoading() {
        this.isLoading = isUndefined(this.isElevateCustomer)
            || isNull(this.isElevateCustomer)
            || isUndefined(this.rdRecord)
            || isNull(this.rdRecord)
            || isUndefined(this.fields.name);
    }

    /**
     * @description Construct field describe info from the Recurring Donation SObject info
     */
    setFields(fieldInfos) {
        this.fields.name = extractFieldInfo(fieldInfos, FIELD_NAME.fieldApiName);
        this.fields.commitmentId = extractFieldInfo(fieldInfos, FIELD_COMMITMENT_ID.fieldApiName);
    }

    /**
     * @description Displays error log
     */
    navigateToErrorLog() {

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

        const isApexClassDisabled = errorDetail && errorDetail.includes("RD2_ElevateInformation_CTRL");
        if (isApexClassDisabled) {
            this.permissions.hasAccess = false;
        }

        if (errorDetail && this.permissions.hasAccess === false) {
            this.error.header = this.labels.insufficientPermissions;
        }

        this.isLoading = false;
    }
}