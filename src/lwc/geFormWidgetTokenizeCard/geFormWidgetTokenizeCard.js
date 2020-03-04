import { LightningElement, api, track } from 'lwc';
import GeLabelService from 'c/geLabelService';
// import purchase call method
// import data import token field reference

export default class geFormWidgetTokenizeCard extends LightningElement {

    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;
    
    @track token = 'token_placeholder';

    @api
    returnValues() {
        return {
            
        };
        //return { data import token field reference : token }
    }

    retrieveTokenFromIframe() {
        //
    }
}