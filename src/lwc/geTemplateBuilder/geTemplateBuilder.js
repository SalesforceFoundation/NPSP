import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import storeFormTemplate from '@salesforce/apex/GE_GiftEntryController.storeFormTemplate';
import retrieveFormTemplateById from '@salesforce/apex/GE_GiftEntryController.retrieveFormTemplateById';
import TemplateBuilderService from 'c/geTemplateBuilderService';
import GeLabelService from 'c/geLabelService';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import {
    dispatch,
    handleError,
    findMissingRequiredFieldMappings,
    findMissingRequiredBatchFields,
    generateId,
    ADDITIONAL_REQUIRED_BATCH_HEADER_FIELDS,
    DEFAULT_BATCH_HEADER_FIELDS,
    EXCLUDED_BATCH_HEADER_FIELDS,
    DEFAULT_FORM_FIELDS
} from 'c/utilTemplateBuilder';
import {
    mutable,
    findIndexByProperty,
    getQueryParameters,
    shiftToIndex,
    sort,
    showToast,
    getNamespace,
    removeByProperty,
    removeFromArray,
    isEmpty,
    hasNestedProperty,
    apiNameFor
} from 'c/utilCommon';
import DATA_IMPORT_BATCH_OBJECT from '@salesforce/schema/DataImportBatch__c';
import DATA_IMPORT_BATCH_TABLE_COLUMNS_FIELD from '@salesforce/schema/DataImportBatch__c.Batch_Table_Columns__c';
import DONATION_RECORD_TYPE_NAME from '@salesforce/schema/DataImport__c.Donation_Record_Type_Name__c';

// imports used for default batch table column headers
import DATA_IMPORT_OBJECT from '@salesforce/schema/DataImport__c';
import DONATION_AMOUNT_FIELD from '@salesforce/schema/DataImport__c.Donation_Amount__c';
import DONATION_DATE_FIELD from '@salesforce/schema/DataImport__c.Donation_Date__c';
import DONATION_CAMPAIGN_SOURCE_FIELD from '@salesforce/schema/DataImport__c.DonationCampaignImported__c';
import STATUS_FIELD from '@salesforce/schema/DataImport__c.Status__c';
import FAILURE_INFORMATION_FIELD from '@salesforce/schema/DataImport__c.FailureInformation__c';
import ELEVATE_PAYMENT_STATUS from '@salesforce/schema/DataImport__c.Elevate_Payment_Status__c';

const DEFAULT_BATCH_TABLE_HEADERS_WITH_FIELD_MAPPINGS = [
    DONATION_AMOUNT_FIELD.fieldApiName,
    DONATION_DATE_FIELD.fieldApiName,
    DONATION_CAMPAIGN_SOURCE_FIELD.fieldApiName,
    STATUS_FIELD.fieldApiName,
    FAILURE_INFORMATION_FIELD.fieldApiName,
];

const SKIPPED_BATCH_TABLE_HEADER_FIELDS = [
    DONATION_AMOUNT_FIELD.fieldApiName,
    DONATION_DATE_FIELD.fieldApiName,
    DONATION_CAMPAIGN_SOURCE_FIELD.fieldApiName,
    STATUS_FIELD.fieldApiName,
    FAILURE_INFORMATION_FIELD.fieldApiName,
];

const FORMAT_VERSION = '1.0';
const DEFAULT_FIELD_MAPPING_SET = 'Migrated_Custom_Field_Mapping_Set';
const GIFT_ENTRY = 'Gift_Entry';
const SORTED_BY = 'required';
const SORT_ORDER = 'desc';
const PICKLIST = 'Picklist';
const BOOLEAN = 'Boolean';
const NEW = 'new';
const EDIT = 'edit';
const SAVE = 'save';
const DELETE = 'delete';
const API_NAME = 'apiName';
const ID = 'id';
const SUCCESS = 'success';
const ERROR = 'error';
const EVENT_TOGGLE_MODAL = 'togglemodal';
const WARNING = 'warning';
const FIELD = 'field';
const FIELDS = 'fields';
const WIDGET = 'widget';
const VALUE = 'value';

export default class geTemplateBuilder extends NavigationMixin(LightningElement) {

    // Expose label service to template
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    /*******************************************************************************
    * @description Enums used for navigating and flagging active lightning-tabs.
    */
    tabs = Object.freeze({
        INFO: { id: "infoTab", label: this.CUSTOM_LABELS.geTabTemplateInfo },
        FORM_FIELDS: { id: "formFieldsTab", label: this.CUSTOM_LABELS.geTabFormFields },
        BATCH_SETTINGS: { id: "batchSettingsTab", label: this.CUSTOM_LABELS.geTabBatchSettings }
    });

    @api formTemplateRecordId;

    existingFormTemplateName;
    currentNamespace;
    @api isClone = false;
    @track isLoading = true;
    @track activeTab = this.tabs.INFO.id;
    @track formTemplate = {
        name: null,
        description: null,
        batchHeaderFields: [],
        layout: null
    };
    formLayout = {
        fieldMappingSetDevName: null,
        version: null,
        sections: []
    };
    @track batchHeaderFields = [];
    @track formSections = [];
    @track activeFormSectionId;
    @track diBatchInfo;
    @track batchFields;
    @track missingRequiredBatchFields;
    batchFieldFormElements = [];
    _dataImportObject;

    @track formFieldsBySourceApiName = {};
    @track availableBatchTableColumnOptions = [];
    @track preselectedBatchTableColumnNames = [
        'donorLink',
        'matchedRecordUrl',
        DONATION_AMOUNT_FIELD.fieldApiName,
        DONATION_DATE_FIELD.fieldApiName,
        DONATION_CAMPAIGN_SOURCE_FIELD.fieldApiName,
        STATUS_FIELD.fieldApiName,
        FAILURE_INFORMATION_FIELD.fieldApiName
    ];
    @track selectedBatchTableColumnOptions = [...this.preselectedBatchTableColumnNames];

    @track hasTemplateInfoTabError;
    @track hasSelectFieldsTabError;
    @track hasBatchSettingsTabError;
    @track previousSaveAttempted = false;
    @track sectionIdsByFieldMappingDeveloperNames = {};

    @wire(getObjectInfo, { objectApiName: DATA_IMPORT_BATCH_OBJECT })
    wiredBatchDataImportObject({ error, data }) {
        if (error) return handleError(error);
        if (data) {
            this.diBatchInfo = data;
            this._dataImportBatchPermissionErrors =
                this.checkSingleFieldPermission(
                    this.diBatchInfo, DATA_IMPORT_BATCH_TABLE_COLUMNS_FIELD.fieldApiName);
            this.dataImportObjectName = DATA_IMPORT_OBJECT.objectApiName;
        }
    }

    // This wired method will only run after wiredBatchDataImportObject assigns the dataImportObjectName property
    @wire(getObjectInfo, { objectApiName: '$dataImportObjectName' })
    wiredDataImportObject({ error, data }) {
        if (error) return handleError(error);
        if (data) {
            this._dataImportObject = data;
            if (this.connected) {
                // We need to be connected before we can initialize this component.
                this.init();
            } else {
                // So if we haven't connected yet, queue it up.
                this.needToInit = true;
            }
        }
    }

    get templateBuilderHeader() {
        return this.existingFormTemplateName ? this.existingFormTemplateName : this.CUSTOM_LABELS.geHeaderNewTemplate;
    }

    get mode() {
        return this.formTemplateRecordId === undefined ? NEW : EDIT;
    }

    get inTemplateInfoTab() {
        return this.activeTab === this.tabs.INFO.id;
    }

    get inBatchHeaderTab() {
        return this.activeTab === this.tabs.BATCH_SETTINGS.id;
    }

    get inSelectFieldsTab() {
        return this.activeTab === this.tabs.FORM_FIELDS.id;
    }

    get disableBatchTableColumnsSubtab() {
        if (!this._dataImportBatchPermissionErrors) return false;

        this._batchTableLabelAccessErrorLabel =
            this._dataImportBatchPermissionErrors
                .noAccessFields
                .find(field => field.includes(DATA_IMPORT_BATCH_TABLE_COLUMNS_FIELD.fieldApiName));

        return this._batchTableLabelAccessErrorLabel ? true : false;
    }

    get batchTableColumnsAccessErrorMessage() {
        if (!this.disableBatchTableColumnsSubtab) return '';

        return GeLabelService.format(
            this.CUSTOM_LABELS.geErrorFLSBody,
            [this._batchTableLabelAccessErrorLabel]);
    }

    /*******************************************************************************
    * Start getters for data-qa-locator attributes
    */

    get qaLocatorNextFormFields() {
        return `button ${this.CUSTOM_LABELS.geButtonBuilderNavFormFields}`;
    }

    get qaLocatorNextBatchHeaderFields() {
        return `button ${this.CUSTOM_LABELS.geButtonBuilderNavBatchHeader}`;
    }

    get qaLocatorSaveAndClose() {
        return `button ${this.CUSTOM_LABELS.commonSaveAndClose}`;
    }

    get qaLocatorBackTemplateInfo() {
        return `button ${this.CUSTOM_LABELS.geButtonBuilderNavBackTemplateInfo}`;
    }

    get qaLocatorBackFormFields() {
        return `button ${this.CUSTOM_LABELS.geButtonBuilderNavBackFormFields}`;
    }

    get qaLocatorCancel() {
        return `button ${this.CUSTOM_LABELS.commonCancel}`;
    }

    /*******************************************************************************
    * End getters for data-qa-locator attributes
    */

    connectedCallback() {
        this.connected = true;

        if (this.needToInit) {
            this.init();
        }
    }

    init = async () => {
        try {
            this.currentNamespace = getNamespace(DATA_IMPORT_BATCH_OBJECT.objectApiName);
            const queryParameters = getQueryParameters();
            await TemplateBuilderService.init(DEFAULT_FIELD_MAPPING_SET);
            await this.loadFormTemplateRecord(queryParameters);

            this.buildBatchHeaderFields();
            this.buildDefaultFormFields();
            this.buildFormFieldsBySourceApiNameMap(this.formSections);
            this.buildDefaultBatchTableColumnOptions();
            this.buildBatchTableColumnOptions(this.formSections);
            this.setInitialActiveFormSection();

            this.isLoading = false;
        } catch (error) {
            handleError(error);
        }
    };

    checkSingleFieldPermission(objectSchema, fieldApiName) {
        return this.checkFieldPermissions(objectSchema, [fieldApiName]);
    }

    checkFieldPermissions(objectSchema, fieldApiNames) {
        if (!objectSchema && !objectSchema.fields) return;

        this._noReadAccessFields = [];
        this._noEditAccessFields = [];

        fieldApiNames.forEach(fieldApiName => {
            const field = objectSchema.fields[fieldApiName];
            if (!field) return this._noReadAccessFields.push(`${objectSchema.label}: ${fieldApiName}`);

            if (field) {
                const canEdit = field.updateable;
                if (!canEdit) return this._noEditAccessFields.push(`${objectSchema.label}: ${fieldApiName}`);
            }
        });

        return {
            objectApiName: objectSchema.apiName,
            noAccessFields: [...this._noReadAccessFields, ...this._noEditAccessFields],
        }
    }

    /*******************************************************************************
    * @description Checks for a form template record id on initial load and sets
    * form template properties accordingly if one is found.
    *
    * @param {object} queryParameters: Object containing query parameters
    */
    loadFormTemplateRecord = async (queryParameters) => {
        if (!this.formTemplateRecordId) {
            this.formTemplateRecordId = queryParameters.c__formTemplateRecordId;
        }

        if (this.formTemplateRecordId) {
            let formTemplate = await retrieveFormTemplateById({
                templateId: this.formTemplateRecordId
            });

            this.existingFormTemplateName = formTemplate.name;
            this.formTemplate = formTemplate;
            this.batchHeaderFields = formTemplate.batchHeaderFields;
            this.formLayout = formTemplate.layout;
            this.formSections = this.formLayout.sections;

            this.selectedBatchTableColumnOptions = isEmpty(formTemplate.defaultBatchTableColumns) ?
                [] : formTemplate.defaultBatchTableColumns;

            this.catalogFieldsForTemplateEdit();
        }

        this.clearRecordIdOnClone(queryParameters);
    }

    /*******************************************************************************
    * @description Builds a map of form fields by their source field api names.
    */
    buildFormFieldsBySourceApiNameMap() {
        let elements = {};
        this.formSections.map(section => {
            section.elements.map(element => {
                const fieldMapping =
                    TemplateBuilderService.fieldMappingByDevName[element.dataImportFieldMappingDevNames[0]];
                if (!fieldMapping) return;

                elements[fieldMapping.Source_Field_API_Name] = element;
            });
        });

        this.formFieldsBySourceApiName = elements;
    }

    setInitialActiveFormSection() {
        if (!this.activeFormSectionId && this.formSections && this.formSections.length > 0) {
            this.activeFormSectionId = this.formSections[0].id;
        }
    }

    clearRecordIdOnClone(queryParameters) {
        if (queryParameters.c__clone || this.isClone) {
            this.formTemplateRecordId = null;
        }
    }

    handleUpdateSelectedBatchTableColumns(event) {
        this.selectedBatchTableColumnOptions = event.detail;
    }

    /*******************************************************************************
    * @description Builds default options from a defined list of field mappings
    * for the dual-listbox component inside the Batch Table Columns subtab of
    * the Batch Settings tab.
    */
    buildDefaultBatchTableColumnOptions() {
        let defaultBatchTableColumnOptions = [
            { label: this.CUSTOM_LABELS.geDonorColumnLabel, value: 'donorLink' },
            { label: this.CUSTOM_LABELS.geDonationColumnLabel, value: 'matchedRecordUrl' },
        ];

        DEFAULT_BATCH_TABLE_HEADERS_WITH_FIELD_MAPPINGS.forEach(fieldApiName => {
            const hasFieldMappingInForm = this.formFieldsBySourceApiName[fieldApiName];

            const shouldBeExcludedInEditMode =
                this.mode === EDIT &&
                !hasFieldMappingInForm &&
                fieldApiName !== STATUS_FIELD.fieldApiName &&
                fieldApiName !== FAILURE_INFORMATION_FIELD.fieldApiName;

            if (shouldBeExcludedInEditMode) return;

            const label = hasFieldMappingInForm ?
                this.formFieldsBySourceApiName[fieldApiName].customLabel :
                this._dataImportObject.fields[fieldApiName].label;

            defaultBatchTableColumnOptions = [
                ...defaultBatchTableColumnOptions,
                {
                    label: label,
                    value: fieldApiName
                }
            ];
        });

        this.availableBatchTableColumnOptions = defaultBatchTableColumnOptions;
    }

    /*******************************************************************************
    * @description Builds option objects from all form field elements in the form
    * for the dual-listbox component inside the Batch Table Columns subtab of the
    * Batch Settings tab.
    */
    buildBatchTableColumnOptions() {
        if (!this.formSections || this.formSections.length === 0) return;

        this.getFormFieldsFromSections(this.formSections).forEach(formField => {
            if (formField.elementType === 'widget') return;

            const fieldMapping =
                TemplateBuilderService.fieldMappingByDevName[formField.dataImportFieldMappingDevNames[0]];

            if (isEmpty(fieldMapping) ||
                SKIPPED_BATCH_TABLE_HEADER_FIELDS.includes(fieldMapping.Source_Field_API_Name)) {

                return;
            }

            this.availableBatchTableColumnOptions = [
                ...this.availableBatchTableColumnOptions,
                {
                    label: formField.customLabel,
                    value: fieldMapping.Source_Field_API_Name
                }
            ];
        });

        this.includePaymentStatusDisplayField();
    }

    includePaymentStatusDisplayField() {
        const hasElevatePaymentStatusField =
            hasNestedProperty(this._dataImportObject, FIELDS, apiNameFor(ELEVATE_PAYMENT_STATUS));

        if (TemplateBuilderService.isElevateCustomer && hasElevatePaymentStatusField) {
            const elevatePaymentStatusOption = {
                label: this._dataImportObject.fields[apiNameFor(ELEVATE_PAYMENT_STATUS)]?.label,
                value: this._dataImportObject.fields[apiNameFor(ELEVATE_PAYMENT_STATUS)]?.apiName
            };
            this.availableBatchTableColumnOptions.push(elevatePaymentStatusOption);
        }
    }

    /*******************************************************************************
    * @description Collects all form field elements from all form sections.
    *
    * @param {array} formSections: A list of form section objects
    *
    * @return {array} formFields: A list of form field objects
    */
    getFormFieldsFromSections(formSections) {
        let formFields = [];
        formSections.forEach(formSection => {
            formFields = [
                ...formFields,
                ...formSection.elements
                    .filter(element => element.dataImportFieldMappingDevNames.length > 0)
                    .map(element => element)
            ];
        });

        return formFields;
    }

    /*******************************************************************************
    * @description Method builds and sorts a list of batch header fields for the
    * child component geTemplateBuilderBatchHeader. Takes into consideration
    * additionally required fields and exluded fields. List is used by the sidebar
    * for the lightning-input checkboxes.
    */
    buildBatchHeaderFields() {
        this.batchFields = mutable(this.diBatchInfo.fields);

        Object.getOwnPropertyNames(this.batchFields).forEach((key) => {
            let field = this.batchFields[key];
            const isFieldExcluded = EXCLUDED_BATCH_HEADER_FIELDS.includes(field.apiName);
            const isNewAndNotCreatable = this.mode === NEW && !field.createable;
            const isEditAndNotAccessible = this.mode === EDIT && !field.createable && !field.updateable;

            if (isFieldExcluded || isNewAndNotCreatable || isEditAndNotAccessible) {
                return;
            }

            field.isPicklist = field.dataType === PICKLIST ? true : false;

            if (ADDITIONAL_REQUIRED_BATCH_HEADER_FIELDS.includes(field.apiName)) {
                field.required = true;
            }

            if (field.required && field.dataType !== BOOLEAN) {
                field.checked = true;
                field.isRequiredFieldDisabled = true;
            } else {
                field.checked = false;
                field.isRequiredFieldDisabled = false;
            }

            // Need to set checkbox field types 'required' field to false
            // as it always returns true from the field describe info.
            if (field.dataType === BOOLEAN) {
                field.required = false;
            }

            this.batchFieldFormElements.push(field);
        });

        this.batchFieldFormElements = sort(this.batchFieldFormElements, SORTED_BY, SORT_ORDER);

        this.addRequiredBatchHeaderFields();
        this.validateBatchHeaderTab(new Set());
    }

    /*******************************************************************************
    * @description Method adds all required batch header fields on new templates.
    */
    addRequiredBatchHeaderFields() {
        if (this.mode === NEW) {
            const requiredFields = this.batchFieldFormElements.filter(batchField => {
                return batchField.required;
            });

            requiredFields.forEach((field) => {
                this.handleAddBatchHeaderField({ detail: field.apiName });
            });

            DEFAULT_BATCH_HEADER_FIELDS.forEach((fieldApiName) => {
                this.handleAddBatchHeaderField({ detail: fieldApiName });
            })
        }
    }

    /*******************************************************************************
    * @description Method handles tab validity change events from child components
    * that happen outside an explicit save action.
    *
    * @param {object} event: Event received from any of the following components.
    * geTemplateBuilderTemplateInfo, geTemplateBuilderSelectFields, and
    * geTemplateBuilderBatchHeader.
    */
    handleUpdateValidity(event) {
        this[event.detail.property] = event.detail.hasError;
    }

    /*******************************************************************************
    * @description Handles the onactive event on a lightning-tab element. Sets the
    * activeTab property based on the lightning-tab element's value.
    *
    * @param {object} event: Event received from the lightning-tab element.
    */
    handleOnActiveTab(event) {
        const tabValue = event.target.value;

        switch (tabValue) {
            case this.tabs.INFO.id:
            case this.tabs.FORM_FIELDS.id:
            case this.tabs.BATCH_SETTINGS.id:
                // intentional fall-through
                // if clicked tab id matches any of the above, switch to that tab
                this.activeTab = tabValue;
                break;
            default:
                this.activeTab = this.tabs.INFO.id;
        }
    }

    /*******************************************************************************
    * @description Public method for receiving modal related events. Used in the
    * geTemplateBuilderSectionModalBody, GE_modalProxy, GE_TemplateBuilder component's
    * event chain. Handles the section save and section delete actions from the modal.
    *
    * @param {object} modalData: Event object containing the action and section
    * information.
    * component chain: geTemplateBuilderSectionModalBody -> utilDedicatedListener -> GE_TemplateBuilder -> here
    */
    @api
    notify(modalData) {
        if (modalData.action === SAVE) {
            let formSections = mutable(this.formSections);
            let formSection = formSections.find((fs) => { return fs.id === modalData.section.id });
            formSection.defaultDisplayMode = modalData.section.defaultDisplayMode;
            formSection.label = modalData.section.label;
            this.formSections = formSections;
        }

        if (modalData.action === DELETE) {
            const selectFieldsComponent = this.template.querySelector('c-ge-template-builder-form-fields');
            selectFieldsComponent.handleDeleteFormSection({ detail: modalData.section.id });
        }
    }

    /*******************************************************************************
    * @description Dispatches an event notifying the parent component GE_TemplateBuilder
    * to open a modal.
    *
    * @param {object} event: Event received from child component.
    * component chain: geTemplateBuilderFormSection -> geTemplateBuilderSelectFields -> here
    */
    toggleModal(event) {
        dispatch(this, EVENT_TOGGLE_MODAL, event.detail);
    }

    /*******************************************************************************
    * @description Receives and handles event from child component to set the
    * template name.
    *
    * @param {object} event: Event received from child component.
    * Detail property contains template name string.
    * component chain: geTemplateBuilderTemplateInfo -> here
    */
    handleChangeTemplateInfoName(event) {
        this.formTemplate.name = event.detail;
    }

    /*******************************************************************************
    * @description Receives and handles event from child component to set the
    * template description.
    *
    * @param {object} event: Event received from child component.
    * Detail property contains template description string.
    * component chain: geTemplateBuilderTemplateInfo -> here
    */
    handleChangeTemplateInfoDescription(event) {
        this.formTemplate.description = event.detail;
    }

    /*******************************************************************************
    * @description Receives and handles event from child component to add a new
    * field to batch headers.
    *
    * @param {object} event: Event received from child component.
    * Detail property contains batch header fields array.
    * component chain: geTemplateBuilderbatchHeader -> here
    */
    handleAddBatchHeaderField(event) {
        const fieldName = event.detail;
        let batchField = this.batchFields[fieldName];

        let field = {
            label: batchField.label,
            apiName: batchField.apiName,
            required: batchField.required,
            isRequiredFieldDisabled: batchField.isRequiredFieldDisabled,
            allowDefaultValue: true,
            defaultValue: null,
            dataType: batchField.dataType
        }

        this.batchHeaderFields = [...this.batchHeaderFields, field];
    }

    /*******************************************************************************
    * @description Receives and handles event from child component to update the
    * details on a batch header field.
    *
    * @param {object} event: Event received from child component.
    * Detail property contains batch header field object.
    * component chain: geTemplateBuilderFormField -> geTemplateBuilderbatchHeader -> here
    */
    handleUpdateBatchHeaderField(event) {
        let batchHeaderField = this.batchHeaderFields.find((bf) => {
            return bf.apiName === event.detail.fieldName
        });

        if (batchHeaderField) {
            batchHeaderField[event.detail.property] = event.detail.value;
        }
    }

    /*******************************************************************************
    * @description Receives and handles event from child component to move a batch
    * header field up.
    *
    * @param {object} event: Event received from child component.
    * Detail property contains batch header field api name.
    * component chain: geTemplateBuilderFormField -> geTemplateBuilderbatchHeader -> here
    */
    handleBatchHeaderFieldUp(event) {
        let index = findIndexByProperty(this.batchHeaderFields, API_NAME, event.detail);
        if (index > 0) {
            this.batchHeaderFields = shiftToIndex(this.batchHeaderFields, index, index - 1);
        }
    }

    /*******************************************************************************
    * @description Receives and handles event from child component to move a batch
    * header field down.
    *
    * @param {object} event: Event received from child component.
    * Detail property contains batch header field api name.
    * component chain: geTemplateBuilderFormField -> geTemplateBuilderbatchHeader -> here
    */
    handleBatchHeaderFieldDown(event) {
        let index = findIndexByProperty(this.batchHeaderFields, API_NAME, event.detail);
        if (index < this.batchHeaderFields.length - 1) {
            this.batchHeaderFields = shiftToIndex(this.batchHeaderFields, index, index + 1);
        }
    }

    /*******************************************************************************
    * @description Receives and handles event from child component to remove a batch
    * header field.
    *
    * @param {object} event: Event received from child component.
    * Detail property contains batch header field array index.
    * component chain: geTemplateBuilderFormField -> geTemplateBuilderbatchHeader -> here
    * OR
    * geTemplateBuilderbatchHeader -> here
    */
    handleRemoveBatchHeaderField(event) {
        this.batchHeaderFields.splice(event.detail, 1);
    }

    /*******************************************************************************
    * @description Receives and handles event from child component to set the
    * form sections property. Used only for actions related to deleting a section.
    * Event is dispatched from geTemplateBuilderSelectFields.handleDeleteFormSection()
    *
    * @param {object} event: Event received from child component.
    * Detail property contains a list of form sections.
    * component chain: geTemplateBuilderSelectFields -> here
    */
    handleRefreshFormSections(event) {
        this.formSections = event.detail;
    }

    /*******************************************************************************
    * @description Method sets the currently active form section id by the provided
    * form section id.
    *
    * @param {object} event: Event received from child component that contains a
    * section id.
    */
    handleChangeActiveSection(event) {
        this.activeFormSectionId = event.detail;
    }

    /*******************************************************************************
    * @description Method creates a default section and adds default form fields
    * defined in imported constant DEFAULT_FORM_FIELDS.
    */
    buildDefaultFormFields() {
        if (this.formSections && this.formSections.length === 0) {
            let sectionId = this.handleAddFormSection({
                detail: { label: this.CUSTOM_LABELS.geHeaderFormFieldsDefaultSectionName }
            });
            let fieldMappingBySourceFieldAndTargetObject = this.getFieldMappingBySourceFieldAndTargetObject();

            Object.keys(DEFAULT_FORM_FIELDS).forEach(sourceFieldApiName => {
                if (DEFAULT_FORM_FIELDS[sourceFieldApiName]) {
                    const key = `${sourceFieldApiName}.${DEFAULT_FORM_FIELDS[sourceFieldApiName]}`;

                    if (fieldMappingBySourceFieldAndTargetObject[key]) {
                        const fieldMapping = fieldMappingBySourceFieldAndTargetObject[key];
                        const objectMapping = TemplateBuilderService
                            .objectMappingByDevName[fieldMapping.Target_Object_Mapping_Dev_Name];

                        let formField = this.constructFormField(objectMapping, fieldMapping, sectionId);

                        this.handleAddFieldToSection(sectionId, formField);
                        this.catalogSelectedField(fieldMapping.DeveloperName, sectionId);
                    }
                }
            });
        }
    }

    /*******************************************************************************
    * @description Method catalogs selected fields when in edit mode so we can toggle
    * each field's corresponding checkbox.
    */
    catalogFieldsForTemplateEdit() {
        for (let i = 0; i < this.formSections.length; i++) {
            const formSection = this.formSections[i];
            formSection.elements.forEach(element => {
                const name = element.componentName ?
                    element.componentName :
                    element.dataImportFieldMappingDevNames[0];

                this.catalogSelectedField(name, formSection.id)
            });
        }
    }

    /*******************************************************************************
    * @description Builds a map of Field Mappings by their Source Field and Target
    * Object api names i.e. npsp__Account1_Street__c.Account.
    */
    getFieldMappingBySourceFieldAndTargetObject() {
        let map = {};
        Object.keys(TemplateBuilderService.fieldMappingByDevName).forEach(key => {
            const fieldMapping = TemplateBuilderService.fieldMappingByDevName[key];
            if (fieldMapping.Source_Field_API_Name && fieldMapping.Target_Object_API_Name) {
                const newKey =
                    `${fieldMapping.Source_Field_API_Name}.${fieldMapping.Target_Object_API_Name}`;
                map[newKey] = TemplateBuilderService.fieldMappingByDevName[key];
            }
        });

        return map;
    }

    /*******************************************************************************
    * @description Method receives an event from the child geTemplateBuilderFormFields
    * component's handleToggleFieldMapping method.
    *
    * @param {object} event: Event received from child component.
    */
    handleToggleFieldMapping(event) {
        let { clickEvent, fieldMappingDeveloperName, fieldMapping, objectMapping } = event.detail;
        let sectionId = this.activeFormSectionId;
        const isAddField = clickEvent.target.checked;

        if (isAddField) {
            sectionId = this.checkFormSectionId(sectionId, clickEvent);

            let formElement;
            if (fieldMapping.Element_Type === FIELD) {
                formElement = this.constructFormField(objectMapping, fieldMapping, sectionId);
            } else if (fieldMapping.Element_Type === WIDGET) {
                formElement = this.constructFormWidget(fieldMapping, sectionId);
            }

            this.catalogSelectedField(fieldMappingDeveloperName, sectionId);
            this.handleAddFieldToSection(sectionId, formElement);
        } else {
            this.handleRemoveFieldFromSection(fieldMappingDeveloperName);
        }
    }

    /*******************************************************************************
    * @description Method checks to see if a new form section needs to be created
    * by the provided section id and click event.
    *
    * @param {string} sectionId: Form section id to check.
    * @param {object} clickEvent: Click event from the field mapping checkbox in the
    * Form Fields tab's sidebar.
    */
    checkFormSectionId(sectionId, clickEvent) {
        const hasNoSection = !this.formSections || this.formSections.length === 0;
        const hasOneSection = this.formSections.length === 1;
        const hasManySections = this.formSections.length > 1;
        const hasNoActiveSection = this.activeFormSectionId === undefined;

        if (hasNoSection) {
            sectionId = this.handleAddFormSection();
        } else if (hasOneSection) {
            sectionId = this.formSections[0].id;
            this.activeFormSectionId = sectionId;
        } else if (hasManySections && hasNoActiveSection) {
            clickEvent.target.checked = false;
            showToast(this.CUSTOM_LABELS.geToastSelectActiveSection, '', WARNING);
        }

        return sectionId;
    }

    /*******************************************************************************
    * @description Maps the given field mapping developer name to the section id.
    * Used to later find and remove gift fields from their sections.
    *
    * @param {string} fieldMappingDeveloperName: Developer name of a Field Mapping
    * @param {string} sectionId: Id of form section this form widget will be in.
    */
    catalogSelectedField(fieldMappingDeveloperName, sectionId) {
        this.sectionIdsByFieldMappingDeveloperNames[fieldMappingDeveloperName] = sectionId;
    }

    /*******************************************************************************
    * @description Constructs a form field object.
    *
    * @param {object} objectMapping: Instance of BDI_ObjectMapping wrapper class.
    * @param {object} fieldMapping: Instance of BDI_FieldMapping wrapper class.
    * @param {string} sectionId: Id of form section this form field will be under.
    */
    constructFormField(objectMapping, fieldMapping, sectionId) {
        return {
            id: generateId(),
            label: `${objectMapping.MasterLabel}: ${fieldMapping.Target_Field_Label}`,
            customLabel: this.getCustomLabel(objectMapping, fieldMapping),
            required: fieldMapping.Is_Required || false,
            sectionId: sectionId,
            defaultValue: null,
            dataType: fieldMapping.Target_Field_Data_Type,
            dataImportFieldMappingDevNames: [fieldMapping.DeveloperName],
            elementType: fieldMapping.Element_Type,
            fieldApiName: fieldMapping.Target_Field_API_Name,
            objectApiName: objectMapping.Object_API_Name
        }
    }

    /*******************************************************************************
    * @description Constructs a form widget object.
    *
    * @param {object} widget: Currently an instance of BDI_FieldMapping wrapper class
    * made to look like a widget.
    * @param {object} fieldMapping: Instance of BDI_FieldMapping wrapper class
    * @param {string} sectionId: Id of form section this form field will be in.
    */
    constructFormWidget(widget, sectionId) {
        return {
            id: generateId(),
            componentName: widget.DeveloperName,
            label: widget.MasterLabel,
            customLabel: widget.MasterLabel,
            required: false,
            sectionId: sectionId,
            elementType: widget.Element_Type,
            dataImportObjectMappingDevName: widget.objectMappingDeveloperName,
            dataImportFieldMappingDevNames: widget.fieldMappingDeveloperNames,
        }
    }

    /*******************************************************************************
    * @description Method handles creating and inserting a new form section.
    *
    * @param {object} event: An object that contains the label for the form section.
    */
    handleAddFormSection(event) {
        let label = (event && event.detail && typeof event.detail.label === 'string') ?
            event.detail.label :
            this.CUSTOM_LABELS.geHeaderNewSection;

        let newSection = {
            id: generateId(),
            displayType: 'accordion',
            defaultDisplayMode: 'expanded',
            displayRule: 'displayRule',
            label: label,
            elements: []
        }

        this.formSections = [...this.formSections, newSection];
        this.activeFormSectionId = newSection.id;

        return newSection.id;
    }

    /*******************************************************************************
    * @description Receives and handles event from child component to move a form
    * section up.
    *
    * @param {object} event: Event received from child component.
    * Detail property contains sectionId.
    * component chain: geTemplateBuilderFormSection -> geTemplateBuilderSelectFields -> here
    */
    handleFormSectionUp(event) {
        let index = findIndexByProperty(this.formSections, ID, event.detail);
        if (index > 0) {
            this.formSections = shiftToIndex(this.formSections, index, index - 1);
        }
    }

    /*******************************************************************************
    * @description Receives and handles event from child component to move a form
    * section down.
    *
    * @param {object} event: Event received from child component.
    * Detail property contains form section id.
    * component chain: geTemplateBuilderFormSection -> geTemplateBuilderSelectFields -> here
    */
    handleFormSectionDown(event) {
        let index = findIndexByProperty(this.formSections, ID, event.detail);
        if (index < this.formSections.length - 1) {
            this.formSections = shiftToIndex(this.formSections, index, index + 1);
        }
    }

    /*******************************************************************************
    * @description Receives and handles event from child component to add a form
    * field to a form section.
    *
    * @param {object} event: Event received from child component.
    * component chain: geTemplateBuilderSelectFields -> here
    */
    handleAddFieldToSection(sectionId, field) {
        let formSections = mutable(this.formSections);
        let formSection = formSections.find(fs => fs.id === sectionId);

        if (formSection) {
            field.sectionId = sectionId;
            formSection.elements.push(field);

            this.addFieldToAvailableBatchTableColumnOptions(field);
        }

        this.formSections = formSections;
    }

    addFieldToAvailableBatchTableColumnOptions(field) {
        const fieldMappingDevNames = field.dataImportFieldMappingDevNames;

        const isAFieldMappingField =
            fieldMappingDevNames &&
            fieldMappingDevNames[0] &&
            field.elementType === 'field';

        if (isAFieldMappingField) {
            const fieldMapping = TemplateBuilderService.fieldMappingByDevName[fieldMappingDevNames[0]];
            const existingOptionIndex = findIndexByProperty(
                this.availableBatchTableColumnOptions,
                VALUE,
                fieldMapping.Source_Field_API_Name
            );

            const isNewOption = existingOptionIndex === -1;
            if (isNewOption) {
                const option = {
                    label: field.customLabel,
                    value: fieldMapping.Source_Field_API_Name
                };
                this.availableBatchTableColumnOptions = [...this.availableBatchTableColumnOptions, option];
            } else {
                this.availableBatchTableColumnOptions[existingOptionIndex].label = field.customLabel;
            }
        }
    }

    /*******************************************************************************
    * @description Receives and handles event from child component to remove a form
    * field from a form section.
    *
    * @param {object} event: Event received from child component.
    * component chain: geTemplateBuilderFormField -> geTemplateBuilderFormSection ->
    * geTemplateBuilderSelectFields -> here
    */
    handleRemoveFieldFromSection(fieldMappingDeveloperName) {
        const sectionId = this.sectionIdsByFieldMappingDeveloperNames[fieldMappingDeveloperName];

        let formSections = mutable(this.formSections);
        let section = formSections.find(fs => fs.id === sectionId);
        const index = section.elements.findIndex((element) => {
            const name = element.componentName ? element.componentName : element.dataImportFieldMappingDevNames[0];
            return name === fieldMappingDeveloperName;
        });
        section.elements.splice(index, 1);

        this.formSections = formSections;

        this.removeOptionFromBatchTableColumn(fieldMappingDeveloperName);
    }

    /*******************************************************************************
    * @description Removes an option from "available fields" of the Batch Table
    * Columns dual-listbox component.
    *
    * @param {string} fieldMappingDeveloperName: Developer name of the options
    * corresponding field mapping.
    */
    removeOptionFromBatchTableColumn(fieldMappingDeveloperName) {
        const fieldMapping = TemplateBuilderService.fieldMappingByDevName[fieldMappingDeveloperName];
        if (!fieldMapping) return;

        removeFromArray(this.selectedBatchTableColumnOptions, fieldMapping.Source_Field_API_Name);
        removeByProperty(this.availableBatchTableColumnOptions, VALUE, fieldMapping.Source_Field_API_Name);
    }

    /*******************************************************************************
    * @description Removes an option from "available fields" of the Batch Table
    * Columns dual-listbox component.
    *
    * @param {string} fieldMappingDeveloperName: Developer name of the options
    * corresponding field mapping.
    */
    updateOptionFromBatchTableColumn(formField) {
        const fieldMapping =
            TemplateBuilderService.fieldMappingByDevName[formField.dataImportFieldMappingDevNames[0]];
        if (!fieldMapping) return;

        const index = findIndexByProperty(
            this.availableBatchTableColumnOptions,
            VALUE,
            fieldMapping.Source_Field_API_Name);

        if (index !== -1) {
            this.availableBatchTableColumnOptions[index].label = formField.customLabel;
        }
    }

    /*******************************************************************************
    * @description Receives and handles event from child component to move a form
    * field up within its parent form section.
    *
    * @param {object} event: Event received from child component.
    * component chain: geTemplateBuilderFormField -> geTemplateBuilderFormSection ->
    * geTemplateBuilderSelectFields -> here
    */
    handleFormElementUp(event) {
        const { sectionId, fieldName } = event.detail;

        let section = this.formSections.find((fs) => { return fs.id === sectionId });
        let index = section.elements.findIndex((element) => {
            const name = element.componentName ? element.componentName : element.dataImportFieldMappingDevNames[0];
            return name === fieldName;
        });

        if (index > 0) {
            section = shiftToIndex(section.elements, index, index - 1);
        }
    }

    /*******************************************************************************
    * @description Receives and handles event from child component to move a form
    * field down within its parent form section.
    *
    * @param {object} event: Event received from child component.
    * component chain: geTemplateBuilderFormField -> geTemplateBuilderFormSection ->
    * geTemplateBuilderSelectFields -> here
    */
    handleFormElementDown(event) {
        const { sectionId, fieldName } = event.detail;

        let section = this.formSections.find((fs) => { return fs.id === sectionId });
        let index = section.elements.findIndex((element) => {
            const name = element.componentName ? element.componentName : element.dataImportFieldMappingDevNames[0];
            return name === fieldName;
        });
        if (index < section.elements.length - 1) {
            section = shiftToIndex(section.elements, index, index + 1);
        }
    }

    /*******************************************************************************
    * @description Receives and handles event from child component to remove a form
    * field from its parent form section.
    *
    * @param {object} event: Event received from child component.
    * component chain: geTemplateBuilderFormField -> geTemplateBuilderFormSection ->
    * geTemplateBuilderSelectFields -> here
    * OR
    * geTemplateBuilderSelectFields -> here
    */
    handleDeleteFormElement(event) {
        const { sectionId, id } = event.detail;

        let section = this.formSections.find((fs) => { return fs.id === sectionId });
        let index = section.elements.findIndex((element) => {
            return element.id === id;
        });

        if (section.elements[index].elementType === 'field') {
            this.removeOptionFromBatchTableColumn(section.elements[index].dataImportFieldMappingDevNames[0]);
        }

        section.elements.splice(index, 1);
    }

    /*******************************************************************************
    * @description Receives and handles event from child component to update the
    * details of a form field within its parent form section.
    *
    * @param {object} event: Event received from child component.
    * component chain: geTemplateBuilderFormField -> geTemplateBuilderFormSection ->
    * geTemplateBuilderSelectFields -> here
    */
    handleUpdateFormElement(event) {
        const { sectionId, fieldName, property, value } = event.detail;

        let section = this.formSections.find((fs) => { return fs.id === sectionId });
        let element = section.elements.find((e) => {
            const name = e.componentName ? e.componentName : e.dataImportFieldMappingDevNames[0];
            return name === fieldName
        });

        if (element) {
            element[property] = value;
        }

        this.updateOptionFromBatchTableColumn(element);
    }

    /*******************************************************************************
    * @description Handles previous and next tab navigation
    *
    * @param {object} event: Event received from lightning-button.
    */
    handleGoToTab(event) {
        this.activeTab = event.target.getAttribute('data-tab-value');
    }

    /*******************************************************************************
    * @description Methods runs validity checks for all tabs, sets tab errors, and
    * throws a toast to notify users which tabs to check.
    */
    checkTabsValidity = async () => {
        let tabsWithErrors = new Set();

        await this.validateTemplateInfoTab(tabsWithErrors);
        this.validateSelectFieldsTab(tabsWithErrors);
        this.validateBatchHeaderTab(tabsWithErrors);

        if (this.hasTemplateInfoTabError || this.hasSelectFieldsTabError || this.hasBatchSettingsTabError) {
            const message = `${tabsWithErrors.size > 1 ?
                this.CUSTOM_LABELS.geToastTemplateTabsError
                : this.CUSTOM_LABELS.geToastTemplateTabsError}`;
            const errors = [...tabsWithErrors].join(', ');
            showToast(this.CUSTOM_LABELS.commonError, `${message}${errors}.`, ERROR);

            return false;
        }

        return tabsWithErrors.size === 0 ? true : false;
    }

    /*******************************************************************************
    * @description Method checks for errors in the Template Info tab. Tab currently
    * only has one required field (Name) and this only checks that any value is present
    * there.
    */
    validateTemplateInfoTab = async (tabsWithErrors) => {
        const templateInfoComponent = this.template.querySelector('c-ge-template-builder-template-info');

        if (templateInfoComponent) {
            // Component exists in the dom and can validate itself.
            const isTemplateInfoTabValid = await templateInfoComponent.validate();

            if (isTemplateInfoTabValid) {
                this.hasTemplateInfoTabError = false;
            } else {
                this.hasTemplateInfoTabError = true;
            }
        }

        if (this.hasTemplateInfoTabError) {
            tabsWithErrors.add(this.tabs.INFO.label);
        }
    };

    /*******************************************************************************
    * @description Method checks for errors in the Select Fields tab. Currently only
    * checks for 'requiredness' in the Field Mapping's source (DataImport__c).
    */
    validateSelectFieldsTab(tabsWithErrors) {
        const selectFieldsComponent = this.template.querySelector('c-ge-template-builder-form-fields');

        if (selectFieldsComponent) {
            // Component exists in the dom and can validate itself.
            this.hasSelectFieldsTabError = !selectFieldsComponent.validate();
        } else {
            // Component doesn't exist in the dom and can't validate itself.
            const missingRequiredFields = findMissingRequiredFieldMappings(
                TemplateBuilderService,
                this.formSections);

            if (missingRequiredFields && missingRequiredFields.length > 0) {
                this.hasSelectFieldsTabError = true;
            } else {
                this.hasSelectFieldsTabError = false;
            }
        }

        if (this.hasSelectFieldsTabError) {
            tabsWithErrors.add(this.tabs.FORM_FIELDS.label);
        }
    }

    /*******************************************************************************
    * @description Method checks for missing required DataImportBatch__c fields
    * and adds them proactively.
    */
    validateBatchHeaderTab(tabsWithErrors) {
        this.missingRequiredBatchFields = findMissingRequiredBatchFields(this.batchFieldFormElements,
            this.batchHeaderFields);

        if (this.missingRequiredBatchFields && this.missingRequiredBatchFields.length > 0) {
            for (let field of this.missingRequiredBatchFields) {
                this.handleAddBatchHeaderField({ detail: field.apiName });
            }

            const fieldLabels = this.missingRequiredBatchFields.map(field => field.label).join(', ');
            showToast(this.CUSTOM_LABELS.commonWarning,
                `${this.CUSTOM_LABELS.geBodyBatchHeaderWarning} ${fieldLabels}`,
                'warning',
                'sticky');
        }

        if (tabsWithErrors && !this.disableBatchTableColumnsSubtab) {
            const isMissingBatchTableColumns =
                isEmpty(this.selectedBatchTableColumnOptions) ||
                (this.selectedBatchTableColumnOptions.length === 0);

            if (isMissingBatchTableColumns) {
                this.hasBatchSettingsTabError = true;
                tabsWithErrors.add(this.tabs.BATCH_SETTINGS.label);
            } else {
                this.hasBatchSettingsTabError = false;
            }
        }
    }

    /*******************************************************************************
    * @description Method sets properties on the formTemplate object and passes the
    * FormTemplate JSON to apex and waits for a record id so we can navigate
    * to the newly inserted Form_Template__c record detail page.
    */
    handleFormTemplateSave = async () => {
        this.previousSaveAttempted = true;
        const isTemplateValid = await this.checkTabsValidity();

        if (isTemplateValid) {
            this.isLoading = true;

            if (this.formSections && this.formSections.length === 0) {
                this.buildDefaultFormFields();
            }

            this.formLayout.sections = this.formSections;
            this.formTemplate.batchHeaderFields = this.batchHeaderFields;
            this.formTemplate.layout = this.formLayout;
            if (this.disableBatchTableColumnsSubtab && this.mode === NEW) {
                this.formTemplate.defaultBatchTableColumns = [];
            } else {
                this.formTemplate.defaultBatchTableColumns = this.selectedBatchTableColumnOptions;
            }

            // TODO: Currently hardcoded as we're not providing a way to
            // create custom migrated field mapping sets yet.
            this.formTemplate.layout.fieldMappingSetDevName = DEFAULT_FIELD_MAPPING_SET;

            const preppedFormTemplate = {
                id: this.formTemplateRecordId || null,
                templateJSON: JSON.stringify(this.formTemplate),
                name: this.formTemplate.name,
                description: this.formTemplate.description,
                formatVersion: FORMAT_VERSION
            };

            try {
                const recordId = await storeFormTemplate(preppedFormTemplate);
                if (recordId) {
                    const toastLabel = this.mode === NEW ?
                        this.CUSTOM_LABELS.geToastTemplateCreateSuccess :
                        this.CUSTOM_LABELS.geToastTemplateUpdateSuccess;

                    const toastMessage = GeLabelService.format(toastLabel, [this.formTemplate.name]);
                    showToast(toastMessage, '', SUCCESS);
                }

                this.navigateToLandingPage();
            } catch (error) {
                showToast(this.CUSTOM_LABELS.commonError, this.CUSTOM_LABELS.geToastSaveFailed, ERROR);
                this.isLoading = false;
            }
        }
    }

    /*******************************************************************************
    * @description Navigates to Gift Entry landing page.
    */
    navigateToLandingPage() {
        dispatch(this, 'changeview', { view: GIFT_ENTRY });
    }

    getCustomLabel(objectMapping, fieldMapping) {
        // Donation_Record_Type_Name__c field holds the RecordType Name value even though
        // it is mapped to a target RecordTypeId field because BDI processing handles the
        // translation internally.  Since the Name is the value presented in the UI, this
        // field's custom label is defaulted to just "Opportunity: Record Type"
        if (fieldMapping.Source_Field_API_Name == DONATION_RECORD_TYPE_NAME.fieldApiName) {
            return `${objectMapping.MasterLabel}: Record Type`;
        } else {
            return `${objectMapping.MasterLabel}: ${fieldMapping.Target_Field_Label}`;
        }
    }

}