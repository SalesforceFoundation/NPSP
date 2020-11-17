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
import statusElevateCancelInProgress from '@salesforce/label/c.RD2_ElevateCancelInProgress';
import textSuccess from '@salesforce/label/c.commonAssistiveSuccess';
import textError from '@salesforce/label/c.AssistiveTextError';
import textWarning from '@salesforce/label/c.AssistiveTextWarning';
import textProgress from '@salesforce/label/c.ProgressMarkerAssistiveTextProgress';
import textNewWindow from '@salesforce/label/c.AssistiveTextNewWindow';
import flsErrorHeader from '@salesforce/label/c.geErrorFLSHeader';
import flsErrorDetail from '@salesforce/label/c.RD2_EntryFormMissingPermissions';
import insufficientPermissions from '@salesforce/label/c.commonInsufficientPermissions';
import contactSystemAdmin from '@salesforce/label/c.commonContactSystemAdminMessage';
import elevateDisabledHeader from '@salesforce/label/c.RD2_ElevateDisabledHeader';
import elevateDisabledMessage from '@salesforce/label/c.RD2_ElevateDisabledMessage';
import elevateRecordCreateFailed from '@salesforce/label/c.RD2_ElevateRecordCreateFailed';
import commonUnknownError from '@salesforce/label/c.commonUnknownError';
import viewErrorLogLabel from '@salesforce/label/c.commonViewErrorLog';

import getData from '@salesforce/apex/RD2_ElevateInformation_CTRL.getData';

const FIELDS = [
    FIELD_NAME,
    FIELD_COMMITMENT_ID,
    FIELD_STATUS,
    FIELD_STATUS_REASON
];
const TEMP_PREFIX = '_PENDING_';
const STATUS_SUCCESS = 'success';

export default class rd2ElevateInformation extends LightningElement {

    labels = Object.freeze({
        header,
        loadingMessage,
        statusSuccess,
        statusElevatePending,
        statusElevateCancelInProgress,
        textSuccess,
        textError,
        textWarning,
        textProgress,
        textNewWindow,
        flsErrorHeader,
        flsErrorDetail,
        insufficientPermissions,
        contactSystemAdmin,
        elevateDisabledHeader,
        elevateDisabledMessage,
        elevateRecordCreateFailed,
        commonUnknownError,
        viewErrorLogLabel
    });

    @api recordId;
    @track rdRecord;
    @track fields = {};
    @track status = {
        message: this.labels.statusSuccess,
        isProgress: false,
        value: STATUS_SUCCESS,
        icon: 'utility:success',
        assistiveText: this.labels.textSuccess
    };

    @track isLoading = true;
    @track isElevateCustomer;
    @track isElevateRecord = false;
    @track isElevateConnected = false;
    @track permissions = {
        hasAccess: null,
        alert: ''
    };
    @track error = {};


    /***
     * @description Initializes the component with data
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
                            detail: this.permissions.alert
                        });

                    } else if (response.hasFieldPermissions === false) {
                        this.handleError({
                            header: this.labels.flsErrorHeader,
                            detail: this.labels.flsErrorDetail
                        });

                    } else if (!isNull(response.errorMessage)) {
                        this.setErrorStatus(response.errorMessage);
                    }
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
    * @description Retrieves Recurring Donation Object and fields labels/help text
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
     * @description Tracks specified fields so when the Recurring Donation record is updated,
     * this method is called to force refresh of the data and the component.
     */
    @wire(getRecord, {
        recordId: '$recordId',
        fields: FIELDS
    })
    wiredRecurringDonation(response) {
        if (response.data) {
            this.rdRecord = response.data;

            if (this.getValue(FIELD_STATUS_REASON.fieldApiName) === this.labels.statusElevatePending) {
                this.status.isProgress = true;
                this.status.message = this.labels.statusElevateCancelInProgress;
            }

            this.checkLoading();
        }

        if (response.error && this.hasAccess()) {
            this.handleError(response.error);
        }
    }

    /***
     * @description Checks if record detail page or user has access to the Elevate Information data
     */
    hasAccess() {
        return this.isTrue(this.permissions.isElevateCustomer)
            && this.isTrue(this.permissions.hasAccess);
    }

    /**
     * @description Checks if the form still has outstanding data to load
     */
    checkLoading() {
        if (this.isNot(this.isElevateCustomer) || this.isNot(this.permissions.hasAccess)) {
            this.isLoading = false;

        } else {
            this.isLoading = !this.isSet(this.isElevateCustomer)
                || !this.isSet(this.rdRecord)
                || !this.isSet(this.fields.name);
        }

        this.checkElevateStatus();
    }

    /**
     * @description Determines if the Recurring Donation has commitment Id and
     * if such Id is indeed created in Elevate.
     */
    checkElevateStatus() {
        const commitmentId = this.getValue(FIELD_COMMITMENT_ID.fieldApiName);

        this.isElevateRecord = !isNull(commitmentId);
        this.isElevateConnected = this.isElevateRecord && !commitmentId.startsWith(TEMP_PREFIX);

        if (this.isElevateCustomer === true
            && this.isElevateRecord
            && !this.isElevateConnected
        ) {
            this.handleError({
                detail: this.labels.elevateRecordCreateFailed
            });

            if (this.status.value === STATUS_SUCCESS) {
                this.setErrorStatus(this.labels.commonUnknownError);
            }
        }
    }

    /**
     * @description Sets status and status message to error state
     */
    setErrorStatus(errorMessage) {
        this.status.message = errorMessage;
        this.status.value = 'error';
        this.status.icon = 'utility:error';
        this.status.assistiveText = this.labels.textError;
    }

    /**
     * @description Determines if the Boolean variable is defined and true
     */
    isTrue(value) {
        return this.isSet(value) && value === true;
    }

    /**
     * @description Determines if the Boolean variable is defined and false
     */
    isNot(value) {
        return this.isSet(value) && value === false;
    }

    /**
     * @description Determines if the variable is defined and has a value
     */
    isSet(value) {
        return !isUndefined(value) && !isNull(value);
    }

    /**
     * @description Returns the Recurring Donation field value if the field is set and populated
     */
    getValue(fieldName) {
        return this.hasValue(fieldName)
            ? this.rdRecord.fields[fieldName].value
            : null;
    }

    /**
     * @description Determines if the Recurring Donation record is retrieved and
     * its fields defined and populated
     */
    hasValue(fieldName) {
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
    * @description Handles error construction and its display
    * @param error: Error Event
    */
    handleError(error) {
        this.error = (error && error.detail)
            ? error
            : constructErrorMessage(error);

        if (this.error.detail && this.error.detail.includes('RD2_ElevateInformation_CTRL')) {
            this.permissions.hasAccess = false;
            this.error.header = this.labels.insufficientPermissions;
            this.isLoading = false;
        }
    }


    /***
    * @description data-qa-locator values for elements on the component
    */
    get qaLocatorHeader() {
        return `text ${this.labels.header}`;
    }

    get qaLocatorError() {
        return `error Notification`;
    }

    get qaLocatorSpinner() {
        return `spinner ${this.labels.loadingMessage}`;
    }

    get qaLocatorNoAccessIllustration() {
        return `illustration NoAccess`;
    }

    get qaLocatorNoDataIllustration() {
        return `div illustration NoData`;
    }

    get qaLocatorNoDataMessage() {
        return `text NoData Message`;
    }

    get qaLocatorProgressRing() {
        return `${this.labels.textProgress} 75%`;
    }

    get qaLocatorStatusIcon() {
        return `icon Status ${this.status.value}`;
    }

    get qaLocatorStatusMessage() {
        return `text Status Message`;
    }

    get qaLocatorCommitmentId() {
        return `text ${this.fields.commitmentId.label}`;
    }

    get qaLocatorNewWindow() {
        return `link ${this.labels.textNewWindow}`;
    }

    get qaLocatorViewErrorLog() {
        return `link ${this.labels.viewErrorLogLabel}`;
    }

}