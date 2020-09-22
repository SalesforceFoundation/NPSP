import { LightningElement, track } from 'lwc';

export default class NonProfit_GetProduct extends LightningElement {
    @track penndig = false;
    
    onGetFreeSldc(event) {
        this.penndig = true;
    }
}