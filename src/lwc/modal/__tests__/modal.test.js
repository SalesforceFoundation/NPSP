import { createElement } from "lwc";
import { registerSa11yMatcher } from '@sa11y/jest'
import Modal from "c/modal";

const CSS_CLASS = "modal-hidden";
registerSa11yMatcher();

describe("c-modal", () => {
    let element;

    afterEach(global.clearDOM);

    beforeEach(() => {
        element = createElement("c-modal", {
            is: Modal,
        });
    });

    it("renders the header content based on a public property and doesn not render the header slot", () => {
        const HEADER = "The modal header";
        element.header = HEADER;
        document.body.appendChild(element);

        return global.flushPromises().then(async () => {
            // Query h2 element for header. We use a CSS selector to distinguish
            // between the h2 tag for a header that's set via a public property
            // vs a h2 tag that's set via the slot.
            const headerEl = element.shadowRoot.querySelector("span");
            expect(headerEl.textContent).toBe(HEADER);

            const headerSlotEl = element.shadowRoot.querySelector('slot[name="header"]');
            expect(headerSlotEl).toBeNull();
            await expect(element).toBeAccessible();
        });
    });

    // lwc-jest cannot validate slotchange events. We're only checking
    // here if the empty h2 div is rendered.
    it("renders the header slot when no public header property is set", () => {
        document.body.appendChild(element);

        // Return a promise to wait for any asynchronous DOM updates. Jest
        // will automatically wait for the Promise chain to complete before
        // ending the test and fail the test if the promise rejects.
        return global.flushPromises().then(async () => {
            // Query header slot element
            const headerSlotEl = element.shadowRoot.querySelector('slot[name="header"]');
            expect(headerSlotEl).not.toBeNull();
        });
    });

    it("hides the modal as default based on a CSS class", () => {
        document.body.appendChild(element);

        return global.flushPromises().then(() => {
            const outerDivEl = element.shadowRoot.querySelector("div");

            // // Validate default value
            expect(outerDivEl.classList.value).toBe(CSS_CLASS);
        });
    });

    it("changes the modal CSS class based on public function calls", () => {
        document.body.appendChild(element);

        return global.flushPromises().then(() => {
            const outerDivEl = element.shadowRoot.querySelector("div");

            // Call `show` function to remove CSS class
            element.show();

            // // Validate that CSS class is removed
            expect(outerDivEl.classList.value).toBe("");

            // Call `hide` function to add CSS class
            element.hide();

            // // Validate that CSS class is added
            expect(outerDivEl.classList.value).toBe(CSS_CLASS);
        });
    });
});
