import { LightningElement, api } from 'lwc';
import { isEmpty } from 'c/utilCommon';

export default class AlertBanner extends LightningElement {
    @api _alertClass;
    @api assistText;
    @api alertIcon;
    @api variant;
    @api size;
    @api isDisplayed;
    @api message;

    defaultClass = 'slds-notify slds-notify_alert slds-theme_alert-texture';

    get alertClass() {
        if(isEmpty(this._alertClass)) {
            this._alertClass = this.defaultClass + ' slds-theme_warning';
        }
        return this._alertClass;
    }
}