import { LightningElement, api } from 'lwc';

export default class GeFormField extends LightningElement {
    @api element;
    @api targetFieldName;
    @api formState;
}