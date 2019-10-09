import { LightningElement, api, track } from 'lwc';

import textActive from '@salesforce/label/c.AlternativeTextActive';
import textComplete from '@salesforce/label/c.AlternativeTextComplete';
import textError from '@salesforce/label/c.AlternativeTextError';
import textWarning from '@salesforce/label/c.AlternativeTextWarning';

export default class ProgressRing extends LightningElement {

    @api ringContent = '';

    @track ringClass = 'slds-progress-ring slds-progress-ring_large ';
    @track arcValue;
    @track displayContent = false;
    @track isComplete = false;
    @track iconName = '';
    @track alternativeText = '';

    @api
    get valueNow() {
        return this._valueNow;
    }

    /***
    * @description Sets current progress value and determines the "d" parameter for the progress ring
    * @param value Current progress value
    */
    set valueNow(value) {
        this._valueNow = value;
        let max = 100;
        let quotient = value / max >= 0.5 ? "1" : "0";

        this.arcValue = "M 1 0 A 1 1 0 " + quotient + " 1 " +
            Math.cos(2 * Math.PI * value / max) + " " +
            Math.sin(2 * Math.PI * value / max) + " L 0 0";

        this.setAttribute('d', this.arcValue);
    }

    @api
    get status() {
        return this._status;
    }

    /***
    * @description Sets progress status properties
    * @param value Progress status: active, complete, warning, error, or any other value
    */
    set status(value) {
        this.ringClass = 'slds-progress-ring slds-progress-ring_large';
        this.isComplete = false;
        this.iconName = '';
        this.alternativeText = value;

        switch (value) {
            case 'warning':
                this.ringClass += ' slds-progress-ring_warning';
                this.iconName = 'utility:warning';
                this.alternativeText = `${textWarning}`;
                break;
            case 'error':
                this.ringClass += ' slds-progress-ring_expired';
                this.iconName = 'utility:error';
                this.alternativeText = `${textError}`;
                break;
            case 'active':
                this.ringClass += ' slds-progress-ring_active-step';
                this.alternativeText = `${textActive}`;
                break;
            case 'complete':
                this.ringClass += ' slds-progress-ring_complete';
                this.isComplete = true;
                this.iconName = 'utility:check';
                this.alternativeText = `${textComplete}`;
                break;
            default:
                this.ringClass = 'slds-progress-ring slds-progress-ring_large';
        }

        this.displayContent = this.iconName === '';
    }
}