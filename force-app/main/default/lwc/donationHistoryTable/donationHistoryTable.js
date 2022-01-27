import { api, LightningElement, wire, track } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import DATA_IMPORT from '@salesforce/schema/DataImport__c';
import PAYMENT_FIELD from '@salesforce/schema/DataImport__c.Payment_Method__c';
import donationHistoryDatatableAriaLabel from '@salesforce/label/c.donationHistoryDatatableAriaLabel';
import RD2_ScheduleVisualizerColumnDate from '@salesforce/label/c.RD2_ScheduleVisualizerColumnDate';
import getDonationHistory from '@salesforce/apex/DonationHistoryController.getDonationHistory';
import commonAmount from '@salesforce/label/c.commonAmount';
import donationHistoryDonorLabel from '@salesforce/label/c.donationHistoryDonorLabel';
import commonDate from "@salesforce/label/c.commonDate";
const RECORDS_TO_LOAD = 50;
export default class DonationHistoryTable extends LightningElement {
    @api contactId;

    _filter;
    
    paymentMethodLabel;

    totalNumberOfRows;

    tableElement;

    allData = [];

    data = [];

    label = {
        donationHistoryDatatableAriaLabel,
    };

    arePaymentsEnabled = false;

    @track
    columns = [];

    @wire(getObjectInfo, { objectApiName: DATA_IMPORT })
    oppInfo({ data, error }) {
        if (data) {
            this.paymentMethodLabel = data.fields[PAYMENT_FIELD.fieldApiName].label
        };
        this.columns = [
            { label: RD2_ScheduleVisualizerColumnDate, fieldName: 'closeDate', type: 'date-local', typeAttributes:{
                year: "numeric",
                month: "numeric",
                day: "numeric",
            },
            cellAttributes: { alignment: 'right' }},
            { label: donationHistoryDonorLabel, fieldName: 'name', type: 'text' },
            { label: commonAmount, fieldName: 'amount', type: 'currency', },
            { label: this.paymentMethodLabel, fieldName: 'paymentMethod', type: 'text', },
        ];
    }

    @api
    get filter() {
        return this._filter;
    }

    set filter(value) {
        this._filter = value;
        this.retrieveDonationHistory();
    }
    
    connectedCallback() {
        this.retrieveDonationHistory();
    }

    // eslint-disable-next-line @lwc/lwc/no-async-await
    async retrieveDonationHistory() {
        getDonationHistory({contactId: this.contactId, filter : this.filter})
        .then(data => {
            if (data) {
                this.allData = data.donations;
                this.data = data.donations.slice(0, RECORDS_TO_LOAD);
                this.totalNumberOfRows = data.donations.length;
                this.paymentMethodLabel = data.paymentMethodLabel;
                this.arePaymentsEnabled = data.isPaymentsEnabled;

                this.columns = [
                    {
                        label: commonDate,
                        fieldName: "closeDate",
                        type: "date-local",
                        typeAttributes: {
                            year: "numeric",
                            month: "numeric",
                            day: "numeric",
                        },
                        cellAttributes: { alignment: "right" },
                    },
                    {
                        label: donationHistoryDonorLabel,
                        fieldName: "name",
                        type: "text",
                    },
                    { label: commonAmount, fieldName: "amount", type: "currency" },
                ];
                if (this.arePaymentsEnabled) {
                    this.columns.push({
                        label: this.paymentMethodLabel,
                        fieldName: "paymentMethod",
                        type: "text",
                    });
                }
            }
        });
    }

    /**
     *
     * @param {*} event
     * handle the scroll event to get more content and concat to the existing table data
     */
    loadMoreDonationData(event) {
        event.target.isLoading = true;
        if (this.data.length >= this.totalNumberOfRows) {
            event.target.enableInfiniteLoading = false;
            event.target.isLoading = false;
            return;
        }
        const current = this.data.length;
        const offset = current + RECORDS_TO_LOAD;
        const currentData = this.data;
        //Appends new data to the end of the table
        const newData = currentData.concat(this.allData.slice(current, offset));
        this.data = newData;
        event.target.isLoading = false;
    }
}
