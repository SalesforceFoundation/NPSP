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
import gsApplicationStatusModalHeader from '@salesforce/label/c.gsApplicationStatusModalHeader'
import gsClose from '@salesforce/label/c.gsClose'
import gsFollowUpApplicationStatus from '@salesforce/label/c.gsFollowUpApplicationStatus'
export default class GsApplicationStatus extends LightningElement {
    
    @track errorMessage = "";
    @track diffInDays = null;
    @track isApplicationSubmitted = false;
    @track isLoading = false;

    labels = {
        gsNoApplicationSubmitted,
        gsLearnMore,
        gsDaysRemainingInFreeTrial,
        gsApplyForFreeLicenses,
        gsApplicationStatus,
        gsSubmitted,
        gsDaysAdded,
        gsCheckStatus,
        gsApplicationStatusModalHeader,
        gsClose,
        gsFollowUpApplicationStatus
    }
    
    connectedCallback() {
        this.showSpinner();

        getApplicationStatus()
        .then(result => {
            this.diffInDays = this.calculateDiffDays(result);
            this.isApplicationSubmitted = this.checkApplicationSubmitted(result); 
            this.hideSpinner();
        })
        .catch(error => {
            this.errorMessage = error;
            this.hideSpinner();
        });
    }

    showSpinner() {
        this.isLoading = true;
    }

    hideSpinner() {
        this.isLoading = false;
    }
    calculateDiffDays(result) {
        const date = new Date(result.trialExpirationDate)
        const oneDay = 24 * 60 * 60 * 1000
        const today = new Date();
        return Math.ceil(Math.abs(date - today)/oneDay);
    }

    checkApplicationSubmitted(result) {
        return result.applicationDate != null;
    }

    onCheckStatusClick() {
        this.template.querySelector("c-gs-modal").openModal();
    }
}