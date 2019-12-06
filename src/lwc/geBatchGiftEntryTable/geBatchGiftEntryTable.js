import {LightningElement, api, track} from 'lwc';
import getDataImportModel
    from '@salesforce/apex/BGE_DataImportBatchEntry_CTRL.getDataImportModel';
import getDataImportRows
    from '@salesforce/apex/BGE_DataImportBatchEntry_CTRL.getDataImportRows';
import GeFormService from 'c/geFormService';
import STATUS_FIELD from '@salesforce/schema/DataImport__c.Status__c';
import {deleteRecord} from 'lightning/uiRecordApi';
import {handleError} from 'c/utilTemplateBuilder';

export default class GeBatchGiftEntryTable extends LightningElement {
    @api batchId;
    @track ready = false;
    accountId;

    _batchLoaded = false;
    @track data = [];
    @track hasData;
    _totalCountOfRows;

    _columnsLoaded = false;
    @track columns = [];
    _columns = [
        {label: 'Status', fieldName: STATUS_FIELD.fieldApiName, type: 'text'},
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
    _actionsColumn = {
        type: 'action',
        typeAttributes: {
            rowActions: [
                {label: 'Delete', name: 'delete'}
            ],
            menuAlignment: 'right'
        }
    };

    connectedCallback() {
        if (this.batchId) {
            this.loadBatch();
        }
    }

    @api
    setAccountId(id) {
        this.accountId = id;
    }

    setReady() {
        this.ready = this._columnsLoaded && this._batchLoaded;
    }

    loadBatch() {
        getDataImportModel({batchId: this.batchId})
            .then(
                response => {
                    const dataImportModel = JSON.parse(response);
                    this._totalCountOfRows = dataImportModel.totalCountOfRows;
                    dataImportModel.dataImportRows.forEach(
                        row => {
                            this.data.push(
                                Object.assign(row, row.record)
                            );
                        }
                    )
                    this.data = [...this.data];
                    this.hasData = this.data.length > 0 ? true : false;
                    this.batchLoaded();
                }
            )
            .catch(
                error => {
                    handleError(error);
                }
            );
    }

    batchLoaded() {
        this._batchLoaded = true;
        this.setReady();
    }

    @api
    handleSectionsRetrieved(sections) {
        this.initColumns(this.buildColumns(sections));
    }

    initColumns(userDefinedColumns) {
        this.columns = [
            ...this._columns,
            ...userDefinedColumns,
            this._actionsColumn];
        this.columnsLoaded();
    }

    buildColumns(sections) {
        const columns = [];
        sections.forEach(
            section => {
                section.elements.forEach(
                    element => {
                        const column = {
                            label: element.label,
                            fieldName: GeFormService.getFieldMappingWrapper(
                                element.dataImportFieldMappingDevNames[0]
                            ).Source_Field_API_Name,
                            type: GeFormService.getInputTypeFromDataType(
                                element.dataType
                            ) === 'date' ? 'date-local' :
                                GeFormService.getInputTypeFromDataType(element.dataType)
                        };
                        columns.push(column);
                    }
                );
            }
        );
        return columns;
    }

    columnsLoaded() {
        this._columnsLoaded = true;
        this.setReady();
    }

    @api
    upsertData(dataRow, idProperty) {
        let existingRow = this.data.find(row =>
            row[idProperty] === dataRow[idProperty]
        );
        if (existingRow) {
            Object.assign(existingRow, dataRow);
            this.data = [...this.data];
        } else {
            this.data = [dataRow, ...this.data];
            if (this.hasData == false) {
                this.hasData = true;
            }
        }
    }

    handleRowActions(event) {
        switch (event.detail.action.name) {
            // TODO: decide if going to edit inline in table or load into form
            // case 'Edit':
            //     this.editDIRow(event.detail.row);
            //     break;
            case 'delete':
                deleteRecord(event.detail.row.Id).then(() => {
                    this.deleteDIRow(event.detail.row);
                }).catch(error => {
                        handleError(error);
                    }
                );
                break;
        }
    }

    deleteDIRow(rowToDelete) {
        const isRowToDelete = row => row.Id == rowToDelete.Id;
        const index = this.data.findIndex(isRowToDelete);
        this.data.splice(index, 1);
        this.data = [...this.data];
    }

    loadMoreData(event){
        event.target.isLoading = true;
        const disableInfiniteLoading = function(){
            this.enableInfiniteLoading = false;
        }.bind(event.target);

        const disableIsLoading = function(){
            this.isLoading = false;
        }.bind(event.target);

        getDataImportRows({batchId: this.batchId, offset: this.data.length}).then(
            rows => {
                rows.forEach(
                    row => {
                        const record = row.record;
                        record.donorLink = row.donorLink;
                        record.donorName = row.donorName;
                        record.matchedRecordLabel = row.matchedRecordLabel;
                        record.matchedRecordUrl = row.matchedRecordUrl;
                        record.errors = row.errors.join(', ');
                        this.data.push(record);
                    }
                );
                this.data = [...this.data];
                if (this.data.length >= this._totalCountOfRows) {
                    disableInfiniteLoading();
                }
                disableIsLoading();
            }
        ).catch(
            error => {
                handleError(error);
            }
        );
    }
}