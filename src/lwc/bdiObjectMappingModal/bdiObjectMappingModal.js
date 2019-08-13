import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createDataImportObjectMapping
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.createDataImportObjectMapping';
import getObjectFieldDescribes
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.getObjectFieldDescribes';
import getRelationshipFieldOptions
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.getRelationshipFieldOptions';
import getMappedDISourceFields
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.getMappedDISourceFields';
import getDataImportObjectName
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.getDataImportObjectName';

import { registerListener, unregisterAllListeners, fireEvent }
    from 'c/pubsubNoPageRef';

// Import Custom Labels
import bdiOMUIChildParentLabel from '@salesforce/label/c.bdiOMUIChildParentLabel';
import bdiOMUIGroupNameLabel from '@salesforce/label/c.bdiOMUIGroupNameLabel';
import bdiOMUIImportStatusLabel from '@salesforce/label/c.bdiOMUIImportStatusLabel';
import bdiOMUILinkToRecordLabel from '@salesforce/label/c.bdiOMUILinkToRecordLabel';
import bdiOMUIObjectNameLabel from '@salesforce/label/c.bdiOMUIObjectNameLabel';
import bdiOMUIOfGroupLabel from '@salesforce/label/c.bdiOMUIOfGroupLabel';
import bdiOMUIThroughFieldLabel from '@salesforce/label/c.bdiOMUIThroughFieldLabel';
import bdiFMUISuccessful from '@salesforce/label/c.bdiFMUISuccessful';
import bdiFMUIUnsuccessful from '@salesforce/label/c.bdiFMUIUnsuccessful';
import bdiFMUITryAgain from '@salesforce/label/c.bdiFMUITryAgain';

import bdiBtnClose from '@salesforce/label/c.bdiBtnClose';
import stgUnknownError from '@salesforce/label/c.stgUnknownError';
import bdiOMUIImportDetailsTitle from '@salesforce/label/c.bdiOMUIImportDetailsTitle';

import bdiOMUIChildParentHelp from '@salesforce/label/c.bdiOMUIChildParentHelp';
import bdiOMUICreateModalTitle from '@salesforce/label/c.bdiOMUICreateModalTitle';
import bdiOMUIEditModalTitle from '@salesforce/label/c.bdiOMUIEditModalTitle';
import bdiOMUIGroupNameHelp from '@salesforce/label/c.bdiOMUIGroupNameHelp';
import bdiOMUIImportStatusHelp from '@salesforce/label/c.bdiOMUIImportStatusHelp';
import bdiOMUILinkToRecordHelp from '@salesforce/label/c.bdiOMUILinkToRecordHelp';
import bdiOMUIObjectNameHelp from '@salesforce/label/c.bdiOMUIObjectNameHelp';
import bdiOMUIOfGroupHelp from '@salesforce/label/c.bdiOMUIOfGroupHelp';
import bdiOMUIThroughFieldHelp from '@salesforce/label/c.bdiOMUIThroughFieldHelp';
import bdiOMUIErrorNoValidThroughThisField from '@salesforce/label/c.bdiOMUIErrorNoValidThroughThisField';
import bdiOMUIErrorDupeName from '@salesforce/label/c.bdiOMUIErrorDupeName';
import bdiOMUIErrorInvalidValues from '@salesforce/label/c.bdiOMUIErrorInvalidValues';
import bdiOMUIErrorNoUnmappedFieldsPt1 from '@salesforce/label/c.bdiOMUIErrorNoUnmappedFieldsPt1';
import bdiOMUIErrorNoUnmappedFieldsPt2 from '@salesforce/label/c.bdiOMUIErrorNoUnmappedFieldsPt2';
import stgBtnCancel from '@salesforce/label/c.stgBtnCancel';
import stgBtnSave from '@salesforce/label/c.stgBtnSave';

export default class bdiObjectMappingModal extends LightningElement {
    
    customLabels = {
        bdiOMUIChildParentLabel,
        bdiOMUIGroupNameLabel,
        bdiOMUIImportStatusLabel,
        bdiOMUILinkToRecordLabel,
        bdiOMUIObjectNameLabel,
        bdiOMUIOfGroupLabel,
        bdiOMUIThroughFieldLabel,
        bdiFMUISuccessful,
        bdiFMUIUnsuccessful,
        bdiFMUITryAgain,
        bdiBtnClose,
        stgUnknownError,
        bdiOMUIImportDetailsTitle,
        bdiOMUIChildParentHelp,
        bdiOMUICreateModalTitle,
        bdiOMUIEditModalTitle,
        bdiOMUIGroupNameHelp,
        bdiOMUIImportStatusHelp,
        bdiOMUILinkToRecordHelp,
        bdiOMUIObjectNameHelp,
        bdiOMUIOfGroupHelp,
        bdiOMUIThroughFieldHelp,
        bdiOMUIErrorNoValidThroughThisField,
        bdiOMUIErrorDupeName,
        bdiOMUIErrorInvalidValues,
        bdiOMUIErrorNoUnmappedFieldsPt1,
        bdiOMUIErrorNoUnmappedFieldsPt2,
        stgBtnCancel,
        stgBtnSave
    };

    excludedDIFields = ['ownerid',
                    'npsp__ApexJobId__c',
                    'npsp__Campaign_Member_Status__c',
                    'npsp__DonationCampaignImportStatus__c',
                    'npsp__DonationCampaignImported__c',
                    'npsp__Donation_Campaign_Name__c',
                    'npsp__Donation_Donor__c',
                    'npsp__Donation_Possible_Matches__c',
                    'npsp__FailureInformation__c',
                    'npsp__ImportedDate__c',
                    'npsp__NPSP_Data_Import_Batch__c',
                    'npsp__Payment_Possible_Matches__c',
                    'npsp__Status__c'];

    @api objectMappings;
    @api objectOptions;
    @api isModalOpen = false;
    @api diObjectMappingSetDevName;

    @track isLoading;
    @track inSave = false;
    @track row;

    @track modalTitle;

    @track diImportRecordFieldOptions;
    @track diImportRecordStatusFieldOptions;
    @track objectMappingOptions;
    @track relationshipFieldOptions;

    alreadyMappedDIFieldsMap;
    dataImportFieldData;
    dataImportFieldMappingSourceNames;

    @api namespace;

    _dataImportApiName;

    constructor() {
        super();
        this.escapeFunction = this.escapeFunction.bind(this);
    }

    /*******************************************************************************
    * @description Determines whether the relationship field (ie 'Through this field') field
    * is disabled or not based on whether there are relationship field options and if it is post-save
    * or if theres is already a relationship field value.
    */
    get isRelationshipFieldDisabled() {
        if (this.row.Relationship_Field || this.relationshipFieldOptions || this.inSave) {
            return false;
        }
        return true;
    }
    /*******************************************************************************
    * @description Dynamically determines style classes for the section.
    */
    get sectionClasses() {
        return this.isModalOpen ? 'slds-modal slds-fade-in-open' : 'slds-modal slds-hidden';
    }
    /*******************************************************************************
    * @description Dynamically determines style classes for the backdrop.
    */
    get backdropClasses() {
        return this.isModalOpen ? 'slds-backdrop slds-backdrop_open' : 'slds-backdrop';
    }

    /*******************************************************************************
    * @description Method called when the component is first instantiated
    */
    connectedCallback() {
        document.addEventListener("keydown", this.escapeFunction, false);

        registerListener('openModal', this.handleOpenModal, this);
        registerListener('closeModal', this.handleCloseModal, this);
        registerListener('objectNameChange',this.handleObjectAPINameChange,this);

        this.init();
    }

    /*******************************************************************************
    * @description Group up various get data calls to apex
    */
    init = async() => {
        try {
            this._dataImportApiName = await getDataImportObjectName();
            this.setDefaultValues();
            this.getDataImportFieldDescribes();
            this.getDataImportMappedFields();
        } catch(error) {
            this.handleError(error);
        }
    }

    /*******************************************************************************
    * @description Gets the list of Data Import field names that have already been 
    * mapped to field mappings.
    */
    getDataImportMappedFields() {
        getMappedDISourceFields()
            .then((data) => {
                this.dataImportFieldMappingSourceNames = data;
            })
            .catch((error) => {
                this.isLoading = false;
                this.handleError(error);
            });
    }

    /*******************************************************************************
    * @description Method called when the component is removed.
    */
    disconnectedCallback() {
        document.removeEventListener("keydown", this.escapeFunction, false);
        unregisterAllListeners(this);
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
    * @description Handles the close modal press and resets the row values to default
    */
    handleCloseModal() {
        this.isModalOpen = false;
        this.setDefaultValues();    
    }

    /*******************************************************************************
    * @description Handles the open modal event from bdiObjectMappings and allows
    * for SLDS classes to fade in modal elements and backdrop
    *
    * @param event: Event containing row details or lack of row details
    */
    handleOpenModal(event) {
        this.isModalOpen = true;
        this.isLoading = true;
        let that = this;
        let data = event;
        
        setTimeout(function() {
            that.loadModalData(data);
        }, 1, [that, data]);
    }

    /*******************************************************************************
    * @description Handles loading relevant data into the modal
    *
    * @param data: Event data containing row details or lack of row details
    */
    loadModalData(data) {
        try {
            this.getObjectMappingOptions();
            if (data.row) {
                // Edit Mode
                this.row = JSON.parse(JSON.stringify(data.row));
                this.row.Data_Import_Object_Mapping_Set = this.diObjectMappingSetDevName;
                this.modalTitle = this.customLabels.bdiOMUIEditModalTitle;

                this.getRelationshipFieldOptions();

            } else {
                // New Object mapping Mode
                this.setDefaultValues();
                this.modalTitle = this.customLabels.bdiOMUICreateModalTitle;
            }
            this.refreshImportRecordFieldOptions();

            this.isLoading = false;
        } catch(error) {
            this.handleError(error);
        }
    }

    /*******************************************************************************
    * @description Resets the values of the row to the default values
    */
    setDefaultValues() {
        this.row = {Id: null,
            MasterLabel: null,
            Custom_Mapping_Logic_Class: null,
            DeveloperName: null, 
            Data_Import_Object_Mapping_Set: this.diObjectMappingSetDevName, 
            Imported_Record_Field_Name: null,
            Imported_Record_Status_Field_Name: null,
            Object_API_Name: null,
            Predecessor: null,
            Relationship_Field: null,
            Relationship_To_Predecessor: null };
    }

    /*******************************************************************************
    * @description Handles the save event and calls the processing of the save
    */
    handleSave() {
        this.isLoading = true;
        this.inSave = true;
        let that = this;
        
        setTimeout(function() {
            that.processSave();
        }, 1, [that]);
    }

    /*******************************************************************************
    * @description Validates the fields and then calls the controller method to insert
    *  a new Object Mapping.
    */
    processSave() {
        let rowString;

        try {
            if (this.row) {
                if (this.validateFields()) {

                    rowString = JSON.stringify(this.row);
        
                    createDataImportObjectMapping({objectMappingString: rowString})
                    .then((deploymentId) => {
                        this.handleDeploymentId(deploymentId);
                    })
                    .catch((error) => {
                        this.isLoading = false;
                        this.handleError(error);
                    });
                } else {
                    this.isLoading = false;
                }
            } else {
                this.isLoading = false;
            }
        } catch(error) {
            this.handleError(error);
        }
    }

    /*******************************************************************************
    * @description Checks whether fields are valid, and returns false if they are not.
    * Also displays error toast if any fields are not valid.
    * @return {boolean} Whether or not the fields are valid.
    */
    validateFields() {

        let result = [...this.template.querySelectorAll('lightning-combobox,lightning-input')]
        .reduce((validSoFar, inputCmp) => {
                    //Special validation to make sure label name is not reused within the same Object Mapping set
                    if (inputCmp.name === 'masterLabel' && this.row.MasterLabel && this.objectMappings) {
                        let dupeFound = false;

                        for (let i = 0; i < this.objectMappings.length; i++) {
                            let tempObjMapping = this.objectMappings[i];

                            //If the labels are the same, but the Ids are not then throw an error
                            if (tempObjMapping.MasterLabel === this.row.MasterLabel
                                && tempObjMapping.Id !== this.row.Id) {

                                dupeFound = true;
                                inputCmp.setCustomValidity(this.customLabels.bdiOMUIErrorDupeName);
                            }
                        }
                        if(!dupeFound){
                            inputCmp.setCustomValidity('');
                        }
                    }

                    inputCmp.reportValidity();
                    let inputValid = inputCmp.checkValidity();
                    return validSoFar && inputValid;
        }, true);

        if (!result) {
            this.showToast(
                'Error',
                this.customLabels.bdiOMUIErrorInvalidValues,
                'error',
                'dismissable',
                null);
        }

        return result;
    }

    /*******************************************************************************
    * @description Creates and dispatches a CustomEvent 'deployment' letting the
    * platformEventListener know that we have an id to register and monitor. After
    * dispatching the CustomEvent, start the deployment timeout on bdiObjectMappings.
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
    * @description Takes the object mappings that have been passed through from the 
    * bdiObjectMappings component and turns them into picklist options for selecting
    * the predecessor object mapping.  Right now they are filtered to exclude anything
    * is not a core object (ie created by the existing bdi code) but in the future could 
    * allow users to select from any object mapping.
    */
    getObjectMappingOptions() {
        this.objectMappingOptions = [];

        for (let i = 0; i < this.objectMappings.length; i++) {
            if (this.objectMappings[i].Relationship_To_Predecessor === 'No Predecessor') {
                let objMappingOption = {
                    label: this.objectMappings[i].MasterLabel,
                    value: this.objectMappings[i].DeveloperName
                }
                this.objectMappingOptions.push(objMappingOption);
            }
        }
    }

    /*******************************************************************************
    * @description Dynamically determines what the valid relationship fields options are
    * for the picklist based on the values of the Object API Name field, the Relationship_To_Predcessor
    *  and the Predecessor object mapping.
    */
    getRelationshipFieldOptions() {
        var objectName;
        var lookupToObjectName;
        var predecessor;
        try {
            if (this.row.Object_API_Name && this.row.Relationship_To_Predecessor && this.row.Predecessor) {
                
                //Find the predecessor so we know how to filter the options.
                for (let i = 0; i < this.objectMappings.length; i++) {
                    if (this.objectMappings[i].DeveloperName === this.row.Predecessor) {
                        predecessor = this.objectMappings[i];
                    }
                }

                //Set the objects to be queried based on the type of relationship to predecessor.
                if (this.row.Relationship_To_Predecessor === 'Parent') {
                    objectName = predecessor.Object_API_Name;
                    lookupToObjectName = this.row.Object_API_Name;
                    
                } else if (this.row.Relationship_To_Predecessor === 'Child') {
                    objectName = this.row.Object_API_Name;
                    lookupToObjectName = predecessor.Object_API_Name;
                }
        
                if (objectName) {
                    this.isLoading = true;
                    getRelationshipFieldOptions({objectName: objectName, 
                                                lookupToObjectName: lookupToObjectName})
                    .then((data) => {
                        let relField = this.template.querySelector("[data-id='throughThisField']");

                        //If there are no valid options then null out the values in the list.
                        //Also null out any value in the Relationship Field since it must be invalid.
                        if (data.length === 0){
                            this.relationshipFieldOptions = null;
                            this.row.Relationship_Field = null;
                            this.isLoading = false;

                            relField.setCustomValidity(this.customLabels.bdiOMUIErrorNoValidThroughThisField);
                            relField.reportValidity();
                            
                            return;
                        }

                        relField.setCustomValidity('');

                        this.relationshipFieldOptions = [];

                        for (let i = 0; i < data.length; i++) {
                            let fieldInfo = data[i];
                            
                            let relFieldOption = {
                                label: fieldInfo.label + ' (' + fieldInfo.value + ')',
                                value: fieldInfo.value
                            }
                            this.relationshipFieldOptions.push(relFieldOption);
                        }

                        this.isLoading = false;
                    })
                    .catch((error) => {
                        this.isLoading = false;
                        this.handleError(error);
                    });
                }

            } else {
                //Clearing out the relationship field options, and clearing any value in the
                //Relationship Field so that it cannot be saved with a bad value.
                this.relationshipFieldOptions = null;
                this.row.Relationship_Field = null;
            }
        } catch(error) {
            this.handleError(error);
        }
    }

    /*******************************************************************************
    * @description Retrieves the field descriptions for the fields on the Data Import Object
    * and then calls 'refreshImportRecordFieldOptions' which determines which fields are available
    * for the ImportedRecordFieldName and ImportedRecordStatusField Name picklists.
    */    
    getDataImportFieldDescribes() {
        getObjectFieldDescribes({objectName: this._dataImportApiName,
                                includeReferenceToObjectList: true })
            .then((data) => {
                this.dataImportFieldData = data;
                this.refreshImportRecordFieldOptions();
            })
            .catch((error) => {
                this.handleError(error);
            });
    }

    /*******************************************************************************
    * @description Generates the picklist options for the for the ImportedRecordFieldName 
    * and ImportedRecordStatusField Name picklists.  It does this by by filtering the list
    * of Data Import fields to exclude those that are already mapped either to field or
    * object mappings as well as filtering by field type.
    */  
    refreshImportRecordFieldOptions() {
        this.diImportRecordFieldOptions = [];
        this.diImportRecordStatusFieldOptions = [];

        let fieldsToExclude = this.getAlreadyMappedDIFields(); 
        if (fieldsToExclude && this.dataImportFieldData) {
            
            for (let i = 0; i < this.dataImportFieldData.length; i++) {
                let fieldData = this.dataImportFieldData[i];

                if (!fieldsToExclude.has(fieldData.value.toLowerCase())) {
                    let labelOption = {
                        label: fieldData.label + ' (' + fieldData.value + ')',
                        value: fieldData.value
                    }
        
                    if (fieldData.value !== this.row.Imported_Record_Status_Field_Name) {

                        if (fieldData.displayType === 'REFERENCE' 
                            && fieldData.referenceToObjectList
                            && (this.row.Object_API_Name 
                                && fieldData.referenceToObjectList.includes(this.row.Object_API_Name.toLowerCase())
                                || !this.row.Object_API_Name)){

                            this.diImportRecordFieldOptions.push(labelOption);
                            
                        } else if (fieldData.displayType === 'STRING') {
                            this.diImportRecordFieldOptions.push(labelOption);
                        }
                    }
        
                    if (fieldData.value !== this.row.Imported_Record_Field_Name &&
                        (fieldData.displayType === 'TEXTAREA' || fieldData.displayType === 'STRING')) {
                        this.diImportRecordStatusFieldOptions.push(labelOption);
                    }
                }
            }

            let importedRecordField = this.template.querySelector("[data-id='importedRecordFieldName']");
            let importedRecordStatusField = this.template.querySelector("[data-id='importedRecordStatusFieldName']");

            if (importedRecordField) {
                if (this.diImportRecordFieldOptions.length === 0) {
                    importedRecordField.setCustomValidity(this.customLabels.bdiOMUIErrorNoUnmappedFieldsPt1 + 
                                                        ' ' + this.customLabels.bdiOMUILinkToRecordLabel + 
                                                        this.customLabels.bdiOMUIErrorNoUnmappedFieldsPt2);
                    importedRecordField.reportValidity();
                } else {
                    importedRecordField.setCustomValidity('');
                }
            }

            if (importedRecordStatusField) {
                if (this.diImportRecordStatusFieldOptions.length === 0) {
                    importedRecordStatusField.setCustomValidity(this.customLabels.bdiOMUIErrorNoUnmappedFieldsPt1 + 
                        ' ' + this.customLabels.bdiOMUIImportStatusLabel + 
                        this.customLabels.bdiOMUIErrorNoUnmappedFieldsPt2);
                    importedRecordStatusField.reportValidity();
                } else {
                    importedRecordStatusField.setCustomValidity('');
                }
            }
        }
    }

    /*******************************************************************************
    * @description Returns or creates and returns a map of all DI fields already mapped to import 
    * record fields or that are used in field mappings.  Also includes a static list of miscellaneous
    * fields that should always be excluded.             
    */
    getAlreadyMappedDIFields() {
        if (this.objectMappings && this.dataImportFieldMappingSourceNames) {

            this.alreadyMappedDIFieldsMap = new Map();

            // Making some baseline exclusions for DI system fields.
            for (let i = 0; i < this.excludedDIFields.length; i++) {
                let field = this.excludedDIFields[i].toLowerCase();

                if (this.namespace !== 'npsp') {
                    field = field.replace('npsp__','');
                }

                this.alreadyMappedDIFieldsMap.set(field,'');
            }

            // Add all of the DI field names used for Imported record info
            for (let i = 0; i < this.objectMappings.length; i++) {
                let tempObjMapping = this.objectMappings[i];

                if (tempObjMapping.Imported_Record_Field_Name 
                    && tempObjMapping.Imported_Record_Field_Name !== this.row.Imported_Record_Field_Name) {
                    this.alreadyMappedDIFieldsMap.set(tempObjMapping.Imported_Record_Field_Name.toLowerCase(),
                    tempObjMapping.MasterLabel);
                }

                if (tempObjMapping.Imported_Record_Status_Field_Name
                    && tempObjMapping.Imported_Record_Status_Field_Name !== this.row.Imported_Record_Status_Field_Name) {
                    this.alreadyMappedDIFieldsMap.set(tempObjMapping.Imported_Record_Status_Field_Name.toLowerCase(),
                    tempObjMapping.MasterLabel);
                }
            }

            // Add all the field names that have been mapped in field mappings
            for (let i = 0; i < this.dataImportFieldMappingSourceNames.length; i++) {
                this.alreadyMappedDIFieldsMap.set(this.dataImportFieldMappingSourceNames[i],'');
            }
        }
        return this.alreadyMappedDIFieldsMap;
    }

    /*******************************************************************************
    * @description Handles the change of the Object API Name field, and refreshes the
    * relationshipFieldOptions.           
    */
    handleObjectAPINameChange(event){
        this.row.Object_API_Name = event.detail.value;
        this.getRelationshipFieldOptions();
        this.refreshImportRecordFieldOptions();
    }

    /*******************************************************************************
    * @description Handles the change of the Relationship to Predecessor field, and refreshes the
    * relationshipFieldOptions.           
    */
    handleRelationshipToPredChange(event) {
        this.row.Relationship_To_Predecessor = event.detail.value;
        this.getRelationshipFieldOptions();
    }

    handleMasterLabelChange(event){
        this.row.MasterLabel = event.detail.value;
    }

    /*******************************************************************************
    * @description Handles the change of the Predecessor field, and refreshes the
    * relationshipFieldOptions.           
    */
    handlePredecessorChange(event) {
        this.row.Predecessor = event.detail.value;
        this.getRelationshipFieldOptions();
    }

    /*******************************************************************************
    * @description Handles the change of the Relationship field.
    */
    handleRelationshipFieldChange(event) {
        this.row.Relationship_Field = event.detail.value;
    }

    /*******************************************************************************
    * @description Handles the change of the Imported Record Field Name field, and refreshes the
    * Imported Record field options.           
    */
    handleImportedRecordFieldNameChange(event) {
        this.row.Imported_Record_Field_Name = event.detail.value;
        this.refreshImportRecordFieldOptions();
    }

    /*******************************************************************************
    * @description Handles the change of the Imported Record Status Field Name field, and refreshes the
    * Imported Record field options.           
    */
    handleImportedRecordStatusFieldNameChange(event) {
        this.row.Imported_Record_Status_Field_Name = event.detail.value;
        this.refreshImportRecordFieldOptions();
    }

    /*******************************************************************************
    * @description Defines the options available to the relationship to predecessor
    * field.        
    */
    get predRelationshipOptions() {
        return [
            { label: 'Child', value: 'Child' },
            { label: 'Parent', value: 'Parent' }
        ];
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
    * @description Creates and dispatches an error toast
    *
    * @param {object} error: Event holding error details
    */
    handleError(error) {
        if (error && error.status && error.body) {
            this.showToast(`${error.status} ${error.statusText}`, error.body.message, 'error', 'sticky');
        } else if (error && error.name && error.message) {
            this.showToast(`${error.name}`, error.message, 'error', 'sticky');
        } else {
            this.showToast(stgUnknownError, '', 'error', 'sticky');
        }
    }
}