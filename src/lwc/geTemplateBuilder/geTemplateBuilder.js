import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import processFormTemplate from '@salesforce/apex/GE_TemplateBuilderCtrl.processFormTemplate';
import retrieveFormTemplate from '@salesforce/apex/GE_TemplateBuilderCtrl.retrieveFormTemplate';
import { FormTemplate, FormLayout, mutable } from 'c/utilTemplateBuilder';

export default class geTemplateBuilder extends NavigationMixin(LightningElement) {
    @track activeTab;
    _previousTab;

    @track formTemplate = new FormTemplate(
        undefined,
        undefined,
        new FormLayout()
    );

    /* TODO: Needs to be revisited, WIP tied to retrieving and rendering an existing template */
    get templateInfo() {
        return { name: this.formTemplate.name, description: this.formTemplate.description };
    }

    /* TODO: Needs to be revisited, WIP tied to retrieving and rendering an existing template */
    get batchHeaderFields() {
        return this.formTemplate.batchHeaderFields ? this.formTemplate.batchHeaderFields : undefined;
    }

    /* TODO: Needs to be revisited, WIP tied to retrieving and rendering an existing template */
    get layoutSections() {
        return this.formTemplate.layout ? this.formTemplate.layout.sections : undefined;
    }

    /* TODO: Needs to be revisited, WIP tied to retrieving and rendering an existing template */
    get selectedFieldMappingSet() {
        return this.formTemplate.layout.fieldMappingSetDevName ? this.formTemplate.layout.fieldMappingSetDevName : undefined;
    }

    /*******************************************************************************
    * @description Lifecycle hook that gets called after every render of the component.
    * Need to reset the activeTab for lightning:tabset to rerender properly because
    * clicking on the individual lightning:tab components does not auto-update the
    * lightning:tabset active-tab-value property.
    */
    renderedCallback() {
        this.activeTab = undefined;
    }

    /*******************************************************************************
    * @description Handles previous and next tab navigation
    *
    * @param {object} event: Event received from child component
    */
    handleGoToTab(event) {
        this.activeTab = event.detail.tabValue;
    }

    /*******************************************************************************
    * @description Function queries for the builder's various child components,
    * calls a data getter method on each child component, and populates properties
    * on the FormTemplate object. Pass the FormTemplate JSON to apex and awaits
    * for a record id so we can navigate to the inserted Form_Template__c detail page
    */
    handleFormTemplateSave = async () => {
        const templateInfo = this.template.querySelector('c-ge-template-builder-template-info').getTabData();
        const batchHeader = this.template.querySelector('c-ge-template-builder-batch-header').getTabData();
        const formLayout = this.template.querySelector('c-ge-template-builder-gift-fields').getTabData();

        this.formTemplate.name = templateInfo.name;
        this.formTemplate.description = templateInfo.description;
        this.formTemplate.batchHeaderFields = batchHeader;
        this.formTemplate.layout = formLayout;

        const preppedFormTemplate = {
            templateJSON: JSON.stringify(this.formTemplate),
            templateName: this.formTemplate.name,
            templateDescription: this.formTemplate.description
        };
        const formTemplateRecordId = await processFormTemplate(preppedFormTemplate);

        this.navigateToRecordViewPage(formTemplateRecordId);
    }

    /*******************************************************************************
    * @description Navigates to a record detail page by record id
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

    /* TODO: Needs to be revisited, WIP tied to retrieving and rendering an existing template */
    getFormTemplate() {
        const templateId = this.template.querySelector('lightning-input[data-name="templateId"]').value;
        retrieveFormTemplate({ templateId: templateId })
            .then(data => {
                this.formTemplate = data;
            })
            .catch(error => {
                console.log('Error: ', error);
            })
    }

    /* delete once all sections are their own components, currently only used by
    * matching logic tab */
    handleToggleClick(event) {
        this._previousTab = this.activeTab;
        this.activeTab = event.target.getAttribute('data-tab-value');
    }
}