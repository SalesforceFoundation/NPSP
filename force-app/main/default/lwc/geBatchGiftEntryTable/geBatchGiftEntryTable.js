import { LightningElement, api, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import {isNotEmpty, isUndefined, apiNameFor, showToast, hasNestedProperty, deepClone, format} from 'c/utilCommon';
import GeFormService from 'c/geFormService';
import { fireEvent } from 'c/pubsubNoPageRef';

import geDonorColumnLabel from '@salesforce/label/c.geDonorColumnLabel';
import geDonationColumnLabel from '@salesforce/label/c.geDonationColumnLabel';
import bgeActionDelete from '@salesforce/label/c.bgeActionDelete';
import geBatchGiftsCount from '@salesforce/label/c.geBatchGiftsCount';
import geBatchGiftsTotal from '@salesforce/label/c.geBatchGiftsTotal';
import geBatchGiftsHeader from '@salesforce/label/c.geBatchGiftsHeader';

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
import DONATION_IMPORTED from '@salesforce/schema/DataImport__c.DonationImported__c';
import PAYMENT_IMPORTED from '@salesforce/schema/DataImport__c.PaymentImported__c';
import RECURRING_DONATION_IMPORTED from '@salesforce/schema/DataImport__c.RecurringDonationImported__c';
import CONTACT_IMPORTED from '@salesforce/schema/DataImport__c.Contact1Imported__c';
import ORGANIZATION_IMPORTED from '@salesforce/schema/DataImport__c.Account1Imported__c';
import DONATION_DONOR from '@salesforce/schema/DataImport__c.Donation_Donor__c';

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

const DONOR_LINK = 'donorLink';
const DONOR_NAME = 'donorName';
const MATCHED_DONATION_LINK = 'matchedRecordUrl';
const MATCHED_DONATION_LABEL = 'matchedRecordLabel';

const COLUMNS = [
    { label: 'Status', fieldName: STATUS_FIELD.fieldApiName, type: 'text', editable: true },
    { label: 'Errors', fieldName: FAILURE_INFORMATION_FIELD.fieldApiName, type: 'text' },
    {
        label: geDonorColumnLabel, fieldName: DONOR_LINK, type: 'url',
        typeAttributes: { label: { fieldName: DONOR_NAME } }
    },
    {
        label: geDonationColumnLabel, fieldName: MATCHED_DONATION_LINK, type: 'url',
        typeAttributes: { label: { fieldName: MATCHED_DONATION_LABEL } }
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
    giftsFromView = [];

    @api batchId;
    @api isElevateCustomer = false;

    get ready() {
        return this._columnsLoaded && this._batchLoaded;
    }

    _columnsLoaded = false;
    _columnsBySourceFieldApiName = {};
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;
    _batchLoaded = false;

    @api userDefinedBatchTableColumnNames;
    @api batchCurrencyIsoCode;
    isLoaded = true;
    isLoading = false;


    constructor() {
        super();
        COLUMNS.forEach(column => {
            this._columnsBySourceFieldApiName[column.fieldName] = column;
        });
    }

    get tableTitle() {
        return format(geBatchGiftsHeader, [this.giftBatchState?.name]);
    }

    get giftBatchState() {
        return this._giftBatchState;
    }

    @api
    set giftBatchState(giftBatchState) {
        this._giftBatchState = giftBatchState;
        if (this._dataImportObjectInfo) {
            this._setTableProperties();
        }
    }

    _setTableProperties() {
        if (this._giftBatchState?.gifts) {
            this.giftsFromView = [];

            this._giftBatchState.gifts.forEach(gift => {
                let giftViewAsTableRow = deepClone(gift.state());
                giftViewAsTableRow = Object.assign(
                    giftViewAsTableRow.fields,
                    this.appendUrlColumnProperties.call(
                        giftViewAsTableRow.fields,
                        this._dataImportObjectInfo
                    )
                );
                giftViewAsTableRow = this.populateDonorLink(giftViewAsTableRow);
                giftViewAsTableRow = this.populateMatchedDonationLink(giftViewAsTableRow);

                this.giftsFromView.push(giftViewAsTableRow);
            });

            this.assignDataImportErrorsToTableRows(this.giftsFromView);

            this._count = this._giftBatchState.totalGiftsCount;
            this._total = this._giftBatchState.totalDonationsAmount;
            this._batchLoaded = true;
            this.isLoading = false;
        }
    }

    get hasData() {
        return this.giftsFromView.length > 0;
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
                    row.hasOwnProperty(errorProperty))

    }

    getTableRowErrorMessages(dataImportRow) {
        let errorMessages = [];
        this.getErrorPropertiesToDisplayInRow().forEach(errorProperty => {
            if (dataImportRow.hasOwnProperty(errorProperty)) {
                errorMessages.push(dataImportRow[errorProperty]);
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
                this.dispatchEvent(new CustomEvent('delete', {
                    detail: event.detail.row
                }));
                this.isLoading = true;
                break;
        }
    }

    handleLoadMoreGifts() {
        if (this.hasAllExistingGifts() || this.isLoading) {
            return;
        }

        const loadMoreGiftsEvent = new CustomEvent('loadmoregifts', {
            detail: { giftsOffset: this.giftsFromView.length }
        });
        this.dispatchEvent(loadMoreGiftsEvent);
        this.isLoading = true;
    }

    hasAllExistingGifts() {
        return this.giftsFromView.length === this.giftBatchState.totalGiftsCount;
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
                key.endsWith('__r') || this[key]?.attributes
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

    populateDonorLink(giftViewAsTableRow) {
        const donorType = giftViewAsTableRow[DONATION_DONOR.fieldApiName];

        if (donorType === 'Contact1') {
            giftViewAsTableRow[DONOR_LINK] = giftViewAsTableRow[`${CONTACT_IMPORTED.fieldApiName}${URL_SUFFIX}`];
            giftViewAsTableRow[DONOR_NAME] = giftViewAsTableRow[`${CONTACT_IMPORTED.fieldApiName}${URL_LABEL_SUFFIX}`];
        } else if (donorType === 'Account1') {
            giftViewAsTableRow[DONOR_LINK] = giftViewAsTableRow[`${ORGANIZATION_IMPORTED.fieldApiName}${URL_SUFFIX}`];
            giftViewAsTableRow[DONOR_NAME] = giftViewAsTableRow[`${ORGANIZATION_IMPORTED.fieldApiName}${URL_LABEL_SUFFIX}`];
        }
        return giftViewAsTableRow;
    }

    populateMatchedDonationLink(giftViewAsTableRow) {
        const isMatchedToAPaymentRecord = giftViewAsTableRow[PAYMENT_IMPORTED.fieldApiName];
        const isMatchedToAnOpportunityRecord = giftViewAsTableRow[DONATION_IMPORTED.fieldApiName];
        const isRecurringGift = giftViewAsTableRow[RECURRING_DONATION_IMPORTED.fieldApiName];

        if (isMatchedToAPaymentRecord) {
            giftViewAsTableRow[MATCHED_DONATION_LINK] = giftViewAsTableRow[`${PAYMENT_IMPORTED.fieldApiName}${URL_SUFFIX}`];
            giftViewAsTableRow[MATCHED_DONATION_LABEL] = giftViewAsTableRow[`${PAYMENT_IMPORTED.fieldApiName}${URL_LABEL_SUFFIX}`];
        } else if (isMatchedToAnOpportunityRecord) {
            giftViewAsTableRow[MATCHED_DONATION_LINK] = giftViewAsTableRow[`${DONATION_IMPORTED.fieldApiName}${URL_SUFFIX}`];
            giftViewAsTableRow[MATCHED_DONATION_LABEL] = giftViewAsTableRow[`${DONATION_IMPORTED.fieldApiName}${URL_LABEL_SUFFIX}`];
        } else if (isRecurringGift) {
            giftViewAsTableRow[MATCHED_DONATION_LINK] = giftViewAsTableRow[`${RECURRING_DONATION_IMPORTED.fieldApiName}${URL_SUFFIX}`];
            giftViewAsTableRow[MATCHED_DONATION_LABEL] = giftViewAsTableRow[`${RECURRING_DONATION_IMPORTED.fieldApiName}${URL_LABEL_SUFFIX}`];
        }
        return giftViewAsTableRow;
    }

    get batchCurrencyISOCode() {
        return this.batchCurrencyIsoCode;
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
            this._setTableProperties();
        }
    }

    getColumnTypeFromFieldType(dataType) {
        return columnTypeByDescribeType[dataType] || dataType.toLowerCase();
    }

    getColumn(element, fieldMapping) {
        const isReferenceField = element.dataType === REFERENCE && !this.isDonationRecordType(fieldMapping);
        const columnFieldName =
            fieldMapping.Source_Field_API_Name.toLowerCase().endsWith('id')
                ? fieldMapping.Source_Field_API_Name.slice(0, -2)
                : fieldMapping.Source_Field_API_Name;

        let column = {
            label: element.customLabel,
            fieldName: isReferenceField ?
                `${columnFieldName}${URL_SUFFIX}` :
                fieldMapping.Source_Field_API_Name,
            type: this.isDonationRecordType(fieldMapping)
                ? columnTypeByDescribeType.STRING
                : this.getColumnTypeFromFieldType(element.dataType)
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

    isDonationRecordType(fieldMapping) {
        return fieldMapping.Source_Field_API_Name === DONATION_RECORD_TYPE_NAME.fieldApiName;
    }

    // Public properties below are deprecated.
    @api title;
    @api total;
    @api expectedTotal;
    @api count;
    @api expectedCount;
}
