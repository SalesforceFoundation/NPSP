import { LightningElement, api, track } from 'lwc';
import { isNull, isEmpty } from 'c/util';

import getStatusFieldLabel from '@salesforce/apex/RD2_StatusMappingSettings_CTRL.getStatusFieldLabel';
import getStateOptions from '@salesforce/apex/RD2_StatusMappingSettings_CTRL.getStateOptions';
import loadMapping from '@salesforce/apex/RD2_StatusMappingSettings_CTRL.loadMapping';
import saveMapping from '@salesforce/apex/RD2_StatusMappingSettings_CTRL.saveMapping';
import getDeployResult from '@salesforce/apex/RD2_StatusMappingSettings_CTRL.getDeployResult';

import editButtonLabel from '@salesforce/label/c.stgBtnEdit';
import cancelButtonLabel from '@salesforce/label/c.stgBtnCancel';
import saveButtonLabel from '@salesforce/label/c.stgBtnSave';

import mappingIntro from '@salesforce/label/c.RD2_StatusMappingIntro';
import mappingDefinitions from '@salesforce/label/c.RD2_StatusMappingDefinitions';
import fieldLabelStatusApiName from '@salesforce/label/c.RD2_StatusMappingColumnStatusAPIName';
import fieldLabelState from '@salesforce/label/c.RD2_StatusMappingColumnState';
import stateUnmappedLabel from '@salesforce/label/c.RD2_StatusMappingStateUnmapped';

import deploymentInProgressMessage from '@salesforce/label/c.RD2_StatusMappingInProgressMessage';
import deploymentSuccessMessage from '@salesforce/label/c.RD2_StatusMappingSuccessMessage';
import stgUnknownError from '@salesforce/label/c.stgUnknownError';
import loadingMessage from '@salesforce/label/c.labelMessageLoading';

const toastVariant = {
    INFO: 'info',
    SUCCESS: 'success',
    WARNING: 'warning',
    ERROR: 'error'
}

export default class rd2StatusMappingSettings extends LightningElement {

    labels = {
        mappingIntro,
        mappingDefinitions,
        editButtonLabel,
        cancelButtonLabel,
        saveButtonLabel,
        loadingMessage
    }

    @track records;

    @track isLoading;
    @track isViewMode = true;
    @track viewColumns = [];
    @track editColumns = [];
    stateOptions = [];
    fieldLabelStatus;

    @track hasMessage = false;
    @track message = {};

    _deploymentIds = new Set();
    deploymentTimer;
    deploymentTimeout = 2000;

    /***
    * @description Called when the component is first loaded.
    * It checks if there is any status to state mapping deployment in progress.
    * If the deployment is not in progress, it displays mapping records.
    * Otherwise, it keeps checking for the deployment result and
    * displays the mapping records the deployment completion.
    */
    connectedCallback() {
        this.init();
    }

    /***
    * @description Group various calls to Apex
    */
    init = async () => {
        try {
            this.isLoading = true;
            this.stateOptions = await getStateOptions();
            this.fieldLabelStatus = await getStatusFieldLabel();
            this.handleDatatableColumns();
            this.handleDeploymentProgress();

        } catch (error) {
            this.handleError(error);
        }
    }

    /**
    * @description Contains datatable column names and field mapping for both view and edit modes.
    * Columns cannot be constants since labels need to be updated whenever the label in the org
    * is changed (for example on a translated org).
    */
    handleDatatableColumns() {
        this.viewColumns = [
            { label: this.fieldLabelStatus, fieldName: 'label', type: 'text' },
            { label: fieldLabelStatusApiName, fieldName: 'status', type: 'text' },
            { label: fieldLabelState, fieldName: 'stateLabel', type: 'text' }
        ];

        this.editColumns = [
            { label: this.fieldLabelStatus, fieldName: 'label', type: 'text' },
            { label: fieldLabelStatusApiName, fieldName: 'status', type: 'text' },
            {
                label: fieldLabelState, fieldName: 'state', editable: true,
                type: 'picklistType',
                typeAttributes: {
                    placeholder: stateUnmappedLabel,
                    options: this.stateOptions,
                    keyField: { fieldName: 'status' },
                    disabled: { fieldName: 'isReadOnly' }
                }
            }
        ];
    }

    /***
    * @description Loads status to state mapping records
    */
    handleLoadMapping() {
        loadMapping({})
            .then((data) => {
                this.records = data;
                this.isLoading = false;
            })
            .catch((error) => {
                this.handleError(error);
            });
    }

    /***
    * @description Updates the matching record state value based on the propagated picklist value change
    */
    handleStateChange(event) {
        event.stopPropagation();
        let data = event.detail.data;

        if (this.records) {
            this.records
                .filter(mapping => mapping.status === data.keyField)
                .forEach(mapping => {
                    mapping.state = data.value;
                });
        }
    }

    /**
    * @description Indicates the edit button should be disabled when Status 
    * picklist field does not contain any client defined value
    */
    get isEditDisabled() {
        let disabled = false;

        if (this.records) {
            disabled = this.records.length <= 3;
        }

        return disabled;
    }

    /***
    * @description Displays page in the edit mode
    */
    handleEdit() {
        this.clearMessage();

        if (this.records) {
            this.records
                .filter(mapping => mapping.isReadOnly === false)
                .forEach(mapping => {
                    mapping.oldState = mapping.state;
                });
        }

        this.isViewMode = false;
    }

    /***
    * @description Cancels the edit and displays the page in the view mode
    */
    handleCancel() {
        this.clearMessage();

        //reset values to the values as they were before the edit
        if (this.records) {
            this.records
                .filter(mapping => mapping.isReadOnly === false)
                .forEach(mapping => {
                    mapping.state = isNull(mapping.oldState) ? stateUnmappedLabel : mapping.oldState;
                    mapping.oldState = null;
                });
        }
        this.isViewMode = true;
    }

    /**
    * @description Indicates the save button should be disabled when at least one status is unmapped
    */
    get isSaveDisabled() {
        let disabled = false;

        if (this.records) {
            disabled = this.records
                .filter(mapping => mapping.state === stateUnmappedLabel)
                .length > 0;
        }

        return disabled;
    }

    /***
    * @description Saves mapping records
    */
    handleSave() {
        this.clearMessage();
        this.isLoading = true;

        try {
            let jsonRecords = JSON.stringify(this.records);

            saveMapping({ jsonMapping: jsonRecords })
                .then((deploymentId) => {
                    this.registerDeploymentId(deploymentId);
                })
                .catch((error) => {
                    this.handleError(error);
                });
        } catch (error) {
            this.handleError(error);
        }
    }

    /***
    * @description Registers deployment Id for the deployment monitoring. 
    * Display data and messages based on the deployment status.
    */
    registerDeploymentId(deploymentId) {
        this.showToast(deploymentInProgressMessage, toastVariant.INFO);

        this._deploymentIds.add(deploymentId);

        this.handleDeploymentProgress(deploymentId);
    }

    /***
    * @description Starts polling for the deployment job progress until the deployment completes
    */
    handleDeploymentProgress(deploymentId) {
        var self = this;

        this.deploymentTimer = setTimeout(function () {
            self.handleDeploymentResult(deploymentId);

        }, this.deploymentTimeout, self);
    }

    /***
    * @description Retrieves deployment result for the specified deployment Id.
    * When the deployment Id is not specified, the latest deployment result (if any) will be retrieved and processed.
    */
    handleDeploymentResult(deploymentId) {
        getDeployResult({ deploymentId: deploymentId })
            .then((data) => {
                const response = JSON.parse(data);
                this.handleDeploymentResponse(response);

                if (response.isInProgress) {
                    this.handleDeploymentProgress(response.deploymentId);

                } else if (response.isSuccess) {
                    this.isViewMode = true;
                }
            })
            .catch((error) => {
                this.handleError(error);
            });
    }

    /***
    * @description Displays response message based on the deployment status.
    * Refresh mapping records when the deployment has completed.
    */
    handleDeploymentResponse(response) {

        if (this.isMonitored(response.deploymentId)) {
            let variant;
            let message;

            if (response.isInProgress) {
                variant = toastVariant.INFO;
                message = deploymentInProgressMessage;

            } else if (response.isSuccess) {
                variant = toastVariant.SUCCESS;
                message = deploymentSuccessMessage;

            } else if (response.hasResult) {
                variant = toastVariant.ERROR
                message = response.errorMessage;
            }

            if (!isNull(variant)) {
                this.showToast(message, variant);
            }
        }

        if (!isNull(response.deploymentId)) {
            this._deploymentIds.add(response.deploymentId);
        }

        var hasErrorMessage = !isNull(this.message)
            && this.message.variant === toastVariant.ERROR;

        var shouldRefreshRecords = !hasErrorMessage
            && (response.hasResult === false || response.isInProgress === false);

        if (shouldRefreshRecords) {
            this.handleLoadMapping();

        } else if (hasErrorMessage) {
            this.isLoading = false;
        }
    }

    /***
    * @description Checks if the specific deployment is monitored by this component
    */
    isMonitored(deploymentId) {
        return this._deploymentIds
            && this._deploymentIds.has(deploymentId);
    }

    /**
    * @description Creates and dispatches an error toast
    *
    * @param {object} error: Event holding error details
    */
    handleError(error) {
        const errorVariant = toastVariant.ERROR;

        if (error && error.status && error.body) {
            this.showToast(`${error.status} ${error.statusText}`, error.body.message, errorVariant);
        } else if (error && error.name && error.message) {
            this.showToast(`${error.name}`, error.message, errorVariant);
        } else {
            this.showToast(stgUnknownError, '', errorVariant);
        }

        this.isLoading = false;
    }

    /**
    * @description Displays message notification. 
    * ***ShowToastEvent does not work in Lightning Out
    * @param {string} message: Message of the toast.
    * @param {string} variant: Toast variant (info, success, warning, error)
    */
    showToast(message, variant) {
        this.hasMessage = true;
        this.message.body = message;
        this.message.variant = variant;
    }

    /**
    * @description Toast message notification formatting
    */
    get notificationClass() {
        let classNames = 'slds-notify_extension slds-notify_toast ';
        switch (this.message.variant) {
            case toastVariant.SUCCESS:
                classNames += 'slds-theme_success';
                break;
            case toastVariant.WARNING:
                classNames += 'slds-theme_warning';
                break;
            case toastVariant.ERROR:
                classNames += 'slds-theme_error';
                break;
            default:
                classNames += 'slds-theme_info';
                break;
        }
        return classNames;
    }

    /**
    * @description Toast message notification icon
    */
    get iconName() {
        return 'utility:' + this.message.variant;
    }

    /**
    * @description Handles the message notification close action
    */
    handleCloseNotification() {
        this.clearMessage();
    }

    /**
    * @description Clears the message notification
    */
    clearMessage() {
        this.hasMessage = false;
        this.message = {};
    }
}