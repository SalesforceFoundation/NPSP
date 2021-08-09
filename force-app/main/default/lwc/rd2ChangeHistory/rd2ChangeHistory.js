import { LightningElement, api, track, wire } from 'lwc';
import getChangeHistory from '@salesforce/apex/RD2_ChangeHistoryController.getChangeHistory'
import { NavigationMixin } from 'lightning/navigation';

import commonViewMore from '@salesforce/label/c.commonViewMore';
import commonError from '@salesforce/label/c.commonError';
import rdchDisabled from '@salesforce/label/c.RDCH_Disabled';
import rdchChangeHistory from '@salesforce/label/c.RDCH_Change_History';
import rdchNoRecords from '@salesforce/label/c.RDCH_No_Records';

const STATES = {
    LOADING: 'LOADING',
    READY: 'READY',
    ERROR: 'ERROR',
    SETTING_DISABLED: 'SETTING_DISABLED',
    EMPTY_LIST: 'EMPTY_LIST'
};

export default class Rd2ChangeHistory extends NavigationMixin(LightningElement) {
    @api recordId;
    @api changeTypeFilter;
    @api recordLimit;

    @track changeHistory;

    displayState = STATES.LOADING;
    errorMessage;

    labels = {
        commonError,
        commonViewMore,
        rdchDisabled,
        rdchChangeHistory,
        rdchNoRecords
    };

    async connectedCallback() {
        const { recordId, changeTypeFilter, recordLimit } = this;
        try {
            this.changeHistory = await getChangeHistory({ recurringDonationId: recordId, changeTypeFilter, recordLimit });
            this.displayState = this.changeHistory.settingEnabled ? STATES.READY : STATES.SETTING_DISABLED;
        } catch (ex) {
            this.displayState = STATES.ERROR;
            this.errorMessage = ex.body.message;
        }
    }

    get isSettingDisabled() {
        return this.displayState === STATES.SETTING_DISABLED;
    }

    get hasChanges() {
        return this.displayState === STATES.READY
            && this.changeHistory.changes.length > 0
            && this.changeHistory.hasMore === false;
    }

    get hasMoreChanges() {
        return this.displayState === STATES.READY
            && this.changeHistory.changes.length > 0
            && this.changeHistory.hasMore === true;
    }

    get hasEmptyList() {
        return this.displayState === STATES.READY && this.changeHistory.changes.length === 0;
    }

    get isLoading() {
        return this.displayState === STATES.LOADING;
    }

    get hasError() {
        return this.displayState === STATES.ERROR;
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