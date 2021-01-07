import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { constructErrorMessage, extractFieldInfo, isNull, isUndefined, format } from 'c/utilCommon';
import getData from '@salesforce/apex/ERR_Log_CTRL.getData';

import title from '@salesforce/label/c.ERR_RecordLogTitle';
import loadingMessage from '@salesforce/label/c.labelMessageLoading';
import insufficientPermissions from '@salesforce/label/c.commonInsufficientPermissions';
import accessDeniedMessage from '@salesforce/label/c.addrCopyConAddBtnFls';
import contactSystemAdmin from '@salesforce/label/c.commonContactSystemAdminMessage';
import commonUnknownError from '@salesforce/label/c.commonUnknownError';
import commonNoItems from '@salesforce/label/c.commonNoItems';
import actionView from '@salesforce/label/c.bgeActionView';
import listViewItemCount from '@salesforce/label/c.geTextListViewItemCount';
import listViewItemCountPlural from '@salesforce/label/c.geTextListViewItemsCount';
import listViewSortedBy from '@salesforce/label/c.geTextListViewSortedBy';

import ERROR_OBJECT from '@salesforce/schema/Error__c';
import ERROR_FIELD_NAME from '@salesforce/schema/Error__c.Name';
import ERROR_FIELD_DATETIME from '@salesforce/schema/Error__c.Datetime__c';
import ERROR_FIELD_ERROR_TYPE from '@salesforce/schema/Error__c.Error_Type__c';
import ERROR_FIELD_FULL_MESSAGE from '@salesforce/schema/Error__c.Full_Message__c';

const ASC = "asc";
const DESC = "desc";
const ERROR_LOG_URL_FIELD = 'logURL';

export default class errRecordLog extends NavigationMixin(LightningElement) {

    labels = Object.freeze({
        title,
        loadingMessage,
        insufficientPermissions,
        accessDeniedMessage,
        contactSystemAdmin,
        commonUnknownError,
        commonNoItems,
        actionView,
        listViewItemCount,
        listViewItemCountPlural,
        listViewSortedBy
    });

    @api recordId;

    @track isLoading = true;
    @track error = {};
    @track hasAccess;

    @track recordInfo = {};
    @track columns = [];
    @track data;
    @track hasData = true;
    @track sortedBy;
    @track sortDirection = DESC;
    fieldDatetime = {};


    /***
     * @description Initializes the component
     */
    connectedCallback() {
        if (this.recordId) {
            getData({ recordId: this.recordId })
                .then(response => {
                    this.hasAccess = response.hasAccess;

                    this.recordInfo = {
                        sObjectType: response.sObjectType,
                        sObjectLabelPlural: response.sObjectLabelPlural,
                        name: response.recordName
                    };

                    this.data = response.data;
                    this.hasData = !isUndefined(this.data) && this.data.length > 0;

                    if (this.hasData) {
                        this.data.forEach(function (log) {
                            log[ERROR_LOG_URL_FIELD] = '/' + log['Id'];
                        });
                    }

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

            const fieldName = extractFieldInfo(fields, ERROR_FIELD_NAME.fieldApiName);
            if (fieldName) {
                this.columns.push({
                    label: fieldName.label,
                    fieldName: ERROR_LOG_URL_FIELD,
                    type: 'url',
                    typeAttributes: {
                        label: { fieldName: fieldName.apiName }
                    },
                    hideDefaultActions: true
                });
            }

            this.fieldDatetime = extractFieldInfo(fields, ERROR_FIELD_DATETIME.fieldApiName);
            if (this.fieldDatetime) {
                this.columns.push({
                    label: this.fieldDatetime.label,
                    fieldName: this.fieldDatetime.apiName,
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
                });
            }

            const fieldErrorType = extractFieldInfo(fields, ERROR_FIELD_ERROR_TYPE.fieldApiName);
            if (fieldErrorType) {
                this.columns.push({
                    label: fieldErrorType.label,
                    fieldName: fieldErrorType.apiName,
                    type: fieldErrorType.dataType,
                    hideDefaultActions: true
                });
            }

            const fieldFullMessage = extractFieldInfo(fields, ERROR_FIELD_FULL_MESSAGE.fieldApiName);
            if (fieldFullMessage) {
                this.columns.push({
                    label: fieldFullMessage.label,
                    fieldName: fieldFullMessage.apiName,
                    type: fieldFullMessage.dataType,
                    wrapText: true
                });
            }

            if (this.columns.lenth === 0) {
                this.hasAccess = false;
            }

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
        const hasError = this.error && this.error.detail;

        if (this.hasAccess === false || hasError) {
            this.isLoading = false;

        } else {
            const waitingForData = isUndefined(this.data) || isNull(this.data);
            const waitingForObjectInfo = this.columns.length === 0;

            this.isLoading = waitingForData || waitingForObjectInfo;
        }
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
     * @description Sorts records by the sort direction and sorted field
     */
    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const sorted = [...this.data];

        sorted.sort(this.sortBy(sortedBy, sortDirection === ASC ? 1 : -1));

        this.data = sorted;
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
    * @description Returns total number of logs
    */
    get itemSummary() {
        const size = this.data ? this.data.length : 0;

        return size !== 1
            ? format(this.labels.listViewItemCountPlural, [size])
            : format(this.labels.listViewItemCount, [size]);
    }

    /***
    * @description Returns info about sorted by field which is Datetime field only
    */
    get sortedByLabel() {
        return (this.fieldDatetime && this.fieldDatetime.label)
            ? format(this.labels.listViewSortedBy, [this.fieldDatetime.label])
            : undefined;
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
        }
    }


    /***
    * @description data-qa-locator values for elements on the component
    */
    get qaLocatorSpinner() {
        return `spinner ${this.labels.loadingMessage}`;
    }

    get qaLocatorError() {
        return `error Notification`;
    }

    get qaLocatorRecordViewPage() {
        return `breadcrumb Record View Page`;
    }

    get qaLocatorRecordSObjectPage() {
        return `breadcrumb Record SObject Page`;
    }

    get qaLocatorSummary() {
        return `text Summary`;
    }

    get qaLocatorDatatable() {
        return `datatable Logs`;
    }

    get qaLocatorNoItemsMessage() {
        return `text No Items Message`;
    }

    get qaLocatorNoAccessIllustration() {
        return `illustration NoAccess`;
    }

}