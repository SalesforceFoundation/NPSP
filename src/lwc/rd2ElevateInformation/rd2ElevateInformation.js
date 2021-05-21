import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import { constructErrorMessage, extractFieldInfo, isNull, isUndefined, getNamespace } from 'c/utilCommon';
import { Rd2Service } from 'c/rd2Service';
import { PAYMENT_METHOD_CREDIT_CARD, PAYMENT_METHOD_ACH } from 'c/geConstants';

import RECURRING_DONATION_OBJECT from '@salesforce/schema/npe03__Recurring_Donation__c';
import FIELD_NAME from '@salesforce/schema/npe03__Recurring_Donation__c.Name';
import FIELD_COMMITMENT_ID from '@salesforce/schema/npe03__Recurring_Donation__c.CommitmentId__c';
import FIELD_STATUS from '@salesforce/schema/npe03__Recurring_Donation__c.Status__c';
import FIELD_PAYMENT_METHOD from '@salesforce/schema/npe03__Recurring_Donation__c.PaymentMethod__c';
import FIELD_CC_EXP_MONTH from '@salesforce/schema/npe03__Recurring_Donation__c.CardExpirationMonth__c';
import FIELD_CC_EXP_YEAR from '@salesforce/schema/npe03__Recurring_Donation__c.CardExpirationYear__c';
import FIELD_CC_LAST_4 from '@salesforce/schema/npe03__Recurring_Donation__c.CardLast4__c';
import FIELD_ACH_LAST_4 from '@salesforce/schema/npe03__Recurring_Donation__c.ACH_Last_4__c';
import FIELD_STATUS_REASON from '@salesforce/schema/npe03__Recurring_Donation__c.ClosedReason__c';
import FIELD_NEXT_DONATION_DATE from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Next_Payment_Date__c';
import FIELD_RD_ACCOUNT_NAME from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Organization__r.Name';
import FIELD_RD_PRIMARY_CONTACT_LAST_NAME from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Organization__r.npe01__One2OneContact__r.LastName';
import FIELD_RD_CONTACT_FIRST_NAME from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Contact__r.FirstName';
import FIELD_RD_CONTACT_LAST_NAME from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Contact__r.LastName';
import FIELD_RD_CONTACT_ID from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Contact__c';
import FIELD_RD_ACCOUNT_ID from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Organization__c';
import ERROR_OBJECT from '@salesforce/schema/Error__c';

import header from '@salesforce/label/c.RD2_ElevateInformationHeader';
import loadingMessage from '@salesforce/label/c.labelMessageLoading';
import statusSuccess from '@salesforce/label/c.RD2_ElevateInformationStatusSuccess';
import statusElevatePending from '@salesforce/label/c.RD2_ElevatePendingStatus';
import statusElevateCancelInProgress from '@salesforce/label/c.RD2_ElevateCancelInProgress';
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
import elevateRecordCreateFailed from '@salesforce/label/c.RD2_ElevateRecordCreateFailed';
import commonUnknownError from '@salesforce/label/c.commonUnknownError';
import viewErrorLogLabel from '@salesforce/label/c.commonViewErrorLog';
import updatePaymentInformation from '@salesforce/label/c.commonEditPaymentInformation';
import commonExpirationDate from '@salesforce/label/c.commonMMYY';

import getPermissionData from '@salesforce/apex/RD2_ElevateInformation_CTRL.getPermissionData';
import getError from '@salesforce/apex/RD2_ElevateInformation_CTRL.getLatestErrorMessage';
import getRecurringData from '@salesforce/apex/RD2_EntryFormController.getRecurringData';

const FIELDS = [
    FIELD_NAME,
    FIELD_PAYMENT_METHOD,
    FIELD_COMMITMENT_ID,
    FIELD_STATUS,
    FIELD_STATUS_REASON,
    FIELD_NEXT_DONATION_DATE,
    FIELD_RD_ACCOUNT_NAME,
    FIELD_RD_PRIMARY_CONTACT_LAST_NAME,
    FIELD_RD_CONTACT_LAST_NAME,
    FIELD_RD_CONTACT_FIRST_NAME,
    FIELD_RD_CONTACT_ID,
    FIELD_RD_ACCOUNT_ID
];

const OPTIONAL_FIELDS = [
    FIELD_CC_LAST_4,
    FIELD_ACH_LAST_4,
    FIELD_CC_EXP_MONTH,
    FIELD_CC_EXP_YEAR
];
const TEMP_PREFIX = '_PENDING_';
const STATUS_SUCCESS = 'success';

export default class rd2ElevateInformation extends NavigationMixin(LightningElement) {

    @api recordId;

    labels = Object.freeze({
        header,
        loadingMessage,
        statusSuccess,
        statusElevatePending,
        statusElevateCancelInProgress,
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
        elevateRecordCreateFailed,
        commonUnknownError,
        viewErrorLogLabel,
        updatePaymentInformation,
        commonExpirationDate
    });

    @track rdRecord;
    @track fields = {};
    @track status = {
        message: this.labels.statusSuccess,
        isProgress: false,
        value: STATUS_SUCCESS,
        icon: 'utility:success',
        assistiveText: this.labels.textSuccess
    };
    @track error = {};
    @track permissions = {
        hasAccess: null,
        hasKeyFieldsUpdateAccess : null,
        hasKeyFieldsAccess: null,
        showLastFourDigits: null,
        showExpirationDate: null,
        alert: ''
    };

    rd2Service = new Rd2Service();

    isLoading = true;
    isElevateCustomer = false;
    isElevateRecord = false;
    isElevateConnected = false;
    showLastFourACH = false;
    showLastFourCreditCard = false;
    showExpirationDate = false;
    displayEditModal = false;
    commitmentURLPrefix;
    defaultRecordTypeId;

    get paymentMethod() {
        return this.getValue(FIELD_PAYMENT_METHOD.fieldApiName);
    }

    get commitmentId() {
        return this.getValue(FIELD_COMMITMENT_ID.fieldApiName);
    }

    get commitmentURL() {
        return this.commitmentURLPrefix + this.commitmentId;
    }

    get nextDonationDate() {
        return this.getValue(FIELD_NEXT_DONATION_DATE.fieldApiName);
    }

    get canEditPaymentInformation() {
        return this.isElevateCustomer
            && this.permissions.hasKeyFieldsUpdateAccess;
    }

    /***
     * @description Initializes the component with data
     */
    connectedCallback() {
        if (this.recordId) {
            this.populatePermissionData();
            this.populateRecurringData();
        }
    }

    populatePermissionData() {
        getPermissionData({recordId: this.recordId})
            .then(response => {
                this.isElevateCustomer = response.isElevateCustomer;
                this.permissions.alert = response.alert;
                this.commitmentURLPrefix = response.commitmentURLPrefix;

                this.permissions.hasKeyFieldsAccess = this.isElevateCustomer === true
                    && response.hasFieldPermissions === true
                    && isNull(this.permissions.alert);

                this.permissions.hasKeyFieldsUpdateAccess = response.hasRDSObjectUpdatePermission
                    && response.hasFieldUpdatePermission;
                this.permissions.showExpirationDate = response.showExpirationDate;
                this.permissions.showLastFourDigits = response.showLastFourDigits;

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

                    } else {
                        this.getLatestErrorMessage();
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

    populateRecurringData() {
        getRecurringData({ recordId: this.recordId })
            .then(response => {
                this.accountHolderType = this.rd2Service.accountHolderTypeFor(response.DonorType);
            })
            .catch((error) => {
                this.handleError(error);
            });
    }

    /***
    * @description Retrieves Recurring Donation Object and fields labels/help text
    */
    @wire(getObjectInfo, { objectApiName: RECURRING_DONATION_OBJECT.objectApiName })
    wiredRecurringDonationObjectInfo(response) {
        if (response.data) {
            const rdObjectInfo = response.data;
            this.setFields(rdObjectInfo.fields);
            this.defaultRecordTypeId = rdObjectInfo.defaultRecordTypeId;
            this.checkLoading();
        }

        if (response.error && this.hasKeyFieldsAccess()) {
            this.handleError(response.error);
        }
    }

    /***
     * @description Tracks specified fields so when the Recurring Donation record is updated,
     * this method is called to force refresh of the data and the component.
     */
    @wire(getRecord, {
        recordId: '$recordId',
        fields: FIELDS,
        optionalFields: OPTIONAL_FIELDS
    })
    wiredRecurringDonation(response) {
        if (response.data) {
            this.rdRecord = response.data;

            const statusReason = this.getValue(FIELD_STATUS_REASON.fieldApiName);
            if (statusReason === this.labels.statusElevatePending) {
                this.status.isProgress = true;
                this.status.message = this.labels.statusElevateCancelInProgress;
            }

            this.checkLoading();
        }

        if (response.error && this.hasKeyFieldsAccess()) {
            this.handleError(response.error);
        }
    }

    /**
    * @description Get the lateset relevant error message for the Elevate Recurring Donation 
    */
    getLatestErrorMessage() {
        getError({recordId: this.recordId})
            .then(response => {
                if (!isNull(response)) {
                    this.setErrorStatus(response);
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
     * @description Checks if record detail page or user has access to the Elevate Information data fields
     */
    hasKeyFieldsAccess() {
        return this.isTrue(this.permissions.isElevateCustomer)
            && this.isTrue(this.permissions.hasKeyFieldsAccess);
    }

    /***
     * @description Is the payment type ACH and the user has read perms to the two last4 fields?
     */
    shouldShowLastFourACH() {
        return this.paymentMethod === PAYMENT_METHOD_ACH
            && this.isTrue(this.isElevateCustomer)
            && this.isTrue(this.permissions.showLastFourDigits);
    }

    /***
     * @description Is the payment type CreditCard and the user has read perms to the last4 fields?
     */
    shouldShowLastFourCreditCard() {
        return this.paymentMethod === PAYMENT_METHOD_CREDIT_CARD
            && this.isTrue(this.isElevateCustomer)
            && this.isTrue(this.permissions.showLastFourDigits);
    }

    /***
     * @description Does the user have perms to show the Expiration Date fields?
     */
    shouldShowExpirationDate() {
        return this.isTrue(this.permissions.showExpirationDate) && this.paymentMethod === PAYMENT_METHOD_CREDIT_CARD;
    }

    /***
     * @description Returns the expiration date as string in the format of MM/YYYY
     */
    get expirationDate() {
        return this.getValue(FIELD_CC_EXP_MONTH.fieldApiName) + '/' + this.getValue(FIELD_CC_EXP_YEAR.fieldApiName);
    }

    /***
     * @description Returns the last 4 digits from the ACH account
     */
    get lastFourDigitsAch() {
        return this.getValue(FIELD_ACH_LAST_4.fieldApiName);
    }

    /***
     * @description Returns the last 4 digits for a credit card
     */
    get lastFourDigitsCreditCard() {
        return this.getValue(FIELD_CC_LAST_4.fieldApiName);
    }

    /**
    * @desciprtion launch Update Payment Information Modal
    */
    openUpdatePaymentInformationModal() {
        this.displayEditModal = true;
    }

    closeUpdatePaymentInformationModal() {
        this.displayEditModal = false;
      }

    /***
     * @description Generates URL for Elevate commitment
     */
    navigateToCommitment() {
        // Navigate to a URL
        this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: this.commitmentURL
                }
            },
            false
        );
    }

    /**
     * @description Checks if the form still has outstanding data to load
     */
    checkLoading() {
        if (this.isNot(this.isElevateCustomer) || this.isNot(this.permissions.hasKeyFieldsAccess)) {
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
        const commitmentId = this.commitmentId;

        this.isElevateRecord = !isNull(commitmentId);
        this.isElevateConnected = this.isElevateRecord && !commitmentId.startsWith(TEMP_PREFIX);

        this.showLastFourACH = this.shouldShowLastFourACH();
        this.showLastFourCreditCard = this.shouldShowLastFourCreditCard();
        this.showExpirationDate = this.shouldShowExpirationDate();

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
        this.fields.payment_method = extractFieldInfo(fieldInfos, FIELD_PAYMENT_METHOD.fieldApiName);
        this.fields.ach_last_four = extractFieldInfo(fieldInfos, FIELD_ACH_LAST_4.fieldApiName);
        this.fields.credit_last_four = extractFieldInfo(fieldInfos, FIELD_CC_LAST_4.fieldApiName);
        this.fields.exp_month = extractFieldInfo(fieldInfos, FIELD_CC_EXP_MONTH.fieldApiName);
        this.fields.exp_year = extractFieldInfo(fieldInfos, FIELD_CC_EXP_YEAR.fieldApiName);
    }

    /**
     * @description Displays record error log page by navigating to
     * the "ERR_RecordLog" Lightning Component wrapper displaying the "errRecordLog" LWC.
     * The LC name has the namespace, or "c" in unmanaged package, followed by "__" prefix.
     * The state attributes representing must be prefixed with "c__" prefix, see the following for more details:
     * https://developer.salesforce.com/docs/component-library/documentation/lwc/lwc.use_navigate_add_params_url
     */
    navigateToErrorLog() {
        const namespace = getNamespace(ERROR_OBJECT.objectApiName);
        const compName = (namespace ? namespace : 'c') + "__ERR_RecordLog";

        this[NavigationMixin.Navigate]({
            type: "standard__component",
            attributes: {
                componentName: compName
            },
            state: {
                c__recordId: this.recordId
            }
        });
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
            this.permissions.hasKeyFieldsAccess = false;
            this.permissions.showLastFourDigits = false;
            this.permissions.showExpirationDate = false;
            this.error.header = this.labels.insufficientPermissions;
            this.isLoading = false;
        }
    }


    /***
    * @description data-qa-locator values for elements on the component
    */
    get qaLocatorHeader() {
        return `text Header`;
    }

    get qaLocatorError() {
        return `error Notification`;
    }

    get qaLocatorSpinner() {
        return `spinner Loading Message`;
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
        return `progress ring`;
    }

    get qaLocatorStatusIcon() {
        return `icon Status`;
    }

    get qaLocatorStatusMessage() {
        return `text Status Message`;
    }

    get qaLocatorCommitmentId() {
        return `text Elevate Recurring Id`;
    }

    get qaLocatorLastFourDigits() {
        return `text Last Four Digits`;
    }

    get qaLocatorExpirationDate() {
        return `text Expiration Date`;
    }

    get qaLocatorLastFourDigits() {
        return `text Last Four Digits`;
    }

    get qaLocatorExpirationDate() {
        return `text Expiration Date`;
    }

    get qaLocatorNewWindow() {
        return `link New Window`;
    }

    get qaLocatorViewErrorLog() {
        return `link View Error Log`;
    }

    get qaLocatorUpdatePaymentInformation() {
        return `link Update Payment Information`;
    }

}