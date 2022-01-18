import { LightningElement } from 'lwc';
import { isNull } from 'c/util';
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
import commonNoneSpecific from '@salesforce/label/c.commonNoneSpecific';
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
        commonNoneSpecific,
        daysForClosedTooSmall,
        daysForLapsedTooLarge
    };

    displayState = STATES.LOADING;
    errorMessage;

    isEdit = false;

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
    minimunDaysForClosed;

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
            : this.labels.commonNoneSpecific;
        this.inputDaysForClosed = automationSettings.numberOfDaysForClosed;
        this.maximumDaysForLapsed = (this.numberOfDaysForClosed == null)
            ? null
            : parseInt(this.numberOfDaysForClosed) - 1;
    
        this.numberOfDaysForLapsed = (automationSettings.numberOfDaysForLapsed)
            ? automationSettings.numberOfDaysForLapsed
            : this.labels.commonNoneSpecific
        this.inputDaysForLapsed = automationSettings.numberOfDaysForLapsed;
        this.minimunDaysForClosed = (this.numberOfDaysForLapsed == null)
            ? null
            : parseInt(this.numberOfDaysForLapsed) + 1;

        this.closedStatus = automationSettings.closedStatus;
        this.inputClosedStatus = automationSettings.closedStatus;

        this.lapsedStatus = automationSettings.lapsedStatus;
        this.inputLapsedStatus = automationSettings.lapsedStatus;

        this.closedStatusOption = automationSettings.closedStatusOption;
        this.lapsedStatusOption = automationSettings.lapsedStatusOption;

        this.displayState = STATES.READY;
    }

    handleEdit() {
        this.isEdit = true;
    }

    handleCancel() {
        this.isEdit = false;
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
            })
            .catch ((error) => {
                this.errorMessage = error.body.message;
            })
        } catch (error) {
            this.errorMessge = error.body.message;
        }
    }

    handleDaysForLapsedChanged(event) {
        this.inputDaysForLapsed = (event.detail.value == '')
            ? null
            : event.detail.value;
        this.minimunDaysForClosed = (this.inputDaysForLapsed == null)
            ? null
            : parseInt(this.inputDaysForLapsed) + 1;

        this.validateNumberOfDays();
    }

    handleDaysForClosedChanged(event) {
        this.inputDaysForClosed = (event.detail.value == '')
            ? null
            : event.detail.value;

            this.maximumDaysForLapsed = (this.inputDaysForClosed == null)
            ? null
            : parseInt(this.inputDaysForClosed) - 1;

        this.validateNumberOfDays();
    }

    validateNumberOfDays() {
        let that = this;
        setTimeout(() => {
            that.template.querySelectorAll('.daysInput').forEach(element => {
                element.reportValidity();
            });
        }, 0);
        

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
}