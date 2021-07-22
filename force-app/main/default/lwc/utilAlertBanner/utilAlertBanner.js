import { LightningElement, api } from 'lwc';
import { isEmpty } from 'c/utilCommon';

const defaultClass = 'slds-notify slds-notify_alert slds-theme_alert-texture slds-theme_';

export default class AlertBanner extends LightningElement {
    /**
     * The stylized theme for the alert.
     * @type {string}
     * @default warning
     */
    @api theme;
    @api variant;
    @api assistText;
    @api icon;
    @api size;
    @api message;
    @api isDismissable = false;

    _isVisible = true;

    get alertTheme() {
        const warningThemeDefault = 'warning';

        if(isEmpty(this.theme)) {
            return defaultClass.concat(warningThemeDefault);
        }

        return defaultClass.concat(this.theme);
    }

    get isVisible() {
        return this._isVisible;
    }
    set isVisible(value) {
        this._isVisible = value;
    }

    get alertVariant() {
        const variantInverseDefault = 'inverse';

        if(isEmpty(this.variant)) {
            return variantInverseDefault;
        }

        return this.variant;
    }

    get alertIcon() {
        const iconDefault = 'utility:warning';

        if(isEmpty(this.icon)) {
            return iconDefault;
        }

        return this.icon;
    }

    get alertSize() {
        const sizeDefault = 'x-small';

        if(isEmpty(this.size)) {
            return sizeDefault;
        }

        return this.size;
    }

    get alertAssistText() {
        const assistDefault = 'An error has occurred';

        if(isEmpty(this.assistText)) {
            return assistDefault;
        }

        return this.assistText;
    }

    get alertMessage() {
        const messageDefault = 'An error has occurred.';

        if(isEmpty(this.message)) {
            return messageDefault;
        }

        return this.message;
    }

    hideAlert() {
        this.isVisible = false;
    }
}
