import { LightningElement, track, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getFieldMappingsByObjectMappingName from '@salesforce/apex/BDI_FieldMappingsCtrl.getFieldMappingsByObjectMappingName';
import {
    registerListener,
    unregisterListener,
    unregisterAllListeners,
    fireEvent
} from 'c/pubsubNoPageRef';

const actions = [
    { label: 'Edit', name: 'edit' },
    { label: 'Delete', name: 'delete' },
];

const columns = [
    { label: 'Field Label', fieldName: 'sourceFieldLabel', type: 'text', sortable: true },
    { label: 'Field API Name', fieldName: 'Source_Field_API_Name__c', type: 'text' },
    { label: 'Data Type', fieldName: 'sourceFieldDataType', type: 'text' },
        {
            label: 'Maps To', fieldName: '', type: 'text',
            cellAttributes: { iconName: { fieldName: 'mapsToIcon' }, iconPosition: 'right' }
        },
    { label: 'Field Label', fieldName: 'MasterLabel', type: 'text' },
    { label: 'Field API Name', fieldName: 'Target_Field_API_Name__c', type: 'text' },
    { label: 'Data Type', fieldName: '', type: 'text' },
    { type: 'action', typeAttributes: { rowActions: actions } }
];

export default class Bdi_FieldMappings extends LightningElement {

    @track displayFieldMappings = false;
    @track selectedObjectMapping = 'Opportunity';
    @api objectMapping;
    @track fieldMappings;
    @track columns = columns;
    @api forceRefresh() {
        this.getFieldMappings();
    }

    handleNavButton(event) {
        fireEvent(this.pageRef, 'showobjectmappings');
    }

    connectedCallback() {
        console.log('bdi_FieldMappings | connectedCallback()');
        registerListener('showobjectmappings', this.handleShowObjectMappings, this);
        registerListener('showfieldmappings', this.handleShowFieldMappings, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    handleShowObjectMappings(event) {
        console.log('In handleShowObjectMappings for fieldmappings cmp');
        this.displayFieldMappings = false;
    }

    handleShowFieldMappings(event) {
        console.log('In handleShowFieldMappings for fieldmappings cmp');
        this.objectMapping = event.objectMapping;
        this.displayFieldMappings = true;
        this.forceRefresh();

    }

    /*******************************************************************************
    * @description Call apex method 'getFieldMappingsByObjectMappingName' to get
    * a list of field mappings by their parent object mapping name
    *
    * @param name: Name of the object mapping received from parent component 
    */
    getFieldMappings = function () {
        console.log('getFieldMappings()');
        getFieldMappingsByObjectMappingName({ name: this.objectMapping.DeveloperName })
            .then((data) => {
                this.fieldMappings = this.addMapsToIconProperty(data);
                console.log('received data: ', this.log(data));
                console.log('fieldMappings: ', this.log(this.fieldMappings));
            })
            .catch((error) => {
                this.message = 'Error received: code' + error.errorCode + ', ' +
                    'message ' + error.body.message;
                console.log(this.message);
            });
    }

    /*******************************************************************************
    * @description Adds icon property to each row (field mapping) for the
    * 'Maps To' column in the datatable
    *
    * @param fieldMappings: List of field mappings
    * @return list: List of field mappings with added mapsToIcon attribute
    */
    addMapsToIconProperty = function (fieldMappings) {
        let list = [];
        fieldMappings.forEach((mapping) => {
            mapping = this.log(mapping);
            mapping.dataImportFieldMapping.mapsToIcon = 'utility:forward';
            mapping.dataImportFieldMapping.sourceFieldLabel = mapping.sourceFieldLabel;
            mapping.dataImportFieldMapping.sourceFieldDataType = mapping.sourceFieldDataType;
            mapping = mapping.dataImportFieldMapping;
            list.push(mapping);
        });
        return list;
    }

    /*******************************************************************************
    * @description Action handler for datatable row actions (i.e. edit, delete)
    *
    * @param event: Event containing row details of the action
    */
    handleRowAction(event) {
        console.log('bdi_FieldMappings | handleRowAction()');
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'delete':
                console.log('DELETE ACTION');
                this.deleteRowFromDatatable(row);
                alert('Row deleted from datatable in UI, send delete event');
                // TODO: Add logic to mark field mapping's field isDeleted = true
                // Are we going to fire off a 'delete' deployment for every single delete?
                // Or would it be possible to potentially queue up and send off deletes
                // as a group? Probably not a good idea. One deployment per delete seems safest.
                break;
            case 'edit':
                console.log('EDIT ACTION');
                console.log('Row: ', this.log(row));
                alert('Send edit field mapping event to parent container');
                // TODO: Add logic to send event to parent container / edit component containing
                // data on the row (field mapping) to be editted.
                break;
            default:
        }
    }

    deleteRowFromDatatable(row) {
        const { id } = row;
        const index = this.findRowIndexById(id);
        if (index !== -1) {
            this.fieldMappings = this.fieldMappings
                .slice(0, index)
                .concat(this.fieldMappings.slice(index + 1));
        }
    }

    findRowIndexById(id) {
        let ret = -1;
        this.fieldMappings.some((row, index) => {
            if (row.id === id) {
                ret = index;
                return true;
            }
            return false;
        });
        return ret;
    }

    handleNewFieldMapping() {
        console.log('bdi_FieldMappings | handleNewFieldMapping()');
        alert('Send create new field mapping event to parent container');
    }

    /*******************************************************************************
    * @description Parse proxy objects for debugging, mutating, etc
    *
    * @param object: Object to be parsed
    */
    log(object) {
        return JSON.parse(JSON.stringify(object));
    }
}