import { LightningElement, track, api } from 'lwc';
import GeLabelService from 'c/geLabelService';
// TODO: maybe import data import token field reference?

export default class geFormWidgetTokenizeCard extends LightningElement {

    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;
    
    @track token = 'token_placeholder';
    @api element;

    get tokenizeCardHeader() {
        return GeLabelService.format(
            this.CUSTOM_LABELS.geHeaderPaymentServices,
            [this.CUSTOM_LABELS.commonPaymentServices]);
    }
    // TODO: public method for returning widget data
    // TODO: method for calling tokenize method in iframe and retrieving the token

    @api
    load(){

    }
}