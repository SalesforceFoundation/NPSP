import {LightningElement, api, track} from 'lwc';
import GeFormService from 'c/geFormService';
import NPSP_DATA_IMPORT_BATCH_FIELD
    from '@salesforce/schema/DataImport__c.NPSP_Data_Import_Batch__c';
import {handleError} from 'c/utilTemplateBuilder';

export default class GeBatchGiftEntryApp extends LightningElement {
    @api recordId;

    handleSubmit(event) {
        const table = this.template.querySelector('c-ge-batch-gift-entry-table');
        const dataRow = this.getTableDataRow(
            event.target.submissions[event.target.submissions.length - 1]
        );

        if (!dataRow[NPSP_DATA_IMPORT_BATCH_FIELD.fieldApiName]) {
            dataRow[NPSP_DATA_IMPORT_BATCH_FIELD.fieldApiName] = this.recordId;
        }

        const displayValues = dataRow.displayValues;
        // Apex is unable to read the dataRow (DataImport__c record) if it
        // has this property, so it is stashed here and appended after the server call to
        // make the display values available when loading Lookup fields in edit mode.
        delete dataRow.displayValues;

        GeFormService.saveAndDryRun(
            this.recordId, dataRow)
            .then(
                dataImportModel => {
                    Object.assign(dataImportModel.dataImportRows[0],
                        dataImportModel.dataImportRows[0].record);
                    dataImportModel.dataImportRows[0].displayValues = displayValues;
                    table.upsertData(dataImportModel.dataImportRows[0], 'Id');
                    table.setTotalCount(dataImportModel.totalCountOfRows);
                    table.setTotalAmount(dataImportModel.totalAmountOfRows);
                    event.detail.success(); //Re-enable the Save button
                }
            )
            .catch(error => {
                handleError(error);
                event.detail.error();
            });
    }

    getTableDataRow(formSubmission) {
        let dataImportRecord =
            GeFormService.getDataImportRecord(formSubmission.sectionsList);
        return dataImportRecord;
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

    handleEdit(event) {
        const form = this.template.querySelector('c-ge-form-renderer');
        form.load(event.detail);
    }
}