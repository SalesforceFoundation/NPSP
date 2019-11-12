import {LightningElement, api, track} from 'lwc';
import GeFormService from 'c/geFormService';

export default class GeFormTable extends LightningElement {
    @api ready = false;
    @track data = [];
    @api columns = [
        {label: 'Status', fieldName: 'Status__c', type: 'text'},
        {
            label: 'Donor', fieldName: 'donorLink', type: 'url',
            typeAttributes: {label: {fieldName: 'donorName'}}
        }
    ];

    @api
    addColumns(columns) {
        this.columns = [...this.columns, ...columns];
    }

    @api
    upsertRow(uid, dataImport) {
        if (dataImport && !dataImport.hasOwnProperty('uid')) {
            dataImport.uid = uid;
        }
        if (this.data.some(item => item.uid === uid)) {
            for (let i = 0; i < this.data.length; i++) {
                let row = this.data[i];
                if (row.uid === uid) {
                    row.Status__c = dataImport.Status__c;
                    row.donorName = dataImport.donorName;
                    row.donorLink = dataImport.donorLink;
                    break;
                }
            }
        } else {
            //todo: if the record is new then it should be added to the top and the table should
            // be ordered desc by created date (when we turn on ordering by column)
            this.data.push(dataImport);
        }
        this.data = [...this.data]; //re-assign the table, to rerender it
    }
}