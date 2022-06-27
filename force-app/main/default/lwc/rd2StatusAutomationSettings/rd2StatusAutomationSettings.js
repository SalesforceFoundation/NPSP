import { LightningElement } from 'lwc';
import { isNull} from 'c/util';
import getAutomationSettings from '@salesforce/apex/RD2_StatusAutomationSettings_CTRL.getAutomationSettings';
import saveStatusAutomationSettings from '@salesforce/apex/RD2_StatusAutomationSettings_CTRL.saveStatusAutomationSettings';

import statusAutomationIntro from '@salesforce/label/c.RD2_StatusAutomationIntro';
import configurationSectionHeader from '@salesforce/label/c.RD2_StatusAutomationConfigurationSection';
import closedDefinition from '@salesforce/label/c.RD2_StatusAutomationClosedDefinition';
import lapsedDefinition from '@salesforce/label/c.RD2_StatusAutomationLapsedDefinition';
import daysForClosed from '@salesforce/label/c.RD2_StatusAutomationDaysForClosed';
import daysForLapsed from '@salesforce/label/c.RD2_StatusAutomationDaysForLapsed';
import setClosedStatus from '@salesforce/label/c.RD2_StatusAutomationSetClosedStatus';
import setLapsedStatus from '@salesforce/label/c.RD2_StatusAutomationSetLapsedStatus';

import editButtonLabel from '@salesforce/label/c.stgBtnEdit';
import cancelButtonLabel from '@salesforce/label/c.stgBtnCancel';
import saveButtonLabel from '@salesforce/label/c.stgBtnSave';
import commonError from '@salesforce/label/c.commonError';
import commonNoneSpecified from '@salesforce/label/c.commonNoneSpecified';
import rd2DisabledError from '@salesforce/label/c.RD2_ScheduleVisualizerErrorInvalidUsage';
import daysForClosedTooSmall from '@salesforce/label/c.RD2_StatusAutomationInvalidNumberOfDaysForClosed';
import daysForLapsedTooLarge from '@salesforce/label/c.RD2_StatusAutomationInvalidNumberOfDaysForLapsed';

const STATES = {
    LOADING: 'LOADING',
    READY: 'READY',
    ERROR: 'ERROR',
    RD2_DISABLED: 'RD2_DISABLED'
};



export default class Rd2StatusAutomationSettings extends LightningElement {
    labels = {
        statusAutomationIntro,
        configurationSectionHeader,
        closedDefinition,
        lapsedDefinition,
        daysForClosed,
        daysForLapsed,
        setClosedStatus,
        setLapsedStatus,
        editButtonLabel,
        cancelButtonLabel,
        saveButtonLabel,
        rd2DisabledError,
        commonError,
        commonNoneSpecified,
        daysForClosedTooSmall,
        daysForLapsedTooLarge
    };

    displayState = STATES.LOADING;
    errorMessage;

    isEdit = false;
    isSaveDisabled = false;

    automationSettings;
    numberOfDaysForLapsed;
    numberOfDaysForClosed;
    closedStatus;
    lapsedStatus;
    lapsedStatusOption;
    closedStatusOption;

    inputDaysForLapsed;
    inputDaysForClosed;

    maximumDaysForLapsed;
    minimumDaysForClosed;
    maximumDaysForClosed = 2147483647;
    minimumDaysForClosedErrorMessage = '';

    inputClosedStatus;
    inputLapsedStatus;


    async connectedCallback() {
        try {
            this.automationSettings = await getAutomationSettings();

            if (this.automationSettings.rd2Enabled) {
                this.assignSettings(this.automationSettings);
            } else {
                this.displayState = STATES.RD2_DISABLED;
            }

        } catch (ex) {
            this.displayState = STATES.ERROR;
            this.errorMessage = ex.body.message;
        }
    }

    assignSettings(automationSettings) {
        this.numberOfDaysForClosed = (automationSettings.numberOfDaysForClosed) 
            ? automationSettings.numberOfDaysForClosed
            : this.labels.commonNoneSpecified;
        this.inputDaysForClosed = automationSettings.numberOfDaysForClosed;

        this.numberOfDaysForLapsed = (automationSettings.numberOfDaysForLapsed)
            ? automationSettings.numberOfDaysForLapsed
            : this.labels.commonNoneSpecified;
        this.inputDaysForLapsed = automationSettings.numberOfDaysForLapsed;

        this.assignInputDaysThreshold();
        this.closedStatusOption = automationSettings.closedStatusOption;
        this.lapsedStatusOption = automationSettings.lapsedStatusOption;
        this.closedStatus = automationSettings.closedStatus;
        this.lapsedStatus = automationSettings.lapsedStatus;
    
        this.assignInputStatusWithApiValue(automationSettings);

        this.displayState = STATES.READY;
    }

    handleEdit() {
        this.isEdit = true;
    }

    handleCancel() {
        this.resetSettingsInput();
        this.errorMessage = null;
        this.isEdit = false;
        this.displayState = STATES.READY;
    }

    handleSave() {
        this.errorMessage = null;
        this.displayState === STATES.LOADING;
        try {
            saveStatusAutomationSettings(
                { daysForLapsed: this.inputDaysForLapsed,
                daysForClosed: this.inputDaysForClosed,
                lapsedStatus: this.inputLapsedStatus,
                closedStatus: this.inputClosedStatus }
            ).then ((automationSettings) => {
                this.assignSettings(automationSettings);
                this.isEdit = false;
                this.displayState = STATES.READY;
            })
            .catch ((error) => {
                this.errorMessage = error.body.message;
                this.displayState = STATES.READY;
            })
        } catch (error) {
            this.errorMessage = error.body.message;
            this.displayState = STATES.READY;
        }
    }

    handleDaysForLapsedChanged(event) {
        this.inputDaysForLapsed = this.getConvertedDays(event.detail.value);
        this.assignInputDaysThreshold();
        this.validateNumberOfDays();
    }

    handleDaysForClosedChanged(event) {
        this.inputDaysForClosed = this.getConvertedDays(event.detail.value);
        this.assignInputDaysThreshold();
        this.validateNumberOfDays();
    }

    validateNumberOfDays() {
        let that = this;
        setTimeout(() => {
            that.isSaveDisabled = !(that.lapsedDaysInputField().reportValidity()
                && that.closedDaysInputField().reportValidity());
        }, 0);
    }

    getConvertedDays(value) {
        return (value === '') ? null : value;
    }

    assignInputDaysThreshold() {
        this.maximumDaysForLapsed = (isNull(this.inputDaysForClosed))
            ? null
            : this.getMinimumDays(parseInt(this.inputDaysForClosed) - 1);
        
        this.minimumDaysForClosed = (isNull(this.inputDaysForLapsed))
            ? 0
            : this.getMinimumDays(parseInt(this.inputDaysForLapsed) + 1);

        this.adjustDaysForClosedErrorMessage();
    }

    assignInputStatusWithApiValue(automationSettings) {
        this.inputClosedStatus = automationSettings.closedStatusOption.filter(
            closedStatusOption => closedStatusOption.label === this.closedStatus
        )[0]?.value;
        this.inputLapsedStatus = automationSettings.lapsedStatusOption.filter(
            lapsedStatusOption => lapsedStatusOption.label === this.lapsedStatus
        )[0]?.value;
    }

    adjustDaysForClosedErrorMessage() {
        this.minimumDaysForClosedErrorMessage = 
            (!isNull(this.inputDaysForLapsed) && this.minimumDaysForClosed >= 0 && this.inputDaysForClosed >= 0) 
                ? this.labels.daysForClosedTooSmall
                : '';
    }
    resetSettingsInput() {
        this.assignInputStatusWithApiValue(this.automationSettings);
        this.inputDaysForClosed = this.automationSettings.numberOfDaysForClosed;
        this.inputDaysForLapsed = this.automationSettings.numberOfDaysForLapsed;
    }

    getMinimumDays(days) {
        return (days < 0)? 0 : days;
    }

    handleLapsedStatusChanged(event) {
        this.inputLapsedStatus = event.detail.value;
    }

    handleClosedStatusChanged(event) {
        this.inputClosedStatus = event.detail.value;
    }

    get isLoading() {
        return this.displayState === STATES.LOADING;
    }

    get isReady() {
        return this.displayState === STATES.READY;
    }

    get hasError() {
        return !isNull(this.errorMessage);
    }

    get isRd2Disabled() {
        return this.displayState === STATES.RD2_DISABLED;
    }

    lapsedDaysInputField() {
        return this.template.querySelector("lightning-input[data-id=lapsedDaysInput]");
    }

    closedDaysInputField() {
        return this.template.querySelector("lightning-input[data-id=closedDaysInput]")
    }
}