import { LightningElement, track, api } from 'lwc';
import { findIndexByProperty, mutable, generateId, dispatch } from 'c/utilTemplateBuilder';
import TemplateBuilderService from 'c/geTemplateBuilderService';

// Import source field names for required Field Mappings
import DONATION_AMOUNT_INFO from '@salesforce/schema/DataImport__c.Donation_Amount__c';
import DONATION_DATE_INFO from '@salesforce/schema/DataImport__c.Donation_Date__c';

export default class geTemplateBuilderSelectFields extends LightningElement {
    @track isLoading = true;
    @track selectedFieldMappingSet;

    @api
    set selectedFieldMappingSet(selectedFieldMappingSet) {
        this.selectedFieldMappingSet = selectedFieldMappingSet;
    }

    @api formSections;

    @api activeFormSectionId;
    @track _sectionIdsByFieldMappingDeveloperNames = {};
    @track fieldMappingSetComboboxOptions;
    @track objectMappings;
    objectMappingNames = [];
    @track isAllSectionsExpanded = false;

    toggleModal(event) {
        dispatch(this, 'togglemodal', event.detail);
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
        for (const objMappingDevName in TemplateBuilderService.fieldMappingsByObjMappingDevName) {
            if (TemplateBuilderService.fieldMappingsByObjMappingDevName[objMappingDevName]) {

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
                DONATION_DATE_INFO.fieldApiName
            ];

            let sectionId = this.handleAddSection('Gift Entry Form');

            for (let fieldMappingDevName in TemplateBuilderService.fieldMappingByDevName) {
                if (TemplateBuilderService.fieldMappingByDevName[fieldMappingDevName]) {
                    const fieldMapping = TemplateBuilderService.fieldMappingByDevName[fieldMappingDevName];
                    const objectMapping = TemplateBuilderService.objectMappingByDevName[fieldMapping.Target_Object_Mapping_Dev_Name];

                    if (REQUIRED_FIELDS.includes(fieldMapping.Source_Field_API_Name)) {
                        let formField = {
                            id: generateId(),
                            label: `${objectMapping.MasterLabel}: ${fieldMapping.Target_Field_Label}`,
                            required: false,
                            sectionId: sectionId,
                            defaultValue: null,
                            dataType: fieldMapping.Target_Field_Data_Type,
                            picklistOptions: fieldMapping.Target_Field_Picklist_Options,
                            dataImportFieldMappingDevNames: [fieldMapping.DeveloperName],
                            elementType: fieldMapping.Element_Type
                        }

                        this.handleAddFieldToSection(sectionId, formField);
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

        let formSections = mutable(this.formSections);
        let formSection = formSections.find(fs => fs.id === formSectionId);

        if (formSection.id === this.activeFormSectionId) {
            this.activeFormSectionId = undefined;
        }

        if (formSection.elements && formSection.elements.length > 0) {
            const formFields = formSection.elements;
            for (let i = 0; i < formFields.length; i++) {
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
    * gift fields from their respective sections.
    *
    * @param {object} event: Onchange event object from lightning-input checkbox
    */
    handleToggleFieldMapping(event) {
        const removeField = !event.target.checked;
        const fieldMappingDeveloperName = event.target.value;
        let sectionId = this.activeFormSectionId;

        if (removeField) {
            sectionId = this._sectionIdsByFieldMappingDeveloperNames[fieldMappingDeveloperName];
            dispatch(this, 'removefieldfromsection', {
                sectionId: sectionId,
                fieldName: fieldMappingDeveloperName
            });
        } else {
            if (!this.formSections || this.formSections.length === 0) {
                sectionId = this.handleAddSection();
            } else if (this.formSections.length === 1) {
                sectionId = this.formSections[0].id;
                this.activeFormSectionId = sectionId;
            } else if (this.activeFormSectionId === undefined && this.formSections.length > 1) {
                event.target.checked = false;
                return;
            }

            const fieldMapping = TemplateBuilderService.fieldMappingByDevName[fieldMappingDeveloperName];
            const objectMapping = TemplateBuilderService.objectMappingByDevName[fieldMapping.Target_Object_Mapping_Dev_Name];

            let formField;

            if (fieldMapping.Element_Type === 'field') {
                formField = {
                    id: generateId(),
                    label: `${objectMapping.MasterLabel}: ${fieldMapping.Target_Field_Label}`,
                    required: false,
                    sectionId: sectionId,
                    defaultValue: null,
                    dataType: fieldMapping.Target_Field_Data_Type,
                    picklistOptions: fieldMapping.Target_Field_Picklist_Options,
                    dataImportFieldMappingDevNames: [fieldMapping.DeveloperName],
                    elementType: fieldMapping.Element_Type
                }
            } else if (fieldMapping.Element_Type === 'widget') {
                formField = {
                    id: generateId(),
                    componentName: fieldMapping.DeveloperName,
                    label: fieldMapping.MasterLabel,
                    required: false,
                    sectionId: sectionId,
                    elementType: fieldMapping.Element_Type
                }
            }

            this.catalogSelectedField(fieldMappingDeveloperName, sectionId);
            this.formSections = this.handleAddFieldToSection(sectionId, formField);
        }
    }

    /*******************************************************************************
    * @description Maps the given field mapping developer name to the section id.
    * Used to later find and remove gift fields from their sections.
    *
    * @param {string} fieldMappingDeveloperName: Developer name of a Field Mapping
    * @param {string} sectionId: Id for a FormSection
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
    handleAddSection(label) {
        let newSection = {
            id: generateId(),
            displayType: 'accordion',
            defaultDisplayMode: 'expanded',
            displayRule: 'displayRule',
            label: label || 'New Section',
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
    handleAddFieldToSection(sectionId, field) {
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
    handleFormFieldUp(event) {
        dispatch(this, 'formfieldup', event.detail);
    }

    /*******************************************************************************
    * @description Receives event from child component and dispatches event to
    * parent to move the given FormField down within its parent FormSection.
    *
    * @param {object} event: Event object from child component.
    * component chain: geTemplateBuilderFormField -> geTemplateBuilderFormSection -> here
    */
    handleFormFieldDown(event) {
        dispatch(this, 'formfielddown', event.detail);
    }

    /*******************************************************************************
    * @description Receives event from child component and dispatches event to
    * parent to remove the FormField from its parent FormSection.
    *
    * @param {object} event: Event object from child component.
    * component chain: geTemplateBuilderFormField -> geTemplateBuilderFormSection -> here
    */
    handleDeleteFormField(event) {
        const element = this.template.querySelector(`lightning-input[data-field-mapping="${event.detail.fieldName}"]`);
        element.checked = false;

        dispatch(this, 'deleteformfield', event.detail);
    }

    /*******************************************************************************
    * @description Receives event from child component and dispatches event to
    * parent to update the details of the given FormField.
    *
    * @param {object} event: Event object from child component.
    * component chain: geTemplateBuilderFormField -> geTemplateBuilderFormSection -> here
    */
    handleUpdateFormField(event) {
        dispatch(this, 'updateformfield', event.detail);
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
        const lightningAccordion = this.template.querySelector(
            'lightning-accordion'
        );
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
    handleMinimizeAllSections() {
        const lightningAccordion = this.template.querySelector(
            'lightning-accordion'
        );
        lightningAccordion.activeSectionName = [];
        this.isAllSectionsExpanded = false;
    }
}