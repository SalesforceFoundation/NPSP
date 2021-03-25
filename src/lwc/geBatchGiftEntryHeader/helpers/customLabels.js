import bgeBatchDryRun from '@salesforce/label/c.bgeBatchDryRun';
import bgeProcessBatch from '@salesforce/label/c.bgeProcessBatch';
import geEditBatchInfo from '@salesforce/label/c.geEditBatchInfo';
import bgeTabHeader from '@salesforce/label/c.bgeTabHeader';
import commonRecordsProcessed from '@salesforce/label/c.commonRecordsProcessed';
import commonRecordsFailed from '@salesforce/label/c.commonRecordsFailed';
import commonPaymentProcessingErrors from '@salesforce/label/c.commonPaymentProcessingErrors';

const CUSTOM_LABELS = Object.freeze({
    bgeBatchDryRun,
    bgeProcessBatch,
    geEditBatchInfo,
    bgeTabHeader,
    commonRecordsProcessed,
    commonRecordsFailed,
    commonPaymentProcessingErrors,
});

export default CUSTOM_LABELS;