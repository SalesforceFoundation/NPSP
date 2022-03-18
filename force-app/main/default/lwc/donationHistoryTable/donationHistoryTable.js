import { api, LightningElement, wire, track } from 'lwc';
import donationHistoryDatatableAriaLabel from '@salesforce/label/c.donationHistoryDatatableAriaLabel';
import getDonationHistory from '@salesforce/apex/DonationHistoryController.getDonationHistory';
import commonAmount from '@salesforce/label/c.commonAmount';
import donationHistoryDonorLabel from '@salesforce/label/c.donationHistoryDonorLabel';
import commonDate from "@salesforce/label/c.commonDate";

export default class DonationHistoryTable extends LightningElement {
    @api contactId;

    _filter;

    infiniteScroll = true;

    paymentMethodLabel;

    totalNumberOfRecords;
    
    tableElement;

    allData = [];

    data = [];

    label = {
        donationHistoryDatatableAriaLabel,
    };

    arePaymentsEnabled = false;

    @track
    columns = [];

    connectedCallback() {
        this.retrieveDonationHistory();
    }

    @api
    get filter() {
        return this._filter;
    }

    set filter(value) {
        this.data = [];
        this._filter = value;
        this.retrieveDonationHistory();
        this.infiniteScroll = true;
        this.tableElement ? this.tableElement.enableInfiniteLoading = true : null;
    }

    retrieveDonationHistory(){
        getDonationHistory({ contactId: this.contactId, offset: 0, filter : this.filter })
        .then((data) => {
            console.log('data.totalNumberOfRecords: ',data.totalNumberOfRecords);
            if (data) {
                this.totalNumberOfRecords = data.totalNumberOfRecords;
                this.data = data.donations;
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
                        hideDefaultActions: true
                    },
                    {
                        label: donationHistoryDonorLabel,
                        fieldName: "name",
                        type: "text",
                        hideDefaultActions: true
                    },
                    { label: commonAmount, fieldName: "amount", type: "currency", hideDefaultActions: true },
                ];
                if (this.arePaymentsEnabled) {
                    this.columns.push({
                        label: this.paymentMethodLabel,
                        fieldName: "paymentMethod",
                        type: "text",
                        hideDefaultActions: true
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
        this.tableElement = event.target;
        console.log('this.filter: ',this.filter);
        getDonationHistory({contactId: this.contactId, offset: this.data.length, filter: this.filter})
        .then(data => {
            console.log('this.data.length: ',this.data.length);
            console.log('this.totalNumberOfRecords: ',this.totalNumberOfRecords);
                if (this.data.length >= this.totalNumberOfRecords) {
                    this.tableElement.isLoading = false;
                    this.infiniteScroll = false;
                    this.tableElement.enableInfiniteLoading = false;

                    return;
                }
                const currentData = this.data;
                const newData = currentData.concat(data.donations);
                this.data = newData;
                //this fails for reference
                this.tableElement.isLoading = false;
        });
    }
}
