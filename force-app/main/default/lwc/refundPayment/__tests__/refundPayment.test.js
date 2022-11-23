import { createElement } from 'lwc';
import { CloseScreenEventName } from 'lightning/actions';
import refundPayment from 'c/refundPayment';
import processRefund from "@salesforce/apex/PMT_RefundController.processRefund";
import getInitialView from "@salesforce/apex/PMT_RefundController.getInitialView";

const mockRefundView = require('./data/RefundView.json');

jest.mock('@salesforce/apex/PMT_RefundController.processRefund',
    () => ({ default : jest.fn() }),
    { virtual : true}
);

jest.mock('@salesforce/apex/PMT_RefundController.getInitialView',
    () => ({ default : jest.fn() }),
    { virtual : true}
);

describe('c-refund-payment', () => {
    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    it('The UI should load correctly', async () => {
        const component = createElement('c-refund-payment', { is: refundPayment });

        getInitialView.mockResolvedValue(mockRefundView);
        processRefund.mockResolvedValue(mockRefundView);
        component.recordId = 'dummyId';
        document.body.appendChild(component);
        await flushPromises();

        expect(cancelButton(component).title).toBe('c.stgBtnCancel');
        expect(refundButton(component).title).toBe('c.pmtRefundPaymentConfirmedButton');
        expect(refundAmountInput(component)).not.toBeNull();
        expect(refundAmountInput(component).label).toBe('c.pmtRefundAmount');
        expect(remainingBalanceDisplay(component).value).toBe(mockRefundView.remainingBalance);
        expect(refundAmountInput(component).value).toBe(mockRefundView.paymentAmount);
    });

    it('The screen should be closed on Cancel', async () => {
        const component = createElement('c-refund-payment', { is: refundPayment });

        getInitialView.mockResolvedValue(mockRefundView);
        processRefund.mockResolvedValue(mockRefundView);
        document.body.appendChild(component);
        await flushPromises();

        const handler = jest.fn();
        component.addEventListener(CloseScreenEventName, handler);
        cancelButton(component).click();

        expect(handler).toHaveBeenCalled();
    });


    it('The screen should be closed on Successful refund', async () => {
        const component = createElement('c-refund-payment', { is: refundPayment });

        getInitialView.mockResolvedValue(mockRefundView);
        processRefund.mockResolvedValue({
            hasRequiredPermissions : true,
            isSuccess : true,
            redirectToPaymentId : true
        });
        document.body.appendChild(component);
        await flushPromises();

        const actionHandler = jest.fn();
        component.addEventListener(CloseScreenEventName, actionHandler);
        refundButton(component).click();
        await flushPromises();

        expect(actionHandler).toHaveBeenCalled();
    });
});

const cancelButton = (component) => {
    return component.shadowRoot.querySelector('lightning-button[data-id="cancelButton"]');
}
const refundButton = (component) => {
    const button = component.shadowRoot.querySelector('lightning-button[data-id="refundButton"]');
    return button;
}
const refundAmountInput = (component) => {
    return component.shadowRoot.querySelector('lightning-input');
}
const remainingBalanceDisplay = (component) => {
    return component.shadowRoot.querySelector('lightning-formatted-number[id="remaining-balance"]');
}