import {LightningElement, api, track} from 'lwc';

export default class GeFormSection extends LightningElement {
    @api section;
    @track expanded = true;

    /**
     * Get the icon that should display next to the twistable section header
     * @returns {string} containing the icon name from SLDS
     */
    get iconName() {
        return this.expanded ? 'utility:chevrondown' : 'utility:chevronright';
    }

    /**
     * Get the alternative text that represents the section expand/collapse button
     * @returns {string} containing the section expand alternative text
     */
    get altTextLabel() {
        return 'Toggle ' + this.section.label;
    }

    /**
     * Get the css classname for the body of the twistable section, show/hide when closed/open
     * @returns {string} 'slds-hidden' when the section is closed
     */
    get sectionClassName() {
        return this.expanded ? '' : 'slds-hidden';
    }

    /**
     * When twistable section header is clicked, collapse/expand it
     * @param event
     */
    toggleExpand(event) {
        event.preventDefault();
        this.expanded = !this.expanded;
    }
}