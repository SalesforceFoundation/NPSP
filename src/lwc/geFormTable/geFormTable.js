import {LightningElement, api, track} from 'lwc';
import getDataImportModel
    from '@salesforce/apex/BGE_DataImportBatchEntry_CTRL.getDataImportModel';
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
        },
        {
            label: 'Donation', fieldName: 'matchedRecordUrl', type: 'url',
            typeAttributes: {label: {fieldName: 'matchedRecordLabel'}}
        }
    ];
    accountId;

    connectedCallback() {
        if (this.batchId) {
            this.loadBatch();
        }
    }

    @api
    setAccountId(id) {
        this.accountId = id;
    }

    @api
    setBatchId(id) {
        if (this.batchId !== id) {
            this.loadBatch(id);
        }
        this.batchId = id;
    }


    @api
    loadBatch(batchId = this.batchId) {
        this.data = []; //clear out table
        if (!batchId) {
            return;
        }
        getDataImportModel({batchId: batchId})
            .then(
                response => {
                    const dataImportModel = JSON.parse(response);
                    dataImportModel.dataImportRows.forEach(
                        row => {
                            const record = row.record;
                            record.donorLink = row.donorLink;
                            record.donorName = row.donorName;
                            record.errors = row.errors.join(', ');
                            this.data.push(record);
                        }
                    )
                    this.data = [...this.data];
                }
            )
            .catch(
                error => {
                    console.error(JSON.stringify(error));
                }
            );
    }

    @api
    addColumns(columns) {
        this.columns = [...this.columns, ...columns];
    }

    @api
    handleFormSubmission(submission) {
        const dataImportRecord =
            GeFormService.getDataImportRecord(submission.sectionsList);
        dataImportRecord.Account1Imported__c = this.accountId;
        dataImportRecord.Donation_Donor__c = "Account1";
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
                    dataImport.matchedRecordLabel = model.dataImportRows[0].matchedRecordLabel;
                    dataImport.matchedRecordUrl = model.dataImportRows[0].matchedRecordUrl;
                    dataImport.errors = model.dataImportRows[0].errors;
                    this.upsertRow(submission.submissionId, dataImport);
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
                            fieldName: GeFormService.getFieldMappingWrapper(element.dataImportFieldMappingDevNames[0]).Source_Field_API_Name,
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
                    row.matchedRecordLabel = dataImport.matchedRecordLabel;
                    row.matchedRecordUrl = dataImport.matchedRecordUrl;
                    row.errors = dataImport.errors.join(', ');
                    break;
                }
            }
        } else {
            this.data.unshift(dataImport);
        }
        this.data = [...this.data];
    }
}