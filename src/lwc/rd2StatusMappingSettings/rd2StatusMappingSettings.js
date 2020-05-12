import { LightningElement, api, track } from 'lwc';
import { isNull, isEmpty } from 'c/util';

import loadMapping from '@salesforce/apex/RD2_StatusMappingSettings_CTRL.loadMapping';
import saveMapping from '@salesforce/apex/RD2_StatusMappingSettings_CTRL.saveMapping';
import getDeployResult from '@salesforce/apex/RD2_StatusMappingSettings_CTRL.getDeployResult';

import editButtonLabel from '@salesforce/label/c.stgBtnEdit';
import cancelButtonLabel from '@salesforce/label/c.stgBtnCancel';
import saveButtonLabel from '@salesforce/label/c.stgBtnSave';

import mappingIntro from '@salesforce/label/c.RD2_StatusMappingIntro';
import mappingDefinitions from '@salesforce/label/c.RD2_StatusMappingDefinitions';
import fieldStatusLabel from '@salesforce/label/c.RD2_StatusMappingColumnStatusLabel';
import fieldStatus from '@salesforce/label/c.RD2_StatusMappingColumnStatus';
import fieldState from '@salesforce/label/c.RD2_StatusMappingColumnState';

import stateUnmappedLabel from '@salesforce/label/c.RD2_StatusMappingStateUnmapped';
import stateActiveLabel from '@salesforce/label/c.RD2_StatusMappingStateActive';
import stateLapsedLabel from '@salesforce/label/c.RD2_StatusMappingStateLapsed';
import stateClosedLabel from '@salesforce/label/c.RD2_StatusMappingStateClosed';

import deploymentInProgressMessage from '@salesforce/label/c.RD2_StatusMappingInProgressMessage';
import deploymentSuccessMessage from '@salesforce/label/c.RD2_StatusMappingSuccessMessage';
import stgUnknownError from '@salesforce/label/c.stgUnknownError';

const viewColumns = [
    { label: fieldStatusLabel, fieldName: 'label', type: 'text' },
    { label: fieldStatus, fieldName: 'status', type: 'text' },
    { label: fieldState, fieldName: 'stateLabel', type: 'text' }
];

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
        saveButtonLabel
    }

    @track viewColumns = viewColumns;
    @track records;

    @track hasMessage = false;
    @track message = {};

    @track isLoading;
    @track isViewMode = true;

    _deploymentIds = new Set();
    deploymentTimer;
    deploymentTimeout = 2000;

    /**
    * @description Contains column names and values when datatable is in the edit mode
    * Since the custom label is used in the columns, "editColumns" cannot be a constant as "viewColumns" are. 
    * Otherwise, labels keep the old value if they are changed in the custom labels (for example a translated org).
    */
    get editColumns() {
        return [
            { label: fieldStatusLabel, fieldName: 'label', type: 'text' },
            { label: fieldStatus, fieldName: 'status', type: 'text' },
            {
                label: fieldState, fieldName: 'state', editable: true,
                type: 'picklistType',
                typeAttributes: {
                    placeholder: stateUnmappedLabel,
                    options: [
                        { label: stateActiveLabel, value: 'Active' },
                        { label: stateLapsedLabel, value: 'Lapsed' },
                        { label: stateClosedLabel, value: 'Closed' }
                    ],
                    keyField: { fieldName: 'status' },
                    disabled: { fieldName: 'isReadOnly' }
                }
            }
        ];
    }

    /***
    * @description Called when the component is first loaded.
    * It checks if there is any status to state mapping deployment in progress.
    * If deployment is not in progress, it displays mapping records.
    * Otherwise, mapping records are displayed upon the deployment completion.
    */
    connectedCallback() {
        this.isLoading = true;
        this.handleDeploymentProgress();
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

    /***
    * @description Applies actions on a button click
    */
    handleButtonClick(event) {
        this.clearMessage();

        switch (event.target.label) {
            case editButtonLabel:
                this.handleEdit();
                break;
            case cancelButtonLabel:
                this.handleCancel();
                break;
            case saveButtonLabel:
                this.handleSave();
                break;
        }
    }

    /***
    * @description Displays page in the edit mode
    */
    handleEdit() {
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
    * @description Registers deployment Id for the deployment monitoring and
    * data and messages display based on its status
    */
    registerDeploymentId(deploymentId) {
        this.showToast(deploymentInProgressMessage, toastVariant.INFO);

        this._deploymentIds.add(deploymentId);

        this.handleDeploymentProgress(deploymentId);
    }

    /***
    * @description Starts polling for the deployment job progress details until the deployment completes
    */
    handleDeploymentProgress(deploymentId) {
        var self = this;

        this.deploymentTimer = setTimeout(function () {
            self.handleDeploymentResult(deploymentId);

        }, this.deploymentTimeout, self);
    }

    /***
    * @description Retrieves deployment result for the specified deployment Id.
    * When the deployment Id is not specified, the latest deployment result (if any) will be processed.
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
    * Refresh data if deployment has been completed.
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

        if (response.hasResult === false || response.isInProgress === false) {
            //refresh mapping records
            this.handleLoadMapping();
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
    * ***ShowToastMessage does not work in Lightning Out
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
        let classNames = 'slds-notify slds-notify_extension slds-notify_toast ';
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