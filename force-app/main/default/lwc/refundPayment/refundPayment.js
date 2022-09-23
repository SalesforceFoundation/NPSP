import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import { constructErrorMessage, showToast} from "c/utilCommon";
import refundPaymentTitle from "@salesforce/label/c.pmtRefundPaymentTitle";
import refundAmountField from "@salesforce/label/c.pmtRefundAmount";
import remainingBalance from "@salesforce/label/c.pmtRemainingBalance";
import refundPaymentConfirmButton from "@salesforce/label/c.pmtRefundPaymentConfirmedButton";
import cancelButtonLabel from "@salesforce/label/c.stgBtnCancel";
import commonRefreshPage from "@salesforce/label/c.commonRefreshPage";
import noRefundPermissionMessage from "@salesforce/label/c.pmtNoRefundPermissionMessage";
import refundAllocationHelpText from "@salesforce/label/c.pmtRefundAllocationHelpText";
import refundPaymentErrorMessage from "@salesforce/label/c.pmtRefundPaymentErrorMessage";
import refundPaymentSuccessMessage from "@salesforce/label/c.pmtRefundPaymentSuccessMessage";
import refundAmountTooLow from "@salesforce/label/c.pmtRefundAmountTooLow";
import refundAmountTooHigh from "@salesforce/label/c.pmtRefundAmountTooHigh";
import refundProcessing from "@salesforce/label/c.pmtRefundProcessing";
import loadingMessage from "@salesforce/label/c.labelMessageLoading";
import spinnerAltText from "@salesforce/label/c.geAssistiveSpinner";
import getInitialView from "@salesforce/apex/PMT_RefundController.getInitialView";
import processRefund from "@salesforce/apex/PMT_RefundController.processRefund";

export default class refundPayment extends NavigationMixin(LightningElement) {
    _recordId;
    hasError = false;
    isLoading = false;
    isSaveDisabled = false;
    errorMessage;
    labels = Object.freeze({
        refundPaymentTitle,
        refundPaymentConfirmButton,
        cancelButtonLabel,
        commonRefreshPage,
        noRefundPermissionMessage,
        refundAllocationHelpText,
        refundAmountField,
        refundProcessing,
        refundPaymentErrorMessage,
        refundPaymentSuccessMessage,
        refundAmountTooLow,
        remainingBalance,
        loadingMessage,
        spinnerAltText
    });
    refundView;
    refundAmount;
    remainingBalance;
    currencyCode;

    @api set recordId(value) {
        this._recordId = value;
        this.isLoading = true;
        this.isSaveDisabled = this.isLoading;
        getInitialView({
            paymentId: this.recordId
        }) 
            .then((response) => {
                if (response.hasRequiredPermissions === false) {
                    this.displayErrorMessage(this.labels.noRefundPermissionMessage);
                    return;
                }
                this.remainingBalance = response.remainingBalance;
                this.refundAmount = response.remainingBalance;
                this.currencyCode = response.currencyCode;
                this.isLoading = false;
                this.isSaveDisabled = this.isLoading;

        })
        .catch((error) => {
            this.displayErrorMessage(constructErrorMessage(error).detail);
        });
    }

    get recordId() {
        return this._recordId;
    }

    get refundAmountTooHighErrorString() {
        return refundAmountTooHigh.replace('{{AMOUNT}}', this.remainingBalance);
    }

    handleRefund() {
        this.isLoading = true;
        this.isSaveDisabled = this.isLoading;
        processRefund({
            paymentId: this.recordId,
            refundAmount: this.refundAmount
        }) 
            .then((response) => {
                this.processResponse(response);
                this.isLoading = false;
                this.isSaveDisabled = this.isLoading;
        })
        .catch((error) => {
            this.displayErrorMessage(constructErrorMessage(error).detail);
        });
    }

    handleClose(){
        this.dispatchEvent( new CloseActionScreenEvent() );
    }

    handleRefundAmountChanged(event) {
        this.refundAmount = event.detail.value;
        this.isSaveDisabled = !this.refundAmountInputField().reportValidity();
    }

    processResponse(response) {
        if (response.hasRequiredPermissions === false) {
            this.displayErrorMessage(this.labels.noRefundPermissionMessage);
            return;

        } else if (response.isSuccess === true) {
            if (this.recordId === response.redirectToPaymentId) {
                showToast('', this.labels.refundProcessing, 'success', 'sticky');
            } else {
                showToast('', this.labels.refundPaymentSuccessMessage, 'success', 'dismissible');
                this.navigateToRecordPage(response.redirectToPaymentId);
            }

        } else if (response.isSuccess === false) {
            showToast(this.labels.refundPaymentErrorMessage, response.errorMessage, 'error', 'sticky');
        }
        
        this.handleClose();
    }

    navigateToRecordPage(rediectToId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: rediectToId,
                actionName: 'view'
            }
        });
}

    displayErrorMessage(errorMessage) {
        this.hasError = true;
        this.errorMessage = errorMessage;
        this.isLoading = false;
        this.isSaveDisabled = this.isLoading;
    }

    refundAmountInputField() {
        return this.template.querySelector("lightning-input[data-id=RefundAmountInput]");
    }
}