import {LightningElement, api, track} from 'lwc';

const LIGHTNING_INPUT_TYPES = ['CHECKBOX', 'CURRENCY', 'DATE', 'DATETIME', 'EMAIL', 'NUMBER', 'STRING', 'PHONE', 'TEXT', 'TIME', 'URL'];
const RICH_TEXT_TYPE = 'RICHTEXT';
const LOOKUP_TYPE = 'LOOKUP';
const PICKLIST_TYPE = 'PICKLIST';
const DELAY = 300;

export default class GeFormField extends LightningElement {
    @track value;
    @api element;
    changeTimeout;

    connectedCallback() {

    }

    handleValueChange(event) {
        this.value = event.target.value;
        window.clearTimeout(this.changeTimeout);
        this.changeTimeout = setTimeout(() => {
            // parent component (formSection) should bind to onchange event
            const evt = new CustomEvent('change', {field: this.element, value: this.value});
            console.log(evt); 
            this.dispatchEvent(evt);
        }, DELAY);
    }

    get isLightningInput() {
        return LIGHTNING_INPUT_TYPES.indexOf(this.element.dataType) !== -1;
    }

    get isRichText() {
        return this.element.dataType === RICH_TEXT_TYPE;
    }

    get isLookup() {
        return this.element.dataType === LOOKUP_TYPE;
    }

    get isPicklist() {
        return this.element.dataType === PICKLIST_TYPE;
    }
}