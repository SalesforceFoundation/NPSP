import { LightningElement, api, track } from 'lwc';

export default class StopRecurringDonationModal extends LightningElement {
    @track open = false;

    @api 
    openmodal() {
        this.open = true
    }

    closeModal() {
        this.open = false
    } 
}