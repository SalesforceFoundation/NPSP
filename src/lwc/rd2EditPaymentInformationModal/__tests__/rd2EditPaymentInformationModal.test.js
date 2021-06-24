import { createElement } from 'lwc';
import rd2EditPaymentInformationModal from 'c/rd2EditPaymentInformationModal';
import { registerSa11yMatcher } from '@sa11y/jest';
import { updateRecord } from 'lightning/uiRecordApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';

import handleUpdatePaymentCommitment from '@salesforce/apex/RD2_EntryFormController.handleUpdatePaymentCommitment';
import { mockGetIframeReply } from 'c/psElevateTokenHandler';
import { ACCOUNT_HOLDER_TYPES } from "c/geConstants";

jest.mock(
    '@salesforce/apex/RD2_EntryFormController.handleUpdatePaymentCommitment',
    () => {
        return {
            default: jest.fn(),
        };
    },
    { virtual: true }
);

const mockPaymentResultBody = require('./data/updatePaymentResultBody.json');
const mockPaymentACHResultBody = require('./data/updatePaymentACHResultBody.json');
const mockPaymentError = require('./data/updatePaymentError.json');
const recurringDonation = require('./data/recurringDonation.json');
const recurringACHDonation = require('./data/reccuringACHDonation.json');
const creditCardPayload = require('./data/creditCardPayload.json');
const paymentMethodPicklistValues = require('./data/paymentMethodPicklistValues.json');

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
        beforeEach(async () => {
            component.rdRecord = recurringDonation;
            setupUpdateCommitmentResponse(mockPaymentResultBody);
            document.body.appendChild(component);
            await flushPromises();
        });

        it('should display credit card edit form', async () => {
            const widget = getElevateWidget(component);
            assertElevateCreditCardWidget(component);

            const expectedDate = new Date(recurringDonation.fields.npe03__Next_Payment_Date__c.value);
            const utcDate = new Date(expectedDate.getUTCFullYear(), expectedDate.getUTCMonth(), expectedDate.getUTCDate());
            expect(widget.nextDonationDate.toISOString()).toBe(utcDate.toISOString());
        });

        it('should display save and cancel buttons', () => {
            assertAllButtons(component);
        });

        it('should not display do not use elevate button', () => {
            const widget = getElevateWidget(component);
            const doNotUseElevate = widget.shadowRoot.querySelector('[data-qa-locator="button Do Not Use Elevate"]');
            expect(doNotUseElevate).toBeNull();
        })

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
            setupUpdateCommitmentResponse(mockPaymentResultBody);
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

    describe('updating an existing credit card commitment', () => {
        beforeEach(() => {
            component.rdRecord = recurringDonation;
            component.accountHolderType = ACCOUNT_HOLDER_TYPES.INDIVIDUAL;
            setupUpdateCommitmentResponse(mockPaymentResultBody);
            setupIframeReply();
            updateRecord.mockResolvedValue(recurringDonation);
            getPicklistValues.emit(paymentMethodPicklistValues);
            document.body.appendChild(component);
        });

        it('has a radio group with ACH and Credit Card as options', () => {
            const radioGroup = component.shadowRoot.querySelector('lightning-radio-group');
            expect(radioGroup).toBeTruthy();
            expect(radioGroup.options).toContainOptions(['ACH', 'Credit Card']);
        })

        it('radio group displays payment method from existing record', () => {
            const radioGroup = component.shadowRoot.querySelector('lightning-radio-group');
            expect(radioGroup.value).toBe('Credit Card');
        });

        it('updates widget when payment method changed to ACH', async () => {
            const radioGroup = component.shadowRoot.querySelector('lightning-radio-group');
            changeValue(radioGroup, 'ACH');
            await flushPromises();
            expect(mockGetIframeReply).toHaveBeenCalledTimes(1);
            expect(mockGetIframeReply).toHaveBeenCalledWith(
                expect.any(HTMLIFrameElement),
                expect.objectContaining({
                    action: 'setPaymentMethod',
                    paymentMethod: 'ACH'
                }),
                undefined
            );
        });

        it('updates widget when swapped to ACH and back to Credit Card', async () => {
            const radioGroup = component.shadowRoot.querySelector('lightning-radio-group');
            changeValue(radioGroup, 'ACH');
            await flushPromises();

            changeValue(radioGroup, 'Credit Card');
            await flushPromises();

            expect(mockGetIframeReply).toHaveBeenCalledTimes(2);
            expect(mockGetIframeReply).toHaveBeenLastCalledWith(
                expect.any(HTMLIFrameElement),
                expect.objectContaining({
                    action: 'setPaymentMethod',
                    paymentMethod: 'Credit Card'
                }),
                undefined
            );
        });

        it('sets donor information on rd2 credit card form after load', async () => {
            const widget = getElevateWidget(component);
            expect(widget.achAccountType).toBe(ACCOUNT_HOLDER_TYPES.INDIVIDUAL);
        });

        it('saves successfully after swapping to ACH', async () => {
            const radioGroup = component.shadowRoot.querySelector('lightning-radio-group');
            changeValue(radioGroup, 'ACH');
            await flushPromises();

            getSaveButton(component).click();
            await flushPromises();

            const ACH_PARAMS = {
                "accountHolder": {
                    "firstName": "John",
                    "lastName": "Smith",
                    "type": "INDIVIDUAL",
                    "bankType": "CHECKING"
                },
                "achCode": "WEB",
                "nameOnAccount": "John Smith"
            };

            expect(mockGetIframeReply).toHaveBeenLastCalledWith(
                expect.any(HTMLIFrameElement),
                expect.objectContaining({
                    action: 'createAchToken',
                    params: expect.any(String)
                }),
                undefined
            );
            expect(mockGetIframeReply).toHaveBeenCalledTimes(2);
            const { params } = mockGetIframeReply.mock.calls[1][1];
            const paramObject = JSON.parse(params);
            expect(paramObject).toMatchObject(ACH_PARAMS);
        });

        it('clears credit card information after swapping to ACH and saving', async () => {
            setupUpdateCommitmentResponse(mockPaymentACHResultBody);
            const radioGroup = component.shadowRoot.querySelector('lightning-radio-group');
            changeValue(radioGroup, 'ACH');
            await flushPromises();

            getSaveButton(component).click();
            await flushPromises();
            const UPDATE_RECORD_ARGS = {
                "fields": {
                    "ACH_Last_4__c": "1234",
                    "CardExpirationMonth__c": null,
                    "CardExpirationYear__c": null,
                    "CardLast4__c": null,
                    "CommitmentId__c": "fake-commitment-uuid",
                    "Id": "a0900000008MR9bQAG",
                    "InstallmentFrequency__c": 1,
                    "PaymentMethod__c": "ACH",
                    "npe03__Contact__c": "003S000001WqpKSIAZ",
                    "npe03__Organization__c": "001S000001NAsRFIA1"
                }
            };

            const updatePaymentArgs = handleUpdatePaymentCommitment.mock.calls[0][0];

            const parsedJson = JSON.parse(updatePaymentArgs.jsonRecord);
            expect(parsedJson).toMatchObject({
                "Id": "a0900000008MR9bQAG",
                "CommitmentId__c": "11a1c101-bcde-001-111f-g1dh00i0jk111",
                "InstallmentFrequency__c": 1,
                "PaymentMethod__c": "ACH",
                "npe03__Contact__c": "003S000001WqpKSIAZ",
                "npe03__Organization__c": "001S000001NAsRFIA1"
            });
            expect(updateRecord).toHaveBeenCalledTimes(1);
            expect(updateRecord).toHaveBeenCalledWith(UPDATE_RECORD_ARGS);
        });

    });

    describe('updating an existing ach commitment', () => {
        beforeEach(() => {
            component.rdRecord = recurringACHDonation;
            component.donorType = 'Account';
            setupIframeReply();
            document.body.appendChild(component);
        });

        it('sets payer information on widget after load', async () => {
            const widget = getElevateWidget(component);
            expect(widget.payerFirstName).toBe('TestingFirstName');
            expect(widget.payerLastName).toBe('TestingLastName');
            expect(widget.payerOrganizationName).toBe('TestingLastName Household');
        });

        it('clears ach information after swapping to card and saving', async () => {
            setupUpdateCommitmentResponse(mockPaymentResultBody);
            const radioGroup = component.shadowRoot.querySelector('lightning-radio-group');
            changeValue(radioGroup, 'Credit Card');
            await flushPromises();

            getSaveButton(component).click();
            await flushPromises();
            const UPDATE_RECORD_ARGS = {
                "fields": {
                    "ACH_Last_4__c": null,
                    "CardExpirationMonth__c": "12",
                    "CardExpirationYear__c": "25",
                    "CardLast4__c": 1111,
                    "CommitmentId__c": "fake-commitment-uuid",
                    "Id": "a09S000000HNWL3IAP",
                    "InstallmentFrequency__c": 1,
                    "PaymentMethod__c": "Credit Card",
                    "npe03__Contact__c": "003S000001WqpKSIAZ",
                    "npe03__Organization__c": "001S000001NAsRFIA1"
                }
            };
            expect(updateRecord).toHaveBeenCalledTimes(1);
            expect(updateRecord).toHaveBeenCalledWith(UPDATE_RECORD_ARGS);
        });
    })
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

const changeValue = (element, value) => {
    element.value = value;
    element.dispatchEvent(new CustomEvent('change', { detail: { value }} ));
}

const setupUpdateCommitmentResponse = (responseBody) => {
    const response = {
        "statusCode": 200,
        "status": "OK",
        "body": JSON.stringify(responseBody)
    };
    handleUpdatePaymentCommitment.mockResolvedValue(JSON.stringify(response));
}

const setupIframeReply = () => {
    mockGetIframeReply.mockImplementation((iframe, message, targetOrigin) => {
        const type = "post__npsp";
        const token = "a_dummy_token";
        // if message action is "createToken", reply with dummy token immediately
        // instead of trying to hook into postMessage
        // see sendIframeMessage in mocked psElevateTokenHandler
        if (message.action === 'createToken' || message.action === 'createAchToken') {
            return { type, token };
        }

        if (message.action === 'setPaymentMethod') {
            return { type };
        }
    });
}


