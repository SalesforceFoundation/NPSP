import { LightningElement, track, api } from 'lwc';
import getFieldMappingSets from '@salesforce/apex/GE_TemplateBuilderCtrl.getFieldMappingSetNames';
import getFieldAndObjectMappingsByFieldMappingSetName
    from '@salesforce/apex/GE_TemplateBuilderCtrl.getFieldAndObjectMappingsByFieldMappingSetName';
import { FormSection, FormField, showToast, removeByProperty, findIndexByProperty, shiftToIndex, mutable, generateId } from 'c/utilTemplateBuilder';

export default class geTemplateBuilderGiftFields extends LightningElement {
    @track isLoading = true;
    @track selectedFieldMappingSet;

    /* Public setter for the tracked property selectedFieldMappingSet
    // TODO: Needs to be revisited, WIP tied to retrieving and rendering an existing template */
    @api
    set selectedFieldMappingSet(selectedFieldMappingSet) {
        this.selectedFieldMappingSet = selectedFieldMappingSet;
    }

    @track formSections = [];
    /* Public setter for the tracked property formSections
    // TODO: Needs to be revisited, WIP tied to retrieving and rendering an existing template */
    @api
    set formSections(formSections) {
        this.formSections = formSections;
    }

    @track _activeFormSectionId;
    @track _sectionIdsByFieldMappingDeveloperNames = {};
    @track fieldMappingSetComboboxOptions;
    _fieldMappingSets;
    @track objectMappings;
    _fieldMappingsForSelectedSet = [];

    @api
    getTabData() {
        const formLayoutComponent = this.template.querySelector('c-ge-template-builder-form-layout');
        const formLayout = formLayoutComponent.getFormLayout();
        return formLayout;
    }

    connectedCallback() {
        this.init();
    }

    /*******************************************************************************
    * @description Container function for grouping various async functions.
    */
    init = async () => {
        this._fieldMappingSets = await getFieldMappingSets();
        this.fieldMappingSetComboboxOptions = await this.getComboboxOptionsForFieldMappingSets(this._fieldMappingSets);

        // TODO: Need to finish or scrap lines between START and END comments
        /* START */
        /* tbd on this retrieve stuff :) */
        // This section between START and END are directly tied to the button "Test Retrieve Form Template"
        const weAreRetrievingAnExistingTemplate = this.selectedFieldMappingSet;

        if (weAreRetrievingAnExistingTemplate) {
            this.objectMappings = await getFieldAndObjectMappingsByFieldMappingSetName({
                fieldMappingSetName: this.selectedFieldMappingSet
            });
            this.setObjectAndFieldMappings(this.objectMappings);

            if (this.formSections) {
                for (let i = 0; i < this.formSections.length; i++) {
                    const formSection = this.formSections[i];
                    formSection.elements.forEach(element => { this.catalogSelectedField(element.value, formSection.id) });
                }
                this.toggleCheckboxForSelectedFieldMappings(this.objectMappings);
            }
        }
        /* END */

        this.isLoading = false;
    }

    /*******************************************************************************
    * @description Sends an event up to geTemplateBuilder for tab navigation
    *
    * @param {object} event: Onclick event object from lightning-button.
    */
    handleGoToTab(event) {
        let detail = {
            tabValue: event.target.getAttribute('data-tab-value')
        }
        this.dispatchEvent(new CustomEvent('gototab', { detail: detail }));
    }

    /*******************************************************************************
    * @description Convert fieldMappingSets to usable picklist options for the
    * lightning-combobox component.
    *
    * @param {object} fieldMappingSets: List of field mapping sets.
    */
    getComboboxOptionsForFieldMappingSets = async (fieldMappingSets) => {
        let options = [];

        fieldMappingSets.forEach(fieldMappingSet => {
            let option = {
                label: fieldMappingSet.MasterLabel,
                value: fieldMappingSet.DeveloperName
            }
            options.push(option);
        });

        return options;
    }

    /*******************************************************************************
    * @description Handles the onchange event for the field mapping set 
    * lightning-combobox.
    *
    * @param {object} event: Onchange event from the lightning-combobox component.
    */
    handleChangeFieldMappingSet = async (event) => {
        this.isLoading = true;
        this.selectedFieldMappingSet = event.target.value;
        this.objectMappings = await getFieldAndObjectMappingsByFieldMappingSetName({
            fieldMappingSetName: this.selectedFieldMappingSet
        });
        this.setObjectAndFieldMappings(this.objectMappings);
        this.isLoading = false;
    }

    /*******************************************************************************
    * @description Takes object mapping wrappers and sets them to a mutable property.
    * Sets a flat array of field mapping checkboxes from each object mapping wrapper's
    * field mapping checkboxes. Planning on using this later to easily grab field related
    * data like type. Also considering just populating a data attribute in the
    * checkbox element itself and forego having another property to this component.
    *
    * @param {list} objectMappings: List of Object Mapping Wrappers
    */
    setObjectAndFieldMappings(objectMappings) {
        this.objectMappings = mutable(objectMappings);
        for (const objectMapping of this.objectMappings) {
            this._fieldMappingsForSelectedSet.push(...objectMapping.fieldMappingCheckboxes);
        }
    }

    /*******************************************************************************
    * @description Removes a section and unchecks checkboxes for all the gift fields
    * contained in this section
    *
    * @param {object} event: Onclick event object from lightning-button-icon
    */
    handleDeleteFormSection(event) {
        this.formSections = event.detail.formSections;

        const formSection = event.detail.formSection;
        if (formSection.id == this._activeFormSectionId) {
            this._activeFormSectionId = undefined;
        }

        if (formSection.elements && formSection.elements.length > 0) {
            const formFields = formSection.elements;
            for (let i = 0; i < formFields.length; i++) {
                let checkbox =
                    this.template.querySelector(`lightning-input[data-field-mapping="${formFields[i].value}"]`);
                checkbox.checked = false;
            }
        }
    }

    /*******************************************************************************
    * @description Handles the active section event from the child component
    * geTemplateBuilderFormLayout and sets the _activeFormSectionId property.
    *
    * @param {object} event: Event object containing the section id from the
    * geTemplateBuilderFormLayout component.
    */
    handleChangeActiveSection(event) {
        this._activeFormSectionId = event.detail;
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
        let sectionId = this._activeFormSectionId;

        if (removeField) {
            sectionId = this._sectionIdsByFieldMappingDeveloperNames[fieldMappingDeveloperName];
            let section = this.formSections.find(fs => fs.id == sectionId);
            removeByProperty(section.elements, 'value', fieldMappingDeveloperName);
        } else {
            const fieldMapping =
                this._fieldMappingsForSelectedSet.find(fm => fm.value === fieldMappingDeveloperName);

            let formField = new FormField(
                fieldMapping.label,
                false,
                fieldMapping.value,
                false,
                sectionId,
                undefined,
                fieldMapping.dataType,
                fieldMapping.picklistOptions
            )

            if (!this.formSections || this.formSections.length === 0) {
                sectionId = this.handleAddSection();
            } else if (this.formSections.length === 1) {
                sectionId = this.formSections[0].id;
            } else if (this._activeFormSectionId === undefined && this.formSections.length > 1) {
                event.target.checked = false;
                showToast(this, '', 'Please select a section', 'warning');
                return;
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
    * @description Handles adding a new section to the formSections list.
    *
    * @param {list} fieldMappings: List of FormFields to be added with the section
    */
    handleAddSection() {
        if (!this.formSections) { this.formSections = [] }
        let formLayout = this.getTabData();
        let formSections = formLayout.sections.length > 0 ? mutable(formLayout.sections) : mutable(this.formSections);

        let newSection = new FormSection(
            generateId(),
            'accordion',
            'expanded',
            'displayRule',
            'Test Label ' + formSections.length,
            []
        )

        formSections.push(newSection);
        this.formSections = formSections;
        return newSection.id;
    }

    /*******************************************************************************
    * @description Handles adding a new FormField to a FormSection.
    *
    * @param {string} sectionId: Id of the FormSection
    * @param {object} field: Instance of FormField to be added
    */
    handleAddFieldToSection(sectionId, field) {
        field.sectionId = sectionId;
        let formLayout = this.getTabData();
        let formSections = formLayout.sections.length > 0 ? mutable(formLayout.sections) : mutable(this.formSections);
        let formSection = formSections.find(fs => fs.id == sectionId);

        formSection.elements.push(field);

        return formSections;
    }

    /*******************************************************************************
    * @description Handles shifting the FormField element up in the list and UI
    *
    * @param {object} event: Onclick event object from lightning-button
    */
    handleFormFieldUp(event) {
        const section = this.formSections.find(fs => fs.id == event.detail.sectionId);
        const oldIndex = findIndexByProperty(section.elements, 'value', event.detail.value);
        if (oldIndex > 0) {
            shiftToIndex(section.elements, oldIndex, oldIndex - 1);
        }
    }

    /*******************************************************************************
    * @description Handles shifting the FormField element down in the list and UI
    *
    * @param {object} event: Onclick event object from lightning-button
    */
    handleFormFieldDown(event) {
        const section = this.formSections.find(fs => fs.id == event.detail.sectionId);
        const oldIndex = findIndexByProperty(section.elements, 'value', event.detail.value);
        if (oldIndex < section.elements.length - 1) {
            shiftToIndex(section.elements, oldIndex, oldIndex + 1);
        }
    }

    /*******************************************************************************
    * @description Handles shifting the FormSection element up in the list and UI
    *
    * @param {object} event: Onclick event object from lightning-button
    */
    handleFormSectionUp(event) {
        let sectionId = event.detail;
        const oldIndex = findIndexByProperty(this.formSections, 'id', sectionId);
        if (oldIndex > 0) {
            shiftToIndex(this.formSections, oldIndex, oldIndex - 1);
        }
    }

    /*******************************************************************************
    * @description Handles shifting the FormSection element down in the list and UI
    *
    * @param {object} event: Onclick event object from lightning-button
    */
    handleFormSectionDown(event) {
        let sectionId = event.detail;
        const oldIndex = findIndexByProperty(this.formSections, 'id', sectionId);
        if (oldIndex < this.formSections.length - 1) {
            shiftToIndex(this.formSections, oldIndex, oldIndex + 1);
        }
    }

    // TODO: Need to finish or scrap the incomplete function below
    /*******************************************************************************
    * @description Function toggles the checkboxes for any existing/selected gift
    * fields. Used when retrieving an existing form template.
    */
    toggleCheckboxForSelectedFieldMappings(objectMappings) {
        const selectedFieldMappings = Object.keys(this._sectionIdsByFieldMappingDeveloperNames);
        if (selectedFieldMappings && selectedFieldMappings.length > 0) {
            for (let i = 0; i < objectMappings.length; i++) {
                let fieldMappingCheckboxes = objectMappings[i].fieldMappingCheckboxes;
                for (let ii = 0; ii < fieldMappingCheckboxes.length; ii++) {
                    let fieldMappingCheckbox = fieldMappingCheckboxes[ii];
                    if (selectedFieldMappings.includes(fieldMappingCheckbox.value)) {
                        fieldMappingCheckbox.checked = true;
                    }
                }
            }
            this.objectMappings = objectMappings;
        }
    }

    // TODO: Need to finish or scrap the incomplete function below.
    // Potentially not needed.
    handleSectionToggle(event) {
        const openSections = event.detail.openSections;

        if (openSections.length === 0) {
            //console.log('All sections are closed');
        } else {
            //console.log('Open sections: ' + openSections.join(', '));
        }
    }

    // TODO: Used for dev. Delete later.
    logFormSections() {
        //console.log('***logFormSections');
        //console.log('***************************');
        let formLayout = this.template.querySelector('c-ge-template-builder-form-layout');
        let formSections = formLayout.getFormLayout();
        //console.log('FormSections', mutable(formSections));
    }
}