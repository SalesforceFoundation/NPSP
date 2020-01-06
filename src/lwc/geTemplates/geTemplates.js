import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getAllFormTemplates from '@salesforce/apex/FORM_ServiceGiftEntry.getAllFormTemplates';
import deleteFormTemplates from '@salesforce/apex/FORM_ServiceGiftEntry.deleteFormTemplates';
import cloneFormTemplate from '@salesforce/apex/FORM_ServiceGiftEntry.cloneFormTemplate';
import getDataImportSettings from '@salesforce/apex/UTIL_CustomSettingsFacade.getDataImportSettings';
import TemplateBuilderService from 'c/geTemplateBuilderService';
import { findIndexByProperty } from 'c/utilTemplateBuilder';
import GeLabelService from 'c/geLabelService';
import FIELD_MAPPING_METHOD_FIELD_INFO from '@salesforce/schema/Data_Import_Settings__c.Field_Mapping_Method__c';

const actions = [
    { label: 'Edit', name: 'edit' },
    { label: 'Clone', name: 'clone' },
    { label: 'Delete', name: 'delete' }
];

const ADVANCED_MAPPING = 'Data Import Field Mapping';

const columns = [
    { label: 'Template Name', fieldName: 'name' },
    { label: 'Template Description', fieldName: 'description' },
    {
        type: 'action',
        typeAttributes: { rowActions: actions },
    },
];

export default class GeTemplates extends NavigationMixin(LightningElement) {

    // Expose custom labels to template
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    @track templates;
    @track columns = columns;
    @track isLoading = true;
    currentNamespace;
    @track isAccessible = true;

    get templateBuilderCustomTabApiName() {
        return this.currentNamespace ? `${this.currentNamespace}__GE_Template_Builder` : 'GE_Template_Builder';
    }

    connectedCallback() {
        this.init();
    }

    init = async () => {
        this.isAccessible = await this.checkPageAccess();
        if(this.isAccessible){
            await TemplateBuilderService.init('Migrated_Custom_Field_Mapping_Set');
            this.currentNamespace = TemplateBuilderService.namespaceWrapper.currentNamespace;
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