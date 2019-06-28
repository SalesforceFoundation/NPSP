import { LightningElement, api, wire, track } from 'lwc';
import getObjectMappings from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.getObjectMappings';
import { CurrentPageReference } from 'lightning/navigation';
import {
    registerListener,
    unregisterListener,
    unregisterAllListeners,
    fireEvent
} from 'c/pubsubNoPageRef';

const actions = [
    { label: 'Field Mappings', name: 'goToFieldMappings' },
    { label: 'Delete', name: 'delete' }
];

const columns = [
    {label: 'Object Mapping Name', fieldName: 'MasterLabel', type: 'text'},
    {label: 'Object API Name', fieldName: 'Object_API_Name__c', type: 'text'},
    {label: 'Is Child/Parent', fieldName: 'Relationship_To_Predecessor__c', type: 'text'},
    {label: 'Of This Object Mapping', fieldName: 'Predecessor__c', type: 'text'},
    {label: 'Through This Field', fieldName: 'Relationship_Field__c', type: 'text'},
    { label: 'Field Mapping', fieldName: 'url', type: 'url' },
    { type: 'action', typeAttributes: { rowActions: actions }}
];

export default class Bdi_ObjectMappings extends LightningElement {
    @track error;
    @track columns = columns;
    @track displayObjectMappings = true;

    @wire(getObjectMappings) objectMappings;

    /*
    handleNavButton(event) {
        const showFieldMappings = new CustomEvent('showFieldMappings', {
            detail: 'Opportunity',
        });
        this.dispatchEvent(showFieldMappings);
    }
    */

    handleNavButton(event) {
        console.log('In handleNavButton');
        fireEvent(this.pageRef,'showfieldmappings',{objectMapping:'Contact1'});
    }

    connectedCallback() {
        console.log('bdi_ObjectMappings | connectedCallback()');
        registerListener('showobjectmappings', this.handleShowObjectMappings, this);
        registerListener('showfieldmappings', this.handleShowFieldMappings, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    handleShowObjectMappings(event) {
        console.log('In handleShowObjectMappings for objectmappings cmp');
        this.displayObjectMappings = true;
    }

    handleShowFieldMappings(event) {

        console.log('In handleShowFieldMappings for objectmappings cmp' + event.objectMapping);
        console.log(event);
        this.displayObjectMappings = false;
    }

    handleRowAction(event) {
        console.log('bdi_FieldMappings | handleRowAction()');
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        console.log({actionName, row});
        switch (actionName) {

            case 'goToFieldMappings':
                console.log('GOTOFIELDMAPPING ACTION');
                fireEvent(this.pageRef,'showfieldmappings', {objectMapping:row});
                break;

            case 'delete':
                alert('Row deleted from datatable in UI, send delete event');
                this.dispatchMessage('deletefieldmapping', row);
                this.deleteRowFromDatatable(row);
                break;

            default:
        }
    }
}
