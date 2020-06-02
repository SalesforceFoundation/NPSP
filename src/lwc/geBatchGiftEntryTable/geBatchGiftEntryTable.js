import {LightningElement, api, track} from 'lwc';
import getDataImportModel
    from '@salesforce/apex/BGE_DataImportBatchEntry_CTRL.getDataImportModel';
import getDataImportRows
    from '@salesforce/apex/BGE_DataImportBatchEntry_CTRL.getDataImportRows';
import GeFormService from 'c/geFormService';
import STATUS_FIELD from '@salesforce/schema/DataImport__c.Status__c';
import FAILURE_INFORMATION_FIELD
    from '@salesforce/schema/DataImport__c.FailureInformation__c';
import DONATION_AMOUNT from '@salesforce/schema/DataImport__c.Donation_Amount__c';
import {deleteRecord} from 'lightning/uiRecordApi';
import {handleError} from 'c/utilTemplateBuilder';
import runBatchDryRun from '@salesforce/apex/BGE_DataImportBatchEntry_CTRL.runBatchDryRun';
import geDonorColumnLabel from '@salesforce/label/c.geDonorColumnLabel';
import geDonationColumnLabel from '@salesforce/label/c.geDonationColumnLabel';
import bgeActionDelete from '@salesforce/label/c.bgeActionDelete';
import geBatchGiftsCount from '@salesforce/label/c.geBatchGiftsCount';
import geBatchGiftsTotal from '@salesforce/label/c.geBatchGiftsTotal';
import commonOpen from '@salesforce/label/c.commonOpen';
import { isNotEmpty } from 'c/utilCommon';

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
    _userDefinedBatchTableColumnNames;
    _columnsBySourceFieldApiName = {};


    @api title;
    @api total;
    @api expectedTotal;
    @api count;
    @api expectedCount;
    @track isLoaded = true;

    connectedCallback() {
        if (this.batchId && this._columnsLoaded) {
            this.loadBatch();
        } else {
            this.needsToLoadBatch = true;
        }
    }

    renderedCallback() {
        if (this.needsToLoadBatch) {
            this.needsToLoadBatch = false;
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
                    this._count = dataImportModel.totalCountOfRows;
                    this._total = dataImportModel.totalRowAmount;
                    dataImportModel.dataImportRows.forEach(row => {
                            this.data.push(
                                Object.assign(row, row.record));
                        }
                    );
                    this.data = [...this.data];
                    this.hasData = this.data.length > 0 ? true : false;
                    this._userDefinedBatchTableColumnNames =
                        dataImportModel.batchTableColumnSourceFieldApiNames;

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
        this.buildColumns(sections);
        this.initColumns(this.getUserDefinedColums());
    }

    getUserDefinedColums() {
        let userDefinedColumns = [];
        this._userDefinedBatchTableColumnNames.forEach(columnName => {
            userDefinedColumns.push(this._columnsBySourceFieldApiName[columnName]);
        });
        return userDefinedColumns;
    }

    initColumns(userDefinedColumns) {
        this.columns = [
            ...userDefinedColumns,
            this._actionsColumn];
        this.columnsLoaded();
    }

    buildColumns(sections) {
        this.addSpecialCasedColumns();

        sections.forEach(
            section => {
                section.elements
                    .filter(e => e.elementType === 'field')
                    .forEach(
                    element => {
                        const fieldWrapper = GeFormService.getFieldMappingWrapper(element.dataImportFieldMappingDevNames[0]);
                        if (isNotEmpty(fieldWrapper)) {
                            const column = {
                                label: element.customLabel,
                                fieldName: fieldWrapper.Source_Field_API_Name,
                                type: GeFormService.getInputTypeFromDataType(
                                    element.dataType
                                ) === 'date' ? 'date-local' :
                                    GeFormService.getInputTypeFromDataType(element.dataType)
                            };

                            this._columnsBySourceFieldApiName[column.fieldName] = column;
                        }
                    }
                );
            }
        );

    }

    addSpecialCasedColumns() {
        this._columnsBySourceFieldApiName[this._columns[0].fieldName] = this._columns[0];
        this._columnsBySourceFieldApiName[this._columns[1].fieldName] = this._columns[1];
        this._columnsBySourceFieldApiName[this._columns[2].fieldName] = this._columns[2];
        this._columnsBySourceFieldApiName[this._columns[3].fieldName] = this._columns[3];
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
        this.dispatchEvent(new CustomEvent('delete', {
            detail: {
                amount: rowToDelete[DONATION_AMOUNT.fieldApiName]
            }
        }));
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
                if (this.data.length >= this.count) {
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
                this._count = dataImportModel.totalCountOfRows;
                this._total = dataImportModel.totalRowAmount;
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

    get geBatchGiftsCountLabel() {
        return geBatchGiftsCount;
    }

    get geBatchGiftsTotalLabel() {
        return geBatchGiftsTotal;
    }

    loadRow(row) {
        this.dispatchEvent(new CustomEvent('loaddata', {
            detail: row
        }));
    }

    /**
     * @description Internal setters used to communicate the current count and total
     *              up to the App, which needs them to keep track of whether the batch's
     *              expected totals match.
     */
    set _count(count) {
        this.dispatchEvent(new CustomEvent('countchanged', {
            detail: {
                value: count
            }
        }));
    }

    set _total(total) {
        this.dispatchEvent(new CustomEvent('totalchanged', {
            detail: {
                value: total
            }
        }));
    }

}