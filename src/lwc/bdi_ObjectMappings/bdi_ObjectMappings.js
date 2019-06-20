import { LightningElement, api, wire, track } from 'lwc';
import getObjectMappings from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.getObjectMappings';
const columns = [
    {label: 'Object Mapping Name', fieldName: 'MasterLabel', type: 'text'},
    {label: 'Object API Name', fieldName: 'Object_API_Name__c', type: 'text'},
    {label: 'Is Child/Parent', fieldName: 'Relationship_To_Predecessor__c', type: 'text'},
    {label: 'Of This Object Mapping', fieldName: 'Predecessor__c', type: 'text'},
    {label: 'Through This Field', fieldName: 'Relationship_Field__c', type: 'text'}
];

export default class Bdi_ObjectMappings extends LightningElement {
    @api name;
    @track error;
    @track columns = columns;
    @wire(getObjectMappings) objectMappings;

}
