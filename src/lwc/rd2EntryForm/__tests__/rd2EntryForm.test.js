import { createElement } from 'lwc';
import Rd2EntryForm from 'c/rd2EntryForm';
import { mockGetInputFieldValue } from "lightning/inputField";
import getRecurringSettings from '@salesforce/apex/RD2_EntryFormController.getRecurringSettings';
import hasRequiredFieldPermissions from '@salesforce/apex/RD2_EntryFormController.hasRequiredFieldPermissions';
import RD2_EntryFormMissingPermissions from '@salesforce/label/c.RD2_EntryFormMissingPermissions';
import FIELD_INSTALLMENT_PERIOD from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installment_Period__c';
import FIELD_DAY_OF_MONTH from '@salesforce/schema/npe03__Recurring_Donation__c.Day_of_Month__c';
import FIELD_RECURRING_TYPE from '@salesforce/schema/npe03__Recurring_Donation__c.RecurringType__c';

import RECURRING_DONATION_OBJECT from '@salesforce/schema/npe03__Recurring_Donation__c';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import CONTACT_OBJECT from '@salesforce/schema/Contact';
import {getObjectInfo, getPicklistValues} from 'lightning/uiObjectInfoApi';
const recurringSettingsResponse = require('./data/getRecurringSettings.json');
const recurringDonationObjectInfo = require('./data/recurringDonationObjectInfo.json');
const installmentPeriodPicklistValues = require('./data/installmentPeriodPicklistValues.json');
const dayOfMonthPicklistValues = require('./data/dayOfMonthPicklistValues.json');
const contactPartialDescribe = require('./data/contactPartialDescribe.json');
const accountPartialDescribe = require('./data/accountPartialDescribe.json');

const mockScrollIntoView = jest.fn();

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


describe('c-rd2-entry-form', () => {

    beforeEach(() => {
        getRecurringSettings.mockResolvedValue(recurringSettingsResponse);
        hasRequiredFieldPermissions.mockResolvedValue(true);
        window.HTMLElement.prototype.scrollIntoView = mockScrollIntoView;
    });

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    })

    it('displays an error when user does not have required permissions', async () => {
        hasRequiredFieldPermissions.mockResolvedValue(false);
        const element = createElement('c-rd2-entry-form', { is: Rd2EntryForm })
        document.body.appendChild(element);

        await flushPromises();

        expect(mockScrollIntoView).toHaveBeenCalledTimes(1);

        const saveButton = selectSaveButton(element);
        expect(saveButton.disabled).toBe(true);

        const formattedText = element.shadowRoot.querySelector('lightning-formatted-text');
        expect(formattedText.value).toBe(RD2_EntryFormMissingPermissions);
    });

    it('elevate customer selects Credit Card payment method then widget displayed', async () => {
        const element = createElement('c-rd2-entry-form', { is: Rd2EntryForm });
        document.body.appendChild(element);

        mockGetInputFieldValue.mockImplementation(field => {
            return field.fieldName === FIELD_RECURRING_TYPE.fieldApiName ? 'Open' : field._value;
        });

        await flushPromises();

        await setupWireMocksForElevate();

        const paymentMethodField = selectPaymentMethodField(element);

        dispatchChangeEvent(paymentMethodField, 'Credit Card');

        await flushPromises();

        const elevateWidget = selectElevateWidget(element);
        expect(elevateWidget).toBeTruthy();

    });

    it('elevate customer selects ACH payment method then widget displayed', async () => {
        const element = createElement('c-rd2-entry-form', { is: Rd2EntryForm });
        document.body.appendChild(element);

        mockGetInputFieldValue.mockImplementation(field => {
            return field.fieldName === FIELD_RECURRING_TYPE.fieldApiName ? 'Open' : field._value;
        });

        await flushPromises();

        await setupWireMocksForElevate();

        const paymentMethodField = selectPaymentMethodField(element);

        dispatchChangeEvent(paymentMethodField, 'ACH');

        await flushPromises();

        const elevateWidget = selectElevateWidget(element);
        expect(elevateWidget).toBeTruthy();
    });



});

const selectSaveButton = (element) => {
    return element.shadowRoot.querySelector('lightning-button[data-id="submitButton"]');
}

const selectPaymentMethodField = (element) => {
    return element.shadowRoot.querySelector('lightning-input-field[data-id="paymentMethod"]');
}

const selectScheduleSection = (element) => {
    return element.shadowRoot.querySelector('c-rd2-entry-form-schedule-section');
}

const selectElevateWidget = (element) => {
    return element.shadowRoot.querySelector('c-rd2-elevate-credit-card-form');
}

const dispatchChangeEvent = (element, value) => {
    element.dispatchEvent(new CustomEvent('change', { detail: { value } }));
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