import { LightningElement, track, api } from 'lwc';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsubNoPageRef';
import getAdvancedMappingFieldsData
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.getAdvancedMappingFieldsData';
import getFieldMappingsByObjectAndFieldSetNames
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.getFieldMappingsByObjectAndFieldSetNames';
import createDataImportFieldMapping
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.createDataImportFieldMapping';
import DATA_IMPORT from '@salesforce/schema/DataImport__c';


// Import custom labels
import bdiFieldMappingsLabel from '@salesforce/label/c.bdiFieldMappings';
import bdiFMUIBackToMapGroup from '@salesforce/label/c.bdiFMUIBackToMapGroup';
import bdiFMUIDescription1 from '@salesforce/label/c.bdiFMUIDescription1';
import bdiFMUIDescription2 from '@salesforce/label/c.bdiFMUIDescription2';
import bdiFMUILongDeployment from '@salesforce/label/c.bdiFMUILongDeployment';
import bdiFMUILongDeploymentLink from '@salesforce/label/c.bdiFMUILongDeploymentLink';
import bdiFMUILongDeploymentMessage from '@salesforce/label/c.bdiFMUILongDeploymentMessage';
import bdiFMUINewFieldMapping from '@salesforce/label/c.bdiFMUINewFieldMapping';
import bdiFMUINoFieldMappings from '@salesforce/label/c.bdiFMUINoFieldMappings';
import bdiFMUISourceObject from '@salesforce/label/c.bdiFMUISourceObject';
import bdiFMUISuccessful from '@salesforce/label/c.bdiFMUISuccessful';
import bdiFMUITarget from '@salesforce/label/c.bdiFMUITarget';
import bdiFMUITryAgain from '@salesforce/label/c.bdiFMUITryAgain';
import bdiFMUIUnsuccessful from '@salesforce/label/c.bdiFMUIUnsuccessful';
import bdiFMUIUpdate from '@salesforce/label/c.bdiFMUIUpdate';
import stgLabelObject from '@salesforce/label/c.stgLabelObject';
import stgUnknownError from '@salesforce/label/c.stgUnknownError';

// Import custom labels for datatable
import bdiFMUIDatatableMapsTo from '@salesforce/label/c.bdiFMUIDatatableMapsTo';
import bdiFMUIDataType from '@salesforce/label/c.bdiFMUIDataType';
import bdiFMUIFieldAPIName from '@salesforce/label/c.bdiFMUIFieldAPIName';
import bdiFMUIFieldLabel from '@salesforce/label/c.bdiFMUIFieldLabel';
import bgeActionDelete from '@salesforce/label/c.bgeActionDelete';
import stgBtnEdit from '@salesforce/label/c.stgBtnEdit';
import bdiOMUIFieldMappingProblemHeader from '@salesforce/label/c.bdiOMUIFieldMappingProblemHeader';
import bdiOMUIFieldMappingProblemMessagePart1 from '@salesforce/label/c.bdiOMUIFieldMappingProblemMessagePart1';
import bdiOMUIFieldMappingProblemMessagePart2 from '@salesforce/label/c.bdiOMUIFieldMappingProblemMessagePart2';
import { isNull, showToast } from 'c/utilCommon';


const actions = [
    { label: stgBtnEdit, name: 'edit' },
    { label: bgeActionDelete, name: 'delete' },
];

const columns = [
    { label: bdiFMUIFieldLabel, fieldName: 'Source_Field_Label', type: 'text', sortable: true },
    { label: bdiFMUIFieldAPIName, fieldName: 'Source_Field_API_Name', type: 'text', sortable: true},
    { label: bdiFMUIDataType, fieldName: 'Source_Field_Display_Type_Label', type: 'text', initialWidth: 125, sortable: true },
        {
            label: bdiFMUIDatatableMapsTo, fieldName: '', type: 'text', fixedWidth: 95,
            cellAttributes: { alignment: 'center', iconName: { fieldName: 'Maps_To_Icon' } }
        },
    { label: bdiFMUIFieldLabel, fieldName: 'Target_Field_Label', type: 'text', sortable: true },
    { label: bdiFMUIFieldAPIName, fieldName: 'Target_Field_API_Name', type: 'text', sortable: true },
    { label: bdiFMUIDataType, fieldName: 'Target_Field_Display_Type_Label', type: 'text', initialWidth: 125, sortable: true },
    { type: 'action', typeAttributes: { rowActions: actions } }
];

export default class bdiFieldMappings extends LightningElement {

    customLabels = {
        bdiFieldMappingsLabel,
        bdiFMUIBackToMapGroup,
        bdiFMUIDescription1,
        bdiFMUIDescription2,
        bdiFMUINewFieldMapping,
        bdiFMUINoFieldMappings,
        bdiFMUISourceObject,
        bdiFMUITarget,
        stgLabelObject,
        bdiOMUIFieldMappingProblemHeader,
        bdiOMUIFieldMappingProblemMessagePart1,
        bdiOMUIFieldMappingProblemMessagePart2
    }

    @api shouldRender;
    @track brokenFieldMappings = [];

    objectMapping;
    diFieldDescribes;
    mappedDiFieldDescribes;
    targetObjectFieldDescribes;
    displayFieldMappings = false;
    isLoading = true;
    columns = columns;
    sortedBy;
    sortDirection;
    fieldMappingSetName;
    fieldMappings;
    deploymentTimer;
    deploymentTimeout = 10000;
    @track errors;

    get noFieldMappings() {
        return !this.fieldMappings || this.fieldMappings.length === 0;
    }

    refresh() {
        if (this.displayFieldMappings) {
            this.init();
        }
    }

    handleNavButton() {
        this.displayFieldMappings = false;
        fireEvent(this.pageRef, 'showobjectmappings');
    }

    connectedCallback() {
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
        this.brokenFieldMappings = [];
        this.errors = null;
        try {
            this.isLoading = true;
            let fieldMappingData = await getAdvancedMappingFieldsData({
                targetObjectApiName : this.objectMapping.Object_API_Name,
                sourceObjectApiName : DATA_IMPORT.objectApiName
            });

            if (!isNull(fieldMappingData)) {
                this.diFieldDescribes = fieldMappingData.sourceObjectFieldDescribes;
                this.targetObjectFieldDescribes = fieldMappingData.targetObjectFieldDescribes;
                this.mappedDiFieldDescribes = fieldMappingData.mappedDISourceFields;
                this.fieldMappingSetName = fieldMappingData.fieldMappingSetName;
            }

            // Get all the field mappings for the currently selected object mapping
            this.fieldMappings =
                await getFieldMappingsByObjectAndFieldSetNames({
                    objectName: this.objectMapping.DeveloperName,
                    fieldMappingSetname: this.fieldMappingSetName
                });
            if (this.fieldMappings && this.fieldMappings.length > 0) {
                this.fieldMappings = this.sortData(
                    this.fieldMappings,
                    'Source_Field_Label',
                    'asc');
                this.processBrokenFieldMappingReferences();
            }

            this.isLoading = false;

        } catch(error) {
            this.handleError(error);
        }
    }

    processBrokenFieldMappingReferences () {
        this.errors = { rows: {}, table: {} };
        this.fieldMappings.forEach(fieldMapping => {
            if (!fieldMapping.isDescribable && !fieldMapping.Is_Deleted) {
                this.errors.rows[fieldMapping.DeveloperName] = {
                    title: bdiOMUIFieldMappingProblemHeader,
                    messages: bdiOMUIFieldMappingProblemMessagePart2,
                    fieldNames: []
                };
                this.brokenFieldMappings.push(
                    `${this.objectMapping.MasterLabel} : ${fieldMapping.MasterLabel} (${fieldMapping.Target_Field_API_Name})`);
            }
        });
    }

    get hasBrokenFieldReferences () {
        return this.brokenFieldMappings.length > 0;
    }

    get showRowNumberColumns () {
        return isNull(this.errors) ? false : !isNull(this.errors.rows);
    }

    get brokenFieldReferencesWarningMessage () {
        return `${this.customLabels.bdiOMUIFieldMappingProblemMessagePart1} ${this.customLabels.bdiOMUIFieldMappingProblemMessagePart2}`
    }

    /*******************************************************************************
    * @description Handles the timeout toast of deployments whenever a deployment
    * that's registered with platformEventListener takes 10 seconds or longer to
    * send out a response.
    */
    handleDeploymentTimeout(event) {
        if (this.displayFieldMappings) {
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
                    bdiFMUILongDeployment,
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
        if (this.displayFieldMappings) {
            clearTimeout(this.deploymentTimer);
            fireEvent(this.pageRef, 'refresh', {});
            fireEvent(this.pageRef, 'closeModal', {});

            const payload = platformEvent.response.data.payload;
            const status = payload.Status__c || payload.npsp__Status__c;
            // TODO: Update toasts when we're able to determine create, edit, delete from the platform event
            const successful = bdiFMUISuccessful.charAt(0).toUpperCase() + bdiFMUISuccessful.slice(1);
            const unsuccessful = bdiFMUIUnsuccessful.charAt(0).toUpperCase() + bdiFMUIUnsuccessful.slice(1);
            const successMessage = `${successful} ${bdiFieldMappingsLabel} ${bdiFMUIUpdate}.`;
            const failMessage = `${unsuccessful} ${bdiFieldMappingsLabel} ${bdiFMUIUpdate}. ${bdiFMUITryAgain}.`;
            const succeeded = status === 'Succeeded';
            
            showToast(
                `${succeeded ? successMessage : failMessage}`,
                '',
                succeeded ? 'success' : 'error', []);
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
        if (this.displayFieldMappings) {
            fireEvent(this.pageRef, 'openModal', {
                objectMapping: this.objectMapping,
                row: undefined,
                fieldMappings: this.fieldMappings,
                diFieldDescribes: this.diFieldDescribes,
                mappedDiFieldDescribes: this.mappedDiFieldDescribes,
                targetObjectFieldDescribes: this.targetObjectFieldDescribes,
            });
        }
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
                row.Is_Deleted = true;

                createDataImportFieldMapping({fieldMappingString: JSON.stringify(row)})
                    .then((deploymentId) => {
                        this.handleDeleteDeploymentId(deploymentId);
                    })
                    .catch((error) => {
                        this.handleError(error);
                    });
                break;

            case 'edit':
                fireEvent(this.pageRef, 'openModal', {
                    objectMapping: this.objectMapping,
                    row: row,
                    fieldMappings: this.fieldMappings,
                    diFieldDescribes: this.diFieldDescribes,
                    mappedDiFieldDescribes: this.mappedDiFieldDescribes,
                    targetObjectFieldDescribes: this.targetObjectFieldDescribes,
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
        if (this.displayFieldMappings) {
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
    * @description Handles the onsort event from the lightning:datatable
    *
    * @param {object} event: Event holding column details of the action
    */
    handleColumnSorting(event) {
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        this.fieldMappings = this.sortData(this.fieldMappings, this.sortedBy, this.sortedDirection);
    }

    /*******************************************************************************
    * @description Sorts the given list by field name and direction
    *
    * @param {array} list: List to be sorted
    * @param {string} fieldName: Property to sort by
    * @param {string} sortDirection: Direction to sort by (i.e. 'asc' or 'desc')
    */
    sortData(list, fieldName, sortDirection) {
        const data = JSON.parse(JSON.stringify(list));
        const key =(a) => a[fieldName];
        const reverse = sortDirection === 'asc' ? 1 : -1;

        data.sort((a,b) => {
            let valueA = key(a) ? key(a).toLowerCase() : '';
            let valueB = key(b) ? key(b).toLowerCase() : '';
            return reverse * ((valueA > valueB) - (valueB > valueA));
        });

        return data;
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