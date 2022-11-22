import { createElement } from "lwc";
import GeGatewaySelectWidget from "c/geGatewaySelectWidget";
import GeGatewaySettings from "c/geGatewaySettings";
import getGatewayAssignmentSettings from "@salesforce/apex/GE_GiftEntryController.getGatewayAssignmentSettings";
import getGatewaysFromElevate from "@salesforce/apex/GE_GiftEntryController.getGatewaysFromElevate";

const gatewaysFromElevate = require("./data/getGatewaysFromElevate.json");

const PAYMENT_METHOD_MODE = "PAYMENT";
const GATEWAY_MANAGEMENT_MODE = "MANAGEMENT";
const SELECTED_GATEWAY_ID = "Non-default Gateway Id";
const DEFAULT_GATEWAY_ID = "Default Gateway Id";
const DEFAULT_TEMPLATE_ID = "Default Template Id";

jest.mock(
    "@salesforce/apex/GE_GiftEntryController.getGatewayAssignmentSettings",
    () => {
        return { default: jest.fn() };
    },
    { virtual: true }
);

jest.mock(
    "@salesforce/apex/GE_GiftEntryController.getGatewaysFromElevate",
    () => {
        return { default: jest.fn() };
    },
    { virtual: true }
);

describe("c-ge-gateway-select-widget", () => {
    beforeEach(() => {
        getGatewaysFromElevate.mockResolvedValue(JSON.stringify(gatewaysFromElevate));
    });

    afterEach(() => {
        GeGatewaySettings.clearDecryptedElevateSettings();
        jest.clearAllMocks();
        clearDOM();
    });

    describe("gateway assignment mode", () => {
        beforeEach(() => {
            getGatewayAssignmentSettings.mockResolvedValue(JSON.stringify({
                defaultGatewayId: DEFAULT_GATEWAY_ID,
                defaultTemplateId: DEFAULT_TEMPLATE_ID,
                gatewayAssignmentEnabled: true,
            }));
        });

        it("renders widget contents when not default template", async () => {
            GeGatewaySettings.setElevateSettings(null, SELECTED_GATEWAY_ID);
            const element = createGeGatewaySelectWidget(null);
            document.body.appendChild(element);
            await flushPromises();

            expect(element).toBeTruthy();
            expect(getDiv(element)).toBeTruthy();
        });

        it("does not render widget contents when default template", async () => {
            GeGatewaySettings.setElevateSettings(null, DEFAULT_TEMPLATE_ID);
            const element = createGeGatewaySelectWidget(null);
            document.body.appendChild(element);
            await flushPromises();

            expect(element).toBeTruthy();
            expect(getDiv(element)).toBeFalsy();
        });

        it("displays spinner if no gateways found", async () => {
            GeGatewaySettings.setElevateSettings(null, null);
            getGatewaysFromElevate.mockResolvedValueOnce(null);
            const element = createGeGatewaySelectWidget(null);
            document.body.appendChild(element);
            await flushPromises();

            expect(getSpinner(element)).toBeTruthy();
        });

        it("displays gateways and payment methods when expanded", async () => {
            GeGatewaySettings.setElevateSettings(null, null);
            const element = createGeGatewaySelectWidget(null);
            document.body.appendChild(element);
            await flushPromises();

            const expandGatewayControl = getExpandGatewayControl(element);
            expect(expandGatewayControl).toBeTruthy();
            expandGatewayControl.click();
            await flushPromises();

            expect(getComboBox(element)).toBeTruthy();
            expect(getACHCheckBox(element)).toBeTruthy();
            expect(getCCCheckBox(element)).toBeTruthy();

            const collapseGatewayControl = shadowQuerySelector(element,'[data-id="ga-hide-button"]');
            expect(collapseGatewayControl).toBeTruthy();
            collapseGatewayControl.click();
            await flushPromises();

            expect(getComboBox(element)).toBeFalsy();
            expect(getACHCheckBox(element)).toBeFalsy();
            expect(getCCCheckBox(element)).toBeFalsy();
        })
    });

    describe("payment method mode", () => {
        beforeEach(() => {
            getGatewayAssignmentSettings.mockResolvedValue(JSON.stringify({
                defaultGatewayId: DEFAULT_GATEWAY_ID,
                defaultTemplateId: DEFAULT_TEMPLATE_ID,
                gatewayAssignmentEnabled: false,
            }));
        });

        it("renders widget contents when not default template", async () => {
            GeGatewaySettings.setElevateSettings(null, SELECTED_GATEWAY_ID);
            const element = createGeGatewaySelectWidget(PAYMENT_METHOD_MODE);
            document.body.appendChild(element);
            await flushPromises();

            expect(element).toBeTruthy();
            expect(getDiv(element)).toBeTruthy();
        });

        it("does not render widget contents when default template", async () => {
            GeGatewaySettings.setElevateSettings(null, DEFAULT_TEMPLATE_ID);
            const element = createGeGatewaySelectWidget(PAYMENT_METHOD_MODE);
            document.body.appendChild(element);
            await flushPromises();

            expect(element).toBeTruthy();
            expect(getDiv(element)).toBeFalsy();
        });

        it("does not display spinner if no gateways found", async () => {
            getGatewaysFromElevate.mockResolvedValueOnce(null);
            GeGatewaySettings.setElevateSettings(null, null);
            const element = createGeGatewaySelectWidget(null);
            document.body.appendChild(element);
            await flushPromises();

            expect(getSpinner(element)).toBeFalsy();
        });

        it("displays payment methods, but not gateways when expanded", async () => {
            GeGatewaySettings.setElevateSettings(null, null);
            const element = createGeGatewaySelectWidget(null);
            document.body.appendChild(element);
            await flushPromises();

            const expandPaymentControl = getExpandPaymentControl(element);
            expect(expandPaymentControl).toBeTruthy();
            expandPaymentControl.click();
            await flushPromises();

            expect(getComboBox(element)).toBeFalsy();
            expect(getACHCheckBox(element)).toBeTruthy();
            expect(getCCCheckBox(element)).toBeTruthy();

            const collapsePaymentControl = shadowQuerySelector(element,'[data-id="pm-hide-button"]');
            expect(collapsePaymentControl).toBeTruthy();
            collapsePaymentControl.click();
            await flushPromises();

            expect(getComboBox(element)).toBeFalsy();
            expect(getACHCheckBox(element)).toBeFalsy();
            expect(getCCCheckBox(element)).toBeFalsy();
        })
    });

    describe("gateway management mode", () => {
        beforeEach(() => {
            getGatewayAssignmentSettings.mockResolvedValue(JSON.stringify({
                defaultGatewayId: DEFAULT_GATEWAY_ID,
                defaultTemplateId: DEFAULT_TEMPLATE_ID,
                gatewayAssignmentEnabled: true,
            }));
        });

        it("does not display spinner if no gateways found", async () => {
            getGatewaysFromElevate.mockResolvedValueOnce(null);
            GeGatewaySettings.setElevateSettings(null, null);
            const element = createGeGatewaySelectWidget(GATEWAY_MANAGEMENT_MODE);
            document.body.appendChild(element);
            await flushPromises();

            expect(getSpinner(element)).toBeFalsy();
        });

        it("Only gateway combo-box is displayed", async () => {
            GeGatewaySettings.setElevateSettings(null, null);
            const element = createGeGatewaySelectWidget(GATEWAY_MANAGEMENT_MODE);
            document.body.appendChild(element);
            await flushPromises();

            expect(getExpandGatewayControl(element)).toBeFalsy();
            expect(getExpandPaymentControl(element)).toBeFalsy();
            expect(getComboBox(element)).toBeTruthy();
            expect(getACHCheckBox(element)).toBeFalsy();
            expect(getCCCheckBox(element)).toBeFalsy();
        });
    });
});

const createGeGatewaySelectWidget = (mode) => {
    const element = createElement("c-ge-gateway-select-widget", { is: GeGatewaySelectWidget });
    element.parentContext = mode;
    return element;
};

const getShadowRoot = (element) => {
    if (!element || !element.shadowRoot) {
        const tagName =
            element && element.tagName && element.tagName.toLowerCase();
        throw new Error(
            `Attempting to retrieve the shadow root of '${tagName || element}'
            but no shadowRoot property found`
        );
    }
    return element.shadowRoot;
}

const shadowQuerySelector = (element, selector) => {
    return getShadowRoot(element).querySelector(selector);
}

const getComboBox = (element) => {
    return shadowQuerySelector(element,'[data-id="gateway-combobox"]');
}

const getACHCheckBox = (element) => {
    return shadowQuerySelector(element,'[data-id="checkboxACH"]');
}

const getCCCheckBox = (element) => {
    return shadowQuerySelector(element,'[data-id="checkboxCreditCard"]');
}

const getExpandGatewayControl = (element) => {
    return shadowQuerySelector(element,'[data-id="ga-show-button"]');
}

const getExpandPaymentControl = (element) => {
    return shadowQuerySelector(element,'[data-id="pm-show-button"]');
}

const getDiv = (element) => {
    return shadowQuerySelector(element,'div');
}

const getSpinner = (element) => {
    return shadowQuerySelector(element,'[data-id="spinner"]');
}
