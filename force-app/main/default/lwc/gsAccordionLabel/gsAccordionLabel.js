import { LightningElement, api } from 'lwc';

export default class GsAccordionLabel extends LightningElement {

    /**
    * @description Number display on Icon
    * @type      String
    */
    @api number
    
    /**
    * @description Accordion title
    * @type      String
    */
    @api title
    
    /**
     * @description Total items rendered in the section
     * @type int
     */
    @api totalElements

    /**
     * @description Quatity of checked element in the section
     * @type int
     */
    @api checkedElements

    /**
    * @description Display event on click title
    * @type      void
    * @see       Event
    */
    onClickTitle() {
        this.dispatchEvent(new CustomEvent('clicktitle'));
    }
}