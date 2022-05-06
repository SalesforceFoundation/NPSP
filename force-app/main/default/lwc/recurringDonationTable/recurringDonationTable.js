import { LightningElement, api, wire } from 'lwc';
import commonAmount from '@salesforce/label/c.commonAmount';
import RDCL_Frequency from '@salesforce/label/c.RDCL_Frequency';
import lblStatus from '@salesforce/label/c.lblStatus';
import dateStarted from '@salesforce/label/c.dateStarted'
import nextInstallment from '@salesforce/label/c.nextInstallment';
import endDate from '@salesforce/label/c.endDate';
import lastUpdated from '@salesforce/label/c.lastUpdated';
import commonActions from '@salesforce/label/c.commonActions';
import RECURRING_DONATION from '@salesforce/schema/npe03__Recurring_Donation__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

export default class RecurringDonationTable extends LightningElement {
    @api
    donationTypeFilter = 'Show all Recurring Donations';

    paymentMethod = '';

    lastDonationDate = '';
    
    data = [{
        "id": 1,
        "dateStarted": "7/4/2022",
        "donor": "Saba",
        "amount": 69,
        "paymentMethod": "maestro",
        "frequency": "Monthly on the 22nd",
        "status": "Active",
        "endDate": "12/10/2023",
        "lastDonationDate": "4/10/2023",
        "nextInstallment": "10/14/2023",
        "lastUpdated": "4/01/2023"
      },
      {
        "id": 2,
        "dateStarted": "4/10/2022",
        "donor": "Siward",
        "amount": 43,
        "paymentMethod": "laser",
        "frequency": "Monthly on the 22nd",
        "status": "Active",
        "endDate": "12/10/2023",
        "lastDonationDate": "4/10/2023",
        "nextInstallment": "2 of 5 installments paid. Next on 2/22/2022",
        "lastUpdated": "4/01/2023"
      },
      {
        "id": 3,
        "dateStarted": "3/31/2022",
        "donor": "Page",
        "amount": 43,
        "paymentMethod": "switch",
        "frequency": "Monthly on the 22nd",
        "status": "Active",
        "endDate": "12/10/2023",
        "lastDonationDate": "4/10/2023",
        "nextInstallment": "10/14/2023",
        "lastUpdated": "4/01/2023"
      },
      {
        "id": 4,
        "dateStarted": "6/25/2022",
        "donor": "Eric",
        "amount": 91,
        "paymentMethod": "diners-club-enroute",
        "frequency": "Monthly on the 22nd",
        "status": "Active",
        "endDate": "12/10/2023",
        "lastDonationDate": "4/10/2023",
        "nextInstallment": "10/14/2023",
        "lastUpdated": "4/01/2023"
      },
      {
        "id": 5,
        "dateStarted": "5/18/2022",
        "donor": "Merrill",
        "amount": 10,
        "paymentMethod": "diners-club-us-ca",
        "frequency": "Monthly on the 22nd",
        "status": "Active",
        "endDate": "12/10/2023",
        "lastDonationDate": "4/10/2023",
        "nextInstallment": "2 of 5 installments paid. Next on 2/22/2022",
        "lastUpdated": "4/01/2023"
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
          this.lastDonationDate = data.fields.npe03__Last_Payment_Date__c.label;
          this.columns = [
            { label: commonAmount, fieldName: "amount", type: "currency", hideDefaultActions: true },
            { label: RDCL_Frequency, fieldName: "frequency", type: "text", hideDefaultActions: true },
            { label: this.paymentMethod, fieldName: "paymentMethod", type: "text", hideDefaultActions: true },
            { label: lblStatus, fieldName: "status", type: "text", hideDefaultActions: true },
            { label: dateStarted, fieldName: "dateStarted", type: "text", hideDefaultActions: true },
            { label: endDate, fieldName: "endDate", type: "text", hideDefaultActions: true },
            { label: this.lastDonationDate, fieldName: "lastDonationDate", type: "text", hideDefaultActions: true },
            { label: nextInstallment, fieldName: "nextInstallment", type: "text", hideDefaultActions: true },
            { label: lastUpdated, fieldName: "lastUpdated", type: "text", hideDefaultActions: true },
            { label: commonActions, type: 'action', typeAttributes: {
                rowActions: this.actions,
                menuAlignment: 'center'
            }}
        ];
        }
    }
}