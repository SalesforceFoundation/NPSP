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

    get hasSoftCredits() {
        return this.softCredits && this.softCredits.length > 0;
    }

    @wire(getHardCreditDonorsFor, { opportunityId: '$recordId' }) 
    wiredDonors({data, error}) {
        if (data) {
            this.donors = this.generateDonationIcon(data);

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
            this.softCredits = this.generateDonationIcon(data);
        } else if (error) {
            this.error = 'Unknown error';
            if (Array.isArray(error.body)) {
                this.error = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                this.error = error.body.message;
            }
        }
    };

    generateDonationIcon(records) {
        let updatedRecords = [];
        
        for (let i = 0; i < records.length; i++) {
            updatedRecords.push(Object.assign({}, records[i], { selectable: false }));
        }

        updatedRecords.map(record => {
            let iconName = 'standard:contact';
            if (record.donorType === 'HOUSEHOLD') {
                iconName = 'standard:household';
            }

            record.iconName = iconName;
        });

        return updatedRecords;
    }

}