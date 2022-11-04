import { LightningElement, api, track } from 'lwc';

import { isNull } from 'c/util';

import labelStatus from '@salesforce/label/c.BatchProgressStatus';
import labelTotalJobItems from '@salesforce/label/c.BatchProgressTotalJobItems';
import labelJobItemsProcessed from '@salesforce/label/c.BatchProgressJobItemsProcessed';
import labelTimeElapsed from '@salesforce/label/c.BatchProgressTimeElapsed';
import labelCompletedDate from '@salesforce/label/c.BatchProgressCompletedDate';
import labelExtendedStatus from '@salesforce/label/c.BatchProgressExtendedStatus';
import labelTotalRecords from '@salesforce/label/c.BatchProgressTotalRecords';
import labelTotalRecordsProcessed from '@salesforce/label/c.BatchProgressTotalRecordsProcessed';
import labelTotalRecordsFailed from '@salesforce/label/c.BatchProgressTotalRecordsFailed';
import labelLoading from '@salesforce/label/c.labelMessageLoading';
import labelStatusComplete from '@salesforce/label/c.BatchProgressStatusComplete';
import labelStatusCompleteErrors from '@salesforce/label/c.BatchProgressStatusCompleteErrors';
import labelStatusFailed from '@salesforce/label/c.BatchProgressStatusFailed';
import labelStatusHolding from '@salesforce/label/c.BatchProgressStatusHolding';
import labelStatusError from '@salesforce/label/c.BatchProgressStatusError';
import labelStatusPreparing from '@salesforce/label/c.BatchProgressStatusPreparing';
import labelStatusProcessing from '@salesforce/label/c.BatchProgressStatusProcessing';
import labelStatusQueued from '@salesforce/label/c.BatchProgressStatusQueued';
import labelStatusStopped from '@salesforce/label/c.BatchProgressStatusStopped';
import labelStatusSuccess from '@salesforce/label/c.BatchProgressStatusSuccess';
import labelUnknownError from '@salesforce/label/c.stgUnknownError';

import loadBatchJob from '@salesforce/apex/UTIL_BatchJobProgress_CTRL.loadBatchJob';

export default class BatchProgress extends LightningElement {
    @api title;
    @api className;

    @track batchJob;
    @track hasSummary;
    prevBatchJob;

    pollingTimeout = 10000;
    labels = {
        labelStatus,
        labelTotalJobItems,
        labelJobItemsProcessed,
        labelTimeElapsed,
        labelCompletedDate,
        labelExtendedStatus,
        labelTotalRecords,
        labelTotalRecordsProcessed,
        labelTotalRecordsFailed,
        labelLoading
    };

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
                this.prevBatchJob = this.batchJob;
                this.batchJob = this.setTotalRecords(JSON.parse(data));

                if (isNull(this.batchJob)) {
                    return;
                }

                this.hasSummary = !isNull(this.batchJob.summary);

                this.notifyOnStatusChange();

                if (this.batchJob.isInProgress === true
                    || (this.batchJob.status === 'Completed' && this.hasSummary !== true)
                ) {
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
    * @description Sets the total value as the sum of processed and failed
    */
    setTotalRecords(data) {
        if(!isNull(data) && !isNull(data.summary)) {
            data.summary.total = data.summary.processed + data.summary.failed;
        }
        return data;
    }

    /***
    * @description Notifies other components about the batch status change
    */
    notifyOnStatusChange() {
        if (isNull(this.batchJob)) {
            return;
        }

        if (isNull(this.prevBatchJob)
            || this.prevBatchJob.isInProgress !== this.batchJob.isInProgress
            || this.prevBatchJob.summary !== this.batchJob.summary
        ) {
            const isSuccess = this.batchJob.numberOfErrors === 0;

            const batchProgress = {
                batchId: this.batchJob.batchId,
                className: this.className,
                status: this.batchJob.status,
                isInProgress: this.batchJob.isInProgress,
                isSuccess: isSuccess,
                completedDaysBetween: this.batchJob.completedDaysBetween
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

    /***
    * @description Sets theme based on the batch job status
    */
    get themeClass() {
        let themeClass = '';

        if (isNull(this.batchJob)) {
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
    * @description Returns batch job status to display
    */
    get batchStatusDisplay() {
        let status = '';

        if (isNull(this.batchJob)) {
            return status;
        }

        switch (this.batchJob.status) {
            case 'Completed':
                status = this.batchJob.numberOfErrors > 0 ? labelStatusCompleteErrors : labelStatusComplete;
                break;
            default:
                status = this.batchStatus;
        }

        return status;
    }

    /***
    * @description Returns batch job status to display in the badge
    */
    get batchStatusBadge() {
        let status = '';

        if (isNull(this.batchJob)) {
            return status;
        }

        switch (this.batchJob.status) {
            case 'Completed':
                status = this.batchJob.numberOfErrors > 0 ? labelStatusError : labelStatusSuccess;
                break;
            default:
                status = this.batchStatus;
        }

        return status;
    }

    /***
    * @description Returns batch job status to display
    */
    get batchStatus() {
        let status = '';

        switch (this.batchJob.status) {
            case 'Holding':
                status = labelStatusHolding;
                break;
            case 'Queued':
                status = labelStatusQueued;
                break;
            case 'Preparing':
                status = labelStatusPreparing;
                break;
            case 'Processing':
                status = labelStatusProcessing;
                break;
            case 'Failed':
                status = labelStatusFailed;
                break;
            case 'Aborted':
                status = labelStatusStopped;
                break;
            default:
                status = this.batchJob.status;
        }

        return status;
    }

    /***
    * @description Returns message indicating percent completed
    */
    get progressMessage() {
        return isNull(this.batchJob)
            ? ''
            : this.batchJob.percentComplete + '% ' + labelStatusComplete;
    }
}