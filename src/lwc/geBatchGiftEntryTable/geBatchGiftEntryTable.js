import { api, track } from 'lwc';
import { deleteRecord } from 'lightning/uiRecordApi';

import getDataImportModel from '@salesforce/apex/BGE_DataImportBatchEntry_CTRL.getDataImportModel';
import runBatchDryRun from '@salesforce/apex/BGE_DataImportBatchEntry_CTRL.runBatchDryRun';
import getDataImportRows from '@salesforce/apex/BGE_DataImportBatchEntry_CTRL.getDataImportRows';

import { handleError } from 'c/utilTemplateBuilder';
import { isNotEmpty, isUndefined } from 'c/utilCommon';
import GeListView from 'c/geListView';
import GeFormService from 'c/geFormService';

import geDonorColumnLabel from '@salesforce/label/c.geDonorColumnLabel';
import geDonationColumnLabel from '@salesforce/label/c.geDonationColumnLabel';
import bgeActionDelete from '@salesforce/label/c.bgeActionDelete';
import geBatchGiftsCount from '@salesforce/label/c.geBatchGiftsCount';
import geBatchGiftsTotal from '@salesforce/label/c.geBatchGiftsTotal';

import commonOpen from '@salesforce/label/c.commonOpen';

import DATAIMPORT_INFO from '@salesforce/schema/DataImport__c';
import STATUS_FIELD from '@salesforce/schema/DataImport__c.Status__c';
import FAILURE_INFORMATION_FIELD from '@salesforce/schema/DataImport__c.FailureInformation__c';
import DONATION_AMOUNT from '@salesforce/schema/DataImport__c.Donation_Amount__c';

export default class GeBatchGiftEntryTable extends GeListView {
    @api batchId;
    @api userDefinedBatchTableColumnNames;
    @track columnsByFieldApiName = {};
    @track ready = false;

    _batchLoaded = false;
    @track data = [];
    @track hasData = false;

    _columnsLoaded = false;
    _columns = [
        { label: 'Status', fieldName: STATUS_FIELD.fieldApiName, type: 'text' },
        { label: 'Errors', fieldName: FAILURE_INFORMATION_FIELD.fieldApiName, type: 'text' },
        {
            label: geDonorColumnLabel, fieldName: 'donorLink', type: 'url',
            typeAttributes: { label: { fieldName: 'donorName' } }
        },
        {
            label: geDonationColumnLabel, fieldName: 'matchedRecordUrl', type: 'url',
            typeAttributes: { label: { fieldName: 'matchedRecordLabel' } }
        }
    ];
    _actionsColumn = {
        type: 'action',
        typeAttributes: {
            rowActions: [
                { label: commonOpen, name: 'open' },
                { label: bgeActionDelete, name: 'delete' }
            ],
            menuAlignment: 'auto'
        }
    };

    @api title;
    @api total;
    @api expectedTotal;
    @api count;
    @api expectedCount;
    @track isLoaded = true;

    constructor() {
        super(DATAIMPORT_INFO.objectApiName);
        /* Add the loadBatch function as a callback for the parent component to execute once it executes the
        objectInfo wire service */
        this.callbacks.push(this.loadBatch);
    }

    setReady() {
        this.ready = this._columnsLoaded && this._batchLoaded;
    }

    loadBatch = () => {
        getDataImportModel({ batchId: this.batchId })
            .then(
                response => {
                    const dataImportModel = JSON.parse(response);
                    this._count = dataImportModel.totalCountOfRows;
                    this._total = dataImportModel.totalRowAmount;

                    this.data = this.setDatatableRecordsForImperativeCall(
                        dataImportModel.dataImportRows.map(row => {
                            return Object.assign(row, row.record);
                        })
                    )
                    this.hasData = this.data.length > 0;
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
        if (!this._columnsLoaded) {
            this.buildColumns(sections);
        }
    }

    get computedColumns() {
        if (!this._columnsLoaded) return [];

        const hasUserDefinedColumns =
            this.userDefinedBatchTableColumnNames &&
            this.userDefinedBatchTableColumnNames.length > 0;

        if (hasUserDefinedColumns) {
            return [...this.retrieveUserDefinedColumns(), this._actionsColumn];
        }

        return [...this.retrieveAllColumns(), this._actionsColumn]
    }

    retrieveAllColumns() {
        let allColumns = [];
        for (const columnValue in this.columnsByFieldApiName) {
            allColumns.push(this.columnsByFieldApiName[columnValue]);
        }
        return allColumns;
    }

    retrieveUserDefinedColumns() {
        let userDefinedColumns = [];
        this.userDefinedBatchTableColumnNames.forEach(columnName => {
            if (isUndefined(this.columnsByFieldApiName[columnName])) return;
            userDefinedColumns.push(this.columnsByFieldApiName[columnName]);
        });
        return userDefinedColumns;
    }

    buildColumns(sections) {
        const fieldApiNames = [];
        sections.forEach(section => {
            section.elements
                .filter(element => element.elementType === 'field')
                .forEach(element => {
                    const fieldWrapper = GeFormService.getFieldMappingWrapper(
                        element.dataImportFieldMappingDevNames[0]
                    );
                    if (isNotEmpty(fieldWrapper)) {
                        fieldApiNames.push(fieldWrapper.Source_Field_API_Name);
                    }
                });
        });

        this.buildColumnsByFieldApiNamesMap(fieldApiNames);
        this.columnsLoaded();
    }

    /**
    * @description Builds a map of all possible columns based on form fields
    *              in the gift entry form. This map is used to return the relevant
    *              columns based on the user defined list of table headers or
    *              all columns if a user defined list couldn't be found.
    */
    buildColumnsByFieldApiNamesMap(fieldApiNames) {
        const columns = this.buildNameFieldColumns(fieldApiNames);
        columns.forEach(column => {
            this.columnsByFieldApiName[column.fieldApiName] = column;
        });
        this.addSpecialCasedColumns();
    }

    /**
    * @description Adds special cased columns to the map of columns. These
    *              four special cased fields are the Donor, Donation, Status,
    *              Failure Information fields. Donor and Donation are derived
    *              fields and constructed in the BGE_DataImportBatchEntry_CTRL
    *              class. Status and Failure Information are fields on the
    *              DataImport__c object.
    */
    addSpecialCasedColumns() {
        this.columnsByFieldApiName[this._columns[0].fieldName] = this._columns[0];
        this.columnsByFieldApiName[this._columns[1].fieldName] = this._columns[1];
        this.columnsByFieldApiName[this._columns[2].fieldName] = this._columns[2];
        this.columnsByFieldApiName[this._columns[3].fieldName] = this._columns[3];
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

        let rows = this.setDatatableRecordsForImperativeCall([dataRow]);

        if (existingRowIndex !== -1) {
            this.data.splice(existingRowIndex, 1, dataRow);
            this.data = [...this.data];
        } else {
            this.data = [...rows, ...this.data];
            if (this.hasData === false) {
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

        getDataImportRows({ batchId: this.batchId, offset: this.data.length })
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

    /*************************************************************************************
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