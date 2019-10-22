import {LightningElement, api, track} from 'lwc';
import { getFormTemplate } from 'c/geFormService';

export default class GeFormRenderer extends LightningElement {
    @track sections = [];
    @track ready = false;
    @track name = '';
    @track description = '';
    @track mappingSet = '';
    @track version = '';

    // connectedCallback() {
    //     getFormTemplate().then(response => {

    //         // read the template header info
    //         if(response !== null && typeof response !== 'undefined') {
    //             this.ready = true;
    //             this.name = response.name;
    //             this.description = response.description;
    //             this.mappingSet = response.layout.fieldMappingSetDevName;
    //             this.version = response.layout.version;

    //             if (response.layout !== null && typeof response.layout !== 'undefined' && Array.isArray(response.layout.sections)) {
    //                 this.sections = response.layout.sections;              
    //             }
    //         }
    //     });
    // }

    connectedCallback() {
        getFormTemplate()
        .then(response => {
            this.sections = response.formTemplate.layout.sections;
        });
    }


}