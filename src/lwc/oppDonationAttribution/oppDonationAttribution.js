import { LightningElement, api, track, wire } from 'lwc';
import getHardCreditDonorsFor 
    from '@salesforce/apex/DonorService.getHardCreditDonorsFor';


export default class OppDonationAttribution extends LightningElement {

    @api recordId;
    
    @track donors = []; 
    donorNames = '';
    error;

    @wire(getHardCreditDonorsFor, { opportunityId: '$recordId' }) 
    wiredDonors({data, error}) {
        if (data) {
            this.donorNames = data;
        } else if (error) {
            this.error = 'Unknown error';
            if (Array.isArray(error.body)) {
                this.error = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                this.error = error.body.message;
            }
        }
    };

    /***
    async connectedCallback() {
        this.donorNames = await getHardCreditDonorsFor({ recordId: this.recordId });
    }
    get displayText() {
        if(this.donorNames) {
            return this.donorNames;
        } else {
            return 'Not Found';
        }
    }
    */
}