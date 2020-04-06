import { LightningElement, api } from 'lwc';
import { isEmpty } from 'c/utilCommon';

/**
 * @typedef {Class} AlertBanner
 * @property {string} _alertClass The class theme.
 */
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

    defaultClass = 'slds-notify slds-notify_alert slds-theme_alert-texture slds-theme_';

    get alertTheme() {
        const warningThemeDefault = 'warning';

        if(isEmpty(this.theme)) {
            return this.defaultClass.concat(warningThemeDefault);
        }

        return this.defaultClass.concat(this.theme);
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

        return this.icon
    }

    get alertSize() {
        const sizeDefault = 'x-small';

        if(isEmpty(this.size)) {
            return sizeDefault;
        }

        return this.size;
    }

    get alertAssistText() {
        const sizeDefault = 'An error has occurred';

        if(isEmpty(this.size)) {
            return sizeDefault;
        }

        return this.size
    }

    get alertMessage() {
        const messageDefault = 'An error has occurred.';

        if(isEmpty(this.message)) {
            return messageDefault;
        }

        return this.message;
    }
}