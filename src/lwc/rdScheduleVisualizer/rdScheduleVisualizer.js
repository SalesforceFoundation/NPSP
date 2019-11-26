// TODO Get this component to refresh automatically when the record is updated
// TODO Implement Custom Label as defined below
// TODO Implement a user definable setting (in the LWC) for number of schedules to show

// import labelScheduleTitle from '@salesforce/label/c.RD2_ScheduleVisualizerTitle';

import { LightningElement, api, wire, track } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

import SOBJECT_OPPORTUNITY from '@salesforce/schema/Opportunity';
import SOBJECT_PAYMENT from '@salesforce/schema/npe01__OppPayment__c';

import FIELD_CLOSEDATE from '@salesforce/schema/Opportunity.CloseDate';
import FIELD_AMOUNT from '@salesforce/schema/Opportunity.Amount';
import FIELD_PAYMENT_METHOD from '@salesforce/schema/npe01__OppPayment__c.npe01__Payment_Method__c';

import getSchedule from '@salesforce/apex/RD2_VisualizeScheduleController.getSchedule';
import getCurrencyCode from '@salesforce/apex/RD2_VisualizeScheduleController.getCurrencyCode';

const SCHEDULE_COLS = [
    { label: '#', fieldName: 'installmentNumber', type: 'number', sortable: false, fixedWidth: 50 },
    { label: '$CLOSEDATE', fieldName: 'donationDate', type: 'date-local', sortable: false,
        typeAttributes:{
            month: "2-digit",
            day: "2-digit"
        } },
    { label: '$AMOUNT', fieldName: 'amount', type: 'currency', sortable: false,
        typeAttributes: { currencyCode: '$CURRENCYISOCODE' } },
    { label: '$PMTMETHOD', fieldName: 'paymentMethod', type: 'text', sortable: false }
];

export default class RdScheduleVisualizer extends LightningElement {

    @api recordId;

    @track schedule;
    @track error;
    @track columns = SCHEDULE_COLS;
    @track currencyIsoCode;
    @track lblCloseDate;
    @track lblAmount;
    @track lblPmtMethod;

    /*******************************************************************************
     * @description Call Apex to retrieve the Schedule to render in the UI
     */
    @wire(getSchedule, { recordId: '$recordId' })
    wiredGetScheduleForRD( { data, error } ) {
        if (data) {
            this.handleColumns();
            this.schedule = data;
        } else {
            this.error = this.handleError(error);
        }
    }

    /*******************************************************************************
     * @description Call Apex to retrieve the Currency Code to use in the UI
     */
    @wire(getCurrencyCode, { recordId: '$recordId' })
    wiredCurrencyIsoCode( { data, error } ) {
        if (data) {
            this.currencyIsoCode = data;
        } else {
            this.currencyIsoCode = 'USD';
        }
    }

    /*******************************************************************************
     * @description Retrieve the object info for the Opportunity Object to set the field labels
     */
    @wire(getObjectInfo, { objectApiName: SOBJECT_OPPORTUNITY })
    wireGetOppObjectInfo({error, data}) {
        if (data) {
            this.lblCloseDate = data.fields[FIELD_CLOSEDATE.fieldApiName].label;
            this.lblAmount = data.fields[FIELD_AMOUNT.fieldApiName].label;
        }
    }

    /*******************************************************************************
     * @description Retrieve the object info for the Payment Object to set the field labels
     */
    @wire(getObjectInfo, { objectApiName: SOBJECT_PAYMENT })
    wireGetPmtObjectInfo({error, data}) {
        if (data) {
            this.lblPmtMethod = data.fields[FIELD_PAYMENT_METHOD.fieldApiName].label;
        }
    }

    /*******************************************************************************
     * @description Called by the HTML to retrieve the schedule to render
     */
    get schedule() {
        return this.schedule;
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
            { label: '$CLOSEDATE', value: this.lblCloseDate },
            { label: '$AMOUNT', value: this.lblAmount },
            { label: '$PMTMETHOD', value: this.lblPmtMethod }
        ];
        const currencyIsoCode = this.currencyIsoCode;

        this.columns = SCHEDULE_COLS;
        this.columns.forEach(function(col){
            if (col.label === '$AMOUNT') {
                col.typeAttributes.currencyCode = currencyIsoCode;
            }
            labelConversions.forEach(function(lbl){
                if (col.label === lbl.label) {
                    console.log('converting ' + col.label + ' to ' + lbl.value);
                    col.label = lbl.value;
                }
            });
        });

    }
}
