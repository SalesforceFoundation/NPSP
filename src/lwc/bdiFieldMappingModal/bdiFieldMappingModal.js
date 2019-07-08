import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsubNoPageRef';
import createDataImportFieldMapping
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.createDataImportFieldMapping';

export default class bdiFieldMappingModal extends LightningElement {

    @api diFieldDescribes;
    @api targetObjectFieldDescribes;
    @api objectMapping
    @api isModalOpen;
    @api isSearchOpen;

    @track isLoading;
    @track row;
    @track searchKey = '';
    @track diKeys;
    @track searchResults;
    @track areSearchResultsVisible = false;

    // Combobox vars
    @track selectedSourceFieldLabel;
    @track sourceFieldLabelOptions;
    @track selectedSourceFieldAPIName;
    @track sourceFieldAPINameOptions;
    @track selectedSourceFieldDisplayType;

    @track selectedTargetFieldLabel;
    @track targetFieldLabelOptions;
    @track selectedTargetFieldAPIName;
    @track targetFieldAPINameOptions;

    // This is kinda dumb, but there's no way to get the label from the selected option in the combobox
    // via the onchange event handler. As far as I can tell?
    @api diFieldsByLabel;
    @api diFieldsByAPIName;

    @api targetObjectFieldsByLabel;
    @api targetObjectFieldsByAPIName;

    // Map of field lists by Display Type
    @api targetFieldsByLabelByDisplayType;
    @api targetFieldsByAPINameByDisplayType;

    @track mappedDIFieldLabels = [];
    @track mappedTargetFieldLabels = [];

    // Map of Display Types
    validTargetTypesBySourceType = {
        "ID": ["ID", "STRING"],
        "REFERENCE": ["REFERENCE", "STRING"],
        "PHONE": ["PHONE", "STRING"],
        "TEXTAREA": ["TEXTAREA", "STRING"],
        "URL": ["URL", "STRING"],
        "EMAIL": ["EMAIL", "STRING"],
        "BOOLEAN": ["BOOLEAN"],
        "STRING": ["STRING", "PICKLIST"],
        "DATETIME": ["DATETIME"],
        "DATE": ["DATE"],
        "PICKLIST": ["PICKLIST"], // TODO: Include sometimes Boolean as per the BDI Mapping Field Types dc
        "CURRENCY": ["CURRENCY"],
        "PERCENT": ["PERCENT"]
    };

    get isTargetFieldDisabled() {
        if ((this.selectedSourceFieldAPIName || this.selectedSourceFieldLabel) &&
            (this.targetFieldLabelOptions && this.targetFieldLabelOptions.length > 0)) {
            return false;
        }
        return true;
    }

    constructor() {
        super();
        this.escapeFunction = this.escapeFunction.bind(this);
    }

    connectedCallback() {
        document.addEventListener("keydown", this.escapeFunction, false);
        registerListener('openModal', this.handleOpenModal, this);
        registerListener('closeModal', this.handleCloseModal, this);

        // Register listeners for child searchable combobox components
        registerListener('sourceFieldLabelChange', this.handleSourceFieldLabelChange, this);
        registerListener('sourceFieldAPINameChange', this.handleSourceFieldAPINameChange, this);
        registerListener('targetFieldLabelChange', this.handleTargetFieldLabelChange, this);
        registerListener('targetFieldAPINameChange', this.handleTargetFieldAPINameChange, this);
    }

    disconnectedCallback() {
        document.removeEventListener("keydown", this.escapeFunction, false);
        unregisterAllListeners(this);
    }

    /*******************************************************************************
    * @description Handles the open modal event from bdiFieldMappings
    *
    * @param event: Event containing row details or lack of row details
    */
    handleOpenModal(event) {
        this.isModalOpen = true;
        this.isLoading = true;
        this.objectMapping = event.objectMapping;

        this.collectMappedDataImportFields(event.fieldMappings);

        this.row = event.row;

        if (this.row) {
            // Edit row
            this.selectedSourceFieldLabel = this.row.xxx_Source_Field_Label_xxx;
            this.selectedSourceFieldAPIName = this.row.xxx_Source_Field_API_Name_xxx;
            this.selectedTargetFieldAPIName = this.row.xxx_Target_Field_API_Name_xxx;
            this.selectedTargetFieldLabel = this.row.xxx_Target_Field_Label_xxx;
            this.selectedSourceFieldDisplayType = this.row.xxx_Source_Field_Data_Type_xxx;
        } else {
            // New row
            this.clearSelections();
        }

        this.setDataImportFieldDescribes(this.diFieldDescribes);
        this.setTargetObjectFieldDescribes(this.targetObjectFieldDescribes);

        this.isLoading = false
    }

    /*******************************************************************************
    * @description Loops through and collects the source field label and target field
    * labels of existing field mappings for the currently selected object mapping
    *
    * @param {array} fieldMappings: List of field mappings from bdiFieldMappings
    */
    collectMappedDataImportFields(fieldMappings) {
        for (let i = 0; i < fieldMappings.length; i++) {
            let fieldMapping = fieldMappings[i];

            this.mappedDIFieldLabels.push(fieldMapping.xxx_Source_Field_Label_xxx);
            this.mappedTargetFieldLabels.push(fieldMapping.xxx_Target_Field_Label_xxx);
        }
    }

    /*******************************************************************************
    * @description Creates a map of data import field labels by field API name and a
    * map of data import field API names by field label.
    *
    * @param {array} data: List of data import field describes
    */
    setDataImportFieldDescribes(data) {
        this.sourceFieldLabelOptions = [];
        this.sourceFieldAPINameOptions = [];
        let diFieldsByLabel = {};
        let diFieldsByAPIName = {};

        for (let i = 0; i < data.length; i++) {

            // Skip any di fields that have already been mapped in this object
            if (!this.mappedDIFieldLabels.includes(data[i].label) ||
                this.selectedSourceFieldLabel === data[i].label) {
                let labelOption = {
                    label: data[i].label,
                    value: data[i].value
                }
                let apiNameOption = {
                    label: data[i].value,
                    value: data[i].label
                };

                this.sourceFieldLabelOptions.push(labelOption);
                this.sourceFieldAPINameOptions.push(apiNameOption);

                diFieldsByLabel[labelOption.label] = this.parse(data[i]);
                diFieldsByAPIName[labelOption.value] = this.parse(data[i]);
            }
        }

        this.diFieldsByLabel = diFieldsByLabel;
        this.diFieldsByAPIName = diFieldsByAPIName;
    }

    /*******************************************************************************
    * @description Creates a map of target object field labels by field API name and a
    * map of target object field API names by field label.
    *
    * @param {array} data: List of target object field describes
    */
    setTargetObjectFieldDescribes(data) {
        this.targetFieldLabelOptions = [];
        this.targetFieldAPINameOptions = [];
        let targetObjectFieldsByLabel = {}, targetObjectFieldsByAPIName = {};
        let fieldByLabelByDisplayType = {}, fieldByAPINameByDisplayType = {};
        let selectedTargetFieldLabel = this.selectedTargetFieldLabel
        let selectedTargetFieldAPIName = this.selectedTargetFieldAPIName;

        for (let i = 0; i < data.length; i++) {

            // Skip any mapped target fields
            if (!this.mappedTargetFieldLabels.includes(data[i].label)  ||
                this.selectedTargetFieldLabel === data[i].label) {

                let labelOption = {
                    label: data[i].label,
                    value: data[i].value
                }
                let apiNameOption = {
                    label: data[i].value,
                    value: data[i].label
                };

                this.targetFieldLabelOptions.push(labelOption);
                if (fieldByLabelByDisplayType[data[i].displayType]) {
                    fieldByLabelByDisplayType[data[i].displayType].push(labelOption);
                } else {
                    fieldByLabelByDisplayType[data[i].displayType] = [labelOption];
                }

                this.targetFieldAPINameOptions.push(apiNameOption);
                if (fieldByAPINameByDisplayType[data[i].displayType]) {
                    fieldByAPINameByDisplayType[data[i].displayType].push(apiNameOption);
                } else {
                    fieldByAPINameByDisplayType[data[i].displayType] = [apiNameOption];
                }

                targetObjectFieldsByLabel[labelOption.label] = labelOption.value;
                targetObjectFieldsByAPIName[labelOption.value] = labelOption.label;
            }
        }

        this.targetObjectFieldsByLabel = targetObjectFieldsByLabel;
        this.targetObjectFieldsByAPIName = targetObjectFieldsByAPIName;

        this.targetFieldsByLabelByDisplayType = fieldByLabelByDisplayType;
        this.targetFieldsByAPINameByDisplayType = fieldByAPINameByDisplayType;

        if (this.selectedSourceFieldDisplayType) {
            this.handleAvailableTargetFieldsBySourceFieldDisplayType(this.selectedSourceFieldDisplayType);
        }

        this.selectedTargetFieldLabel = selectedTargetFieldLabel;
        this.selectedTargetFieldAPIName = selectedTargetFieldAPIName;
    }

    /*******************************************************************************
    * @description Clears out all the various "selected" properties
    */
    clearSelections() {
        this.selectedSourceFieldLabel = undefined;
        this.selectedSourceFieldAPIName = undefined;
        this.selectedTargetFieldLabel = undefined;
        this.selectedTargetFieldAPIName = undefined;
    }

    /*******************************************************************************
    * @description Handles the close modal event from bdiFieldMappings
    */
    handleCloseModal() {
        this.isModalOpen = false;
    }

    /*******************************************************************************
    * @description Handles escape key press and closes the modal
    */
    escapeFunction(event) {
        if (event.keyCode === 27) {
            this.handleCloseModal();
        }
    }

    /*******************************************************************************
    * @description Handles the creation or update of a row based on the existence of
    * the row property. If the row property exists, we only set the source and target
    * field API name, otherwise we set all the fields. Calls the handleDeploymentId
    * function on receiving an id back from createDataImportFieldMapping.
    */
    handleSave() {
        this.isLoading = true;
        let rowDetails;

        if (this.row) {
            // Set source and target fields
            this.row.xxx_Source_Field_API_Name_xxx = this.selectedSourceFieldAPIName;
            this.row.xxx_Target_Field_API_Name_xxx = this.selectedTargetFieldAPIName;
            rowDetails = JSON.stringify(this.row);
        } else {
            // New Field Mapping
            rowDetails = JSON.stringify({
                DeveloperName: null,
                Label: this.selectedSourceFieldLabel,
                MasterLabel: this.selectedSourceFieldLabel,
                xxx_Data_Import_Field_Mapping_Set_xxx: 'Migrated_Custom_Field_Mapping_Set',
                xxx_Is_Deleted_xxx: false,
                xxx_Required_xxx: 'No',
                xxx_Source_Field_API_Name_xxx: this.selectedSourceFieldAPIName,
                xxx_Target_Field_API_Name_xxx: this.selectedTargetFieldAPIName,
                xxx_Target_Object_Mapping_xxx: this.objectMapping.DeveloperName
            });
        }

        createDataImportFieldMapping({fieldMappingString: rowDetails})
            .then((deploymentId) => {
                this.handleDeploymentId(deploymentId);
            })
            .catch((error) => {
                this.isLoading = false;
                if (error && error.body) {
                    this.showToast(
                        'Error',
                        '{0}. {1}. {2}.',
                        'error',
                        'sticky',
                        [error.body.exceptionType, error.body.message, error.body.stackTrace]);
                }
            });
    }

    /*******************************************************************************
    * @description Creates and dispatches a CustomEvent 'deployment' letting the
    * platformEventListener know that we have an id to register and monitor. After
    * dispatching the CustomEvent, start the deployment timeout on bdiFieldMappings.
    *
    * @param {string} deploymentId: Custom Metadata Deployment Id
    */
    handleDeploymentId(deploymentId) {
        const deploymentEvent = new CustomEvent('deployment', {
            bubbles: true,
            composed: true,
            detail: {deploymentId}
        });
        this.dispatchEvent(deploymentEvent);

        fireEvent(this.pageRef, 'startDeploymentTimeout', { deploymentId: deploymentId });
    }

    /*******************************************************************************
    * @description Handles the onchange event for the bdiFieldMappingModalComboboxSearch
    * sourceFieldLabel, sets the value for both sourceFieldLabel and sourceFieldAPIName,
    * and updates the available target fields based on the selected source field's display
    * type.
    *
    * @param {object} event: Event containing combobox selection details
    */
    handleSourceFieldLabelChange(event) {
        let fieldAPIName = event.detail.value;
        let fieldInfo = this.diFieldsByAPIName[fieldAPIName];

        this.selectedSourceFieldAPIName = fieldAPIName;
        this.selectedSourceFieldLabel = fieldInfo.label;

        this.handleAvailableTargetFieldsBySourceFieldDisplayType(fieldInfo.displayType);
    }

    /*******************************************************************************
    * @description Handles the onchange event for the bdiFieldMappingModalComboboxSearch
    * sourceFieldAPIName, sets the value for both sourceFieldAPIName and sourceFieldLabel,
    * and updates the available target fields based on the selected source field's display
    * type.
    *
    * @param {object} event: Event containing combobox selection details
    */
    handleSourceFieldAPINameChange(event) {
        let fieldLabel = event.detail.value;
        let fieldInfo = this.diFieldsByLabel[fieldLabel];

        this.selectedSourceFieldLabel = fieldLabel;
        this.selectedSourceFieldAPIName = fieldInfo.value;

        this.handleAvailableTargetFieldsBySourceFieldDisplayType(fieldInfo.displayType);
    }

    /*******************************************************************************
    * @description Filters the available target fields based on display type
    *
    * @param {string} displayType: Display Type of the currently selected source field
    */
    handleAvailableTargetFieldsBySourceFieldDisplayType(displayType) {
        this.selectedTargetFieldAPIName = undefined;
        this.selectedTargetFieldLabel = undefined;
        this.targetFieldLabelOptions = [];
        this.targetFieldAPINameOptions = [];
        let validTargetTypes = this.validTargetTypesBySourceType[displayType];

        for (let i = 0; i < validTargetTypes.length; i++) {
            let validType = validTargetTypes[i];
            let validTargetTypesByLabel = this.targetFieldsByLabelByDisplayType[validType] || [];
            let validTargetTypesAPIName = this.targetFieldsByAPINameByDisplayType[validType] || [];

            this.targetFieldLabelOptions.push(...validTargetTypesByLabel);
            this.targetFieldAPINameOptions.push(...validTargetTypesAPIName);
        }
    }

    /*******************************************************************************
    * @description Handles the onchange event for the bdiFieldMappingModalComboboxSearch
    * targetFieldLabel, sets the value for both targetFieldLabel and targetFieldAPIName.
    *
    * @param {object} event: Event containing combobox selection details
    */
    handleTargetFieldLabelChange(event) {
        this.selectedTargetFieldAPIName = event.detail.value;
        this.selectedTargetFieldLabel = this.targetObjectFieldsByAPIName[event.detail.value];
    }

    /*******************************************************************************
    * @description Handles the onchange event for the bdiFieldMappingModalComboboxSearch
    * targetFieldAPIName, sets the value for both targetFieldAPIName and targetFieldLabel.
    *
    * @param {object} event: Event containing combobox selection details
    */
    handleTargetFieldAPINameChange(event) {
        this.selectedTargetFieldLabel = event.detail.value;
        this.selectedTargetFieldAPIName = this.targetObjectFieldsByLabel[event.detail.value];
    }

    /*******************************************************************************
    * @description Creates and dispatches a ShowToastEvent
    *
    * @param {string} title: Title of the toast, dispalyed as a heading.
    * @param {string} message: Message of the toast. It can contain placeholders in
    * the form of {0} ... {N}. The placeholders are replaced with the links from
    * messageData param
    * @param {string} mode: Mode of the toast
    * @param {array} messageData: List of values that replace the {index} placeholders
    * in the message param
    */
    showToast(title, message, variant, mode, messageData) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode,
            messageData: messageData
        });
        this.dispatchEvent(event);
    }

    /*******************************************************************************
    * @description Parse proxy objects for debugging, mutating, etc
    *
    * @param object: Object to be parsed
    */
    parse(obj) {
       return JSON.parse(JSON.stringify(obj));
    }
}