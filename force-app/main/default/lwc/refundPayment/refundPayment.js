import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import { constructErrorMessage, showToast} from "c/utilCommon";
import refundPaymentTitle from "@salesforce/label/c.pmtRefundPaymentTitle";
import refundAmountField from "@salesforce/label/c.pmtRefundAmount";
import remainingBalance from "@salesforce/label/c.pmtRemainingBalance";
import refundPaymentDate from "@salesforce/label/c.pmtRefundPaymentDate";
import refundPaymentConfirmButton from "@salesforce/label/c.pmtRefundPaymentConfirmedButton";
import cancelButtonLabel from "@salesforce/label/c.stgBtnCancel";
import commonRefreshPage from "@salesforce/label/c.commonRefreshPage";
import noRefundPermissionMessage from "@salesforce/label/c.pmtNoRefundPermissionMessage";
import refundAllocationHelpText from "@salesforce/label/c.pmtRefundAllocationHelpText";
import refundPaymentErrorMessage from "@salesforce/label/c.pmtRefundPaymentErrorMessage";
import refundPaymentSuccessMessage from "@salesforce/label/c.pmtRefundPaymentSuccessMessage";
import refundPaymentMessage from "@salesforce/label/c.pmtRefundPaymentMessage";
import refundProcessing from "@salesforce/label/c.pmtRefundProcessing";
import loadingMessage from "@salesforce/label/c.labelMessageLoading";
import spinnerAltText from "@salesforce/label/c.geAssistiveSpinner";
import getInitialView from "@salesforce/apex/PMT_RefundController.getInitialView";
import processRefund from "@salesforce/apex/PMT_RefundController.processRefund";

export default class refundPayment extends NavigationMixin(LightningElement) {
    _recordId;
    hasError = false;
    isLoading = false;
    errorMessage;
    labels = Object.freeze({
        refundPaymentTitle,
        refundPaymentConfirmButton,
        cancelButtonLabel,
        commonRefreshPage,
        noRefundPermissionMessage,
        refundAllocationHelpText,
        refundPaymentMessage,
        refundAmountField,
        refundPaymentDate,
        refundProcessing,
        refundPaymentErrorMessage,
        refundPaymentSuccessMessage,
        remainingBalance,
        loadingMessage,
        spinnerAltText
    });
    refundView;
    refundAmount;
    remainingBalance;
    paymentDate;
    currencyCode;

    @api set recordId(value) {
        this._recordId = value;
        this.isLoading = true;
        getInitialView({
            paymentId: this.recordId
        }) 
            .then((response) => {
                if (response.hasRequiredPermissions === false) {
                    this.displayErrorMessage(this.labels.noRefundPermissionMessage);
                    return;
                }
                this.remainingBalance = response.remainingBalance;
                this.refundAmount = response.refundAmount;
                this.paymentDate = response.paymentDate;
                this.currencyCode = response.currencyCode;
                this.isLoading = false;
        })
        .catch((error) => {
            this.displayErrorMessage(constructErrorMessage(error).detail);
        });
    }

    get recordId() {
        return this._recordId;
    }

    handleRefund() {
        this.isLoading = true;
        processRefund({
            paymentId: this.recordId,
            refundAmount: this.refundAmount
        }) 
            .then((response) => {
                this.processResponse(response);
                this.isLoading = false;
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
    }
}