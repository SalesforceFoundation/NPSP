import { LightningElement, api, track } from 'lwc';
import createDataImportFieldMapping
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.createDataImportFieldMapping';
import getObjectFieldDescribes
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.getObjectFieldDescribes';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { registerListener, unregisterAllListeners, fireEvent }
    from 'c/pubsubNoPageRef';

export default class bdiFieldMappingModal extends LightningElement {

    @api objectMapping;
    @api isModalOpen;
    @track isLoading;
    @track row;

    // Combobox vars
    @track selectedSourceFieldLabel;
    @track sourceFieldLabelOptions;
    @track selectedSourceFieldAPIName;
    @track sourceFieldAPINameOptions;

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

    // Map of Display Types
    validTargetTypesBySourceType = {
        "ID": ["ID", "STRING"],
        "REFERENCE": ["REFERENCE", "STRING"],
        "PHONE": ["PHONE", "STRING"],
        "TEXTAREA": ["TEXTAREA", "STRING"],
        "URL": ["URL", "STRING"],
        "EMAIL": ["EMAIL", "STRING"],
        // The following currently only support same-type mapping
        "BOOLEAN": ["BOOLEAN"],
        "STRING": ["STRING"],
        "DATETIME": ["DATETIME"],
        "DATE": ["DATE"],
        "PICKLIST": ["PICKLIST"], // TODO: Include sometimes Boolean as per the BDI Mapping Field Types dc
        "CURRENCY": ["CURRENCY"],
        "PERCENT": ["PERCENT"]
    };

    get isTargetFieldDisabled() {
        if (this.selectedSourceFieldAPIName || this.selectedSourceFieldLabel) {
            return false;
        }
        return true;
    }

    constructor() {
        super();
        this.escapeFunction = this.escapeFunction.bind(this);
    }

    connectedCallback() {
        this.logBold('Modal | connectedCallback()');
        console.log(this.validTargetTypesBySourceType);
        document.addEventListener("keydown", this.escapeFunction, false);
        registerListener('openModal', this.handleOpenModal, this);

        this.handleGetDataImportFieldDescribes();
        this.handleGetTargetObjectFieldDescribes();
    }

    disconnectedCallback() {
        this.logBold('Modal | disconnectedCallback()');
        document.removeEventListener("keydown", this.escapeFunction, false);
        unregisterAllListeners(this);
    }

    escapeFunction(event) {
        if (event.keyCode === 27) {
            this.handleCloseModal();
        }
    }

    handleCloseModal() {
        this.objectMapping = undefined;
        this.isModalOpen = false;
    }

    handleOpenModal(event) {
        this.logBold('bdiFieldMappingModal | handleOpenModal()');
        this.isModalOpen = true;
        this.isLoading = true;
        this.objectMapping = event.objectMapping;
        this.row = event.row;

        if (this.row) {
            // Edit
            this.selectedSourceFieldLabel = this.row.xxx_Source_Field_Label_xxx;
            this.selectedSourceFieldAPIName = this.row.xxx_Source_Field_API_Name_xxx;
            this.selectedTargetFieldAPIName = this.row.xxx_Target_Field_API_Name_xxx;
            this.selectedTargetFieldLabel = this.row.xxx_Target_Field_Label_xxx;

            this.targetFieldLabelOptions = this.targetFieldsByLabelByDisplayType[this.row.xxx_Source_Field_Data_Type_xxx];
            this.targetFieldAPINameOptions = this.targetFieldsByAPINameByDisplayType[this.row.xxx_Source_Field_Data_Type_xxx];
        } else {
            // New
            this.selectedSourceFieldLabel = undefined;
            this.selectedSourceFieldAPIName = undefined;
            this.selectedTargetFieldLabel = undefined;
            this.selectedTargetFieldAPIName = undefined;
        }

        this.isLoading = false;
    }

    handleSave() {
        this.logBold('bdiFieldMappingModal | handleSave()');
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
            .then((data) => {
                this.handleSaveResult(data);
            })
            .catch((error) => {
                this.isLoading = false;
                this.showToast(
                    'Error',
                    '{0}. {1}. {2}.',
                    'error',
                    'sticky',
                    [error.body.exceptionType, error.body.message, error.body.stackTrace]);
            });
    }

    handleSaveResult() {
        this.logBold('bdiFieldMappingModal | handleSaveResult');
        let that = this;
        setTimeout(function() {
            console.log('First Refresh');
            fireEvent(that.pageRef, 'refresh', {});
            that.isModalOpen = false;
            that.isLoading = false;
            that.showToast(
                'Success',
                '',
                'success');
        }, 5000, that);
    }

    handleSourceFieldLabelChange(event) {
        this.logBold('bdiFieldMappingModal | handleSourceFieldLabelChange()');
        let fieldAPIName = event.detail.value;
        let fieldInfo = this.diFieldsByAPIName[fieldAPIName];

        this.selectedSourceFieldAPIName = fieldAPIName;
        this.selectedSourceFieldLabel = fieldInfo.label;

        this.handleAvailableTargetFieldsBySourceFieldDisplayType(fieldInfo.displayType);
    }

    handleSourceFieldAPINameChange(event) {
        this.logBold('bdiFieldMappingModal | handleSourceFieldAPINameChange()');
        let fieldLabel = event.detail.value;
        let fieldInfo = this.diFieldsByLabel[fieldLabel];

        this.selectedSourceFieldLabel = fieldLabel;
        this.selectedSourceFieldAPIName = fieldInfo.value;

        this.handleAvailableTargetFieldsBySourceFieldDisplayType(fieldInfo.displayType);
    }

    handleAvailableTargetFieldsBySourceFieldDisplayType(displayType) {
        this.logBold('bdiFieldMappingModal | handleAvailableTargetFieldsBySourceFieldDisplayType()');
        this.targetFieldLabelOptions = [];
        this.targetFieldAPINameOptions = [];
        let validTargetTypes = this.validTargetTypesBySourceType[displayType];

        for (let i = 0; i < validTargetTypes.length; i++) {
            let validType = validTargetTypes[i];

            let validTargetTypesByLabel = this.targetFieldsByLabelByDisplayType[validType];
            let validTargetTypesAPIName = this.targetFieldsByAPINameByDisplayType[validType];

            this.targetFieldLabelOptions.push(...validTargetTypesByLabel);
            this.targetFieldAPINameOptions.push(...validTargetTypesAPIName);
        }
    }

    handleTargetFieldLabelChange(event) {
        this.logBold('bdiFieldMappingModal | handleTargetFieldLabelChange()');
        this.selectedTargetFieldAPIName = event.detail.value;
        this.selectedTargetFieldLabel = this.targetObjectFieldsByAPIName[event.detail.value];
    }

    handleTargetFieldAPINameChange(event) {
        this.logBold('bdiFieldMappingModal | handleTargetFieldAPINameChange()');
        this.selectedTargetFieldLabel = event.detail.value;
        this.selectedTargetFieldAPIName = this.targetObjectFieldsByLabel[event.detail.value];
    }

    handleGetDataImportFieldDescribes() {
        this.logBold('bdiFieldMappingModal | handleGetDataImportFieldDescribes()');
        getObjectFieldDescribes({objectName: 'DataImport__c'})
            .then((data) => {
                this.sourceFieldLabelOptions = [];
                this.sourceFieldAPINameOptions = [];
                let diFieldsByLabel = {}, diFieldsByAPIName = {};

                for (let i = 0; i < data.length; i++) {
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

                    diFieldsByLabel[labelOption.label] = data[i];
                    diFieldsByAPIName[labelOption.value] = data[i];
                }

                this.diFieldsByLabel = diFieldsByLabel;
                this.diFieldsByAPIName = diFieldsByAPIName;

                console.log(this.log(diFieldsByLabel));
            })
            .catch((error) => {
                this.showToast(
                    'Error',
                    '{0}. {1}. {2}.',
                    'error',
                    'sticky',
                    [error.body.exceptionType, error.body.message, error.body.stackTrace]);
            });
    }

    handleGetTargetObjectFieldDescribes() {
        getObjectFieldDescribes({objectName: this.objectMapping.Object_API_Name__c || this.objectMapping.npsp__Object_API_Name__c})
            .then((data) => {
                this.targetFieldLabelOptions = [];
                this.targetFieldAPINameOptions = [];
                let targetObjectFieldsByLabel = {}, targetObjectFieldsByAPIName = {};
                let fieldByLabelByDisplayType = {}, fieldByAPINameByDisplayType = {};
                for (let i = 0; i < data.length; i++) {
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

                this.targetObjectFieldsByLabel = targetObjectFieldsByLabel;
                this.targetObjectFieldsByAPIName = targetObjectFieldsByAPIName;

                this.targetFieldsByLabelByDisplayType = fieldByLabelByDisplayType;
                this.targetFieldsByAPINameByDisplayType = fieldByAPINameByDisplayType;

                console.log(this.log(fieldByLabelByDisplayType));
            })
            .catch((error) => {
                this.showToast(
                    'Error',
                    '{0}. {1}. {2}.',
                    'error',
                    'sticky',
                    [error.body.exceptionType, error.body.message, error.body.stackTrace]);
            });
    }

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

    // TODO: Delete later
    /*******************************************************************************
    * @description Parse proxy objects for debugging, mutating, etc
    *
    * @param object: Object to be parsed
    */
    parse(obj) {
       return JSON.parse(JSON.stringify(obj));
    }

    logBold(string) {
        return console.log('%c ' + string, 'font-weight: bold; font-size: 16px;');
    }
    // TODO: END
}