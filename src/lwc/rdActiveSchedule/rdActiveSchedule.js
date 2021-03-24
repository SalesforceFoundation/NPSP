import scheduleTitle from '@salesforce/label/c.RD2_ScheduleLWCTitle';
import currentSchedule from '@salesforce/label/c.RD2_CurrentScheduleTitle';
import futureSchedule from '@salesforce/label/c.RD2_ScheduleLWCFutureSchedule';
import recordIcon from '@salesforce/label/c.AssistiveTextRecordIcon';
import none from '@salesforce/label/c.stgLabelFieldValueNone';

import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

import FIELD_RD_AMOUNT from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Amount__c';
import FIELD_RD_PERIOD from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installment_Period__c';
import FIELD_RD_FREQUENCY from '@salesforce/schema/npe03__Recurring_Donation__c.InstallmentFrequency__c';
import FIELD_RD_DAYOFMONTH from '@salesforce/schema/npe03__Recurring_Donation__c.Day_of_Month__c';
import FIELD_RD_STARTDATE from '@salesforce/schema/npe03__Recurring_Donation__c.StartDate__c';
import FIELD_RD_PAYMENT_METHOD from '@salesforce/schema/npe03__Recurring_Donation__c.PaymentMethod__c';
import FIELD_RD_CAMPAIGN from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Recurring_Donation_Campaign__c';

import getSchedules from '@salesforce/apex/RD2_VisualizeScheduleController.getSchedules';

export default class RdActiveSchedule extends LightningElement {

    @api recordId;
    @api displayNum;

    @track schedules;
    @track error;

    labels = {
        scheduleTitle,
        currentSchedule,
        futureSchedule,
        none,
        recordIcon
    }

    /*******************************************************************************
     * @description Track specified fields so when the Recurring Donation record is updated,
     * this method is called to force refresh of the data and the component.
     */
    @wire(getRecord, {
        recordId: '$recordId',
        fields: [FIELD_RD_AMOUNT, FIELD_RD_DAYOFMONTH, FIELD_RD_FREQUENCY, FIELD_RD_PERIOD,
            FIELD_RD_STARTDATE, FIELD_RD_PAYMENT_METHOD, FIELD_RD_CAMPAIGN]
    })
    wireRecordChange() {
        if (this.recordId) {
            getSchedules({ recordId: this.recordId })
                .then(response => {
                    this.handleRecords(response);
                    this.error = null;
                })
                .catch(error => {
                    this.schedules = null;
                    this.error = this.handleError(error);
                });
        }
    }

    /*******************************************************************************
     * @description Get the schedules
     */
    handleRecords(response) {
        if (response && response.dataTable) {
            let filteredRows = [];

            response.dataTable.records.forEach(record => {
                let schedule = {};
                schedule.field = [];

                response.dataTable.columns.forEach(column => {
                    if (column.fieldName === 'isCurrent') {
                        schedule.title = record[column.fieldName] === true ? currentSchedule : futureSchedule;

                    } else {
                        let field = {};
                        field.column = column;
                        field.column.isCurrency = column.type === 'currency';
                        field.column.isDate = column.type === 'date-local' || column.type === 'date';
                        field.column.isText = column.type === 'text';

                        if (record[column.fieldName] === undefined) {
                            field.value = null;
                        } else {
                            field.value = record[column.fieldName];
                        }

                        schedule.field.push(field);
                    }
                });
                schedule.scheduleNumber = record.scheduleNumber;
                filteredRows.push(schedule);
            });
            this.schedules = filteredRows;
        }
    }

    /*******************************************************************************
     * @description Parse the error response
     * @param {object} error: Event holding error details
     * @return The error message to render.
     */
    handleError(error) {
        if (error && error.status && error.body) {
            return error.body.message;
        } else if (error && error.name && error.message) {
            return error.message;
        } else {
            return "";
        }
    }

    get qaLocatorHeader() {
        return `text Schedule Title`;
    }

    get qaLocatorError() {
        return `text Error`;
    }

    get qaLocatorRecordIcon() {
        return `icon Record Icon`;
    }

    get qaLocatorScheduleFieldLabel() {
        return `text Field Label`;
    }
}
