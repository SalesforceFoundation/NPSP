import { LightningElement, api } from 'lwc';
import { dispatch } from 'c/utilTemplateBuilder';
import GeLabelService from 'c/geLabelService';

const activeSectionClass = 'slds-card slds-card_extension slds-card_extension_active slds-m-vertical_small';
const inactiveSectionClass = 'slds-card slds-card_extension slds-m-vertical_small';

export default class GeTemplateBuilderFormSection extends LightningElement {

    // Expose custom labels to template
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    @api activeFormSectionId;
    @api isFirst;
    @api isLast;
    @api formSection;
    @api sourceObjectFieldsDescribe;


    get isActive() {
        return this.activeFormSectionId === this.formSection.id ? true : false;
    }

    get sectionClass() {
        return this.isActive ? activeSectionClass : inactiveSectionClass;
    }

    get isEmptySection() {
        return this.formSection.elements.length === 0 ? true : false;
    }

    get labelGeAssistiveFormFieldsSectionEdit() {
        return GeLabelService.format(this.CUSTOM_LABELS.geAssistiveFormFieldsSectionEdit, [this.formSection.label]);
    }

    get labelGeBuilderAssistiveSectionUp() {
        return GeLabelService.format(this.CUSTOM_LABELS.geAssistiveSectionUp, [this.formSection.label]);
    }

    get labelGeBuilderAssistiveSectionDown() {
        return GeLabelService.format(this.CUSTOM_LABELS.geAssistiveSectionDown, [this.formSection.label]);
    }

    /*******************************************************************************
    * Start getters for data-qa-locator attributes
    */

    get qaLocatorSection() {
        return `form section ${this.formSection.label}`;
    }

    get qaLocatorSectionSettings() {
        return `button Settings ${this.formSection.label}`;
    }

    get qaLocatorSectionUp() {
        return `button Up ${this.formSection.label}`;
    }

    get qaLocatorSectionDown() {
        return `button Down ${this.formSection.label}`;
    }

    /*******************************************************************************
    * End getters for data-qa-locator attributes
    */

    /*******************************************************************************
     * @description Handles the custom event fired from the geTemplateBuilderFormField child when
     * there is a metadata error on the field such as a deleted field mapping or deleted source or
     * target field.
     * @param {object} event: object for the custom event
     */
    handleFieldMetadataValidation(event) {
        this.dispatchEvent(new CustomEvent('fieldmetadatavalidation', {detail : event.detail}));
    }

    /*******************************************************************************
    * @description Dispatches an event notifying the parent component GE_TemplateBuilder
    * to open a modal for editing the section.
    *
    * @param {object} event: Event object from lightning-button-icon onclick event handler.
    */
    handleEditFormSection(event) {
        event.stopPropagation();
        const detail = {
            componentProperties: {
                modalData: {
                    section: this.formSection,
                    action: 'edit',
                    receiverComponent: 'ge-template-builder',
                },
                dedicatedListenerEventName: 'geTemplateBuilderSectionModalBodyEvent',
            },
            modalProperties: {
                componentName: 'geTemplateBuilderSectionModalBody',
                header: this.CUSTOM_LABELS.geHeaderFormFieldsModalSectionSettings,
                showCloseButton: true,
            }
        };
        //const detail = { componentName: 'ge-templates', action: 'edit', section: this.formSection };
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
    handleFormElementUp(event) {
        event.stopPropagation();
        const detail = {
            sectionId: this.formSection.id,
            fieldName: event.detail
        }
        dispatch(this, 'formelementup', detail);
    }

    /*******************************************************************************
    * @description Dispatches an event notifying the parent component
    * geTemplateBuilderSelectFields to move a FormField in the FormSection down.
    *
    * @param {object} event: Event received from child component.
    * component chain: geTemplateBuilderFormField -> here
    */
    handleFormElementDown(event) {
        event.stopPropagation();
        const detail = {
            sectionId: this.formSection.id,
            fieldName: event.detail
        }
        dispatch(this, 'formelementdown', detail);
    }

    /*******************************************************************************
    * @description Dispatches an event notifying the parent component
    * geTemplateBuilderSelectFields that a property in a FormField has changed values.
    *
    * @param {object} event: Event received from child component.
    * component chain: geTemplateBuilderFormField -> here
    */
    handleUpdateFormElement(event) {
        event.detail.sectionId = this.formSection.id;
        dispatch(this, 'updateformelement', event.detail);
    }

    /*******************************************************************************
    * @description Dispatches an event notifying the parent component
    * geTemplateBuilderSelectFields that a FormField needs to be removed from the
    * FormSection.
    *
    * @param {object} event: Event received from child component.
    * component chain: geTemplateBuilderFormField -> here
    */
    handleDeleteFormElement(event) {
        event.stopPropagation();
        const detail = {
            sectionId: this.formSection.id,
            fieldName: event.detail.fieldName,
            id: event.detail.id
        }
        dispatch(this, 'deleteformelement', detail);
    }
}