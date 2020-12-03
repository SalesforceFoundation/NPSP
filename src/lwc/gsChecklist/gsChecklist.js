import { LightningElement, api, track } from 'lwc';


/*
*  @description This class controller the checklist to render and his items
*/
export default class gsChecklist extends LightningElement {
    
    /**
    * @description Group of step in a checklist
    * @type      Checklist
    */
    @api group;

    /**
     * @description Quantity of checked items in the section
     */
    @track checkedItems = 0;

    connectedCallback() {
        this.group.items.forEach(item => {
            if (item.checked) {
                this.checkedItems++;
            }
        });
    }

    /**
     * @description event handler when an element is checked
     */
    handleChecked() {
        this.checkedItems++;
    }

    /**
     * @description event handler when an element is unchecked
     */
    handleUnchecked() {
        this.checkedItems--;
    }
    
}