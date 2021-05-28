import { createElement } from "lwc";
import Rd2EntryFormDonorSection from 'c/rd2EntryFormDonorSection';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

import getRecurringData from '@salesforce/apex/RD2_EntryFormController.getRecurringData';
import RECURRING_DONATION_OBJECT from '@salesforce/schema/npe03__Recurring_Donation__c';


const recurringDataAccountResponse = require('./data/recurringDataAccountResponse.json');
const recurringDataContactResponse = require('./data/recurringDataContactResponse.json');
const recurringDonationObjectInfo = require('./data/recurringDonationObjectInfo.json');

const mockHandleContactChange = jest.fn();
const mockHandleAccountChange = jest.fn();
const mockHandleDonorTypeChange = jest.fn();

const FAKE_RD_ID = 'fake-rd-record-id';
const FAKE_ACCOUNT_ID = 'fake-account-record-id';
const FAKE_CONTACT_ID = 'fake-contact-record-id';

const assertDonorTypeFieldValue = (element, expectedValue) => {
    const donorTypeField = getDonorTypeField(element);
    expect(donorTypeField).toBeTruthy();
    expect(donorTypeField.options).toContainOptions(['Contact', 'Account']);
    expect(donorTypeField.value).toBe(expectedValue);
}

describe('new recurring donation', () => {
    let element;

    beforeEach(async () => {
        element = createDonorSection();
        getObjectInfo.emit(recurringDonationObjectInfo, ({objectApiName}) => {
            return objectApiName === RECURRING_DONATION_OBJECT.objectApiName
        });
        await flushPromises();
    });

    afterEach(() => {
        jest.clearAllMocks();
        clearDOM();
    });

    it('donor type picklist defaults to Contact', () => {
        assertDonorTypeFieldValue(element, 'Contact');
    });


    it('when set to Account, then account lookup appears', async () => {

        const donorTypeField = getDonorTypeField(element);
        donorTypeField.value = 'Account';
        donorTypeField.dispatchEvent(new CustomEvent('change', { detail: { value: 'Account' } }));
        await flushPromises();
        const lastEventDetail = getLastEventDetail(mockHandleDonorTypeChange);
        expect(lastEventDetail).toBe('Account');

        const accountLookup = getAccountLookup(element);
        expect(accountLookup).toBeTruthy();
    });

});

describe('existing recurring contact donation', () => {
    let element;

    beforeEach(async () => {
        getRecurringData.mockResolvedValue(recurringDataContactResponse);
        element = createDonorSection({ recordId: FAKE_RD_ID });
        getObjectInfo.emit(recurringDonationObjectInfo, ({objectApiName}) => {
            return objectApiName === RECURRING_DONATION_OBJECT.objectApiName
        });
        await flushPromises();
    });

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    })

    it('loads with donor type set to contact', () => {
        assertDonorTypeFieldValue(element, 'Contact');
    });

    it('notifies parent component of donor type change', () => {
        expect(mockHandleDonorTypeChange).toHaveBeenCalled();
        const lastEventDetail = getLastEventDetail(mockHandleDonorTypeChange);
        expect(lastEventDetail).toBe('Contact');
    });
});


describe('existing recurring account donation', () => {
    let element;

    beforeEach(async () => {
        getRecurringData.mockResolvedValue(recurringDataAccountResponse);

        element = createDonorSection({ recordId: FAKE_RD_ID });

        getObjectInfo.emit(recurringDonationObjectInfo, ({objectApiName}) => {
            return objectApiName === RECURRING_DONATION_OBJECT.objectApiName
        });

        await flushPromises();
    });

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    it('loads with donor type set to Account', () => {
        expect(getRecurringData).toHaveBeenCalled();
        assertDonorTypeFieldValue(element, 'Account');
    });

    it('clears values in Account lookup when donor type changed to Contact', async () => {
        changeDonorType(element, 'Contact');
        assertDonorTypeFieldValue(element, 'Contact');

        await flushPromises();

        expect(getAccountLookup(element)).toBeNull();

        changeDonorType(element, 'Account');
        await flushPromises();

        const accountLookup = getAccountLookup(element);
        expect(accountLookup).toBeTruthy();
        expect(accountLookup.value).toBeFalsy();
    });
});

describe('new donation from account', () => {
    let element;

    beforeEach(async () => {
        getRecurringData.mockResolvedValue(recurringDataAccountResponse);

        element = createDonorSection({ parentId: FAKE_ACCOUNT_ID, parentSObjectType: 'Account' });

        getObjectInfo.emit(recurringDonationObjectInfo, ({objectApiName}) => {
            return objectApiName === RECURRING_DONATION_OBJECT.objectApiName
        });

        await flushPromises();
    });

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    it('alerts parent component of accountId', () => {
        const lastEventDetail = getLastEventDetail(mockHandleAccountChange);
        expect(lastEventDetail).toBe(FAKE_ACCOUNT_ID);
    });

    it('populates account lookup', () => {
        const accountLookup = getAccountLookup(element);
        expect(accountLookup).toBeTruthy();
        expect(accountLookup.value).toBe(FAKE_ACCOUNT_ID);
    });

    it('clears account lookup on donor type change', async () => {
        changeDonorType(element, 'Contact');
        await flushPromises();
        const accountLookup = getAccountLookup(element);
        expect(accountLookup).toBeNull();

        const contactLookup = getContactLookup(element);
        expect(contactLookup).toBeTruthy();
    });
});


describe('new donation from contact', () => {
    let element;

    beforeEach(async () => {
        getRecurringData.mockResolvedValue(recurringDataAccountResponse);

        element = createDonorSection({ parentId: FAKE_CONTACT_ID, parentSObjectType: 'Contact' });

        getObjectInfo.emit(recurringDonationObjectInfo, ({objectApiName}) => {
            return objectApiName === RECURRING_DONATION_OBJECT.objectApiName
        });

        await flushPromises();
    });

    afterEach(() => {
        jest.clearAllMocks();
        clearDOM();
    });

    it('alerts parent component of contactId', () => {
       const lastEventDetail = getLastEventDetail(mockHandleContactChange);
       expect(lastEventDetail).toBe(FAKE_CONTACT_ID);
    });

    it('populates contact lookup', () => {
        const contactLookup = getContactLookup(element);
        expect(contactLookup).toBeTruthy();
        expect(contactLookup.value).toBe(FAKE_CONTACT_ID);
    });

    it('when donor type changed to account, contact lookup cleared', async () => {
        changeDonorType(element, 'Account');
        await flushPromises();
        const contactLookup = getContactLookup(element);

        expect(contactLookup).toBeNull();
        const accountLookup = getAccountLookup(element);
        expect(accountLookup).toBeTruthy();
    });

});

const getLastEventDetail = (mockedFn) => {
    const { calls } = mockedFn.mock;
    const lastIndex = calls.length - 1;
    return calls[lastIndex][0].detail;
}

const changeDonorType = (element, value) => {
    const field = getDonorTypeField(element);
    field.value = value;
    field.dispatchEvent(new CustomEvent('change', { detail: { value } }));
}

const getDonorTypeField = (element) => {
    return element.shadowRoot.querySelector('lightning-combobox[data-id="donorType"]');
}

const getAccountLookup = (element) => {
    return element.shadowRoot.querySelector('lightning-input-field[data-id="accountLookup"]');
}

const getContactLookup = (element) => {
    return element.shadowRoot.querySelector('lightning-input-field[data-id="contactLookup"]');
}

const createDonorSection = (params) => {
    const donorSection = createElement('c-rd2-entry-form-donor-section', { is: Rd2EntryFormDonorSection });
    if(params) {
        const { recordId, parentId, parentSObjectType } = params;
        donorSection.recordId = recordId;
        donorSection.parentId = parentId;
        donorSection.parentSObjectType = parentSObjectType;
    }
    donorSection.addEventListener('donortypechange', mockHandleDonorTypeChange);
    donorSection.addEventListener('accountchange', mockHandleAccountChange);
    donorSection.addEventListener('contactchange', mockHandleContactChange);
    document.body.appendChild(donorSection);
    return donorSection;
};