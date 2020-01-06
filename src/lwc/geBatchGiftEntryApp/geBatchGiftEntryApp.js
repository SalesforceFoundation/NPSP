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

        GeFormService.saveAndDryRun(
            this.recordId, dataRow)
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
                handleError(error);
                event.detail.error();
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

    handleBatchDryRun() {
        const table = this.template.querySelector('c-ge-batch-gift-entry-table');
        table.runBatchDryRun();
    }
}