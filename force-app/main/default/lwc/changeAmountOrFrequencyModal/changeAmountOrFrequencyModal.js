import { LightningElement, api } from 'lwc';
import changeAmountOrFrequency from '@salesforce/label/c.changeAmountOrFrequency';
import updateRecurringDonation from '@salesforce/label/c.updateRecurringDonation';
export default class ChangeAmountOrFrequencyModal extends LightningElement {
    @api openChangeAmountOrFrequency;

    labels = {
        changeAmountOrFrequency,
        updateRecurringDonation
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('close', {detail: 'changeAmountOrFrequency'}));
    } 
}