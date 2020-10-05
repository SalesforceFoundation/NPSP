import { LightningElement, track, api } from 'lwc';

export default class GsModal extends LightningElement {
    @track bShowModal = false;

    @api header;
    @api buttonLabel

    /**
     * Opens a salesforce like modal
     */
    @api
    openModal() {    
        this.bShowModal = true;
    }
 
    /**
     * Closes the modal
     */
    closeModal() {    
        this.bShowModal = false;
    }
}