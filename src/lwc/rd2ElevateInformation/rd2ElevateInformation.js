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
import flsErrorHeader from '@salesforce/label/c.geErrorFLSHeader';
import flsErrorDetail from '@salesforce/label/c.RD2_EntryFormMissingPermissions';
import insufficientPermissions from '@salesforce/label/c.commonInsufficientPermissions';
import contactSystemAdmin from '@salesforce/label/c.commonContactSystemAdminMessage';
import elevateDisabledHeader from '@salesforce/label/c.RD2_ElevateDisabledHeader';
import elevateDisabledMessage from '@salesforce/label/c.RD2_ElevateDisabledMessage';
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
        flsErrorHeader,
        flsErrorDetail,
        insufficientPermissions,
        contactSystemAdmin,
        elevateDisabledHeader,
        elevateDisabledMessage,
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

    @track isLoading = true;
    @track isElevateCustomer;
    @track isElevateRecord = false;
    @track permissions = {
        hasAccess: null,
        alert: ''
    };
    @track error = {};


    /***
     * @description Initializes the component
     */
    connectedCallback() {
        getData({ recordId: this.recordId })
            .then(response => {
                this.isElevateCustomer = response.isElevateCustomer;
                this.permissions.alert = response.alert;

                this.permissions.hasAccess = this.isElevateCustomer === true
                    && response.hasFieldPermissions === true
                    && isNull(this.permissions.alert);

                if (this.isElevateCustomer === true) {
                    if (!isNull(this.permissions.alert)) {
                        this.handleError({
                            header: this.labels.insufficientPermissions,
                            detail: this.permissions.alert
                        });

                    } else if (response.hasFieldPermissions === false) {
                        this.handleError({
                            header: this.labels.flsErrorHeader,
                            detail: this.labels.flsErrorDetail
                        });

                    } else if (!isNull(response.errorMessage)) {
                        this.status.message = response.errorMessage;
                        this.status.value = 'error';
                        this.status.icon = 'utility:error';
                        this.status.assistiveText = this.labels.textError;
                    }
                }
            })
            .catch((error) => {
                this.handleError(error);
            })
            .finally(() => {
                console.log('******getData*****');
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

        if (response.error && this.hasAccess()) {
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

        if (response.error && this.hasAccess()) {
            this.handleError(response.error);
        }
    }

    hasAccess() {
        return this.isTrue(this.permissions.isElevateCustomer)
            && this.isTrue(this.permissions.hasAccess);
    }

    /**
     * @description Checks if the form is still loading all data required to be displayed
     */
    checkLoading() {
        if (this.isNot(this.isElevateCustomer) || this.isNot(this.permissions.hasAccess)) {
            this.isLoading = false;

        } else {
            this.isLoading = !this.isSet(this.isElevateCustomer)
                || !this.isSet(this.rdRecord)
                || !this.isSet(this.fields.name);
        }

        this.isElevateRecord = this.isSetField('CommitmentId__c');
        console.log('******isloading: ' + this.isLoading);
    }

    isTrue(value) {
        return this.isSet(value) && value === true;
    }
    isNot(value) {
        return this.isSet(value) && value === false;
    }
    isSet(value) {
        return !isUndefined(value) && !isNull(value);
    }
    isSetField(fieldName) {
        return this.rdRecord
            && this.rdRecord.fields
            && !isUndefined(this.rdRecord.fields[fieldName])
            && !isNull(this.rdRecord.fields[fieldName].value);
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
        this.error = (error && error.detail)
            ? error
            : constructErrorMessage(error);

        if (this.error.detail && this.error.detail.includes("RD2_ElevateInformation_CTRL")) {
            this.permissions.hasAccess = false;
            this.error.header = this.labels.insufficientPermissions;
        }

        this.isLoading = false;
    }
}