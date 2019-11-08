import {LightningElement, api, track} from 'lwc';
import GeFormService from 'c/geFormService';

export default class GeFormTable extends LightningElement {
    @track data = [];
    @api columns = [];

    connectedCallback() {
        GeFormService.getFormTemplate();
        console.log('GeFormService.fieldMappings: ', GeFormService.fieldMappings);
    }

    @api
    upsertRow(uid, dataImport){
        console.log('*** ' + 'upserting row in table' + ' ***');
        console.log('dataImport: ', dataImport);
        console.log('uid: ', uid);
        if (dataImport && !dataImport.hasOwnProperty('uid')) {
            dataImport.uid = uid;
        }
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
    //todo: if the record is new then it should be added to the top and the table should
            // be ordered desc by created date
            console.log('*** ' + 'this di is new' + ' ***');
            this.data.push(dataImport);
        }
        this.data = [...this.data]; //re-assign the table, to rerender it
    }
}