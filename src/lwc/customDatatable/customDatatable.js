import LightningDatatable from 'lightning/datatable';
import picklistTypeTemplate from './picklistTypeTemplate.html';

export default class customDatatable extends LightningDatatable {
    static customTypes = {
        picklistType: {
            template: picklistTypeTemplate,
            typeAttributes: ['label', 'placeholder', 'options', 'keyField', 'disabled'],
        }
    };
}