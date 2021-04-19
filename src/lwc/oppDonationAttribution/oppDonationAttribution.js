import { LightningElement, api } from 'lwc';

export default class OppDonationAttribution extends LightningElement {

    @api recordId;

    get displayText() {
        return 'Tess Testerson';
    }
}