import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { dispatch, handleError, generateId, showToast } from 'c/utilTemplateBuilder';
import { format, sort, deepClone } from 'c/utilCommon';
import LibsMoment from 'c/libsMoment';
import TemplateBuilderService from 'c/geTemplateBuilderService';
import GeLabelService from 'c/geLabelService';
import upsertCustomColumnHeaders from '@salesforce/apex/FORM_ServiceGiftEntry.upsertCustomColumnHeaders';
import retrieveCustomColumnHeaders from '@salesforce/apex/FORM_ServiceGiftEntry.retrieveCustomColumnHeaders';
import retrieveRecords from '@salesforce/apex/FORM_ServiceGiftEntry.retrieveRecords';

import COLUMN_ID_INFO from '@salesforce/schema/Custom_Column_Header__c.Id';
import COLUMN_NAME_INFO from '@salesforce/schema/Custom_Column_Header__c.Name';
import COLUMN_FIELD_API_NAME_INFO from '@salesforce/schema/Custom_Column_Header__c.Field_Api_Name__c';
import COLUMN_INDEX_INFO from '@salesforce/schema/Custom_Column_Header__c.Index__c';
import COLUMN_LIST_NAME_INFO from '@salesforce/schema/Custom_Column_Header__c.List_Name__c';

import FORM_TEMPLATE_INFO from '@salesforce/schema/Form_Template__c';
// import default templates list view column header fields describe info
import FORM_TEMPLATE_NAME_INFO from '@salesforce/schema/Form_Template__c.Name';
import FORM_TEMPLATE_DESCRIPTION_INFO from '@salesforce/schema/Form_Template__c.Description__c';
import FORM_TEMPLATE_CREATED_BY_INFO from '@salesforce/schema/Form_Template__c.CreatedById';
import FORM_TEMPLATE_LAST_MODIFIED_DATE_INFO from '@salesforce/schema/Form_Template__c.LastModifiedDate';

const TEMPLATES = 'Templates';
const TEMPLATE_BUILDER_TAB_NAME = 'GE_Template_Builder';
const SLDS_ICON_CATEGORY_STANDARD = 'standard';
const DEFAULT_INCREMENT_BY = 10;
const DEFAULT_LIMIT = 10;
const MAX_RECORDS = 2000;
const NAME = 'Name';
const USER = 'User';
const URL = 'url';
const _SELF = '_self';
const DATE_FORMAT = 'M/D/YYYY, h:mm:ss A';
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

    get recordsToDisplay() {
        if (this.actions && this.columns.length === 1) {
            return [];
        }
        return this.records;
    }

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
        const ITEM_COUNT = [this.recordsToDisplay.length];
        return this.recordsToDisplay.length !== 1 ?
            GeLabelService.format(this.CUSTOM_LABELS.geTextListViewItemsCount, ITEM_COUNT)
            : GeLabelService.format(this.CUSTOM_LABELS.geTextListViewItemCount, ITEM_COUNT);
    }

    get sortedByLabel() {
        const columnEntry = this.columnEntriesByName[this.sortedBy];
        if (columnEntry) {
            let sortLabel = GeLabelService.format(this.CUSTOM_LABELS.geTextListViewSortedBy, [columnEntry.label]);
            return this.sortedBy ? sortLabel : undefined;
        }
        return undefined;
    }

    get lastUpdatedOn() {
        const isMomentLoaded = LibsMoment && LibsMoment.moment;
        if (isMomentLoaded && this.hasRecords) {
            let records = deepClone(this.records);
            records.sort((a, b) => {
                return new Date(b.LastModifiedDate) - new Date(a.LastModifiedDate);
            });

            const UPDATED_TIME_AGO = [LibsMoment.moment(records[0].LastModifiedDate).fromNow()];
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
        return this.recordsToDisplay && this.recordsToDisplay.length > 0 ? true : false;
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
            this.saveColumnHeaders(modalData.payload.values);
        }
    }

    /*******************************************************************************
    * @description Public method to force a refresh of the list view.
    */
    @api
    refresh() {
        this.handleImperativeRefresh();
    }

    handleImperativeRefresh = async () => {
        this.isLoading = true;
        const displayColumns = this.buildDisplayColumns(this.selectedColumnHeaders);
        await this.getRecords(displayColumns)
            .catch(error => {
                handleError(error);
            });
        this.isLoading = false;
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
        // Initialize static resources if not already initialized (moment.js)
        await LibsMoment.init(this);

        // Set 'Available Fields' options for the column headers
        this.options = this.buildFieldsToDisplayOptions(this.objectInfo.fields);

        // Get column header data
        let columnHeaderData = await this.getColumnHeaderData(this.listName)
            .catch(error => {
                handleError(error);
            });

        if (columnHeaderData === null || columnHeaderData.length < 1) {
            columnHeaderData = this.buildDefaultColumnHeadersData(this.listName);
        }

        // Set currently selected column headers
        this.selectedColumnHeaders = this.setSelectedColumnHeaders(columnHeaderData);

        // Build the columns for the datatable using the currently selected column headers
        const displayColumns = this.buildDisplayColumns(this.selectedColumnHeaders);

        // Set the datatable columns
        this.setDatatableColumns(displayColumns);

        // Set the datatable actions
        this.setDatatableActions();

        // Get records
        await this.getRecords(displayColumns)
            .catch(error => {
                handleError(error);
            });

        this.isLoading = false;
    }

    /*******************************************************************************
    * @description Method takes in the currently selected column headers and builds
    * a query string that's used to get records with the relevant fields.
    *
    * @param {list} displayColumns: List of display columns used by lightning-datatable.
    */
    getRecords = async (displayColumns) => {
        const fields = displayColumns.map(column => column.fieldApiName);
        if (fields.length > 0) {
            let orderBy = null;
            if (this.sortedBy && this.sortedDirection) {
                const orderedByFieldApiName = this.columnEntriesByName[this.sortedBy].fieldApiName;
                orderBy = `${orderedByFieldApiName} ${this.sortedDirection}`;
            }

            let formTemplates = await retrieveRecords({
                selectFields: fields,
                sObjectApiName: this.objectApiName,
                orderByClause: orderBy,
                limitClause: this.limit
            })
                .catch(error => {
                    handleError(error);
                });

            this.setDatatableRecordsForImperativeCall(formTemplates);
        }
    }

    /*******************************************************************************
    * @description Method retrieves the column header data held in the List Custom
    * Setting Custom_Column_Header__c records.
    *
    * @param {string} listViewDeveloperName: The value held in the List_Name__c of
    * the Custom_Column_Header__c List Custom Setting.
    */
    getColumnHeaderData = async (listViewDeveloperName) => {
        return retrieveCustomColumnHeaders({ listName: listViewDeveloperName })
            .catch(error => {
                handleError(error);
            });
    }

    /*******************************************************************************
    * @description Method sets the columnHeadersByFieldApiName map. Map conatains
    * currently selected column headers and is used to quickly find a column header
    * records based on their target field api name.
    *
    * @param {list} columnHeaderData: List of Custom_Column_Header__c records.
    */
    setSelectedColumnHeaders(columnHeaderData) {
        this.columnHeadersByFieldApiName = {};

        return columnHeaderData.map(column => {
            this.columnHeadersByFieldApiName[column[COLUMN_FIELD_API_NAME_INFO.fieldApiName]] = column;
            return column[COLUMN_FIELD_API_NAME_INFO.fieldApiName]
        });
    }

    /*******************************************************************************
    * @description Method sets the default column headers for a given list if no
    * headers exist.
    *
    * @param {string} listName: Name of the list to create default headers for
    */
    buildDefaultColumnHeadersData(listName) {
        let defaultFields = [];
        let defaultColumnHeaders = [];

        if (listName === TEMPLATES) {
            defaultFields = [
                FORM_TEMPLATE_NAME_INFO.fieldApiName,
                FORM_TEMPLATE_DESCRIPTION_INFO.fieldApiName,
                FORM_TEMPLATE_CREATED_BY_INFO.fieldApiName,
                FORM_TEMPLATE_LAST_MODIFIED_DATE_INFO.fieldApiName,
            ];
        }

        for (let i = 0; i < defaultFields.length; i++) {
            defaultColumnHeaders.push(this.constructColumnHeader(defaultFields[i], i, listName));
        }

        return defaultColumnHeaders;
    }

    /*******************************************************************************
    * @description Method constructs an instance of Custom_Column_Header__c.
    *
    * @param {string} fieldApiName: Field Api Name of a field from an SObject.
    * @param {integer} index: Desired position of the column header in the table.
    * @param {string} listName: Value of the List_Name__c field in the
    * Custom_Column_Header__c object for grouping a collection of headers.
    */
    constructColumnHeader(fieldApiName, index, listName) {
        let columnHeader = {};
        columnHeader[COLUMN_ID_INFO.fieldApiName] = undefined;
        columnHeader[COLUMN_NAME_INFO.fieldApiName] = generateId();
        columnHeader[COLUMN_FIELD_API_NAME_INFO.fieldApiName] = fieldApiName;
        columnHeader[COLUMN_INDEX_INFO.fieldApiName] = index;
        columnHeader[COLUMN_LIST_NAME_INFO.fieldApiName] = listName;

        return columnHeader;
    }

    /*******************************************************************************
    * @description Method builds a list of options used to populate the available
    * fields in the utilDualListbox component. utilDualListbox is used in the list
    * settings modal.
    *
    * @param {list} fields: List of fields from the object describe info.
    */
    buildFieldsToDisplayOptions(fields) {
        let options = [];

        Object.keys(fields).forEach(key => {
            let fieldDescribe = this.objectInfo.fields[key];
            let label = fieldDescribe.label;

            options.push({
                label: label,
                value: fieldDescribe.apiName
            });
        });

        return options;
    }

    /*******************************************************************************
    * @description Method builds a list of options used to populate the available
    * fields in the utilDualListbox component. utilDualListbox is used in the list
    * settings modal.
    *
    * @param {list} fields: List of fields from the object describe info.
    */
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
                const reference = fieldDescribe.referenceToInfos[0];
                const isUserReference = fieldDescribe.referenceToInfos.find(info => info.apiName === USER);

                const nameFields = isUserReference ? isUserReference.nameFields : reference.nameFields;
                const nameField = nameFields.find(field => field === NAME) || nameFields[0];

                displayColumn.fieldApiName = `${fieldDescribe.relationshipName}.${nameField}`;
            }

            displayColumns.push(displayColumn);
        }


        return displayColumns;
    }

    /*******************************************************************************
    * @description Method handles the save action in the list view settings modal.
    */
    saveColumnHeaders = async (updatedColumnHeaders) => {
        this.isLoading = true;
        this.selectedColumnHeaders = updatedColumnHeaders;
        const columnHeaders = this.prepareColumnHeadersForSave(updatedColumnHeaders);

        upsertCustomColumnHeaders({
            listName: this.listName,
            columnHeadersString: JSON.stringify(columnHeaders)
        })
            .then(() => {
                this.init();
                showToast(this.CUSTOM_LABELS.geToastListViewUpdated, '', 'success');
            })
            .catch(error => {
                handleError(error);
            })
            .finally(() => {
                this.isLoading = false;
            })
    }

    /*******************************************************************************
    * @description Method prepares the provided column headers to be saved.
    */
    prepareColumnHeadersForSave(updatedColumnHeaders) {
        return updatedColumnHeaders.map((fieldApiName, index) => {
            let columnHeader = this.columnHeadersByFieldApiName[fieldApiName];

            if (!columnHeader) {
                columnHeader = {};
                columnHeader[COLUMN_ID_INFO.fieldApiName] = this.columnHeadersByFieldApiName[fieldApiName];
                columnHeader[COLUMN_NAME_INFO.fieldApiName] = generateId();
                columnHeader[COLUMN_LIST_NAME_INFO.fieldApiName] = this.listName;
            }

            columnHeader[COLUMN_FIELD_API_NAME_INFO.fieldApiName] = fieldApiName;
            columnHeader[COLUMN_INDEX_INFO.fieldApiName] = index;

            return columnHeader;
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

                const datetimeObject = LibsMoment.moment(
                    record[key],
                    LibsMoment.moment.ISO_8601, true);

                if (datetimeObject.isValid()) {
                    record[key] = LibsMoment.moment(record[key]).format(DATE_FORMAT);
                }

                if (typeof record[key] !== 'string') {
                    record[key] = record[key].toString();
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

        this.refresh();
    }

    /*******************************************************************************
    * @description Handles increasing the pageSize for the list-view and loading
    * more records.
    */
    toggleModal(event) {
        event.stopPropagation();
        const detail = {
            componentProperties: {
                cssClass: 'slds-m-bottom_medium slds-p-horizontal_small',
                name: this.listName,
                options: this.options,
                values: this.selectedColumnHeaders,
                sourceLabel: this.CUSTOM_LABELS.geLabelCustomTableSourceFields,
                selectedLabel: this.CUSTOM_LABELS.geLabelCustomTableSelectedFields,
                showModalFooter: true,
                dedicatedListenerEventName: 'geGiftEntryModalEvent'
            },
            modalProperties: {
                componentName: 'utilDualListbox',
                header: this.CUSTOM_LABELS.geHeaderCustomTableHeaders,
                showCloseButton: true,
            }
        };

        dispatch(this, EVENT_TOGGLE_MODAL, detail);
    }
}