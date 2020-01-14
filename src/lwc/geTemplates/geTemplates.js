import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getAllFormTemplates from '@salesforce/apex/FORM_ServiceGiftEntry.getAllFormTemplates';
import deleteFormTemplates from '@salesforce/apex/FORM_ServiceGiftEntry.deleteFormTemplates';
import cloneFormTemplate from '@salesforce/apex/FORM_ServiceGiftEntry.cloneFormTemplate';
import getDataImportSettings from '@salesforce/apex/UTIL_CustomSettingsFacade.getDataImportSettings';
import TemplateBuilderService from 'c/geTemplateBuilderService';
import { showToast, dispatch, handleError } from 'c/utilCommon';
import GeLabelService from 'c/geLabelService';

import FORM_TEMPLATE_INFO from '@salesforce/schema/Form_Template__c';
import DATA_IMPORT_BATCH_INFO from '@salesforce/schema/DataImportBatch__c';
import FIELD_MAPPING_METHOD_FIELD_INFO from '@salesforce/schema/Data_Import_Settings__c.Field_Mapping_Method__c';
import TEMPLATE_LAST_MODIFIED_DATE_INFO from '@salesforce/schema/Form_Template__c.LastModifiedDate';

const ADVANCED_MAPPING = 'Data Import Field Mapping';
const DEFAULT_FIELD_MAPPING_SET = 'Migrated_Custom_Field_Mapping_Set';
const TEMPLATE_BUILDER_TAB_NAME = 'GE_Template_Builder';
const SUCCESS = 'success';
const IS_LOADING = 'isLoading';
const EVENT_TOGGLE_MODAL = 'togglemodal';
const SAVE = 'save';
const EDIT = 'edit';
const CLONE = 'clone';
const DELETE = 'delete';

const TEMPLATES_LIST_VIEW_NAME = 'Templates';
const TEMPLATES_LIST_VIEW_SORT_DIRECTION = 'desc';
const TEMPLATES_LIST_DEFAULT_LIMIT = 10;
const TEMPLATES_LIST_VIEW_ICON = 'standard:visit_templates';
const TEMPLATES_TABLE_ACTIONS = [
    { label: GeLabelService.CUSTOM_LABELS.commonEdit, name: EDIT },
    { label: GeLabelService.CUSTOM_LABELS.commonClone, name: CLONE },
    { label: GeLabelService.CUSTOM_LABELS.commonDelete, name: DELETE }
];

const BATCHES_LIST_VIEW_NAME = 'Batches';
const BATCHES_LIST_VIEW_DEFAULT_LIMIT = 10;
const BATCHES_LIST_VIEW_ICON = 'custom:custom17';

export default class GeTemplates extends NavigationMixin(LightningElement) {

    // Expose custom labels to template
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    @track templates;
    @track templatesTableActions = TEMPLATES_TABLE_ACTIONS;
    @track isAccessible = true;
    @track isLoading = true;

    get templateBuilderCustomTabApiName() {
        return TemplateBuilderService.alignSchemaNSWithEnvironment(TEMPLATE_BUILDER_TAB_NAME);
    }

    get formTemplateObjectApiName() {
        return FORM_TEMPLATE_INFO.objectApiName;
    }

    get templatesListViewName() {
        return TEMPLATES_LIST_VIEW_NAME;
    }

    get templatesListViewIcon() {
        return TEMPLATES_LIST_VIEW_ICON;
    }

    get templatesListViewDefaultLimit() {
        return TEMPLATES_LIST_DEFAULT_LIMIT;
    }

    get sortTemplatesBy() {
        return TEMPLATE_LAST_MODIFIED_DATE_INFO.fieldApiName;
    }

    get sortTemplatesDirection() {
        return TEMPLATES_LIST_VIEW_SORT_DIRECTION;
    }

    get dataImportBatchObjectApiName() {
        return DATA_IMPORT_BATCH_INFO.objectApiName;
    }

    get batchesListViewName() {
        return BATCHES_LIST_VIEW_NAME;
    }

    get batchesListViewIcon() {
        return BATCHES_LIST_VIEW_ICON;
    }

    get batchesListViewDefaultLimit() {
        return BATCHES_LIST_VIEW_DEFAULT_LIMIT;
    }

    get geListViewComponent() {
        return this.template.querySelector(`c-ge-list-view[data-id='${TEMPLATES_LIST_VIEW_NAME}']`);
    }

    /*******************************************************************************
    * @description Public method for receiving modal related events from geListView.
    *
    * @param {object} modalData: Event object containing the action and modal payload.
    * component chain: utilDualListbox -> geListView -> here.
    */
    @api
    notify(event) {
        if (event.action === SAVE) {
            const component =
                this.template.querySelector(`c-ge-list-view[data-id='${event.payload.name}']`);
            if (component) {
                component.notify(event);
            }
        }
    }

    /*******************************************************************************
    * @description Pass through method that receives an event from geListView to
    * notify parent aura component to construct a modal.
    *
    * @param {object} event: Event object containing a payload for the modal.
    */
    toggleModal(event) {
        dispatch(this, EVENT_TOGGLE_MODAL, event.detail);
    }

    connectedCallback() {
        this.init();
    }

    init = async () => {
        this.isAccessible = await this.checkPageAccess();

        if (this.isAccessible) {
            await TemplateBuilderService.init(DEFAULT_FIELD_MAPPING_SET);
            this.templates = await getAllFormTemplates();
            this.isLoading = false;
        }
    }

    /*******************************************************************************
    * @description Method checks for page level access. Currently only checks
    * if Advanced Mapping is on from the Data Import Custom Settings.
    */
    checkPageAccess = async () => {
        const dataImportSettings = await getDataImportSettings();
        const isAdvancedMappingOn =
            dataImportSettings[FIELD_MAPPING_METHOD_FIELD_INFO.fieldApiName] === ADVANCED_MAPPING;
        let hasPageAccess = false;

        if (isAdvancedMappingOn) {
            hasPageAccess = true;
        } else {
            this.isLoading = hasPageAccess = false;
        }
        return hasPageAccess;
    }

    /*******************************************************************************
    * @description Method handles actions for the Templates list view table.
    *
    * @param {object} event: Event received from the list view component
    * containing action details.
    */
    handleTemplatesTableRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {
            case 'edit':
                this.navigateToTemplateBuilder(row.Id);
                break;
            case 'clone':
                this.geListViewComponent.setProperty(IS_LOADING, true);

                cloneFormTemplate({ id: row.Id })
                    .then(clonedTemplate => {
                        this.templates = [...this.templates, clonedTemplate];
                        this.geListViewComponent.setProperty(IS_LOADING, false);
                        this.geListViewComponent.refresh();
                    })
                    .catch(error => {
                        handleError(error);
                    });
                break;
            case 'delete':
                this.geListViewComponent.setProperty(IS_LOADING, true);

                deleteFormTemplates({ ids: [row.Id] })
                    .then(formTemplateNames => {
                        this.geListViewComponent.setProperty(IS_LOADING, false);
                        this.geListViewComponent.refresh();

                        const toastMessage = GeLabelService.format(
                            this.CUSTOM_LABELS.geToastTemplateDeleteSuccess,
                            formTemplateNames);

                        showToast(toastMessage, '', SUCCESS);
                    })
                    .catch(error => {
                        handleError(error);
                    });
                break;
            default:
        }
    }

    /*******************************************************************************
    * @description Navigates to the Record Detail Page.
    *
    * @param {string} recordId: SObject Record ID
    */
    navigateToRecordViewPage(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }

    /*******************************************************************************
    * @description Navigates to the Template Builder. If a recordId is provided,
    * adds the recordId to the navigation state (query param).
    *
    * @param {string} recordId: Record id of the Form_Template__c
    */
    navigateToTemplateBuilder(recordId) {
        const queryParameter = recordId ? { c__recordId: recordId } : {};

        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: this.templateBuilderCustomTabApiName
            },
            state: queryParameter
        });
    }

    /*******************************************************************************
    * @description Handles onclick event from 'Create Template' button and navigates
    * to the Template Builder.
    */
    handleNewFormTemplate() {
        this.navigateToTemplateBuilder();
    }

    /*******************************************************************************
    * @description Handles onclick event from 'New Batch' button and navigates
    * to the Form Renderer.
    */
    navigateToForm() {
        this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                componentName: 'c__geFormRendererPlaceholder'
            }
        });
    }
}