import { LightningElement, api, track } from 'lwc';

export default class utilCard extends LightningElement {
    @api title;
    @api iconName;
    @api iconSize;

    @track showFooter = true;

    renderedCallback() {
        if (this.footerSlot) {
            this.showFooter = this.footerSlot.assignedElements().length !== 0;
        }
    }

    get footerSlot() {
        return this.template.querySelector('slot[name=footer]');
    }

    get hasIcon() {
        return !!this.iconName;
    }

    get hasStringTitle() {
        return !!this.title;
    }
}