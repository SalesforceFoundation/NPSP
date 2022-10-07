import { LightningElement, track, api } from 'lwc';
import getAdvancedMappingObjectData from
        '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.getAdvancedMappingObjectData';
import createDataImportObjectMapping
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.createDataImportObjectMapping';
import { registerListener, unregisterAllListeners, fireEvent} from 'c/pubsubNoPageRef';
import { getNamespace, showToast, isNull } from 'c/utilCommon';

import stgUnknownError from '@salesforce/label/c.stgUnknownError';
import bdiOMUIChildParentLabel from '@salesforce/label/c.bdiOMUIChildParentLabel';
import bdiOMUIGroupNameLabel from '@salesforce/label/c.bdiOMUIGroupNameLabel';
import bdiOMUIImportStatusLabel from '@salesforce/label/c.bdiOMUIImportStatusLabel';
import bdiOMUILinkToRecordLabel from '@salesforce/label/c.bdiOMUILinkToRecordLabel';
import bdiOMUIObjectNameLabel from '@salesforce/label/c.bdiOMUIObjectNameLabel';
import bdiOMUIOfGroupLabel from '@salesforce/label/c.bdiOMUIOfGroupLabel';
import bdiOMUIThroughFieldLabel from '@salesforce/label/c.bdiOMUIThroughFieldLabel';
import bdiFMUISuccessful from '@salesforce/label/c.bdiFMUISuccessful';
import bdiFMUIUnsuccessful from '@salesforce/label/c.bdiFMUIUnsuccessful';
import bdiFMUIUpdate from '@salesforce/label/c.bdiFMUIUpdate';
import bdiFMUITryAgain from '@salesforce/label/c.bdiFMUITryAgain';

import bdiAdvancedMapping from '@salesforce/label/c.bdiAdvancedMapping';
import bdiOMUICreateNewObjectGroup from '@salesforce/label/c.bdiOMUICreateNewObjectGroup';
import bdiOMUIObjectGroupsTitle from '@salesforce/label/c.bdiOMUIObjectGroupsTitle';
import bdiOMUIPageDescriptionPt1 from '@salesforce/label/c.bdiOMUIPageDescriptionPt1';
import bdiOMUIPageDescriptionPt2 from '@salesforce/label/c.bdiOMUIPageDescriptionPt2';
import bdiOMUIPageDescriptionPt3 from '@salesforce/label/c.bdiOMUIPageDescriptionPt3';
import bdiOMUIViewFieldMappingsLabel from '@salesforce/label/c.bdiOMUIViewFieldMappingsLabel';
import bgeActionDelete from '@salesforce/label/c.bgeActionDelete';
import stgBtnEdit from '@salesforce/label/c.stgBtnEdit';

import bdiOMUILongDeployment from '@salesforce/label/c.bdiOMUILongDeployment';
import bdiFMUILongDeploymentLink from '@salesforce/label/c.bdiFMUILongDeploymentLink';
import bdiFMUILongDeploymentMessage from '@salesforce/label/c.bdiFMUILongDeploymentMessage';
import bdiOMUIFieldMappingProblemHeader from '@salesforce/label/c.bdiOMUIFieldMappingProblemHeader';
import bdiOMUIFieldMappingProblemMessagePart1 from '@salesforce/label/c.bdiOMUIFieldMappingProblemMessagePart1';
import bdiOMUIFieldMappingProblemMessagePart2 from '@salesforce/label/c.bdiOMUIFieldMappingProblemMessagePart2';
import DATA_IMPORT from '@salesforce/schema/DataImport__c';
const NPSP_SETTINGS_URL = '/lightning/n/NPSP_Settings';

export default class bdiObjectMappings extends LightningElement {
    @api shouldRender;
    @track brokenMappings = [];
    displayObjectMappings = true;
    isLoading = true;
    isModalOpen = false;
    columns = [];
    objectMappings;
    objectMapping;
    objectOptions;
    deploymentTimer;
    deploymentTimeout = 10000;
    diObjectMappingSetDevName;

    
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
        bdiAdvancedMapping,
        bdiOMUICreateNewObjectGroup,
        bdiOMUIObjectGroupsTitle,
        bdiOMUIPageDescriptionPt1,
        bdiOMUIPageDescriptionPt2,
        bdiOMUIPageDescriptionPt3,
        bdiOMUIViewFieldMappingsLabel,
        bgeActionDelete,
        stgBtnEdit,
        bdiOMUILongDeployment,
        bdiFMUILongDeploymentLink,
        bdiFMUILongDeploymentMessage,
        bdiOMUIFieldMappingProblemHeader,
        bdiOMUIFieldMappingProblemMessagePart1,
        bdiOMUIFieldMappingProblemMessagePart2
    };

    constructor() {
        super();
        this.columns =[
            {label: this.customLabels.bdiOMUIGroupNameLabel, fieldName: 'MasterLabel', type: 'text'},
            {label: this.customLabels.bdiOMUIObjectNameLabel, fieldName: 'Object_API_Name', type: 'text'},
            {label: this.customLabels.bdiOMUIChildParentLabel, fieldName: 'Relationship_To_Predecessor', type: 'text', fixedWidth: 150},
            {label: this.customLabels.bdiOMUIOfGroupLabel, fieldName: 'Predecessor_Label_Name', type: 'text'},
            {label: this.customLabels.bdiOMUIThroughFieldLabel, fieldName: 'Relationship_Field', type: 'text'},
            {label: this.customLabels.bdiOMUILinkToRecordLabel, fieldName: 'Imported_Record_Field_Name', type: 'text'},
            {label: this.customLabels.bdiOMUIImportStatusLabel, fieldName: 'Imported_Record_Status_Field_Name', type: 'text'},
            {type: 'action', typeAttributes: { rowActions: this.getRowActions }}];
    }

    /*******************************************************************************
    * @description Called when the component is first loaded to set up listeners and 
    * prepare data.
    */
    connectedCallback() {
        registerListener('showobjectmappings', this.handleShowObjectMappings, this);
        registerListener('deploymentResponse', this.handleDeploymentResponse, this);
        registerListener('startDeploymentTimeout', this.handleDeploymentTimeout, this);
        registerListener('refresh', this.refresh, this);
        this.retrieveAdvancedMappingObjectData();
    }

    /*******************************************************************************
    * @description Called when the component is unloaded to unregister event listeners.
    */
    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    get namespace() {
        return getNamespace(DATA_IMPORT.objectApiName);
    }

    get npspSettingsURL () {
        return !isNull(this.namespace) ? NPSP_SETTINGS_URL.replace(
            'n/', `n/${this.namespace}__`) : NPSP_SETTINGS_URL;
    }

    get namespaceWrapper () {
        return {
            currentNamespace : this.namespace,
            npspNamespace: this.namespace
        };
    }

    /*******************************************************************************
    * @description Refreshes object mappings data.  Usually called after save/delete.
    */
    refresh() {
        if (this.displayObjectMappings) {
            this.isLoading = true;
            this.retrieveAdvancedMappingObjectData();
        }
    }

    /*******************************************************************************
    * @description Call apex method 'getObjectMappings' to get
    * a list of all non-deleted object mappings
    */
    retrieveAdvancedMappingObjectData() {
        getAdvancedMappingObjectData()
            .then((data) => {
                this.processBrokenMappingReferences(data.objectMappings);
                this.objectOptions = data.objectOptions;
                this.objectMappings = data.objectMappings;
                this.diObjectMappingSetDevName = data.objectMappings[0].
                        Data_Import_Object_Mapping_Set_Dev_Name;
                this.isLoading = false;
            })
            .catch((error) => {
                this.isLoading = false;
                this.handleError(error);
            });
    }

    /**
     * @description Extracts broken field mapping references from retrieved
     * object mappings
     * @param objectMappings
     */
    processBrokenMappingReferences (objectMappings) {
        this.brokenMappings = [];
        objectMappings.forEach(mapping => {
            if (mapping.hasOwnProperty('Field_Mappings')) {
                mapping.Field_Mappings.forEach(fieldMapping => {
                    this.brokenMappings.push(
                        `${mapping.MasterLabel} : ${fieldMapping.MasterLabel} (${fieldMapping.Target_Field_API_Name})`);

                });
            }
        });
    }

    
    /*******************************************************************************
    * @description shows the object mappings component and refreshes the data
    */
    handleShowObjectMappings() {
        this.displayObjectMappings = true;
        this.refresh();
    }


    get hasBrokenMetadataReferences () {
        return this.brokenMappings.length > 0;
    }

    get brokenFieldReferencesWarningMessage () {
        return `${this.customLabels.bdiOMUIFieldMappingProblemMessagePart1} ${this.customLabels.bdiOMUIFieldMappingProblemMessagePart2}`
    }

    /*******************************************************************************
    * @description Opens the object mapping modal passing in the relevant details
    */
    handleOpenModal() {
        if (this.displayObjectMappings) {
            fireEvent(this.pageRef, 'openModal', 
            { objectMapping: null, row: undefined });
        }
    }

    /*******************************************************************************
    * @description Action handler for datatable row actions (i.e. edit, delete)
    *
    * @param event: Event containing row details of the action
    */
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        let rowString;
        switch (actionName) {
            case 'goToFieldMappings':
                this.displayObjectMappings = false;
                fireEvent(this.pageRef,'showfieldmappings', {objectMapping:row});
                break;

            case 'delete':
                this.isLoading = true;
                
                row.Is_Deleted = true;
                row.Data_Import_Object_Mapping_Set = this.diObjectMappingSetDevName;

                rowString = JSON.stringify(row);

                createDataImportObjectMapping({objectMappingString: rowString})
                    .then((deploymentId) => {
                        this.handleDeleteDeploymentId(deploymentId);
                    })
                    .catch((error) => {
                        this.isLoading = false;
                        showToast(
                            'Error',
                            '{0}. {1}. {2}.',
                            'error',
                            'sticky',
                            [error.body.exceptionType, error.body.message, error.body.stackTrace]);
                    });
                break;

            case 'edit':
                fireEvent(this.pageRef,'openModal', {
                    row: row });
                break;

            default:
        }
    }

    /*******************************************************************************
    * @description Dynamically gets the appropriate row actions depending on whether 
    * it is a core object mapping.
    */
    getRowActions(row, doneCallback) {
        const actions = [
            { label: bdiOMUIViewFieldMappingsLabel, name: 'goToFieldMappings' }
        ];

        if (row.Relationship_To_Predecessor !== 'No Predecessor'
            && row.MasterLabel !== 'Opportunity Contact Role 1' 
            && row.MasterLabel !== 'Opportunity Contact Role 2' 
            && row.MasterLabel !== 'GAU Allocation 1' 
            && row.MasterLabel !== 'GAU Allocation 2') {
            actions.push({ label: stgBtnEdit, name: 'edit' });
            actions.push({ label: bgeActionDelete, name: 'delete' });
        }

        setTimeout(() => {
            doneCallback(actions); 
        }, 0);
    }
    
    /*******************************************************************************
    * @description Handles the timeout toast of deployments whenever a deployment
    * that's registered with platformEventListener takes 10 seconds or longer to
    * send out a response.
    */
    handleDeploymentTimeout(event) {
        if (this.displayObjectMappings) {
            let that = this;
            this.deploymentTimer = setTimeout(function() {
                that.isLoading = false;
                fireEvent(this.pageRef, 'closeModal', {});

                let url =
                    '/lightning/setup/DeployStatus/page?' +
                    'address=%2Fchangemgmt%2FmonitorDeploymentsDetails.apexp%3FasyncId%3D' +
                    event.deploymentId +
                    '%26retURL%3D%252Fchangemgmt%252FmonitorDeployment.apexp';

                showToast(
                    bdiOMUILongDeployment,
                    bdiFMUILongDeploymentMessage + ' {0}',
                    'warning',
                    'sticky',
                    [{url, label: bdiFMUILongDeploymentLink}]);
            }, this.deploymentTimeout, that);
        }
    } 

    /*******************************************************************************
    * @description Listens for an event from the platformEventListener component.
    * Upon receiving an event refreshes the field mappings records, closes the modal,
    * and creates a toast.
    *
    * @param {object} platformEvent: Object containing the platform event payload
    */
    handleDeploymentResponse(platformEvent) {
        if (this.displayObjectMappings) {
            clearTimeout(this.deploymentTimer);
            fireEvent(this.pageRef, 'refresh', {});
            fireEvent(this.pageRef, 'closeModal', {});

            const payload = platformEvent.response.data.payload;
            const status = payload.Status__c || payload.npsp__Status__c;

            const successful = bdiFMUISuccessful.charAt(0).toUpperCase() + bdiFMUISuccessful.slice(1);
            const unsuccessful = bdiFMUIUnsuccessful.charAt(0).toUpperCase() + bdiFMUIUnsuccessful.slice(1);
            const successMessage = `${successful} ${bdiOMUIObjectGroupsTitle} ${bdiFMUIUpdate}.`;
            const failMessage = `${unsuccessful} ${bdiOMUIObjectGroupsTitle} ${bdiFMUIUpdate}. ${bdiFMUITryAgain}.`;
            const succeeded = status === 'Succeeded';
            
            showToast(
                `${succeeded ? successMessage : failMessage}`,
                '',
                succeeded ? 'success' : 'error','',[]);
        }
    }
    /*******************************************************************************
    * @description Creates and dispatches a CustomEvent 'deployment' for deletion
    * letting the platformEventListener know that we have an id to register and monitor.
    * After dispatching the CustomEvent, start the deployment timeout.
    *
    * @param {string} deploymentId: Custom Metadata Deployment Id
    */
    handleDeleteDeploymentId(deploymentId) {
        if (this.displayObjectMappings) {
            const deploymentEvent = new CustomEvent('deployment', {
                bubbles: true,
                composed: true,
                detail: {deploymentId}
            });
            this.dispatchEvent(deploymentEvent);

            this.handleDeploymentTimeout({ deploymentId: deploymentId });
        }
    }

    /*******************************************************************************
    * @description Creates and dispatches an error toast
    *
    * @param {object} error: Event holding error details
    */
    handleError(error) {
        if (error && error.status && error.body) {
            showToast(`${error.status} ${error.statusText}`, error.body.message, 'error', 'sticky');
        } else if (error && error.name && error.message) {
            showToast(`${error.name}`, error.message, 'error', 'sticky');
        } else {
            showToast(stgUnknownError, '', 'error', 'sticky');
        }
    }
}