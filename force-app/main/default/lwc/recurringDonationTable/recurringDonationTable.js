import { LightningElement, api, wire } from 'lwc';
import commonAmount from '@salesforce/label/c.commonAmount';
import RDCL_Frequency from '@salesforce/label/c.RDCL_Frequency';
import lblStatus from '@salesforce/label/c.lblStatus';
import firstDonation from '@salesforce/label/c.firstDonation'
import nextDonation from '@salesforce/label/c.nextDonation';
import mostRecentDonation from '@salesforce/label/c.mostRecentDonation';
import lastModified from '@salesforce/label/c.lastModified';
import getData from '@salesforce/apex/RD2_ERecurringDonationsController.getData';

import RECURRING_DONATION from '@salesforce/schema/npe03__Recurring_Donation__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

export default class RecurringDonationTable extends LightningElement {
    @api
    donationTypeFilter = 'Show all Recurring Donations';
    @api 
    allowACHPaymentMethod;
    paymentMethod = '';

    lastDonationDate = '';
    
    data = [];

    actions = [
      { label: 'View', name: 'view' },
      { label: 'Delete', name: 'delete' }
    ];

    columns = [];

    @wire(getObjectInfo, { objectApiName: RECURRING_DONATION })
    oppInfo({ data, error }) {
        this.getRecurringDonationFields();
        if (data){
          this.paymentMethod = data.fields.PaymentMethod__c.label;
          this.columns = [
            { label: commonAmount, fieldName: "npe03__Amount__c", type: "currency", hideDefaultActions: true },
            { label: RDCL_Frequency, fieldName: "frequency", type: "text", hideDefaultActions: true },
            { label: this.paymentMethod, fieldName: "paymentMethod", type: "text", hideDefaultActions: true },
            { label: lblStatus, fieldName: "status", type: "text", hideDefaultActions: true },
            { label: firstDonation, fieldName: "firstDonation", type: "text", hideDefaultActions: true },
            { label: mostRecentDonation, fieldName: "mostRecenDonation", type: "text", hideDefaultActions: true },
            { label: nextDonation, fieldName: "nextDonation", type: "text", hideDefaultActions: true, initialWidth: 160, wrapText: true },
            { label: lastModified, fieldName: "lastModified", type: "text", hideDefaultActions: true },
            { label: '', type: 'action', typeAttributes: {
                rowActions: this.actions,
                menuAlignment: 'center'
            }}
        ];
        }
    }
	
	getRecurringDonationFields() {
        getData()
        .then((data) => {
            if (data) {
                this.data = data.map((d) => { return {...d.recurringDonation, frequency: d.frequency, status: d.status}});
            }
        });
    }
}