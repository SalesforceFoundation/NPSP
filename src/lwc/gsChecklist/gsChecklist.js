import { LightningElement, api, track } from 'lwc';
import gsChecklistArrowRightAlterText from '@salesforce/label/c.gsChecklistArrowRightAlterText';
import gsChecklistArrowDownAlterText from '@salesforce/label/c.gsChecklistArrowDownAlterText';

export default class gsChecklist extends LightningElement {
    
    /**
    * Group of step in a checklist
    * @type      Checklist
    */
    @api group;
    @track open = false;

    /**
    * Return if display the checklist item step
    * @return      Boolean
    * @see         Boolean
    */
    get displaySteps() {
        return this.open;
    }

    /**
    * Return css class to display info section
    * @return      String
    * @see         Css class
    */
    get infoClass() {
        const classNames = ['slds-media', 'info'];
        if (this.displaySteps) {
            classNames.push('open');
        }
        return classNames.join(' '); 
    }

    /**
    * Click event handler to display or not info section
    * @return      void
    * @see         Action
    */
    onClickOpenOrClose(event) {
        this.open = !this.open;
    }
    
    get expandedId() {
        return `section-${this.group ? this.group.id : '0'}`;
    }

    get notOpen() {
        return !this.open;
    }

    get arrowAlterText() {
        return this.open ? gsChecklistArrowRightAlterText :  gsChecklistArrowDownAlterText;
    }

    get arrowIcon() {
        return this.open ? 'utility:chevrondown' :  'utility:chevronright';
    }

    get arrowId() {
        return `arrow-${this.group ? this.group.id : '0'}`;
    }
}