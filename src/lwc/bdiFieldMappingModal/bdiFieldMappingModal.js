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

    connectedCallback() {
        this.logBold('bdiFieldMappingModal | connectCallback()');
        registerListener('openModal', this.handleOpenModal, this);

        this.handleGetDataImportFieldDescribes();
        this.handleGetTargetObjectFieldDescribes();
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    handleCloseModal() {
        this.objectMapping = undefined;
        this.isModalOpen = false;
    }

    handleOpenModal(event) {
        this.logBold('bdiFieldMappingModal | handleOpenModal()');
        console.log('ObjectMapping: ', this.log(event.objectMapping));
        console.log('Event: ', this.log(event));
        this.isModalOpen = true;
        this.isLoading = true;
        this.objectMapping = event.objectMapping;
        this.row = event.row;

        if (this.row) {
            console.log('Made it in here? Row exists?');
            this.selectedSourceFieldLabel = this.row.Source_Field_Label_xxx;
            this.selectedSourceFieldAPIName = this.diFieldsByLabel[this.row.Source_Field_Label_xxx];
            this.selectedTargetFieldAPIName = this.row.Target_Field_API_Name_xxx.toLowerCase();
            this.selectedTargetFieldLabel =
                this.targetObjectFieldsByAPIName[this.row.Target_Field_API_Name_xxx.toLowerCase()];
        } else {
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
            console.log('setting source and target fields...');
            // Set source and target fields
            this.row.Source_Field_API_Name_xxx = this.selectedSourceFieldAPIName;
            this.row.Target_Field_API_Name_xxx = this.selectedTargetFieldAPIName;
            clonedRow = JSON.stringify(this.row);
        } else {
            console.log('creating new field mapping...');
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
            console.log(clonedRow);
        }

        createDataImportFieldMapping({fieldMappingString: clonedRow})
            .then((data) => {
                console.log(this.log(data));
                this.handleSaveResult(data);
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

    handleSaveResult() {
        this.logBold('bdiFieldMappingModal | handleSaveResult');
        let that = this;
        setTimeout(function() {
            console.log('First Refresh');
            fireEvent(that.pageRef, 'forceRefresh', {});
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
        this.selectedSourceFieldAPIName = event.detail.value;
        this.selectedSourceFieldLabel = this.diFieldsByAPIName[event.detail.value];
    }

    handleSourceFieldAPINameChange(event) {
        this.logBold('bdiFieldMappingModal | handleSourceFieldAPINameChange()');
        console.log(event.detail.value);
        console.log(this.diFieldsByLabel[event.detail.value]);
        let selectedSourceFieldLabel = event.detail.value;
        let selectedSourceFieldAPIName = this.diFieldsByLabel[selectedSourceFieldLabel];
        this.selectedSourceFieldAPIName = selectedSourceFieldAPIName;
        this.selectedSourceFieldLabel = selectedSourceFieldLabel;
    }

    handleTargetFieldLabelChange(event) {
        this.logBold('bdiFieldMappingModal | handleTargetFieldLabelChange()');
        console.log(event.detail.value);
        console.log(this.targetObjectFieldsByAPIName[event.detail.value]);
        let selectedTargetFieldAPIName = event.detail.value;
        let selectedTargetFieldLabel = this.targetObjectFieldsByAPIName[selectedTargetFieldAPIName];
        this.selectedTargetFieldAPIName = selectedTargetFieldAPIName;
        this.selectedTargetFieldLabel = selectedTargetFieldLabel;
    }

    handleTargetFieldAPINameChange(event) {
        this.logBold('bdiFieldMappingModal | handleTargetFieldAPINameChange()');
        console.log(event.detail.value);
        console.log(this.targetObjectFieldsByLabel[event.detail.value]);
        let selectedTargetFieldLabel = event.detail.value;
        let selectedTargetFieldAPIName = this.targetObjectFieldsByLabel[selectedTargetFieldLabel];
        this.selectedTargetFieldAPIName = selectedTargetFieldAPIName;
        this.selectedTargetFieldLabel = selectedTargetFieldLabel;
    }

    handleGetDataImportFieldDescribes() {
        getObjectFieldDescribes({objectName: 'DataImport__c'})
            .then((data) => {
                let sourceFieldLabelOptions = [], sourceFieldAPINameOptions = [];

                Object.keys(data).forEach((key) => {
                    let labelOption = {}, apiNameOption = {};

                    labelOption.label = key;
                    labelOption.value = data[key];
                    apiNameOption.label = data[key];
                    apiNameOption.value = key;

                    sourceFieldLabelOptions.push(labelOption);
                    sourceFieldAPINameOptions.push(apiNameOption);
                });

                this.sourceFieldLabelOptions = sourceFieldLabelOptions;
                this.sourceFieldAPINameOptions = sourceFieldAPINameOptions;
                

                // TODO: Clean up or find better way. Currently being used in order to set
                // the value for the sibling combobox when one or the other is updated
                this.diFieldsByLabel = data;
                let diFieldsByAPIName = {};
                if (data) {
                    for(let key in data){
                        if (data[key]) {
                            diFieldsByAPIName[data[key]] = key;
                        }
                    }
                }
                this.diFieldsByAPIName = diFieldsByAPIName;
            })
            .catch((error) => {
                console.log(error);
            });
    }

    handleGetTargetObjectFieldDescribes() {
        // TODO: Dynamically get object name
        getObjectFieldDescribes({objectName: this.objectMapping.Object_API_Name__c})
            .then((data) => {
                let targetFieldLabelOptions = [], targetFieldAPINameOptions = [];

                Object.keys(data).forEach((key) => {
                    let labelOption = {}, apiNameOption = {};

                    labelOption.label = key;
                    labelOption.value = data[key];
                    apiNameOption.label = data[key];
                    apiNameOption.value = key;

                    targetFieldLabelOptions.push(labelOption);
                    targetFieldAPINameOptions.push(apiNameOption);
                });

                this.targetFieldLabelOptions = targetFieldLabelOptions;
                this.targetFieldAPINameOptions = targetFieldAPINameOptions;
                

                // TODO: Clean up or find better way. Currently being used in order to set
                // the value for the sibling combobox when one or the other is updated
                this.targetObjectFieldsByLabel = data;
                let targetObjectFieldsByAPIName = {};
                if (data) {
                    for(let key in data){
                        if (data[key]) {
                            targetObjectFieldsByAPIName[data[key]] = key;
                        }
                    }
                }
                this.targetObjectFieldsByAPIName = targetObjectFieldsByAPIName;
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