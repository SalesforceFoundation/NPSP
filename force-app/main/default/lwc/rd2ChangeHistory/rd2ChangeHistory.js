import { LightningElement, api, track } from 'lwc';
import getChangeHistory from '@salesforce/apex/RD2_ChangeHistoryController.getChangeHistory'
export default class Rd2ChangeHistory extends LightningElement {
    @api recordId;
    @api changeTypeFilter;
    @api recordLimit;

    @track changeHistory;

    errorMessage;
    isReady = false;
    hasError = false;

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

    get serializedChangeHistory() {
        if(this.changeHistory !== null && this.changeHistory !== undefined) {
            return JSON.stringify(this.changeHistory, null, 2);
        }
        return 'Loading...';
    }

    get fakeChangeEntry() {
        return {
            "changeDate": "2021-08-05",
            "fields": [
                {
                    "displayType": "MONEY",
                    "label": "Amount",
                    "oldValue": 72
                },
                {
                    "displayType": "MONEY",
                    "label": "Annual Value",
                    "oldValue": 72
                },
                {
                    "displayType": "LOOKUP",
                    "label": "Campaign",
                    "newId": "701P0000000a2PHIAY",
                    "newValue": "First Campaign"
                }
            ]
        }
    }
}