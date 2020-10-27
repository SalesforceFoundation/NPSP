import { LightningElement, api, track } from 'lwc';
import gsChecklistArrowRightAlterText from '@salesforce/label/c.gsChecklistArrowRightAlterText';
import gsChecklistArrowDownAlterText from '@salesforce/label/c.gsChecklistArrowDownAlterText';

/*
*  @description This class controller the checklist to render and his items
*/
export default class gsChecklist extends LightningElement {
    
    /**
    * @description Group of step in a checklist
    * @type      Checklist
    */
    @api group;
    @track open = false;


    /**
    * @description Click event handler to display or not info section
    * @return      void
    * @see         Action
    */
    onClickOpenOrClose(event) {
        this.open = !this.open;
    }
    
    /**
    * @description This method return a expanded Id
    * @return      String
    */
    get expandedId() {
        return `section-${this.group ? this.group.id : '0'}`;
    }

    /**
    * @description Return alter Text to arrow button
    * @return      String
    */
    get arrowAlterText() {
        return this.open ? gsChecklistArrowRightAlterText :  gsChecklistArrowDownAlterText;
    }

    /**
    * @description Return icon to arrow button
    * @return      String
    */
    get arrowIcon() {
        return this.open ? 'utility:chevrondown' :  'utility:chevronright';
    }

    /**
    * @description Return id to arrow button
    * @return      String
    */
    get arrowId() {
        return `arrow-${this.group ? this.group.id : '0'}`;
    }
}