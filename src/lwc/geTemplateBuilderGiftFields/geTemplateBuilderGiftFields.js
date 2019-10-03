import { LightningElement, track, api } from 'lwc';
import getFieldMappingSets from '@salesforce/apex/GE_TemplateBuilderCtrl.getFieldMappingSetNames';
import getFieldAndObjectMappingsByFieldMappingSetName
    from '@salesforce/apex/GE_TemplateBuilderCtrl.getFieldAndObjectMappingsByFieldMappingSetName';
import { FormSection, FormField, showToast, removeByProperty, findByProperty, shiftSelectedField, mutable, generateId } from 'c/utilTemplateBuilder';

export default class geTemplateBuilderGiftFields extends LightningElement {
    @track isLoading = true;
    @track selectedFieldMappingSet;

    @api
    set selectedFieldMappingSet(selectedFieldMappingSet) {
        this.selectedFieldMappingSet = selectedFieldMappingSet;
    }

    @track fieldMappingSetComboboxOptions;
    _fieldMappingSets;

    @track objectMappings;
    _fieldMappingsForSelectedSet = [];

    @track formSections = [];

    /* Needs to be revisited, WIP tied to retrieving and rendering an existing template */
    @api
    set formSections(formSections) {
        this.formSections = formSections;
    }

    @track _activeFormSectionId;
    @track _sectionIdsByFieldMappingDeveloperNames = {};

    @api
    getTabData() {
        const formLayout = this.template.querySelector('c-ge-template-builder-form-layout');
        const formSections = formLayout.getFormLayout();
        return formSections;
    }

    /* placeholder function that handles the accordion component section toggle */
    handleSectionToggle(event) {
        const openSections = event.detail.openSections;

        if (openSections.length === 0) {
            console.log('All sections are closed');
        } else {
            console.log('Open sections: ' + openSections.join(', '));
        }
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

    connectedCallback() {
        //console.log('geTemplateBuilderGiftFields | connectedCallback');
        this.init();
    }

    /*******************************************************************************
    * @description Container function for grouping various async functions.
    */
    init = async () => {
        console.log('**********************************');
        console.log('geTemplateBuilderGiftFields | init');
        console.log('**********************************');
        this._fieldMappingSets = await getFieldMappingSets();
        this.fieldMappingSetComboboxOptions =
            await this.getComboboxOptionsForFieldMappingSets(this._fieldMappingSets);
        console.log('Field Mapping Set: ', this.selectedFieldMappingSet);

        if (this.selectedFieldMappingSet) {
            this.objectMappings = await getFieldAndObjectMappingsByFieldMappingSetName({
                fieldMappingSetName: this.selectedFieldMappingSet
            });
            this.setObjectAndFieldMappings(this.objectMappings);

            console.log('data: ', mutable(this.objectMappings));
            console.log('object and fields set');

            if (this.formSections) {
                console.log('_sectionIdsByFieldMappingDeveloperNames: ', mutable(this._sectionIdsByFieldMappingDeveloperNames));
                console.log('Form Sections: ', mutable(this.formSections));
                for (let i = 0; i < this.formSections.length; i++) {
                    const formSection = this.formSections[i];
                    formSection.elements.forEach(element => { this.addSelectedFieldToMap(element.value, formSection.id) });
                }
                console.log('_sectionIdsByFieldMappingDeveloperNames: ', mutable(this._sectionIdsByFieldMappingDeveloperNames));
                this.toggleCheckboxForSelectedFieldMappings(this.objectMappings);
            }
        }
        this.isLoading = false;
    }

    toggleCheckboxForSelectedFieldMappings(objectMappings) {
        console.log('=toggleCheckboxForSelectedFieldMappings');
        console.log('Object Mappings: ', objectMappings);
        const selectedFieldMappings = Object.keys(this._sectionIdsByFieldMappingDeveloperNames);
        console.log('Selected Field Mappings: ', selectedFieldMappings);
        if (selectedFieldMappings && selectedFieldMappings.length > 0) {
            console.log('before loop');
            for (let i = 0; i < objectMappings.length; i++) {
                let fieldMappingCheckboxes = objectMappings[i].fieldMappingCheckboxes;
                for (let ii = 0; ii < fieldMappingCheckboxes.length; ii++) {
                    let fieldMappingCheckbox = fieldMappingCheckboxes[ii];
                    console.log(fieldMappingCheckbox.value);
                    if (selectedFieldMappings.includes(fieldMappingCheckbox.value)) {
                        console.log('    FOund match!');
                        fieldMappingCheckbox.checked = true;
                    }
                }
            }
            console.log('Object Mappings: ', objectMappings);
            this.objectMappings = objectMappings;
        }
    }

    /*******************************************************************************
    * @description Convert fieldMappingSets to usable picklist options for the
    * lightning-combobox component.
    *
    * @param {object} fieldMappingSets: List of field mapping sets.
    */
    getComboboxOptionsForFieldMappingSets = async (fieldMappingSets) => {
        console.log('**************************************');
        console.log('=getComboboxOptionsForFieldMappingSets');
        console.log('**************************************');
        let options = [];

        fieldMappingSets.forEach(fieldMappingSet => {
            //console.log(JSON.parse(JSON.stringify(fieldMappingSet)));
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
    * @description Imperatively calls the apex method for getting field and
    * object mappings by the selected field mapping set. Sets properties objectMappings 
    * and _fieldMappingsForSelectedSet.
    *
    * @param {string} fieldMappingSetDeveloperName: Developer Name of Field Mapping Set
    */
    setObjectAndFieldMappings(objectMappings) {
        this.objectMappings = mutable(objectMappings);
        for (const objectMapping of this.objectMappings) {
            this._fieldMappingsForSelectedSet.push(...objectMapping.fieldMappingCheckboxes);
        }
    }

    handleDeleteFormSection(event) {
        console.log('handleDeleteFormSection');
        console.log(event.detail);
        const formSection = event.detail;

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
        console.log('***handleChangeActiveSection | GiftFields');
        console.log('***************************');
        console.log('Section Id: ', event.detail);
        this._activeFormSectionId = event.detail;
        console.log('Active Section Id: ', this._activeFormSectionId);
    }

    /*******************************************************************************
    * @description Handles the active section event from the child component
    * geTemplateBuilderFormLayout and sets the _activeFormSectionId property.
    * This massive function definitely needs to broken up more.
    *
    * @param {object} event: Onchange event object from lightning-input checkbox
    */
    handleToggleFieldMapping(event) {
        console.log('***handleToggleFieldMapping');
        console.log('***************************');
        const removeField = !event.target.checked;
        const fieldMappingDeveloperName = event.target.value;
        let sectionId = this._activeFormSectionId;

        if (removeField) {
            console.log('attempting to remove field');
            const sectionId = this._sectionIdsByFieldMappingDeveloperNames[fieldMappingDeveloperName];
            console.log('Section Id: ', sectionId);
            let section = this.formSections.find(fs => fs.id == sectionId);
            console.log('Section: ', section);
            removeByProperty(section.elements, 'value', fieldMappingDeveloperName);
        } else {
            console.log('attempting to add field');
            const fieldMapping =
                this._fieldMappingsForSelectedSet.find(fm => fm.value === fieldMappingDeveloperName);

            let formField = new FormField(
                fieldMapping.label,
                false,
                fieldMapping.value,
                false,
                sectionId
            );

            if (!this.formSections || this.formSections.length === 0) {
                sectionId = this.handleAddSection();
            } else if (this.formSections.length === 1) {
                sectionId = this.formSections[0].id;
            } else if (this._activeFormSectionId === undefined && this.formSections.length > 1) {
                event.target.checked = false;
                showToast(this, '', 'Please select a section', 'warning');
                return;
            }

            this.addSelectedFieldToMap(fieldMappingDeveloperName, sectionId);
            this.formSections = this.handleAddFieldToSection(sectionId, formField);
        }
    }

    addSelectedFieldToMap(fieldMappingDeveloperName, sectionId) {
        this._sectionIdsByFieldMappingDeveloperNames[fieldMappingDeveloperName] = sectionId;
    }

    /*******************************************************************************
    * @description Handles adding a new section to the formSections list.
    *
    * @param {list} fieldMappings: List of FormFields to be added with the section
    */
    handleAddSection() {
        console.log('***handleAddSection');
        console.log('***************************');

        if (!this.formSections) { this.formSections = [] }

        let formSections = mutable(this.formSections);

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
        console.log(this.formSections);
        return newSection.id;
    }

    /*******************************************************************************
    * @description Handles adding a new FormField to a FormSection.
    *
    * @param {string} sectionId: Id of the FormSection
    * @param {object} field: Instance of FormField to be added
    */
    handleAddFieldToSection(sectionId, field) {
        console.log('***handleAddFieldToSection');
        console.log('***************************');
        console.log(arguments);
        let formSections = mutable(this.formSections);
        let formSection = formSections.find(fs => fs.id == sectionId);
        console.log('Form Section: ', formSection);
        formSection.elements.push(field);

        return formSections;
    }

    /*******************************************************************************
    * @description Handles shifting the FormField element up in the list and UI
    *
    * @param {object} event: Onclick event object from lightning-button
    */
    handleFormFieldUp(event) {
        try {
            console.log('***handleFormFieldUp');
            console.log('********************');
            console.log(event.detail);
            let section = this.formSections.find(fs => fs.id == event.detail.sectionId);
            const oldIndex = findByProperty(section.elements, 'value', event.detail.value);
            if (oldIndex > 0) {
                shiftSelectedField(section.elements, oldIndex, oldIndex - 1);
            }
            console.log('section: ', section);
        } catch (error) {
            console.log(error);
        }
    }

    /*******************************************************************************
    * @description Handles shifting the FormField element down in the list and UI
    *
    * @param {object} event: Onclick event object from lightning-button
    */
    handleFormFieldDown(event) {
        const section = this.formSections.find(fs => fs.id == event.detail.sectionId);
        const oldIndex = findByProperty(section.elements, 'value', event.detail.value);
        if (oldIndex < section.elements.length - 1) {
            shiftSelectedField(section.elements, oldIndex, oldIndex + 1);
        }
        console.log('Section: ', section);
    }

    /*******************************************************************************
    * @description Handles shifting the FormSection element up in the list and UI
    *
    * @param {object} event: Onclick event object from lightning-button
    */
    handleFormSectionUp(event) {
        let sectionId = event.detail;
        const oldIndex = findByProperty(this.formSections, 'id', sectionId);
        if (oldIndex > 0) {
            shiftSelectedField(this.formSections, oldIndex, oldIndex - 1);
        }
    }

    /*******************************************************************************
    * @description Handles shifting the FormSection element down in the list and UI
    *
    * @param {object} event: Onclick event object from lightning-button
    */
    handleFormSectionDown(event) {
        let sectionId = event.detail;
        const oldIndex = findByProperty(this.formSections, 'id', sectionId);
        if (oldIndex < this.formSections.length - 1) {
            shiftSelectedField(this.formSections, oldIndex, oldIndex + 1);
        }
    }

    /* For dev, remove later */
    logFormSections() {
        console.log('***logFormSections');
        console.log('***************************');
        let formLayout = this.template.querySelector('c-ge-template-builder-form-layout');
        let formSections = formLayout.getFormLayout();
        console.log('FormSections', mutable(formSections));
    }
}