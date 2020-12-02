import { createElement } from 'lwc';
import GeFormWidgetTokenizeCard from 'c/geFormWidgetTokenizeCard';

const createWidgetWithPaymentMethod = (paymentMethod) => {
    const element = createElement(
        'c-ge-form-widget-tokenize-card',
        { is: GeFormWidgetTokenizeCard }
    );
    element.sourceFieldsUsedInTemplate = ['Payment_Method__c'];
    setPaymentMethod(element, paymentMethod);
    return element;
}

const setPaymentMethod = (element, paymentMethod) => {
    element.widgetDataFromState = {
        ['Payment_Method__c']: paymentMethod
    };
}

describe('c-ge-form-widget-tokenize-card', () => {

    afterEach(() => {
        clearDOM();
    });

    it('should render disabled message and button to re-enable widget', async () => {
        const element = createWidgetWithPaymentMethod('Credit Card');
        document.body.appendChild(element);

        doNotEnterPaymentButton(element).click();

        return Promise.resolve().then(() => {
            expectDisabledMessage(element);
            expect(enterPaymentButton(element)).toBeTruthy();
        });
    });

    it('should render extended disabled message without button to re-enable widget', async () => {
        const element = createWidgetWithPaymentMethod('Cash');
        document.body.appendChild(element);

        expect(doNotEnterPaymentButton(element)).toBeFalsy();

        return Promise.resolve().then(() => {
            expectExtendedDisabledMessage(element);
        });
    });

    it('should allow disabling and enabling of widget', async () => {
        const element = createWidgetWithPaymentMethod('ACH');
        document.body.appendChild(element);

        expect(doNotEnterPaymentButton(element)).toBeTruthy();

        return Promise.resolve()
            .then(() => {
                expectIframeIsAvailable(element);

                doNotEnterPaymentButton(element).click();
            })
            .then(() => {
                expectIframeIsNotAvailable(element);
                expectDisabledMessage(element);

                enterPaymentButton(element).click();
            })
            .then(() => {
                expectIframeIsAvailable(element);
            });
    });

    it('should disable itself after switch to invalid/incompatible payment method', async () => {
        const element = createWidgetWithPaymentMethod('ACH');
        document.body.appendChild(element);

        expect(doNotEnterPaymentButton(element)).toBeTruthy();

        return Promise.resolve()
            .then(() => {
                expectIframeIsAvailable(element);
                setPaymentMethod(element, 'Cash');
            })
            .then(() => {
                expectExtendedDisabledMessage(element);
            });
    });

    it('should re-enable itself after switch to valid payment method', async () => {
        const element = createWidgetWithPaymentMethod('Cash');
        document.body.appendChild(element);

        return Promise.resolve()
            .then(() => {
                expectExtendedDisabledMessage(element);
                setPaymentMethod(element, 'Credit Card');
            })
            .then(() => {
                expectIframeIsAvailable(element);
            });
    });
});

const enterPaymentButton = (element) => {
    return shadowQuerySelector(element, '[title="c.geButtonPaymentAlternate"]');
}

const doNotEnterPaymentButton = (element) => {
    return shadowQuerySelector(element, '.do-not-charge-card-button');
}

const expectIframeIsAvailable = (element) => {
    const iframe = shadowQuerySelector(element, '.payment-services-iframe');
    expect(iframe.src).toContain('/apex/GE_TokenizeCard');
}

const expectIframeIsNotAvailable = (element) => {
    const iframe = shadowQuerySelector(element, '.payment-services-iframe');
    expect(iframe).toBeFalsy();
}

const expectDisabledMessage = (element) => {
    const span = shadowQuerySelector(element, '.slds-content-message');
    expect(span.innerHTML).toBe('c.geBodyPaymentNotProcessingTransaction');
}

const expectExtendedDisabledMessage = (element) => {
    const span = shadowQuerySelector(element, '.slds-content-message');
    expect(span.innerHTML).toBe('c.geBodyPaymentNotProcessingTransaction c.psSelectValidPaymentMethod');
}

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