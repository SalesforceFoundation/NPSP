import { LightningElement, api, track } from 'lwc';
import { isEmpty } from 'c/utilCommon';

import { Rd2Service, ACTIONS, PERIOD, RECURRING_PERIOD_ADVANCED } from "c/rd2Service";

import commonCancel from '@salesforce/label/c.commonCancel';
import geAddSchedule from '@salesforce/label/c.geAddSchedule';
import geUpdateSchedule from '@salesforce/label/c.geUpdateSchedule';

import RECURRING_TYPE from '@salesforce/schema/npe03__Recurring_Donation__c.RecurringType__c';
import INSTALLMENT_PERIOD from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installment_Period__c';
import START_DATE from '@salesforce/schema/npe03__Recurring_Donation__c.StartDate__c';
import INSTALLMENTS from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installments__c';
import DAY_OF_MONTH from '@salesforce/schema/npe03__Recurring_Donation__c.Day_of_Month__c';
import INSTALLMENT_FREQUENCY from '@salesforce/schema/npe03__Recurring_Donation__c.InstallmentFrequency__c';

export default class GeModalRecurringDonation extends LightningElement {
    @api schedule;
    @api cancelCallback;
    @api createRecurrenceCallback;

    rd2Service = new Rd2Service();
    @track rd2State = this.rd2Service.init();

    async connectedCallback() {
        this.rd2State = await this.rd2Service.loadInitialView();
        if (!isEmpty(this.schedule)) {
            this._populateScheduleFromGift();
        }
    }

    labels = {
        commonCancel,
    };

    get isUpdatingSchedule() {
        return !isEmpty(this.schedule);
    }

    get applyScheduleButton() {
        return this.isUpdatingSchedule ? geUpdateSchedule : geAddSchedule;
    }

    get scheduleComponent() {
        return this.template.querySelectorAll("[data-id=\"scheduleComponent\"]")[0];
    }

    handleAddSchedule() {
        const isValid = this.scheduleComponent.isValid();

        if (isValid) {
            const scheduleData = this.scheduleComponent.returnValues();
            this.createRecurrenceCallback(scheduleData);
        }
    }

    handleCancel() {
        this.cancelCallback();
    }

    perform(action) {
        this.rd2State = this.rd2Service.dispatch(this.rd2State, action);
    }

    handleRecurringTypeChange(event) {
        this.perform({
            type: ACTIONS.SET_RECURRING_TYPE,
            payload: event.detail,
        });
    }

    handleRecurringPeriodChange(event) {
        this.perform({
            type: ACTIONS.SET_RECURRING_PERIOD,
            payload: event.detail,
        });
    }

    handleRecurringPeriodTypeChange(event) {
        this.perform({
            type: ACTIONS.SET_PERIOD_TYPE,
            payload: event.detail,
        });
    }

    handleDayOfMonthChange(event) {
        this.perform({
            type: ACTIONS.SET_DAY_OF_MONTH,
            payload: event.detail,
        });
    }

    handleStartDateChange(event) {
        this.perform({
            type: ACTIONS.SET_START_DATE,
            payload: event.detail,
        });
    }

    handleFrequencyChange(event) {
        this.perform({
            type: ACTIONS.SET_RECURRING_FREQUENCY,
            payload: event.detail,
        });
    }

    handleInstallmentsChange(event) {
        this.perform({
            type: ACTIONS.SET_PLANNED_INSTALLMENTS,
            payload: event.detail,
        });
    }

    _populateScheduleFromGift() {
        this.perform({
            type: ACTIONS.SET_RECURRING_TYPE,
            payload: this.schedule[RECURRING_TYPE.fieldApiName],
        });

        this.perform({
            type: ACTIONS.SET_PERIOD_TYPE,
            payload: this.recurringPeriod(),
        });

        this.perform({
            type: ACTIONS.SET_RECURRING_PERIOD,
            payload: this.schedule[INSTALLMENT_PERIOD.fieldApiName] || 'Monthly',
        });

        this.perform({
            type: ACTIONS.SET_DAY_OF_MONTH,
            payload: this.schedule[DAY_OF_MONTH.fieldApiName],
        });

        this.perform({
            type: ACTIONS.SET_START_DATE,
            payload: this.schedule[START_DATE.fieldApiName],
        });

        this.perform({
            type: ACTIONS.SET_RECURRING_FREQUENCY,
            payload: this.schedule[INSTALLMENT_FREQUENCY.fieldApiName],
        });

        this.perform({
            type: ACTIONS.SET_PLANNED_INSTALLMENTS,
            payload: this.schedule[INSTALLMENTS.fieldApiName],
        });
    }

    recurringPeriod() {
        const isAdvancedType =
            this.schedule[INSTALLMENT_FREQUENCY.fieldApiName]
            || this.schedule[INSTALLMENT_PERIOD.fieldApiName] !== PERIOD.MONTHLY;

        if (isAdvancedType) {
            return RECURRING_PERIOD_ADVANCED;
        }
        return PERIOD.MONTHLY;
    }
}
