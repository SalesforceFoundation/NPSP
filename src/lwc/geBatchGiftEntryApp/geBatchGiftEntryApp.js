import {LightningElement, api} from 'lwc';
import {setAccountId as setServiceAccountId} from 'c/geFormService';
import GeFormService from 'c/geFormService';
import ACCOUNT_1_IMPORTED_FIELD from
        '@salesforce/schema/DataImport__c.Account1Imported__c';
import DONATION_DONOR_FIELD from '@salesforce/schema/DataImport__c.Donation_Donor__c';
import NPSP_DATA_IMPORT_BATCH_FIELD
    from '@salesforce/schema/DataImport__c.NPSP_Data_Import_Batch__c';
import STATUS_FIELD from '@salesforce/schema/DataImport__c.Status__c';

export default class GeBatchGiftEntryApp extends LightningElement {
    @api batchId;
    @api accountId;
    @api isBatchMode = false; // once we are loading from a batch, just batchId should be
    // sufficient

    //method used for testing until form is ready to be loaded with a Batch id
    handleBatchId(event) {
        this.batchId = event.target.value;
        this.isBatchMode = this.batchId ? true : false;

        const form = this.template.querySelector('c-ge-form-renderer');
        form.isBatchMode = this.isBatchMode;

        const table = this.template.querySelector('c-ge-batch-gift-entry-table');
        table.setBatchId(event.target.value);
        table.loadBatch();
    }

    //method used for testing until form has Account/Contact Lookups or is ready to be loaded
    // with an Account Id
    handleAccountId(event) {
        this.accountId = event.target.value;
        const table = this.template.querySelector('c-ge-batch-gift-entry-table');
        table.setAccountId(event.target.value);
        setServiceAccountId(event.target.value);
    }

    connectedCallback() {
        //The form will load in batch mode once we are passing a batch id into the app on
        // load, since the form responds to this property
        this.isBatchMode = this.batchId ? true : false;
    }

    handleSubmit(event) {
        const table = this.template.querySelector('c-ge-batch-gift-entry-table');
        const dataRow = this.getTableDataRow(
            event.target.submissions[event.target.submissions.length - 1]
        );
        if (!dataRow[STATUS_FIELD.fieldApiName]) {
            dataRow[STATUS_FIELD.fieldApiName] = 'Dry Run - Pending';
        }
        table.upsertData(dataRow, dataRow.Id ? 'Id' : 'submissionId');

        //simulate a lookup field being used to select an existing Account
        if (!dataRow[ACCOUNT_1_IMPORTED_FIELD.fieldApiName]) {
            dataRow[ACCOUNT_1_IMPORTED_FIELD.fieldApiName] = this.accountId;
        }
        if (!dataRow[DONATION_DONOR_FIELD.fieldApiName]) {
            dataRow[DONATION_DONOR_FIELD.fieldApiName] = 'Account1';
        }

        if (!dataRow[NPSP_DATA_IMPORT_BATCH_FIELD.fieldApiName]) {
            dataRow[NPSP_DATA_IMPORT_BATCH_FIELD.fieldApiName] = this.batchId;
        }

        GeFormService.saveAndDryRun(
            this.batchId, dataRow)
            .then(
                dataImportModel => {
                    const processedDataRow = dataImportModel.dataImportRows[0].record;
                    processedDataRow.submissionId = dataRow.submissionId;
                    processedDataRow.Id = dataImportModel.dataImportRows[0].record.Id;
                    processedDataRow.donorName = dataImportModel.dataImportRows[0].donorName;
                    processedDataRow.donorLink = dataImportModel.dataImportRows[0].donorLink;
                    processedDataRow.matchedRecordLabel = dataImportModel.dataImportRows[0].matchedRecordLabel;
                    processedDataRow.matchedRecordUrl = dataImportModel.dataImportRows[0].matchedRecordUrl;
                    processedDataRow.errors = dataImportModel.dataImportRows[0].errors;
                    table.upsertData(processedDataRow, 'submissionId');
                }
            )
            .catch(error => {
                console.error(JSON.stringify(error));
            });
    }

    getTableDataRow(formSubmission) {
        let dataImportRecord =
            GeFormService.getDataImportRecord(formSubmission.sectionsList);
        dataImportRecord.submissionId = formSubmission.submissionId;
        return dataImportRecord;
    }

    handleSectionsRetrieved(event) {
        const formSections = event.target.sections;
        const table = this.template.querySelector('c-ge-batch-gift-entry-table');
        table.handleSectionsRetrieved(formSections);
    }
}