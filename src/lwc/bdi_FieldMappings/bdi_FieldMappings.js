import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import {
    registerListener,
    unregisterListener,
    unregisterAllListeners,
    fireEvent
} from 'c/pubsubNoPageRef';

export default class Bdi_FieldMappings extends LightningElement {

    @track displayFieldMappings = false;
    @track selectedObjectMapping = 'Opportunity';

    handleNavButton(event) {
        fireEvent(this.pageRef,'showobjectmappings');
    }

    connectedCallback() {
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
        this.selectedObjectMapping = event.objectMapping;
        this.displayFieldMappings = true;
        
    }
}