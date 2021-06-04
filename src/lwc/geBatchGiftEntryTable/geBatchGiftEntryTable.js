import { LightningElement, api, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { deleteRecord } from 'lightning/uiRecordApi';

import getDataImportModel from '@salesforce/apex/BGE_DataImportBatchEntry_CTRL.getDataImportModel';
import runBatchDryRun from '@salesforce/apex/BGE_DataImportBatchEntry_CTRL.runBatchDryRun';
import getDataImportRows from '@salesforce/apex/BGE_DataImportBatchEntry_CTRL.getDataImportRows';
import saveAndDryRunDataImport from '@salesforce/apex/GE_GiftEntryController.saveAndDryRunDataImport';

import { handleError } from 'c/utilTemplateBuilder';
import {isNotEmpty, isUndefined, apiNameFor, showToast, hasNestedProperty} from 'c/utilCommon';
import GeFormService from 'c/geFormService';
import { fireEvent, registerListener } from 'c/pubsubNoPageRef';

import geDonorColumnLabel from '@salesforce/label/c.geDonorColumnLabel';
import geDonationColumnLabel from '@salesforce/label/c.geDonationColumnLabel';
import bgeActionDelete from '@salesforce/label/c.bgeActionDelete';
import geBatchGiftsCount from '@salesforce/label/c.geBatchGiftsCount';
import geBatchGiftsTotal from '@salesforce/label/c.geBatchGiftsTotal';

import commonOpen from '@salesforce/label/c.commonOpen';
import bgeGridGiftDeleted from '@salesforce/label/c.bgeGridGiftDeleted';
import GeLabelService from 'c/geLabelService';

import DATA_IMPORT_OBJECT from '@salesforce/schema/DataImport__c';
import STATUS_FIELD from '@salesforce/schema/DataImport__c.Status__c';
import FAILURE_INFORMATION_FIELD from '@salesforce/schema/DataImport__c.FailureInformation__c';
import DONATION_AMOUNT from '@salesforce/schema/DataImport__c.Donation_Amount__c';
import PAYMENT_DECLINED_REASON from '@salesforce/schema/DataImport__c.Payment_Declined_Reason__c';
import DONATION_RECORD_TYPE_NAME from '@salesforce/schema/DataImport__c.Donation_Record_Type_Name__c';
import ELEVATE_PAYMENT_STATUS from '@salesforce/schema/DataImport__c.Elevate_Payment_Status__c';

const URL_SUFFIX = '_URL';
const URL_LABEL_SUFFIX = '_URL_LABEL';
const REFERENCE = 'REFERENCE';
const FIELD = 'field';
const FIELDS = 'fields';

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

const COLUMNS = [
    { label: 'Status', fieldName: STATUS_FIELD.fieldApiName, type: 'text', editable: true },
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

const ACTIONS_COLUMN = {
    type: 'action',
    typeAttributes: {
        rowActions: [
            { label: commonOpen, name: 'open' },
            { label: bgeActionDelete, name: 'delete' }
        ],
        menuAlignment: 'auto'
    }
};

export default class GeBatchGiftEntryTable extends LightningElement {
    @api batchId;
    @api isElevateCustomer = false;

    get ready() {
        return this._columnsLoaded && this._dataImportModel;
    }

    _columnsLoaded = false;
    _columnsBySourceFieldApiName = {};
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;
    _batchLoaded = false;

    @api title;
    @api total;
    @api expectedTotal;
    @api count;
    @api expectedCount;
    @api userDefinedBatchTableColumnNames;
    @api batchCurrencyIsoCode;
    isLoaded = true;


    constructor() {
        super();
        COLUMNS.forEach(column => {
            this._columnsBySourceFieldApiName[column.fieldName] = column;
        });
    }

    connectedCallback() {
        this.loadBatch();
        registerListener('refreshtable', this.refreshTable, this);
    }

    refreshTable() {
        let refreshedRows = [];
        getDataImportRows({ batchId: this.batchId, offset: 0 })
            .then(rows => {
                rows.forEach(row => {
                    refreshedRows.push(
                        Object.assign(row,
                            this.appendUrlColumnProperties.call(row.record,
                                this._dataImportObjectInfo)));
                });
                this.data = [ ...refreshedRows ];
            })
            .catch(error => {
                handleError(error);
            });
    }

    get hasData() {
        return this.data.length > 0;
    }

    _data = [];
    get data() {
        return this._data;
    }
    set data(dataImportRows) {
        this.assignDataImportErrorsToTableRows(dataImportRows);
        this._data = dataImportRows;
    }

    tableRowErrors;
    assignDataImportErrorsToTableRows(dataImportRows) {
        let errors = {rows: {}};
        this.getDataImportRowsWithErrors(dataImportRows).forEach(row => {
            Object.assign(errors.rows,  {
                [row.Id] : {
                    title: this.CUSTOM_LABELS.geProcessingErrors,
                    messages: this.getTableRowErrorMessages(row)
                }
            });
        });
        this.tableRowErrors = errors;
    }

    getDataImportRowsWithErrors(dataImportRows) {
        return dataImportRows.filter(row => {
                    return this.hasDataImportRowError(row);
                });
    }


    getErrorPropertiesToDisplayInRow() {
        return [apiNameFor(FAILURE_INFORMATION_FIELD),
                apiNameFor(PAYMENT_DECLINED_REASON)];
    }

    hasDataImportRowError(row) {
        return this.getErrorPropertiesToDisplayInRow().some(errorProperty =>
                    row.record.hasOwnProperty(errorProperty))

    }

    getTableRowErrorMessages(dataImportRow) {
        let errorMessages = [];
        this.getErrorPropertiesToDisplayInRow().forEach(errorProperty => {
            if (dataImportRow.record.hasOwnProperty(errorProperty)) {
                errorMessages.push(dataImportRow.record[errorProperty]);
            }
        });
        return errorMessages;
    }

    @api
    set sections(sections) {
        this._sections = sections;
        this.buildColumnsFromSections();
    }
    get sections() {
        return this._sections;
    }

    _dataImportModel;
    loadBatch() {
        getDataImportModel({batchId: this.batchId})
            .then(
                response => {
                    this._dataImportModel = JSON.parse(response);
                    this.setTableProperties();
                    this._batchLoaded = true;
                }
            )
            .catch(error => handleError(error));
    }


    _propertiesSet = false;
    setTableProperties() {
        if (this._propertiesSet) {
            return;
        }
        if (!this._dataImportObjectInfo) {
            return;
        }
        if (!this._dataImportModel) {
            return;
        }
        this._count = this._dataImportModel.totalCountOfRows;
        this._total = this._dataImportModel.batchTotalRowAmount;
        this._dataImportModel.dataImportRows.forEach(row => {
            this.data.push(Object.assign(row,
                this.appendUrlColumnProperties.call(row.record,
                    this._dataImportObjectInfo)));
        });
        this.data = this.data.slice(0);
        this._propertiesSet = true;
    }

    get columns() {
        return this.userDefinedBatchTableColumnNames &&
        this.userDefinedBatchTableColumnNames.length > 0 ?
            this.userDefinedColumns.concat(ACTIONS_COLUMN) :
            this.allColumns.concat(ACTIONS_COLUMN);
    }

    get allColumns() {
        return Object.values(this._columnsBySourceFieldApiName);
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

    buildColumnsFromSections() {
        this.sections.forEach(section => {
            section.elements.filter(e => e.elementType === FIELD)
                .forEach(fieldElement => {
                    const fieldMapping =
                        GeFormService.getFieldMappingWrapper(
                            fieldElement.dataImportFieldMappingDevNames[0]);

                    if (isNotEmpty(fieldMapping)) {
                        const column = this.getColumn(fieldElement, fieldMapping);
                        this._columnsBySourceFieldApiName[column.fieldName] = column;
                    }
                });
        });
        this.includeElevatePaymentStatusField();
        this._columnsLoaded = true;
    }

    includeElevatePaymentStatusField() {
        if (this.isElevateCustomer) {
            const elevatePaymentStatusApiName = apiNameFor(ELEVATE_PAYMENT_STATUS);

            if (hasNestedProperty(this._dataImportObjectInfo, FIELDS, elevatePaymentStatusApiName)) {
                const elevatePaymentStatus = this._dataImportObjectInfo?.fields[elevatePaymentStatusApiName];
                this._columnsBySourceFieldApiName[elevatePaymentStatus.apiName] = {
                    label: elevatePaymentStatus.label,
                    fieldName: elevatePaymentStatus.apiName,
                    type: elevatePaymentStatus.dataType
                }
            }
        }
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
            this.data = [dataRow].concat(this.data);
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
        const isRowToDelete = row => row.Id === rowToDelete.Id;
        const index = this.data.findIndex(isRowToDelete);
        this.data.splice(index, 1);
        this.data = this.data.splice(0);
        this.dispatchEvent(new CustomEvent('delete', {
            detail: {
                amount: rowToDelete[DONATION_AMOUNT.fieldApiName]
            }
        }));
        this.notifyGiftBatchHeaderOfTableChange();
        this.requestFormRendererReset();
        showToast(
            this.CUSTOM_LABELS.PageMessagesConfirm,
            bgeGridGiftDeleted,
            'success',
            'dismissible',
            null
        );
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
                                this._dataImportObjectInfo)));
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
                this._total = dataImportModel.batchTotalRowAmount;
                dataImportModel.dataImportRows.forEach(row => {
                    this.upsertData(
                        Object.assign(row,
                            this.appendUrlColumnProperties.call(row.record,
                                this._dataImportObjectInfo)), 'Id');
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
                    values: this.columns
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
        Object.keys(this)
            .filter(key =>
                key.endsWith('__r') || this[key].attributes
            )
            .forEach(key => {
                const referenceObj = this[key];
                const urlFieldName = key.endsWith('__r') ?
                    `${key.replace(/.$/,"c")}${urlSuffix}` :
                    `${key}${urlSuffix}`;
                const urlLabelFieldName = key.endsWith('__r') ?
                    `${key.replace(/.$/,"c")}${urlLabelSuffix}` :
                    `${key}${urlLabelSuffix}`;

                this[urlFieldName] = `/${referenceObj.Id}`;

                if (referenceObj.Name) {
                    this[urlLabelFieldName] = referenceObj.Name;
                } else {
                    try {
                        const field = objectInfo.fields[key];
                        const nameField = field.referenceToInfos[0].nameFields[0];
                        this[urlLabelFieldName] = referenceObj[nameField];
                    } catch (e) {
                        this[urlLabelFieldName] = referenceObj.Id;
                    }
                }
        });
        return this;
    }

    get batchCurrencyISOCode() {
        return this.batchCurrencyIsoCode;
    }

    @api
    handleSubmit(event) {
        saveAndDryRunDataImport({
            batchId: this.batchId,
            dataImport: event.detail.dataImportRecord
        }).then(result => {
            let dataImportModel = JSON.parse(result);
            let row = dataImportModel.dataImportRows[0];
            Object.assign(row,
                this.appendUrlColumnProperties.call(row.record,
                    this._dataImportObjectInfo));
            this.upsertData(row, 'Id');
            this._count = dataImportModel.totalCountOfRows;
            this._total = dataImportModel.batchTotalRowAmount;
            event.detail.success(); //Re-enable the Save button
            this.notifyGiftBatchHeaderOfTableChange();
        }).catch(error => {
            event.detail.error(error);
        });
    }

    notifyGiftBatchHeaderOfTableChange = () => {
        fireEvent(this, 'geBatchGiftEntryTableChangeEvent', {});
    }

    requestFormRendererReset() {
        fireEvent(this, 'formRendererReset', {});
    }

    _dataImportObjectInfo;
    @wire(getObjectInfo, {objectApiName: DATA_IMPORT_OBJECT})
    wiredDataImportObjectInfo({error, data}) {
        if (data) {
            this._dataImportObjectInfo = data;
            if (!this._propertiesSet) {
                this.setTableProperties();
            }
        }
    }

    getColumnTypeFromFieldType(dataType) {
        return columnTypeByDescribeType[dataType] || dataType.toLowerCase();
    }

    getColumn(element, fieldMapping) {
        const isReferenceField = element.dataType === REFERENCE &&
            fieldMapping.Source_Field_API_Name !== DONATION_RECORD_TYPE_NAME.fieldApiName;

        const columnFieldName =
            fieldMapping.Source_Field_API_Name.toLowerCase().endsWith('id')
                ? fieldMapping.Source_Field_API_Name.slice(0, -2)
                : fieldMapping.Source_Field_API_Name;

        let column = {
            label: element.customLabel,
            fieldName: isReferenceField ?
                `${columnFieldName}${URL_SUFFIX}` :
                fieldMapping.Source_Field_API_Name,
            type: this.getColumnTypeFromFieldType(element.dataType)
        };

        if (column.fieldName === DONATION_AMOUNT.fieldApiName) {
            column.typeAttributes = {
                currencyCode: this.batchCurrencyISOCode
            };
        }

        if (isReferenceField) {
            column.type = 'url';
            column.target = '_blank';
            column.typeAttributes = {
                label: {
                    fieldName:
                        `${columnFieldName}${URL_LABEL_SUFFIX}`
                }
            };
        }
        return column;
    }

}