import { LightningElement, api } from 'lwc';
import PaymentInformationTitle from '@salesforce/label/c.PaymentInformation';
import cancelButtonLabel from '@salesforce/label/c.stgBtnCancel';
import saveButtonLabel from '@salesforce/label/c.stgBtnSave';

export default class Rd2EditCreditCardModal extends LightningElement {
    @api nextDonationDate;



    labels = Object.freeze({
        PaymentInformationTitle,
        cancelButtonLabel,
        saveButtonLabel
    });

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }
    handleClosedButtonTrapFocus() {

    }
    handleSaveButtonTrapFocus() {

    }
}