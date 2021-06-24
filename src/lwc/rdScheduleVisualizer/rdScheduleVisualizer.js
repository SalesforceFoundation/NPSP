import lblTitle from '@salesforce/label/c.RD2_ScheduleVisualizerTitle';
import lblLoading from '@salesforce/label/c.labelMessageLoading'

import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

import FIELD_RD_AMOUNT from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Amount__c';
import FIELD_RD_PERIOD from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installment_Period__c';
import FIELD_RD_FREQUENCY from '@salesforce/schema/npe03__Recurring_Donation__c.InstallmentFrequency__c';
import FIELD_RD_DAYOFMONTH from '@salesforce/schema/npe03__Recurring_Donation__c.Day_of_Month__c';
import FIELD_RD_STARTDATE from '@salesforce/schema/npe03__Recurring_Donation__c.StartDate__c';
import FIELD_RD_PAYMENT_METHOD from '@salesforce/schema/npe03__Recurring_Donation__c.PaymentMethod__c';

import getInstallments from '@salesforce/apex/RD2_VisualizeScheduleController.getInstallments';

export default class RdScheduleVisualizer extends LightningElement {

    @api recordId;
    @api displayNum;

    @track isLoading = true;
    @track columns = [];
    @track installments;
    selectedIds = [];
    @track error;

    labels = {
        lblTitle,
        lblLoading
    }

    /*******************************************************************************
     * @description Track specified fields so when the Recurring Donation record is updated, 
     * this method is called to force refresh of the data and the component.
     */
    @wire(getRecord, {
        recordId: '$recordId',
        fields: [FIELD_RD_AMOUNT, FIELD_RD_DAYOFMONTH, FIELD_RD_FREQUENCY, FIELD_RD_PERIOD, FIELD_RD_STARTDATE, FIELD_RD_PAYMENT_METHOD]
    })
    wireRecordChange() {
        if (this.recordId) {
            this.isLoading = true;
            getInstallments({ recordId: this.recordId, displayNum: this.displayNum })
                .then(response => {
                    this.handleRecords(response);
                    this.handleColumns(response);
                    this.error = null;

                })
                .catch(error => {
                    this.installments = null;
                    this.error = this.handleError(error);
                });
            this.isLoading = false;
        }
    }

    /*******************************************************************************
     * @description Get the installments
     */
    handleRecords(response) {
        if (response && response.dataTable) {
            this.installments = response.dataTable.records;

            this.selectSkippedInstallments();
        }
    }

    /*******************************************************************************
     * @description Highlight rows containing skipped installments
     */
    selectSkippedInstallments() {
        if (this.installments) {
            this.selectedIds = [];

            for (let i = 0; i < this.installments.length; i++) {
                if (this.installments[i].isSkipped === true) {
                    this.selectedIds.push(this.installments[i].installmentNumber);
                }
            }
        }
    }

    /*******************************************************************************
     * @description Get the data table columns
     */
    handleColumns(response) {
        if (response && response.dataTable) {
            this.columns = response.dataTable.columns;
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
}
