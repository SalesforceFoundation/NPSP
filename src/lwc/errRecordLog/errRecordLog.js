import { LightningElement, api, wire, track } from 'lwc';
import LOCALE from '@salesforce/i18n/locale';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { constructErrorMessage, extractFieldInfo, isNull, isUndefined } from 'c/utilCommon';
import getData from '@salesforce/apex/ERR_Log_CTRL.getData';

import loadingMessage from '@salesforce/label/c.labelMessageLoading';
import insufficientPermissions from '@salesforce/label/c.commonInsufficientPermissions';
import contactSystemAdmin from '@salesforce/label/c.commonContactSystemAdminMessage';
import commonUnknownError from '@salesforce/label/c.commonUnknownError';
import commonNoItems from '@salesforce/label/c.commonNoItems';
import actionView from '@salesforce/label/c.bgeActionView';

import ERROR_OBJECT from '@salesforce/schema/Error__c';
import ERROR_FIELD_DATETIME from '@salesforce/schema/Error__c.Datetime__c';
import ERROR_FIELD_ERROR_TYPE from '@salesforce/schema/Error__c.Error_Type__c';
import ERROR_FIELD_FULL_MESSAGE from '@salesforce/schema/Error__c.Full_Message__c';

const ASC = "asc";
const DESC = "desc";

export default class errRecordLog extends NavigationMixin(LightningElement) {

    labels = Object.freeze({
        loadingMessage,
        insufficientPermissions,
        contactSystemAdmin,
        commonUnknownError,
        commonNoItems,
        actionView
    });

    @api recordId;

    @track isLoading = true;
    @track error = {};

    @track recordInfo = {};
    @track columns = [];
    @track errorLogs;
    @track hasErrorLogs;
    @track sortedBy;
    @track sortDirection = DESC;


    /***
     * @description Initializes the component
     */
    connectedCallback() {
        if (this.recordId) {
            getData({ recordId: this.recordId })
                .then(response => {
                    this.recordInfo = {
                        sObjectType: response.sObjectType,
                        sObjectTypeLabelPlural: response.sObjectTypeLabelPlural,
                        name: response.recordName
                    };

                    this.errorLogs = response.errorLogs;
                    this.hasErrorLogs = !isUndefined(this.errorLogs) && this.errorLogs.length > 0;
                })
                .catch((error) => {
                    this.handleError(error);
                })
                .finally(() => {
                    this.checkLoading();
                });
        }
    }

    /***
    * @description Retrieves Error SObject info and its field labels/help text
    */
    @wire(getObjectInfo, { objectApiName: ERROR_OBJECT.objectApiName })
    wiredErrorObjectInfo(response) {
        if (response.data) {
            const fields = response.data.fields;

            const fieldDatetime = extractFieldInfo(fields, ERROR_FIELD_DATETIME.fieldApiName);
            const fieldErrorType = extractFieldInfo(fields, ERROR_FIELD_ERROR_TYPE.fieldApiName);
            const fieldFullMessage = extractFieldInfo(fields, ERROR_FIELD_FULL_MESSAGE.fieldApiName);

            this.columns = [
                {
                    type: 'action',
                    typeAttributes: {
                        rowActions: [{ label: this.labels.actionView, name: 'show_details' }],
                    }
                },
                {
                    label: fieldDatetime.label,
                    fieldName: fieldDatetime.apiName,
                    type: 'date',
                    typeAttributes: {
                        year: 'numeric',
                        month: 'numeric',
                        day: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit',
                        hour12: true
                    },
                    hideDefaultActions: true,
                    sortable: true
                },
                {
                    label: fieldErrorType.label,
                    fieldName: fieldErrorType.apiName,
                    type: fieldErrorType.dataType,
                    hideDefaultActions: true
                },
                {
                    label: fieldFullMessage.label,
                    fieldName: fieldFullMessage.apiName,
                    type: fieldFullMessage.dataType,
                    wrapText: true
                }
            ];

            this.checkLoading();
        }

        if (response.error) {
            this.handleError(response.error);
        }
    }


    /**
     * @description Checks if the form still has outstanding data to load
     */
    checkLoading() {
        const hasLoadedLogs = !isUndefined(this.errorLogs) && !isNull(this.errorLogs);
        const hasLoadedColumns = this.columns.length > 0;

        this.isLoading = !hasLoadedLogs && !hasLoadedColumns;
    }

    /**
     * @description Navigates to the record detail page
     */
    navigateToRecordViewPage(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        });
    }

    /**
     * @description Navigates to the record tab
     */
    navigateToRecordObjectPage(event) {
        this[NavigationMixin.Navigate]({
            type: "standard__objectPage",
            attributes: {
                objectApiName: this.recordInfo.sObjectType,
                actionName: "list",
            }
        });
    }

    /**
     * @description Navigates to the error log detail page
     */
    handleRowAction(event) {
        const row = event.detail.row;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: row.Id,
                actionName: 'view'
            }
        });
    }

    /**
     * @description Sorts records by the sort direction and sorted field
     */
    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const sorted = [...this.errorLogs];

        sorted.sort(this.sortBy(sortedBy, sortDirection === ASC ? 1 : -1));
        this.errorLogs = sorted;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                return primer(x[field]);
            }
            : function (x) {
                return x[field];
            };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    /***
    * @description Handles error construction and its display
    * @param error: Error Event
    */
    handleError(error) {
        this.error = (error && error.detail)
            ? error
            : constructErrorMessage(error);

        if (this.error.detail && this.error.detail.includes('ERR_Log_CTRL')) {
            this.error.header = this.labels.insufficientPermissions;
            this.isLoading = false;
        }
    }


    /***
    * @description data-qa-locator values for elements on the component
    */
    get qaLocatorSpinner() {
        return `spinner ${this.labels.loadingMessage}`;
    }

    get qaLocatorErrorLogDatatable() {
        return `datatable Error Logs`;
    }

    get qaLocatorEmptyErrorLogMessage() {
        return `text Error Log Message`;
    }
}