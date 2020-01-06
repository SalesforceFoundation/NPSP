import labelScheduleTitle from '@salesforce/label/c.RD2_ActiveSchedulesTitle';
import labelEndDate from '@salesforce/label/c.RD2_ActiveSchedulesEndDate';
import labelCurrentSchedule from '@salesforce/label/c.RD2_ActiveSchedulesCurrentSchedule';
import labelFutureSchedule from '@salesforce/label/c.RD2_ActiveSchedulesFutureSchedule';

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

const SCHEDULE_COLS = [
    { label: '$AMOUNT', fieldName: 'amount', type: 'currency', sortable: false,
        typeAttributes: { currencyCode: '$CURRENCYISOCODE' } },
    { label: '$PAYMENT_METHOD', fieldName: 'paymentMethod', type: 'text', sortable: false },
    { label: '$CAMPAIGN', fieldName: 'campaign', type: 'text', sortable: false },
    { label: '$START_DATE', fieldName: 'startDate', type: 'date-local', sortable: false,
        typeAttributes:{
            month: "2-digit",
            day: "2-digit"
        } },
    { label: '$END_DATE', fieldName: 'endDate', type: 'date-local', sortable: false,
        typeAttributes:{
            month: "2-digit",
            day: "2-digit"
        } },
    { label: '$PERIOD', fieldName: 'period', type: 'text', sortable: false },
    { label: '$FREQUENCY', fieldName: 'frequency', type: 'number', sortable: false },
    { label: '$DAY_OF_MONTH', fieldName: 'dayOfMonth', type: 'text', sortable: false }
];

export default class RdScheduleVisualizer extends LightningElement {

    @api recordId;
    @api displayNum;

    @track schedules;
    @track error;
    @track columns = SCHEDULE_COLS;
    @track currencyIsoCode;
    @track lblScheduleTitle = labelScheduleTitle;
    @track lblCurrentSchedule = labelCurrentSchedule;
    @track lblFutureSchedule = labelFutureSchedule;
    @track lblAmount;
    @track lblPmtMethod;
    @track lblCampaign;
    @track lblStartDate;
    @track lblEndDate = labelEndDate;
    @track lblPeriod;
    @track lblFrequency;
    @track lblDayOfMonth;

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
                    this.handleColumns();
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
            this.lblAmount = data.fields[FIELD_RD_AMOUNT.fieldApiName].label;
            this.lblPmtMethod = data.fields[FIELD_RD_PAYMENT_METHOD.fieldApiName].label;
            this.lblCampaign = data.fields[FIELD_RD_CAMPAIGN.fieldApiName].label;
            this.lblStartDate = data.fields[FIELD_RD_STARTDATE.fieldApiName].label;
            this.lblEndDate = labelEndDate;
            this.lblPeriod = data.fields[FIELD_RD_PERIOD.fieldApiName].label;
            this.lblFrequency = data.fields[FIELD_RD_FREQUENCY.fieldApiName].label;
            this.lblDayOfMonth = data.fields[FIELD_RD_DAYOFMONTH.fieldApiName].label;
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

    /*******************************************************************************
     * @description Configure column labels and the currency code to use for the amount field
     * by replacing constants in the SCHEDULE_COL string with the actual (translated) field labels
     * as well as the $CurrencyIsoCode with the RD or Org CurrencyIsoCode as retrieved from Apex
     */
    handleColumns() {
        const labelConversions = [
            { label: '$AMOUNT', value: this.lblAmount },
            { label: '$PAYMENT_METHOD', value: this.lblPmtMethod },
            { label: '$CAMPAIGN', value: this.lblCampaign },
            { label: '$START_DATE', value: this.lblStartDate },
            { label: '$END_DATE', value: this.lblEndDate },
            { label: '$PERIOD', value: this.lblPeriod },
            { label: '$FREQUENCY', value: this.lblFrequency },
            { label: '$DAY_OF_MONTH', value: this.lblDayOfMonth }
        ];

        const currencyIsoCode = this.currencyIsoCode;

        this.columns = SCHEDULE_COLS;
        this.columns.forEach(function(col){
            if (col.label === '$AMOUNT') {
                col.typeAttributes.currencyCode = currencyIsoCode;
            }
            labelConversions.forEach(function(lbl){
                if (col.label === lbl.label) {
                    col.label = lbl.value;
                }
            });
        });

    }
}
