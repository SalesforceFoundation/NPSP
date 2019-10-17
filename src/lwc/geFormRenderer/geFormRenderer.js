import {LightningElement, api, track} from 'lwc';
import { getFormTemplate } from 'c/geFormService';

export default class GeFormRenderer extends LightningElement {
    @track sections = [];

    connectedCallback() {

        getFormTemplate().then(response => {
            if(response !== null && typeof response !== 'undefined' && Array.isArray(response.layout.sections)) {
                console.log(response.layout.sections);
                this.sections = response.layout.sections;
                // this.ready = true;
            }
        });

    }

}