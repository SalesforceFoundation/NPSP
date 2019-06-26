import { LightningElement, track, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getFieldMappingsByObjectAndFieldSetNames from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.getFieldMappingsByObjectAndFieldSetNames';
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
    { label: 'Field Label', fieldName: 'Source_Field_Label', type: 'text', sortable: true },
    { label: 'Field API Name', fieldName: 'Source_Field_API_Name', type: 'text' },
    { label: 'Data Type', fieldName: 'Source_Field_Data_Type', type: 'text' },
        {
            label: 'Maps To', fieldName: '', type: 'text',
            cellAttributes: { iconName: { fieldName: 'Maps_To_Icon' }, iconPosition: 'right' }
        },
    { label: 'Field Label', fieldName: 'MasterLabel', type: 'text' },
    { label: 'Field API Name', fieldName: 'Target_Field_API_Name', type: 'text' },
    { label: 'Data Type', fieldName: '', type: 'text' },
    { type: 'action', typeAttributes: { rowActions: actions } }
];

export default class Bdi_FieldMappings extends LightningElement {

    @track displayFieldMappings = false;
    @track isLoading = true;
    @track isModalOpen = false;
    @track fieldMappings;
    @track columns = columns;

    @api objectMapping = {
        DeveloperName: 'Payment',
        MasterLabel: 'Payment',
        Object_API_Name__c: 'npe01__OppPayment__c'};
    @api forceRefresh() {
        this.handleFieldMappings();
    }

    handleNavButton(event) {
        fireEvent(this.pageRef, 'showobjectmappings');
    }

    connectedCallback() {
        console.log('bdi_FieldMappings | connectedCallback()');
        registerListener('showobjectmappings', this.handleShowObjectMappings, this);
        registerListener('showfieldmappings', this.handleShowFieldMappings, this);
        registerListener('closeModal', this.handleCloseModal, this);

        // TODO: delete later, using so I can hop directly into the field mappings
        // component via a url addressable harness aura component
        this.handleFieldMappings();
        this.displayFieldMappings = true;
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

    handleOpenModal() {
        console.log('bdi_FieldMappings | handleOpenModal()');
        console.log(this.log(this.objectMapping));
        fireEvent(this.pageRef,'openModal', { objectMapping: this.objectMapping });
    }

    handleCloseModal(event) {
        console.log('CLOSE NEW FIELD MAPPING MODAL');
        this.isModalOpen = false;
    }

    /*******************************************************************************
    * @description Call apex method 'getFieldMappingsByObjectMappingName' to get
    * a list of field mappings by their parent object mapping name
    *
    * @param name: Name of the object mapping received from parent component 
    */
    handleFieldMappings = function () {
        console.log('getFieldMappings()');
        getFieldMappingsByObjectAndFieldSetNames({
                objectSetName: this.objectMapping.DeveloperName,
                // TODO: Get field set name dynamically
                fieldSetName: 'Migrated_Custom_Field_Mapping_Set'
            })
            .then((data) => {
                this.fieldMappings = data;
                this.isLoading = false;
            })
            .catch((error) => {
                console.log(error);
                this.isLoading = false;
            });
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

    // TODO: Delete later
    /*******************************************************************************
    * @description Parse proxy objects for debugging, mutating, etc
    *
    * @param object: Object to be parsed
    */
    log(object) {
        return JSON.parse(JSON.stringify(object));
    }
}