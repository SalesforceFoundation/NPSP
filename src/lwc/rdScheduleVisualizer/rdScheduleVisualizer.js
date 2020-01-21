import labelInstallmentTitle from '@salesforce/label/c.RD2_ScheduleVisualizerTitle';
import labelColumnDate from '@salesforce/label/c.RD2_ScheduleVisualizerColumnDate';

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

import getInstallments from '@salesforce/apex/RD2_VisualizeScheduleController.getInstallments';

const INSTALLMENT_COLS = [
    { label: '$DATE', fieldName: 'donationDate', type: 'date-local', sortable: false,
        typeAttributes:{
            month: "2-digit",
            day: "2-digit"
        } },
    { label: '$AMOUNT', fieldName: 'amount', type: 'currency', sortable: false,
        typeAttributes: { currencyCode: '$CURRENCYISOCODE' } },
    { label: '$PAYMENT_METHOD', fieldName: 'paymentMethod', type: 'text', sortable: false }
];

export default class RdScheduleVisualizer extends LightningElement {

    @api recordId;
    @api displayNum;

    @track installments;
    @track error;
    @track columns = INSTALLMENT_COLS;
    @track currencyIsoCode;
    @track lblInstallmentTitle = labelInstallmentTitle;
    @track lblCloseDate = labelColumnDate;
    @track lblAmount;
    @track lblPmtMethod;
    @track fldAmount;

    /*******************************************************************************
     * @description Whenever the related RD record is updated, this is called to force
     * a refresh of the table and component.
     */
    @wire(getRecord, { recordId: '$recordId',
        fields: [FIELD_RD_AMOUNT, FIELD_RD_DAYOFMONTH, FIELD_RD_FREQUENCY, FIELD_RD_PERIOD, FIELD_RD_STARTDATE, FIELD_RD_PAYMENT_METHOD] })
    wireRecordChange() {
        if (this.recordId) {
            getInstallments({ recordId: this.recordId, displayNum: this.displayNum })
                .then(data => {
                    this.handleCurrencyIsoCode(data);
                    this.handleColumns();
                    this.installments = data;
                    this.error = null;

                })
                .catch(error => {
                    this.installments = null;
                    this.error = this.handleError(error);
                });
        }
    }

    /*******************************************************************************
     * @description Call Apex to retrieve the Currency Code to use in the UI
     */
    handleCurrencyIsoCode(installments) {
        if (installments) {
            this.currencyIsoCode = installments[0].currencyIsoCode;
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
            this.lblCloseDate = this.lblCloseDate
            this.lblAmount = data.fields[FIELD_RD_AMOUNT.fieldApiName].label;
            this.lblPmtMethod = data.fields[FIELD_RD_PAYMENT_METHOD.fieldApiName].label;
        }
    }

    /*******************************************************************************
     * @description Called by the HTML to retrieve the schedule to render
     */
    get installments() {
        return this.installments;
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
            { label: '$DATE', value: this.lblCloseDate },
            { label: '$AMOUNT', value: this.lblAmount },
            { label: '$PAYMENT_METHOD', value: this.lblPmtMethod }
        ];
        const currencyIsoCode = this.currencyIsoCode;

        this.columns = INSTALLMENT_COLS;
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
