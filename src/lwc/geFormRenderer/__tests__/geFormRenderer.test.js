import { createElement } from 'lwc';
import GeFormRenderer from 'c/geFormRenderer';
import retrieveDefaultSGERenderWrapper from '@salesforce/apex/GE_GiftEntryController.retrieveDefaultSGERenderWrapper';
import getPaymentTransactionStatusValues from '@salesforce/apex/GE_PaymentServices.getPaymentTransactionStatusValues';

const mockWrapperWithNoNames = require('./data/retrieveDefaultSGERenderWrapper.json');
const mockPaymentTransactionStatusValues = require('./data/paymentTransactionStatusValues.js');

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

    it('loads with nothing', () => {
        const element = createElement('c-ge-form-renderer', { is: GeFormRenderer });
        document.body.appendChild(element);
        return flushPromises().then((() => {
            expect(element).toMatchSnapshot();
        }));
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

})




