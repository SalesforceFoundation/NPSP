import { LightningElement, api, track } from 'lwc';

import labelStatus from '@salesforce/label/c.BatchProgressStatus';
import labelTotalJobItems from '@salesforce/label/c.BatchProgressTotalJobItems';
import labelJobItemsProcessed from '@salesforce/label/c.BatchProgressJobItemsProcessed';
import labelTimeElapsed from '@salesforce/label/c.BatchProgressTimeElapsed';
import labelCompletedDate from '@salesforce/label/c.BatchProgressCompletedDate';
import labelExtendedStatus from '@salesforce/label/c.BatchProgressExtendedStatus';
import labelLoading from '@salesforce/label/c.labelMessageLoading';
import labelUnknownError from '@salesforce/label/c.stgUnknownError';

import loadBatchJob from '@salesforce/apex/UTIL_BatchJobProgress_CTRL.loadBatchJob';

export default class BatchProgress extends LightningElement {
    @api title;
    @api className;

    @track batchJob;

    pollingTimeout = 10000;
    labels = {
        labelStatus,
        labelTotalJobItems,
        labelJobItemsProcessed,
        labelTimeElapsed,
        labelCompletedDate,
        labelExtendedStatus,
        labelLoading
    };

    /***
    * @description Sets theme based on the batch job status
    */
    get themeClass() {
        let themeClass = '';

        if (this.batchJob === undefined || this.batchJob == null) {
            return themeClass;
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
    * @description Initializes the component
    */
    connectedCallback() {
        this.handleLoadBatchJob();
    }

    /***
    * @description Loads batch job details
    */
    @api
    handleLoadBatchJob() {
        loadBatchJob({ className: this.className })
            .then((data) => {
                let previousBatchJob = this.batchJob;
                this.batchJob = JSON.parse(data);

                this.notifyOnStatusChange(previousBatchJob, this.batchJob);

                if (this.batchJob && this.batchJob.isInProgress === true) {
                    this.refreshBatchJob();
                }
            })
            .catch((error) => {
                this.handleError(error);
            });
    }

    /***
    * @description Starts polling for the batch job progress details until the batch job stops
    */
    refreshBatchJob() {
        var self = this;

        setTimeout(function () {
            self.handleLoadBatchJob();

        }, this.pollingTimeout, self);
    }

    /***
    * @description Notifies other components about the batch status change
    */
    notifyOnStatusChange(previousBatchJob, currentBatchJob) {
        if (currentBatchJob === undefined || currentBatchJob === null) {
            return;
        }

        const isFirstLoad = previousBatchJob === undefined || previousBatchJob === null;

        if (isFirstLoad
            || previousBatchJob.isInProgress !== currentBatchJob.isInProgress
        ) {
            const batchProgress = {
                className: this.className,
                status: currentBatchJob.status,
                isInProgress: currentBatchJob.isInProgress,
                isSuccess: currentBatchJob.status === 'Completed' && currentBatchJob.numberOfErrors === 0
            };

            const statusChangeEvent = new CustomEvent('statuschange', {
                detail: { batchProgress }
            });
            this.dispatchEvent(statusChangeEvent);
        }
    }

    /***
    * @description Notifies parent component of the error
    * In the case LightningOut is used, then showToast message cannot be invoked.
    * Thus, let the parent component define how user should be notified of the error.
    * @param {object} error: Event holding error details
    */
    handleError(error) {
        let toastTitle;
        let message;

        if (error && error.status && error.body) {
            toastTitle = `${error.status} ${error.statusText}`;
            message = error.body.message;

        } else if (error && error.name && error.message) {
            toastTitle = `${error.name}`;
            message = error.message;

        } else {
            message = labelUnknownError;
        }

        const errorDetail = {
            className: this.className,
            title: toastTitle,
            message: message
        };
        const errorEvent = new CustomEvent('error', {
            detail: { errorDetail }
        });
        this.dispatchEvent(errorEvent);
    }


}