import { api, LightningElement, track } from "lwc";
import donationHistoryDatatableAriaLabel from "@salesforce/label/c.donationHistoryDatatableAriaLabel";
import commonDate from "@salesforce/label/c.commonDate";
import getDonationHistory from "@salesforce/apex/DonationHistoryController.getDonationHistory";
import commonAmount from "@salesforce/label/c.commonAmount";
import donationHistoryDonorLabel from "@salesforce/label/c.donationHistoryDonorLabel";
const RECORDS_TO_LOAD = 50;
export default class DonationHistoryTable extends LightningElement {
    @api contactId;

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

    // eslint-disable-next-line @lwc/lwc/no-async-await
    async connectedCallback() {
        getDonationHistory({ contactId: this.contactId, offset: 0 }).then((data) => {
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
        this.tableElement = event.target;
        getDonationHistory({contactId: this.contactId, offset: this.data.length})
        .then(data => {
                if (this.data.length >= this.totalNumberOfRecords) {
                    this.tableElement.isLoading = false;
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
