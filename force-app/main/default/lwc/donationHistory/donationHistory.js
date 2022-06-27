import { LightningElement, api } from 'lwc';

export default class DonationHistory extends LightningElement {
    @api recordId;

    filter;

    handleFilterChange(event) {
        this.filter = event.detail;
    }
}