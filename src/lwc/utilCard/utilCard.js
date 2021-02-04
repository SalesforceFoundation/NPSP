import { LightningElement, api, track } from 'lwc';

export default class utilCard extends LightningElement {
    @api title;
    @api iconName;
    @api iconSize;
    @api cssClass;

    @track showFooter = true;

    renderedCallback() {
        if (this.footerSlot) {
            this.showFooter = this.footerSlot.length !== 0;
        }
    }

    get footerSlot() {
        return this.template.querySelectorAll('slot[name=footer]');
    }

    get hasIcon() {
        return !!this.iconName;
    }

    get hasStringTitle() {
        return !!this.title;
    }

    get computedCssClass() {
        let baseClass = ['slds-card', 'slds-card_boundary'];

        if (this.cssClass) {
            let cssClass = this.cssClass.split(' ');
            baseClass = [...baseClass, ...cssClass];
        }

        return baseClass.join(' ');
    }
}