import { LightningElement, api, track } from 'lwc';
import getChangeLog from '@salesforce/apex/RD2_ChangeLogController.getChangeLog'
import { getCurrentNamespace } from 'c/utilCommon';
import { NavigationMixin } from 'lightning/navigation';

import commonViewMore from '@salesforce/label/c.commonViewMore';
import commonError from '@salesforce/label/c.commonError';
import rdclDisabled from '@salesforce/label/c.RDCL_Disabled';
import rdclChangeLog from '@salesforce/label/c.RDCL_Change_Log';
import rdclNoRecords from '@salesforce/label/c.RDCL_No_Records';
import rd2DisabledError from '@salesforce/label/c.RD2_ScheduleVisualizerErrorInvalidUsage';

const STATES = {
    LOADING: 'LOADING',
    READY: 'READY',
    ERROR: 'ERROR',
    SETTING_DISABLED: 'SETTING_DISABLED',
    RD2_DISABLED: 'RD2_DISABLED',
    EMPTY_LIST: 'EMPTY_LIST'
};

export default class Rd2ChangeLog extends NavigationMixin(LightningElement) {
    @api recordId;
    @api changeTypeFilter;
    @api recordLimit;

    @track changeLog;

    displayState = STATES.LOADING;
    errorMessage;

    labels = {
        commonError,
        commonViewMore,
        rdclDisabled,
        rdclChangeLog,
        rdclNoRecords,
        rd2DisabledError
    };

    async connectedCallback() {
        const { recordId, changeTypeFilter, recordLimit } = this;
        try {
            this.changeLog = await getChangeLog({
                recurringDonationId: recordId,
                changeTypeFilter,
                recordLimit
            });

            if (this.changeLog.rd2Enabled) {
                this.displayState = this.changeLog.settingEnabled ? STATES.READY : STATES.SETTING_DISABLED;
            } else {
                this.displayState = STATES.RD2_DISABLED;
            }

        } catch (ex) {
            this.displayState = STATES.ERROR;
            this.errorMessage = ex.body.message;
        }
    }

    get isSettingDisabled() {
        return this.displayState === STATES.SETTING_DISABLED;
    }

    get isRd2Disabled() {
        return this.displayState === STATES.RD2_DISABLED;
    }

    get hasChanges() {
        return this.displayState === STATES.READY
            && this.changeLog.changes.length > 0
            && this.changeLog.hasMore === false;
    }

    get hasMoreChanges() {
        return this.displayState === STATES.READY
            && this.changeLog.changes.length > 0
            && this.changeLog.hasMore === true;
    }

    get hasEmptyList() {
        return this.displayState === STATES.READY && this.changeLog.changes.length === 0;
    }

    get isLoading() {
        return this.displayState === STATES.LOADING;
    }

    get hasError() {
        return this.displayState === STATES.ERROR;
    }

    navigateToRelatedList() {
        const namespace = getCurrentNamespace();
        const relationshipField = 'RDChangeLog__r';
        const relationshipApiName = namespace ? `${namespace}__${relationshipField}` : relationshipField;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'npe03__Recurring_Donation__c',
                relationshipApiName,
                actionName: 'view'
            }
        });
    }
}