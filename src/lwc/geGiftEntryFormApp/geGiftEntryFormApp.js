import {LightningElement, api, track} from 'lwc';
import GeFormService from 'c/geFormService';
import DATA_IMPORT_BATCH_OBJECT from '@salesforce/schema/DataImportBatch__c';

export default class GeGiftEntryFormApp extends LightningElement {
    @api recordId;
    @api sObjectName;

    @track isPermissionError;

    handleSubmit(event) {
        const table = this.template.querySelector('c-ge-batch-gift-entry-table');
        const { diRecord, widgetValues } = event.detail.data;
        let widgetString = '';
        if(widgetValues) {
            widgetString = JSON.stringify(widgetValues);
        }
        GeFormService.saveAndDryRun(
            this.recordId, diRecord, widgetString)
            .then(
                dataImportModel => {
                    Object.assign(dataImportModel.dataImportRows[0],
                        dataImportModel.dataImportRows[0].record);
                    table.upsertData(dataImportModel.dataImportRows[0], 'Id');
                    table.setTotalCount(dataImportModel.totalCountOfRows);
                    table.setTotalAmount(dataImportModel.totalAmountOfRows);
                    event.detail.success(); //Re-enable the Save button
                }
            )
            .catch(error => {
                event.detail.error(error);
            });
    }

    handleSectionsRetrieved(event) {
        const formSections = event.target.sections;
        const table = this.template.querySelector('c-ge-batch-gift-entry-table');
        table.handleSectionsRetrieved(formSections);
    }

    handleBatchDryRun() {
        //toggle the spinner on the form
        const form = this.template.querySelector('c-ge-form-renderer');
        const toggleSpinner = function () {
            form.showSpinner = !form.showSpinner
        };
        form.showSpinner = true;

        const table = this.template.querySelector('c-ge-batch-gift-entry-table');
        table.runBatchDryRun(toggleSpinner);
    }

    handleLoadData(event) {
        const form = this.template.querySelector('c-ge-form-renderer');
        form.reset();
        form.load(event.detail);
    }

    handlePermissionErrors() {
        this.isPermissionError = true;
    }
    handleEditBatch() {
        this.dispatchEvent(new CustomEvent('editbatch'));
    }

    get isBatchMode() {
        return this.sObjectName &&
            this.sObjectName === DATA_IMPORT_BATCH_OBJECT.objectApiName;
    }

    handleReviewDonationsModal(event) {
        this.dispatchEvent(new CustomEvent('togglereviewdonationsmodal', { detail: event.detail }));
    }

}