import { LightningElement, track, api } from 'lwc';
//import getFieldMappingSets from '@salesforce/apex/GE_TemplateBuilderCtrl.getFieldMappingSetNames';
import getFieldAndObjectMappingsByFieldMappingSetName
    from '@salesforce/apex/GE_TemplateBuilderCtrl.getFieldAndObjectMappingsByFieldMappingSetName';
import { findIndexByProperty, mutable, generateId, dispatch } from 'c/utilTemplateBuilder';

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
    _fieldMappingsForSelectedSet = [];
    objectMappingNames = [];
    @track isAllSectionsExpanded = false;

    @api
    getSections() {
        const formSectionComponents = this.template.querySelectorAll('c-ge-template-builder-form-section');
        let formSections = [];
        for (let i = 0; i < formSectionComponents.length; i++) {
            let formSection = formSectionComponents[i].getFormSectionValues();
            formSections.push(formSection);
        }

        return formSections;
    }

    toggleModal(event) {
        dispatch(this, 'togglemodal', event.detail);
    }

    connectedCallback() {
        this.init();
    }

    init = async () => {
        this.objectMappings = await this.handleGetFieldAndObjectMappings(this.selectedFieldMappingSet);
        this.handleSortFieldMappings();
        this.loadObjectAndFieldMappingSets();
        this.isLoading = false;
    }

    /*******************************************************************************
    * @description Intermediary async method for getting the object and field mappings
    * based on the selected field mapping set.
    */
    handleGetFieldAndObjectMappings = async (selectedFieldMappingSet) => {
        return getFieldAndObjectMappingsByFieldMappingSetName({ fieldMappingSetName: selectedFieldMappingSet });
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
    * @description Method determines whether or not we're pulling an existing
    * template, populates the UI with the appropriate object and field mappings,
    * and toggles field mapping checkboxes.
    */
    loadObjectAndFieldMappingSets() {
        const isExistingTemplate = this.selectedFieldMappingSet;

        if (isExistingTemplate) {
            this.setObjectAndFieldMappings(this.objectMappings);

            if (this.formSections) {
                if (this.formSections.length === 1) {
                    this.handleChangeActiveSection({ detail: this.formSections[0].id });
                }
                for (let i = 0; i < this.formSections.length; i++) {
                    const formSection = this.formSections[i];
                    formSection.elements.forEach(element => {
                        this.catalogSelectedField(element.dataImportFieldMappingDevNames[0], formSection.id)
                    });
                }
                this.toggleCheckboxForSelectedFieldMappings(this.objectMappings);
            }
        } else {
            this.setObjectAndFieldMappings(this.objectMappings);
        }
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
            this.objectMappingNames.push(objectMapping.DeveloperName);
            this._fieldMappingsForSelectedSet.push(...objectMapping.Field_Mappings);
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
                let checkbox =
                    this.template.querySelector(`lightning-input[data-field-mapping="${formFields[i].dataImportFieldMappingDevNames[0]}"]`);
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

            const fieldMapping =
                this._fieldMappingsForSelectedSet.find(fm => fm.DeveloperName === fieldMappingDeveloperName);
            const objectMapping =
                this.objectMappings.find(om => om.DeveloperName === fieldMapping.Target_Object_Mapping_Dev_Name);

            let formField = {
                id: generateId(),
                label: `${objectMapping.MasterLabel}: ${fieldMapping.Target_Field_Label}`,
                required: false,
                sectionId: sectionId,
                defaultValue: null,
                dataType: fieldMapping.Target_Field_Data_Type,
                picklistOptions: fieldMapping.Target_Field_Picklist_Options,
                dataImportFieldMappingDevNames: [fieldMapping.DeveloperName]
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
    handleAddSection() {
        let newSection = {
            id: generateId(),
            displayType: 'accordion',
            defaultDisplayMode: 'expanded',
            displayRule: 'displayRule',
            label: 'New Section',
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