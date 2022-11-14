import { createElement } from 'lwc';
import GeFormWidgetTokenizeCard from 'c/geFormWidgetTokenizeCard';
import { DISABLE_TOKENIZE_WIDGET_EVENT_NAME } from 'c/geConstants';
import { fireEvent } from 'c/pubsubNoPageRef';
import { getRecord } from "lightning/uiRecordApi";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import Settings from 'c/geSettings';

const mockGetRecord = require('./data/DIMockRecord.json');
const mockGetRecordAch = require('./data/DIMockRecordAch.json');
const mockObjectInfo = require('./data/dataImportObjectDescribeInfo.json');

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

import RD2_ElevateRDCannotBeFixedLength from '@salesforce/label/c.RD2_ElevateRDCannotBeFixedLength';

const createWidgetElement = () => {
    let element = createElement(
        'c-ge-form-widget-tokenize-card',
        {is: GeFormWidgetTokenizeCard}
    );
    element.Settings = Settings;
    return element;
}

const setPaymentMethod = (element, paymentMethod) => {
    element.widgetDataFromState = {
        [PAYMENT_METHOD_FIELD]: paymentMethod
    };
}


describe('c-ge-form-widget-tokenize-card', () => {

    beforeEach(() => {
        Settings.isElevateCustomer = jest.fn(() => true);
        clearDOM();
    });

    it('should deactivate the widget in edit mode when a fixed recurring type gift is loaded', async() => {
        const element = createWidgetElement();
        element.widgetDataFromState = {
            'Payment_Method__c': 'Credit Card',
            'Recurring_Donation_Recurring_Type__c': 'Fixed',
            'NPSP_Data_Import_Batch__c': 'DUMMY_BATCH_ID'
        };
        document.body.appendChild(element);

        await flushPromises();

        const deactivatedMessage = shadowQuerySelector(element, '[data-id="deactivatedMessage"]');
        const editPaymentInformationLink = shadowQuerySelector(element, '[data-id="editPaymentInformation"]');

        expect(deactivatedMessage.textContent).toBe(RD2_ElevateRDCannotBeFixedLength);
        expect(editPaymentInformationLink).toBeFalsy();
    });

    it('should activate the widget when recurring type is changed from Fixed to Open', async() => {
        const element = createWidgetElement();
        element.widgetDataFromState = {
            'Payment_Method__c': 'Credit Card',
            'Recurring_Donation_Recurring_Type__c': 'Fixed',
            'NPSP_Data_Import_Batch__c': 'DUMMY_BATCH_ID'
        };
        document.body.appendChild(element);
        await flushPromises();

        const deactivatedMessage = shadowQuerySelector(element, '[data-id="deactivatedMessage"]');
        const editPaymentInformationLink = shadowQuerySelector(element, '[data-id="editPaymentInformation"]');

        expect(deactivatedMessage.textContent).toBe(RD2_ElevateRDCannotBeFixedLength);
        expect(editPaymentInformationLink).toBeFalsy();

        element.widgetDataFromState = {
            'Payment_Method__c': 'Credit Card',
            'Recurring_Donation_Recurring_Type__c': 'Open',
            'NPSP_Data_Import_Batch__c': 'DUMMY_BATCH_ID'
        };
        await flushPromises();

        const deactivatedMessageReRendered = shadowQuerySelector(element, '[data-id="deactivatedMessage"]');
        expect(deactivatedMessageReRendered).toBeFalsy();

        const chargeIFrameContainer = shadowQuerySelector(element, '[data-id="chargeIFrameContainer"]');
        expect(chargeIFrameContainer).toBeTruthy();
    });

    it('should deactivate the widget in read-only mode when a fixed recurring type gift is loaded', async() => {
        const element = createWidgetElement();
        element.widgetDataFromState = {
            'Payment_Method__c': 'Credit Card',
            'Recurring_Donation_Recurring_Type__c': 'Open',
            'NPSP_Data_Import_Batch__c': 'DUMMY_BATCH_ID',
            'Id': 'DUMMY_RECORD_ID'
        };
        document.body.appendChild(element);
        await flushPromises();

        const dataImportRecord = {
            'Payment_Card_Last_4__c': '1234',
            'Payment_Card_Expiration_Month__c': 'testMonth',
            'Payment_Card_Expiration_Year__c': 'testYear'
        };
        const dataImportObjectInfo = {
          data: {
              fields: {
                  'Payment_Card_Last_4__c': 'yes',
                  'Payment_Card_Expiration_Month__c': 'yes',
                  'Payment_Card_Expiration_Year__c': 'yes'
              }
          }
        };
        getObjectInfo.emit(dataImportObjectInfo);
        await flushPromises();

        getRecord.emit(dataImportRecord, record => {
            record.recordId = 'DUMMY_RECORD_ID';
            return record;
        });
        await flushPromises();

        const readOnlyLayout = shadowQuerySelector(element, '[data-id="readOnlyLayout"]');
        expect(readOnlyLayout).toBeTruthy();

        element.widgetDataFromState = {
            'Payment_Method__c': 'Credit Card',
            'Recurring_Donation_Recurring_Type__c': 'Fixed',
            'NPSP_Data_Import_Batch__c': 'DUMMY_BATCH_ID',
            'Id': 'DUMMY_RECORD_ID'
        };
        await flushPromises();

        const deactivatedMessage = shadowQuerySelector(element, '[data-id="deactivatedMessage"]');
        const editPaymentInformationLink = shadowQuerySelector(element, '[data-id="editPaymentInformation"]');

        expect(deactivatedMessage.textContent).toBe(RD2_ElevateRDCannotBeFixedLength);
        expect(editPaymentInformationLink).toBeFalsy();

        const readOnlyLayoutReRendered = shadowQuerySelector(element, '[data-id="readOnlyLayout"]');
        expect(readOnlyLayoutReRendered).toBeFalsy();
    });

    it('should not render the iframe and related elements if is not an Elevate customer', async () => {
        Settings.isElevateCustomer = jest.fn(() => false);
        const element = createWidgetElement();

        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            expect(iframe(element)).toBeNull();
            expect(doNotEnterPaymentButton(element)).toBeNull();
        });
    });

    it('should display payment service disconnected label', async () => {
        Settings.isElevateCustomer = jest.fn(() => false);
        const element = createWidgetElement();

        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            expect(spanDisabledMessage(element).innerHTML).toBe('c.geElevateWidgetPaymentServiceUnavailable');
        });
    });

    it('should render default credit card if payment method field is not on the form', async () => {
        const element = createWidgetElement();
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            expect(iframe(element).src).toContain(PATH_GE_TOKENIZE_CARD);
            expect(doNotEnterPaymentButton(element)).toBeTruthy();
        });
    });

    it('should render disabled message and button to re-enable widget', async () => {
        const element = createWidgetElement();
        element.hasPaymentMethodFieldInForm = true;
        setPaymentMethod(element, CREDIT_CARD);
        document.body.appendChild(element);

        doNotEnterPaymentButton(element).click();

        return Promise.resolve().then(() => {
            expect(spanDisabledMessage(element).innerHTML).toBe(DISABLED_MESSAGE);
            expect(enterPaymentButton(element)).toBeTruthy();
        });
    });

    it('should render extended disabled message without button to re-enable widget', async () => {
        const element = createWidgetElement();
        element.hasPaymentMethodFieldInForm = true;
        setPaymentMethod(element, CASH);
        document.body.appendChild(element);

        expect(doNotEnterPaymentButton(element)).toBeFalsy();

        return Promise.resolve().then(() => {
            expect(spanExtendedDisabledMessage(element).innerHTML).toBe(EXTENDED_DISABLED_MESSAGE);
        });
    });

    it('should allow disabling and enabling of widget', async () => {
        const element = createWidgetElement();
        element.hasPaymentMethodFieldInForm = true;
        setPaymentMethod(element, ACH);
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
        const element = createWidgetElement();
        element.hasPaymentMethodFieldInForm = true;
        setPaymentMethod(element, ACH);
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
        const element = createWidgetElement();
        element.hasPaymentMethodFieldInForm = true;
        setPaymentMethod(element, CASH);
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
        const element = createWidgetElement();
        element.hasPaymentMethodFieldInForm = true;
        setPaymentMethod(element, ACH);
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

    it('should display ACH input fields when in batch mode', async () => {
        const element = createWidgetElement();
        element.hasPaymentMethodFieldInForm = true;
        setPaymentTransactionStatusValues(element);
        setPaymentMethod(element, ACH);

        element.widgetDataFromState = {
            ...element.widgetDataFromState,
            [DATA_IMPORT_PARENT_BATCH_LOOKUP]: 'DUMMY_ID'
        }
        getObjectInfo.emit(mockObjectInfo);
        document.body.appendChild(element);

        return Promise.resolve()
            .then(() => {
                expect(iframe(element).src).toContain(PATH_GE_TOKENIZE_CARD);
                expect(doNotEnterPaymentButton(element)).toBeTruthy();
            });
    });

    it('should go into hard read-only mode when credit card payment has been captured', async () => {
        const element = createWidgetElement();
        element.hasPaymentMethodFieldInForm = true;
        setPaymentTransactionStatusValues(element);
        element.widgetDataFromState = {
            ...element.widgetDataFromState,
            [PAYMENT_METHOD_FIELD]: CREDIT_CARD,
            [DATA_IMPORT_PARENT_BATCH_LOOKUP]: 'DUMMY_ID',
            [DATA_IMPORT_PAYMENT_STATUS]: 'CAPTURED'
        };

        getObjectInfo.emit(mockObjectInfo);
        getRecord.emit(mockGetRecord);
        document.body.appendChild(element);

        await flushPromises();
        expect(getLastFourDigits(element)).not.toBe(null);
        expect(getCardExpirationDate(element)).not.toBe(null);
        expect(editPaymentInformationButton(element)).toBeFalsy();
    });

    it('should go into soft read-only mode when credit card payment has expired', async () => {
        const element = createWidgetElement();
        element.hasPaymentMethodFieldInForm = true;
        setPaymentTransactionStatusValues(element);
        element.widgetDataFromState = {
            ...element.widgetDataFromState,
            [PAYMENT_METHOD_FIELD]: CREDIT_CARD,
            [DATA_IMPORT_PARENT_BATCH_LOOKUP]: 'DUMMY_ID',
            [DATA_IMPORT_PAYMENT_STATUS]: 'EXPIRED'
        }

        getObjectInfo.emit(mockObjectInfo);
        getRecord.emit(mockGetRecord);
        document.body.appendChild(element);

        await flushPromises();
        expect(getLastFourDigits(element)).not.toBe(null);
        expect(getCardExpirationDate(element)).not.toBe(null);
        expect(editPaymentInformationButton(element)).toBeTruthy();
    });

    it('should go into soft read-only mode when ach payment is pending', async () => {
        const element = createWidgetElement();
        element.hasPaymentMethodFieldInForm = true;
        setPaymentTransactionStatusValues(element);
        element.widgetDataFromState = {
            ...element.widgetDataFromState,
            [PAYMENT_METHOD_FIELD]: ACH,
            [DATA_IMPORT_PARENT_BATCH_LOOKUP]: 'DUMMY_ID',
            [DATA_IMPORT_PAYMENT_STATUS]: 'PENDING'
        };

        getObjectInfo.emit(mockObjectInfo);
        getRecord.emit(mockGetRecordAch);
        document.body.appendChild(element);

        await flushPromises();
        expect(getAchLastFourDigits(element)).not.toBe(null);
        expect(editPaymentInformationButton(element)).toBeTruthy();
    });

    it('should not be able to click cancel on widget when gift is expired', async () => {
        const element = createWidgetElement();
        element.hasPaymentMethodFieldInForm = true;
        setPaymentTransactionStatusValues(element);
        element.widgetDataFromState = {
            ...element.widgetDataFromState,
            [PAYMENT_METHOD_FIELD]: CREDIT_CARD,
            [DATA_IMPORT_PARENT_BATCH_LOOKUP]: 'DUMMY_ID',
            [DATA_IMPORT_PAYMENT_STATUS]: 'EXPIRED'
        }

        getObjectInfo.emit(mockObjectInfo);
        getRecord.emit(mockGetRecord);
        document.body.appendChild(element);

        editPaymentInformationButton(element).click();

        await flushPromises();
        expect(editPaymentInformationButton(element)).toBeFalsy();
        expect(cancelEditPaymentInformationButton(element)).toBeFalsy();
        expect(iframe(element).src).toContain(PATH_GE_TOKENIZE_CARD);
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

const getAchLastFourDigits = (element) => {
    return shadowQuerySelector(element,'[data-qa-locator="text ACH Last Four Digits"]');
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

const setPaymentTransactionStatusValues = (element) => {
    element.paymentTransactionStatusValues = {
        AUTHORIZED: 'AUTHORIZED',
        CAPTURED: 'CAPTURED',
        SUBMITTED: 'SUBMITTED',
        PENDING: 'PENDING',
        DECLINED: 'DECLINED',
        EXPIRED: 'EXPIRED'
    }
}