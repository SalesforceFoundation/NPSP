import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { deleteRecord } from 'lightning/uiRecordApi';

import getDataImportModel from '@salesforce/apex/BGE_DataImportBatchEntry_CTRL.getDataImportModel';
import runBatchDryRun from '@salesforce/apex/BGE_DataImportBatchEntry_CTRL.runBatchDryRun';
import getDataImportRows from '@salesforce/apex/BGE_DataImportBatchEntry_CTRL.getDataImportRows';
import saveAndDryRunDataImport from '@salesforce/apex/GE_GiftEntryController.saveAndDryRunDataImport';

import { handleError } from 'c/utilTemplateBuilder';
import { isNotEmpty, isUndefined } from 'c/utilCommon';
import GeFormService from 'c/geFormService';

import geDonorColumnLabel from '@salesforce/label/c.geDonorColumnLabel';
import geDonationColumnLabel from '@salesforce/label/c.geDonationColumnLabel';
import bgeActionDelete from '@salesforce/label/c.bgeActionDelete';
import geBatchGiftsCount from '@salesforce/label/c.geBatchGiftsCount';
import geBatchGiftsTotal from '@salesforce/label/c.geBatchGiftsTotal';

import commonOpen from '@salesforce/label/c.commonOpen';
import GeLabelService from 'c/geLabelService';

import DATA_IMPORT_OBJECT from '@salesforce/schema/DataImport__c';
import STATUS_FIELD from '@salesforce/schema/DataImport__c.Status__c';
import FAILURE_INFORMATION_FIELD from '@salesforce/schema/DataImport__c.FailureInformation__c';
import DONATION_AMOUNT from '@salesforce/schema/DataImport__c.Donation_Amount__c';

const URL_SUFFIX = '_URL';
const URL_LABEL_SUFFIX = '_URL_LABEL';

const columnTypeByDescribeType = {
    'DATE': 'date-local',
    'DATETIME': 'date',
    'EMAIL': 'email',
    'DOUBLE': 'number',
    'INTEGER': 'number',
    'LONG': 'number',
    'PERCENT': 'number',
    'STRING': 'text',
    'PICKLIST': 'text'
};

export default class GeBatchGiftEntryTable extends LightningElement {
    @api batchId;
    @track ready = false;

    _batchLoaded = false;
    @track data = [];
    @track hasData;

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
    _columnsBySourceFieldApiName = {};
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    @api title;
    @api total;
    @api expectedTotal;
    @api count;
    @api expectedCount;
    @api userDefinedBatchTableColumnNames;
    @track isLoaded = true;

    @api
    handleSectionsRetrieved(sections) {
        if (!this._batchLoaded) {
            this.loadBatch(sections);
        }
    }

    setReady() {
        this.ready = this._columnsLoaded && this._batchLoaded;
    }

    loadBatch(sections) {
        getDataImportModel({batchId: this.batchId})
            .then(
                response => {
                    const dataImportModel = JSON.parse(response);
                    this.setTableProperties(dataImportModel);
                    this.buildColumnsFromSections(sections);
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

    setTableProperties(dataImportModel) {
        this._count = dataImportModel.totalCountOfRows;
        this._total = dataImportModel.totalRowAmount;
        dataImportModel.dataImportRows.forEach(row => {
            this.data.push(Object.assign(row,
                this.appendUrlColumnProperties.call(row.record,
                    this.dataImportObjectInfo)));
        });
        this.data = this.data.slice(0);
        this.hasData = this.data.length > 0 ? true : false;
    }

    get columns() {
        if (!this._columnsLoaded) return [];
        if (this._columnsLoaded) return [...this.computedColumns, this._actionsColumn];
    }

    get computedColumns() {
        const hasUserDefinedColumns =
            this.userDefinedBatchTableColumnNames && this.userDefinedBatchTableColumnNames.length > 0;
        if (hasUserDefinedColumns) {
            return this.userDefinedColumns;
        }

        return this.allColumns;
    }

    get allColumns() {
        let allColumns = [];
        for (const columnValue in this._columnsBySourceFieldApiName) {
            allColumns.push(this._columnsBySourceFieldApiName[columnValue]);
        }
        return allColumns;
    }

    get userDefinedColumns() {
        let userDefinedColumns = [];
        this.userDefinedBatchTableColumnNames.forEach(columnName => {
            if (this._columnsBySourceFieldApiName[`${columnName}${URL_SUFFIX}`]) {
                userDefinedColumns.push(this._columnsBySourceFieldApiName[`${columnName}${URL_SUFFIX}`]);
            } else if (isUndefined(this._columnsBySourceFieldApiName[columnName])) {
                return;
            } else {
                userDefinedColumns.push(this._columnsBySourceFieldApiName[columnName]);
            }
        });
        return userDefinedColumns;
    }

    buildColumnsFromSections(sections) {
        this.addSpecialCasedColumns();
        if (!sections) return;

        sections.forEach(section => {
            section.elements.filter(e => e.elementType === 'field')
                .forEach(fieldElement => {
                    const fieldWrapper =
                        GeFormService.getFieldMappingWrapper(
                            fieldElement.dataImportFieldMappingDevNames[0]);

                    if (isNotEmpty(fieldWrapper)) {
                        const column = this.getColumn(fieldElement, fieldWrapper);
                        this._columnsBySourceFieldApiName[column.fieldName] = column;
                    }
                });
        });

        this.columnsLoaded();
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
            this.data = this.data.splice(0);
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
                });
                break;
        }
    }

    deleteDIRow(rowToDelete) {
        const isRowToDelete = row => row.Id == rowToDelete.Id;
        const index = this.data.findIndex(isRowToDelete);
        this.data.splice(index, 1);
        this.data = this.data.splice(0);
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
                        Object.assign(row,
                            this.appendUrlColumnProperties.call(row.record,
                                this.dataImportObjectInfo)));
                });
                this.data = this.data.splice(0);
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
                dataImportModel.dataImportRows.forEach(row => {
                    this.upsertData(
                        Object.assign(row,
                            this.appendUrlColumnProperties.call(row.record,
                                this.dataImportObjectInfo)), 'Id');
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

    handleMenuItemSelect(event) {
        if (event.detail.value === 'selectcolumns') {
            const selectColumns = new CustomEvent('selectcolumns', {
                detail: {
                    options: this.allColumns
                        .map(({label, fieldName}) => ({
                            label, value: fieldName
                        })),
                    values: this.computedColumns
                        .map(({fieldName}) => fieldName)
                }
            });
            this.dispatchEvent(selectColumns);
        }
    }

    get qaLocatorTableMenu() {
        return 'button Show menu';
    }

    get qaLocatorSelectBatchTableColumns() {
        return `link ${this.CUSTOM_LABELS.geSelectBatchTableColumns}`;

    }

    /*************************************************************************************
     * @description For each relationship field on an object, this function appends two
     *              properties to the object intended for use with url-type columns in
     *              lightning-datatables. One to be used as the url value and another
     *              to be used as its label.
     * @param objectInfo objectInfo of the record object in context.
     * @param urlSuffix value to be appended to the field name to comprise first new
     *        property name.
     * @param urlLabelSuffix value to be appended to the field name to comprise second new
     *        property name.
     * @returns {object}
     */
    appendUrlColumnProperties(objectInfo, urlSuffix = URL_SUFFIX,
                              urlLabelSuffix = URL_LABEL_SUFFIX) {
        const replaceLast = (find, replacement, string) => {
            const lastIndex = string.lastIndexOf(find);
            if (lastIndex === -1) {
                return string;
            }
            return string.substring(0, lastIndex) + replacement;
        };

        for (const [key, value] of Object.entries(this)) {
            const field = objectInfo.fields[key];
            if (field && field.dataType === 'Reference') {
                const relationshipField = replaceLast('__c', '__r', key);
                if (!this[relationshipField]) {
                    continue;
                }

                this[`${key}${urlSuffix}`] = `/${value}`;
                if (this[relationshipField].Name) {
                    this[`${key}${urlLabelSuffix}`] = this[relationshipField].Name;
                } else {
                    try {
                        const nameField = field.referenceToInfos[0].nameFields[0];
                        this[`${key}${urlLabelSuffix}`] = this[relationshipField][nameField];
                    } catch (e) {
                        this[`${key}${urlLabelSuffix}`] = value;
                    }
                }
            }
        }
        return this;
    }

    @api
    handleSubmit(event) {
        saveAndDryRunDataImport({
            batchId: this.batchId,
            dataImport: event.detail.dataImportRecord
        })
            .then(result => {
                let dataImportModel = JSON.parse(result);
                let row = dataImportModel.dataImportRows[0];
                Object.assign(row,
                    this.appendUrlColumnProperties.call(row.record,
                        this.dataImportObjectInfo));
                this.upsertData(row, 'Id');
                this._count = dataImportModel.totalCountOfRows;
                this._total = dataImportModel.totalRowAmount;
                event.detail.success(); //Re-enable the Save button
            })
            .catch(error => {
                event.detail.error(error);
            });
    }

    @wire(getObjectInfo, { objectApiName: DATA_IMPORT_OBJECT})
    dataImportObjectInfo;

    getColumnTypeFromFieldType(dataType) {
        return columnTypeByDescribeType[dataType] || dataType.toLowerCase();
    }

    getColumnFieldName(element, fieldWrapper) {
        return element.dataType === 'REFERENCE' ?
            `${fieldWrapper.Source_Field_API_Name}${URL_SUFFIX}`
            : fieldWrapper.Source_Field_API_Name;
    }

    getColumn(element, fieldWrapper) {
        let column = {
            label: element.customLabel,
            fieldName: this.getColumnFieldName(element, fieldWrapper),
            type: this.getColumnTypeFromFieldType(element.dataType)
        };

        if (element.dataType === 'REFERENCE') {
            column.type = 'url';
            column.target = '_blank';
            column.typeAttributes = {
                label: {
                    fieldName:
                        `${fieldWrapper.Source_Field_API_Name}${URL_LABEL_SUFFIX}`
                }
            };
        }
        return column;
    }

}
