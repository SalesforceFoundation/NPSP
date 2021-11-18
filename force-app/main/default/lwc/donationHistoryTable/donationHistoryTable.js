import { LightningElement } from 'lwc';
import {MOCK_DATA} from './donationHistoryTableData';
//TODO: set custom label for datatable aria label

const columns = [
    { label: 'Date', fieldName: 'date', type: 'date' },
    { label: 'Donor', fieldName: 'donor', type: 'text' },
    { label: 'Amount', fieldName: 'amount', type: 'currency', },
    { label: 'Payment Method', fieldName: 'paymentMethod', type: 'text', },
];


export default class DonationHistoryTable extends LightningElement {
    data = [];
    columns = columns;
    totalNumberOfRows = MOCK_DATA.length;
    
    // eslint-disable-next-line @lwc/lwc/no-async-await
    async connectedCallback() {
        const data = MOCK_DATA.slice(0, 50);
        this.data = data;
        console.log(this.data.length);
    }

    loadMoreDonationData(event){
        //TODO: add wired service
        //Display a spinner to signal that data is being loaded
        event.target.isLoading = true;
        if (this.data.length >= this.totalNumberOfRows) {
            console.log('load all records');
            event.target.enableInfiniteLoading = false;
            this.loadMoreStatus = 'No more data to load';
        } else {
            const currentData = this.data;
            //Appends new data to the end of the table
            const newData = currentData.concat(MOCK_DATA.slice(50, 70));
            this.data = newData;
            console.log(this.data.length);
        }
        event.target.isLoading = false;
    }
}