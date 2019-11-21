import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getAllFormTemplates from '@salesforce/apex/FORM_ServiceGiftEntry.getAllFormTemplates';
import deleteFormTemplates from '@salesforce/apex/FORM_ServiceGiftEntry.deleteFormTemplates';
import cloneFormTemplate from '@salesforce/apex/FORM_ServiceGiftEntry.cloneFormTemplate';
import TemplateBuilderService from 'c/geTemplateBuilderService';
import { findIndexByProperty } from 'c/utilTemplateBuilder';

const actions = [
    { label: 'Edit', name: 'edit' },
    { label: 'Clone', name: 'clone' },
    { label: 'Delete', name: 'delete' }
];

const columns = [
    { label: 'Template Name', fieldName: 'name' },
    { label: 'Template Description', fieldName: 'description' },
    {
        type: 'action',
        typeAttributes: { rowActions: actions },
    },
];

export default class GeTemplates extends NavigationMixin(LightningElement) {
    @track templates;
    @track columns = columns;
    @track isLoading = true;
    currentNamespace;

    get templateBuilderCustomTabApiName() {
        return this.currentNamespace ? `${this.currentNamespace}__GE_Template_Builder` : 'GE_Template_Builder';
    }

    connectedCallback() {
        this.init();
    }

    init = async () => {
        await TemplateBuilderService.init('Migrated_Custom_Field_Mapping_Set');
        this.currentNamespace = TemplateBuilderService.namespaceWrapper.currentNamespace;
        this.templates = await getAllFormTemplates();
        this.isLoading = false;
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        this.isLoading = true;

        switch (actionName) {
            case 'edit':
                this.navigateToTemplateBuilder(row.id);
                break;
            case 'clone':
                cloneFormTemplate({ id: row.id }).then((clonedTemplate) => {
                    this.templates = [...this.templates, clonedTemplate];
                    this.isLoading = false;
                });
                break;
            case 'delete':
                deleteFormTemplates({ ids: [row.id] }).then(() => {
                    const index = findIndexByProperty(this.templates, 'id', row.id);
                    this.templates.splice(index, 1);
                    this.templates = [...this.templates];
                    this.isLoading = false;
                });
                break;
            default:
        }
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