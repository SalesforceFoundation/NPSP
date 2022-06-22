import { createElement } from "lwc";
import UtilInlineText from "c/utilInlineText";

describe("c-util-inline-text", () => {
    afterEach(() => {
        clearDOM();
    });

    it("renders with provided classes", async () => {
        const element = buildElement(
            "utility:warning",
            "small",
            "warning",
            "dummy text",
            "test-class-1 test-class-2"
        );
        document.body.appendChild(element);

        await flushPromises();

        const divs = element.shadowRoot.querySelectorAll("div");
        const outerDiv = divs[0];
        expect(outerDiv.classList.contains("test-class-1")).toBeTruthy();
        expect(outerDiv.classList.contains("test-class-2")).toBeTruthy();
    });

    it("renders with default classes", async () => {
        const element = buildElement(
            "utility:warning",
            "small",
            "warning",
            "dummy text"
        );
        document.body.appendChild(element);

        await flushPromises();

        const divs = element.shadowRoot.querySelectorAll("div");
        const outerDiv = divs[0];
        expect(outerDiv.classList.contains("slds-p-horizontal_medium")).toBeTruthy();
        expect(outerDiv.classList.contains("slds-p-vertical_small")).toBeTruthy();
    });

    it("calculates the correct css class based on the provided variant", async () => {
        const element = buildElement(
            "utility:warning",
            "small",
            "inverse",
            "dummy text"
        );
        document.body.appendChild(element);

        await flushPromises();

        const divs = element.shadowRoot.querySelectorAll("div");
        const iconDiv = divs[1];
        expect(iconDiv.classList.contains("slds-inline_icon_text--inverse")).toBeTruthy();
    });

    it("passes the provided public properties to the base lightning-icon component", async () => {
        const element = buildElement(
            "standard:account",
            "large",
            "error",
            "dummy text"
        );
        document.body.appendChild(element);

        await flushPromises();

        const lightningIcon = element.shadowRoot.querySelector("lightning-icon");
        expect(lightningIcon.iconName).toBe("standard:account");
        expect(lightningIcon.size).toBe("large");
        expect(lightningIcon.variant).toBe("error");
    });

    it("renders the provided text", async () => {
        const element = buildElement(
            "utility:warning",
            "small",
            "warning",
            "dummy text"
        );
        document.body.appendChild(element);

        await flushPromises();

        const divs = element.shadowRoot.querySelectorAll("div");
        const textDiv = divs[2];
        expect(textDiv.textContent).toBe("dummy text");
    });
});

const buildElement = (iconName, iconSize, iconVariant, text, customCss) => {
    const element = createElement("c-util-inline-text", {
        is: UtilInlineText
    });
    element.iconName = iconName;
    element.iconSize = iconSize;
    element.iconVariant = iconVariant;
    element.text = text;
    element.customClass = customCss;

    return element;
}
