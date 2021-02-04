import LightningDatatable from 'lightning/datatable';
import picklistTypeTemplate from './picklistTypeTemplate.html';
import { loadStyle } from 'lightning/platformResourceLoader';
import CUMULUS_STATIC_RESOURCES from '@salesforce/resourceUrl/CumulusStaticResources';

export default class customDatatable extends LightningDatatable {
    /***
    * @description Defines custom data types by specifying
    * data type template and which typeAttributes data will be passed to the template.
    * 
    */
    static customTypes = {
        picklistType: {
            template: picklistTypeTemplate,
            typeAttributes: ['label', 'placeholder', 'options', 'keyField', 'disabled'],
        }
    };

    /***
    * @description Loads custom datatable CSS from the static resources
    */
    connectedCallback() {
        Promise.all([
            loadStyle(this, CUMULUS_STATIC_RESOURCES + '/customDatatable/style.css')
        ]).then(() => {

        }).catch(error => {
            console.error('Error loading static resource: ' + JSON.stringify(error));
        });
    }
}