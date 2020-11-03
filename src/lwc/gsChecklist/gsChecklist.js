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
    
}