import { LightningElement, api, track } from "lwc";
import { isNull } from "c/util";

import toggleInstructionsWhenOpen from "@salesforce/label/c.accordionSection_ToggleInstructionsWhenOpen";
import toggleInstructionsWhenClosed from "@salesforce/label/c.accordionSection_ToggleInstructionsWhenClosed";

export default class AccordionSection extends LightningElement {
    @api preventToggle = false;
    @api title
    @api shadeOnOpen;

    @track isOpen = false;

    connectedCallback() {
        if (this.shadeOnOpen !== undefined) {
            document.documentElement.style.setProperty("--bgColor", this.shadeOnOpen);
        }
    }

    get toggleIcon() {
        return this.isOpen ? "utility:chevrondown" : "utility:chevronright";
    }

    get toggleInstructions() {
        return this.isOpen ? toggleInstructionsWhenOpen : toggleInstructionsWhenClosed;
    }

    get ariaExpanded() {
        return this.isOpen ? "true" : "false";
    }

    get buttonAriaLabel() {
        const state = this.isOpen ? "expanded" : "collapsed";
        return `${this.title}, ${state}`;
    }

    get classes() {
        let classes = ["slds-accordion__section"];

        if (this.isOpen) {
            classes.push("slds-is-open");
        }

        return classes.join(" ");
    }

    @api
    open() {
        this.toggle(true);
    }

    @api
    close() {
        this.toggle(false);
    }

    handleToggle() {
        this.toggle();
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => this.template.querySelector("button")?.focus(), 0);
    }

    handleClickableKeydown(event) {
        if (event.key === "Enter" || event.key === " ") {
            event.preventDefault();
            this.handleToggle();
        }
    }

    @api
    overrideOpen() {
        this.toggle(true, true);
    }

    @api
    toggle(isOpen, override) {
        if (!this.preventToggle || override) {
            this.isOpen = isNull(isOpen) ? !this.isOpen : isOpen;
        }
        this.dispatchEvent(
            new CustomEvent("toggled", {
                detail: {
                    isOpen: this.isOpen,
                    preventToggle: this.preventToggle,
                },
            })
        );
    }
}
