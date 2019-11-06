import {LightningElement, api} from 'lwc';
import GeFormService from 'c/geFormService';

export default class GeFormApp extends LightningElement {
    @api isBatchMode = false;
    dataImportRecords = [];

    handleSubmit(event) {
        const submissions = event.target.submissions;
        console.log('submissions (in GeFormAPP: ', submissions);
        const newDataImportRecord = GeFormService.getDataImportRecord(submissions.pop());
        console.log('newDataImportRecord: ', newDataImportRecord);
        this.dataImportRecords = [...this.dataImportRecords, newDataImportRecord];
        console.log('this.dataImportRecords: ', this.dataImportRecords);
        const table = this.template.querySelector('c-ge-form-table');
    }
}