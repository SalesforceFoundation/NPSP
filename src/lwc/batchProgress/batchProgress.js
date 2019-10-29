import { LightningElement, api, track } from 'lwc';

import batchJobProgressTitle from '@salesforce/label/c.BatchJobProgressTitle';
import unknownError from '@salesforce/label/c.stgUnknownError';

import loadBatchJob from '@salesforce/apex/UTIL_BatchJobProgress_CTRL.loadBatchJob';

export default class BatchProgress extends LightningElement {
    @api className;
    @track batchJob;

    pollingTimer;
    pollingTimeout = 1000;

    labels = {
        batchJobProgressTitle
    };

    /***
    * @description Starts polling for the batch job details until the batch job is completed
    */
    @api
    refreshBatchJob() {
        var self = this;
        console.log('refreshBatchJob ');

        this.pollingTimer = setTimeout(function () {
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
            console.log(unknownError);
        }
    }
}