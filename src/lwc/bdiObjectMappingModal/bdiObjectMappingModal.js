import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createDataImportObjectMapping
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.createDataImportObjectMapping';
import getObjectFieldDescribes
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.getObjectFieldDescribes';
import getRelationshipFieldOptions
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.getRelationshipFieldOptions';
import { registerListener, unregisterAllListeners, fireEvent }
    from 'c/pubsubNoPageRef';


export default class bdiObjectMappingModal extends LightningElement {
    @api objectMappings;
    @api objectOptions;
    @api isModalOpen = false;
    @api diObjectMappingSetId;

    @track isLoading;
    @track row;

    @track modalTitle;

    @track diImportRecordFieldOptions;
    @track diImportRecordStatusFieldOptions;
    @track objectMappingOptions;
    @track relationshipFieldOptions;

    @track hasObjectNameErrors;

    constructor() {
        super();
        //this.escapeFunction = this.escapeFunction.bind(this);
    }

    get isRelationshipFieldDisabled() {
        console.log('In isRelationshipField disabled');
        if (this.row.Relationship_Field || this.relationshipFieldOptions ) {
            console.log('returning false');
            return false;
        }
        console.log('returning true');
        return true;
    }

    get sectionClasses() {
        return this.isModalOpen ? 'slds-modal slds-fade-in-open' : 'slds-modal slds-hidden';
    }

    get backdropClasses() {
        return this.isModalOpen ? 'slds-backdrop slds-backdrop_open' : 'slds-backdrop';
    }

    connectedCallback() {
        document.addEventListener("keydown", this.escapeFunction, false);
        registerListener('openModal', this.handleOpenModal, this);
        registerListener('closeModal', this.handleCloseModal, this);
        registerListener('objectNameChange',this.handleObjectAPINameChange,this);
        this.setDefaultValues();
        console.log('In connected Callback');
        this.handleGetDataImportFieldDescribes();
        console.log('In connected Callback after describes');
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
        console.log('In bdiObjectMappings handleCloseModal');
        this.isModalOpen = false;
    }

    /*******************************************************************************
    * @description Handles the open modal event from bdiObjectMappings and allows
    * for SLDS classes to fade in modal elements and backdrop
    *
    * @param event: Event containing row details or lack of row details
    */
    handleOpenModal(event) {
        this.logBold('bdiObjectMappingModal | handleOpenModal()');
        this.isModalOpen = true;
        this.isLoading = true;
        let that = this;
        let data = event;
        
        console.log('before load modal data');
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
        this.logBold('bdiObjectMappingModal | loadModalData()');

        this.getObjectMappingOptions();
        console.log('mapping data.row');
        console.log(data.row);
        if (data.row) {
            // Edit
            console.log('Edit');        
            this.row = JSON.parse(JSON.stringify(data.row));
            this.row.Data_Import_Object_Mapping_Set = 'Default_Object_Mapping_Set';
            this.modalTitle = 'Edit Mapping Group';
            console.log(this.row);
            this.getRelationshipFieldOptions();

        } else {
            //New Object mapping
            this.setDefaultValues();
            this.modalTitle = 'Create Mapping Group';
        }

        console.log('Set isLoading to false');
        this.isLoading = false;
    }

    setDefaultValues() {
        this.row = {Id: null,
            MasterLabel: null,
            Custom_Mapping_Logic_Class: null,
            DeveloperName: null, 
            Data_Import_Object_Mapping_Set: 'Default_Object_Mapping_Set', 
            Imported_Record_Field_Name: null,
            //Imported_Record_Field_Name_Label: null,
            Imported_Record_Status_Field_Name: null,
            //Imported_Record_Status_Field_Name_Label: '',
            Object_API_Name: null,
            Predecessor: null,
            //Predecessor_Label: '',
            Relationship_Field: null,
            //Relationship_Field_Label: '',
            Relationship_To_Predecessor: null };
    }

    handleSave() {
        this.logBold('bdiObjectMappingModal | handleSave()');
        this.isLoading = true;
        let rowString;
        console.log('in handle save row is:');
        console.log(this.row);
        if (this.row) {

            console.log('in handle save row after mapping:');
            console.log(this.row);

            rowString = JSON.stringify(this.row);

            createDataImportObjectMapping({objectMappingString: rowString})
            .then((deploymentId) => {
                console.log('post createDataImportObjectMapping with data');
                //console.log(this.log(data));
                console.log('deployment Id: ' + deploymentId);
                this.handleDeploymentId(deploymentId);
            })
            .catch((error) => {
                console.log('Error Encountered during object save');
                console.log(this.log(error));
                console.log(error);
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
    }

    /*******************************************************************************
    * @description Creates and dispatches a CustomEvent 'deployment' letting the
    * platformEventListener know that we have an id to register and monitor. After
    * dispatching the CustomEvent, start the deployment timeout on bdiFieldMappings.
    *
    * @param {string} deploymentId: Custom Metadata Deployment Id
    */
    handleDeploymentId(deploymentId) {
        console.log('Inside handleDeploymentId');
        const deploymentEvent = new CustomEvent('deployment', {
            bubbles: true,
            composed: true,
            detail: {deploymentId}
        });
        this.dispatchEvent(deploymentEvent);
        console.log('Inside handleDeploymentId after dispatch event');
        fireEvent(this.pageRef, 'startDeploymentTimeout', { deploymentId: deploymentId });
    }

    getObjectMappingOptions() {
        this.objectMappingOptions = [];
        for (let i = 0; i < this.objectMappings.length; i++) {
            if (this.objectMappings[i].Relationship_To_Predecessor === 'No Predecessor') {
                let objMappingOption = {
                    label: this.objectMappings[i].MasterLabel + ' (' + this.objectMappings[i].DeveloperName + ')',
                    value: this.objectMappings[i].DeveloperName
                }
                this.objectMappingOptions.push(objMappingOption);
            }

        }
    }

    getRelationshipFieldOptions() {
        var objectName;
        var lookupToObjectName;
        var predecessor;
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

                    //If there are no valid options then null out the values in the list.
                    if (data.length === 0){
                        this.relationshipFieldOptions = null;
                        this.isLoading = false;
                        this.showToast(
                            'Warning',
                            'There are no valid lookup fields to choose from for this combination ' +
                            '\'of Object Name\', \'Is Child/Parent\', and \'Of This Mapping Group\'.  Please change '+
                            'one of those fields to try again.',
                            'warning',
                            'sticky',
                            null);
                        return;
                    }
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
                    console.log(error);
                });
            }

        } else {
            this.relationshipFieldOptions = null;
        }
    }

   handleGetDataImportFieldDescribes() {
    getObjectFieldDescribes({objectName: 'DataImport__c'})
        .then((data) => {
            this.diImportRecordFieldOptions = [];
            this.diImportRecordStatusFieldOptions = [];

            let diFieldsByLabel = {}, diFieldsByAPIName = {};

            for (let i = 0; i < data.length; i++) {
                console.log('data label is: ' + data[i].label);
                console.log('data displayType is: ' + data[i].displayType);
                let labelOption = {
                    label: data[i].label + ' (' + data[i].value + ')',
                    value: data[i].value
                }

                if (data[i].displayType === 'REFERENCE' || data[i].displayType === 'STRING') {
                    this.diImportRecordFieldOptions.push(labelOption);
                }

                if (data[i].displayType === 'TEXTAREA' || data[i].displayType === 'STRING') {
                    this.diImportRecordStatusFieldOptions.push(labelOption);
                }

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

    handleObjectAPINameChange(event){
        this.row.Object_API_Name = event.detail.value;
        this.getRelationshipFieldOptions();
    }

    handleRelationshipToPredChange(event) {
        this.row.Relationship_To_Predecessor = event.detail.value;
        this.getRelationshipFieldOptions();
    }

    handleMasterLabelChange(event){
        this.row.MasterLabel = event.detail.value;
    }

    handlePredecessorChange(event) {
        this.row.Predecessor = event.detail.value;
        this.getRelationshipFieldOptions();
    }

    handleRelationshipFieldChange(event) {
        this.row.Relationship_Field = event.detail.value;
    }

    handleImportedRecordFieldNameChange(event) {
        this.row.Imported_Record_Field_Name = event.detail.value;
    }

    handleImportedRecordStatusFieldNameChange(event) {
        this.row.Imported_Record_Status_Field_Name = event.detail.value;
    }

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
        console.log('Error: ', error);
        if (error && error.status && error.body) {
            this.showToast(`${error.status} ${error.statusText}`, error.body.message, 'error', 'sticky');
        } else if (error && error.name && error.message) {
            this.showToast(`${error.name}`, error.message, 'error', 'sticky');
        } else {
            this.showToast(stgUnknownError, '', 'error', 'sticky');
        }
    }

    /*******************************************************************************
    * @description Sorts a list by a property
    *
    * @param {array} list: List to be sorted
    * @param {string} sortedBy: Property to sort by
    */
    sortBy(list, sortedBy) {
        return list.sort((a, b) => { return (a[sortedBy] > b[sortedBy]) ? 1 : -1} );
    }


}