import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import storeFormTemplate from '@salesforce/apex/FORM_ServiceGiftEntry.storeFormTemplate';
import retrieveFormTemplateById from '@salesforce/apex/FORM_ServiceGiftEntry.retrieveFormTemplateById';
import getDataImportSettings from '@salesforce/apex/UTIL_CustomSettingsFacade.getDataImportSettings';
import TemplateBuilderService from 'c/geTemplateBuilderService';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import {
    mutable,
    findIndexByProperty,
    shiftToIndex,
    dispatch,
    sort,
    getQueryParameters,
    handleError,
    showToast,
    findMissingRequiredFieldMappings,
    findMissingRequiredBatchFields,
    ADDITIONAL_REQUIRED_BATCH_HEADER_FIELDS,
    EXCLUDED_BATCH_HEADER_FIELDS
} from 'c/utilTemplateBuilder';
import DATA_IMPORT_BATCH_OBJECT from '@salesforce/schema/DataImportBatch__c';
import FIELD_MAPPING_METHOD_FIELD_INFO from '@salesforce/schema/Data_Import_Settings__c.Field_Mapping_Method__c';

const FORMAT_VERSION = '1.0';
const ADVANCED_MAPPING = 'Data Import Field Mapping';
const DEFAULT_FIELD_MAPPING_SET = 'Migrated_Custom_Field_Mapping_Set';
const LANDING_PAGE_TAB_NAME = 'GE_Templates';
const SORTED_BY = 'required';
const SORT_ORDER = 'desc';
const PICKLIST = 'Picklist';
const NEW = 'new';
const EDIT = 'edit';

export default class geTemplateBuilder extends NavigationMixin(LightningElement) {

    // TODO: The following enum values will become custom labels.
    /*******************************************************************************
    * @description Enums used for navigating and flagging active lightning-tabs.
    */
    TabEnums = Object.freeze({
        INFO_TAB: 'Template Info',
        SELECT_FIELDS_TAB: 'Form Fields',
        BATCH_HEADER_TAB: 'Batch Header'
    });

    formTemplateRecordId;
    currentNamespace;
    @track isLoading = true;
    @track isAccessible = true;
    @track activeTab = this.TabEnums.INFO_TAB;
    @track formTemplate = {
        name: null,
        description: null,
        batchHeaderFields: [],
        layout: null
    }
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

    @track hasTemplateInfoTabError;
    @track hasSelectFieldsTabError;
    @track hasBatchHeaderTabError;
    @track previousSaveAttempted = false;

    @wire(getObjectInfo, { objectApiName: DATA_IMPORT_BATCH_OBJECT })
    wiredBatchDataImportObject({ error, data }) {
        if (data) {
            this.diBatchInfo = data;
            this.init();
        } else if (error) {
            handleError(this, error);
        }
    }

    get mode() {
        return this.formTemplateRecordId === undefined ? NEW : EDIT;
    }

    get inTemplateInfoTab() {
        return this.activeTab === this.TabEnums.INFO_TAB ? true : false;
    }

    get inBatchHeaderTab() {
        return this.activeTab === this.TabEnums.BATCH_HEADER_TAB ? true : false;
    }

    get inSelectFieldsTab() {
        return this.activeTab === this.TabEnums.SELECT_FIELDS_TAB ? true : false;
    }

    get namespace() {
        return this.currentNamespace ? `${this.currentNamespace}__` : '';
    }

    get listViewCustomTabApiName() {
        return this.currentNamespace ? `${this.namespace + LANDING_PAGE_TAB_NAME}` : LANDING_PAGE_TAB_NAME;
    }

    init = async () => {
        try {
            const dataImportSettings = await getDataImportSettings();

            if (dataImportSettings[FIELD_MAPPING_METHOD_FIELD_INFO.fieldApiName] !== ADVANCED_MAPPING) {
                this.isAccessible = false;
                this.isLoading = false;

            } else if (dataImportSettings[FIELD_MAPPING_METHOD_FIELD_INFO.fieldApiName] === ADVANCED_MAPPING) {
                await TemplateBuilderService.init(DEFAULT_FIELD_MAPPING_SET);
                this.currentNamespace = TemplateBuilderService.namespaceWrapper.currentNamespace;

                // Check if there's a record id in the url
                this.formTemplateRecordId = getQueryParameters().c__recordId;

                if (this.formTemplateRecordId) {
                    let formTemplate = await retrieveFormTemplateById({ templateId: this.formTemplateRecordId });

                    this.formTemplate = formTemplate;
                    this.batchHeaderFields = formTemplate.batchHeaderFields;
                    this.formLayout = formTemplate.layout;
                    this.formSections = this.formLayout.sections;
                }

                this.collectBatchHeaderFields();
                this.addRequiredBatchHeaderFields();
                this.validateBatchHeaderTab();

                this.isLoading = false;
                this.isAccessible = true;
            }
        } catch (error) {
            handleError(error);
        }
    }

    /*******************************************************************************
    * @description Method builds and sorts a list of batch header fields for the
    * child component geTemplateBuilderBatchHeader. Takes into consideration
    * additionally required fields and exluded fields. List is used by the sidebar
    * for the lightning-input checkboxes.
    */
    collectBatchHeaderFields() {
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

            if (field.required) {
                field.checked = true;
                field.isRequiredFieldDisabled = true;
            } else {
                field.checked = false;
                field.isRequiredFieldDisabled = false;
            }

            this.batchFieldFormElements.push(field);
        });

        this.batchFieldFormElements = sort(this.batchFieldFormElements, SORTED_BY, SORT_ORDER);
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
            case this.TabEnums.INFO_TAB:
                this.activeTab = this.TabEnums.INFO_TAB;
                break;
            case this.TabEnums.SELECT_FIELDS_TAB:
                this.activeTab = this.TabEnums.SELECT_FIELDS_TAB;
                break;
            case this.TabEnums.BATCH_HEADER_TAB:
                this.activeTab = this.TabEnums.BATCH_HEADER_TAB;
                break;
            default:
                this.activeTab = this.TabEnums.INFO_Tab;
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
        if (modalData.action === 'save') {
            let formSections = mutable(this.formSections);
            let formSection = formSections.find((fs) => { return fs.id === modalData.section.id });

            formSection.label = modalData.section.label;
            this.formSections = formSections;
        }

        if (modalData.action === 'delete') {
            const selectFieldsComponent = this.template.querySelector('c-ge-template-builder-select-fields');
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
        dispatch(this, 'togglemodal', event.detail);
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
        let index = findIndexByProperty(this.batchHeaderFields, 'apiName', event.detail);
        if (index > 0) {
            this.batchHeaderFields =
                shiftToIndex(this.batchHeaderFields, index, index - 1);
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
        let index = findIndexByProperty(this.batchHeaderFields, 'apiName', event.detail);
        if (index < this.batchHeaderFields.length - 1) {
            this.batchHeaderFields =
                shiftToIndex(this.batchHeaderFields, index, index + 1);
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
    * @description Receives and handles event from child component to set the
    * currently active section based on id.
    *
    * @param {object} event: Event received from child component.
    * Detail property contains sectionId.
    * component chain: geTemplateBuilderFormSection -> geTemplateBuilderSelectFields -> here
    */
    handleChangeActiveSection(event) {
        this.activeFormSectionId = event.detail;
    }

    /*******************************************************************************
    * @description Receives and handles event from child component to add a new
    * form section.
    *
    * @param {object} event: Event received from child component.
    * Detail property contains a form section object.
    * component chain: geTemplateBuilderSelectFields -> here
    */
    handleAddFormSection(event) {
        this.formSections = [...this.formSections, event.detail];
        this.activeFormSectionId = event.detail.id;
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
        let index = findIndexByProperty(this.formSections, 'id', event.detail);
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
        let index = findIndexByProperty(this.formSections, 'id', event.detail);
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
    handleAddFieldToSection(event) {
        const sectionId = event.detail.sectionId;
        let field = event.detail.field;
        let formSections = mutable(this.formSections);

        let formSection = formSections.find(fs => fs.id === sectionId);

        if (formSection) {
            field.sectionId = sectionId;
            formSection.elements.push(field);
        }

        this.formSections = formSections;
    }

    /*******************************************************************************
    * @description Receives and handles event from child component to remove a form
    * field from a form section.
    *
    * @param {object} event: Event received from child component.
    * component chain: geTemplateBuilderFormField -> geTemplateBuilderFormSection ->
    * geTemplateBuilderSelectFields -> here
    */
    handleRemoveFieldFromSection(event) {
        const { sectionId, fieldName } = event.detail;

        let formSections = mutable(this.formSections);
        let section = formSections.find(fs => fs.id === sectionId);
        const index = section.elements.findIndex((element) => {
            const name = element.componentName ? element.componentName : element.dataImportFieldMappingDevNames[0];
            return name === fieldName;
        });
        section.elements.splice(index, 1);

        this.formSections = formSections;
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
    checkTabsValidity() {
        let tabsWithErrors = new Set();

        this.validateTemplateInfoTab(tabsWithErrors);
        this.validateSelectFieldsTab(tabsWithErrors);
        this.validateBatchHeaderTab();

        if (this.hasTemplateInfoTabError || this.hasSelectFieldsTabError || this.hasBatchHeaderTabError) {
            const message = `Please review ${tabsWithErrors.size > 1 ? 'tabs' : 'tab'}: `;
            const errors = [...tabsWithErrors].join(', ');
            showToast('Error', `${message} ${errors}`, 'error');

            return false;
        }

        return tabsWithErrors.size === 0 ? true : false;
    }

    /*******************************************************************************
    * @description Method checks for errors in the Template Info tab. Tab currently
    * only has one required field (Name) and this only checks that any value is present
    * there.
    */
    validateTemplateInfoTab(tabsWithErrors) {
        const templateInfoComponent = this.template.querySelector('c-ge-template-builder-template-info');

        if (templateInfoComponent) {
            // Component exists in the dom and can validate itself.
            const isTemplateInfoTabValid = templateInfoComponent.validate();

            if (isTemplateInfoTabValid) {
                this.hasTemplateInfoTabError = false;
            } else {
                this.hasTemplateInfoTabError = true;
                tabsWithErrors.add(this.TabEnums.INFO_TAB);
            }
        }
    }

    /*******************************************************************************
    * @description Method checks for errors in the Select Fields tab. Currently only
    * checks for 'requiredness' in the Field Mapping's source (DataImport__c).
    */
    validateSelectFieldsTab(tabsWithErrors) {
        const selectFieldsComponent = this.template.querySelector('c-ge-template-builder-select-fields');

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
                tabsWithErrors.add(this.TabEnums.SELECT_FIELDS_TAB);
            } else {
                this.hasSelectFieldsTabError = false;
            }
        }
    }

    /*******************************************************************************
    * @description Method checks for missing required DataImportBatch__c fields
    * and adds them proactively.
    */
    validateBatchHeaderTab() {
        this.missingRequiredBatchFields = findMissingRequiredBatchFields(this.batchFieldFormElements,
            this.batchHeaderFields);

        if (this.missingRequiredBatchFields && this.missingRequiredBatchFields.length > 0) {
            for (let field of this.missingRequiredBatchFields) {
                this.handleAddBatchHeaderField({ detail: field.apiName });
            }

            const fieldLabels = this.missingRequiredBatchFields.map(field => field.label);
            showToast('Warning',
                `Added the following missing required Batch Header fields: ${fieldLabels}`,
                'warning',
                'sticky');
        }
    }

    /*******************************************************************************
    * @description Method sets properties on the formTemplate object and passes the
    * FormTemplate JSON to apex and waits for a record id so we can navigate
    * to the newly inserted Form_Template__c record detail page.
    */
    handleFormTemplateSave = async () => {
        this.previousSaveAttempted = true;
        const isTemplateValid = this.checkTabsValidity();

        if (isTemplateValid) {
            this.isLoading = true;
            this.formLayout.sections = this.formSections;
            this.formTemplate.batchHeaderFields = this.batchHeaderFields;
            this.formTemplate.layout = this.formLayout;

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

            await storeFormTemplate(preppedFormTemplate);

            this[NavigationMixin.Navigate]({
                type: 'standard__navItemPage',
                attributes: {
                    apiName: this.listViewCustomTabApiName
                }
            });
        }
    }

    /*******************************************************************************
    * @description Navigates to the list view GE_Templates tab.
    */
    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: this.listViewCustomTabApiName
            }
        });
    }

    /*******************************************************************************
    * @description Navigates to a record detail page by record id.
    */
    navigateToRecordViewPage(formTemplateRecordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: formTemplateRecordId,
                actionName: 'view'
            }
        });
    }
}