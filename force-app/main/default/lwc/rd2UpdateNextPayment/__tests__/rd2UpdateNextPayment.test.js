import {createElement} from 'lwc';
import Rd2UpdateNextPayment from 'c/rd2UpdateNextPayment';
import commonPermissionErrorMessage from '@salesforce/label/c.commonPermissionErrorMessage';
import { CloseScreenEventName } from 'lightning/actions';

const mockPauseData = require('./data/getPauseData.json');
const mockGetInstallments = require('./data/getInstallments.json');
const mockScrollIntoView = jest.fn();
const mockHandleClose = jest.fn();
const FAKE_RD2_ID = '00A-fake-rd2-id'

import getPauseData from '@salesforce/apex/RD2_PauseForm_CTRL.getPauseData';
import getInstallments from '@salesforce/apex/RD2_PauseForm_CTRL.getInstallments';
import handleNextPaymentAmount from '@salesforce/apex/RD2_EntryFormController.handleNextPaymentAmount';

jest.mock('@salesforce/apex/RD2_PauseForm_CTRL.getPauseData',
    () => {
        return { default: jest.fn() }
    },
    { virtual: true }
);

jest.mock('@salesforce/apex/RD2_PauseForm_CTRL.getInstallments',
    () => {
        return { default: jest.fn() }
    },
    { virtual: true }
);

jest.mock('@salesforce/apex/RD2_EntryFormController.handleNextPaymentAmount',
    () => {
        return { default: jest.fn() }
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/label/c.RD2_NewInstallmentConfirmation',
    () => {
        return {
            default: 'The next installment on {0} will be {1}.'
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/label/c.commonUnknownError',
    () => {
        return {
            default: 'Unknown Error'
        };
    },
    { virtual: true }
);

describe('c-rd2-update-next-payment', () => {
    let component;

    beforeEach(() => {
        component = createElement('c-rd2-update-next-payment', { is: Rd2UpdateNextPayment })
        getInstallments.mockResolvedValue(mockGetInstallments);
        getPauseData.mockResolvedValue(JSON.stringify(mockPauseData));
        component.recordId = FAKE_RD2_ID;
        component.addEventListener(CloseScreenEventName, mockHandleClose);
        window.HTMLElement.prototype.scrollIntoView = mockScrollIntoView;
    });

    afterEach(() => {
        clearDOM();
    });

    describe('enter next payment amount', () => {
        beforeEach(async () => {
            document.body.appendChild(component);
            await flushPromises();
        });

        it('sends next payment amount when saving', async () => {
            handleNextPaymentAmount.mockResolvedValue({});
            const controller = new UpdateNextPaymentTestController(component);
            controller.setNextPaymentAmount(10.11);
            await flushPromises();

            controller.save();
            const updateNextPaymentArgId = handleNextPaymentAmount.mock.calls[0][0].rdId;
            const updateNextPaymentArgAmount = handleNextPaymentAmount.mock.calls[0][0].nextPaymentAmount;
            
            expect(updateNextPaymentArgId).toBe(FAKE_RD2_ID);
            expect(updateNextPaymentArgAmount).toBe(10.11);
        });

        it('sends cancel event when cancel button is clicked', () => {
            const controller = new UpdateNextPaymentTestController(component);
            controller.cancel();
            expect(mockHandleClose).toHaveBeenCalledTimes(1);
        });

        it('displays the change summary', async () => {
            const controller = new UpdateNextPaymentTestController(component);
            controller.setNextPaymentAmount(12.99);
            await flushPromises();
            expect(controller.rowSummaryValue()).toBe("The next installment on 10/18/2021 will be $12.99.");
        });

    });


    describe('error states', () => {

        it('save button deactivates when next payment amount is empty', async () => {
            document.body.appendChild(component);
            await flushPromises();

            const controller = new UpdateNextPaymentTestController(component);
            expect(controller.saveButton().disabled).toBeTruthy();

            controller.setNextPaymentAmount(12.99);
            await flushPromises();

            expect(controller.saveButton().disabled).toBeFalsy();

            controller.setNextPaymentAmount('');
            await flushPromises();

            expect(controller.saveButton().disabled).toBeTruthy();
        });

        it('displays an error if user does not have access', async () => {
            await getPauseData.mockResolvedValue(JSON.stringify({
                ...mockPauseData,
                hasAccess: false
            }));
            component.recordId = FAKE_RD2_ID;
            document.body.appendChild(component);
            await flushPromises();

            const controller = new UpdateNextPaymentTestController(component);

            expect(controller.utilPageLevelMessage().subtitle).toBe(commonPermissionErrorMessage);
        });

        it('displays an error if apex class RD2_EntryFormController is inaccessible', async () => {
            const controller = new UpdateNextPaymentTestController(component);
            getPauseData.mockRejectedValue({
                "status": 500,
                "body": {
                    "message": "You do not have access to the Apex class named 'RD2_EntryFormController'."
                },
                "headers": {}
            });
            getInstallments.mockResolvedValue(mockGetInstallments);
            component.recordId = FAKE_RD2_ID;
            document.body.appendChild(component);
            await flushPromises();

            expect(controller.utilPageLevelMessage().subtitle).toBe("You do not have access to the Apex class named 'RD2_EntryFormController'.");

        });

        it('on save, when Exception encountered, displays error', async () => {
            handleNextPaymentAmount.mockRejectedValue({});
            const controller = new UpdateNextPaymentTestController(component);
            getPauseData.mockResolvedValue(JSON.stringify(mockPauseData));
            getInstallments.mockResolvedValue(mockGetInstallments);
            component.recordId = FAKE_RD2_ID;
            document.body.appendChild(component);
            await flushPromises();

            controller.setNextPaymentAmount(12.99);
            await flushPromises();

            controller.save();
            await flushPromises();

            expect(controller.utilPageLevelMessage().subtitle).toBe('Unknown Error');
        });

        it('when no permission to fields on installments, displays error', async () => {
            const controller = new UpdateNextPaymentTestController(component);
            getPauseData.mockResolvedValue(JSON.stringify(mockPauseData));
            getInstallments.mockRejectedValue({
                "status": 500,
                "body": {
                    "message": "You don't have permissions to view Upcoming Installments. Please contact your system administrator for more information."
                },
                "headers": {}
            });
            component.recordId = FAKE_RD2_ID;
            document.body.appendChild(component);

            await flushPromises();

            expect(controller.utilPageLevelMessage().subtitle).toBe('You don\'t have permissions to view Upcoming Installments. Please contact your system administrator for more information.');
        });
    });
});


class UpdateNextPaymentTestController {
    component;

    constructor(component) {
        this.component = component;
    }

    setNextPaymentAmount(value) {
        const field = this.nextPaymentAmount();
        field.value = value;
        field.dispatchEvent(new CustomEvent('change', { detail: { value } }));
    }

    nextPaymentAmount() {
        return this.component.shadowRoot.querySelector("[data-id='nextPaymentAmount']");
    }

    save() {
        this.saveButton().click();
    }

    saveButton() {
        return this.component.shadowRoot.querySelector("[data-id='saveButton']");
    }

    cancel() {
        this.cancelButton().click();
    }

    cancelButton() {
        return this.component.shadowRoot.querySelector("[data-id='cancelButton']");
    }

    rowSummaryValue() {
        return this.component.shadowRoot.querySelector("[data-id='rowSummary']").value;
    }

    utilPageLevelMessage() {
        return this.component.shadowRoot.querySelector("c-util-page-level-message");
    }
}