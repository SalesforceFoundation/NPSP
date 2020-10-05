import { LightningElement, api, track } from 'lwc';

export default class gsChecklist extends LightningElement {
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
        if(this.displaySteps) {
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
        console.log('onClickOpenOrClose')
        this.open = !this.open;
    }
}