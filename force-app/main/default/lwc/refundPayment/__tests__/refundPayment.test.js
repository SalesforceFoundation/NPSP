import { createElement } from 'lwc';
import { CloseScreenEventName } from 'lightning/actions';
import { ShowToastEventName } from 'lightning/platformShowToastEvent';
import refundPayment from 'c/refundPayment';
import { getRecord } from "lightning/uiRecordApi";
import processRefund from "@salesforce/apex/PMT_RefundController.processRefund";
import getPermissionData from "@salesforce/apex/PMT_RefundController.getPermissionData";

const paymentGetRecord = require("./data/paymentGetRecord.json");
const mockRefundView = require('./data/RefundView.json');

jest.mock('@salesforce/apex/PMT_RefundController.processRefund',
    () => ({ default : jest.fn() }),
    { virtual : true}
);

jest.mock('@salesforce/apex/PMT_RefundController.getPermissionData',
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
        getRecord.emit(paymentGetRecord, (config) => {
            return config.recordId === "a01FakePayment00Id";
        });

        getPermissionData.mockResolvedValue(mockRefundView);
        processRefund.mockResolvedValue(mockRefundView);
        document.body.appendChild(component);
        await flushPromises();

        expect(cancelButton(component).title).toBe('c.stgBtnCancel');
        expect(refundButton(component).title).toBe('c.pmtRefundPaymentTitle');
    });

    it('The screen should be closed on Cancel', async () => {
        const component = createElement('c-refund-payment', { is: refundPayment });
        getRecord.emit(paymentGetRecord, (config) => {
            return config.recordId === "a01FakePayment00Id";
        });

        getPermissionData.mockResolvedValue(mockRefundView);
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
        getRecord.emit(paymentGetRecord, (config) => {
            return config.recordId === "a01FakePayment00Id";
        });

        getPermissionData.mockResolvedValue(mockRefundView);
        processRefund.mockResolvedValue({
            hasRequiredPermissions : true,
            isSuccess : true,
            redirectToPaymentId : true
        });
        document.body.appendChild(component);
        await flushPromises();

        const actionHandler = jest.fn();
        component.addEventListener(CloseScreenEventName, actionHandler);
        const toastHandler = jest.fn();
        component.addEventListener(ShowToastEventName, toastHandler);
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