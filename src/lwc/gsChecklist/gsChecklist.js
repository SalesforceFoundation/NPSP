import { LightningElement, api, track } from 'lwc';
import gsChecklistArrowRightAltText from '@salesforce/label/c.gsChecklistArrowRightAlterText';
import gsChecklistArrowDownAltText from '@salesforce/label/c.gsChecklistArrowDownAlterText';

/*
*  @description This class controller the checklist to render and his items
*/
export default class gsChecklist extends LightningElement {
    
    /**
    * @description Group of step in a checklist
    * @type      Checklist
    */
    @api group;
    
}