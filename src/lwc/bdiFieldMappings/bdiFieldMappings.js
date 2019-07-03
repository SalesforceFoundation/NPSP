import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { registerListener, unregisterAllListeners, fireEvent} from 'c/pubsubNoPageRef';
import getFieldMappingsByObjectAndFieldSetNames
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.getFieldMappingsByObjectAndFieldSetNames';
import createDataImportFieldMapping
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.createDataImportFieldMapping';

const actions = [
    { label: 'Edit', name: 'edit' },
    { label: 'Delete', name: 'delete' },
];

const columns = [
    { label: 'Field Label', fieldName: 'xxx_Source_Field_Label_xxx', type: 'text', sortable: true },
    { label: 'Field API Name', fieldName: 'xxx_Source_Field_API_Name_xxx', type: 'text' },
    { label: 'Data Type', fieldName: 'xxx_Source_Field_Data_Type_xxx', type: 'text' },
        {
            label: 'Maps To', fieldName: '', type: 'text',
            cellAttributes: { iconName: { fieldName: 'Maps_To_Icon' }, iconPosition: 'right' }
        },
    { label: 'Field Label', fieldName: 'xxx_Target_Field_Label_xxx', type: 'text' },
    { label: 'Field API Name', fieldName: 'xxx_Target_Field_API_Name_xxx', type: 'text' },
    { label: 'Data Type', fieldName: 'xxx_Target_Field_Data_Type_xxx', type: 'text' },
    { type: 'action', typeAttributes: { rowActions: actions } }
];

export default class bdiFieldMappings extends LightningElement {
    @track displayFieldMappings = false;
    @track isLoading = true;
    @track columns = columns;
    @api objectMapping;
    @track fieldMappings;
    @track deploymentTimer;
    @api deploymentTimeout = 5000;

    @api
    refresh() {
        this.isLoading = true;
        this.handleFieldMappings();
    }

    handleNavButton() {
        fireEvent(this.pageRef, 'showobjectmappings');
    }

    connectedCallback() {
        this.logBold('bdiFieldMappings | connectedCallback()');
        registerListener('showobjectmappings', this.handleShowObjectMappings, this);
        registerListener('showfieldmappings', this.handleShowFieldMappings, this);
        registerListener('deploymentResponse', this.handleDeploymentResponse, this);
        registerListener('startDeploymentTimeout', this.handleDeploymentTimeout, this);
        registerListener('refresh', this.refresh, this);

        if (this.objectMapping) {
            this.handleFieldMappings();
        }
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    handleDeploymentTimeout(event) {
        let that = this;
        this.deploymentTimer = setTimeout(function() {
            that.isLoading = false;
            fireEvent(this.pageRef, 'closeModal', {});
            that.showToast(
                'Field Mapping deployment is taking longer than expected.',
                'Your deployment ({0}) will continue to process in the background.',
                'warning',
                'sticky',
                [event.deploymentId]);
        }, this.deploymentTimeout, that);
    }

    handleDeploymentResponse(platformEvent) {
        console.log('handleDeploymentResponse()');
        clearTimeout(this.deploymentTimer);
        fireEvent(this.pageRef, 'refresh', {});
        fireEvent(this.pageRef, 'closeModal', {});

        const status =
            platformEvent.response.data.payload.Status__c || platformEvent.response.data.payload.npsp__Status__c;
        const deploymentId =
            platformEvent.response.data.payload.DeploymentId__c || platformEvent.response.data.payload.npsp__DeploymentId__c;
        console.log('Creating toast event');
        const evt = new ShowToastEvent({
            title: 'Deployment completed with Status: ' + status,
            message: 'Deployment Id: ' + deploymentId,
            variant: 'success',
        });
        this.dispatchEvent(evt);
        console.log('Toast event dispatched');
    }

    handleShowObjectMappings() {
        this.displayFieldMappings = false;
    }

    handleShowFieldMappings(event) {
        this.objectMapping = event.objectMapping;
        this.displayFieldMappings = true;
        this.refresh();
    }

    handleOpenModal() {
        fireEvent(this.pageRef, 'openModal', {
            objectMapping: this.objectMapping,
            row: undefined,
            fieldMappings: this.fieldMappings
        });
    }

    /*******************************************************************************
    * @description Call apex method 'getFieldMappingsByObjectMappingName' to get
    * a list of field mappings by their parent object mapping name
    *
    * @param name: Name of the object mapping received from parent component 
    */
    handleFieldMappings() {
        //this.logBold('bdiFieldMappings | handleFieldMappings()');
        getFieldMappingsByObjectAndFieldSetNames({
                objectName: this.objectMapping.DeveloperName})
            .then((data) => {
                this.fieldMappings = data;
                this.isLoading = false;
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

    /*******************************************************************************
    * @description Action handler for datatable row actions (i.e. edit, delete)
    *
    * @param event: Event containing row details of the action
    */
    handleRowAction(event) {
        //this.logBold('bdiFieldMappings | handleRowAction()');
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {

            case 'delete':
                this.isLoading = true;
                row.xxx_Is_Deleted_xxx = true;
                let clonedRow = JSON.stringify(row);

                createDataImportFieldMapping({fieldMappingString: clonedRow})
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
                fireEvent(this.pageRef, 'openModal', {
                    objectMapping: this.objectMapping,
                    row: row,
                    fieldMappings: this.fieldMappings
                });
                break;

            default:
        }
    }

    handleDeleteDeploymentId(deploymentId) {
        //tell our parent element that we have an Id to monitor
        const deploymentEvent = new CustomEvent('deployment', {
            bubbles: true,
            composed: true,
            detail: {deploymentId}
        });
        this.dispatchEvent(deploymentEvent);

        this.deploymentTimeout({ deploymentId: deploymentId });
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
    log(object) {
        return JSON.parse(JSON.stringify(object));
    }

    logBold(string) {
        return console.log('%c ' + string, 'font-weight: bold; font-size: 16px;');
    }
}