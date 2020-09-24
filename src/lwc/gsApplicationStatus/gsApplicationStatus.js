import { LightningElement, track, wire } from 'lwc';
import getApplicationStatus from '@salesforce/apex/GS_ApplicationStatusController.getApplicationStatus'
import gsNoApplicationSubmitted from '@salesforce/label/c.gsNoApplicationSubmitted'
import gsLearnMore from '@salesforce/label/c.gsLearnMore'
import gsDaysRemainingInFreeTrial from '@salesforce/label/c.gsDaysRemainingInFreeTrial'
import gsApplyForFreeLicenses from '@salesforce/label/c.gsApplyForFreeLicenses'
import gsApplicationStatus from '@salesforce/label/c.gsApplicationStatus'
import gsSubmitted from '@salesforce/label/c.gsSubmitted'
import gsDaysAdded from '@salesforce/label/c.gsDaysAdded'
import gsCheckStatus from '@salesforce/label/c.gsCheckStatus'
export default class NonProfit_GetProduct extends LightningElement {
    
    @track errorMessage = "";
    @track diffInDays = null;
    @track isApplicationSubmitted = false;

    labels = {
        gsNoApplicationSubmitted,
        gsLearnMore,
        gsDaysRemainingInFreeTrial,
        gsApplyForFreeLicenses,
        gsApplicationStatus,
        gsSubmitted,
        gsDaysAdded,
        gsCheckStatus
    }
    
    connectedCallback() {
        getApplicationStatus()
        .then(result => {
            console.info(result.isSandbox);
            console.info(result.trialExpirationDate);
            this.diffInDays = this.calculateDiffDays(new Date(result.trialExpirationDate));
            this.isApplicationSubmitted = true; 
            
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