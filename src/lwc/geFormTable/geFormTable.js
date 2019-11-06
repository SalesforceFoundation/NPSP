import {LightningElement} from 'lwc';

export default class GeFormTable extends LightningElement {
    data = [{id:'newId'}];
    columns = [{label: 'ID', fieldName: 'id'}];
}