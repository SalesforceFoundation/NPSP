import geGatewaySelectWidget from 'c/geGatewaySelectWidget';
import geGatewaySettings from 'c/geGatewaySettings';
import { createElement } from 'lwc';

afterEach(() => {
    clearDOM();
    jest.clearAllMocks();
});

describe('Loading', () => {

    let component;

    beforeEach(() => {
        component = createElement("c-gateway-select-widget", { is: geGatewaySelectWidget });
    });

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    })

    it('loading spinner', () => {
        document.body.appendChild(component);
        const spinner = component.shadowRoot.querySelector("[data-id='spinner']");
        expect(spinner).toBeTruthy();
    });
});

describe('Default Template', () => {

    let component;

    // TODO: Mock getDefaultTemplateId and initialize elevateSettings to be equal

    beforeEach(() => {
        component = createElement("c-gateway-select-widget", { is: geGatewaySelectWidget });
    });

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    })

    it('loading spinner', () => {
        document.body.appendChild(component);
        const spinner = component.shadowRoot.querySelector("[data-id='spinner']");
        expect(spinner).toBeTruthy();
    });

    it('ga show button', () => {
        document.body.appendChild(component);
        const spinner = component.shadowRoot.querySelector("[data-id='ga-show-button']");
        expect(spinner).toBeFalsy();
    });

});

describe('Payment Methods', () => {

    let component;

    // TODO: Mock isGatewayAssignmentEnabled

    beforeEach(() => {
        component = createElement("c-gateway-select-widget", { is: geGatewaySelectWidget });
    });

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    })

    it('loading spinner', () => {
        document.body.appendChild(component);
        const spinner = component.shadowRoot.querySelector("[data-id='spinner']");
        expect(spinner).toBeTruthy();
    });

    it('ga show button', () => {
        document.body.appendChild(component);
        const spinner = component.shadowRoot.querySelector("[data-id='ga-show-button']");
        expect(spinner).toBeFalsy();
    });

});

describe('Gateway Assignment Enabled', () => {

    let component;

    // TODO: Mock isGatewayAssignmentEnabled
    //            getGatewaysFromElevate
    //            encryptGatewayId
    //            decryptGatewayId
    //            getGatewayIdFromConfig

    beforeEach(() => {
        component = createElement("c-gateway-select-widget", { is: geGatewaySelectWidget });
    });

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    })

    it('loading spinner', () => {
        document.body.appendChild(component);
        const spinner = component.shadowRoot.querySelector("[data-id='spinner']");
        expect(spinner).toBeTruthy();
    });

    it('ga show button', () => {
        geGatewaySettings.setElevateSettings(null, null);
        document.body.appendChild(component);
        const spinner = component.shadowRoot.querySelector("[data-id='ga-show-button']");
        expect(spinner).toBeFalsy();
    });
});
