import {LightningElement, api} from 'lwc';
import GeFormService from 'c/geFormService';

export default class GeFormApp extends LightningElement {
    @api isBatchMode = false;
    submissionId = 0;

    handleSubmit(event) {
        const submissions = event.target.submissions;
        const dataImportRecord = GeFormService.getDataImportRecord(submissions.pop());
        const table = this.template.querySelector('c-ge-form-table');
        table.upsertRow(this.submissionId, dataImportRecord);
        this.submissionId = this.submissionId + 1;
    }
}