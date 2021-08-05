import { LightningElement, api, track } from 'lwc';
import getChangeHistory from '@salesforce/apex/RD2_ChangeHistoryController.getChangeHistory'
export default class Rd2ChangeHistory extends LightningElement {
    @api recordId;
    @api changeTypeFilter;
    @api recordLimit;

    @track changeHistory;

    errorMessage;
    hasError = false;

    async connectedCallback() {
        const { recordId, changeTypeFilter, recordLimit } = this;
        try {
            this.changeHistory = await getChangeHistory({recordId, changeTypeFilter, recordLimit});
        } catch (ex) {
            this.hasError = true;
            this.errorMessage = ex.message;
        }
    }

    get serializedChangeHistory() {
        if(this.changeHistory !== null && this.changeHistory !== undefined) {
            return JSON.stringify(this.changeHistory, null, 2);
        } else {
            return 'Loading...'
        }
    }
}