import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { dispatch, handleError } from 'c/utilTemplateBuilder';
import { showToast } from 'c/utilCommon';
import GeLabelService from 'c/geLabelService';
import { deleteRecord } from 'lightning/uiRecordApi';
import FORM_TEMPLATE_INFO from '@salesforce/schema/Form_Template__c';
import DATA_IMPORT_BATCH_INFO from '@salesforce/schema/DataImportBatch__c';
import TEMPLATE_LAST_MODIFIED_DATE_INFO from '@salesforce/schema/Form_Template__c.LastModifiedDate';

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
    // TODO: Move this tracked property to a getter
    @track templatesTableActions = TEMPLATES_TABLE_ACTIONS;
    @track isAccessible = true;
    @track isLoading = true;

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

    /*******************************************************************************
    * @description Opens the new batch wizard modal.
    */
    openNewBatchWizard(event) {
        event.stopPropagation();
        const detail = {
            componentProperties: {
                recordId: event.record ? event.record.Id : undefined,
                dedicatedListenerEventName: 'geBatchWizardEvent'
            },
            modalProperties: {
                cssClass: 'slds-modal_large',
                componentName: 'geBatchWizard',
                showCloseButton: true,
                // TODO: We can use this callback after a save/update/cancel action
                // to perform additional logic in BGE (refresh, redirect, etc).
                // Otherwise we can scrap it in the "BGE Batch Header Edit" WI.
                closeCallback: undefined,
            }
        };

        dispatch(this, EVENT_TOGGLE_MODAL, detail);
    }

    connectedCallback() {
        this.isLoading = false;
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
                this.navigateToTemplateBuilder(row.Id, { clone: true });
                break;
            case 'delete':
                this.geListViewComponent.setProperty(IS_LOADING, true);
                this.handleTemplateDeletion(row);
                break;
            default:
        }
    }

    /*******************************************************************************************************
     * @description Handles Form Template Deletion. Currently prevents deletion if Form Templates used by a
     * Data Import Batch
     * @param {Id} recordId : Record id of the Form_Template__c to be deleted
     */
    handleTemplateDeletion(row) {
        deleteRecord(row.Id)
            .then(() => {
                this.geListViewComponent.setProperty(IS_LOADING, false);
                this.geListViewComponent.refresh();
                const toastMessage = GeLabelService.format(
                    this.CUSTOM_LABELS.geToastTemplateDeleteSuccess,
                    [row.Name]);

                showToast(toastMessage, '', SUCCESS);
            })
            .catch(error => {
                handleError(error);
                this.geListViewComponent.setProperty(IS_LOADING, false);
                this.geListViewComponent.refresh();
            });
    }

    /*******************************************************************************
    * @description Navigates to the Template Builder. If a recordId is provided,
    * adds the recordId to the navigation state (query param).
    *
    * @param {string} recordId: Record id of the Form_Template__c
    */
    navigateToTemplateBuilder(recordId, additionalParameters) {
        dispatch(this, 'changeview', {
            view: 'Template_Builder',
            formTemplateId: recordId,
            ...additionalParameters
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
        dispatch(this, 'changeview', { view: 'Single_Gift_Entry' });
    }

    /*******************************************************************************
     * Start getters for data-qa-locator attributes
     */

    get qaLocatorButtonNewBatch() {
        return `button Header ${this.CUSTOM_LABELS.geButtonNewBatch}`;
    }

    get qaLocatorButtonNewSingleGift() {
        return `button Header ${this.CUSTOM_LABELS.geButtonNewSingleGift}`;
    }

    get qaLocatorCreateTemplate() {
        return `button ${this.CUSTOM_LABELS.geButtonTemplatesTabCreateTemplate}`;
    }

    get qaLocatorBatches() {
        return `tab link ${this.CUSTOM_LABELS.commonBatches}`;
    }

    get qaLocatorTemplates() {
        return `tab link ${this.CUSTOM_LABELS.commonTemplates}`;
    }

    /*******************************************************************************
     * End getters for data-qa-locator attributes
     */

}