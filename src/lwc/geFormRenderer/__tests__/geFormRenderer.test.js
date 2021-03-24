import { createElement } from 'lwc';
import GeFormRenderer from 'c/geFormRenderer';
import { mockCheckInputValidity } from 'lightning/input';
import { mockCheckComboboxValidity } from 'lightning/combobox';
import retrieveDefaultSGERenderWrapper from '@salesforce/apex/GE_GiftEntryController.retrieveDefaultSGERenderWrapper';
import getPaymentTransactionStatusValues from '@salesforce/apex/GE_PaymentServices.getPaymentTransactionStatusValues';
import sendPurchaseRequest from '@salesforce/apex/GE_GiftEntryController.sendPurchaseRequest';
import GeLabelService from 'c/geLabelService';

const mockWrapperWithNoNames = require('./data/retrieveDefaultSGERenderWrapper.json');
const mockPaymentTransactionStatusValues = JSON.stringify(require('./data/paymentTransactionStatusValues.json'));

jest.mock('@salesforce/apex/GE_GiftEntryController.retrieveDefaultSGERenderWrapper', () => {
    return { default: jest.fn() };
}, { virtual: true });

jest.mock('@salesforce/apex/GE_PaymentServices.getPaymentTransactionStatusValues', () => {
    return { default: jest.fn() };
}, { virtual: true });

describe('c-ge-form-renderer', () => {

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    it('loads with template', () => {
        getPaymentTransactionStatusValues.mockResolvedValue(mockPaymentTransactionStatusValues);
        retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
        const element = createElement('c-ge-form-renderer', { is: GeFormRenderer });
        document.body.appendChild(element);
        return flushPromises().then(() => {
            expect(retrieveDefaultSGERenderWrapper).toHaveBeenCalledTimes(1);
            expect(element).toMatchSnapshot();
            const sections = element.shadowRoot.querySelectorAll('c-ge-form-section');
            expect(sections).toHaveLength(4);
        });
    });

    it('updates form state when a field is changed', () => {
        getPaymentTransactionStatusValues.mockResolvedValue(mockPaymentTransactionStatusValues);
        retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
        const element = createElement('c-ge-form-renderer', { is: GeFormRenderer });
        document.body.appendChild(element);
        return flushPromises().then(() => {
            const sections = element.shadowRoot.querySelectorAll('c-ge-form-section');
            const account1BillingCity = sections[1].shadowRoot.querySelectorAll('c-ge-form-field')[1];
            const changeEvent = new CustomEvent('formfieldchange', {
                detail: {
                    value: 'Gary',
                    label: 'Gary',
                    fieldMappingDevName: 'Account1_City_a992c3bb1'
                }
            });
            account1BillingCity.dispatchEvent(changeEvent);
            return flushPromises().then(() => {

            });
        });
    });


    it('saving without filling anything in should result in a page level error for missing fields', () => {
        getPaymentTransactionStatusValues.mockResolvedValue(mockPaymentTransactionStatusValues);
        retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
        // This error is specific to this mockRenderWrapperWithNoNames
        // Donor Type, Donation Date, Donation Amount, Payment Method should appear as required

        mockCheckInputValidity.mockReturnValue(true); // lightning-input is always valid
        mockCheckComboboxValidity.mockReturnValue(true); // lightning-combobox is always valid

        const element = createElement('c-ge-form-renderer', {is: GeFormRenderer});
        document.body.appendChild(element);

        const mockSubmit = jest.fn();
        element.addEventListener('submit', mockSubmit);

        return flushPromises().then(() => {
            const btns = element.shadowRoot.querySelectorAll('lightning-button');
            btns[1].click();
            return flushPromises().then(() => {
                expect(element).toMatchSnapshot();
            });
        });
    });

    it('form with payment widget, when payment method changed to credit card then payment iframe loads', () => {
        getPaymentTransactionStatusValues.mockResolvedValue(mockPaymentTransactionStatusValues);
        retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);

        mockCheckInputValidity.mockReturnValue(true); // lightning-input is always valid
        mockCheckComboboxValidity.mockReturnValue(true); // lightning-combobox is always valid

        const element = createElement('c-ge-form-renderer', { is: GeFormRenderer });
        document.body.appendChild(element);

        const mockSubmit = jest.fn();
        element.addEventListener('submit', mockSubmit);

        return flushPromises().then(() => {
            const sections = element.shadowRoot.querySelectorAll('c-ge-form-section');
            // for this template, the account1 billing city field is the second field in the second section

            const sectionWithWidget = sections[0];
            expect(sectionWithWidget.isPaymentWidgetAvailable).toBeTruthy(); // widget in first section
            dispatchFormFieldChange(sectionWithWidget, 'Credit Card', 'Payment_Method_87c012365');

            return flushPromises().then(() => {

                const { commonPaymentServices } = GeLabelService.CUSTOM_LABELS;
                const iframeSelector = `iframe[data-id='${commonPaymentServices}']`;
                const selectors = ['c-ge-form-widget', 'c-ge-form-widget-tokenize-card', iframeSelector];
                const iframeElement = traverse(sectionWithWidget, ...selectors);
                expect(iframeElement).toMatchSnapshot();
            });
        });
    });


    it('form without contact firstname when lookup populated and widget in chargeable state then sendPurchaseRequest is called with first name', () => {
        getPaymentTransactionStatusValues.mockResolvedValue(mockPaymentTransactionStatusValues);
        retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
        // This error is specific to this mockRenderWrapperWithNoNames
        // Donor Type, Contact Preferred Email, Donation Date, Donation Amount appear as required

        mockCheckInputValidity.mockReturnValue(true); // lightning-input is always valid
        mockCheckComboboxValidity.mockReturnValue(true); // lightning-combobox is always valid

        const element = createElement('c-ge-form-renderer', { is: GeFormRenderer });
        document.body.appendChild(element);

        const mockSubmit = jest.fn();
        element.addEventListener('submit', mockSubmit);

        return flushPromises().then(() => {
            const sections = element.shadowRoot.querySelectorAll('c-ge-form-section');

            const sectionWithWidget = sections[0];
            expect(sectionWithWidget.isPaymentWidgetAvailable).toBeTruthy(); // widget in first section
            dispatchFormFieldChange(sectionWithWidget, 'Credit Card', 'Payment_Method_87c012365');
            dispatchFormFieldChange(sectionWithWidget, 'Contact', 'Donation_Donor__c');
            dispatchFormFieldChange(sectionWithWidget, '000000000000000001', 'Contact1Imported__c');
            dispatchFormFieldChange(sectionWithWidget, '0.01', 'Donation_Amount_9e48e0798');
            dispatchFormFieldChange(sectionWithWidget, '2021-02-23', 'Donation_Date_de92fcb14');

            return flushPromises().then(() => {

                const { commonPaymentServices } = GeLabelService.CUSTOM_LABELS;
                const iframeSelector = `iframe[data-id='${commonPaymentServices}']`;

                const iframeElement = traverse(sectionWithWidget,
                    'c-ge-form-widget',
                    'c-ge-form-widget-tokenize-card',
                    iframeSelector
                );

                expect(iframeElement.tagName.toLowerCase()).toBe('iframe');
                const mockHandlePostMessage = jest.fn();
                iframeElement.addEventListener('message', mockHandlePostMessage);
                const btns = element.shadowRoot.querySelectorAll('lightning-button');
                btns[1].click();
                return flushPromises().then(() => {
                    expect(element).toMatchSnapshot();
                });
            });
        });
    });
});

const getFieldByIndex = (rendererElement, sectionIndex, fieldIndex) => {
    const sections = rendererElement.shadowRoot.querySelectorAll('c-ge-form-section');
    return sections[sectionIndex].shadowRoot.querySelectorAll('c-ge-form-field')[fieldIndex];
}

const traverse = (element, ...selectors) => {
    if(selectors.length === 1) {
        return element.shadowRoot.querySelector(selectors[0]);
    }
    const [firstSelector, ...rest] = selectors;
    const nextElement = element.shadowRoot.querySelector(firstSelector);
    return traverse(nextElement, ...rest);
}

const dispatchFormFieldChange = (element, value, fieldMappingDevName) => {
    const changeEvent = new CustomEvent('formfieldchange', {
        detail: {
            value,
            "label": value,
            fieldMappingDevName
        }
    });
    element.dispatchEvent(changeEvent);
};



