import { LightningElement, api, track } from 'lwc';
import createDataImportFieldMapping
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.createDataImportFieldMapping';
import getObjectFieldDescribes
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.getObjectFieldDescribes';
import { registerListener, unregisterListener, unregisterAllListeners, fireEvent }
    from 'c/pubsubNoPageRef';

export default class BdiMappingModal extends LightningElement {

    @api objectMapping;
    @api isModalOpen;
    @track isLoading;

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
        this.logBold('bdiMappingModal | connectCallback()');
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
        this.logBold('bdiMappingModal | handleOpenModal()');
        console.log('ObjectMapping: ', this.log(event.objectMapping));
        console.log('Event: ', this.log(event));
        this.isModalOpen = true;
        this.isLoading = true;
        this.objectMapping = event.objectMapping;

        // TODO: Clean up or find better way. This is how we're setting the edit mode stuff
        console.log('handleGetTargetObjectFieldDescribes inside then');
        if (event.sourceFieldLabel && event.targetFieldAPIName) {
            this.selectedSourceFieldLabel = event.sourceFieldLabel;
            this.selectedSourceFieldAPIName = this.diFieldsByLabel[event.sourceFieldLabel];
            console.log(event.targetFieldAPIName);
            this.selectedTargetFieldAPIName = event.targetFieldAPIName.toLowerCase();
            this.selectedTargetFieldLabel =
                this.targetObjectFieldsByAPIName[event.targetFieldAPIName.toLowerCase()];
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
        this.logBold('bdiMappingModal | handleSave()');
        this.isLoading = true;
        createDataImportFieldMapping({fieldMappingString: this.buildDataImportFieldMapping()})
            .then((data) => {
                console.log(this.log(data));
                this.handleSaveResult(data);
            })
            .catch((error) => {
                console.log(error);
            });
    }

    handleSaveResult() {
        this.logBold('bdiMappingModal | handleSaveResult');
        let that = this;
        setTimeout(function() {
            console.log('First Refresh');
            fireEvent(that.pageRef, 'forceRefresh', {});
            that.isModalOpen = false;
        }, 5000, that);
    }

    buildDataImportFieldMapping() {
        // TODO: Make dynamic
        this.logBold('Building Data Import Field Mapping');

        let dataImportFieldMapping = {
            DeveloperName: this.selectedSourceFieldLabel.replace(/\s/g, '_'),
            MasterLabel: this.selectedSourceFieldLabel,
            Label: this.selectedSourceFieldLabel,
            Source_Field_API_Name__c: this.selectedSourceFieldAPIName,
            Target_Field_API_Name__c: this.selectedTargetFieldAPIName,
            Data_Import_Field_Mapping_Set__c: 'Migrated_Custom_Field_Mapping_Set',
            Target_Object_Mapping__c: this.objectMapping.DeveloperName,
            Is_Deleted__c: false,
            Required__c: 'No'};
        console.log(dataImportFieldMapping);
        console.log(JSON.stringify(dataImportFieldMapping));
        
        return JSON.stringify(dataImportFieldMapping);
    }

    handleSourceFieldLabelChange(event) {
        this.logBold('bdiMappingModal | handleSourceFieldLabelChange()');
        console.log(event.detail.value);
        console.log(this.diFieldsByAPIName[event.detail.value]);
        let selectedSourceFieldAPIName = event.detail.value;
        let selectedSourceFieldLabel = this.diFieldsByAPIName[selectedSourceFieldAPIName];
        this.selectedSourceFieldAPIName = selectedSourceFieldAPIName;
        this.selectedSourceFieldLabel = selectedSourceFieldLabel;
    }

    handleSourceFieldAPINameChange(event) {
        this.logBold('bdiMappingModal | handleSourceFieldAPINameChange()');
        console.log(event.detail.value);
        console.log(this.diFieldsByLabel[event.detail.value]);
        let selectedSourceFieldLabel = event.detail.value;
        let selectedSourceFieldAPIName = this.diFieldsByLabel[selectedSourceFieldLabel];
        this.selectedSourceFieldAPIName = selectedSourceFieldAPIName;
        this.selectedSourceFieldLabel = selectedSourceFieldLabel;
    }

    handleTargetFieldLabelChange(event) {
        this.logBold('bdiMappingModal | handleTargetFieldLabelChange()');
        console.log(event.detail.value);
        console.log(this.targetObjectFieldsByAPIName[event.detail.value]);
        let selectedTargetFieldAPIName = event.detail.value;
        let selectedTargetFieldLabel = this.targetObjectFieldsByAPIName[selectedTargetFieldAPIName];
        this.selectedTargetFieldAPIName = selectedTargetFieldAPIName;
        this.selectedTargetFieldLabel = selectedTargetFieldLabel;
    }

    handleTargetFieldAPINameChange(event) {
        this.logBold('bdiMappingModal | handleTargetFieldAPINameChange()');
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