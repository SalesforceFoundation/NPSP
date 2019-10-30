import { LightningElement, api, track } from 'lwc';

import labelStatus from '@salesforce/label/c.BatchProgressStatus';
import labelTotalJobItems from '@salesforce/label/c.BatchProgressTotalJobItems';
import labelJobItemsProcessed from '@salesforce/label/c.BatchProgressJobItemsProcessed';
import labelTimeElapsed from '@salesforce/label/c.BatchProgressTimeElapsed';
import labelCompletedDate from '@salesforce/label/c.BatchProgressCompletedDate';
import labelExtendedStatus from '@salesforce/label/c.BatchProgressExtendedStatus';
import labelUnknownError from '@salesforce/label/c.stgUnknownError';

import loadBatchJob from '@salesforce/apex/UTIL_BatchJobProgress_CTRL.loadBatchJob';

export default class BatchProgress extends LightningElement {
    @api title;
    @api className;

    @track batchJob;

    pollingTimeout = 1000;
    labels = {
        labelStatus,
        labelTotalJobItems,
        labelJobItemsProcessed,
        labelTimeElapsed,
        labelCompletedDate,
        labelExtendedStatus
    };

    /***
    * @description Starts polling for the batch job details until the batch job is completed
    */
    @api
    refreshBatchJob() {
        var self = this;
        console.log('refreshBatchJob ');

        setTimeout(function () {
            loadBatchJob({ className: self.className })
                .then((data) => {
                    self.batchJob = JSON.parse(data);
                    console.log('Polling: ' + self.batchJob);

                    if (self.batchJob && self.batchJob.isInProgress === true) {
                        self.refreshBatchJob();
                    }
                })
                .catch((error) => {
                    self.handleError(error);
                });


        }, this.pollingTimeout, self);
    }

    get hasJobItems() {

        if (this.batchJob === undefined || this.batchJob == null) {
            return false;
        }

        return this.batchJob.totalJobItems > 0;
    }

    get themeClass() {
        let themeClass = '';

        if (this.batchJob === undefined || this.batchJob == null) {
            return '';
        }

        switch (this.batchJob.status) {
            case 'Aborted':
                themeClass = 'slds-theme_warning';
                break;
            case 'Failed':
                themeClass = 'slds-theme_error';
                break;
            case 'Completed':
                themeClass = this.batchJob.numberOfErrors > 0 ? 'slds-theme_warning' : 'slds-theme_success';
                break;
            default:
        }

        return themeClass;
    }

    /***
    * @description Notifies user of the error
    * @param {object} error: Event holding error details
    */
    handleError(error) {
        if (error && error.status && error.body) {
            console.log(`${error.name} + ${error.statusText} + ${error.body.message}`);
        } else if (error && error.name && error.message) {
            console.log(`${error.name} + ${error.message}`);
        } else {
            console.log(labelUnknownError);
        }
    }
}