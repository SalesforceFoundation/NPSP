import { LightningElement, api, wire } from 'lwc';
import commonAmount from '@salesforce/label/c.commonAmount';
import RDCL_Frequency from '@salesforce/label/c.RDCL_Frequency';
import lblStatus from '@salesforce/label/c.lblStatus';
import firstDonation from '@salesforce/label/c.firstDonation'
import nextDonation from '@salesforce/label/c.nextDonation';
import mostRecentDonation from '@salesforce/label/c.mostRecentDonation';
import lastModified from '@salesforce/label/c.lastModified';

import RECURRING_DONATION from '@salesforce/schema/npe03__Recurring_Donation__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

export default class RecurringDonationTable extends LightningElement {
    @api
    donationTypeFilter = 'Show all Recurring Donations';

    paymentMethod = '';

    lastDonationDate = '';
    
    data = [{
        "id": 1,
        "firstDonation": "7/4/2022",
        "donor": "Saba",
        "amount": 69,
        "paymentMethod": "maestro",
        "frequency": "Monthly on the 22nd",
        "status": "Active",
        "mostRecenDonation": "12/10/2023",
        "nextDonation": "Paid Donation: 1 of 5. Next Donation: 1/12/2022.",
        "lastModified": "4/01/2023"
      },
      {
        "id": 2,
        "firstDonation": "4/10/2022",
        "donor": "Siward",
        "amount": 43,
        "paymentMethod": "laser",
        "frequency": "Monthly on the 22nd",
        "status": "Active",
        "mostRecenDonation": "12/10/2023",
        "nextDonation": "Paid Donation: 3 of 6. Next Donation: 12/20/2022.",
        "lastModified": "4/01/2023"
      },
      {
        "id": 3,
        "firstDonation": "3/31/2022",
        "donor": "Page",
        "amount": 43,
        "paymentMethod": "switch",
        "frequency": "Monthly on the 22nd",
        "status": "Active",
        "mostRecenDonation": "12/10/2023",
        "nextDonation": "Paid Donation: 2 of 5. Next Donation: 2/22/2022.",
        "lastModified": "4/01/2023"
      },
      {
        "id": 4,
        "firstDonation": "6/25/2022",
        "donor": "Eric",
        "amount": 91,
        "paymentMethod": "diners-club-enroute",
        "frequency": "Monthly on the 22nd",
        "status": "Active",
        "mostRecenDonation": "12/10/2023",
        "nextDonation": "Paid Donation: 2 of 10. Next Donation: 11/11/2022.",
        "lastModified": "4/01/2023"
      },
      {
        "id": 5,
        "firstDonation": "5/18/2022",
        "donor": "Merrill",
        "amount": 10,
        "paymentMethod": "diners-club-us-ca",
        "frequency": "Monthly on the 22nd",
        "status": "Active",
        "mostRecenDonation": "12/10/2023",
        "nextDonation": "Paid Donation: 6 of 8. Next Donation: 12/22/2022.",
        "lastModified": "4/01/2023"
    }];
    actions = [
      { label: 'View', name: 'view' },
      { label: 'Delete', name: 'delete' }
    ];
    columns = [];
    @wire(getObjectInfo, { objectApiName: RECURRING_DONATION })
    oppInfo({ data, error }) {
        if (data){
          this.paymentMethod = data.fields.PaymentMethod__c.label;
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
}