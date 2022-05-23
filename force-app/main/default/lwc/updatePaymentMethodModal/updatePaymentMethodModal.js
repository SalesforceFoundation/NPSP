import { LightningElement, api } from 'lwc';
import updatePaymentMethod from '@salesforce/label/c.updatePaymentMethod';
export default class UpdatePaymentMethodModal extends LightningElement {
    @api openUpdatePaymentMethod;

    labels = {
        updatePaymentMethod
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('close', {detail: 'updatePaymentMethod'}));
    } 
}