import { LightningElement, track, api } from 'lwc';

export default class GsModal extends LightningElement {
    @track bShowModal = false;

    @api header;
    @api buttonLabel

    
    @api
    openModal() {    
        // to open modal window set 'bShowModal' tarck value as true
        this.bShowModal = true;
    }
 
    closeModal() {    
        // to close modal window set 'bShowModal' tarck value as false
        this.bShowModal = false;
    }
}