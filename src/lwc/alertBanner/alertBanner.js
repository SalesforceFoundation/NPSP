import { LightningElement, api } from 'lwc';
import { isEmpty } from 'c/utilCommon';

export default class AlertBanner extends LightningElement {
    @api _alertClass;
    @api _variant;
    @api _assistText;
    @api _alertIcon;
    @api variant;
    @api _size;
    @api isDisplayed;
    @api message;

    defaultClass = 'slds-notify slds-notify_alert slds-theme_alert-texture';

    get alertClass() {
        const warningThemeDefault = 'slds-theme_warning';
        if(isEmpty(this._alertClass)) {
            this._alertClass = this.defaultClass + ' ' + warningTheme;
        }
        return this._alertClass;
    }

    get variant() {
        const variantInverseDefault = 'inverse';
        if(isEmpty(this._variant)) {
            this._variant = variantInverse;
        }
        return this._variant;
    }

    get alertIcon() {
        const iconDefault = 'utility:warning';
        if(isEmpty(this._alertIcon)) {
            this._alertIcon = iconDefault;
        }
        return this._alertIcon;
    }

    get size() {
        const sizeDefault = 'x-small';
        if(isEmpty(this._size)) {
            this._size = sizeDefault;
        }
        return this._size;
    }
}