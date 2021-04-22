import { LightningElement, api, wire, track } from 'lwc';
import getHardCreditDonorsFor 
    from '@salesforce/apex/DonorService.getHardCreditDonorsFor';
import getSoftCreditDonorsFor 
    from '@salesforce/apex/DonorService.getSoftCreditDonorsFor';

export default class OppDonationAttribution extends LightningElement {

    @api recordId;
    
    @track donors = [];
    @track softCredits = []; 
    donorNames = '';
    error;

    @wire(getHardCreditDonorsFor, { opportunityId: '$recordId' }) 
    wiredDonors({data, error}) {
        if (data) {
            for (let i = 0; i < data.length; i++) {
                this.donors.push(Object.assign({}, data[i], {selectable: false}));
            }
            
            this.donors.map(donor => {
                let iconName = 'standard:contact';
                if (donor.donorType === 'HOUSEHOLD') {
                    iconName = 'standard:household';
                }

                donor.iconName = iconName;
            });

            if(this.donors.length > 0) {
                this.donorNames = this.donors[0].fullName;
            }
        } else if (error) {
            this.error = 'Unknown error';
            if (Array.isArray(error.body)) {
                this.error = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                this.error = error.body.message;
            }
        }
    };

    @wire(getSoftCreditDonorsFor, { opportunityId: '$recordId' }) 
    wiredSoftCredit({data, error}) {
        if (data) {
            this.softCredits = data;
        } else if (error) {
            this.error = 'Unknown error';
            if (Array.isArray(error.body)) {
                this.error = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                this.error = error.body.message;
            }
        }
    };
}