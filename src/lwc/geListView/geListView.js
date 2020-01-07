import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { dispatch, handleError, format, generateId, sort, deepClone } from 'c/utilTemplateBuilder';
import CumulusStaticResources from 'c/utilCumulusStaticResources';
import TemplateBuilderService from 'c/geTemplateBuilderService';
import GeLabelService from 'c/geLabelService';

import ID_INFO from '@salesforce/schema/Custom_Column_Header__c.Id';
import NAME_INFO from '@salesforce/schema/Custom_Column_Header__c.Name';
import FIELD_API_NAME_INFO from '@salesforce/schema/Custom_Column_Header__c.Field_Api_Name__c';
import INDEX_INFO from '@salesforce/schema/Custom_Column_Header__c.Index__c';
import LIST_NAME_INFO from '@salesforce/schema/Custom_Column_Header__c.List_Name__c';

import FORM_TEMPLATE_INFO from '@salesforce/schema/Form_Template__c';

import upsertCustomColumnHeaders from '@salesforce/apex/FORM_ServiceGiftEntry.upsertCustomColumnHeaders';
import retrieveCustomColumnHeaders from '@salesforce/apex/FORM_ServiceGiftEntry.retrieveCustomColumnHeaders';
import retrieveRecords from '@salesforce/apex/FORM_ServiceGiftEntry.retrieveRecords';

const TEMPLATE_BUILDER_TAB_NAME = 'GE_Template_Builder';
const SLDS_ICON_CATEGORY_STANDARD = 'standard';
const DEFAULT_INCREMENT_BY = 10;
const DEFAULT_LIMIT = 10;
const MAX_RECORDS = 2000;
const NAME = 'Name';
const USER = 'User';
const BY = 'By';
const URL = 'url';
const _SELF = '_self';
const DATE_FORMAT = 'M/D/YYYY, h:mm:ss A';
const ASC = 'asc';
const DESC = 'desc';
const SAVE = 'save';

const EVENT_TOGGLE_MODAL = 'togglemodal';

export default class geListView extends LightningElement {

    // Expose custom labels to template
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    @api listName;
    @api objectApiName;
    @api customIcon;
    @api title;
    @api objectName;
    @api listViewApiName;
    @api showStandardFooter;
    @api description;
    @api limit = DEFAULT_LIMIT;
    @api incrementBy = DEFAULT_INCREMENT_BY;
    @api actions;
    @api sortedBy;
    @api sortedDirection;
    @api filteredBy;

    @track objectInfo;
    @track selectedColumnHeaders;
    @track isLoading = true;
    @track options = [];
    @track records = [];
    @track columns = [];
    @track columnEntriesByName = {};
    @track selectedListView;
    @track orderedByInfo;

    columnHeadersByFieldApiName;
    isLoaded = false;

    get hasCustomTitle() {
        return this.title ? true : false;
    }

    get iconName() {
        if (this.customIcon) {
            return this.customIcon;
        }
        return this.objectInfo && this.objectInfo ?
            `${SLDS_ICON_CATEGORY_STANDARD}:${this.objectInfo.apiName}`
            : '';
    }

    get objectLabel() {
        return this.objectInfo && this.objectInfo ? this.objectInfo.label : '';
    }

    get listViewLabel() {
        return this.selectedListView ? this.selectedListView.label : '';
    }

    get recordCount() {
        const ITEM_COUNT = [this.records.length];
        return this.records.length !== 1 ?
            GeLabelService.format(this.CUSTOM_LABELS.geTextListViewItemsCount, ITEM_COUNT)
            : GeLabelService.format(this.CUSTOM_LABELS.geTextListViewItemCount, ITEM_COUNT);
    }

    get sortedByLabel() {
        const columnEntry = this.columnEntriesByName[this.sortedBy];
        if (columnEntry) {
            let sortLabel = GeLabelService.format(this.CUSTOM_LABELS.geTextListViewSortedBy, [columnEntry.label]);
            return this.sortedBy ? sortLabel : undefined;
        }
    }

    get lastUpdatedOn() {
        const isMomentLoaded = CumulusStaticResources && CumulusStaticResources.moment;
        const hasRecords = this.records && this.records.length > 0;
        if (isMomentLoaded && hasRecords) {
            let records = deepClone(this.records);
            records.sort((a, b) => {
                return new Date(b.LastModifiedDate) - new Date(a.LastModifiedDate);
            });

            const UPDATED_TIME_AGO = [CumulusStaticResources.moment(records[0].LastModifiedDate).fromNow()];
            return GeLabelService.format(this.CUSTOM_LABELS.geTextListViewUpdatedAgo, UPDATED_TIME_AGO);
        }
        return '';
    }

    get isShowStandardFooter() {
        const showFooter =
            this.showStandardFooter === 'true' ||
            this.showStandardFooter === true ||
            this.showStandardFooter === 1;
        return showFooter ? true : false;
    }

    get hasRecords() {
        return this.records && this.records.length > 0 ? true : false;
    }

    @api
    setProperty(property, value) {
        this[property] = value;
    }

    /*******************************************************************************
    * @description Public method for receiving modal related events.\
    *
    * @param {object} modalData: Event object containing the action and payload.
    * component chain: utilDualListbox -> GE_GiftEntry -> geTemplates -> here.
    */
    @api
    notify(modalData) {
        if (modalData.action === SAVE) {
            this.selectedColumnHeaders = modalData.payload.values;
            this.saveColumnHeaders();
        }
    }

    @api
    refresh() {
        this.handleImperativeRefresh();
    }

    handleImperativeRefresh = async () => {
        try {
            const displayColumns = this.buildDisplayColumns(this.selectedColumnHeaders);
            const fields = displayColumns.map(column => column.fieldApiName);
            let queryObject = this.buildSoqlQuery(fields);

            let formTemplates = await retrieveRecords({
                selectFields: queryObject.selectFields,
                sObjectApiName: queryObject.sObjectApiName,
                whereClauses: queryObject.whereClauses,
                orderByClause: queryObject.orderByClause,
                limitClause: queryObject.limitClause,
            });

            this.setDatatableRecordsForImperativeCall(formTemplates);
        } catch (e) {
            console.error(e);
            handleError(e);
        }
    }

    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    wiredObjectInfo(response) {
        if (response.data) {
            this.objectInfo = response.data;

            if (this.isLoaded === false) {
                this.init();
                this.isLoaded = true;
            }
        }
    }

    init = async () => {
        await CumulusStaticResources.init(this);
        await this.getColumnHeaderData('Templates');

        this.isLoading = false;
    }

    getColumnHeaderData = async (listViewDeveloperName) => {
        const columnHeaderData = await retrieveCustomColumnHeaders({ listName: listViewDeveloperName });

        this.selectedColumnHeaders = this.setSelectedColumnHeaders(columnHeaderData);

        this.options = this.buildFieldsToDisplayOptions(this.objectInfo.fields);

        let displayColumns = this.buildDisplayColumns(this.selectedColumnHeaders);
        this.setDatatableColumns(displayColumns);
        this.setDatatableActions();

        const fields = displayColumns.map(column => column.fieldApiName);
        let queryObject = this.buildSoqlQuery(fields);

        let formTemplates = await retrieveRecords({
            selectFields: queryObject.selectFields,
            sObjectApiName: queryObject.sObjectApiName,
            whereClauses: queryObject.whereClauses,
            orderByClause: queryObject.orderByClause,
            limitClause: queryObject.limitClause,
        });

        this.setDatatableRecordsForImperativeCall(formTemplates);
    }

    setSelectedColumnHeaders(columnHeaderData) {
        this.columnHeadersByFieldApiName = {};

        return columnHeaderData.map(column => {
            this.columnHeadersByFieldApiName[column[FIELD_API_NAME_INFO.fieldApiName]] = column;
            return column[FIELD_API_NAME_INFO.fieldApiName]
        });
    }

    buildFieldsToDisplayOptions(fields) {
        let options = [];

        Object.keys(fields).forEach(key => {
            let fieldDescribe = this.objectInfo.fields[key];
            let label = fieldDescribe.label;

            // Handle relationship info for fields looking up to a User.
            const isRelationshipField =
                fieldDescribe.relationshipName &&
                fieldDescribe.referenceToInfos &&
                fieldDescribe.referenceToInfos.length >= 1;

            if (isRelationshipField) {
                const lastWordIndex = label.lastIndexOf(" ");
                label = label.substring(0, lastWordIndex);
            }

            options.push({
                label: label,
                value: fieldDescribe.apiName
            });
        });

        return options;
    }

    buildDisplayColumns(headerFieldApiNames) {
        let displayColumns = [];
        for (let i = 0; i < headerFieldApiNames.length; i++) {
            const fieldApiName = headerFieldApiNames[i];
            const fieldDescribe = this.objectInfo.fields[fieldApiName];
            let displayColumn = {
                fieldApiName: fieldDescribe.apiName,
                label: fieldDescribe.label,
                sortable: fieldDescribe.sortable
            }

            // Handle relationship info for fields looking up to a User.
            const isRelationshipField =
                fieldDescribe.relationshipName &&
                fieldDescribe.referenceToInfos &&
                fieldDescribe.referenceToInfos.length >= 1;

            if (isRelationshipField) {
                const isUserReference = fieldDescribe.referenceToInfos.find(info => info.apiName === USER);

                if (isUserReference) {
                    const nameFields = isUserReference.nameFields;
                    const nameField = nameFields.find(field => field === NAME) || nameFields[0];

                    displayColumn.fieldApiName = `${fieldDescribe.relationshipName}.${nameField}`;
                    const lastWordIndex = displayColumn.label.lastIndexOf(" ");
                    displayColumn.label = displayColumn.label.substring(0, lastWordIndex);
                }
            }

            displayColumns.push(displayColumn);
        }


        return displayColumns;
    }

    handleChangeFieldsToDisplay(event) {
        this.selectedColumnHeaders = event.detail.value;
    }

    saveColumnHeaders = async (event) => {
        const columnHeaders = this.selectedColumnHeaders.map((fieldApiName, index) => {
            let columnHeader = this.columnHeadersByFieldApiName[fieldApiName];

            if (!columnHeader) {
                columnHeader = {};
                columnHeader[ID_INFO.fieldApiName] = this.columnHeadersByFieldApiName[fieldApiName];
                columnHeader[NAME_INFO.fieldApiName] = generateId();
                columnHeader[LIST_NAME_INFO.fieldApiName] = this.listName;
            }

            columnHeader[FIELD_API_NAME_INFO.fieldApiName] = fieldApiName;
            columnHeader[INDEX_INFO.fieldApiName] = index;

            return columnHeader;
        });

        upsertCustomColumnHeaders({
            listName: this.listName,
            columnHeadersString: JSON.stringify(columnHeaders)
        })
            .then(response => {

                this.getColumnHeaderData(this.listName)
                    .then(response => {

                    })
                    .catch(error => {
                        handleError(error);
                    });
            })
            .catch(error => {
                console.error(error);
                handleError(error);
            });
    }

    /*******************************************************************************
    * @description Method handles setting up the lightning-datatable columns based
    * on the displayColumn that's provided by the getListUi api.
    *
    * @param {object} displayColumns: Data describing the column headers for a list
    * view
    */
    setDatatableColumns(displayColumns) {
        this.columnEntriesByName = {};
        this.columns = [];

        displayColumns.forEach(column => {
            let fieldApiName = column.fieldApiName;

            // Special case for relationship references e.g. 'CreatedBy.Name'
            // so we can display the Name prop of the reference.
            if (column.fieldApiName.includes(`.${NAME}`)) {
                fieldApiName = column.fieldApiName.split('.')[0];
            }

            // Gotta create a new column object with correct properties
            // because for some reason lightning-datatable
            // requires the property 'fieldName', but we're given
            // the property 'fieldApiName' by the getListUi api
            let columnEntry = {
                label: column.label,
                fieldName: fieldApiName,
                fieldApiName: column.fieldApiName,
                sortable: column.sortable
            }

            // Turn fields in the 'Name' column into URLs
            if (fieldApiName === NAME) {
                columnEntry.type = URL;
                columnEntry.fieldName = URL;
                columnEntry.typeAttributes = {
                    label: {
                        fieldName: fieldApiName
                    },
                    target: _SELF
                }
            }

            this.columns = [...this.columns, columnEntry];
            this.columnEntriesByName[columnEntry.fieldName] = columnEntry;
        });
    }

    /*******************************************************************************
    * @description Method sets the actions for the lightning-datatable based on
    * the public property 'actions'.
    */
    setDatatableActions() {
        if (this.actions) {
            this.columns = [...this.columns, {
                type: 'action',
                typeAttributes: { rowActions: this.actions },
            }];
        }
    }

    /*******************************************************************************
    * @description Method builds a SOQL query based on the currently selected list
    * view's describe info.
    */
    buildSoqlQuery(selectedFieldApiNames) {
        // Get select fields
        const selectFields = selectedFieldApiNames.join(', ');

        // Get object name
        const sObjectApiName = this.objectApiName;

        // Get where clause
        let whereClauses;
        if (this.filteredBy && this.filteredBy.length > 0) {
            let filters = deepClone(this.filteredBy);
            whereClauses = filters.map((filter) => {
                return this.createFilterEntry(filter);
            });
        }

        // Get order by clause
        let orderByClause;
        if (this.sortedBy && this.sortedDirection) {
            const columnEntry = this.columnEntriesByName[this.sortedBy];

            if (columnEntry) {
                const sortBy = columnEntry.fieldApiName ? columnEntry.fieldApiName : this.sortedBy;
                orderByClause =
                    `${sortBy} ${this.sortedDirection === ASC ? ASC : DESC}`;
            }
        }

        // Get limit
        const limitClause = `${this.limit}`;

        return { selectFields, sObjectApiName, whereClauses, orderByClause, limitClause };
    }

    /*******************************************************************************
    * @description Method creates expressions for the where clause of a soql query.
    *
    * @param {object} filterInfo: Filter object from a list view describe that
    * contains the following fields:
    *   String: fieldApiName
    *   String: label
    *   String[]: operandLabels
    *   String: operator
    *   e.g. {fieldApiName:'CreatedBy.Name', label:'Created By', operandLabels:['John'], operator:'Equals'}
    */
    createFilterEntry(filterInfo) {
        const OPERATORS = {
            'Equals': '=',
            'NotEqual': '!=',
            'LessThan': '<',
            'GreaterThan': '>',
            'LessOrEqual': '<=',
            'GreaterOrEqual': '>=',
            'Contains': 'LIKE',
            'NotContain': 'LIKE',
            'StartsWith': 'LIKE',
        }

        const fieldName = filterInfo.fieldApiName;
        const comparisonOperator = OPERATORS[filterInfo.operator];
        const value = filterInfo.operandLabels[0];

        const isString = typeof value === 'string';
        const isNumber = typeof value === 'number';
        let filter = `${fieldName} ${comparisonOperator} `;

        if (isString && filterInfo.operator === 'Contains') {
            filter += `'%${value}%'`;

        } else if (isString && filterInfo.operator === 'NotContain') {
            filter = `NOT ${fieldName} ${comparisonOperator} '%${value}%'`

        } else if (isString && filterInfo.operator === 'StartsWith') {
            filter += `'${value}%'`

        } else if (isString) {
            filter += `'${value}'`;

        } else if (isNumber) {
            filter += `${value}`;

        }

        return filter;
    }

    /*******************************************************************************
    * @description Method handles setting up the records provided by the imperative
    * method call retrieveRecords. Some values for fields like 'CreatedBy.Name' and
    * 'LastModifiedDate' need to get parsed/reassigned so we can display more user
    * friendly values i.e. Name rather than RecordId or a formatted date.
    *
    * @param {list} dataRecords: List of sObject records
    */
    setDatatableRecordsForImperativeCall(dataRecords) {
        this.records = [];
        let recordUrl = this.getRecordUrl();

        let records = deepClone(dataRecords);
        records.forEach(record => {
            Object.keys(record).forEach(key => {
                if (record[key].Name) {
                    record[key] = record[key].Name;
                }

                const datetimeObject = CumulusStaticResources.moment(
                    record[key],
                    CumulusStaticResources.moment.ISO_8601, true);

                if (datetimeObject.isValid()) {
                    record[key] = CumulusStaticResources.moment(record[key]).format(DATE_FORMAT);
                }
            });

            record[URL] = format(recordUrl, [record.Id]);

            this.records = [...this.records, record];
        });
    }

    /*******************************************************************************
    * @description Method builds the url to be used for the 'Name' column in the
    * list view lightning-datatable. We're special casing the url for the
    * Form_Template__c object specifically to go to the Template Builder.
    */
    getRecordUrl() {
        let url;

        if (this.objectApiName === FORM_TEMPLATE_INFO.objectApiName) {
            const builderTabApiName =
                TemplateBuilderService.alignSchemaNSWithEnvironment(TEMPLATE_BUILDER_TAB_NAME);

            url = `/lightning/n/${builderTabApiName}?c__recordId={0}`;
        } else {
            url = `/lightning/r/${this.objectApiName}/{0}/view`;
        }

        const builderTabApiName =
            TemplateBuilderService.alignSchemaNSWithEnvironment(TEMPLATE_BUILDER_TAB_NAME);

        url = `/lightning/n/${builderTabApiName}?c__recordId={0}`;

        return url;
    }

    /*******************************************************************************
    * @description Handles the onsort event from the lightning:datatable
    *
    * @param {object} event: Event holding column details of the action
    */
    handleColumnSorting(event) {
        this.sortedBy = event.detail.fieldName;
        const columnEntry = this.columnEntriesByName[this.sortedBy];
        this.sortedDirection = event.detail.sortDirection;

        // Set sortedBy to correct fieldName if a URL type column.
        let sortedBy =
            columnEntry.typeAttributes ? columnEntry.typeAttributes.label.fieldName : this.sortedBy;

        this.records = sort(this.records, sortedBy, this.sortedDirection, false);
    }

    /*******************************************************************************
    * @description Handles the rowaction event from lightning-datable and dispatches
    * an event to notify parent component.
    *
    * @param {object} event: Event holding row action details
    */
    handleRowAction(event) {
        dispatch(this, 'rowaction', event.detail);
    }

    /*******************************************************************************
    * @description Handles increasing the pageSize for the list-view and loading
    * more records.
    */
    handleViewMore = async () => {
        const NEW_LIMIT = Number(this.limit) + this.incrementBy;
        this.limit = NEW_LIMIT < MAX_RECORDS ? NEW_LIMIT : MAX_RECORDS;

        await this.getColumnHeaderData(this.listName);
    }

    /*******************************************************************************
    * @description Handles increasing the pageSize for the list-view and loading
    * more records.
    */
    toggleModal(event) {
        event.stopPropagation();
        const detail = {
            options: this.options,
            values: this.selectedColumnHeaders,
            name: this.listName,
            sourceLabel: this.CUSTOM_LABELS.geLabelCustomTableSourceFields,
            selectedLabel: this.CUSTOM_LABELS.geLabelCustomTableSelectedFields,
        };

        dispatch(this, EVENT_TOGGLE_MODAL, detail);
    }
}