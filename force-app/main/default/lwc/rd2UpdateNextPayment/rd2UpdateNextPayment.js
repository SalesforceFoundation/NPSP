import { LightningElement, api, track } from 'lwc';
import { showToast, constructErrorMessage, isNull } from 'c/utilCommon';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getNumberAsLocalizedCurrency } from 'c/utilNumberFormatter';

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
import savePause from '@salesforce/apex/RD2_PauseForm_CTRL.savePause';

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

    @track isLoading = true;
    @track permissions = {
        hasAccess: false,
        isBlocked: false,
        blockedReason: ''
    };
    @track isSaveDisplayed;
    @track isSaveDisabled = false;
    @track pageHeader = '';
    @track nextPaymentAmount;
    validAmount = false;

    @track columns = [];
    @track installments = [];

    numberOfInstallments = 12;
    maxRowDisplay = 1;
    @track changeInstallmentSummary = '';

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
            await this.loadPauseData();
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
                console.log(response); 

                // TODO: Set nextPaymentAmount if its entered

                this.handleRecords(response);
                this.handleColumns(response);
            })
            .catch(error => {
                this.installments = null;

                if (this.permissions.isBlocked !== true && this.permissions.hasAccess !== false) {
                    this.handleError(error);
                }
            });
            // .finally(() => {
            //     this.isLoading = false;
            //     this.handleButtonsDisplay();
            // });
    }

    /***
    * @description Load active current/future Pause.
    * Sets Paused Reason field.
    * If the user does not have permission to create/edit RD, then pause details are not rendered.
    */
    loadPauseData = async () => {
        // TODO: Update this to a new call?
        getPauseData({ rdId: this.recordId })
            .then(response => {
                const pauseData = JSON.parse(response);
                this.permissions.hasAccess = pauseData.hasAccess;
                this.permissions.isBlocked = pauseData.isRDClosed;
                if (!this.permissions.hasAccess) {
                    this.error.detail = this.labels.permissionRequired;
                    this.handleErrorDisplay();
                } else {
                    this.pausedReason = pauseData.pausedReason;
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
            console.log(response.dataTable.records); 
            
            for (let i in response.dataTable.records) {
                if (!response.dataTable.records[i].isSkipped) {
                    this.donationDate = response.dataTable.records[i].donationDate;
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
                    console.log(tempColumns[i]); 
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

        // TODO: Figure out if this is needed
        // this.refreshSaveButton();
    }

    /***
     * @description Rechecks if the [Save] button should be displayed
     */
    // refreshSaveButton() {
    //     this.isSaveDisabled = !this.validAmount;
    // }

    /***
    * @description Save pause: Inserts new pause (if any) and deactivates the old one.
    */
    handleSave() {
        this.clearError();

        const pausedReasonField = this.template.querySelector("[data-id='pausedReason']");
        if (pausedReasonField && !pausedReasonField.reportValidity()) {
            return;
        }

        this.isLoading = true;
        try {
            // TODO: Need to call RD2 Entry Form Method from here
            const jsonData = JSON.stringify(this.constructNextPaymentAmountData());

            savePause({ jsonPauseData: jsonData })
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
    * @description Displays message that the pause save has been successful
    * and closes the modal.
    */
    handleSaveSuccess() {
        const message = this.labels.changeNextInstallmentSuccess;
        showToast(message, '', 'success', []);

        this.dispatchEvent( new CloseActionScreenEvent() );
    }

    /***
    * @description Records the latest Paused Reason value
    * and checks if the [Save] button should be enabled.
    */
    handleNextPaymentAmountChange(event) {
        this.nextPaymentAmount = event.detail.value;
        const nextPaymentAmountField = this.template.querySelector("[data-id='nextPaymentAmount']");
        if (isNull(this.nextPaymentAmount) || this.nextPaymentAmount < 0) {
            nextPaymentAmountField.setCustomValidity(this.labels.newInstallmentAmountValidation);
            this.isSaveDisabled = true;
            this.changeInstallmentSummary = '';
        } else {
            nextPaymentAmountField.reportValidity();
            this.isSaveDisabled = false;

            // TODO Figure out how to keep this in its timezone
            // new Date defaults to UTC, but local Date converts it
            // Are there Utils out there?
            let dateString = new Date(this.donationDate).toLocaleDateString();
            let currencyAmount = getNumberAsLocalizedCurrency(this.nextPaymentAmount);
            this.changeInstallmentSummary = 
                this.labels.newInstallmentConfirmation.replace('{0}', dateString)
                .replace('{1}', currencyAmount);
        }

        // this.refreshSaveButton();
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