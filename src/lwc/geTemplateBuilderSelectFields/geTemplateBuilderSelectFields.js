import { LightningElement, track, api } from 'lwc';
import { findIndexByProperty, mutable, generateId, dispatch, showToast } from 'c/utilTemplateBuilder';
import TemplateBuilderService from 'c/geTemplateBuilderService';

// Import source field names for required Field Mappings
import DONATION_AMOUNT_INFO from '@salesforce/schema/DataImport__c.Donation_Amount__c';
import DONATION_DATE_INFO from '@salesforce/schema/DataImport__c.Donation_Date__c';
import PAYMENT_CHECK_REF_NUM_INFO from '@salesforce/schema/DataImport__c.Payment_Check_Reference_Number__c';

export default class geTemplateBuilderSelectFields extends LightningElement {
    isInitialized;
    @api previousSaveAttempted;

    @track isLoading = true;
    @api selectedFieldMappingSet;

    @api formSections;

    @api activeFormSectionId;
    @track _sectionIdsByFieldMappingDeveloperNames = {};
    @track objectMappings;
    objectMappingNames = [];
    @track isAllSectionsExpanded = false;

    @track hasErrors = false;
    @track errors;

    @api
    validate() {
        let isValid;
        let objectMappingsWithMissingRequiredFields = new Set();
        let missingRequiredFieldMappings = [];

        const elements = this.template.querySelectorAll('lightning-input');
        elements.forEach(el => {
            if (el.required && !el.checked) {
                objectMappingsWithMissingRequiredFields.add(el.getAttribute('data-object-mapping'));
                let objectMappingLabel = el.getAttribute('data-object-mapping-label');
                missingRequiredFieldMappings.push(`${objectMappingLabel}: ${el.label}`);
            }

            this.validateGiftField(el);
        });

        if (missingRequiredFieldMappings.length > 0) {
            const lightningAccordion = this.template.querySelector('lightning-accordion');
            lightningAccordion.activeSectionName = [...objectMappingsWithMissingRequiredFields];

            this.hasErrors = true;
            this.errors = [...missingRequiredFieldMappings];

            isValid = false;
        } else {
            isValid = true;
            this.hasErrors = false;
            this.errors = [];
        }

        dispatch(this, 'updatevalidity', { property: 'hasSelectFieldsTabError', hasError: this.hasErrors });
        return isValid;
    }

    toggleModal(event) {
        dispatch(this, 'togglemodal', event.detail);
    }

    renderedCallback() {
        if (!this.isInitialized && this.isLoading === false && this.previousSaveAttempted) {
            this.isInitialized = true;
            this.validate();
        }
    }

    connectedCallback() {
        this.init();
    }

    init = async () => {
        this.objectMappings = await this.buildObjectMappingsList();

        this.handleSortFieldMappings();
        this.handleRequiredFields();
        this.loadObjectAndFieldMappingSets();
        this.isLoading = false;
    }

    /*******************************************************************************
    * @description Intermediary async method for pulling the object and field mappings
    * stored in the TemplateBuilderService component and build an iterable list for
    * the UI.
    */
    buildObjectMappingsList = async () => {
        let objectMappings = [];

        const fieldMappingsByObjMappingDevName = TemplateBuilderService.fieldMappingsByObjMappingDevName;
        for (const objMappingDevName in fieldMappingsByObjMappingDevName) {

            if (Object.prototype.hasOwnProperty.call(fieldMappingsByObjMappingDevName, objMappingDevName)) {
                this.objectMappingNames = [...this.objectMappingNames, objMappingDevName];

                let fieldMappings = TemplateBuilderService.fieldMappingsByObjMappingDevName[objMappingDevName];
                let objectMapping = {
                    ...TemplateBuilderService.objectMappingByDevName[objMappingDevName],
                    Field_Mappings: fieldMappings
                }

                objectMappings.push(objectMapping)
            }
        }

        return objectMappings;
    }

    /*******************************************************************************
    * @description Sorts the field mappings within their respective object mappings
    * alphabetically and by their requiredness.
    */
    handleSortFieldMappings() {
        let objectMappings = mutable(this.objectMappings);
        for (let i = 0; i < objectMappings.length; i++) {
            let objectMapping = objectMappings[i];

            if (objectMapping.Field_Mappings) {
                objectMapping.Field_Mappings.sort(function (a, b) {
                    const requiredCompare = b.Is_Required - a.Is_Required;
                    const labelCompare = a.Target_Field_Label.localeCompare(b.Target_Field_Label);

                    return requiredCompare || labelCompare;
                });
            }
        }

        this.objectMappings = objectMappings;
    }

    /*******************************************************************************
    * @description Creates a default section and adds required fields.
    */
    handleRequiredFields() {
        if (this.formSections && this.formSections.length === 0) {
            const REQUIRED_FIELDS = [
                DONATION_AMOUNT_INFO.fieldApiName,
                DONATION_DATE_INFO.fieldApiName,
                PAYMENT_CHECK_REF_NUM_INFO.fieldApiName
            ];

            let sectionId = this.addSection('Gift Entry Form');

            for (let fieldMappingDevName in TemplateBuilderService.fieldMappingByDevName) {
                if (TemplateBuilderService.fieldMappingByDevName[fieldMappingDevName]) {
                    const fieldMapping = TemplateBuilderService.fieldMappingByDevName[fieldMappingDevName];
                    const objectMapping = TemplateBuilderService.objectMappingByDevName[fieldMapping.Target_Object_Mapping_Dev_Name];

                    if (REQUIRED_FIELDS.includes(fieldMapping.Source_Field_API_Name)) {
                        let formField = this.constructFormField(objectMapping, fieldMapping, sectionId);
                        this.addFieldToSection(sectionId, formField);
                        this.catalogSelectedField(fieldMapping.DeveloperName, sectionId);
                    }
                }
            }

            this.toggleCheckboxForSelectedFieldMappings(this.objectMappings);
        }
    }

    /*******************************************************************************
    * @description Method determines whether or not we're pulling an existing
    * template, populates the UI with the appropriate object and field mappings,
    * and toggles field mapping checkboxes.
    */
    loadObjectAndFieldMappingSets() {
        const isExistingTemplate = this.selectedFieldMappingSet;

        if (isExistingTemplate && this.formSections) {
            if (this.formSections.length === 1) {
                this.handleChangeActiveSection({ detail: this.formSections[0].id });
            }
            for (let i = 0; i < this.formSections.length; i++) {
                const formSection = this.formSections[i];
                formSection.elements.forEach(element => {
                    const name = element.componentName ? element.componentName : element.dataImportFieldMappingDevNames[0];
                    this.catalogSelectedField(name, formSection.id)
                });
            }
            this.toggleCheckboxForSelectedFieldMappings(this.objectMappings);
        }
    }

    /*******************************************************************************
    * @description Removes a section and unchecks checkboxes for all the gift fields
    * contained in this section
    *
    * @param {object} event: Onclick event object from lightning-button-icon
    */
    @api
    handleDeleteFormSection(event) {
        const formSectionId = event.detail;
        let isRequiredFormElement = false;

        let formSections = mutable(this.formSections);
        let formSection = formSections.find(fs => fs.id === formSectionId);

        if (formSection.id === this.activeFormSectionId) {
            this.activeFormSectionId = undefined;
        }

        if (formSection.elements && formSection.elements.length > 0) {
            const formFields = formSection.elements;
            for (let i = 0; i < formFields.length; i++) {
                if (formFields[i].Is_Required) {
                    isRequiredFormElement = true;
                }

                const inputName = formFields[i].componentName ? formFields[i].componentName : formFields[i].dataImportFieldMappingDevNames[0];
                let checkbox =
                    this.template.querySelector(`lightning-input[data-field-mapping="${inputName}"]`);
                checkbox.checked = false;
            }
        }

        const formSectionIndex = findIndexByProperty(formSections, 'id', formSection.id);
        formSections.splice(formSectionIndex, 1);

        if (formSections.length === 1) {
            this.handleChangeActiveSection({ detail: this.formSections[0].id });
        }

        if (isRequiredFormElement) {
            this.validate();
        }

        dispatch(this, 'refreshformsections', formSections);
    }

    /*******************************************************************************
    * @description Receives event from the child component and dispatches an event to
    * notify parent component geTemplateBuilder that the active section has changed.
    *
    * @param {object} event: Event object containing the section id from the
    * child component geTemplateBuilderFormSection.
    */
    handleChangeActiveSection(event) {
        dispatch(this, 'changeactivesection', event.detail);
    }

    /*******************************************************************************
    * @description Handles onchange event of the gift fields checkboxes. Adds/removes
    * gift fields from sections.
    *
    * @param {object} event: Onchange event object from lightning-input checkbox
    */
    handleToggleFieldMapping(event) {
        const name = event.target.value;
        const fieldMapping = TemplateBuilderService.fieldMappingByDevName[name];
        const objectMapping = TemplateBuilderService.objectMappingByDevName[fieldMapping.Target_Object_Mapping_Dev_Name];
        let sectionId = this.activeFormSectionId;
        const isAddField = event.target.checked;

        if (isAddField) {
            const hasNoSection = !this.formSections || this.formSections.length === 0;
            const hasOneSection = this.formSections.length === 1;
            const hasManySections = this.formSections.length > 1;
            const hasNoActiveSection = this.activeFormSectionId === undefined;

            if (hasNoSection) {
                sectionId = this.addSection();
            } else if (hasOneSection) {
                sectionId = this.formSections[0].id;
                this.activeFormSectionId = sectionId;
            } else if (hasManySections && hasNoActiveSection) {
                event.target.checked = false;
                showToast('Please select a section', '', 'warning');
                return;
            }

            let formElement;
            if (fieldMapping.Element_Type === 'field') {
                formElement = this.constructFormField(objectMapping, fieldMapping, sectionId);
            } else if (fieldMapping.Element_Type === 'widget') {
                formElement = this.constructFormWidget(fieldMapping, sectionId);
            }

            this.catalogSelectedField(name, sectionId);
            this.formSections = this.addFieldToSection(sectionId, formElement);
        } else {
            this.handleRemoveFormElement(name);
        }

        if (fieldMapping.Is_Required) {
            this.validate();
        }
    }

    /*******************************************************************************
    * @description Dispatches an event up notifying parent component geTemplateBuilder
    * that an element needs to be removed with the given name and section id.
    *
    * @param {string} name: Name of the element to be removed, field mapping developer
    * name or widget component name.
    */
    handleRemoveFormElement(name) {
        const sectionId = this._sectionIdsByFieldMappingDeveloperNames[name];
        dispatch(this, 'removefieldfromsection', {
            sectionId: sectionId,
            fieldName: name
        });
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
            required: fieldMapping.Is_Required || false,
            sectionId: sectionId,
            defaultValue: null,
            dataType: fieldMapping.Target_Field_Data_Type,
            dataImportFieldMappingDevNames: [fieldMapping.DeveloperName],
            elementType: fieldMapping.Element_Type
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
            required: false,
            sectionId: sectionId,
            elementType: widget.Element_Type
        }
    }

    /*******************************************************************************
    * @description Maps the given field mapping developer name to the section id.
    * Used to later find and remove gift fields from their sections.
    *
    * @param {string} fieldMappingDeveloperName: Developer name of a Field Mapping
    * @param {string} sectionId: Id of form section this form widget will be in.
    */
    catalogSelectedField(fieldMappingDeveloperName, sectionId) {
        this._sectionIdsByFieldMappingDeveloperNames[fieldMappingDeveloperName] = sectionId;
    }

    /*******************************************************************************
    * @description Handles adding a new section. Dispatches an event to notify parent
    * component geTemplateBuilder that a new section needs to be added.
    *
    * @return {string} id: Generated id of the new section.
    */
    addSection(label) {
        label = typeof label === 'string' ? label : 'New Section';
        let newSection = {
            id: generateId(),
            displayType: 'accordion',
            defaultDisplayMode: 'expanded',
            displayRule: 'displayRule',
            label: label,
            elements: []
        }
        dispatch(this, 'addformsection', newSection);

        return newSection.id
    }

    /*******************************************************************************
    * @description Handles adding a new FormField to a FormSection. Dispatches an
    * event to notify parent component geTemplateBuilder that new FormField needs
    * to be added to the FormSection with the given id.
    *
    * @param {string} sectionId: Id of the parent FormSection
    * @param {object} field: Instance of FormField to be added to FormSection
    */
    addFieldToSection(sectionId, field) {
        const detail = {
            sectionId: sectionId,
            field: field
        }
        dispatch(this, 'addfieldtosection', detail);
    }

    /*******************************************************************************
    * @description Receives event from child component and dispatches event to
    * parent to move the given FormField up within its parent FormSection.
    *
    * @param {object} event: Event object from child component.
    * component chain: geTemplateBuilderFormField -> geTemplateBuilderFormSection -> here
    */
    handleFormElementUp(event) {
        dispatch(this, 'formelementup', event.detail);
    }

    /*******************************************************************************
    * @description Receives event from child component and dispatches event to
    * parent to move the given FormField down within its parent FormSection.
    *
    * @param {object} event: Event object from child component.
    * component chain: geTemplateBuilderFormField -> geTemplateBuilderFormSection -> here
    */
    handleFormElementDown(event) {
        dispatch(this, 'formelementdown', event.detail);
    }

    /*******************************************************************************
    * @description Receives event from child component and dispatches event to
    * parent to remove the FormField from its parent FormSection.
    *
    * @param {object} event: Event object from child component.
    * component chain: geTemplateBuilderFormField -> geTemplateBuilderFormSection -> here
    */
    handleDeleteFormElement(event) {
        const fieldMapping = TemplateBuilderService.fieldMappingByDevName[event.detail.fieldName];
        const element = this.template.querySelector(`lightning-input[data-field-mapping="${event.detail.fieldName}"]`);
        element.checked = false;

        if (fieldMapping.Is_Required) {
            this.validate();
        }
        dispatch(this, 'deleteformelement', event.detail);
    }

    /*******************************************************************************
    * @description Receives event from child component and dispatches event to
    * parent to update the details of the given FormField.
    *
    * @param {object} event: Event object from child component.
    * component chain: geTemplateBuilderFormField -> geTemplateBuilderFormSection -> here
    */
    handleUpdateFormElement(event) {
        dispatch(this, 'updateformelement', event.detail);
    }

    /*******************************************************************************
    * @description Receives event from child component and dispatches event to
    * parent to move the given FormSection up.
    *
    * @param {object} event: Event object from child component.
    * component chain: geTemplateBuilderFormSection -> here
    */
    handleFormSectionUp(event) {
        const sectionId = event.detail;
        dispatch(this, 'formsectionup', sectionId);
    }

    /*******************************************************************************
    * @description Receives event from child component and dispatches event to
    * parent to move the given FormSection down.
    *
    * @param {object} event: Event object from child component.
    * component chain: geTemplateBuilderFormSection -> here
    */
    handleFormSectionDown(event) {
        const sectionId = event.detail;
        dispatch(this, 'formsectiondown', sectionId);
    }

    /*******************************************************************************
    * @description Method toggles the checkboxes for any existing/selected gift
    * fields. Used when retrieving an existing form template.
    *
    * @param {list} objectMappings: List of object mappings containing field mapping details
    */
    toggleCheckboxForSelectedFieldMappings(objectMappings) {
        const selectedFieldMappings = Object.keys(this._sectionIdsByFieldMappingDeveloperNames);

        if (selectedFieldMappings && selectedFieldMappings.length > 0) {
            for (let i = 0; i < objectMappings.length; i++) {
                let fieldMappings = objectMappings[i].Field_Mappings;

                for (let ii = 0; ii < fieldMappings.length; ii++) {
                    let fieldMapping = fieldMappings[ii];

                    if (selectedFieldMappings.includes(fieldMapping.DeveloperName)) {
                        fieldMapping.checked = true;
                    }
                }
            }

            this.objectMappings = objectMappings;
        }
    }

    /*******************************************************************************
    * @description Handles onsectiontoggle event handler of lightning-accordion.
    * Sets the isAllSectionsExpanded property.
    *
    * @param {object} event: Event object from lightning-accordion onsectiontoggle
    * event handler.
    */
    handleSectionToggle(event) {
        const openSections = event.detail.openSections;

        if (openSections.length === 0) {
            this.isAllSectionsExpanded = false;
        } else if (openSections.length === this.objectMappingNames.length) {
            this.isAllSectionsExpanded = true;
        }
    }

    /*******************************************************************************
    * @description Handles onclick event handler of lightning-button.
    * Toggles all sections open and sets the isAllSectionsExpanded property.
    *
    * @param {object} event: Event object from lightning-button onclick
    * event handler.
    */
    handleExpandAllSections() {
        const lightningAccordion = this.template.querySelector('lightning-accordion');
        lightningAccordion.activeSectionName = [...this.objectMappingNames];
        this.isAllSectionsExpanded = true;
    }

    /*******************************************************************************
    * @description Handles onclick event handler of lightning-button.
    * Toggles all sections closed and sets the isAllSectionsExpanded property.
    *
    * @param {object} event: Event object from lightning-button onclick
    * event handler.
    */
    handleCollapseAllSections() {
        const lightningAccordion = this.template.querySelector(
            'lightning-accordion'
        );
        lightningAccordion.activeSectionName = [];
        this.isAllSectionsExpanded = false;
    }

    /*******************************************************************************
    * @description Method takes in a lightning-input element and sets validity.
    *
    * @param {object} element: Lightning-input element to set and report validity
    * of.
    */
    validateGiftField(element) {
        let customValidity = 'Required field';
        customValidity = (element.required && element.checked === false) ? customValidity : '';

        element.setCustomValidity(customValidity);
        element.reportValidity();
    }
}