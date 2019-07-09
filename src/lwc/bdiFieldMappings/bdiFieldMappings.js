import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { registerListener, unregisterAllListeners, fireEvent} from 'c/pubsubNoPageRef';
import getFieldMappingSetName
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.getFieldMappingSetName';
import getFieldMappingsByObjectAndFieldSetNames
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.getFieldMappingsByObjectAndFieldSetNames';
import createDataImportFieldMapping
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.createDataImportFieldMapping';
import getObjectFieldDescribes
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.getObjectFieldDescribes';

const actions = [
    { label: 'Edit', name: 'edit' },
    { label: 'Delete', name: 'delete' },
];

const columns = [
    { label: 'Field Label', fieldName: 'xxx_Source_Field_Label_xxx', type: 'text', sortable: true },
    { label: 'Field API Name', fieldName: 'xxx_Source_Field_API_Name_xxx', type: 'text' },
    { label: 'Data Type', fieldName: 'xxx_Source_Field_Data_Type_xxx', type: 'text', fixedWidth: 125 },
        {
            label: 'Maps To', fieldName: '', type: 'text', fixedWidth: 95,
            cellAttributes: { iconName: { fieldName: 'Maps_To_Icon' }, iconPosition: 'right' }
        },
    { label: 'Field Label', fieldName: 'xxx_Target_Field_Label_xxx', type: 'text' },
    { label: 'Field API Name', fieldName: 'xxx_Target_Field_API_Name_xxx', type: 'text' },
    { label: 'Data Type', fieldName: 'xxx_Target_Field_Data_Type_xxx', type: 'text', fixedWidth: 125 },
    { type: 'action', typeAttributes: { rowActions: actions } }
];

export default class bdiFieldMappings extends LightningElement {

    @api objectMapping;
    @api diFieldDescribes;
    @api targetObjectFieldDescribes;

    @track displayFieldMappings = false;
    @track isLoading = true;
    @track columns = columns;
    @track fieldMappingSetName;
    @track fieldMappings;

    deploymentTimer;
    deploymentTimeout = 10000;

    @api
    get noFieldMappings() {
        return !this.fieldMappings || this.fieldMappings.length === 0;
    }

    @api
    refresh() {
        this.init();
    }

    handleNavButton() {
        fireEvent(this.pageRef, 'showobjectmappings');
    }

    connectedCallback() {
        registerListener('showobjectmappings', this.handleShowObjectMappings, this);
        registerListener('showfieldmappings', this.handleShowFieldMappings, this);
        registerListener('deploymentResponse', this.handleDeploymentResponse, this);
        registerListener('startDeploymentTimeout', this.handleDeploymentTimeout, this);
        registerListener('refresh', this.refresh, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    /*******************************************************************************
    * @description Group up various get data calls to apex
    */
    init = async() => {
        try {
            this.isLoading = true;

            // Get all the data import field describes
            if (!this.diFieldDescribes) {
                this.diFieldDescribes =
                    await getObjectFieldDescribes({objectName: 'DataImport__c'});
            }

            // Get all the target object field describes based on the currently
            // selected object mapping
            let objectAPIName =
                this.objectMapping.Object_API_Name__c || this.objectMapping.npsp__Object_API_Name__c;
            this.targetObjectFieldDescribes =
                await getObjectFieldDescribes({objectName: objectAPIName});

            // Get the field mapping set name from the data import custom settings
            this.fieldMappingSetName =
                await getFieldMappingSetName();

            // Get all the field mappings for the currently selected object mapping
            this.fieldMappings =
                await getFieldMappingsByObjectAndFieldSetNames({
                    objectName: this.objectMapping.DeveloperName,
                    fieldMappingSetname: this.fieldMappingSetName
                });

            this.isLoading = false;

        } catch(error) {
            if (error) {
                this.showToast('Error', error, 'error', 'sticky');
            }
        }
    }

    /*******************************************************************************
    * @description Handles the timeout toast of deployments whenever a deployment
    * that's registered with platformEventListener takes 10 seconds or longer to
    * send out a response.
    */
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

    /*******************************************************************************
    * @description Listens for an event from the platformEventListener component.
    * Upon receiving an event refreshes the field mappings records, closes the modal,
    * and creates a toast.
    *
    * @param {object} platformEvent: Object containing the platform event payload
    */
    handleDeploymentResponse(platformEvent) {
        clearTimeout(this.deploymentTimer);
        fireEvent(this.pageRef, 'refresh', {});
        fireEvent(this.pageRef, 'closeModal', {});

        const payload = platformEvent.response.data.payload;
        const status = payload.Status__c || payload.npsp__Status__c;
        const deploymentId = payload.DeploymentId__c || payload.npsp__DeploymentId__c;

        if (status === 'Succeeded') {
            this.showToast(
                'Deployment completed with Status: ' + status,
                'Deployment Id: ' + deploymentId,
                'success');
        } else {
            this.showToast(
                'Deployment completed with Status: ' + status,
                'Deployment Id: ' + deploymentId,
                'error');
        }
    }

    /*******************************************************************************
    * @description Hides the field mappings component and fires an event to the parent
    * object mappings component to show itself.
    */
    handleShowObjectMappings() {
        this.displayFieldMappings = false;
    }

    /*******************************************************************************
    * @description Shows the field mappings component and forces a refresh to get
    * fresh field mapping records for the currently selected object mapping.
    */
    handleShowFieldMappings(event) {
        this.objectMapping = event.objectMapping;
        this.displayFieldMappings = true;
        this.init();
    }

    /*******************************************************************************
    * @description Opens the field mapping modal passing in relevant details on
    * the currently selected object and child field mappings.
    */
    handleOpenModal() {
        fireEvent(this.pageRef, 'openModal', {
            objectMapping: this.objectMapping,
            row: undefined,
            fieldMappings: this.fieldMappings
        });
    }

    /*******************************************************************************
    * @description Action handler for datatable row actions (i.e. edit, delete)
    *
    * @param {object} event: Event containing row details of the action
    */
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {

            case 'delete':
                this.isLoading = true;
                row.xxx_Is_Deleted_xxx = true;

                createDataImportFieldMapping({fieldMappingString: JSON.stringify(row)})
                    .then((deploymentId) => {
                        this.handleDeleteDeploymentId(deploymentId);
                    })
                    .catch((error) => {
                        console.log(error);
                        // TODO: Need to clean up the way these errors are handled
                        if (error && error.body) {
                            this.showToast(
                                'Error',
                                '{0}. {1}. {2}.',
                                'error',
                                'sticky',
                                [error.body.exceptionType, error.body.message, error.body.stackTrace]);
                        }
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

    /*******************************************************************************
    * @description Creates and dispatches a CustomEvent 'deployment' for deletion
    * letting the platformEventListener know that we have an id to register and monitor.
    * After dispatching the CustomEvent, start the deployment timeout.
    *
    * @param {string} deploymentId: Custom Metadata Deployment Id
    */
    handleDeleteDeploymentId(deploymentId) {
        const deploymentEvent = new CustomEvent('deployment', {
            bubbles: true,
            composed: true,
            detail: {deploymentId}
        });
        this.dispatchEvent(deploymentEvent);

        this.handleDeploymentTimeout({ deploymentId: deploymentId });
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
}