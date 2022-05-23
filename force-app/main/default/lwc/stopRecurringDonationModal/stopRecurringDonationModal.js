import { LightningElement, api } from 'lwc';
import stopRecurringDonation from '@salesforce/label/c.stopRecurringDonation';
import stopRecurringDonationModalTitle from '@salesforce/label/c.stopRecurringDonationModalTitle';
export default class StopRecurringDonationModal extends LightningElement {

    labels = {
        stopRecurringDonation,
        stopRecurringDonationModalTitle
    }

    @api openStopRecurringDonation;

    closeModal() {
        this.dispatchEvent(new CustomEvent('close', {detail: 'stopRecurringDonation'}));
    } 
}