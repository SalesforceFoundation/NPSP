import { LightningElement, api, track } from 'lwc';
import { mutable, dispatch } from 'c/utilTemplateBuilder';

const activeSectionClass = 'slds-card slds-card_extension slds-card_extension_active slds-m-vertical_small';
const inActiveSectionClass = 'slds-card slds-card_extension slds-m-vertical_small';

export default class GeTemplateBuilderFormSection extends LightningElement {
    @api activeFormSectionId;
    @api isFirst;
    @api isLast;
    @track isEditMode;

    @track formSection;
    @api
    set formSection(formSection) {
        this.formSection = formSection;
    }

    get isActive() {
        return this.activeFormSectionId === this.formSection.id ? true : false;
    }

    get sectionClass() {
        return this.isActive ? activeSectionClass : inActiveSectionClass;
    }

    get isEmptySection() {
        return this.formSection.elements.length === 0 ? true : false;
    }

    /*******************************************************************************
    * @description Public method that collects the current values of all the relevant
    * input fields for this FormSection and return an instance of FormSection.
    *
    * @return {object} formSection: Instance of the FormSection class
    */
    @api
    getFormSectionValues() {
        let formSection = mutable(this.formSection);
        formSection.elements = this.getSectionFormFields();
        return formSection;
    }

    /*******************************************************************************
    * @description Method that collects all relevant input fields and returns a list
    * of FormFields.
    *
    * @return {list} sectionFormFields: List of FormFields
    */
    getSectionFormFields() {
        let sectionFormFieldComponents = this.template.querySelectorAll('c-ge-template-builder-form-field');
        let sectionFormFields = [];
        for (let i = 0; i < sectionFormFieldComponents.length; i++) {
            let formField = sectionFormFieldComponents[i].getFormFieldValues();
            sectionFormFields.push(formField);
        }

        return sectionFormFields;
    }

    /*******************************************************************************
    * @description Dispatches an event notifying the parent component GE_TemplateBuilder
    * to open a modal for editing the section.
    *
    * @param {object} event: Event object from lightning-button-icon onclick event handler.
    */
    handleEditFormSection(event) {
        event.stopPropagation();
        const detail = { action: 'edit', section: this.formSection };
        dispatch(this, 'togglemodal', detail);
    }

    /*******************************************************************************
    * @description Dispatches an event up to parent component geTemplateBuilderSelectFields
    * to set the currently active section
    */
    handleSelectActiveSection() {
        dispatch(this, 'changeactivesection', this.formSection.id);
    }

    /*******************************************************************************
    * @description Dispatches an event up to parent component geTemplateBuilderSelectFields
    * to move the FormSection up.
    * 
    * @param {object} event: Event object from lightning-button-icon onclick event handler.
    */
    handleFormSectionUp(event) {
        event.stopPropagation();
        dispatch(this, 'formsectionup', this.formSection.id);
    }

    /*******************************************************************************
    * @description Dispatches an event up to parent component geTemplateBuilderSelectFields
    * to move the FormSection down.
    * 
    * @param {object} event: Event object from lightning-button-icon onclick event handler.
    */
    handleFormSectionDown(event) {
        event.stopPropagation();
        dispatch(this, 'formsectiondown', this.formSection.id);
    }

    /*******************************************************************************
    * @description Dispatches an event notifying the parent component
    * geTemplateBuilderSelectFields to move a FormField in the FormSection up.
    *
    * @param {object} event: Event received from child component.
    * component chain: geTemplateBuilderFormField -> here
    */
    handleFormFieldUp(event) {
        event.stopPropagation();
        const detail = {
            sectionId: this.formSection.id,
            fieldName: event.detail
        }
        dispatch(this, 'formfieldup', detail);
    }

    /*******************************************************************************
    * @description Dispatches an event notifying the parent component
    * geTemplateBuilderSelectFields to move a FormField in the FormSection down.
    *
    * @param {object} event: Event received from child component.
    * component chain: geTemplateBuilderFormField -> here
    */
    handleFormFieldDown(event) {
        event.stopPropagation();
        const detail = {
            sectionId: this.formSection.id,
            fieldName: event.detail
        }
        dispatch(this, 'formfielddown', detail);
    }

    /*******************************************************************************
    * @description Dispatches an event notifying the parent component
    * geTemplateBuilderSelectFields that a property in a FormField has changed values.
    *
    * @param {object} event: Event received from child component.
    * component chain: geTemplateBuilderFormField -> here
    */
    handleUpdateFormField(event) {
        event.detail.sectionId = this.formSection.id;
        dispatch(this, 'updateformfield', event.detail);
    }

    /*******************************************************************************
    * @description Dispatches an event notifying the parent component
    * geTemplateBuilderSelectFields that a FormField needs to be removed from the
    * FormSection.
    *
    * @param {object} event: Event received from child component.
    * component chain: geTemplateBuilderFormField -> here
    */
    handleDeleteFormField(event) {
        event.stopPropagation();
        const detail = {
            sectionId: this.formSection.id,
            fieldName: event.detail.fieldName,
            id: event.detail.id
        }
        dispatch(this, 'deleteformfield', detail);
    }
}