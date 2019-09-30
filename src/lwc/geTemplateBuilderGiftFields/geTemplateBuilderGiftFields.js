import { LightningElement, track } from 'lwc';
import getFieldMappingSets from '@salesforce/apex/GE_TemplateBuilderCtrl.getFieldMappingSetNames';
import getFieldAndObjectMappingsByFieldMappingSetName
    from '@salesforce/apex/GE_TemplateBuilderCtrl.getFieldAndObjectMappingsByFieldMappingSetName';
import { FormSection, FormField, showToast, findByProperty, shiftSelectedField, mutable } from 'c/utilTemplateBuilder';

export default class geTemplateBuilderGiftFields extends LightningElement {
    @track fieldMappingSetComboboxOptions;
    _fieldMappingSets;

    @track objectMappings;
    _fieldMappingsForSelectedSet = [];

    @track formSections = [];
    _activeFormSectionId;

    _selectedFieldMappings = {};

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
        //console.log('geTemplateBuilderGiftFields | init');
        this._fieldMappingSets = await getFieldMappingSets();
        this.fieldMappingSetComboboxOptions =
            this.getComboboxOptionsForFieldMappingSets(this._fieldMappingSets);

        /* for dev only, remove later. load the migrated custom field mapping set on init */
        getFieldAndObjectMappingsByFieldMappingSetName({ fieldMappingSetName: 'Migrated_Custom_Field_Mapping_Set' })
            .then(data => {
                console.log(data);
                this.objectMappings = mutable(data);
                for (const objectMapping of this.objectMappings) {
                    this._fieldMappingsForSelectedSet.push(...objectMapping.npsp__Data_Import_Field_Mappings__r);
                }
                console.log(this._fieldMappingsForSelectedSet);
            })
            .catch(error => {
                console.log('error:', error.body);
            })
        /* END */
    }

    /*******************************************************************************
    * @description Convert fieldMappingSets to usable picklist options for the
    * lightning-combobox component.
    *
    * @param {object} fieldMappingSets: List of field mapping sets.
    */
    getComboboxOptionsForFieldMappingSets(fieldMappingSets) {
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
    * lightning-combobox. Imperatively calls the apex method for getting field and
    * object mappings by the selected field mapping set and sets objectMappings and
    * _fieldMappingsForSelectedSet properties.
    *
    * @param {object} event: Onchange event from the lightning-combobox component.
    */
    handleChangeFieldMappingSet = async (event) => {
        //console.log('handleChangeFieldMappingSet');
        let selectedFieldMappingSet = event.target.value;
        //console.log(selectedFieldMappingSet);
        getFieldAndObjectMappingsByFieldMappingSetName({ fieldMappingSetName: selectedFieldMappingSet })
            .then(data => {
                console.log(data);
                this.objectMappings = mutable(data);
                for (const objectMapping of this.objectMappings) {
                    this._fieldMappingsForSelectedSet.push(...objectMapping.npsp__Data_Import_Field_Mappings__r);
                }
                console.log(this._fieldMappingsForSelectedSet);
            })
            .catch(error => {
                console.log('error:', error);
            })
        //console.log(JSON.parse(JSON.stringify(test)));
    }
    
    /*******************************************************************************
    * @description Handles the active section event from the child component
    * geTemplateBuilderFormLayout and sets the _activeFormSectionId property.
    *
    * @param {object} event: Event object containing the section id from the
    * geTemplateBuilderFormLayout component.
    */
    handleChangeActiveSection(event) {
        console.log('***handleChangeActiveSection');
        console.log('***************************');
        this._activeFormSectionId = event.detail;
    }

    /*******************************************************************************
    * @description Handles the active section event from the child component
    * geTemplateBuilderFormLayout and sets the _activeFormSectionId property.
    * This massive function definitely needs to broken up more.
    *
    * @param {object} event: Onchange event object from lightning-input checkbox
    */
    handleAddFieldMapping(event) {
        console.log('***handleAddFieldMapping');
        console.log('***************************');
        let removeField = !event.target.checked;
        let fieldMappingDeveloperName = event.target.getAttribute('data-field-mapping');

        if (removeField) {
            console.log('NEED TO REMOVE FIELD');
            let sectionId = this._selectedFieldMappings[fieldMappingDeveloperName];
            console.log('section id: ', sectionId);
            let section = this.formSections.find(fs => fs.id == sectionId);
            for (let i = 0; i < section.elements.length; i++) {
                if (section.elements[i].value === fieldMappingDeveloperName) {
                    section.elements.splice(i, 1);
                }
            }
        } else {
            //let objectMappingDeveloperName = event.target.getAttribute('data-object-mapping');

            console.log(fieldMappingDeveloperName);
            //console.log(objectMappingDeveloperName);

            let fieldMapping =
                this._fieldMappingsForSelectedSet
                    .find(fm => fm.DeveloperName === fieldMappingDeveloperName);

            let formField = new FormField(
                fieldMapping.MasterLabel,
                fieldMapping.npsp__Required__c,
                fieldMapping.DeveloperName,
                false,
                this._activeFormSectionId || 0
            );

            console.log('formField: ', formField);

            if (!this.formSections || this.formSections.length === 0) {
                console.log('new section');
                this.handleAddSection([formField]);

                /* Add selected field mapping to map of section ids by selected field mappings */
                this._selectedFieldMappings[formField.value] = 0;
            } else if (this.formSections.length === 1) {
                this._selectedFieldMappings[formField.value] = 0;
                this.formSections = this.handleAddFieldToSection(0, formField);
            } else if (!this._activeFormSectionId && this.formSections.length > 1) {
                event.target.checked = false;
                showToast(this, '', 'Please select a section', 'warning');
            } else {
                console.log('adding to existing section');
                this._selectedFieldMappings[formField.value] = this._activeFormSectionId;
                this.formSections = this.handleAddFieldToSection(this._activeFormSectionId, formField);
            }
        }
    }

    /*******************************************************************************
    * @description Handles adding a new section to the formSections list.
    *
    * @param {list} fieldMappings: List of FormFields to be added with the section
    */
    handleAddSection(fieldMappings) {
        console.log('***handleAddSection');
        console.log('***************************');

        if (!this.formSections) { this.formSections = [] }
        let formSections = JSON.parse(JSON.stringify(this.formSections));

        let newSection = new FormSection(
            formSections.length,
            'accordion',
            'expanded',
            'displayRule',
            'Test Label ' + formSections.length,
            Array.isArray(fieldMappings) ? [...fieldMappings] : []
        )

        formSections.push(newSection);
        this.formSections = formSections;
        console.log(this.formSections);
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
        let formSections = JSON.parse(JSON.stringify(this.formSections));
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
        console.log('FormSections', mutable(this.formSections));
    }
}