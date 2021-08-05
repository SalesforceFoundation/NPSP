import { LightningElement, api } from 'lwc';

export default class Rd2ChangeHistory extends LightningElement {
    @api recordId;
    @api changeTypeFilter;
    @api recordLimit;
}