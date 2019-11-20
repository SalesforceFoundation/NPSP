import { LightningElement, api } from 'lwc';

export default class utilPageMessage extends LightningElement {
    @api title;
    @api subtitle;
    @api errors;

    get titleText() {
        return this.title ? this.title : 'Review the errors on this page.';
    }

    get subtitleText() {
        return this.subtitle ? this.subtitle : '';
    }

    renderedCallback() {
        console.log('renderedCallback: ', this.errors);
    }
}