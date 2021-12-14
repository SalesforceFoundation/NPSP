import { api, LightningElement, track, wire } from 'lwc';
import {MOCK_DATA} from './donationHistoryTableData';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import DATA_IMPORT from '@salesforce/schema/DataImport__c';
import PAYMENT_FIELD from '@salesforce/schema/DataImport__c.Payment_Method__c';
import donationHistoryDatatableAriaLabel from '@salesforce/label/c.donationHistoryDatatableAriaLabel';
import RD2_ScheduleVisualizerColumnDate from '@salesforce/label/c.RD2_ScheduleVisualizerColumnDate';
import getDonationHistory from '@salesforce/apex/ListDonation.getDonationHistory';
import commonAmount from '@salesforce/label/c.commonAmount';
import donorLabel from '@salesforce/label/c.donorLabel';
export default class DonationHistoryTable extends LightningElement {
    @api contactId;

    paymentMethodLabel;

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
            { label: RD2_ScheduleVisualizerColumnDate, fieldName: 'closeDate', type: 'date', typeAttributes:{
                year: "numeric",
                month: "short",
                day: "2-digit"
            },
            cellAttributes: { alignment: 'right' }},
            { label: donorLabel, fieldName: 'name', type: 'text' },
            { label: commonAmount, fieldName: 'amount', type: 'currency', },
            { label: this.paymentMethodLabel, fieldName: 'paymentMethod', type: 'text', },
        ];
    }

    @wire(getDonationHistory, { contactId: '$contactId' })
    getDonation({ data, error }) {
        if (data) {
            console.log(JSON.stringify(data));
            this.data = data;
        }
    }

    
    
    totalNumberOfRows = MOCK_DATA.length;
    
    // eslint-disable-next-line @lwc/lwc/no-async-await
    async connectedCallback() {
    }

    /**
     * 
     * @param {*} event 
     * handle the scroll event to get more content and concat to the existing table data
     */
    loadMoreDonationData(event){
        //TODO: add wired service
        //Display a spinner to signal that data is being loaded
        event.target.isLoading = true;
        if (this.data.length >= this.totalNumberOfRows) {
            event.target.enableInfiniteLoading = false;
            event.target.isLoading = false;
            return;
        }
        const currentData = this.data;
        //Appends new data to the end of the table
        const newData = currentData.concat(MOCK_DATA.slice(50, 70));
        this.data = newData;
        event.target.isLoading = false;
    }
}