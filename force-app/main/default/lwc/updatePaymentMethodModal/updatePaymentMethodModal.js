import { LightningElement, track, api } from 'lwc';

export default class UpdatePaymentMethodModal extends LightningElement {
    @track open = false;

    @api 
    openmodal() {
        this.open = true
    }

    closeModal() {
        this.open = false
    } 
}