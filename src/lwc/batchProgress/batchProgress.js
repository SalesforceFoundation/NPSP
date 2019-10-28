import { LightningElement, api, track } from 'lwc';

import batchJobProgressTitle from '@salesforce/label/c.BatchJobProgressTitle';
import unknownError from '@salesforce/label/c.stgUnknownError';

import loadBatchJob from '@salesforce/apex/UTIL_BatchJobProgress_CTRL.loadBatchJob';

export default class BatchProgress extends LightningElement {
    @api className;
    @track batchJob;

    labels = {
        batchJobProgressTitle
    };


    /***
    * @description Returns the batch job object
    */
    @api
    get batchJob() {
        return this._batchJob;
    }

    /***
    * @description Loads batch job details
    * @param value Current batch job
    */
    set batchJob(value) {
        this._batchJob = loadBatchJob({ className: this.className });
    }


    /***
    * @description Notifies user of the error
    *
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