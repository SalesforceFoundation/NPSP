import { LightningElement, api } from 'lwc';
import commonAmount from '@salesforce/label/c.commonAmount';
import commonPaymentMethod from '@salesforce/label/c.commonPaymentMethod';
import RDCL_Frequency from '@salesforce/label/c.RDCL_Frequency';
import lblStatus from '@salesforce/label/c.lblStatus';
import dateStarted from '@salesforce/label/c.dateStarted'
import lastDonationDate from '@salesforce/label/c.lastDonationDate';
import nextInstallment from '@salesforce/label/c.nextInstallment';
import lastUpdate from '@salesforce/label/c.lastUpdate';
import commonActions from '@salesforce/label/c.commonActions';

export default class RecurringDonationTable extends LightningElement {
    @api
    donationTypeFilter = 'all';
    data = [{
        "id": 1,
        "dateStarted": "7/4/2022",
        "donor": "Saba",
        "amount": 69,
        "paymentMethod": "maestro",
        "frequency": "Monthly on the 22nd",
        "status": "Active",
        "lastDonationDate": "4/10/2023",
        "nextInstallment": "14/10/2023",
        "lastUpdate": "4/01/2023"
      },
      {
        "id": 2,
        "dateStarted": "4/10/2022",
        "donor": "Siward",
        "amount": 43,
        "paymentMethod": "laser",
        "frequency": "Monthly on the 22nd",
        "status": "Active",
        "lastDonationDate": "4/10/2023",
        "nextInstallment": "14/10/2023",
        "lastUpdate": "4/01/2023"
      },
      {
        "id": 3,
        "dateStarted": "3/31/2022",
        "donor": "Page",
        "amount": 43,
        "paymentMethod": "switch",
        "frequency": "Monthly on the 22nd",
        "status": "Active",
        "lastDonationDate": "4/10/2023",
        "nextInstallment": "14/10/2023",
        "lastUpdate": "4/01/2023"
      },
      {
        "id": 4,
        "dateStarted": "6/25/2022",
        "donor": "Eric",
        "amount": 91,
        "paymentMethod": "diners-club-enroute",
        "frequency": "Monthly on the 22nd",
        "status": "Active",
        "lastDonationDate": "4/10/2023",
        "nextInstallment": "14/10/2023",
        "lastUpdate": "4/01/2023"
      },
      {
        "id": 5,
        "dateStarted": "5/18/2022",
        "donor": "Merrill",
        "amount": 10,
        "paymentMethod": "diners-club-us-ca",
        "frequency": "Monthly on the 22nd",
        "status": "Active",
        "lastDonationDate": "4/10/2023",
        "nextInstallment": "14/10/2023",
        "lastUpdate": "4/01/2023"
    }];
    actions = [
        { label: 'View', name: 'view' },
        { label: 'Delete', name: 'delete' }
    ];
    columns = [
        { label: commonAmount, fieldName: "amount", type: "currency", hideDefaultActions: true },
        { label: RDCL_Frequency, fieldName: "frequency", type: "text", hideDefaultActions: true },
        { label: commonPaymentMethod, fieldName: "paymentMethod", type: "text", hideDefaultActions: true },
        { label: lblStatus, fieldName: "status", type: "text", hideDefaultActions: true },
        { label: dateStarted, fieldName: "dateStarted", type: "text", hideDefaultActions: true },
        { label: lastDonationDate, fieldName: "lastDonationDate", type: "text", hideDefaultActions: true },
        { label: nextInstallment, fieldName: "nextInstallment", type: "text", hideDefaultActions: true },
        { label: lastUpdate, fieldName: "lastUpdate", type: "text", hideDefaultActions: true },
        { label: commonActions, type: 'action', typeAttributes: {
            rowActions: this.actions,
            menuAlignment: 'center'
        }}
    ]
}