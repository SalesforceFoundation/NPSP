import { LightningElement, api, track } from "lwc";
import closeLabel from "@salesforce/label/c.commonClose";

const CSS_CLASS = "modal-hidden";
const ESCAPE = "Escape";
/*
 * Modal copied form CaseMan: https://github.com/SalesforceFoundation/CaseMan/tree/master/force-app/main/default/lwc/modal
 */
export default class Modal extends LightningElement {
    @api doInsteadOfHide;

    close = closeLabel;
    visibilityClass = CSS_CLASS;

    @api
    set defaultVisible(value) {
        if (value) {
            this.visibilityClass = "";
        } else {
            this.visibilityClass = CSS_CLASS;
        }
    }
    get defaultVisible() {
        return this.visibilityClass;
    }

    @api
    set header(value) {
        this.hasHeaderString = value !== "";
        this._headerPrivate = value;
    }
    get header() {
        return this._headerPrivate;
    }

    @track hasHeaderString = false;
    _headerPrivate;

    @api show() {
        const outerDivEl = this.template.querySelector("div");
        outerDivEl.classList.remove(CSS_CLASS);
        this.template.querySelector("lightning-button-icon").focus();
    }

    @api hide() {
        if (this.doInsteadOfHide) {
            this.doInsteadOfHide();
            return;
        }

        const outerDivEl = this.template.querySelector("div");
        outerDivEl.classList.add(CSS_CLASS);
        this.dispatchEvent(new CustomEvent("dialogclose"));
    }

    handleSlotTaglineChange() {
        const taglineEl = this.template.querySelector("p");
        taglineEl.classList.remove(CSS_CLASS);
    }

    handleSlotFooterChange() {
        const footerEl = this.template.querySelector("footer");
        footerEl.classList.remove(CSS_CLASS);
    }

    handleEscapeKey(event) {
        if (event.key === ESCAPE) {
            this.hide();
        }
    }
}
