import { createElement } from 'lwc';
import GeFormWidgetTokenizeCard from 'c/geFormWidgetTokenizeCard';
import { DISABLE_TOKENIZE_WIDGET_EVENT_NAME } from 'c/geConstants';
import { fireEvent } from 'c/pubsubNoPageRef';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { registerLdsTestWireAdapter } from '@salesforce/sfdx-lwc-jest';

const mockGetRecord = require('./data/DIMockRecord.json');
const mockObjectInfo = require('./data/dataImportObjectDescribeInfo.json');

const getRecordAdapter = registerLdsTestWireAdapter(getRecord);
const getObjectInfoAdapter = registerLdsTestWireAdapter(getObjectInfo);

const CASH = 'Cash';
const CREDIT_CARD = 'Credit Card';
const ACH = 'ACH';
const PATH_GE_TOKENIZE_CARD = '/apex/GE_TokenizeCard';
const DISABLED_MESSAGE = 'c.geBodyPaymentNotProcessingTransaction';
const EXTENDED_DISABLED_MESSAGE = 'c.geBodyPaymentNotProcessingTransaction c.psSelectValidPaymentMethod';
const BDI_FAILURE_DISABLED_MESSAGE = 'c.geErrorCardChargedBDIFailed';
const PAYMENT_METHOD_FIELD = 'Payment_Method__c';
const DATA_IMPORT_PARENT_BATCH_LOOKUP = 'NPSP_Data_Import_Batch__c';
const DATA_IMPORT_PAYMENT_STATUS = 'Payment_Status__c';

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

    it('should not display ACH input fields when in batch mode', async () => {
        const element = createWidgetWithPaymentMethod(ACH);
        element.widgetDataFromState = {
            ...element.widgetDataFromState,
            [DATA_IMPORT_PARENT_BATCH_LOOKUP]: 'DUMMY_ID'
        }
        document.body.appendChild(element);

        return Promise.resolve()
            .then(() => {
                expect(iframe(element)).toBeNull();
                expect(spanExtendedDisabledMessage(element).innerHTML).toBe(EXTENDED_DISABLED_MESSAGE);
                expect(doNotEnterPaymentButton(element)).toBeFalsy();
            });
    });

    it('should go into hard read-only mode when credit card payment has been captured', async () => {
        const element = createWidgetWithPaymentMethod(CREDIT_CARD);
        element.widgetDataFromState = {
            ...element.widgetDataFromState,
            [DATA_IMPORT_PARENT_BATCH_LOOKUP]: 'DUMMY_ID',
            [DATA_IMPORT_PAYMENT_STATUS]: 'CAPTURED'
        }
        document.body.appendChild(element);
        getObjectInfoAdapter.emit(mockObjectInfo);
        getRecordAdapter.emit(mockGetRecord);
        return Promise.resolve()
            .then(() => {
                expect(getLastFourDigits(element).not.toBe(null));
                expect(getCardExpirationDate(element).not.toBe(null));
                expect(editPaymentInformationButton(element)).toBeFalsy();
            });
    });

    it('should go into soft read-only mode when credit card payment has been authorized', async () => {
        const element = createWidgetWithPaymentMethod(CREDIT_CARD);
        element.widgetDataFromState = {
            ...element.widgetDataFromState,
            [DATA_IMPORT_PARENT_BATCH_LOOKUP]: 'DUMMY_ID',
            [DATA_IMPORT_PAYMENT_STATUS]: 'AUTHORIZED'
        }
        element.paymentTransactionStatusValues = {
            AUTHORIZED: 'AUTHORIZED',
            CAPTURED: 'CAPTURED'
        }
        document.body.appendChild(element);
        await flushPromises();

        getObjectInfoAdapter.emit(mockObjectInfo);
        getRecordAdapter.emit(mockGetRecord);
        return Promise.resolve()
            .then(() => {
                expect(getLastFourDigits(element).not.toBe(null));
                expect(getCardExpirationDate(element).not.toBe(null));
                expect(editPaymentInformationButton(element)).toBeTruthy();
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

const getLastFourDigits = (element) => {
    return shadowQuerySelector(element,'[data-qa-locator="text Last Four Digits"]');
}

const getCardExpirationDate = (element) => {
    return shadowQuerySelector(element,'[data-qa-locator="text Expiration Date"]');
}

const editPaymentInformationButton = (element) => {
    return shadowQuerySelector(element, '[data-qa-locator="button Edit Payment Information"]');
}

const cancelEditPaymentInformationButton = (element) => {
    return shadowQuerySelector(element, '[data-qa-locator="button Cancel Edit Payment Information"]');
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