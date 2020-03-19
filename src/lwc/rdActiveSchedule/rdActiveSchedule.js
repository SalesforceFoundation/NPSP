import lblScheduleTitle from '@salesforce/label/c.RD2_ScheduleLWCTitle';
import lblEndDate from '@salesforce/label/c.RD2_ScheduleLWCEndDate';
import lblCurrentSchedule from '@salesforce/label/c.RD2_CurrentScheduleTitle';
import lblFutureSchedule from '@salesforce/label/c.RD2_ScheduleLWCFutureSchedule';
import lblRecordIcon from '@salesforce/label/c.AssistiveTextRecordIcon';
import lblNone from '@salesforce/label/c.stgLabelFieldValueNone';

import { LightningElement, api, wire, track } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';

import SOBJECT_RECURRING_DONATION from '@salesforce/schema/npe03__Recurring_Donation__c';

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
    @track currencyIsoCode;

    @track labels = {};

    /*******************************************************************************
     * @description Whenever the related RD record is updated, this is called to force
     * a refresh of the table and component.
     */
    @wire(getRecord, { recordId: '$recordId',
        fields: [FIELD_RD_AMOUNT, FIELD_RD_DAYOFMONTH, FIELD_RD_FREQUENCY, FIELD_RD_PERIOD,
                 FIELD_RD_STARTDATE, FIELD_RD_PAYMENT_METHOD, FIELD_RD_CAMPAIGN] })
    wireRecordChange() {
        if (this.recordId) {
            getSchedules({ recordId: this.recordId })
                .then(data => {
                    this.handleCurrencyIsoCode(data);
                    this.schedules = data;
                    this.error = null;

                })
                .catch(error => {
                    this.schedules = null;
                    this.error = this.handleError(error);
                });
        }
    }

    /*******************************************************************************
     * @description Call Apex to retrieve the Currency Code to use in the UI
     */
    handleCurrencyIsoCode(schedules) {
        if (schedules) {
            this.currencyIsoCode = schedules[0].currencyIsoCode;
        } else {
            this.currencyIsoCode = 'USD';
        }
    }

    /*******************************************************************************
     * @description Retrieve the object info for the Recurring Donation Object to set the field labels
     */
    @wire(getObjectInfo, { objectApiName: SOBJECT_RECURRING_DONATION })
    wireGetRDObjectInfo({error, data}) {
        if (data) {
            let fieldApis = data.fields;

            this.labels['lblScheduleTitle'] = lblScheduleTitle;
            this.labels['lblCurrentSchedule'] = lblCurrentSchedule;
            this.labels['lblFutureSchedule'] = lblFutureSchedule;
            this.labels['lblEndDate'] = lblEndDate;
            this.labels['lblAmount'] = (fieldApis[FIELD_RD_AMOUNT.fieldApiName]) ? fieldApis[FIELD_RD_AMOUNT.fieldApiName].label : null;
            this.labels['lblPmtMethod'] = (fieldApis[FIELD_RD_PAYMENT_METHOD.fieldApiName]) ? fieldApis[FIELD_RD_PAYMENT_METHOD.fieldApiName].label : null;
            this.labels['lblCampaign'] = (fieldApis[FIELD_RD_CAMPAIGN.fieldApiName]) ? fieldApis[FIELD_RD_CAMPAIGN.fieldApiName].label : null;
            this.labels['lblStartDate'] = (fieldApis[FIELD_RD_STARTDATE.fieldApiName]) ? fieldApis[FIELD_RD_STARTDATE.fieldApiName].label : null;
            this.labels['lblPeriod'] = (fieldApis[FIELD_RD_PERIOD.fieldApiName]) ? fieldApis[FIELD_RD_PERIOD.fieldApiName].label : null;
            this.labels['lblFrequency'] = (fieldApis[FIELD_RD_FREQUENCY.fieldApiName]) ? fieldApis[FIELD_RD_FREQUENCY.fieldApiName].label : null;
            this.labels['lblDayOfMonth'] = (fieldApis[FIELD_RD_DAYOFMONTH.fieldApiName]) ? fieldApis[FIELD_RD_DAYOFMONTH.fieldApiName].label : null;
            this.labels['lblNone'] = lblNone;
            this.labels['lblRecordIcon'] = lblRecordIcon;
        }
    }

    /*******************************************************************************
     * @description Called by the HTML to retrieve the schedule to render
     */
    get schedules() {
        return this.schedules;
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
