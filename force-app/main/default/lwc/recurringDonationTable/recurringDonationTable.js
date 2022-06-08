import { LightningElement, api, wire } from 'lwc';
import commonAmount from '@salesforce/label/c.commonAmount';
import RDCL_Frequency from '@salesforce/label/c.RDCL_Frequency';
import lblStatus from '@salesforce/label/c.lblStatus';
import firstDonation from '@salesforce/label/c.firstDonation'
import nextDonation from '@salesforce/label/c.nextDonation';
import mostRecentDonation from '@salesforce/label/c.mostRecentDonation';
import lastModified from '@salesforce/label/c.lastModified';
import updatePaymentMethod from '@salesforce/label/c.updatePaymentMethod';
import changeAmountOrFrequency from '@salesforce/label/c.changeAmountOrFrequency';
import stopRecurringDonation from '@salesforce/label/c.stopRecurringDonation';

import RECURRING_DONATION from '@salesforce/schema/npe03__Recurring_Donation__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

export default class RecurringDonationTable extends LightningElement {
    @api
    donationTypeFilter = 'Show all Recurring Donations';

    openUpdatePaymentMethod = false;

    openChangeAmountOrFrequency = false;

    openStopRecurringDonation = false;

    @api 
    allowACHPaymentMethod;
    paymentMethod = '';

    lastDonationDate = '';
    
    data = [{
        "id": 1,
        "firstDonation": "7/4/2022",
        "donor": "Saba",
        "amount": 69,
        "paymentMethod": "Credit Card, *1111Exp. 11/2023",
        "frequency": "Monthly on the 22nd",
        "status": "Active",
        "mostRecenDonation": "12/10/2023",
        "lastModified": "4/01/2023",
        "nextDonation": "Paid Donation: 1 of 5. Next Donation: 1/12/2022."
      },
      {
        "id": 2,
        "firstDonation": "4/10/2022",
        "donor": "Siward",
        "amount": 43,
        "paymentMethod": "ACH, *1111",
        "frequency": "Monthly on the 22nd",
        "status": "Active",
        "mostRecenDonation": "12/10/2023",
        "lastModified": "4/01/2023",
        "nextDonation": "Paid Donation: 3 of 6. Next Donation: 12/20/2022."
      },
      {
        "id": 3,
        "firstDonation": "3/31/2022",
        "donor": "Page",
        "amount": 43,
        "paymentMethod": "Credit Card, *1111Exp. 11/2023",
        "frequency": "Monthly on the 22nd",
        "status": "Active",
        "mostRecenDonation": "12/10/2023",
        "lastModified": "4/01/2023",
        "nextDonation": "Paid Donation: 2 of 5. Next Donation: 2/22/2022."
      },
      {
        "id": 4,
        "firstDonation": "6/25/2022",
        "donor": "Eric",
        "amount": 91,
        "paymentMethod": "Check",
        "frequency": "Monthly on the 22nd",
        "status": "Active",
        "mostRecenDonation": "12/10/2023",
        "lastModified": "4/01/2023",
        "nextDonation": "Paid Donation: 2 of 10. Next Donation: 11/11/2022."
      },
      {
        "id": 5,
        "firstDonation": "5/18/2022",
        "donor": "Merrill",
        "amount": 10,
        "paymentMethod": "Credit Card",
        "frequency": "Monthly on the 22nd",
        "status": "Active",
        "mostRecenDonation": "12/10/2023",
        "lastModified": "4/01/2023",
        "nextDonation": "Paid Donation: 6 of 8. Next Donation: 12/22/2022."
    }];
    actions = [
      { label: updatePaymentMethod, name: 'updatePaymentMethod' },
      { label: changeAmountOrFrequency, name: 'changeAmountOrFrequency' },
      { label: stopRecurringDonation, name: 'stopRecurringDonation' }
    ];

    columns = [];

    openchangeAmountOrFrequency() {
      this.template.querySelector('c-change-amount-or-frequency-modal').openmodal();
    }
    openstopRecurringDonation() {
      this.template.querySelector('c-stop-recurring-donation-modal').openmodal();
    }

    @wire(getObjectInfo, { objectApiName: RECURRING_DONATION })
    oppInfo({ data, error }) {
        if (data){
          this.paymentMethod = data.fields.PaymentMethod__c.label;
          console.log('this is a test');
          this.columns = [
            { label: commonAmount, fieldName: "amount", type: "currency", hideDefaultActions: true },
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
      handleRowAction(e) {
        const action = e.detail.action;
        switch (action.name) {
            case 'updatePaymentMethod':
                this.openUpdatePaymentMethod = true;
                break;
            case 'changeAmountOrFrequency':
                this.openChangeAmountOrFrequency = true;
                break;
            case 'stopRecurringDonation':
                this.openStopRecurringDonation = true;
                break;
            default:
                break;
      }
    }
    handleClose(event){ 
      switch (event.detail) {
        case 'updatePaymentMethod':
            this.openUpdatePaymentMethod = false;
            break;
        case 'changeAmountOrFrequency':
            this.openChangeAmountOrFrequency = false;
            break;
        case 'stopRecurringDonation':
            this.openStopRecurringDonation = false;
            break;
        default:
            break;
      }
    }
}