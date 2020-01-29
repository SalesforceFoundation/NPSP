import {LightningElement, track, api} from 'lwc';
import { generateId } from 'c/utilTemplateBuilder';

export default class CollapsibleSection extends LightningElement {
    @track localId;
    @track collapsed = false;
    @api sectionTitle;

    connectedCallback() {
        this.localId = generateId();
    }

    handleToggleClick() {
        this.collapsed = !this.collapsed;
    }

    get outerDivClass() {
        return this.collapsed ? "slds-section" : "slds-section slds-is-open"
    }

    get ariaExpanded() {
        return !this.collapsed;
    }

}