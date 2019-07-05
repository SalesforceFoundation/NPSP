/* eslint-disable @lwc/lwc/no-async-operation */
import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsubNoPageRef';
import createDataImportFieldMapping
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.createDataImportFieldMapping';
import getObjectFieldDescribes
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.getObjectFieldDescribes';

const DELAY = 300;

export default class bdiFieldMappingModal extends LightningElement {

    @api objectMapping = {
        DeveloperName: 'Account',
        Object_API_Name__c: 'Account',
        MasterLabel: 'Account1'
    };
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
    @track mappedTargetFieldAPINames = [];

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
        this.logBold('Modal | connectedCallback()');
        document.addEventListener("keydown", this.escapeFunction, false);
        registerListener('openModal', this.handleOpenModal, this);
        registerListener('closeModal', this.handleCloseModal, this);
        this.getAllData();
        this.isModalOpen = true;
    }

    disconnectedCallback() {
        //this.logBold('Modal | disconnectedCallback()');
        document.removeEventListener("keydown", this.escapeFunction, false);
        unregisterAllListeners(this);
    }

    getAllData = async() => {
        try {
            const dataImportFieldDescribe = await this.handleGetDataImportFieldDescribes();
            const targetObjectFieldDescribes = await this.handleGetTargetObjectFieldDescribes();

            this.setDataImportProperties(dataImportFieldDescribe);
            this.setTargetObjectFieldDescribes(targetObjectFieldDescribes);
        } catch(error) {
            if (error) {
                this.showToast('Error', error, 'error', 'sticky');
            }
            throw error;
        }
    }

    handleGetDataImportFieldDescribes = async() => {
        //this.logBold('bdiFieldMappingModal | handleGetDataImportFieldDescribes()');
        return getObjectFieldDescribes({objectName: 'DataImport__c'})
            .then((data) => {
                return data;
            });
    }

    handleGetTargetObjectFieldDescribes = async() => {
        //this.logBold('bdiFieldMappingModal | handleGetTargetObjectFieldDescribes()');
        let objectAPIName =
            this.objectMapping.Object_API_Name__c || this.objectMapping.npsp__Object_API_Name__c;

        return getObjectFieldDescribes({objectName: objectAPIName})
            .then((data) => {
                return data;
            });
    }

    setDataImportProperties(data) {
        //this.logBold('setDataImportProperties()');
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

    setTargetObjectFieldDescribes(data) {
        //this.logBold('setTargetObjectFieldDescribes()');
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

    escapeFunction(event) {
        if (event.keyCode === 27) {
            this.handleCloseModal();
        }
    }

    showSearch() {
        this.isSearchOpen = true;
    }

    hideSearch() {
        this.isSearchOpen = false;
        this.areSearchResultsVisible = false;
    }

    debounceOnSearchKeyChange(event) {
        // Debouncing this method: Do not update the reactive property as long as this function is
        // being called within a delay of DELAY. This is to avoid a very large number of Apex method calls.
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        if (searchKey && searchKey.length > 1) {
            console.log('Start time out for search');
            this.delayTimeout = setTimeout(() => {
                this.handleSearchkeyChange(searchKey);
            }, DELAY);
        } else {
            this.searchResults = undefined;
        }
    }

    handleSearchkeyChange(searchKey) {
        console.log('handleSearchkeyChange: ', searchKey);
        let results = [];
        if (!this.diKeys) {
            this.diKeys = Object.keys(this.diFieldsByLabel);
        }
        console.log('By Labels');
        console.log(this.parse(this.diFieldsByLabel));
        console.log('By Keys');
        console.log(this.parse(this.diKeys));

        for(let i = 0; i < this.diKeys.length; i++) {
            if (this.diKeys[i].toLowerCase().indexOf(searchKey.toLowerCase()) != -1) {
                let result = {
                    id: i,
                    fieldInfo: this.diFieldsByLabel[this.diKeys[i]]
                }
                results.push(result);
            }
        }
        this.searchResults = results;
        this.areSearchResultsVisible = true;
        console.log(results);
    }

    selectSearchResult(event) {
        this.logBold('bdiFieldMappingModal | selectSearchResult()');
        let result = {
            id: event.target.dataset.id,
            label: event.target.dataset.fieldLabel,
            value: event.target.dataset.fieldValue
        }
        console.log(result);

        let fieldAPIName = result.value;
        console.log('fieldAPIName: ', fieldAPIName);
        let fieldInfo = this.diFieldsByAPIName[fieldAPIName];
        console.log('fieldInfo: ', fieldInfo);

        this.selectedSourceFieldAPIName = fieldAPIName;
        this.selectedSourceFieldLabel = fieldInfo.label;

        this.searchResults = undefined;
        this.isSearchOpen = false;
        this.areSearchResultsVisible = false;

        this.handleAvailableTargetFieldsBySourceFieldDisplayType(fieldInfo.displayType);
    }

    handleCloseModal() {
        this.isModalOpen = false;
    }

    handleOpenModal(event) {
        this.logBold('bdiFieldMappingModal | handleOpenModal()');
        this.isModalOpen = true;
        this.isLoading = true;
        this.objectMapping = event.objectMapping;

        for (let i = 0; i < event.fieldMappings.length; i++) {
            let fieldMapping = event.fieldMappings[i];

            this.mappedDIFieldLabels.push(fieldMapping.xxx_Source_Field_Label_xxx);
            this.mappedTargetFieldLabels.push(fieldMapping.xxx_Target_Field_Label_xxx);
            this.mappedTargetFieldAPINames.push(fieldMapping.xxx_Target_Field_API_Name_xxx);
        }

        this.row = event.row;

        if (this.row) {
            //this.logBold('EDIT');
            // Edit
            this.selectedSourceFieldLabel = this.row.xxx_Source_Field_Label_xxx;
            this.selectedSourceFieldAPIName = this.row.xxx_Source_Field_API_Name_xxx;
            this.selectedTargetFieldAPIName = this.row.xxx_Target_Field_API_Name_xxx;
            this.selectedTargetFieldLabel = this.row.xxx_Target_Field_Label_xxx;
            this.selectedSourceFieldDisplayType = this.row.xxx_Source_Field_Data_Type_xxx;
        } else {
            // New
            this.selectedSourceFieldLabel = undefined;
            this.selectedSourceFieldAPIName = undefined;
            this.selectedTargetFieldLabel = undefined;
            this.selectedTargetFieldAPIName = undefined;
        }

        this.getAllData().then(() => { this.isLoading = false });
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

    handleDeploymentId(deploymentId) {
        //tell our parent element that we have an Id to monitor
        const deploymentEvent = new CustomEvent('deployment', {
            bubbles: true,
            composed: true,
            detail: {deploymentId}
        });
        this.dispatchEvent(deploymentEvent);

        fireEvent(this.pageRef, 'startDeploymentTimeout', { deploymentId: deploymentId });
    }

    handleSourceFieldLabelChange(event) {
        this.logBold('bdiFieldMappingModal | handleSourceFieldLabelChange()');
        let fieldAPIName = event.detail.value;
        console.log('fieldAPIName: ', fieldAPIName);
        console.log('this.diFieldsByAPIName: ', this.parse(this.diFieldsByAPIName));
        let fieldInfo = this.diFieldsByAPIName[fieldAPIName];
        console.log('fieldInfo: ', fieldInfo);

        this.selectedSourceFieldAPIName = fieldAPIName;
        this.selectedSourceFieldLabel = fieldInfo.label;

        console.log('handling available target fields by source field display type');
        this.handleAvailableTargetFieldsBySourceFieldDisplayType(fieldInfo.displayType);
    }

    handleSourceFieldAPINameChange(event) {
        //this.logBold('bdiFieldMappingModal | handleSourceFieldAPINameChange()');
        let fieldLabel = event.detail.value;
        let fieldInfo = this.diFieldsByLabel[fieldLabel.toLowerCase()];

        this.selectedSourceFieldLabel = fieldLabel;
        this.selectedSourceFieldAPIName = fieldInfo.value;

        this.handleAvailableTargetFieldsBySourceFieldDisplayType(fieldInfo.displayType);
    }

    handleAvailableTargetFieldsBySourceFieldDisplayType(displayType) {
        //this.logBold('bdiFieldMappingModal | handleAvailableTargetFieldsBySourceFieldDisplayType()');
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

    handleTargetFieldLabelChange(event) {
        //this.logBold('bdiFieldMappingModal | handleTargetFieldLabelChange()');
        this.selectedTargetFieldAPIName = event.detail.value;
        this.selectedTargetFieldLabel = this.targetObjectFieldsByAPIName[event.detail.value];
    }

    handleTargetFieldAPINameChange(event) {
        //this.logBold('bdiFieldMappingModal | handleTargetFieldAPINameChange()');
        this.selectedTargetFieldLabel = event.detail.value;
        this.selectedTargetFieldAPIName = this.targetObjectFieldsByLabel[event.detail.value];
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