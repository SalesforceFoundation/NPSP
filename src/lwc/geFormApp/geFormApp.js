import {LightningElement, api} from 'lwc';
import GeFormService from 'c/geFormService';

export default class GeFormApp extends LightningElement {
    @api isBatchMode = false;
    submissionId = 0;
    columns = [
        {label: 'Status', fieldName: 'Status__c', type: 'text'},
        {label: 'UID', fieldName: 'uid', type: 'number'},
        {label: 'Donor', fieldName: 'donorName', type: 'text'},
        {label: 'Donor Link', fieldName: 'donorLink', type: 'text'}
    ];

    handleSubmit(event) {
        const submissions = event.target.submissions;
        const dataImportRecord = GeFormService.getDataImportRecord(submissions.pop());
        
        const table = this.template.querySelector('c-ge-form-table');
        table.upsertRow(this.submissionId, dataImportRecord);

        dataImportRecord.NPSP_Data_Import_Batch__c = 'a0R8A000000WB12UAG';
        const uid = this.submissionId;
        console.log('dataImportRecord: ', dataImportRecord);
        GeFormService.saveAndDryRun(this.batchId = 'a0R8A000000WB12UAG', dataImportRecord)
            .then(
                model => {
                    console.log('*** ' + 'trying to upsert row with submission id: ' +this.submissionId+ ' ***');
                    console.log('*** ' + 'trying to upsert row with submission id: ' +uid+ ' ***');
                    console.log('returned model: ', model);
                    const modelObj = JSON.parse(model);
                    const dataImport = modelObj.dataImportRows[0].record;
                    console.log('modelObj: ', modelObj);
                    dataImport.donorName = modelObj.dataImportRows[0].donorName;
                    dataImport.donorLink = modelObj.dataImportRows[0].donorLink;
                    table.upsertRow(uid, dataImport);
                }
            )
            .catch(

            );
        
        // if (this.submissionId < 3) {
        //     this.submissionId = this.submissionId + 1;
        // } else if (this.submissionId == 3) {
        //     this.submissionId = 1;
        // }

        this.submissionId = this.submissionId + 1;
    }

    handleSectionsRetrieved(event) {
        console.log('*** ' + 'sections Retrieved!, building columns' + ' ***');
        let form = this.template.querySelector('c-ge-form-renderer');
        let sections = form.sections;
        const columnsToAdd = GeFormService.buildColumns(sections);
        console.log('*** ' + 'columnsToAdd vv' + ' ***');
        console.log(JSON.parse(JSON.stringify(columnsToAdd)));
        this.columns = [...this.columns, ...columnsToAdd];
        // Array.prototype.concat.apply(this.columns, columnsToAdd);
        console.log('this.columns: ', this.columns);
        const table = this.template.querySelector('c-ge-form-table');
        table.columns = this.columns;
    }
}