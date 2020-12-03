import { LightningElement, api, track } from "lwc";
import { isNull } from "c/util";

import toggleInstructionsWhenOpen from "@salesforce/label/c.accordionSection_ToggleInstructionsWhenOpen";
import toggleInstructionsWhenClosed from "@salesforce/label/c.accordionSection_ToggleInstructionsWhenClosed";

export default class AccordionSection extends LightningElement {
    @api preventToggle = false;
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
