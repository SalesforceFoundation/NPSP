import {createElement} from 'lwc';
import Rd2EntryForm from 'c/rd2EntryForm';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import { mockGetIframeReply } from "c/psElevateTokenHandler";

import getRecurringSettings from '@salesforce/apex/RD2_EntryFormController.getRecurringSettings';
import getRecurringData from '@salesforce/apex/RD2_EntryFormController.getRecurringData';
import hasRequiredFieldPermissions from '@salesforce/apex/RD2_EntryFormController.hasRequiredFieldPermissions';
import handleCommitment from '@salesforce/apex/RD2_EntryFormController.handleCommitment';

import RD2_EntryFormMissingPermissions from '@salesforce/label/c.RD2_EntryFormMissingPermissions';
import FIELD_INSTALLMENT_PERIOD from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installment_Period__c';
import FIELD_DAY_OF_MONTH from '@salesforce/schema/npe03__Recurring_Donation__c.Day_of_Month__c';
import RECURRING_DONATION_OBJECT from '@salesforce/schema/npe03__Recurring_Donation__c';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import CONTACT_OBJECT from '@salesforce/schema/Contact';


const recurringSettingsResponse = require('./data/getRecurringSettings.json');
const recurringDonationObjectInfo = require('./data/recurringDonationObjectInfo.json');
const installmentPeriodPicklistValues = require('./data/installmentPeriodPicklistValues.json');
const dayOfMonthPicklistValues = require('./data/dayOfMonthPicklistValues.json');
const contactPartialDescribe = require('./data/contactPartialDescribe.json');
const accountPartialDescribe = require('./data/accountPartialDescribe.json');
const contactGetRecord = require('./data/contactGetRecord.json');
const accountGetRecord = require('./data/accountGetRecord.json');
const rd2WithCardCommitment = require('./data/rd2WithCardCommitment.json');
const rd2WithACHCommitment = require('./data/rd2WithACHCommitment.json');
const rd2WithoutCommitmentCard = require('./data/rd2WithoutCommitmentCard.json');
const recurringDataContactResponse = require('./data/recurringDataContactResponse.json');
const handleCommitmentResponseBody = require('./data/handleCommitmentResponseBody.json');
const handleCommitmentResponseBodyACH = require('./data/handleCommitmentResponseBodyACH.json');

const mockScrollIntoView = jest.fn();
const mockRecordEditFormSubmit = jest.fn();

const FAKE_ACH_RD2_ID = 'a0963000008pebAAAQ';
const FAKE_CARD_RD2_ID = 'a0963000008oxZnAAI';

const EXPECTED_BUSINESS_ACH_PARAMS = {
    nameOnAccount: "Donor Organization",
    accountHolder: {
        type: "BUSINESS",
        businessName: "Anthropy",
        accountName: "Donor Organization",
        bankType: "CHECKING"
    },
    achCode: 'WEB'
};

const EXPECTED_INDIVIDUAL_ACH_PARAMS = {
    nameOnAccount: "John Smith",
    accountHolder: {
        type: "INDIVIDUAL",
        firstName: "John",
        lastName: "Smith",
        bankType: "CHECKING"
    },
    achCode: 'WEB'
};

jest.mock('@salesforce/apex/RD2_EntryFormController.getRecurringSettings',
    () => {
        return { default: jest.fn() }
    },
    { virtual: true }
);

jest.mock('@salesforce/apex/RD2_EntryFormController.hasRequiredFieldPermissions',
    () => {
        return { default: jest.fn() }
    },
    { virtual: true }
);

jest.mock('@salesforce/apex/RD2_EntryFormController.handleCommitment',
    () => {
        return { default: jest.fn() }
    },
    { virtual: true }
);


describe('c-rd2-entry-form', () => {

    beforeEach(() => {
        getRecurringSettings.mockResolvedValue(recurringSettingsResponse);
        hasRequiredFieldPermissions.mockResolvedValue(true);
        window.HTMLElement.prototype.scrollIntoView = mockScrollIntoView;
    });

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    describe('creating new records', () => {
        it('displays an error when user does not have required permissions', async () => {
            hasRequiredFieldPermissions.mockResolvedValue(false);
            const element = createRd2EntryForm();
            const controller = new RD2FormController(element);

            await flushPromises();

            expect(mockScrollIntoView).toHaveBeenCalledTimes(1);

            const saveButton = controller.saveButton();
            expect(saveButton.disabled).toBe(true);

            const formattedText = element.shadowRoot.querySelector('lightning-formatted-text');
            expect(formattedText.value).toBe(RD2_EntryFormMissingPermissions);
        });

        it('elevate customer selects Credit Card payment method then widget displayed', async () => {
            const element = createRd2EntryForm();
            const controller = new RD2FormController(element);

            await flushPromises();

            await setupWireMocksForElevate();
            controller.setDefaultInputFieldValues();

            controller.paymentMethod().changeValue('Credit Card');

            await flushPromises();

            const elevateWidget = controller.elevateWidget();
            expect(controller.disableElevateButton()).toBeTruthy();
            expect(elevateWidget).toBeTruthy();

        });

        it('elevate customer selects ACH payment method then widget displayed', async () => {
            const element = createRd2EntryForm();
            const controller = new RD2FormController(element);
            await flushPromises();

            await setupWireMocksForElevate();
            controller.setDefaultInputFieldValues();

            controller.paymentMethod().changeValue('ACH');

            await flushPromises();

            const elevateWidget = controller.elevateWidget();
            expect(elevateWidget).toBeTruthy();
            expect(controller.disableElevateButton()).toBeTruthy();
            expect(controller.cancelUpdatePaymentButton()).toBeFalsy();
        });
    });

    describe('tokenization', () => {

        beforeEach(() => {
            setupIframeReply();
        });

        it('individual donor, contact name is used for account holder name when tokenizing an ACH payment', async () => {
            setupCommitmentResponse(handleCommitmentResponseBodyACH);
            const element = createRd2EntryForm();
            const controller = new RD2FormController(element);

            await flushPromises();

            await setupWireMocksForElevate();

            controller.setDefaultInputFieldValues();
            controller.setupSubmitMock();
            controller.contactLookup().changeValue('001fakeContactId');
            await flushPromises();

            getRecord.emit(contactGetRecord, config => {
                return config.recordId === '001fakeContactId';
            });

            controller.amount().changeValue(1.00);
            controller.paymentMethod().changeValue('ACH');

            await flushPromises();

            const elevateWidget = controller.elevateWidget();
            expect(elevateWidget).toBeTruthy();
            expect(controller.disableElevateButton()).toBeTruthy();
            expect(elevateWidget.payerFirstName).toBe('John');
            expect(elevateWidget.payerLastName).toBe('Smith');

            controller.saveButton().click();

            await flushPromises();
            validateIframeMessage(mockGetIframeReply.mock.calls[0], EXPECTED_INDIVIDUAL_ACH_PARAMS);
            const EXPECTED_RECORD = {
                "RecurringType__c": "Open",
                "Day_of_Month__c": "6",
                "StartDate__c": "2021-02-03",
                "npe03__Installment_Period__c": "Monthly",
                "npe03__Contact__c": "001fakeContactId",
                "npe03__Date_Established__c": "2021-02-03",
                "PaymentMethod__c": "ACH",
                "npe03__Amount__c": 1,
                "InstallmentFrequency__c": 1
            };
            validateCommitmentMessage(EXPECTED_RECORD);
            expect(mockRecordEditFormSubmit).toHaveBeenCalled();
            expect(mockRecordEditFormSubmit).toHaveBeenCalledWith({
                "ACH_Last_4__c": "5432",
                "CardExpirationMonth__c": null,
                "CardExpirationYear__c": null,
                "CardLast4__c": null,
                "CommitmentId__c": "ffd252d6-7ffc-46a0-994f-00f7582263d2",
                "Day_of_Month__c": "6",
                "InstallmentFrequency__c": 1,
                "PaymentMethod__c": "ACH",
                "RecurringType__c": "Open",
                "StartDate__c": "2021-02-03",
                "npe03__Amount__c": 1,
                "npe03__Contact__c": "001fakeContactId",
                "npe03__Date_Established__c": "2021-02-03",
                "npe03__Installment_Period__c": "Monthly"
            });
        });

        it('organization donor, account name is used when tokenizing an ACH payment', async () => {

            const element = createRd2EntryForm();
            const controller = new RD2FormController(element);

            await flushPromises();

            await setupWireMocksForElevate();

            controller.setDefaultInputFieldValues();
            controller.dayOfMonth().setValue('6');
            controller.donorType().changeValue('Account');
            controller.paymentMethod().changeValue('ACH');
            await flushPromises();


            controller.accountLookup().changeValue('001fakeAccountId');
            await flushPromises();

            getRecord.emit(accountGetRecord, config => {
                return config.recordId === '001fakeAccountId';
            });
            await flushPromises();
            controller.amount().changeValue(1.00);

            await flushPromises();

            const elevateWidget = controller.elevateWidget();
            expect(elevateWidget).toBeTruthy();
            expect(elevateWidget.payerOrganizationName).toBe("Donor Organization");

            controller.saveButton().click();

            await flushPromises();

            expect(mockGetIframeReply).toHaveBeenCalled();

            validateIframeMessage(mockGetIframeReply.mock.calls[0], EXPECTED_BUSINESS_ACH_PARAMS);
            const EXPECTED_RECORD = {
                "RecurringType__c": "Open",
                "Day_of_Month__c": "6",
                "StartDate__c": "2021-02-03",
                "npe03__Installment_Period__c": "Monthly",
                "npe03__Organization__c": "001fakeAccountId",
                "npe03__Date_Established__c": "2021-02-03",
                "PaymentMethod__c": "ACH",
                "npe03__Amount__c": 1,
                "InstallmentFrequency__c": 1
            };
            validateCommitmentMessage(EXPECTED_RECORD);
        });
    });

    describe('edit mode', () => {

        beforeEach(() => {
            getRecurringData.mockResolvedValue(recurringDataContactResponse);
            setupIframeReply();
        })

        it('rd2 record with card payment, when editing, displays card information', async () => {

            const element = createRd2EditForm(FAKE_CARD_RD2_ID);
            const controller = new RD2FormController(element);
            await flushPromises();

            getRecord.emit(rd2WithCardCommitment, config => {
                return config.recordId === FAKE_CARD_RD2_ID;
            });

            await setupWireMocksForElevate();
            const elevateWidget = controller.elevateWidget();
            expect(elevateWidget).toBeTruthy();

            expect(controller.last4().value).toBe('1212');
            expect(controller.cardExpriation().value).toBe('02/2023');

        });


        it('rd2 record with ACH payment, when editing, displays ACH last 4', async () => {

            const element = createRd2EditForm(FAKE_ACH_RD2_ID);
            const controller = new RD2FormController(element);
            await flushPromises();

            getRecord.emit(rd2WithACHCommitment, config => {
                return config.recordId === FAKE_ACH_RD2_ID;
            });

            await setupWireMocksForElevate();

            const elevateWidget = controller.elevateWidget();
            expect(elevateWidget).toBeTruthy();
            expect(controller.last4().value).toBe('1111');

        });


        it('rd2 record with credit card payment type but no commitment, when editing, displays widget', async () => {
            const element = createRd2EditForm(FAKE_CARD_RD2_ID);
            const controller = new RD2FormController(element);
            await flushPromises();

            getRecord.emit(rd2WithoutCommitmentCard, config => {
                return config.recordId === FAKE_CARD_RD2_ID;
            });

            await flushPromises();

            getRecord.emit(contactGetRecord, config => {
                return config.recordId === '001fakeContactId';
            });

            await setupWireMocksForElevate();

            expect(controller.elevateWidget()).toBeTruthy();

        });

        it('rd2 record with check payment type, when editing and payment type changed to credit card, displays widget', async () => {
            const element = createRd2EditForm(FAKE_CARD_RD2_ID);
            const controller = new RD2FormController(element);
            await flushPromises();

            const rd2WithoutCommitmentCheck = generateMockFrom(rd2WithoutCommitmentCard)
                .withFieldValue('PaymentMethod__c', 'Check');

            getRecord.emit(rd2WithoutCommitmentCheck, config => {
                return config.recordId === FAKE_CARD_RD2_ID;
            });

            await flushPromises();

            getRecord.emit(contactGetRecord, config => {
                return config.recordId === '001fakeContactId';
            });

            await setupWireMocksForElevate();
            controller.setDefaultInputFieldValues();

            expect(controller.elevateWidget()).toBeNull();

            controller.paymentMethod().changeValue('Credit Card');

            await flushPromises();

            expect(controller.elevateWidget()).toBeTruthy();
            expect(controller.disableElevateButton()).toBeTruthy();
            expect(controller.cancelUpdatePaymentButton()).toBeFalsy();
        });

        it('rd2 record, when editing, uses existing contact information in tokenization', async () => {

            const element = createRd2EditForm(FAKE_CARD_RD2_ID);
            const controller = new RD2FormController(element);
            await flushPromises();

            getRecord.emit(rd2WithoutCommitmentCard, config => {
                return config.recordId === FAKE_CARD_RD2_ID;
            });

            await flushPromises();

            getRecord.emit(contactGetRecord, config => {
                return config.recordId === '001fakeContactId';
            });

            await setupWireMocksForElevate();
            controller.setDefaultInputFieldValuesEdit();

            controller.paymentMethod().changeValue('ACH');

            await flushPromises();

            expect(controller.elevateWidget()).toBeTruthy();
            expect(controller.disableElevateButton()).toBeTruthy();

            controller.saveButton().click();

            await flushPromises();

            expect(mockGetIframeReply).toHaveBeenCalled();
            expect(mockGetIframeReply).toHaveBeenCalledTimes(1);
            validateIframeMessage(mockGetIframeReply.mock.calls[0], EXPECTED_INDIVIDUAL_ACH_PARAMS);

            const EXPECTED_RECORD = {
                "RecurringType__c": "Open",
                "Day_of_Month__c": "6",
                "StartDate__c": "2021-02-03",
                "npe03__Installment_Period__c": "Monthly",
                "npe03__Contact__c": "001fakeContactId",
                "npe03__Date_Established__c": "2021-02-03",
                "PaymentMethod__c": "ACH",
                "Status__c": "Active",
                "npe03__Amount__c": 0.5,
                "Id": "a0963000008oxZnAAI",
                "InstallmentFrequency__c": 1
            };

            validateCommitmentMessage(EXPECTED_RECORD);
        });

        it('clears credit card fields when payment method changed to ACH', async () => {
            setupCommitmentResponse(handleCommitmentResponseBodyACH);
            const element = createRd2EditForm(FAKE_CARD_RD2_ID);
            const controller = new RD2FormController(element);
            await flushPromises();
            const rd2WithCommitmentCard = generateMockFrom(rd2WithoutCommitmentCard)
                .withFieldValue('CommitmentId__c', 'fake-commitment-uuid');

            getRecord.emit(rd2WithCommitmentCard, config => {
                return config.recordId === FAKE_CARD_RD2_ID;
            });

            await flushPromises();

            getRecord.emit(contactGetRecord, config => {
                return config.recordId === '001fakeContactId';
            });

            await setupWireMocksForElevate();
            controller.setDefaultInputFieldValuesEdit();
            controller.setupSubmitMock();

            expect(controller.elevateWidget()).toBeTruthy();
            expect(controller.updatePaymentButton()).toBeTruthy();

            controller.paymentMethod().changeValue('ACH');
            await flushPromises();

            expect(controller.updatePaymentButton()).toBeFalsy();
            expect(controller.cancelUpdatePaymentButton()).toBeTruthy();
            expect(controller.disableElevateButton()).toBeFalsy();

            controller.saveButton().click();
            await flushPromises();

            expect(mockRecordEditFormSubmit).toHaveBeenCalled();
            expect(mockRecordEditFormSubmit).toHaveBeenCalledWith({
                "ACH_Last_4__c": "5432",
                "CardExpirationMonth__c": null,
                "CardExpirationYear__c": null,
                "CardLast4__c": null,
                "CommitmentId__c": "ffd252d6-7ffc-46a0-994f-00f7582263d2",
                "Day_of_Month__c": "6",
                "Id": "a0963000008oxZnAAI",
                "InstallmentFrequency__c": 1,
                "PaymentMethod__c": "ACH",
                "RecurringType__c": "Open",
                "StartDate__c": "2021-02-03",
                "Status__c": "Active",
                "npe03__Amount__c": 0.5,
                "npe03__Contact__c": "001fakeContactId",
                "npe03__Date_Established__c": "2021-02-03",
                "npe03__Installment_Period__c": "Monthly"
            });
        });


        it('clears ACH fields when payment method changed to Card', async () => {
            setupCommitmentResponse(handleCommitmentResponseBody);
            const element = createRd2EditForm(FAKE_ACH_RD2_ID);
            const controller = new RD2FormController(element);
            await flushPromises();

            getRecord.emit(rd2WithACHCommitment, config => {
                return config.recordId === FAKE_ACH_RD2_ID;
            });

            await flushPromises();

            getRecord.emit(contactGetRecord, config => {
                return config.recordId === '001fakeContactId';
            });

            await setupWireMocksForElevate();
            controller.setDefaultInputFieldValuesEdit();
            controller.setupSubmitMock();

            expect(controller.elevateWidget()).toBeTruthy();
            expect(controller.updatePaymentButton()).toBeTruthy();

            controller.paymentMethod().changeValue('Credit Card');
            await flushPromises();

            expect(controller.updatePaymentButton()).toBeFalsy();
            expect(controller.cancelUpdatePaymentButton()).toBeTruthy();

            controller.saveButton().click();
            await flushPromises();

            expect(mockRecordEditFormSubmit).toHaveBeenCalled();
            expect(mockRecordEditFormSubmit).toHaveBeenCalledWith({
                "ACH_Last_4__c": null,
                "CardExpirationMonth__c": "05",
                "CardExpirationYear__c": "2023",
                "CardLast4__c": "1111",
                "CommitmentId__c": "ffd252d6-7ffc-46a0-994f-00f7582263d2",
                "Day_of_Month__c": "6",
                "Id": "a0963000008pebAAAQ",
                "InstallmentFrequency__c": 1,
                "PaymentMethod__c": "Credit Card",
                "RecurringType__c": "Open",
                "StartDate__c": "2021-02-03",
                "Status__c": "Active",
                "npe03__Amount__c": 0.5,
                "npe03__Contact__c": "001fakeContactId",
                "npe03__Date_Established__c": "2021-02-03",
                "npe03__Installment_Period__c": "Monthly"
            });
        });
    });
});

const createRd2EntryForm = () => {
    const element = createElement('c-rd2-entry-form', {is: Rd2EntryForm});
    document.body.appendChild(element);
    return element;
}

const createRd2EditForm = (recordId) => {
    const element = createElement('c-rd2-entry-form', {is: Rd2EntryForm});
    element.recordId = recordId;
    document.body.appendChild(element);
    return element;
}

const generateMockFrom = (recordMock) => {
    return {
        withFieldValue: (field, value) => {
            return {
                ...recordMock,
                fields: {
                    ...recordMock.fields,
                    [field]: { value }
                }
            }
        }
    }
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

const setupCommitmentResponse = (responseBody) => {
    const response = {
        "statusCode": 200,
        "status": "OK",
        "body": JSON.stringify(responseBody)
    };
    handleCommitment.mockResolvedValue(JSON.stringify(response));
}

const validateCommitmentMessage = (expectedParams) => {
    expect(handleCommitment).toHaveBeenCalled();
    const { jsonRecord, paymentMethodToken } = handleCommitment.mock.calls[0][0];
    const deserialized = JSON.parse(jsonRecord);
    expect(deserialized).toMatchObject(expectedParams);
    expect(paymentMethodToken).toBe('a_dummy_token');
}

const validateIframeMessage = (tokenizeMockCall, expectedParams) => {

    expect(mockGetIframeReply).toHaveBeenCalled();
    const tokenizeMessage = tokenizeMockCall[1];
    const serializedParams = tokenizeMessage.params;
    const deserializedParams = JSON.parse(serializedParams);
    expect(deserializedParams).toMatchObject(expectedParams);

    expect(mockGetIframeReply).toHaveBeenCalledWith(
        expect.any(HTMLIFrameElement), // iframe
        expect.objectContaining({
            action: "createAchToken",
            params: expect.any(String)
        }),
        undefined
    );
}

const setupWireMocksForElevate = async () => {
    getObjectInfo.emit(recurringDonationObjectInfo, config => {
        return config.objectApiName === RECURRING_DONATION_OBJECT.objectApiName;
    });

    getObjectInfo.emit(contactPartialDescribe, config => {
        return config.objectApiName.objectApiName === CONTACT_OBJECT.objectApiName;
    });

    getObjectInfo.emit(accountPartialDescribe, config => {
        return config.objectApiName.objectApiName === ACCOUNT_OBJECT.objectApiName;
    });

    getPicklistValues.emit(installmentPeriodPicklistValues, config => {
        return config.fieldApiName.fieldApiName === FIELD_INSTALLMENT_PERIOD.fieldApiName;
    });

    getPicklistValues.emit(dayOfMonthPicklistValues, config => {
        return config.fieldApiName.fieldApiName === FIELD_DAY_OF_MONTH.fieldApiName;
    });

    await flushPromises();
}


class RD2FormController {
    element;

    constructor(element) {
        this.element = element;
    }

    setupSubmitMock() {
        const element = this.element.shadowRoot.querySelector('[data-id="outerRecordEditForm"]');
        element.submit = mockRecordEditFormSubmit;
    }

    setDefaultInputFieldValues() {
        this.recurringType().changeValue('Open');
        this.dateEstablished().changeValue('2021-02-03');
        this.startDate().changeValue('2021-02-03');
        this.dayOfMonth().setValue('6');
    }

    setDefaultInputFieldValuesEdit() {
        this.setDefaultInputFieldValues();
        this.status().setValue('Active');
        this.amount().setValue(0.50);
        this.contactLookup().setValue('001fakeContactId');
    }

    donorSection() {
        return this.element.shadowRoot.querySelector('c-rd2-entry-form-donor-section');
    }

    scheduleSection() {
        return this.element.shadowRoot.querySelector('c-rd2-entry-form-schedule-section');
    }

    elevateWidget() {
        return this.element.shadowRoot.querySelector('c-rd2-elevate-credit-card-form');
    }

    amount() {
        const field = this.element.shadowRoot.querySelector('lightning-input-field[data-id="amountField"]');
        return new RD2FormField(field);
    }

    dateEstablished() {
        const donorSection = this.donorSection();
        const field = donorSection.shadowRoot.querySelector('lightning-input-field[data-id="dateEstablished"]');
        return new RD2FormField(field);
    }

    donorType() {
        const donorSection = this.donorSection();
        const field = donorSection.shadowRoot.querySelector('lightning-combobox[data-id="donorType"]');
        return new RD2FormField(field);
    }

    contactLookup() {
        const donorSection = this.donorSection();
        const field = donorSection.shadowRoot.querySelector('lightning-input-field[data-id="contactLookup"]');
        return new RD2FormField(field);
    }

    accountLookup() {
        const donorSection = this.donorSection();
        const field = donorSection.shadowRoot.querySelector('lightning-input-field[data-id="accountLookup"]');
        return new RD2FormField(field);
    }

    paymentMethod() {
        const field = this.element.shadowRoot.querySelector('lightning-input-field[data-id="paymentMethod"]');
        return new RD2FormField(field);
    }

    last4() {
        const widget = this.elevateWidget();
        return widget.shadowRoot.querySelector('lightning-formatted-text[data-qa-locator="text Last Four Digits"]');
    }

    cardExpriation() {
        const widget = this.elevateWidget();
        return widget.shadowRoot.querySelector('lightning-formatted-text[data-qa-locator="text Expiration Date"]');
    }

    dayOfMonth() {
        const scheduleSection = this.scheduleSection();
        const field = scheduleSection.shadowRoot.querySelector('lightning-input-field[data-id="dayOfMonth"]');
        return new RD2FormField(field);
    }

    recurringType() {
        const scheduleSection = this.scheduleSection();
        const field = scheduleSection.shadowRoot.querySelector('lightning-input-field[data-id="RecurringType__c"]');
        return new RD2FormField(field);
    }

    startDate() {
        const scheduleSection = this.scheduleSection();
        const field = scheduleSection.shadowRoot.querySelector('lightning-input-field[data-id="startDate"]');
        return new RD2FormField(field);
    }

    status() {
        const field = this.element.shadowRoot.querySelector('lightning-input-field[data-id="status"]');
        return new RD2FormField(field);
    }

    cardholderName() {
        const field = this.elevateWidget().shadowRoot.querySelector('[data-id="cardholderName"]');
        return new RD2FormField(field);
    }

    saveButton() {
        return this.element.shadowRoot.querySelector('lightning-button[data-id="submitButton"]');
    }

    disableElevateButton() {
        return this.elevateWidget().shadowRoot.querySelector('lightning-button[data-qa-locator="button Do Not Use Elevate"]');
    }

    updatePaymentButton() {
        return this.elevateWidget().shadowRoot.querySelector('lightning-button[data-qa-locator="button Update Payment Information"]');
    }

    cancelUpdatePaymentButton() {
        return this.elevateWidget().shadowRoot.querySelector('lightning-button[data-qa-locator="button Cancel Update Payment Information"]');
    }

}

class RD2FormField {

    constructor(element) {
        this.element = element;
    }

    setValue(value) {
        this.element.value = value;
    }

    changeValue(value) {
        this.setValue(value);
        this.dispatchChangeEvent();
    }

    dispatchChangeEvent() {
        const { value } = this.element;
        this.element.dispatchEvent(new CustomEvent('change', { detail: { value } }));
    }
}