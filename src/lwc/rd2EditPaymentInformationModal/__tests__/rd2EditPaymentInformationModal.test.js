import { createElement } from 'lwc';
import rd2EditPaymentInformationModal from 'c/rd2EditPaymentInformationModal';
import { registerSa11yMatcher } from '@sa11y/jest';
import { updateRecord } from 'lightning/uiRecordApi';

import handleUpdatePaymentCommitment from '@salesforce/apex/RD2_EntryFormController.handleUpdatePaymentCommitment';
jest.mock(
    '@salesforce/apex/RD2_EntryFormController.handleUpdatePaymentCommitment',
    () => {
        return {
            default: jest.fn(),
        };
    },
    { virtual: true }
);

const mockPaymentResult = require('./data/updatePaymentResult.json');
const mockPaymentError = require('./data/updatePaymentError.json');
const recurringDonation = require('./data/recurringDonation.json');
const creditCardPayload = require('./data/creditCardPayload.json');

describe('c-rd2-edit-payment-information-modal', () => {
    let component;

    beforeAll(() => {
        registerSa11yMatcher();
    });

    beforeEach(() => {
        component = createElement('c-rd2-edit-payment-information-modal', {
            is: rd2EditPaymentInformationModal,
        });
    });

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    /***
    * @description Verifies header is always displayed on the widget
    */
    it('should display header', () => {
        document.body.appendChild(component);

        const header = component.shadowRoot.querySelector('h2');
        expect(header).not.toBeNull();
        expect(header.textContent).toBe('c.RD2_PaymentInformation');
    });


    /***
    * @description Verifies the widget when the Recurring Donation has no error
    * or there is no error after the latest successful payment
    */
    describe('on open of the Edit Payment Information Modal', () => {
        beforeEach(() => {
            component.rdRecord = recurringDonation;
            handleUpdatePaymentCommitment.mockResolvedValue(mockPaymentResult);
            document.body.appendChild(component);
        });

        it('should display credt card edit form', async () => {
            return global.flushPromises()
            .then(async () => {
                const widget = getElevateWidget(component);
                assertElevateCreditCardWidget(component);

                const expectedDate = new Date(recurringDonation.fields.npe03__Next_Payment_Date__c.value);
                const utcDate = new Date(expectedDate.getUTCFullYear(), expectedDate.getUTCMonth(), expectedDate.getUTCDate());
                expect(widget.nextDonationDate.toISOString()).toBe(utcDate.toISOString());
            });
        });

        it('should display save and cancel buttons', async () => {
            assertAllButtons(component);
        });

        it('should close the modal when cancel icon is clicked', async () => {
            const handler = jest.fn();
            component.addEventListener('close', handler);

            return global.flushPromises().then(async () => {
                const closeIcon = getCancelButtonIcon(component);
                dispatchClickEvent(closeIcon);
            })
            .then(async () => {
                expect(handler).toHaveBeenCalledTimes(1);
            });
        });

        it('should close the modal when cancel button is clicked', async () => {
            const closeEventHandler = jest.fn();
            component.addEventListener('close', closeEventHandler);

            return global.flushPromises().then(async () => {
                const closeButton = getCancelButtonIcon(component);
                dispatchClickEvent(closeButton);
            })
            .then(async () => {
                expect(closeEventHandler).toBeCalled();
            });
        });

        it("the modal should be accessible", async () => {
            return global.flushPromises().then(async () => {
                await expect(component).toBeAccessible();
            });
        });
    });

    describe('on successfully save with new payment information', () => {
        beforeEach(() => {
            component.rdRecord = recurringDonation;

            const mockPaymentResultString = mockPaymentResult;
            mockPaymentResultString.body = JSON.stringify(mockPaymentResultString.body);
            handleUpdatePaymentCommitment.mockResolvedValue(JSON.stringify(mockPaymentResultString));

            updateRecord.mockResolvedValue(recurringDonation);
            document.body.appendChild(component);
            
        });

        it('should close the modal when successfully save', async () => {
            const closeEventHandler = jest.fn();
            component.addEventListener('close', closeEventHandler);
            
            return global.flushPromises().then( async () => {
                const creditCardWidget = getElevateWidget(component);
                creditCardWidget.returnToken = jest.fn().mockImplementation(() => {return creditCardPayload});

                dispatchClickEvent(getSaveButton(component));
            })
            .then(async () => {
                expect(closeEventHandler).toBeCalled();
                const errorContainer = component.shadowRoot.querySelector('c-util-page-level-message');
                expect(errorContainer).toBeNull();
            });
        });
    });

    describe('on fail to save the payment information', () => {
        beforeEach(() => {
            component.rdRecord = recurringDonation;
            document.body.appendChild(component);
        });

        it('should not close modal if token is failed to generate', async () => {
            const closeEventHandler = jest.fn();
            component.addEventListener('close', closeEventHandler);

            return global.flushPromises().then( async () => {
                const creditCardWidget = getElevateWidget(component);
                creditCardWidget.returnToken = jest.fn().mockImplementation(() => {throw new Error('fail')});

                dispatchClickEvent(getSaveButton(component));
            })
            .then(async () => {
                expect(closeEventHandler).not.toBeCalled();
            });
        });

        it('should display error message if Elevate commitment update fail', async () => {
            const closeEventHandler = jest.fn();
            component.addEventListener('close', closeEventHandler);
            return global.flushPromises().then( async () => {
                const creditCardWidget = getElevateWidget(component);
                creditCardWidget.returnToken = jest.fn().mockImplementation(() => {return creditCardPayload});

                handleUpdatePaymentCommitment.mockResolvedValue(JSON.stringify(mockPaymentError));
                dispatchClickEvent(getSaveButton(component));
            })
            .then(async () => {
                expect(closeEventHandler).not.toBeCalled();
                const errorContainer = component.shadowRoot.querySelector('c-util-page-level-message');
                expect(errorContainer).not.toBeNull();
            });
        });
    });
});

// Helpers
//////////////
/***
* @description Get the elevate credit widget component from the component
*/
const getElevateWidget = (component) => {
    return component.shadowRoot.querySelector('c-rd2-elevate-credit-card-form');
}

/***
* @description Verifies elevate credit card widget exists
*/
const assertElevateCreditCardWidget = (component) => {
    const elevateWidget = getElevateWidget(component);
    expect(elevateWidget).not.toBeNull();
}

/***
* @description Verifies all buttons are properlly rendered in the components
*/
const assertAllButtons = (component) => {
    const cancelIcon = getCancelButtonIcon(component);
    const cancelButton = getCancelButton(component);
    const saveButton = getSaveButton(component);

    expect(cancelIcon).not.toBeNull();
    expect(cancelButton).not.toBeNull();
    expect(saveButton).not.toBeNull();
}

/***
* @description Get the close icon from the component
*/
const getCancelButtonIcon = (component) => {
    return component.shadowRoot.querySelector('lightning-button-icon');
}

/***
* @description Get the close button from the component
*/
const getCancelButton = (component) => {
    return component.shadowRoot.querySelector('[data-id="cancelButton"]');
}

/***
* @description Get the save button from the component
*/
const getSaveButton = (component) => {
    return component.shadowRoot.querySelector('[data-id="submitButton"]');
}

/***
* @description Dispatch event when user clicks on the element
*/
const dispatchClickEvent = (element) => {
    element.dispatchEvent(
        new CustomEvent('click')
    );
}


