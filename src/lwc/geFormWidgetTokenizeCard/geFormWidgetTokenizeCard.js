import { LightningElement, track } from 'lwc';
import GeLabelService from 'c/geLabelService';
// TODO: maybe import data import token field reference?

export default class geFormWidgetTokenizeCard extends LightningElement {

    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;
    
    @track token = 'token_placeholder';

    // TODO: public method for returning widget data
    // TODO: method for calling tokenize method in iframe and retrieving the token
}