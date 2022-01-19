import { api, LightningElement, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import DATA_IMPORT from '@salesforce/schema/DataImport__c';
import PAYMENT_FIELD from '@salesforce/schema/DataImport__c.Payment_Method__c';
import donationHistoryDatatableAriaLabel from '@salesforce/label/c.donationHistoryDatatableAriaLabel';
import RD2_ScheduleVisualizerColumnDate from '@salesforce/label/c.RD2_ScheduleVisualizerColumnDate';
import getDonationHistory from '@salesforce/apex/DonationHistoryController.getDonationHistory';
import getTotalNumberOfRecords from '@salesforce/apex/DonationHistoryController.getTotalNumberOfRecords';
import commonAmount from '@salesforce/label/c.commonAmount';
import donationHistoryDonorLabel from '@salesforce/label/c.donationHistoryDonorLabel';
const RECORDS_TO_LOAD = 50;
export default class DonationHistoryTable extends LightningElement {
    @api contactId;

    paymentMethodLabel;

    totalNumberOfRows;

    tableElement;

    allData = [];

    data = [];

    label = {
        donationHistoryDatatableAriaLabel,
    }

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
    
    // eslint-disable-next-line @lwc/lwc/no-async-await
    async connectedCallback() {
        getTotalNumberOfRecords({contactId: this.contactId})
        .then(data => {
            if(data){
                this.totalNumberOfRows = data;
            }
        });
        getDonationHistory({contactId: this.contactId, offset: 0})
        .then(data => {
            if (data) {
                this.allData = data;
                this.data = data.slice(0, RECORDS_TO_LOAD);
            }
        });
    }

    /**
     * 
     * @param {*} event 
     * handle the scroll event to get more content and concat to the existing table data
     */
    loadMoreDonationData(event){
        event.target.isLoading = true;
        this.tableElement = event.target;
        getDonationHistory({contactId: this.contactId, offset: this.data.length})
        .then(data => {
                if (this.data.length >= this.totalNumberOfRows) {
                    this.tableElement.isLoading = false;
                    this.tableElement.enableInfiniteLoading = false;
                    return;
                }
                const currentData = this.data;
                const newData = currentData.concat(data);
                this.data = newData;
                //this fails for reference
                this.tableElement.isLoading = false;
        });
    }
}