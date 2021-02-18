import { createElement } from 'lwc';
import GeFormWidgetTokenizeCard from 'c/geFormWidgetTokenizeCard';
import { DISABLE_TOKENIZE_WIDGET_EVENT_NAME } from 'c/geConstants';
import { fireEvent } from 'c/pubsubNoPageRef';

const CASH = 'Cash';
const CREDIT_CARD = 'Credit Card';
const ACH = 'ACH';
const PATH_GE_TOKENIZE_CARD = '/apex/GE_TokenizeCard';
const DISABLED_MESSAGE = 'c.geBodyPaymentNotProcessingTransaction';
const EXTENDED_DISABLED_MESSAGE = 'c.geBodyPaymentNotProcessingTransaction c.psSelectValidPaymentMethod';
const BDI_FAILURE_DISABLED_MESSAGE = 'c.geErrorCardChargedBDIFailed';
const PAYMENT_METHOD_FIELD = 'Payment_Method__c';

const createWidgetWithPaymentMethod = (paymentMethod) => {
    const element = createElement(
        'c-ge-form-widget-tokenize-card',
        { is: GeFormWidgetTokenizeCard }
    );
    element.sourceFieldsUsedInTemplate = [PAYMENT_METHOD_FIELD];
    setPaymentMethod(element, paymentMethod);
    return element;
}

const setPaymentMethod = (element, paymentMethod) => {
    element.widgetDataFromState = {
        [PAYMENT_METHOD_FIELD]: paymentMethod
    };
}

describe('c-ge-form-widget-tokenize-card', () => {

    afterEach(() => {
        clearDOM();
    });

    it('should render disabled message and button to re-enable widget', async () => {
        const element = createWidgetWithPaymentMethod(CREDIT_CARD);
        document.body.appendChild(element);

        doNotEnterPaymentButton(element).click();

        return Promise.resolve().then(() => {
            expect(spanDisabledMessage(element).innerHTML).toBe(DISABLED_MESSAGE);
            expect(enterPaymentButton(element)).toBeTruthy();
        });
    });

    it('should render extended disabled message without button to re-enable widget', async () => {
        const element = createWidgetWithPaymentMethod(CASH);
        document.body.appendChild(element);

        expect(doNotEnterPaymentButton(element)).toBeFalsy();

        return Promise.resolve().then(() => {
            expect(spanExtendedDisabledMessage(element).innerHTML).toBe(EXTENDED_DISABLED_MESSAGE);
        });
    });

    it('should allow disabling and enabling of widget', async () => {
        const element = createWidgetWithPaymentMethod(ACH);
        document.body.appendChild(element);

        expect(doNotEnterPaymentButton(element)).toBeTruthy();

        return Promise.resolve()
            .then(() => {
                expect(iframe(element).src).toContain(PATH_GE_TOKENIZE_CARD);

                doNotEnterPaymentButton(element).click();
            })
            .then(() => {
                expect(iframe(element)).toBeFalsy;
                expect(spanDisabledMessage(element).innerHTML).toBe(DISABLED_MESSAGE);

                enterPaymentButton(element).click();
            })
            .then(() => {
                expect(iframe(element).src).toContain(PATH_GE_TOKENIZE_CARD);
            });
    });

    it('should disable itself after switch to invalid/incompatible payment method', async () => {
        const element = createWidgetWithPaymentMethod(ACH);
        document.body.appendChild(element);

        expect(doNotEnterPaymentButton(element)).toBeTruthy();

        return Promise.resolve()
            .then(() => {
                expect(iframe(element).src).toContain(PATH_GE_TOKENIZE_CARD);

                setPaymentMethod(element, CASH);
            })
            .then(() => {
                expect(spanExtendedDisabledMessage(element).innerHTML).toBe(EXTENDED_DISABLED_MESSAGE);
            });
    });

    it('should re-enable itself after switch to valid payment method', async () => {
        const element = createWidgetWithPaymentMethod(CASH);
        document.body.appendChild(element);
        expect(doNotEnterPaymentButton(element)).toBeFalsy();

        return Promise.resolve()
            .then(() => {
                expect(spanExtendedDisabledMessage(element).innerHTML).toBe(EXTENDED_DISABLED_MESSAGE);

                setPaymentMethod(element, CREDIT_CARD);
            })
            .then(() => {
                expect(iframe(element).src).toContain(PATH_GE_TOKENIZE_CARD);
                expect(doNotEnterPaymentButton(element)).toBeTruthy();
            });
    });

    it('should permanently disable itself if an payment transaction has been successful', async () => {
        const element = createWidgetWithPaymentMethod(ACH);
        document.body.appendChild(element);

        return Promise.resolve()
        .then(() => {
            expect(iframe(element).src).toContain(PATH_GE_TOKENIZE_CARD);
            dispatchApplicationEvent(element,
                BDI_FAILURE_DISABLED_MESSAGE, DISABLE_TOKENIZE_WIDGET_EVENT_NAME);
        })
        .then(() => {
            expect(spanDisabledMessage(element).innerHTML).toBe(BDI_FAILURE_DISABLED_MESSAGE);
        });
    });
});

const enterPaymentButton = (element) => {
    return shadowQuerySelector(element, '[title="c.geButtonPaymentAlternate"]');
}

const doNotEnterPaymentButton = (element) => {
    return shadowQuerySelector(element, '.do-not-charge-card-button');
}

const iframe = (element) => {
    return shadowQuerySelector(element, '.payment-services-iframe');
}

const spanDisabledMessage = (element) => {
    return shadowQuerySelector(element, '.slds-content-message');
}

const spanExtendedDisabledMessage = (element) => {
    return shadowQuerySelector(element, '.slds-content-message');
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

const dispatchApplicationEvent = (element, value, eventName) => {
    fireEvent(this, eventName,
        { detail: { message: value } });
}