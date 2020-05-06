import { LightningElement, api, track } from 'lwc';
import { isNull, isEmpty } from 'c/util';

import loadMapping from '@salesforce/apex/RD2_StatusMappingSettings_CTRL.loadMapping';

import editButtonLabel from '@salesforce/label/c.stgBtnEdit';
import cancelButtonLabel from '@salesforce/label/c.stgBtnCancel';
import saveButtonLabel from '@salesforce/label/c.stgBtnSave';

import mappingIntro from '@salesforce/label/c.RD2_StatusMappingIntro';
import mappingDescriptions from '@salesforce/label/c.RD2_StatusMappingDefinitions';
import fieldStatusLabel from '@salesforce/label/c.RD2_StatusMappingColumnStatusLabel';
import fieldStatus from '@salesforce/label/c.RD2_StatusMappingColumnStatus';
import fieldState from '@salesforce/label/c.RD2_StatusMappingColumnState';
import unmappedStateLabel from '@salesforce/label/c.RD2_StatusMappingUnmappedState';
import stgUnknownError from '@salesforce/label/c.stgUnknownError';

const viewColumns = [
    { label: fieldStatusLabel, fieldName: 'label', type: 'text' },
    { label: fieldStatus, fieldName: 'status', type: 'text' },
    { label: fieldState, fieldName: 'state', type: 'text' }
];

const editColumns = [
    { label: fieldStatusLabel, fieldName: 'label', type: 'text' },
    { label: fieldStatus, fieldName: 'status', type: 'text' },
    {
        label: fieldState, fieldName: 'state', editable: true,
        type: 'picklistType',
        typeAttributes: {
            placeholder: unmappedStateLabel,
            options: [
                { label: 'Active', value: 'Active' },
                { label: 'Lapsed', value: 'Lapsed' },
                { label: 'Closed', value: 'Closed' }
            ],
            keyField: { fieldName: 'status' },
            disabled: { fieldName: 'isReadOnly' }
        }
    }
];


export default class rd2StatusMappingSettings extends LightningElement {

    labels = {
        mappingIntro,
        mappingDescriptions,
        editButtonLabel,
        cancelButtonLabel,
        saveButtonLabel
    }

    @track viewColumns = viewColumns;
    @track editColumns = editColumns;
    @track records;

    @track hasMessage = false;
    @track message = {};

    @track isViewMode = true;


    /***
    * @description Initializes the component
    */
    connectedCallback() {
        this.handleLoadMapping();
    }

    /***
    * @description Loads status to state mapping records
    */
    @api
    handleLoadMapping() {
        loadMapping({})
            .then((data) => {
                this.records = data;
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
                    mapping.oldState = mapping.state;
                    mapping.state = data.value;
                });
        }
    }

    /***
    * @description Applies actions on a button click
    */
    handleButtonClick(event) {
        switch (event.target.label) {
            case editButtonLabel:
                this.editMapping();
                break;
            case cancelButtonLabel:
                this.cancelEditMapping();
                break;
            case saveButtonLabel:
                this.saveMapping();
                break;
        }
    }

    /***
    * @description Displays page in the edit mode
    */
    editMapping() {
        this.isViewMode = false;
    }

    /***
    * @description Displays page in the view mode
    */
    cancelEditMapping() {
        //reset values to the before edit values
        if (this.records) {
            this.records
                .filter(mapping => mapping.isReadOnly === false)
                .forEach(mapping => {
                    mapping.state = isNull(mapping.oldState) ? unmappedStateLabel : mapping.oldState;
                    mapping.oldState = null;
                });
        }

        this.isViewMode = true;
    }

    /***
    * @description Saves mapping records
    */
    saveMapping() {
        console.log(JSON.stringify(this.records));

        this.isViewMode = true;
    }

    /**
    * @description Indicates the save button should be disabled when at least one status is unmapped
    */
    get isSaveDisabled() {
        let disabled = false;

        if (this.records) {
            disabled = this.records
                .filter(mapping => mapping.state === unmappedStateLabel)
                .length > 0;
        }

        return disabled;
    }

    /**
    * @description Creates and dispatches an error toast
    *
    * @param {object} error: Event holding error details
    */
    handleError(error) {
        if (error && error.status && error.body) {
            this.showToast(`${error.status} ${error.statusText}`, error.body.message, 'error');
        } else if (error && error.name && error.message) {
            this.showToast(`${error.name}`, error.message, 'error');
        } else {
            this.showToast(stgUnknownError, '', 'error');
        }
    }

    /**
    * @description Displays message notification. ShowToastMessage does not work in Lightning Out
    *
    * @param {string} title: Title of the toast, displayed as a heading.
    * @param {string} message: Message of the toast. It can contain placeholders in
    * the form of {0} ... {N}. The placeholders are replaced with the links from
    * messageData param
    */
    showToast(title, message, variant) {
        this.hasMessage = true;
        this.message.title = title;
        this.message.body = message;
        this.message.variant = variant;
    }

    /**
    * @description Toast message notification formatting
    */
    get notificationClass() {
        let classNames = 'slds-notify slds-notify_extension slds-notify_toast ';
        switch (this.message.variant) {
            case 'success':
                classNames += 'slds-theme_success';
                break;
            case 'warning':
                classNames += 'slds-theme_warning';
                break;
            case 'error':
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