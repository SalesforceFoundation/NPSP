import { LightningElement, api, track } from 'lwc';

export default class utilExpandableSection extends LightningElement {

    @api id;
    @api label;
    @api isCollapsed = false;
    @api alternativeText;
    @track hasSlotContent = false;

    get containerClass() {
        let classItems = ['slds-section', 'slds-is-open'];

        if (this.classList && this.classList.length > 0) {
            classItems = [...classItems, this.classList];
        }

        return classItems.join(' ');
    }

    get iconClass() {
        let classItems = ['slds-p-right_small', 'icon-transition'];

        if (this.isCollapsed) {
            classItems = [...classItems, 'icon-transition_is-open'];
        }

        return classItems.join(' ');
    }

    get sectionClass() {
        let classItems = ['section-transition'];

        if (!this.isCollapsed) {
            classItems = [...classItems, 'section-transition_is-closed'];
        }

        return classItems.join(' ');
    }

    get ariaExpanded() {
        return this.isCollapsed ? true : false;
    }

    get ariaHidden() {
        return this.isCollapsed ? false : true;
    }

    toggleSection() {
        this.isCollapsed = !this.isCollapsed;
    }

    handleSlotChange() {
        this.hasSlotContent = true;
        this.toggleSection();
    }
}