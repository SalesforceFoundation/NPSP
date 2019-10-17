import { LightningElement, api } from 'lwc';

export default class UtilDockedFormFooter extends LightningElement {
    @api assistiveText;
    @api ariaLabel;
}