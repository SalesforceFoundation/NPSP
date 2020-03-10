import {LightningElement, api, track} from 'lwc';
import getDataImportModel
    from '@salesforce/apex/BGE_DataImportBatchEntry_CTRL.getDataImportModel';
import getDataImportRows
    from '@salesforce/apex/BGE_DataImportBatchEntry_CTRL.getDataImportRows';
import GeFormService from 'c/geFormService';
import STATUS_FIELD from '@salesforce/schema/DataImport__c.Status__c';
import FAILURE_INFORMATION_FIELD
    from '@salesforce/schema/DataImport__c.FailureInformation__c';
import {deleteRecord} from 'lightning/uiRecordApi';
import {handleError} from 'c/utilTemplateBuilder';
import runBatchDryRun from '@salesforce/apex/BGE_DataImportBatchEntry_CTRL.runBatchDryRun';
import geDonorColumnLabel from '@salesforce/label/c.geDonorColumnLabel';
import geDonationColumnLabel from '@salesforce/label/c.geDonationColumnLabel';
import bgeActionDelete from '@salesforce/label/c.bgeActionDelete';
import commonOpen from '@salesforce/label/c.commonOpen';

export default class GeBatchGiftEntryTable extends LightningElement {
    @api batchId;
    @track ready = false;

    _batchLoaded = false;
    @track data = [];
    @track hasData;

    _columnsLoaded = false;
    @track columns = [];
    _columns = [
        {label: 'Status', fieldName: STATUS_FIELD.fieldApiName, type: 'text'},
        {label: 'Errors', fieldName: FAILURE_INFORMATION_FIELD.fieldApiName, type: 'text'},
        {
            label: geDonorColumnLabel, fieldName: 'donorLink', type: 'url',
            typeAttributes: {label: {fieldName: 'donorName'}}
        },
        {
            label: geDonationColumnLabel, fieldName: 'matchedRecordUrl', type: 'url',
            typeAttributes: {label: {fieldName: 'matchedRecordLabel'}}
        }
    ];
    _actionsColumn = {
        type: 'action',
        typeAttributes: {
            rowActions: [
                {label: commonOpen, name: 'open'},
                {label: bgeActionDelete, name: 'delete'}
            ],
            menuAlignment: 'auto'
        }
    };

    _totalCountOfGifts;
    _totalAmountOfGifts;
    @track isLoaded = true;

    connectedCallback() {
        if (this.batchId) {
            this.loadBatch();
        }
    }

    setReady() {
        this.ready = this._columnsLoaded && this._batchLoaded;
    }

    loadBatch() {
        getDataImportModel({batchId: this.batchId})
            .then(
                response => {
                    const dataImportModel = JSON.parse(response);
                    this._totalCountOfGifts = dataImportModel.totalCountOfRows;
                    this._totalAmountOfGifts = dataImportModel.totalRowAmount;
                    dataImportModel.dataImportRows.forEach(row => {
                            this.data.push(
                                Object.assign(row, row.record));
                        }
                    );
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
                section.elements
                    .filter(e => e.elementType === 'field')
                    .forEach(
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
        const existingRowIndex = this.data.findIndex(row =>
            row[idProperty] === dataRow[idProperty]
        );

        if (existingRowIndex !== -1) {
            this.data.splice(existingRowIndex, 1, dataRow);
            this.data = [...this.data];
        } else {
            this.data = [dataRow, ...this.data];
            if (this.hasData == false) {
                this.hasData = true;
            }
        }
    }

    @api
    setTotalCount(value) {
        this._totalCountOfGifts = value;
    }

    @api
    setTotalAmount(value) {
        this._totalAmountOfGifts = value;
    }

    handleRowActions(event) {
        switch (event.detail.action.name) {
            case 'open':
                this.loadRow(event.detail.row);
                break;
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

    loadMoreData(event) {
        event.target.isLoading = true;
        const disableInfiniteLoading = function () {
            this.enableInfiniteLoading = false;
        }.bind(event.target);

        const disableIsLoading = function () {
            this.isLoading = false;
        }.bind(event.target);

        getDataImportRows({batchId: this.batchId, offset: this.data.length})
            .then(rows => {
                rows.forEach(row => {
                        this.data.push(
                            Object.assign(row, row.record)
                        );
                    }
                );
                this.data = [...this.data];
                if (this.data.length >= this._totalCountOfGifts) {
                    disableInfiniteLoading();
                }
                disableIsLoading();
            })
            .catch(error => {
                handleError(error);
            });
    }

    @api
    runBatchDryRun(callback) {
        runBatchDryRun({
            batchId: this.batchId,
            numberOfRowsToReturn: this.data.length
        })
            .then(result => {
                const dataImportModel = JSON.parse(result);
                this.setTotalCount(dataImportModel.totalCountOfRows);
                this.setTotalCount(dataImportModel.totalRowAmount);
                dataImportModel.dataImportRows.forEach((row, idx) => {
                    this.upsertData(
                        Object.assign(row, row.record), 'Id');
                });
            })
            .catch(error => {
                handleError(error);
            })
            .finally(() => {
                callback();
            });
    }

    loadRow(row) {
        this.dispatchEvent(new CustomEvent('loaddata', {
            detail: row
        }));
    }
}