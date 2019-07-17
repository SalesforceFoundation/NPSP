import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getObjectMappings from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.getObjectMappings';
import getObjectOptions from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.getObjectOptions';
import createDataImportObjectMapping
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.createDataImportObjectMapping';
import { registerListener, unregisterAllListeners, fireEvent} from 'c/pubsubNoPageRef';

/*
const normalActions = [
    { label: 'View Field Mappings', name: 'goToFieldMappings' },
    { label: 'Edit', name: 'edit' },
    { label: 'Delete', name: 'delete' },
];
*/
export default class bdiObjectMappings extends LightningElement {
    @track displayObjectMappings = true;
    @track isLoading = true;
    @track isModalOpen = false;
    @track columns = [];
    @api objectMapping;
    @api objectOptions;
    @track objectMappings;

    deploymentTimer;
    deploymentTimeout = 10000;

    @api diObjectMappingSetId;

    @api
    refresh() {
        console.log('in refresh outside of displayObjectMappings check.');
        if (this.displayObjectMappings) {
            console.log('in refresh');
            this.isLoading = true;
            this.retrieveObjectMappings();
        }
    }

    constructor() {
        super();
        this.columns =[
            {label: 'Mapping Group Name', fieldName: 'MasterLabel', type: 'text'},
            {label: 'Object API Name', fieldName: 'Object_API_Name', type: 'text'},
            {label: 'Is Child/Parent', fieldName: 'Relationship_To_Predecessor', type: 'text', fixedWidth: 150},
            {label: 'Of This Mapping Group', fieldName: 'Predecessor', type: 'text'},
            {label: 'Through This Field', fieldName: 'Relationship_Field', type: 'text'},
            {label: 'Imported Record Field Name', fieldName: 'Imported_Record_Field_Name', type: 'text'},
            {label: 'Imported Record Status Field Name', fieldName: 'Imported_Record_Status_Field_Name', type: 'text'},
            {type: 'action', typeAttributes: { rowActions: this.getRowActions }}];
    }

    handleNavButton() {
        fireEvent(this.pageRef, 'showfieldmappings');
    }

    connectedCallback() {
        registerListener('showobjectmappings', this.handleShowObjectMappings, this);
        registerListener('showfieldmappings', this.handleShowFieldMappings, this);
        registerListener('deploymentResponse', this.handleDeploymentResponse, this);
        registerListener('startDeploymentTimeout', this.handleDeploymentTimeout, this);
        registerListener('deleteRowFromTable', this.handleDeleteRowFromTable, this);
        registerListener('refresh', this.refresh, this);

        this.retrieveObjectMappings();
        this.retrieveObjectOptions();
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    /*******************************************************************************
    * @description Call apex method 'getObjectMappings' to get
    * a list of all non-deleted object mappings
    */
    retrieveObjectMappings() {
        console.log('in retrieveObjectMappings');
        getObjectMappings()
            .then((data) => {
                this.objectMappings = data;
                this.diObjectMappingSetId = this.objectMappings[0].Data_Import_Object_Mapping_Set;
                this.isLoading = false;
            })
            .catch((error) => {
                console.log(error);
                this.isLoading = false;
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
        console.log('bdiObjectMappings | handleRowAction()');
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        let rowString;
        switch (actionName) {
            case 'goToFieldMappings':
                console.log('GOTOFIELDMAPPING ACTION');
                fireEvent(this.pageRef,'showfieldmappings', {objectMapping:row});
                break;

            case 'delete':
                console.log('DELETE ACTION');
                console.log(this.log(row));
                this.isLoading = true;
                
                row.Is_Deleted = true;
                row.Data_Import_Object_Mapping_Set = 'Default_Object_Mapping_Set';

                rowString = JSON.stringify(row);

                createDataImportObjectMapping({objectMappingString: rowString})
                    .then((deploymentId) => {
                        console.log('Delete deployment Id is: ' + deploymentId);
                        this.handleDeleteDeploymentId(deploymentId);
                    })
                    .catch((error) => {
                        console.log(error);
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
                console.log('EDIT ACTION');
                console.log('Row: ', this.log(row));
                fireEvent(this.pageRef,'openModal', {
                    row: row });
                break;

            default:
        }
    }



    handleDeleteRowFromDatatable(row) {
        const { DeveloperName } = row;
        const index = this.findRowIndexById(DeveloperName);
        if (index !== -1) {
            this.objectMappings = this.objectMappings
                .slice(0, index)
                .concat(this.objectMappings.slice(index + 1));
        }
    }
    
    findRowIndexById(DeveloperName) {
        let ret = -1;
        this.objectMappings.some((row, index) => {
            if (row.DeveloperName === DeveloperName) {
                ret = index;
                return true;
            }
            return false;
        });
        return ret;
    }
    
    getRowActions(row, doneCallback) {
        const actions = [
            { label: 'View Field Mappings', name: 'goToFieldMappings' }
        ];

        if(row.Relationship_To_Predecessor !== 'No Predecessor'){
            actions.push({ label: 'Edit', name: 'edit' });
            actions.push({ label: 'Delete', name: 'delete' });
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
            console.log('inHandleDeploymentTimeout');
            this.deploymentTimer = setTimeout(function() {
                that.isLoading = false;
                console.log('ObjectMapping isLoading set to false on timeout');
                fireEvent(this.pageRef, 'closeModal', {});
                that.showToast(
                    'Mapping Group deployment is taking longer than expected.',
                    'Your deployment ({0}) will continue to process in the background.',
                    'warning',
                    'sticky',
                    [event.deploymentId]);
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
        console.log('In handleDeploymentResponse');
        if (this.displayObjectMappings) {
            console.log('In handleDeploymentResponse displayObjectMappings is true');
            clearTimeout(this.deploymentTimer);
            fireEvent(this.pageRef, 'refresh', {});
            fireEvent(this.pageRef, 'closeModal', {});

            const payload = platformEvent.response.data.payload;
            const status = payload.Status__c || payload.npsp__Status__c;
            const deploymentId = payload.DeploymentId__c || payload.npsp__DeploymentId__c;

            /*
            this.showToast(
                'Deployment completed with Status: ' + status,
                'Deployment Id: ' + deploymentId,
                'success');
                */
            if (status === 'Succeeded') {
                this.showToast(
                    'Deployment completed with Status: ' + status,
                    'Deployment Id: ' + deploymentId,
                    'success');
            } else {
                console.log('In handleDeploymentResponse displayObjectMappings is true');
                console.log
                this.showToast(
                    'Deployment completed with Status: ' + status,
                    'Deployment Id: ' + deploymentId,
                    'error');
            }
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

    // TODO: Delete later
    /*******************************************************************************
    * @description Parse proxy objects for debugging, mutating, etc
    *
    * @param object: Object to be parsed
    */
    log(object) {
        return JSON.parse(JSON.stringify(object));
    }

    logBold(string) {
        return console.log('%c ' + string, 'font-weight: bold; font-size: 16px;');
    }
}