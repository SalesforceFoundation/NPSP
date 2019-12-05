import {LightningElement, api, track} from 'lwc';

export default class GeFormWidgetRow extends LightningElement {
    @api rowIndex;
    @api rowRecord;

    @api
    getRecord() {
        // TODO: Need to fill in data from the widget fields
        let recordData = { Amount__c: 50, General_Accounting_Unit__c : 'GAU_Id' };
        recordData = { ...recordData, ...(this.rowRecord) };
        return recordData;
    }

}