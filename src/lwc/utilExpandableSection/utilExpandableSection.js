import { LightningElement, api } from 'lwc';

export default class utilExpandableSection extends LightningElement {

    @api id;
    @api label;
    @api isCollapsed = false;
    @api alternativeText;
    @api bodyClass;
    @api shouldInformParent = false;

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
        return !this.isCollapsed;
    }

    get ariaHidden() {
        return this.isCollapsed;
    }

    toggleSection() {
        this.isCollapsed = !this.isCollapsed;
        if (this.shouldInformParent === true) {
            this.informParent();
        }
    }

    /*******************************************************************************
     * Start getters for data-qa-locator attributes
     */

    get qaLocatorToggleSection() {
        return `button Toggle Section ${this.label}`;
    }

    /*******************************************************************************
     * End getters for data-qa-locator attributes
     */

    informParent () {
        const collapseEvent = new CustomEvent('sectioncollapse', {
            detail: {
                isCollapsed : this.isCollapsed
            }
        });
        this.dispatchEvent(collapseEvent);
    }
}