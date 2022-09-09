import { LightningElement, api, track } from 'lwc';
import { showToast, constructErrorMessage, isEmpty } from 'c/utilCommon';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getNumberAsLocalizedCurrency, getDateAsLocalizedFormat } from 'c/utilNumberFormatter';
import { Rd2Service } from "c/rd2Service";

import header from '@salesforce/label/c.RD2_PauseHeader';
import description from '@salesforce/label/c.RD2_PauseDescription';
import loadingMessage from '@salesforce/label/c.labelMessageLoading';
import cancelButton from '@salesforce/label/c.stgBtnCancel';
import saveButton from '@salesforce/label/c.stgBtnSave';
import okButton from '@salesforce/label/c.stgLabelOK';
import firstDonationDateMessage from '@salesforce/label/c.RD2_PauseFirstDonationDateDynamicText';
import saveSuccessMessage from '@salesforce/label/c.RD2_PauseSaveSuccessMessage';
import deactivationSuccessMessage from '@salesforce/label/c.RD2_PauseDeactivationSuccessMessage';
import rdClosedMessage from '@salesforce/label/c.RD2_PauseClosedRDErrorMessage';
import elevateNotSupported from '@salesforce/label/c.RD2_ElevateNotSupported';
import permissionRequired from '@salesforce/label/c.RD2_PausePermissionRequired';
import insufficientPermissions from '@salesforce/label/c.commonInsufficientPermissions';

import changeNextInstallmentAmount from '@salesforce/label/c.RD2_ChangeNextInstallmentAmount';
import nextInstallment from '@salesforce/label/c.RD2_NextInstallment';
import dateColumnHeader from '@salesforce/label/c.RD2_ScheduleVisualizerColumnDate';
import amountColumnHeader from '@salesforce/label/c.commonAmount';
import paymentMethodColumnHeader from '@salesforce/label/c.RD2_Payment_Method';
import newInstallmentAmountLabel from '@salesforce/label/c.RD2_NewInstallmentAmount';
import newInstallmentAmountHelp from '@salesforce/label/c.RD2_NewInstallmentAmountHelp';
import newInstallmentConfirmation from '@salesforce/label/c.RD2_NewInstallmentConfirmation';
import newInstallmentAmountValidation from '@salesforce/label/c.RD2_NewInstallmentAmountValidation';
import changeNextInstallmentSuccess from '@salesforce/label/c.RD2_ChangeNextInstallmentSuccess';

import getPauseData from '@salesforce/apex/RD2_PauseForm_CTRL.getPauseData';
import getInstallments from '@salesforce/apex/RD2_PauseForm_CTRL.getInstallments';
import handleNextPaymentAmount from '@salesforce/apex/RD2_EntryFormController.handleNextPaymentAmount';

export default class Rd2UpdateNextPayment extends LightningElement {

    labels = Object.freeze({
        header,
        description,
        loadingMessage,
        cancelButton,
        elevateNotSupported,
        saveButton,
        okButton,
        saveSuccessMessage,
        deactivationSuccessMessage,
        rdClosedMessage,
        firstDonationDateMessage,
        permissionRequired,
        insufficientPermissions,
        changeNextInstallmentAmount,
        nextInstallment,
        dateColumnHeader,
        amountColumnHeader,
        paymentMethodColumnHeader,
        newInstallmentAmountLabel,
        newInstallmentAmountHelp,
        newInstallmentConfirmation,
        newInstallmentAmountValidation,
        changeNextInstallmentSuccess
    });

    _recordId;
    recordName;
    donationDate;
    isElevateRecord = false;
    paymentToken;

    @track isLoading = true;
    @track permissions = {
        hasAccess: false,
        isBlocked: false,
        blockedReason: ''
    };
    @track isSaveDisplayed;
    @track isSaveDisabled = true;
    @track pageHeader = '';
    @track nextPaymentAmount;
    validAmount = false;

    @track columns = [];
    @track installments = [];

    numberOfInstallments = 12;
    maxRowDisplay = 1;
    @track changeInstallmentSummary = '';

    rd2Service = new Rd2Service();
    @track error = {};

    @api set recordId(value) {
        this._recordId = value;
        this.isLoading = true;
        this.init();
    }

    get recordId() {
        return this._recordId;
    }

    /***
    * @description Groups various calls to Apex:
    * - Loads installments
    * - Waits for latest pause data (if any) and initializes the Paused Reason
    */
    init = async () => {
        try {
            this.loadInstallments();
            await this.loadDonationData();
        } catch (error) {
            this.handleError(error);
        }
    }

    /***
    * @description Loads installments and sets datatable columns and records.
    * If the user does not have permission to create/edit RD, then installments are not rendered.
    */
    loadInstallments = async () => {
        getInstallments({ recordId: this.recordId, numberOfInstallments: this.numberOfInstallments })
            .then(response => {
                this.handleRecords(response);
                this.handleColumns(response);
            })
            .catch(error => {
                this.installments = null;

                if (this.permissions.isBlocked !== true && this.permissions.hasAccess !== false) {
                    this.handleError(error);
                }
            });
    }

    /***
    * @description Load active current/future Pause.
    * Sets Paused Reason field.
    * If the user does not have permission to create/edit RD, then pause details are not rendered.
    */
    loadDonationData = async () => {
        getPauseData({ rdId: this.recordId })
            .then(response => {
                const donationData = JSON.parse(response);
                this.permissions.hasAccess = donationData.hasAccess;
                this.permissions.isBlocked = donationData.isRDClosed;
                this.isElevateRecord = donationData.isElevateRecord;
                if (!this.permissions.hasAccess) {
                    this.error.detail = this.labels.permissionRequired;
                    this.handleErrorDisplay();
                }

                if (this.permissions.isBlocked) {
                    this.permissions.blockedReason = this.labels.rdClosedMessage;
                }
            })
            .catch(error => {
                this.handleError(error);
            })
            .finally(() => {
                this.isLoading = false;
                this.handleButtonsDisplay();
            });
    }

    /***
     * @description Sets installment datatable records
     */
    handleRecords(response) {
        if (response && response.dataTable) {
            this.installments = [];
            for (let i in response.dataTable.records) {
                if (!response.dataTable.records[i].isSkipped) {
                    this.donationDate = response.dataTable.records[i].donationDate;
                    this.nextPaymentAmount = response.dataTable.records[i].nextPaymentAmount;
                    this.installments.push(response.dataTable.records[i]);
                    break;
                }
            }
        }
    }

    /***
     * @description Sets installment datatable columns
     */
    handleColumns(response) {
        if (response && response.dataTable) {
            let tempColumns = response.dataTable.columns;
            this.columns = [];

            for (let i = 0; i < tempColumns.length; i++) {
                if (tempColumns[i].fieldName !== "pauseStatus") {
                    this.columns.push(tempColumns[i]);
                }
            }
        }
    }

    /***
    * @description Handles button display. In the case of permission, field visibility
    * or RD closed error, [OK] button is displayed and [Save] button is not displayed.
    */
    handleButtonsDisplay() {
        this.isSaveDisplayed = !this.isLoading && this.permissions.hasAccess && !this.permissions.isBlocked;

        // Disable data display and Save button when installments are not returned
        if (this.installments == null && this.isSaveDisplayed) {
            this.isSaveDisplayed = false;
            this.hasAccess = false;
        }
    }

    /***
    * @description Save Next Payment Amount: Updates Schedule with Next Payment Amount
    */
    handleSave() {
        this.clearError();
        this.isLoading = true;
        if (this.isElevateRecord) {
            console.log('Get Token'); 
            this.prepareCommitmentSubmit();
        } else {
            this.handleSubmit();
        }
    }

    async prepareCommitmentSubmit() {
        const elevateWidget = this.template.querySelector('[data-id="elevateWidget"]');
        this.paymentToken = await elevateWidget.returnToken().payload;

        console.log(this.paymentToken); 

        this.handleSubmit();
    }

    handleSubmit() {
        try {

            console.log(this.paymentToken); 

            handleNextPaymentAmount({
                rdId: this.recordId,
                nextPaymentAmount: this.nextPaymentAmount,
                paymentMethodToken: this.paymentToken
            })
                .then(() => {
                    this.handleSaveSuccess();
                })
                .catch((error) => {
                    this.handleError(error);
                });
        } catch (error) {
            this.handleError(error);
        }
    }

    /***
    * @description Displays message that the save has been successful
    * and closes the modal.
    */
    handleSaveSuccess() {
        const message = this.labels.changeNextInstallmentSuccess;
        showToast(message, '', 'success', []);

        this.dispatchEvent( new CloseActionScreenEvent() );
    }

    /***
    * @description Records the latest Next Payment Amount value
    * and checks if the [Save] button should be enabled.
    */
    handleNextPaymentAmountChange(event) {
        this.nextPaymentAmount = event.detail.value;
        const nextPaymentAmountField = this.template.querySelector("[data-id='nextPaymentAmount']");
        let validityMessage = '';
        if (isEmpty(this.nextPaymentAmount) || this.nextPaymentAmount < 0) {
            validityMessage = this.labels.newInstallmentAmountValidation;
            this.isSaveDisabled = true;
            this.changeInstallmentSummary = '';
        } else {
            this.isSaveDisabled = false;
            let dateString = getDateAsLocalizedFormat(this.donationDate);
            let currencyAmount = getNumberAsLocalizedCurrency(this.nextPaymentAmount);
            this.changeInstallmentSummary = 
                this.labels.newInstallmentConfirmation.replace('{0}', dateString)
                .replace('{1}', currencyAmount);
        }
        nextPaymentAmountField.setCustomValidity(validityMessage);
        nextPaymentAmountField.reportValidity();
    }

    /***
    * @description Closes the pause modal on save
    */
    handleCancel() {
        this.dispatchEvent( new CloseActionScreenEvent() );
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
        this.isLoading = false;

        this.error = constructErrorMessage(error);

        this.handleErrorDisplay();
    }


    /***
    * @description Handle component display when an error occurs
    * @param error: Error Event
    */
    handleErrorDisplay() {
        const errorDetail = this.error.detail;

        const isApexClassDisabled = errorDetail && errorDetail.includes("RD2_PauseForm_CTRL");
        if (isApexClassDisabled) {
            this.permissions.hasAccess = false;
        }

        if (errorDetail && this.permissions.hasAccess === false) {
            this.error.header = this.labels.insufficientPermissions;
        }

        this.template.querySelector(".slds-modal__header").scrollIntoView();
    }
}