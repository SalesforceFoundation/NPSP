import {LightningElement, api, track} from 'lwc';
import getDataImportModel from '@salesforce/apex/BGE_DataImportBatchEntry_CTRL.getDataImportModel';
import GeFormService from 'c/geFormService';

export default class GeFormTable extends LightningElement {
    @api ready = false;
    @api batchId;
    @track data = [];
    @track columns = [
        {label: 'Status', fieldName: 'Status__c', type: 'text'},
        {label: 'Errors', fieldName: 'errors', type: 'text'},
        {
            label: 'Donor', fieldName: 'donorLink', type: 'url',
            typeAttributes: {label: {fieldName: 'donorName'}}
        }
    ];

    @api
    addColumns(columns) {
        this.columns = [...this.columns, ...columns];
    }

    @api
    handleFormSubmission(submission) {
        const dataImportRecord =
            GeFormService.getDataImportRecord(submission.sectionsList);
        this.upsertRow(submission.submissionId, dataImportRecord);

        //todo: for prod going to want to pass in the batch Id
        dataImportRecord.NPSP_Data_Import_Batch__c = this.batchId;

        GeFormService.saveAndDryRun(
            this.batchId, dataImportRecord)
            .then(
                model => {
                    const dataImport = model.dataImportRows[0].record;
                    dataImport.donorName = model.dataImportRows[0].donorName;
                    dataImport.donorLink = model.dataImportRows[0].donorLink;
                    dataImport.errors = model.dataImportRows[0].errors;
                    this.upsertRow(submission.submissionId, dataImport);

                    // model.dataImportRows.forEach(
                    //     row => {
                    //         if (row.errors) {
                    //             row.errors.forEach(
                    //               error => {
                    //                   //todo: investigate how to get these errors to show
                    //                   // on table
                    //                   this.rowErrors[submission.submissionId] = {
                    //                       title: 'Error',
                    //                       messages: ['There was a problem during dry run.'],
                    //                       fieldNames: ['Status__c'],
                    //                       size: 1
                    //                   };
                    //               }
                    //             );
                    //         }
                    //     }
                    // );
                }
            )
            .catch(error => {
                console.error(JSON.stringify(error));
            });
    }

    @api
    handleSectionsRetrieved(sections) {
        this.addColumns(this.buildColumns(sections));
        this.ready = true;
    }

    buildColumns(sections) {
        const columns = [];
        sections.forEach(
            section => {
                section.elements.forEach(
                    element => {
                        const column = {
                            label: element.label,
                            fieldName: GeFormService.getFieldMappingWrapper(element.value).Source_Field_API_Name,
                            type: GeFormService.getInputTypeFromDataType(element.dataType)
                        };
                        columns.push(column);
                    }
                );
            }
        );
        return columns;
    }

    upsertRow(uid, dataImport) {
        if (dataImport && !dataImport.hasOwnProperty('uid')) {
            dataImport.uid = uid;
        }

        if (this.data.some(item => item.uid === uid)) {
            for (let i = 0; i < this.data.length; i++) {
                let row = this.data[i];
                if (row.uid === uid) {
                    row.Status__c = dataImport.Status__c;
                    row.donorName = dataImport.donorName;
                    row.donorLink = dataImport.donorLink;
                    row.errors = dataImport.errors.join(', ');
                    break;
                }
            }
        } else {
            this.data.unshift(dataImport);
        }
        this.data = [...this.data]; //re-assign the table, to rerender it
    }
}