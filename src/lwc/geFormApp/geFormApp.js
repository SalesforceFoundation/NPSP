import {LightningElement, api} from 'lwc';
import GeFormService from 'c/geFormService';

export default class GeFormApp extends LightningElement {
    @api isBatchMode = false;
    submissionId = 0;
    columns = [];

    handleSubmit(event) {
        const submissions = event.target.submissions;
        const dataImportRecord = GeFormService.getDataImportRecord(submissions.pop());
        const table = this.template.querySelector('c-ge-form-table');
        table.upsertRow(this.submissionId, dataImportRecord);
        // this.submissionId = this.submissionId + 1;
        // while (this.submissionId < 2) {
        //     this.submissionId = this.submissionId + 1;
        // }

        if (this.submissionId < 3) {
            this.submissionId = this.submissionId + 1;
        } else if (this.submissionId == 3) {
            this.submissionId = 1;
        }

    }

    handleSectionsRetrieved(event) {
        console.log('*** ' + 'sections Retrieved!, building columns' + ' ***');
        let form = this.template.querySelector('c-ge-form-renderer');
        let sections = form.sections;
        this.columns = GeFormService.buildColumns(sections);
        console.log('this.columns: ', this.columns);
        const table = this.template.querySelector('c-ge-form-table');
        table.columns = this.columns;
    }
}