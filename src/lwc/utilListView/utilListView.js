import { LightningElement, api, track, wire } from 'lwc';
import { getListUi } from 'lightning/uiListApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { deepClone, dispatch, sort, handleError, format } from 'c/utilTemplateBuilder';
import { NavigationMixin } from 'lightning/navigation'
import CumulusStaticResources from 'c/utilCumulusStaticResources';
import TemplateBuilderService from 'c/geTemplateBuilderService';
import GeLabelService from 'c/geLabelService';

import FORM_TEMPLATE_INFO from '@salesforce/schema/Form_Template__c';

const TEMPLATE_BUILDER_TAB_NAME = '{0}GE_Template_Builder';
const SLDS_ICON_CATEGORY_STANDARD = 'standard';
const INCREMENT_BY = 10;
const MAX_RECORDS = 2000;

export default class utilListView extends NavigationMixin(LightningElement) {

    // Expose custom labels to template
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    @api customIcon;
    @api title;
    @api objectName;
    @api listViewApiName;
    @api showStandardFooter;
    @api description;
    @api limit = 10;
    @api actions;
    @api sortedBy;
    @api sortDirection;

    @track isLoading = true;
    @track options = [];
    @track records = [];
    @track columns = [];
    @track columnLabelsByName = {};
    @track selectedListView;

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
        if (this.columnLabelsByName && this.sortedBy) {
            const SORTED_BY = [this.columnLabelsByName[this.sortedBy]];
            return GeLabelService.format(this.CUSTOM_LABELS.geTextListViewSortedBy, SORTED_BY);
        }
        return '';
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

    connectedCallback() {
        this.init();
    }

    /*******************************************************************************
    * @description Method to initialize the utilCumulusStaticResources service
    * component. Currently only imports and loads moment.js from a packaged static
    * resource.
    */
    init = async () => {
        await CumulusStaticResources.init(this);
    }

    /*******************************************************************************
    * @description Wired method for getting the object describe info based on the
    * provided object api name.
    *
    * @param {string} objectApiName: SObject api name
    */
    @wire(getObjectInfo, { objectApiName: '$objectName' })
    getObjectInfo({ error, data }) {
        if (data) {
            this.objectInfo = data;
        }

        if (error) {
            handleError(error);
            this.isLoading = false;
        }
    }

    /*******************************************************************************
    * @description Wired method for getting list views metadata.
    *
    * @param {string} objectApiName: SObject api name
    */
    @wire(getListUi, { objectApiName: '$objectInfo.apiName' })
    getListViews({ error, data }) {
        if (data) {
            data.lists.forEach(listView => {
                let option = {
                    label: listView.label,
                    value: TemplateBuilderService.alignSchemaNSWithEnvironment(listView.apiName)
                }

                this.options = [...this.options, option];
            });

            if (!this.customIcon) {
                this.setDefaultIcon();
            }

            if (this.listViewApiName === undefined && this.options[0]) {
                this.listViewApiName = this.options[0].value;
            }
        }

        if (error) {
            handleError(error);
            this.isLoading = false;
        }
    }

    /*******************************************************************************
    * @description Wired method for getting sobject records based on the currently
    * selected list view.
    *
    * @param {string} objectApiName: SObject api name
    * @param {string} listViewApiName: List View api name
    * @param {string} pageSize: Number of records to retrieve
    */
    @wire(getListUi, {
        objectApiName: '$objectInfo.apiName',
        listViewApiName: '$listViewApiName',
        pageSize: '$limit'
    })
    getRecordByListViewApiName({ error, data }) {
        if (data && data.info && data.records) {
            this.selectedListView = data.info;
            this.setDatatableColumns(data.info.displayColumns);
            this.setDatatableActions();
            this.setDatatableRecords(data.records.records);
            this.setDatatableOrder(data.info.orderedByInfo);

            this.isLoading = false;
        }

        if (error) {
            handleError(error);
            this.isLoading = false;
        }
    }

    /*******************************************************************************
    * @description Method handles setting up the lightning-datatable columns based
    * on the displayColumn that's provided by the getListUi api.
    *
    * @param {object} displayColumns: Data describing the column headers for a list
    * view
    */
    setDatatableColumns(displayColumns) {
        this.columnLabelsByName = {};
        this.columns = [];

        displayColumns.forEach(column => {
            let fieldApiName = column.fieldApiName;

            // Special case for relationship references e.g. 'CreatedBy.Name'
            // so we can display the Name prop of the reference.
            if (column.fieldApiName.includes('.Name')) {
                fieldApiName = column.fieldApiName.split('.')[0];
            }

            // Gotta create a new column object with correct properties
            // because for some reason lightning-datatable
            // requires the property 'fieldName', but we're given
            // the property 'fieldApiName' by the getListUi api
            let columnEntry = {
                label: column.label,
                fieldName: fieldApiName,
                sortable: column.sortable
            }

            // Turn fields in the 'Name' column into URLs
            if (fieldApiName === 'Name') {
                columnEntry.type = 'url';
                columnEntry.fieldName = 'URL';
                columnEntry.typeAttributes = {
                    label: {
                        fieldName: 'Name'
                    },
                    target: '_self'
                }
            }

            this.columns = [...this.columns, columnEntry];
            this.columnLabelsByName[fieldApiName] = column.label;
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
    * @description Method handles setting up the records provided by the getListUi
    * api. Some values for fields like 'CreatedBy.Name' need to get reassigned to
    * displayValue so we can display more user friendly values i.e. Name rather
    * than RecordId or blank.
    *
    * @param {list} dataRecords: List of sObject records
    */
    setDatatableRecords(dataRecords) {
        this.records = [];
        let records = deepClone(dataRecords);
        let recordUrl = this.getRecordUrl();

        records.forEach(record => {
            Object.keys(record.fields).forEach(key => {
                const displayValue = record.fields[key].displayValue;
                const value = record.fields[key].value;

                record.fields[key] = displayValue ? displayValue : value;
            });

            record.fields.URL = format(recordUrl, [record.id]);

            this.records = [...this.records, record.fields];
        });
    }

    /*******************************************************************************
    * @description Method builds the url to be used for the 'Name' column in the
    * list view lightning-datatable. We're special casing the url for the
    * Form_Template__c object specifically to go to the Template Builder.
    */
    getRecordUrl() {
        let url;

        if (this.objectName === FORM_TEMPLATE_INFO.objectApiName) {
            const currentNamespace = TemplateBuilderService.namespaceWrapper.currentNamespace;
            const namespacePrefix = `${currentNamespace}__`;

            const builderTabApiName = currentNamespace ?
                format(TEMPLATE_BUILDER_TAB_NAME, [namespacePrefix])
                : format(TEMPLATE_BUILDER_TAB_NAME, ['']);

            url = `/lightning/n/${builderTabApiName}?c__recordId={0}`;
        } else {
            url = `/lightning/r/${this.objectName}/{0}/view`;
        }

        return url;
    }

    /*******************************************************************************
    * @description Method attempts to set the lightning-datatable sort order based
    * on the public properties 'sortedBy' and 'sortDirection' if provided. Otherwise
    * falls back on the sort order of the currently selected list view.
    *
    * @param {object} orderedByInfo: Data describing the sort order for a list view
    */
    setDatatableOrder(orderedByInfo) {
        if (orderedByInfo && orderedByInfo.length > 0) {
            const detail = {
                fieldName: this.sortedBy || orderedByInfo[0].fieldApiName,
                sortDirection: (this.sortDirection) || (orderedByInfo[0].isAscending ? 'asc' : 'desc')
            };
            this.handleColumnSorting({ detail: detail });
        }
    }

    /*******************************************************************************
    * @description Method attempts to set a default slds icon based on the provided
    * object describe info e.g. 'standard:account', 'custom:custom24', etc.
    */
    setDefaultIcon() {
        const themeInfo = this.objectInfo.themeInfo;
        if (themeInfo && themeInfo.iconUrl) {
            const iconNameRegex = /(.*)\/(.*)_/gm;
            const iconNameMatches = iconNameRegex.exec(themeInfo.iconUrl);

            const typeRegex = /(.*)\/(.*)\//gm;
            const typeMatches = typeRegex.exec(themeInfo.iconUrl);

            this.customIcon = `${typeMatches[2]}:${iconNameMatches[2]}`;
        }
    }

    /*******************************************************************************
    * @description Navigates to an object list view page based on the currently
    * selected list view.
    */
    navigateToListView() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.objectName,
                actionName: 'list'
            },
            state: {
                // 'filterName' is the property on the page 'state'
                // that determines what list view to open.
                // Can be a List View api name or List View id
                filterName: this.listViewApiName
            }
        });
    }

    /*******************************************************************************
    * @description Handles the rowaction event from lightning-datable and dispatches
    * an event to notify parent component.
    *
    * @param {object} event: Combobox onchange event
    */
    handleChange(event) {
        this.listViewApiName = event.detail.value;
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
    * @description Handles the onsort event from the lightning:datatable
    *
    * @param {object} event: Event holding column details of the action
    */
    handleColumnSorting(event) {
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        this.records = sort(this.records, this.sortedBy, this.sortedDirection);
    }

    /*******************************************************************************
    * @description Handles increasing the pageSize for the list-view and loading
    * more records.
    */
    handleViewMore() {
        const NEW_LIMIT = Number(this.limit) + INCREMENT_BY;
        this.limit = NEW_LIMIT < MAX_RECORDS ? NEW_LIMIT : MAX_RECORDS;
    }
}