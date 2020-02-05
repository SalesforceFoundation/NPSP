import { LightningElement, api, track } from 'lwc';

export default class utilExpandableSection extends LightningElement {

    @api id;
    @api label;
    @api isCollapsed = false;
    @api alternativeText;
    @api bodyClass;
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

        if (!this.isCollapsed) {
            classItems = [...classItems, 'icon-transition_is-open'];
        }

        return classItems.join(' ');
    }

    get sectionClass() {
        let classItems = ['section-transition'];

        if (this.isCollapsed) {
            classItems = [...classItems, 'section-transition_is-closed'];
        } else {
            // Apply provided css class to body if section is expanded
            if (this.bodyClass) {
                let bodyClass = this.bodyClass.split(' ');
                classItems = [...classItems, ...bodyClass];
            }
        }

        return classItems.join(' ');
    }

    get ariaExpanded() {
        return this.isCollapsed ? false : true;
    }

    get ariaHidden() {
        return this.isCollapsed ? true : false;
    }

    toggleSection() {
        this.isCollapsed = !this.isCollapsed;
    }

    handleSlotChange() {
        this.hasSlotContent = true;
        if(this.isCollapsed) {
            this.isCollapsed = false;
        }
    }
}