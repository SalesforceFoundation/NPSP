import {LightningElement, api, track} from 'lwc';

export default class GeFormTable extends LightningElement {
    @track data = [{uid: -1, Donation_Amount__c: 0}]; //sample starter data
    columns = [
        {label: 'Submission ID', fieldName: 'uid', type: 'number'},
        {label: 'Donation Amount', fieldName: 'Donation_Amount__c', type: 'number'}
    ];

    @api
    upsertRow(uid, dataImport){
        console.log('*** ' + 'upserting row in table' + ' ***');
        console.log('dataImport: ', dataImport);
        console.log('uid: ', uid);
        dataImport.uid = uid;
        let indexToReplace;
        if (this.data.some(item => item.uid === uid)) {
            console.log('*** ' + 'this di is already in the table!' + ' ***');
            for (let i = 0; i < this.data.length; i++) {
                let row = this.data[i];
                if (row.uid === uid) {
                    indexToReplace = i;
                    break;
                }
            }
            this.data[indexToReplace] = dataImport; //replace it
        } else {
            console.log('*** ' + 'this di is new' + ' ***');
            this.data.push(dataImport);
        }
        this.data = [...this.data]; //re-assign the table, to rerender it
    }
}