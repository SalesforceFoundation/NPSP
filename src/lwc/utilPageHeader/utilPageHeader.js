import { LightningElement, api } from 'lwc';

export default class UtilPageHeader extends LightningElement {
    @api title;
    @api pretext;
    @api iconName;
    @api iconSize;
    @api iconVariant;

    get hasIcon() {
        return !!this.iconName;
    }

    get hasStringTitle() {
        return !!this.title;
    }

    get hasPretext() {
        return !!this.pretext;
    }
}