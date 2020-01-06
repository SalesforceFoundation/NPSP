import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { handleError, format } from 'c/utilTemplateBuilder';
import CumulusStaticResources from 'c/utilCumulusStaticResources';
import TemplateBuilderService from 'c/geTemplateBuilderService';
import GeLabelService from 'c/geLabelService';

import DEVELOPER_NAME_INFO from '@salesforce/schema/Gift_Entry_Column_Header__mdt.DeveloperName';
import MASTER_LABEL_INFO from '@salesforce/schema/Gift_Entry_Column_Header__mdt.MasterLabel';
import COLUMN_HEADERS_INFO from '@salesforce/schema/Gift_Entry_Column_Header__mdt.Column_Headers__c';

import FORM_TEMPLATE_INFO from '@salesforce/schema/Form_Template__c';

import createGiftEntryColumn from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.createGiftEntryColumn';
import retrieveColumHeaders from '@salesforce/apex/FORM_ServiceGiftEntry.retrieveColumnHeaderMetadataRecords';
import retrieveRecords from '@salesforce/apex/FORM_ServiceGiftEntry.retrieveRecords';

const TEMPLATE_BUILDER_TAB_NAME = 'GE_Template_Builder';
const SLDS_ICON_CATEGORY_STANDARD = 'standard';
const DEFAULT_INCREMENT_BY = 10;
const DEFAULT_LIMIT = 10;
const MAX_RECORDS = 2000;

export default class geListView extends LightningElement {

    // Expose custom labels to template
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    @api listView;
    @api objectApiName;
    @api limit = 50;
    @api showStandardFooter;

    @track records;
    @track objectInfo;
    @track options = [];
    @track selectedColumnHeaders;

    @track columns;
    @track columnEntriesByName;

    isLoaded = false;

    get hasRecords() {
        return this.records && this.records.length > 0 ? true : false;
    }

    get isShowStandardFooter() {
        const showFooter =
            this.showStandardFooter === 'true' ||
            this.showStandardFooter === true ||
            this.showStandardFooter === 1;
        return showFooter ? true : false;
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
        console.log('listView: ', this.listView);
        console.log('objectApiName: ', this.objectApiName);
        console.log('COLUMN_HEADERS_INFO: ', COLUMN_HEADERS_INFO);
        await CumulusStaticResources.init(this);
        await this.getColumnHeaderData('Templates');
    }

    getColumnHeaderData = async (listViewDeveloperName) => {
        const giftEntryColumnHeader = await retrieveColumHeaders({ developerName: listViewDeveloperName });
        console.log('giftEntryColumnHeader: ', giftEntryColumnHeader);
        console.log(giftEntryColumnHeader[COLUMN_HEADERS_INFO.fieldApiName]);
        const headers = JSON.parse(giftEntryColumnHeader[COLUMN_HEADERS_INFO.fieldApiName]);
        console.log('headers: ', headers);
        this.selectedColumnHeaders = headers;
        console.log('objectInfo: ', this.objectInfo);

        this.options = this.buildFieldsToDisplayOptions(this.objectInfo.fields);

        let displayColumns = this.buildDisplayColumns(headers);
        this.setDatatableColumns(displayColumns);

        let queryObject = this.buildSoqlQuery(headers);
        console.log('queryObject: ', queryObject);

        let formTemplates = await retrieveRecords({
            selectFields: queryObject.selectFields,
            sObjectApiName: queryObject.sObjectApiName,
            whereClauses: null,//queryObject.whereClauses,
            orderByClause: null,//queryObject.orderByClause,
            limitClause: queryObject.limitClause,
        });
        console.log('formTemplates: ', formTemplates);
        this.setDatatableRecordsForImperativeCall(formTemplates);

        console.log('this.options: ', this.options);
    }

    buildDisplayColumns(headerFieldApiNames) {
        console.log('**************--- buildDisplayColumns');
        let displayColumns = [];
        for (let i = 0; i < headerFieldApiNames.length; i++) {
            const fieldApiName = headerFieldApiNames[i];
            const fieldDescribe = this.objectInfo.fields[fieldApiName];
            let displayColumn = {
                fieldApiName: fieldDescribe.apiName,
                label: fieldDescribe.label,
                sortable: fieldDescribe.sortable
            }

            console.log('Column: ', displayColumn);
            displayColumns.push(displayColumn);
        }

        return displayColumns;
    }

    buildFieldsToDisplayOptions(fields) {
        console.log('**************--- buildFieldsToDisplayOptions');
        let options = [];

        Object.keys(fields).forEach(key => {
            let field = this.objectInfo.fields[key];

            options.push({
                label: field.label,
                value: field.apiName
            });
        });

        return options;
    }


    handleChangeFieldsToDisplay(event) {
        console.log('selected headers: ', event.detail.value);
        this.selectedColumnHeaders = event.detail.value;
    }

    handleColumnHeaderChange(event) {
        console.log('handleColumnHeaderChange');

        const columnHeaders = JSON.stringify(this.selectedColumnHeaders.map((val, index) => { return val }));
        console.log('columnHeaders: ', columnHeaders);

        const listView = {};
        listView[DEVELOPER_NAME_INFO.fieldApiName] = 'Templates';
        listView[MASTER_LABEL_INFO.fieldApiName] = 'Templates';
        listView[COLUMN_HEADERS_INFO.fieldApiName] = columnHeaders;

        createGiftEntryColumn({ giftEntryListViewString: JSON.stringify(listView) })
            .then(response => {
                console.log('Response: ', response);

                let displayColumns = this.buildDisplayColumns(JSON.parse(columnHeaders));
                this.setDatatableColumns(displayColumns);

                let queryObject = this.buildSoqlQuery(JSON.parse(columnHeaders));
                console.log('queryObject: ', queryObject);

                retrieveRecords({
                    selectFields: queryObject.selectFields,
                    sObjectApiName: queryObject.sObjectApiName,
                    whereClauses: null,//queryObject.whereClauses,
                    orderByClause: null,//queryObject.orderByClause,
                    limitClause: queryObject.limitClause,
                })
                    .then(response => {
                        let formTemplates = response;
                        console.log('formTemplates: ', formTemplates);
                        this.setDatatableRecordsForImperativeCall(formTemplates);
                    })
                    .catch(error => {
                        console.error(error);
                        handleError(error);
                    })
            })
            .catch(error => {
                console.error(error);
                handleError(error);
            })
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
                columnEntry.fieldName = fieldApiName;
                columnEntry.typeAttributes = {
                    label: {
                        fieldName: fieldApiName
                    },
                    target: '_self'
                }
            }

            this.columns = [...this.columns, columnEntry];
            this.columnEntriesByName[columnEntry.fieldName] = columnEntry;
        });
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
        /*let whereClauses;
        let filters = this.selectedListView.filteredByInfo;
        if (filters && filters.length > 0) {
            whereClauses = filters.map((filter) => {
                return this.createFilterEntry(filter);
            });
        }*/

        // Get order by clause
        /*let orderByClause;
        if (this.orderedByInfo && this.orderedByInfo.length === 1) {
            orderByClause =
                `${this.orderedByInfo[0].fieldApiName} ${this.orderedByInfo[0].isAscending ? 'ASC' : 'DESC'}`;
        }*/

        // Get limit
        const limitClause = `${this.limit}`;

        return { selectFields, sObjectApiName, /*whereClauses, /*orderByClause,*/ limitClause };
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

        dataRecords.forEach(record => {
            Object.keys(record).forEach(key => {
                if (record[key].Name) {
                    record[key] = record[key].Name;
                }

                const datetimeObject = CumulusStaticResources.moment(
                    record[key],
                    CumulusStaticResources.moment.ISO_8601, true);

                if (datetimeObject.isValid()) {
                    record[key] = CumulusStaticResources.moment(record[key]).format('MM/DD/YYYY, h:mm A');
                }
            });

            record.URL = format(recordUrl, [record.Id]);

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

        /*if (this.objectName === this.objectApiName) {
            const builderTabApiName =
                TemplateBuilderService.alignSchemaNSWithEnvironment(TEMPLATE_BUILDER_TAB_NAME);

            url = `/lightning/n/${builderTabApiName}?c__recordId={0}`;
        } else {
            url = `/lightning/r/${this.objectName}/{0}/view`;
        }*/

        const builderTabApiName =
            TemplateBuilderService.alignSchemaNSWithEnvironment(TEMPLATE_BUILDER_TAB_NAME);

        url = `/lightning/n/${builderTabApiName}?c__recordId={0}`;

        return url;
    }
}