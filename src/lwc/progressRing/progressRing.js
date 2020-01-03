import { LightningElement, api, track } from 'lwc';

import textActive from '@salesforce/label/c.AssistiveTextActive';
import textComplete from '@salesforce/label/c.AssistiveTextComplete';
import textError from '@salesforce/label/c.AssistiveTextError';
import textWarning from '@salesforce/label/c.AssistiveTextWarning';

export default class ProgressRing extends LightningElement {

    @api ringContent = '';
    @api ringSize;

    @track ringClass;
    @track arcValue;
    @track isContentVisible = false;
    @track isComplete = false;
    @track iconName = '';
    @track assistiveText = '';

    @api
    get valueNow() {
        return this._valueNow;
    }

    /***
    * @description Sets current progress value and determines the "d" parameter for the progress ring
    * @param value Current progress value
    */
    set valueNow(value) {
        this._valueNow = value === undefined || value === null ? 0 : value;
        let max = 100;

        let arcX = Math.cos(2 * Math.PI * this._valueNow / max);
        let arcY = Math.sin(2 * Math.PI * this._valueNow / max) * -1;
        let isLong = this._valueNow === max ? 1 : Math.floor(this._valueNow / 50);
        isLong = isLong > 1 ? 1 : isLong;

        this.arcValue = "M 1 0 A 1 1 0 " + isLong + " 0 " + arcX + " " + arcY + " L 0 0";

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
        if (this.ringSize === undefined || this.ringSize === null) {
            this.ringSize = 'slds-progress-ring_medium';
        }

        this.ringClass = 'slds-progress-ring ' + this.ringSize;
        this.isComplete = false;
        this.iconName = '';
        this.assistiveText = value;

        switch (value) {
            case 'warning':
                this.ringClass += ' slds-progress-ring_warning';
                this.iconName = 'utility:warning';
                this.assistiveText = `${textWarning}`;
                break;
            case 'error':
                this.ringClass += ' slds-progress-ring_expired';
                this.iconName = 'utility:error';
                this.assistiveText = `${textError}`;
                break;
            case 'active':
                this.ringClass += ' slds-progress-ring_active-step';
                this.assistiveText = `${textActive}`;
                break;
            case 'complete':
                this.ringClass += ' slds-progress-ring_complete';
                this.isComplete = true;
                this.iconName = 'utility:check';
                this.assistiveText = `${textComplete}`;
                break;
            default:
        }

        this.isContentVisible = this.iconName === '';
    }
}