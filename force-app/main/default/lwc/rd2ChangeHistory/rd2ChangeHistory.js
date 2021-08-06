import { LightningElement, api, track } from 'lwc';
import commonViewMore from '@salesforce/label/c.commonViewMore';
import getChangeHistory from '@salesforce/apex/RD2_ChangeHistoryController.getChangeHistory'
import { NavigationMixin } from 'lightning/navigation';

export default class Rd2ChangeHistory extends NavigationMixin(LightningElement) {
    @api recordId;
    @api changeTypeFilter;
    @api recordLimit;

    @track changeHistory;

    errorMessage;
    isReady = false;
    hasError = false;

    labels = { commonViewMore };

    async connectedCallback() {
        const { recordId, changeTypeFilter, recordLimit } = this;
        try {
            this.changeHistory = await getChangeHistory({recordId, changeTypeFilter, recordLimit});
            this.isReady = true;
        } catch (ex) {
            this.hasError = true;
            this.errorMessage = ex.message;
        }
    }

    navigateToRelatedList() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'npe03__Recurring_Donation__c',
                relationshipApiName: 'RDChangeHistory__r',
                actionName: 'view'
            }
        });
    }
}