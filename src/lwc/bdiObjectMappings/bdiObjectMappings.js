import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getObjectMappings from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.getObjectMappings';
import getObjectOptions from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.getObjectOptions';
import createDataImportObjectMapping
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.createDataImportObjectMapping';
import { registerListener, unregisterAllListeners, fireEvent} from 'c/pubsubNoPageRef';
import getNamespacePrefix
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.getNamespacePrefix';

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
import stgHelpAdvancedMapping3 from '@salesforce/label/c.stgHelpAdvancedMapping3';

import bdiOMUILongDeployment from '@salesforce/label/c.bdiOMUILongDeployment';
import bdiFMUILongDeploymentLink from '@salesforce/label/c.bdiFMUILongDeploymentLink';
import bdiFMUILongDeploymentMessage from '@salesforce/label/c.bdiFMUILongDeploymentMessage';

export default class bdiObjectMappings extends LightningElement {
    @track displayObjectMappings = true;
    @track isLoading = true;
    @track isModalOpen = false;
    @track columns = [];
    @api objectMapping;
    @api objectOptions;
    @track objectMappings;

    namespace;
    @track npspSettingsURL = '/lightning/n/npsp__NPSP_Settings';  

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
        stgHelpAdvancedMapping3,
        bdiOMUILongDeployment,
        bdiFMUILongDeploymentLink,
        bdiFMUILongDeploymentMessage
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
        registerListener('showfieldmappings', this.handleShowFieldMappings, this);
        registerListener('deploymentResponse', this.handleDeploymentResponse, this);
        registerListener('startDeploymentTimeout', this.handleDeploymentTimeout, this);
        registerListener('refresh', this.refresh, this);

        this.retrieveObjectMappings();
        this.retrieveObjectOptions();
        this.getPackageNamespace();
    }

    /*******************************************************************************
    * @description Called when the component is unloaded to unregister event listeners.
    */
    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    /*******************************************************************************
    * @description retrieves the namespace prefix
    */
    getPackageNamespace() {
        getNamespacePrefix()
            .then((data) => {
                this.namespace = data;

                //if we are not in a namespaced npsp org then remove the prefix from
                //the page url.
                if (this.namespace !== 'npsp') {
                    this.npspSettingsURL = this.npspSettingsURL.replace('npsp__','');
                }
            })
            .catch((error) => {
                this.handleError(error);
            });        
    }

    /*******************************************************************************
    * @description Refreshes object mappings data.  Usually called after save/delete.
    */
    @api
    refresh() {
        if (this.displayObjectMappings) {
            this.isLoading = true;
            this.retrieveObjectMappings();
        }
    }

    /*******************************************************************************
    * @description Call apex method 'getObjectMappings' to get
    * a list of all non-deleted object mappings
    */
    retrieveObjectMappings() {
        getObjectMappings()
            .then((data) => {
                this.objectMappings = data;
                this.diObjectMappingSetDevName = this.objectMappings[0].Data_Import_Object_Mapping_Set_Dev_Name;
                this.isLoading = false;
            })
            .catch((error) => {
                this.isLoading = false;
                this.handleError(error);
            });
    }

    /*******************************************************************************
    * @description Call apex method 'getObjectOptions' to get
    * a list of all objects that will be valid for creating object mappings on.
    */
    retrieveObjectOptions() {
        getObjectOptions()
            .then(result => {
                this.objectOptions = result;
            })
            .catch(error => {
                this.error = error;
                this.handleError(error);
            });
    }
    
    /*******************************************************************************
    * @description shows the object mappings component and refreshes the data
    */
    handleShowObjectMappings() {
        this.displayObjectMappings = true;
        this.refresh();
    }

    /*******************************************************************************
    * @description Shows the field mappings component and passes in the selected
    * object mapping.
    */
    handleShowFieldMappings(event) {
        this.objectMapping = event.objectMapping;
        this.displayObjectMappings = false;
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
                        this.showToast(
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
        console.log('customlabel is: ' + bdiOMUIViewFieldMappingsLabel);
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
            console.log('in bdiFieldMappings handleDeploymentResponse');
            let that = this;
            this.deploymentTimer = setTimeout(function() {
                that.isLoading = false;
                fireEvent(this.pageRef, 'closeModal', {});

                let url =
                    '/lightning/setup/DeployStatus/page?' +
                    'address=%2Fchangemgmt%2FmonitorDeploymentsDetails.apexp%3FasyncId%3D' +
                    event.deploymentId +
                    '%26retURL%3D%252Fchangemgmt%252FmonitorDeployment.apexp';

                that.showToast(
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
            
            this.showToast(
                `${succeeded ? successMessage : failMessage}`,
                '',
                succeeded ? 'success' : 'error');
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