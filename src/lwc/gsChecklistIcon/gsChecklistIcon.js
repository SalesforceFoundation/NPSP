import { LightningElement, api } from 'lwc';

export default class gsChecklistIcon extends LightningElement {

    @api label = 1;
    @api totalItem;
    /**
     * @description Quantity of checked items in the section
     */
    @api 
    get checkedItem() {
        return this._checkedItem;
    }
    set checkedItem(value) {
        if (this.totalItem !== undefined) {
            this.percentage = (value / this.totalItem) * 100; 
        }
    }

    /**
     * @description Calculated value of the progress ring
     */
    percentage = 0;
}