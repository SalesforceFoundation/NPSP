import { LightningElement, api, track } from 'lwc';
import getHardCreditDonorsFor 
    from '@salesforce/apex/DonorService.getHardCreditDonorsFor';


export default class OppDonationAttribution extends LightningElement {

    @api recordId;
    
    @track donors = []; 

    async connectedCallback() {
        this.donors = await getHardCreditDonorsFor(this.recordId);
    }

    get displayText() {
        if(this.donors.length > 0) {
            return this.donors[0].fullName;
        } else {
            return 'Not Found';
        }
    }
}