import { LightningElement, api } from 'lwc';

export default class UtilInlineText extends LightningElement {

    @api customClass;
    @api iconName;
    @api iconSize;
    @api iconVariant;
    @api text;

    get calculatedOuterDivClass() {
        if (this.customClass !== undefined) {
            return this.customClass;
        }
        return 'slds-p-horizontal_medium slds-p-vertical_small';
    }

    get calculatedIconName() {
        return this.iconName || 'utility:warning';
    }

    get calculatedIconSize() {
        return this.iconSize || 'small';
    }

    get calculatedIconVariant() {
        return this.iconVariant || 'warning';
    }

    get calculatedIconDivClass() {
        let variant;
        if (this.iconVariant !== undefined) {
            variant = this.iconVariant;
        }
        return `slds-inline_icon_text slds-grid slds-inline_icon_text--${variant}`;
    }
}