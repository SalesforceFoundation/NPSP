import { LightningElement, track, wire } from 'lwc';
import getApplicationStatus from '@salesforce/apex/GS_ApplicationStatusController.getApplicationStatus'
export default class NonProfit_GetProduct extends LightningElement {
    
    @track errorMessage = "";
    @track diffInDays = null;
    connectedCallback() {
        getApplicationStatus()
        .then(result => {
            console.info(result.isSandbox);
            console.info(result.trialExpirationDate);

            this.diffInDays = this.calculateDiffDays(new Date(result.trialExpirationDate));
            
        })
        .catch(error => {
            this.errorMessage = error;
        });
    }

    calculateDiffDays(date) {
        const oneDay = 24 * 60 * 60 * 1000

        console.info("date", date);
        
        let today = new Date();
        console.info("today", today);
        return Math.ceil(Math.abs(date - today)/oneDay);
    }
}