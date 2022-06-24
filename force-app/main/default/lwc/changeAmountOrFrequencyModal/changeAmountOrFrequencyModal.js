/*import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import upsertDonation from '@salesforce/apex/RD2_ETableController.upsertDonation';
import changeAmountOrFrequency from '@salesforce/label/c.changeAmountOrFrequency';
import updateRecurringDonation from '@salesforce/label/c.updateRecurringDonation';
import every from "@salesforce/label/c.RD2_EntryFormScheduleEveryLabel";
import commonAmount from "@salesforce/label/c.commonAmount";
import installmentPeriod from "@salesforce/label/c.installmentPeriod";
import recurringDonationSchedule from "@salesforce/label/c.recurringDonationSchedule";
import RECURRING_DONATION from '@salesforce/schema/npe03__Recurring_Donation__c';
import AMOUNT_FIELD from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Amount__c';
import INSTALLMENT_FREQUENCY_FIELD from '@salesforce/schema/npe03__Recurring_Donation__c.InstallmentFrequency__c';
import INSTALLMENT_PERIOD_FIELD from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installment_Period__c';
import commonCancelAndClose from '@salesforce/label/c.commonCancelAndClose';
import commonCancel from '@salesforce/label/c.commonCancel';
import RD2_ElevateRDCancellingTitle from '@salesforce/label/c.RD2_ElevateRDCancellingTitle';
import RD2_ElevateRDCancellingMessage from '@salesforce/label/c.RD2_ElevateRDCancellingMessage';
import RD2_NonElevateRDCancellingTitle from '@salesforce/label/c.RD2_NonElevateRDCancellingTitle';

const ESC_KEY_CODE = 27;
const ESC_KEY_STRING = "Escape";
const FOCUSABLE_ELEMENTS = "button";
const TAB_KEY_CODE = 9;
const TAB_KEY_STRING = "Tab";
export default class ChangeAmountOrFrequencyModal extends LightningElement {
    @api openChangeAmountOrFrequency;
    @api currentRecord;
    isRenderCallbackActionExecuted = false;
    isElevate;

    recurringDonationApiName = RECURRING_DONATION;
    amountFieldName = AMOUNT_FIELD;
    installmentFrequencyFieldName = INSTALLMENT_FREQUENCY_FIELD;
    installmentPeriodFieldName = INSTALLMENT_PERIOD_FIELD;
    style = document.createElement('style');

    labels = {
        changeAmountOrFrequency,
        updateRecurringDonation,
        every,
        commonAmount,
        recurringDonationSchedule,
        installmentPeriod,
        commonCancelAndClose,
        commonCancel
    }

/**
     * @description Returns title label for toast based on elevate or non elevate RD
     */
//  get title() {
//     if (this.isElevate) {
//         return RD2_ElevateRDCancellingTitle;
//     }
//     return RD2_NonElevateRDCancellingTitle;
//   }

//   /**
//    * @description Returns message label for toast based on elevate or non elevate RD
//    */
//   get message() {
//     if (this.isElevate) {
//         return RD2_ElevateRDCancellingMessage;
//     }
//     return '';
//   }

//     renderedCallback() {
//         if (this.isRenderCallbackActionExecuted) {
//             return;
//         }
//         if(this.currentRecord ){
//             if(this.currentRecord !== {}){
//                 this.template.addEventListener("keydown", (e) => this.handleKeyUp(e));
//                 this.style.innerText = `lightning-helptext {
//                     display:none;
//                 }`;
//                 if(this.template.querySelector('lightning-record-edit-form')){
//                     this.template.querySelector('lightning-record-edit-form').appendChild(this.style);
//                 }
//             }

//         }
//       }
  
//       handleKeyUp(e) {
//           const firstFocusableElement = this._getFocusableElements()[0];
//           const focusableContent = this._getFocusableElements();
//           const lastFocusableElement = focusableContent[focusableContent.length - 1];
        
//           if (e.shiftKey) {
//             if (this.template.activeElement === firstFocusableElement) {
//               lastFocusableElement.focus();
//               e.preventDefault();
//             }
//           } else if(e.code === ESC_KEY_STRING || e.keyCode === ESC_KEY_CODE) {
//             this.closeModal();
//           } else if(e.code === TAB_KEY_STRING || e.keyCode === TAB_KEY_CODE) {
//             if (this.template.activeElement === lastFocusableElement) {
//               firstFocusableElement.focus();
//               e.preventDefault();
//             }
//           }
//       }
      
//       handleSaveRecurringDonation(){
//         let newAmount = this.template.querySelector(".rd-amount-input").value;
//         let newInstallmentFrequency = this.template.querySelector(".rd-installment_frequency-input").value;
//         let newInstallmentPeriod = this.template.querySelector(".rd-installment_period-input").value;
//         let record = Object.assign({}, this.currentRecord.recurringDonation);
//         record.npe03__Amount__c = newAmount;
//         record.InstallmentFrequency__c = newInstallmentFrequency;
//         record.npe03__Installment_Period__c = newInstallmentPeriod;

//         upsertDonation({ recurringDonation: record })
//           .then(() => {
//             this.isElevate = record.CommitmentId__c ? true : false;
//             const event = new ShowToastEvent({
//                 title: this.title,
//                 message: this.message
//             });
//             this.dispatchEvent(event);
//             this.closeModal();
//           })
//       }
  
//       _getFocusableElements() {
//         const potentialElems = [
//           ...this.template.querySelectorAll(FOCUSABLE_ELEMENTS),
//         ];
//         return potentialElems;
//       }
  
//       closeModal() {
//         this.template.removeEventListener("keydown", (e) => this.handleKeyUp(e));       
//         if(this.template.querySelector('lightning-record-edit-form')){
//             this.style.innerText = `lightning-helptext {
//                 display:none;
//             }`;
//             this.template.querySelector('lightning-record-edit-form').removeChild(this.style);
//         }
//         this.isRenderCallbackActionExecuted = false;
//         this.dispatchEvent(new CustomEvent('close', {detail: 'changeAmountOrFrequency'}));
//     } 
// }
import { LightningElement, api, track, wire } from "lwc";
import { registerListener } from "c/pubsubNoPageRef";
import { Rd2Service, ACTIONS } from "c/rd2Service";
import {
    isNull,
    showToast,
    constructErrorMessage,
    format,
    extractFieldInfo,
    buildFieldDescribes,
    isEmpty,
} from "c/utilCommon";
import { HTTP_CODES } from "c/geConstants";

import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { getRecord, getFieldValue, getRecordNotifyChange } from "lightning/uiRecordApi";

import RECURRING_DONATION_OBJECT from "@salesforce/schema/npe03__Recurring_Donation__c";

import FIELD_NAME from "@salesforce/schema/npe03__Recurring_Donation__c.Name";
import FIELD_CAMPAIGN from "@salesforce/schema/npe03__Recurring_Donation__c.npe03__Recurring_Donation_Campaign__c";
import FIELD_AMOUNT from "@salesforce/schema/npe03__Recurring_Donation__c.npe03__Amount__c";
import FIELD_PAYMENT_METHOD from "@salesforce/schema/npe03__Recurring_Donation__c.PaymentMethod__c";
import FIELD_STATUS from "@salesforce/schema/npe03__Recurring_Donation__c.Status__c";
import FIELD_STATUS_REASON from "@salesforce/schema/npe03__Recurring_Donation__c.ClosedReason__c";
import FIELD_ACH_LAST4 from "@salesforce/schema/npe03__Recurring_Donation__c.ACH_Last_4__c";
import FIELD_CARD_LAST4 from "@salesforce/schema/npe03__Recurring_Donation__c.CardLast4__c";
import FIELD_INSTALLMENT_FREQUENCY from "@salesforce/schema/npe03__Recurring_Donation__c.InstallmentFrequency__c";
import FIELD_INSTALLMENT_PERIOD from "@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installment_Period__c";
import FIELD_CHANGE_TYPE from "@salesforce/schema/npe03__Recurring_Donation__c.ChangeType__c";

import currencyFieldLabel from "@salesforce/label/c.lblCurrency";
import cancelButtonLabel from "@salesforce/label/c.stgBtnCancel";
import closeButtonLabel from "@salesforce/label/c.commonClose";
import saveButtonLabel from "@salesforce/label/c.stgBtnSave";
import newHeaderLabel from "@salesforce/label/c.RD2_EntryFormHeader";
import editHeaderLabel from "@salesforce/label/c.commonEdit";
import donorSectionHeader from "@salesforce/label/c.RD2_EntryFormDonorSectionHeader";
import scheduleSectionHeader from "@salesforce/label/c.RD2_EntryFormDonationSectionHeader";
import otherSectionHeader from "@salesforce/label/c.RD2_EntryFormOtherSectionHeader";
import statusSectionHeader from "@salesforce/label/c.RD2_EntryFormStatusSectionHeader";
import customFieldsSectionHeader from "@salesforce/label/c.RD2_EntryFormCustomFieldsSectionHeader";
import insertSuccessMessage from "@salesforce/label/c.RD2_EntryFormInsertSuccessMessage";
import updateSuccessMessage from "@salesforce/label/c.RD2_EntryFormUpdateSuccessMessage";
import flsErrorDetail from "@salesforce/label/c.RD2_EntryFormMissingPermissions";
import flsErrorHeader from "@salesforce/label/c.geErrorFLSHeader";
import elevateWidgetLabel from "@salesforce/label/c.commonPaymentServices";
import spinnerAltText from "@salesforce/label/c.geAssistiveSpinner";
import loadingMessage from "@salesforce/label/c.labelMessageLoading";
import waitMessage from "@salesforce/label/c.commonWaitMessage";
import savingRDMessage from "@salesforce/label/c.RD2_EntryFormSaveRecurringDonationMessage";
import savingCommitmentMessage from "@salesforce/label/c.RD2_EntryFormSaveCommitmentMessage";
import commitmentFailedMessage from "@salesforce/label/c.RD2_EntryFormSaveCommitmentFailedMessage";
import contactAdminMessage from "@salesforce/label/c.commonContactSystemAdminMessage";
import unknownError from "@salesforce/label/c.commonUnknownError";

import handleCommitment from "@salesforce/apex/RD2_EntryFormController.handleCommitment";
import logError from "@salesforce/apex/RD2_EntryFormController.logError";

import MAILING_COUNTRY_FIELD from "@salesforce/schema/Contact.MailingCountry";
import CONTACT_FIRST_NAME from "@salesforce/schema/Contact.FirstName";
import CONTACT_LAST_NAME from "@salesforce/schema/Contact.LastName";
import ACCOUNT_NAME from "@salesforce/schema/Account.Name";
import ACCOUNT_PRIMARY_CONTACT_LAST_NAME from "@salesforce/schema/Account.npe01__One2OneContact__r.LastName";

/***
 * @description Event name fired when the Elevate credit card widget
 * is displayed or hidden on the RD2 entry form
 */
const ELEVATE_WIDGET_EVENT_NAME = "rd2ElevateCreditCardForm";

export default class rd2EntryForm extends LightningElement {
    customLabels = Object.freeze({
        cancelButtonLabel,
        closeButtonLabel,
        saveButtonLabel,
        donorSectionHeader,
        otherSectionHeader,
        scheduleSectionHeader,
        statusSectionHeader,
        customFieldsSectionHeader,
        currencyFieldLabel,
        flsErrorHeader,
        flsErrorDetail,
        elevateWidgetLabel,
        spinnerAltText,
        loadingMessage,
        waitMessage,
        savingRDMessage,
        savingCommitmentMessage,
        commitmentFailedMessage,
        contactAdminMessage,
        unknownError,
    });

    @api openChangeAmountOrFrequency;
    @api parentId;
    recordId='a091k000008MkGrAAK';
    //@api recordId;

    _contactId;
    _accountId;

    @track record;
    @track fields = {};
    fieldInfos;

    isLoading = true;
    loadingText = this.customLabels.loadingMessage;
    isRecordReady = false;
    isSettingReady = false;
    isSaveButtonDisabled = true;

    isElevateWidgetEnabled = false;
    isElevateEditWidgetEnabled = false;
    hasUserDisabledElevateWidget = false;

    rd2Service = new Rd2Service();
    @track rd2State = this.rd2Service.init();

    @track error = {};

    /***
     * @description Get the next donation date for this recurring donation
     */
    get nextDonationDate() {
        const localDate = new Date(this.rd2State.nextDonationDate);
        return new Date(localDate.getUTCFullYear(), localDate.getUTCMonth(), localDate.getUTCDate());
    }

    /***
     * @description Get the Label for the Card Last 4 field
     */
    get cardLastFourLabel() {
        return this.fields.cardLastFour ? this.fields.cardLastFour.label : "";
    }

    /***
     * @description Get the Label for the Card Last 4 field
     */
    get achLastFourLabel() {
        return this.fields.achLastFour ? this.fields.achLastFour.label : "";
    }

    /***
     * @description Dynamically render the new/edit form via CSS to show/hide based on the status of
     * callouts to retrieve RD settings and other required data.
     */
    get cssEditForm() {
        return !this.isLoading && this.isSettingReady && this.isRecordReady ? "" : "slds-hide";
    }

    /***
     * @description Get settings required to enable or disable fields and populate their values
     */
    async connectedCallback() {
        try {
            console.log("rd2EntryForm this.recordId: ",this.recordId);
            console.log("rd2EntryForm this.parentId: ",this.parentId);
            console.log("rd2EntryForm this.state: ",this.state);
            console.log("rd2EntryForm this.rd2State BEFORE: ", JSON.stringify(this.rd2State));
            this.rd2State = await this.rd2Service.loadInitialView(this.state, this.recordId, this.parentId);
            console.log("rd2EntryForm this.rd2State AFTER: ", JSON.stringify(this.rd2State));
        } catch (ex) {
            this.perform({
                type: ACTIONS.SET_ERROR,
                payload: ex,
            });
        }
        this._contactId = this.rd2State.contactId;
        this._accountId = this.rd2State.accountId;
        console.log('rd2EntryForm this._contactId: ',this._contactId);
        console.log('rd2EntryForm this._accountId: ',this._accountId);
        this.isSaveButtonDisabled = false;
        this.isSettingReady = true;
        this.isLoading = false;

        this.evaluateElevateEditWidget();

        if (!this.rd2State.hasRequiredPermissions) {
            this.handleError({
                header: this.customLabels.flsErrorHeader,
                detail: this.customLabels.flsErrorDetail,
            });
        }

        registerListener(ELEVATE_WIDGET_EVENT_NAME, this.handleElevateWidgetDisplayState, this);
    }

    perform(action) {
        this.rd2State = this.rd2Service.dispatch(this.rd2State, action);
    }

    /**
     * @description Set variable that informs the RD form when the
     *  credit card widget is displayed or hidden by a user
     * @param event
     */
    handleElevateWidgetDisplayState(event) {
        if (this.shouldResetPaymentMethodOnStateChange(event)) {
            this.resetPaymentMethod();
        }
        this.hasUserDisabledElevateWidget = event.isDisabled;
    }

    shouldResetPaymentMethodOnStateChange(event) {
        return event.isDisabled && this.isEdit && this.isPaymentMethodChanged() && this.isCommitmentEdit;
    }

    /***
     * @description Retrieve Recurring Donation Object info
     */
    @wire(getObjectInfo, { objectApiName: RECURRING_DONATION_OBJECT.objectApiName })
    wiredRecurringDonationObjectInfo(response) {
        if (response.data) {
            let rdObjectInfo = response.data;
            this.setFields(rdObjectInfo.fields);
            this.fieldInfos = buildFieldDescribes(rdObjectInfo.fields, rdObjectInfo.apiName);

            this.isRecordReady = true;
        }

        if (response.error) {
            this.handleError(response.error);
        }
    }

    /***
     * @description Construct field describe info from the Recurring Donation SObject info
     */
    setFields(fieldInfos) {
        this.fields.campaign = extractFieldInfo(fieldInfos, FIELD_CAMPAIGN.fieldApiName);
        this.fields.name = extractFieldInfo(fieldInfos, FIELD_NAME.fieldApiName);
        this.fields.amount = extractFieldInfo(fieldInfos, FIELD_AMOUNT.fieldApiName);
        this.fields.paymentMethod = extractFieldInfo(fieldInfos, FIELD_PAYMENT_METHOD.fieldApiName);
        this.fields.status = extractFieldInfo(fieldInfos, FIELD_STATUS.fieldApiName);
        this.fields.statusReason = extractFieldInfo(fieldInfos, FIELD_STATUS_REASON.fieldApiName);
        this.fields.cardLastFour = extractFieldInfo(fieldInfos, FIELD_CARD_LAST4.fieldApiName);
        this.fields.currency = { label: currencyFieldLabel, apiName: "CurrencyIsoCode" };
        this.fields.achLastFour = extractFieldInfo(fieldInfos, FIELD_ACH_LAST4.fieldApiName);
        this.fields.changeType = extractFieldInfo(fieldInfos, FIELD_CHANGE_TYPE.fieldApiName);
    }

    /***
     * @description Retrieve Recurring Donation record value
     */
    @wire(getRecord, { recordId: "$recordId", fields: "$fieldInfos" })
    wiredRecurringDonationRecord(response) {
        if (response.data) {
            this.record = response.data;
            this.isRecordReady = true;

            this.evaluateElevateEditWidget();
            this.evaluateElevateWidget();
        } else if (response.error) {
            this.handleError(response.error);
        }
    }

    /**
     * @description Handles contact change only when the org is connected to Elevate
     * and a new Recurring Donation is being created.
     * Otherwise, contact data should not be retrieved from database.
     */
    handleContactChange(event) {
        this._contactId = event.detail;
        this.perform({
            type: ACTIONS.SET_CONTACT_ID,
            payload: event.detail,
        });
    }

    handleAccountChange(event) {
        this._accountId = event.detail;
        this.perform({
            type: ACTIONS.SET_ACCOUNT_ID,
            payload: event.detail,
        });
    }

    handleDonorTypeChange(event) {
        this.perform({
            type: ACTIONS.SET_DONOR_TYPE,
            payload: event.detail,
        });
    }

    handleDateEstablishedChange(event) {
        this.perform({
            type: ACTIONS.SET_DATE_ESTABLISHED,
            payload: event.detail,
        });
    }

    handleNameChange(event) {
        this.perform({
            type: ACTIONS.SET_RECORD_NAME,
            payload: event.target.value,
        });
    }

    handleCampaignChange(event) {
        this.perform({
            type: ACTIONS.SET_CAMPAIGN_ID,
            payload: event.target.value,
        });
    }

    handleChangeTypeChange(event) {
        this.perform({
            type: ACTIONS.SET_CHANGE_TYPE,
            payload: event.detail.value,
        });
    }

    handleCustomFieldChange(event) {
        this.perform({
            type: ACTIONS.CUSTOM_FIELD_CHANGE,
            payload: event.detail,
        });
    }

    /**
     * @description Retrieves the contact data whenever a contact is changed.
     * Data is not refreshed when the contact Id is null.
     */
    @wire(getRecord, {
        recordId: "$_contactId",
        fields: [MAILING_COUNTRY_FIELD, CONTACT_LAST_NAME, CONTACT_FIRST_NAME],
    })
    wiredGetRecord({ error, data }) {
        if (data) {
            const mailingCountry = getFieldValue(data, MAILING_COUNTRY_FIELD);
            const lastName = getFieldValue(data, CONTACT_LAST_NAME);
            const firstName = getFieldValue(data, CONTACT_FIRST_NAME);
            this.perform({
                type: ACTIONS.SET_CONTACT_DETAILS,
                payload: { firstName, lastName, mailingCountry },
            });
            this.handleElevateWidgetDisplay();
        } else if (error) {
            this.handleError(error);
        }
    }

    @wire(getRecord, {
        recordId: "$_accountId",
        fields: [ACCOUNT_NAME, ACCOUNT_PRIMARY_CONTACT_LAST_NAME],
    })
    wiredGetDonorAccount({ error, data }) {
        if (data) {
            const accountName = getFieldValue(data, ACCOUNT_NAME);
            const lastName = getFieldValue(data, ACCOUNT_PRIMARY_CONTACT_LAST_NAME);
            this.perform({
                type: ACTIONS.SET_ACCOUNT_DETAILS,
                payload: { lastName, accountName },
            });
        } else if (error) {
            this.handleError(error);
        }
    }

    /***
     * @description Checks if form re-rendering is required due to payment method change
     * @param event Contains new payment method value
     */
    handlePaymentChange(event) {
        //reset the widget and the form related to the payment method
        this.perform({
            type: ACTIONS.SET_PAYMENT_METHOD,
            payload: event.detail.value,
        });
        this.hasUserDisabledElevateWidget = this.isCommitmentEdit;
        this.isElevateEditWidgetEnabled = false;
        this.evaluateElevateWidget();
    }

    handleStatusChange(event) {
        this.perform({
            type: ACTIONS.SET_STATUS,
            payload: event.detail.value,
        });
        this.evaluateElevateEditWidget();
    }

    handleStatusReasonChange(event) {
        this.perform({
            type: ACTIONS.SET_STATUS_REASON,
            payload: event.detail.value,
        });
    }

    /***
     * @description Handle schedule form fields:
     * - Recurring Type change might hide or display the credit card widget.
     * @param event
     */
    handleRecurringTypeChange(event) {
        this.perform({
            type: ACTIONS.SET_RECURRING_TYPE,
            payload: event.detail,
        });
        this.handleElevateWidgetDisplay();
    }

    handleRecurringPeriodChange(event) {
        this.perform({
            type: ACTIONS.SET_RECURRING_PERIOD,
            payload: event.detail,
        });
        this.handleElevateWidgetDisplay();
    }

    handleRecurringPeriodTypeChange(event) {
        this.handleElevateWidgetDisplay();
        this.perform({
            type: ACTIONS.SET_PERIOD_TYPE,
            payload: event.detail,
        });
    }

    handleDayOfMonthChange(event) {
        this.perform({
            type: ACTIONS.SET_DAY_OF_MONTH,
            payload: event.detail,
        });
    }

    handleStartDateChange(event) {
        this.perform({
            type: ACTIONS.SET_START_DATE,
            payload: event.detail,
        });
    }

    handleFrequencyChange(event) {
        this.perform({
            type: ACTIONS.SET_RECURRING_FREQUENCY,
            payload: event.detail,
        });
    }

    handleInstallmentsChange(event) {
        this.perform({
            type: ACTIONS.SET_PLANNED_INSTALLMENTS,
            payload: event.detail,
        });
    }

    /***
     * @description Currency change might hide or display the credit card widget
     * @param event
     */
    handleCurrencyChange(event) {
        this.perform({
            type: ACTIONS.SET_CURRENCY,
            payload: event.target.value,
        });
        this.handleElevateWidgetDisplay();
    }

    /***
     * @description Checks if the credit card widget should be displayed.
     */
    handleElevateWidgetDisplay() {
        if (this.rd2State.isElevateCustomer) {
            this.evaluateElevateWidget();
        }
    }

    handleAmountChange(event) {
        this.perform({
            type: ACTIONS.SET_DONATION_AMOUNT,
            payload: event.target.value,
        });
    }

    get isCommitmentEdit() {
        return !!this.rd2State.commitmentId;
    }

    get showChangeTypeField() {
        return !!this.rd2State.recordId && this.rd2State.isChangeLogEnabled;
    }

    get hasCustomFields() {
        return Object.keys(this.rd2State.customFieldSets).length > 0;
    }

    /***
     * @description Checks if the Elevate Widget should be displayed on Edit
     */
    evaluateElevateEditWidget() {
        if (this.rd2State.isElevateCustomer && this.rd2State.recordId) {
            // Since the widget requires interaction to Edit, this should start as true
            this.hasUserDisabledElevateWidget = true;

            this.isElevateEditWidgetEnabled = this.rd2Service.isValidForElevate(this.rd2State);

            this.isElevateWidgetEnabled = this.isElevateEditWidgetEnabled;
        }
    }

    /***
     * @description Checks if the Elevate widget should be displayed.
     * The Elevate widget is applicable to new RDs only for now.
     */
    evaluateElevateWidget() {
        const isStateValidForElevate = this.rd2Service.isValidForElevate(this.rd2State);
        this.isElevateWidgetEnabled = this.isElevateEditWidgetEnabled || isStateValidForElevate;
    }

    /***
     * @description Returns true if the Elevate widget is enabled and
     * user did not click on the link to hide it
     */
    isElevateWidgetDisplayed() {
        return this.isElevateWidgetEnabled === true && this.hasUserDisabledElevateWidget !== true;
    }

    /***
     * @description Overrides the standard submit.
     * Collects and validates fields displayed on the form and any integrated LWC
     * and submits them for the record insert or update.
     */
    handleSubmit() {
        this.clearError();
        this.isLoading = true;
        this.loadingText = this.customLabels.waitMessage;
        this.isSaveButtonDisabled = true;

        if (this.isFormValid()) {
            const allFields = this.getAllFields();
            if (this.shouldSendToElevate(allFields)) {
                this.processCommitmentSubmit(allFields);
            } else {
                this.processSubmit(allFields);
            }
        } else {
            this.isLoading = false;
            this.isSaveButtonDisabled = false;
        }
    }

    /***
     * @description Overrides the standard submit when an
     * Elevate recurring commitment record is to be created or updated.
     */
    async processCommitmentSubmit(allFields) {
        try {
            if (this.isElevateWidgetDisplayed()) {
                this.loadingText = this.rd2Service.getPaymentProcessingMessage(this.rd2State.paymentMethod);

                const elevateWidget = this.template.querySelector('[data-id="elevateWidget"]');

                const paymentToken = await elevateWidget.returnToken().payload;
                this.perform({
                    type: ACTIONS.SET_PAYMENT_TOKEN,
                    payload: paymentToken,
                });
            }
        } catch (error) {
            this.enableSaveButton();
            this.isLoading = false;
            return;
        }

        this.loadingText = this.customLabels.savingCommitmentMessage;

        try {
            const rd = this.rd2Service
                .constructRecurringDonation(this.recordId, this.rd2State.commitmentId)
                .withInputFieldValues(allFields);

            handleCommitment({
                jsonRecord: rd.asJSON(),
                paymentMethodToken: this.rd2State.paymentToken,
            })
                .then((jsonResponse) => {
                    const response = isNull(jsonResponse) ? null : JSON.parse(jsonResponse);
                    const isSuccess =
                        isNull(response) ||
                        response.statusCode === HTTP_CODES.Created ||
                        response.statusCode === HTTP_CODES.OK;
                    const responseBody = JSON.parse(response.body);

                    if (isSuccess) {
                        this.perform({
                            type: ACTIONS.COMMITMENT_RESPONSE,
                            payload: responseBody,
                        });
                        rd.withCommitmentResponseBody(responseBody);
                        this.processSubmit(rd.record);
                    } else {
                        const message = this.rd2Service.getCommitmentError(response);
                        this.handleSaveError(message);
                    }
                })
                .catch((error) => {
                    this.handleSaveError(error);
                });
        } catch (error) {
            this.handleSaveError(error);
        }
    }

    /***
     * @description Determines if new or existing Recurring Donation update should send to Elevate
     */
    shouldSendToElevate() {
        if (!this.rd2State.isElevateCustomer) {
            return false;
        }

        return (
            this.isElevateWidgetDisplayed() ||
            (this.rd2Service.hasElevateFieldsChange(this.rd2State) &&
                !isEmpty(this.getCommitmentId()) &&
                !this.rd2Service.isOriginalStatusClosed(this.rd2State))
        );
    }

    /***
     * @description Returns commitment Id that can be retrieved from database, or
     * set by the user in the custom fields section
     */
    getCommitmentId() {
        return !isEmpty(this.rd2State.commitmentId) ? this.rd2State.commitmentId : null;
    }

    /***
     * @description Overrides the standard submit.
     * Collects and validates fields displayed on the form and any integrated LWC
     * and submits them for the record insert or update.
     */
    async processSubmit() {
        try {
            this.loadingText = this.customLabels.savingRDMessage;
            const saveResult = await this.rd2Service.save(this.rd2State);

            if (saveResult.success === true) {
                this.perform({
                    type: ACTIONS.RECORD_SAVED,
                    payload: saveResult,
                });

                if (this.isEdit) {
                    getRecordNotifyChange([{ recordId: this.rd2State.recordId }]);
                }

                this.handleSuccess();
            } else {
                this.handleSaveError(saveResult);
            }
        } catch (error) {
            this.handleSaveError(error);
        }
    }

    /**
     * @description Clears the error notification
     */
    clearError() {
        this.error = {};
    }

    /***
     * @description Handle component display when an error on the save action occurs.
     * Keep Save button enabled so user can correct a value and save again.
     */
    handleSaveError(error) {
        try {
            const constructedError = constructErrorMessage(error);
            // Transform the error to a user-friendly error and log it when
            // the RD insert failed but the Elevate commitment has been created
            if (isNull(this.rd2State.recordId) && !isEmpty(this.getCommitmentId())) {
                constructedError.detail = format(this.customLabels.commitmentFailedMessage, [
                    this.getCommitmentId(),
                    this.error.detail,
                ]);
                logError({ recordId: this.rd2State.recordId, errorMessage: this.error.detail }).catch(() => {});
            }
            this.setError(constructedError);
        } catch (ex) {
            console.error("Unhandled save error", ex);
        }

        this.enableSaveButton();
        this.isLoading = false;
    }

    /***
     * @description Handle error and disable the Save button
     */
    handleError(error) {
        this.setError(error);
        this.disableSaveButton();
    }

    setError(error) {
        this.template.querySelector(".error-container").scrollIntoView();
        this.error = error;
    }

    disableSaveButton() {
        this.isSaveButtonDisabled = true;
    }

    enableSaveButton() {
        this.isSaveButtonDisabled = false;
    }

    /**
     * @description Handle a child-to-parent component error event
     * @param event (error construct)
     */
    handleChildComponentError(event) {
        const error = event.detail && event.detail.value ? event.detail.value : event.detail;
        this.handleError(error);
    }

    /***
     * @description Fires an event to utilDedicatedListener with the cancel action
     */
    handleCancel() {
        this.closeModal(this.rd2State.recordId);
        this.dispatchEvent(new CustomEvent('close', {detail: 'changeAmountOrFrequency'}));
    }

    /***
     * @description Fires an event to utilDedicatedListener with the success action
     */
    handleSuccess() {
        const message = this.isEdit
            ? updateSuccessMessage.replace("{0}", this.rd2State.recordName)
            : insertSuccessMessage.replace("{0}", this.rd2State.recordName);

        showToast(message, "", "success");

        this.closeModal(this.rd2State.recordId);
    }

    /**
     * @description Dispatches an event to close the Recurring Donation entry form modal
     */
    //closeModal(recordId) {
    closeModal() {
        this.resetAllValues();
        
        /*const closeModalEvent = new CustomEvent("closemodal", {
            detail: { recordId: recordId },
        });*/
        //this.dispatchEvent(closeModalEvent);
        this.dispatchEvent(new CustomEvent('close', {detail: 'changeAmountOrFrequency'}));
    }

    /**
     * @description Reset all input values when entry form modal is closed, Reset all values in LWC
     *   because New override button will not refresh in the same lightning session
     */
    resetAllValues() {
        this.isLoading = false;
        this.isSaveButtonDisabled = false;
        this.isElevateWidgetEnabled = false;
        this.clearError();

        const inputFields = this.template.querySelectorAll("lightning-input-field");
        inputFields.forEach((field) => {
            if (field.value) {
                field.clean();
            }
        });

        this.perform({
            type: ACTIONS.RESET,
        });

        if (!isNull(this.donorComponent)) {
            this.donorComponent.resetValues();
        }
        if (!isNull(this.scheduleComponent)) {
            this.scheduleComponent.resetValues();
        }
        if (!isNull(this.customFieldsComponent)) {
            this.customFieldsComponent.resetValues();
        }
    }

    resetPaymentMethod() {
        this.perform({
            type: ACTIONS.SET_PAYMENT_METHOD,
            payload: null,
        });
        const field = this.template.querySelector('lightning-input-field[data-id="paymentMethod"]');
        field.reset();
    }

    get errorContainer() {
        return this.template.querySelector(".error-container");
    }

    get headerLabel() {
        if (this.rd2State.recordId) {
            return `${editHeaderLabel} ${this.rd2State.recordName}`;
        }
        return newHeaderLabel;
    }

    /**
     * @description Returns the Schedule Child Component instance
     * @return rd2EntryFormScheduleSection component dom
     */
    get scheduleComponent() {
        return this.template.querySelectorAll('[data-id="scheduleComponent"]')[0];
    }

    /**
     * @description Returns the Donor Child Component instance
     * @return rd2EntryFormDonorSection component dom
     */
    get donorComponent() {
        return this.template.querySelectorAll('[data-id="donorComponent"]')[0];
    }

    /**
     * @description Returns the Custom Field Child Component instance
     * @return rd2EntryFormCustomFieldsSection component dom
     */
    get customFieldsComponent() {
        return this.template.querySelectorAll('[data-id="customFieldsComponent"]')[0];
    }

    /**
     * @description Returns the Credit Card Child Component instance
     * @returns rd2ElevateCreditCardForm component dom
     */
    get creditCardComponent() {
        return this.template.querySelector('[data-id="elevateWidget"]');
    }

    /**
     * @description Returns the save button element
     */
    get saveButton() {
        return this.template.querySelector("[data-id='submitButton']");
    }

    get originalPaymentMethod() {
        return this.rd2State.initialViewState.paymentMethod;
    }

    get isEdit() {
        return !!this.rd2State.initialViewState.recordId;
    }

    /***
     * @description Collects fields displayed on the form and any integrated LWC
     */
    getAllFields() {
        const donorFields = isNull(this.donorComponent) ? {} : this.donorComponent.returnValues();

        const scheduleFields = isNull(this.scheduleComponent) ? {} : this.scheduleComponent.returnValues();

        const customFields = isNull(this.customFieldsComponent) ? {} : this.customFieldsComponent.returnValues();

        const paymentMethod = {
            [FIELD_PAYMENT_METHOD.fieldApiName]: this.rd2State.paymentMethod,
        };

        return { ...scheduleFields, ...donorFields, ...customFields, ...paymentMethod, ...this.returnValues() };
    }

    isPaymentMethodChanged() {
        return this.rd2Service.isPaymentMethodChanged(this.rd2State);
    }

    /***
     * @description Validate all fields on the integrated LWC sections
     */
    isFormValid() {
        const isDonorSectionValid = isNull(this.donorComponent) ? true : this.donorComponent.isValid();

        const isScheduleSectionValid = isNull(this.scheduleComponent) ? true : this.scheduleComponent.isValid();

        const isCustomFieldSectionValid = isNull(this.customFieldsComponent)
            ? true
            : this.customFieldsComponent.isValid();

        const isEntryFormValid = this.isValid();

        return isDonorSectionValid && isScheduleSectionValid && isCustomFieldSectionValid && isEntryFormValid;
    }

    /**
     * @description Checks if values specified on fields are valid
     * @return Boolean
     */
    isValid() {
        let isValid = true;

        this.template.querySelectorAll("lightning-input-field").forEach((field) => {
            if (!field.reportValidity()) {
                isValid = false;
            }
        });

        return isValid;
    }

    /**
     * @description Returns fields displayed on the parent form
     * @return Object containing field API names and their values
     */
    returnValues() {
        let data = {};
        const inputFields = this.template.querySelectorAll("lightning-input-field");

        inputFields.forEach((field) => {
            data[field.fieldName] = field.value;
        });

        return data;
    }

    /**
     * @description Close the modal when Escape key is pressed
     */
    handleKeyUp(event) {
        if (event.keyCode === 27 || event.code === "Escape") {
            this.handleCancel();
        }
    }

    /**
     * @description Trap focus onto the modal when the focus reaches the top
     */
    handleClosedButtonTrapFocus(event) {
        if (event.shiftKey && event.code === "Tab") {
            event.stopPropagation();
            this.template.querySelector('[data-id="submitButton"]').focus();
        }
    }

    /**
     * @description Trap focus onto the modal when the focus reaches the end
     */
    handleSaveButtonTrapFocus(event) {
        if (event.code === "Tab") {
            event.stopPropagation();
            this.template.querySelector('[data-id="closeButton"]').focus();
        }
    }
}
