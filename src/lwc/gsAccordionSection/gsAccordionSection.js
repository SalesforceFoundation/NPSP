import { LightningElement, api } from 'lwc';

export default class GsAccordionSection extends LightningElement {

    /**
    * @description Is Open Accordion
    * @type      Boolean
    */
    @api open;

    /**
    * @description Label alway display
    * @type      String
    */
    @api label;

    /**
    * @description Expand component aria Id 
    * @type      String
    */
    @api expandedId;

    /**
    * @description Return css class to display info section
    * @return      String
    * @see         Css class
    */
    get infoClass() {
        const classNames = ['slds-media', 'info'];
        if (this.open) {
            classNames.push('open');
        }
        return classNames.join(' '); 
    }

    /**
    * @description Return to display the the collapsable panel
    * @return      Boolean
    */
    get notOpen() {
        return !this.open;
    }
    
}