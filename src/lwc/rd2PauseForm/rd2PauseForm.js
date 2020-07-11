import { LightningElement, api } from 'lwc';

import cancelButton from '@salesforce/label/c.stgBtnCancel';
import saveButton from '@salesforce/label/c.stgBtnSave';
import header from '@salesforce/label/c.RD2_PauseHeader';
import description from '@salesforce/label/c.RD2_PauseDescription';

export default class Rd2PauseForm extends LightningElement {

    labels = Object.freeze({
        cancelButton,
        saveButton,
        header,
        description
    });

    @api recordId;

    /***
    * @description 
    */
    handleCancel() {
        this.closeModal();
    }

    /***
    * @description 
    */
    handleSave() {
        this.closeModal();
    }

    closeModal() {
        const closeEvent = new CustomEvent('close');
        this.dispatchEvent(closeEvent);
    }

}