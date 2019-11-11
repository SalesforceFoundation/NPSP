import {LightningElement, api, track} from 'lwc';
import GeFormService from 'c/geFormService';

export default class GeFormTable extends LightningElement {
    @api ready = false;
    @track data = [];
    @api columns = [
        {label: 'Status', fieldName: 'Status__c', type: 'text'},
        {label: 'UID', fieldName: 'uid', type: 'number'},
        {label: 'Donor', fieldName: 'donorName', type: 'text'},
        {label: 'Donor Link', fieldName: 'donorLink', type: 'url'}
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
        let indexToReplace;
        if (this.data.some(item => item.uid === uid)) {
            for (let i = 0; i < this.data.length; i++) {
                let row = this.data[i];
                if (row.uid === uid) {
                    indexToReplace = i;
                    break;
                }
            }
            this.data[indexToReplace] = dataImport; //replace it
        } else {
    //todo: if the record is new then it should be added to the top and the table should
            // be ordered desc by created date
            this.data.push(dataImport);
        }
        this.data = [...this.data]; //re-assign the table, to rerender it
    }
}