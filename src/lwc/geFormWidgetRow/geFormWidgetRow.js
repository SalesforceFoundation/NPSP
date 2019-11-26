import {LightningElement, api, track} from 'lwc';

export default class GeFormWidgetRow extends LightningElement {
    @api rowIndex;
    @api rowRecord;
    @api fieldList;

    @api
    getValues() {
        const fields = this.template.querySelectorAll('c-ge-form-field');
        let widgetFieldAndValues = {};
        if(fields !== null && typeof fields !== 'undefined') {
            fields.forEach(field => {
                widgetFieldAndValues = { ...widgetFieldAndValues, ...(field.fieldAndValue) };
            });
        }
        // console.log(widgetFieldAndValues); 
        return widgetFieldAndValues;
    }

}