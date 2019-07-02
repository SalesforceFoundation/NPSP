import { LightningElement, api, track } from 'lwc';
import createDataImportFieldMapping
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.createDataImportFieldMapping';
import getObjectFieldDescribes
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.getObjectFieldDescribes';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { registerListener, unregisterListener, unregisterAllListeners, fireEvent }
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
            console.log('Edit');
            console.log(this.log(this.row));
            this.selectedSourceFieldLabel = this.row.Source_Field_Label_xxx;
            this.selectedSourceFieldAPIName = this.row.Source_Field_API_Name_xxx;
            this.selectedTargetFieldAPIName = this.row.Target_Field_API_Name_xxx;
            this.selectedTargetFieldLabel = this.row.Target_Field_Label_xxx;

            this.targetFieldLabelOptions = this.targetFieldsByLabelByDisplayType[this.row.Source_Field_Data_Type_xxx];
            this.targetFieldAPINameOptions = this.targetFieldsByAPINameByDisplayType[this.row.Source_Field_Data_Type_xxx];
        } else {
            // New
            this.selectedSourceFieldLabel = undefined;
            this.selectedSourceFieldAPIName = undefined;
            this.selectedTargetFieldLabel = undefined;
            this.selectedTargetFieldAPIName = undefined;
        }

        console.log('Set isLoading to false');
        this.isLoading = false;
    }

    handleSave() {
        this.logBold('bdiFieldMappingModal | handleSave()');
        this.isLoading = true;
        let clonedRow;

        if (this.row) {
            // Set source and target fields
            this.row.Source_Field_API_Name_xxx = this.selectedSourceFieldAPIName;
            this.row.Target_Field_API_Name_xxx = this.selectedTargetFieldAPIName;
            clonedRow = JSON.stringify(this.row);
        } else {
            // New Field Mapping
            clonedRow = JSON.stringify({
                Data_Import_Field_Mapping_Set__c: 'Migrated_Custom_Field_Mapping_Set',
                DeveloperName: null,
                Is_Deleted__c: false,
                Label: this.selectedSourceFieldLabel,
                MasterLabel: this.selectedSourceFieldLabel,
                Required__c: 'No',
                Source_Field_API_Name__c: this.selectedSourceFieldAPIName,
                Target_Field_API_Name__c: this.selectedTargetFieldAPIName,
                Target_Object_Mapping__c: this.objectMapping.DeveloperName
            });
        }

        createDataImportFieldMapping({fieldMappingString: clonedRow})
            .then((deploymentId) => {
                console.log('deployed metadata, deploymentId vvv');
                console.log(this.log(deploymentId));
                this.handleDeploymentId(deploymentId);
            })
            .catch((error) => {
                console.log(this.log(error));
                this.isLoading = false;
                this.showToast(
                    'Error',
                    '{0}. {1}. {2}.',
                    'error',
                    'sticky',
                    [error.body.exceptionType, error.body.message, error.body.stackTrace]);
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
        this.isLoading = false;
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

        this.targetFieldLabelOptions = this.targetFieldsByLabelByDisplayType[fieldInfo.displayType];
        this.targetFieldAPINameOptions = this.targetFieldsByAPINameByDisplayType[fieldInfo.displayType];
    }

    handleSourceFieldAPINameChange(event) {
        this.logBold('bdiFieldMappingModal | handleSourceFieldAPINameChange()');
        let fieldLabel = event.detail.value;
        let fieldInfo = this.diFieldsByLabel[fieldLabel];

        this.selectedSourceFieldLabel = fieldLabel;
        this.selectedSourceFieldAPIName = fieldInfo.value;

        this.targetFieldLabelOptions = this.targetFieldsByLabelByDisplayType[fieldInfo.displayType];
        this.targetFieldAPINameOptions = this.targetFieldsByAPINameByDisplayType[fieldInfo.displayType];
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
        getObjectFieldDescribes({objectName: 'DataImport__c'})
            .then((data) => {
                this.sourceFieldLabelOptions = [], this.sourceFieldAPINameOptions = [];
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
            })
            .catch((error) => {
                console.log(error);
            });
    }

    handleGetTargetObjectFieldDescribes() {
        getObjectFieldDescribes({objectName: this.objectMapping.Object_API_Name__c})
            .then((data) => {
                this.targetFieldLabelOptions = [], this.targetFieldAPINameOptions = [];
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
            })
            .catch((error) => {
                console.log(error);
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
    log(obj) {
       return JSON.parse(JSON.stringify(obj));
    }

    logBold(string) {
        return console.log('%c ' + string, 'font-weight: bold; font-size: 16px;');
    }
    // TODO: END
}