import { LightningElement, api} from 'lwc';

export default class rd2EntryFormCustomFieldsSection extends LightningElement {
    @api recordId;
    @api fields;

    /**
     * @description Checks if values specified on fields are valid
     * @return Boolean
     */
    @api
    isValid() {
        let isValid = true;
        this.template.querySelectorAll('lightning-input-field')
            .forEach(field => {
                if (!field.reportValidity()) {
                    isValid = false;
                }
            });
        return isValid;
    }

    /**
     * @description Returns fields displayed on the child component to the parent form
     * @return Object containing field API names and their values
     */
    @api
    returnValues() {
        let data = {};

        this.template.querySelectorAll('lightning-input-field')
            .forEach(field => {
                data[field.fieldName] = field.value;
            });

        return data;
    }

    /**
    * @description reset all lighning-input-field value 
    */
    @api
    resetValues() {
    this.template.querySelectorAll('lightning-input-field')
        .forEach(field => {
            if (field.value) {
                field.reset();
            }
        });
    }
}