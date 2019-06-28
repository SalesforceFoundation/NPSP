import { LightningElement, track, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { CurrentPageReference } from 'lightning/navigation';
import getFieldMappingsByObjectAndFieldSetNames from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.getFieldMappingsByObjectAndFieldSetNames';
import { registerListener, unregisterListener, unregisterAllListeners, fireEvent} from 'c/pubsubNoPageRef';
import createDataImportFieldMapping
    from '@salesforce/apex/BDI_ManageAdvancedMappingCtrl.createDataImportFieldMapping';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import DATAIMPORT_OBJECT from '@salesforce/schema/DataImport__c';

const actions = [
    { label: 'Edit', name: 'edit' },
    { label: 'Delete', name: 'delete' },
];

const columns = [
    { label: 'Field Label', fieldName: 'Source_Field_Label_xxx', type: 'text', sortable: true },
    { label: 'Field API Name', fieldName: 'Source_Field_API_Name_xxx', type: 'text' },
    { label: 'Data Type', fieldName: 'Source_Field_Data_Type_xxx', type: 'text' },
        {
            label: 'Maps To', fieldName: '', type: 'text',
            cellAttributes: { iconName: { fieldName: 'Maps_To_Icon' }, iconPosition: 'right' }
        },
    { label: 'Field Label', fieldName: 'Target_Field_Label_xxx', type: 'text' },
    { label: 'Field API Name', fieldName: 'Target_Field_API_Name_xxx', type: 'text' },
    { label: 'Data Type', fieldName: 'Target_Field_Data_Type_xxx', type: 'text' },
    { type: 'action', typeAttributes: { rowActions: actions } }
];

export default class bdiFieldMappings extends LightningElement {

    @track diObjectInfo;
 
    @wire(getObjectInfo, { objectApiName: DATAIMPORT_OBJECT })
    diObjectInfo;

    @track displayFieldMappings = false;
    @track isLoading = true;
    @track isModalOpen = false;
    @track columns = columns;
    @api objectMapping = {
        Id: 'm034P000000buts',
        DeveloperName: 'Payment',
        MasterLabel: 'Payment',
        Object_API_Name__c: 'npe01__OppPayment__c'
    };

    @track fieldMappings;
    wiredFieldMappings
    @wire(getFieldMappingsByObjectAndFieldSetNames, { objectSetName: '$objectMapping.DeveloperName', fieldSetName: 'Migrated_Custom_Field_Mapping_Set' })
    fieldMappingsWiring(result) {
        this.wiredFieldMappings = result;
        if (result.data) {
            this.fieldMappings = result.data;
        }
    }

    @api
    forceRefresh() {
        console.log('attempting to refresh');
        return refreshApex(this.wiredFieldMappings); 
    }

    handleNavButton(event) {
        fireEvent(this.pageRef, 'showobjectmappings');
    }

    connectedCallback() {
        console.log('bdiFieldMappings | connectedCallback()');
        let outerThis = this;
        setTimeout(function() {
            console.log('%c Object Schema Data: ', 'font-size: 16px; font-weight: bold;');
            console.log(JSON.parse(JSON.stringify(outerThis.diObjectInfo.data)));
        }, 3000, outerThis);

        registerListener('showobjectmappings', this.handleShowObjectMappings, this);
        registerListener('showfieldmappings', this.handleShowFieldMappings, this);
        registerListener('deleteRowFromTable', this.handleDeleteRowFromTable, this);
        registerListener('forceRefresh', this.forceRefresh, this);

        // TODO: delete later, using so I can hop directly into the field mappings
        // component via a url addressable harness aura component
        this.handleFieldMappings();
        //this.displayFieldMappings = true;
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    handleShowObjectMappings(event) {
        console.log('In handleShowObjectMappings for fieldmappings cmp');
        this.displayFieldMappings = false;
    }

    handleShowFieldMappings(event) {
        this.logBold('In handleShowFieldMappings for fieldmappings cmp');
        this.objectMapping = event.objectMapping;
        this.displayFieldMappings = true;
        this.forceRefresh();
    }

    handleOpenModal() {
        console.log('bdiFieldMappings | handleOpenModal()');
        console.log(this.log(this.objectMapping));
        fireEvent(this.pageRef, 'openModal', { objectMapping: this.objectMapping, row: undefined });
    }

    /*******************************************************************************
    * @description Call apex method 'getFieldMappingsByObjectMappingName' to get
    * a list of field mappings by their parent object mapping name
    *
    * @param name: Name of the object mapping received from parent component 
    */
    handleFieldMappings = function () {
        console.log('bdiFieldMappings | getFieldMappings()');
        getFieldMappingsByObjectAndFieldSetNames({
                objectSetName: this.objectMapping.DeveloperName,
                // TODO: Get field set name dynamically
                fieldSetName: 'Migrated_Custom_Field_Mapping_Set'
            })
            .then((data) => {
                console.log('Field Mappings: ', this.log(data));
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
        console.log('bdiFieldMappings | handleRowAction()');
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {

            case 'delete':
                console.log('DELETE ACTION');
                this.isLoading = true;

                row.Is_Deleted__c = true;
                let clonedRow = JSON.stringify(row);

                createDataImportFieldMapping({fieldMappingString: clonedRow})
                    .then((data) => {
                        console.log(this.log(data));
                        this.handleDeleteRowFromDatatable(row);
                        this.isLoading = false;
                        this.showToast(
                            'Success',
                            'Field mapping has been deleted.',
                            'success');
                    })
                    .catch((error) => {
                        console.log(error);
                        this.isLoading = false;
                        this.showToast(
                            'Error',
                            '{0}. {1}. {2}.',
                            'error',
                            'sticky',
                            [error.body.exceptionType, error.body.message, error.body.stackTrace]);
                    });
                break;

            case 'edit':
                console.log('EDIT ACTION');
                console.log('Row: ', this.log(row));
                fireEvent(this.pageRef,'openModal', {
                    objectMapping: this.objectMapping,
                    row: row });
                break;

            default:
        }
    }

    handleDeleteRowFromDatatable(row) {
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

    showToast(title, message, variant, mode, messageData) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode,
            messageData: messageData
        });
        this.dispatchEvent(event);
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

    logBold(string) {
        return console.log('%c ' + string, 'font-weight: bold; font-size: 16px;');
    }
}