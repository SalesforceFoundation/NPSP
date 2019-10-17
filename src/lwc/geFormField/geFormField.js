import {LightningElement, api, track} from 'lwc';

const LIGHTNING_INPUT_TYPES = ['CHECKBOX', 'DATE', 'DATETIME', 'EMAIL', 'NUMBER', 'CURRENCY', 'TELEPHONE', 'TEXT', 'TIME', 'URL'];
const RICH_TEXT_TYPE = 'RICHTEXT';
const LOOKUP_TYPE = 'LOOKUP';
const PICKLIST_TYPE = 'PICKLIST';
const DELAY = 300;

export default class GeFormField extends LightningElement {
    @track value;
    @api field = {
        type: null,
        fieldName: null,
        objectApiName: null
    };
    changeTimeout;

    connectedCallback() {

    }

    handleValueChange(event) {
        this.value = event.target.value;
        window.clearTimeout(this.changeTimeout);
        this.changeTimeout = setTimeout(() => {
            // parent component (formSection) should bind to onchange event
            const evt = new CustomEvent('change', {field: this.field, value: this.value});
            this.dispatchEvent(evt);
        }, DELAY);
    }

    get isLightningInput() {
        return LIGHTNING_INPUT_TYPES.findIndex(this.field.type) !== -1;
    }

    get isRichText() {
        return this.field.type === RICH_TEXT_TYPE;
    }

    get isLookup() {
        return this.field.type === LOOKUP_TYPE;
    }

    get isPicklist() {
        return this.field.type === PICKLIST_TYPE;
    }
}