import {LightningElement, api} from 'lwc';
import GeFormService from 'c/geFormService';

export default class GeFormApp extends LightningElement {
    @api isBatchMode = false;

    handleSubmit(event) {
        const latestSubmission =
            event.target.submissions[event.target.submissions.length - 1];
        const dataImportRecord =
            GeFormService.getDataImportRecord(latestSubmission.sectionsList);

        const table = this.template.querySelector('c-ge-form-table');
        table.upsertRow(latestSubmission.submissionId, dataImportRecord);

        //todo: for prod going to want to pass in the batch Id
        dataImportRecord.NPSP_Data_Import_Batch__c = 'a0R8A000000WB12UAG';

        GeFormService.saveAndDryRun(
            this.batchId = 'a0R8A000000WB12UAG', dataImportRecord)
            .then(
                model => {
                    const dataImport = model.dataImportRows[0].record;
                    dataImport.donorName = model.dataImportRows[0].donorName;
                    dataImport.donorLink = model.dataImportRows[0].donorLink;
                    table.upsertRow(latestSubmission.submissionId, dataImport);
                }
            )
            .catch(error => {
                console.error(JSON.stringify(error));
            });
    }

    handleSectionsRetrieved(event) {
        const table = this.template.querySelector('c-ge-form-table');
        table.addColumns(GeFormService.buildColumns(event.target.sections));
        table.ready = true;
    }
}