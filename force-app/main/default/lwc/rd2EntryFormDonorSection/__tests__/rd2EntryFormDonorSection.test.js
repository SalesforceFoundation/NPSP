import { createElement } from "lwc";
import Rd2EntryFormDonorSection from "c/rd2EntryFormDonorSection";
import { Rd2Service } from "c/rd2Service";
import { getObjectInfo } from "lightning/uiObjectInfoApi";

import getInitialView from "@salesforce/apex/RD2_EntryFormController.getInitialView";
import RECURRING_DONATION_OBJECT from "@salesforce/schema/npe03__Recurring_Donation__c";
import { SET_DONOR_TYPE } from "../../rd2Service/actions";


const recurringDonationObjectInfo = require("../../../../../../tests/__mocks__/apex/data/recurringDonationObjectInfo.json");
const initialViewResponse = require("../../../../../../tests/__mocks__/apex/data/getInitialView.json");
const rd2WithCardCommitmentInitialView = require("../../rd2EntryForm/__tests__/data/rd2WithCardCommitmentInitialView.json");

const mockHandleContactChange = jest.fn();
const mockHandleAccountChange = jest.fn();
const mockHandleDonorTypeChange = jest.fn();
const mockHandleDateEstablishedChange = jest.fn();

const FAKE_RD_ID = "fake-rd-record-id";
const FAKE_ACCOUNT_ID = "fake-account-record-id";
const UPDATED_FAKE_ACCOUNT_ID = "updated-fake-account-record-id";
const FAKE_CONTACT_ID = "fake-contact-record-id";
const UPDATED_FAKE_CONTACT_ID = "updated-fake-contact-record-id";

jest.mock("@salesforce/apex/RD2_EntryFormController.getInitialView",
    () => ({ default: jest.fn() }),
    { virtual: true });

const assertDonorTypeFieldValue = (element, expectedValue) => {
    const donorTypeField = getDonorTypeField(element);
    expect(donorTypeField).toBeTruthy();
    expect(donorTypeField.options).toContainOptions(["Contact", "Account"]);
    expect(donorTypeField.value).toBe(expectedValue);
};

describe("new recurring donation", () => {
    let element;

    beforeEach(async () => {
        element = await createDonorSection();
        getObjectInfo.emit(recurringDonationObjectInfo, ({ objectApiName }) => {
            return objectApiName === RECURRING_DONATION_OBJECT.objectApiName;
        });
        await flushPromises();
    });

    afterEach(() => {
        jest.clearAllMocks();
        clearDOM();
    });

    it("donor type picklist defaults to Contact", () => {
        assertDonorTypeFieldValue(element, "Contact");
    });


    it("when set to Account, then account lookup appears", async () => {
        const rd2Service = new Rd2Service();
        const donorTypeField = getDonorTypeField(element);
        const newDonorType = "Account";
        donorTypeField.value = newDonorType;
        donorTypeField.dispatchEvent(new CustomEvent("change", { detail: { value: newDonorType } }));

        // simulate rd2EntryForm's handling of a donor type change to update rd2State
        element.rd2State = rd2Service.dispatch(element.rd2State, { type: SET_DONOR_TYPE, payload: newDonorType });

        await flushPromises();
        const lastEventDetail = getLastEventDetail(mockHandleDonorTypeChange);

        expect(lastEventDetail).toBe(newDonorType);

        const accountLookup = getAccountLookup(element);
        expect(accountLookup).toBeTruthy();
    });

});

describe("existing recurring contact donation", () => {
    let element;

    beforeEach(async () => {
        element = await createDonorSection({ recordId: FAKE_RD_ID });
        getObjectInfo.emit(recurringDonationObjectInfo, ({ objectApiName }) => {
            return objectApiName === RECURRING_DONATION_OBJECT.objectApiName;
        });
        await flushPromises();
    });

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    it("loads with donor type set to contact", () => {
        assertDonorTypeFieldValue(element, "Contact");
    });

    it("notifies parent component of donor type change", () => {
        changeDonorType(element, "Account");
        expect(mockHandleDonorTypeChange).toHaveBeenCalled();
        const lastEventDetail = getLastEventDetail(mockHandleDonorTypeChange);
        expect(lastEventDetail).toBe("Account");
    });
});


describe("existing recurring account donation", () => {
    let element;

    beforeEach(async () => {
        const initialViewWithAccountDonor = {
            ...rd2WithCardCommitmentInitialView,
            record: {
                ...rd2WithCardCommitmentInitialView.record,
                donorType: 'Account'
            }
        };


        element = await createDonorSection({ recordId: FAKE_RD_ID }, initialViewWithAccountDonor);

        getObjectInfo.emit(recurringDonationObjectInfo, ({ objectApiName }) => {
            return objectApiName === RECURRING_DONATION_OBJECT.objectApiName;
        });

        await flushPromises();
    });

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    it("loads with donor type set to Account", () => {
        assertDonorTypeFieldValue(element, "Account");
    });

    it("lookup values are not cleared when donor type is changed", async () => {
        const rd2Service = new Rd2Service();
        changeDonorType(element, "Contact");

        // simulate rd2EntryForm handling donor type change
        const rd2StateContact = rd2Service.dispatch(element.rd2State, { type: SET_DONOR_TYPE, payload: "Contact"});
        element.rd2State = rd2StateContact;

        assertDonorTypeFieldValue(element, "Contact");

        await flushPromises();

        expect(getAccountLookup(element)).toBeNull();

        changeDonorType(element, "Account");
        // simulate rd2EntryForm handling donor type change
        const rd2StateAccount = rd2Service.dispatch(element.rd2State, { type: SET_DONOR_TYPE, payload: "Account"});
        element.rd2State = rd2StateAccount;

        await flushPromises();

        const accountLookup = getAccountLookup(element);
        expect(accountLookup).toBeTruthy();
        expect(accountLookup.value).toBe("001fakeAccountId");
    });
});

describe("new donation from account", () => {
    let element;

    beforeEach(async () => {
        const initialViewFromAccount = {
            ...initialViewResponse,
            parentSObjectType: 'Account',
            contactId: null,
            accountId: FAKE_ACCOUNT_ID
        };


        element = await createDonorSection({ parentId: FAKE_ACCOUNT_ID, parentSObjectType: "Account" }, initialViewFromAccount);

        getObjectInfo.emit(recurringDonationObjectInfo, ({ objectApiName }) => {
            return objectApiName === RECURRING_DONATION_OBJECT.objectApiName;
        });

        await flushPromises();
    });

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    it("alerts parent component of accountId", async () => {
        const accountLookup = getAccountLookup(element);
        expect(accountLookup.value).toBe(FAKE_ACCOUNT_ID);
        accountLookup.value = UPDATED_FAKE_ACCOUNT_ID;
        changeField(accountLookup, accountLookup.value);
        await flushPromises();

        const lastEventDetail = getLastEventDetail(mockHandleAccountChange);
        expect(lastEventDetail).toBe(UPDATED_FAKE_ACCOUNT_ID);
    });

    it("populates account lookup", () => {
        const accountLookup = getAccountLookup(element);
        expect(accountLookup).toBeTruthy();
        expect(accountLookup.value).toBe(FAKE_ACCOUNT_ID);
    });

    it( "sets donor type to account", () => {
        const donorType = getDonorTypeField(element);
        expect(donorType).toBeTruthy();
        expect(donorType.value).toBe("Account");
    });

    it("clears account lookup on donor type change", async () => {
        const rd2Service = new Rd2Service();

        changeDonorType(element, "Contact");

        const rd2StateContact = rd2Service.dispatch(element.rd2State, { type: SET_DONOR_TYPE, payload: "Contact"});
        element.rd2State = rd2StateContact;

        await flushPromises();
        const accountLookup = getAccountLookup(element);
        expect(accountLookup).toBeNull();

        const contactLookup = getContactLookup(element);
        expect(contactLookup).toBeTruthy();
    });
});


describe("new donation from contact", () => {
    let element;

    beforeEach(async () => {

        element = await createDonorSection({ parentId: FAKE_CONTACT_ID, parentSObjectType: "Contact" });

        getObjectInfo.emit(recurringDonationObjectInfo, ({ objectApiName }) => {
            return objectApiName === RECURRING_DONATION_OBJECT.objectApiName;
        });

        await flushPromises();
    });

    afterEach(() => {
        jest.clearAllMocks();
        clearDOM();
    });

    it("alerts parent component of changes to contact lookup", () => {
        const contactLookup = getContactLookup(element);
        changeField(contactLookup, UPDATED_FAKE_CONTACT_ID);

        const lastEventDetail = getLastEventDetail(mockHandleContactChange);
        expect(lastEventDetail).toBe(UPDATED_FAKE_CONTACT_ID);
    });

    it("alerts parent component of date established changes", () => {
        const dateEstablished = getDateEstablishedField(element);
        expect(dateEstablished).toBeTruthy();
        const fakeDate = new Date(2022, 0, 14)
        changeField(dateEstablished, fakeDate);
        const lastEventDetail = getLastEventDetail(mockHandleDateEstablishedChange);

        expect(lastEventDetail).toBe(fakeDate);
    });

    it("populates contact lookup", () => {
        const contactLookup = getContactLookup(element);
        expect(contactLookup).toBeTruthy();
        expect(element.rd2State.contactId).toBe(FAKE_CONTACT_ID);
        expect(contactLookup.value).toBe(FAKE_CONTACT_ID);
    });

    it("when donor type changed to account, contact lookup cleared", async () => {
        changeDonorType(element, "Account");
        const rd2Service = new Rd2Service();
        const rd2State = rd2Service.dispatch(element.rd2State, { type: SET_DONOR_TYPE, payload: "Account"});
        element.rd2State = rd2State;

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
};

const changeDonorType = (element, value) => {
    const field = getDonorTypeField(element);
    changeField(field, value);
}

const changeField = (field, value) => {
    field.value = value;
    field.dispatchEvent(new CustomEvent("change", { detail: { value } }));
};

const getDonorTypeField = (element) => {
    return element.shadowRoot.querySelector("lightning-combobox[data-id=\"donorType\"]");
};

const getAccountLookup = (element) => {
    return element.shadowRoot.querySelector("lightning-input-field[data-id=\"accountLookup\"]");
};

const getContactLookup = (element) => {
    return element.shadowRoot.querySelector("lightning-input-field[data-id=\"contactLookup\"]");
};

const getDateEstablishedField = (element) => {
    return element.shadowRoot.querySelector("lightning-input-field[data-id=\"dateEstablished\"]");
}

const createDonorSection = async (params, mockInitialView = initialViewResponse) => {
    getInitialView.mockResolvedValue(mockInitialView);
    const donorSection = createElement("c-rd2-entry-form-donor-section", { is: Rd2EntryFormDonorSection });
    const rd2Service = new Rd2Service();
    const rd2State = await rd2Service.loadInitialView(rd2Service.init(), FAKE_RD_ID, FAKE_CONTACT_ID);

    if (params) {
        const { recordId, parentId, parentSObjectType } = params;
        rd2State.recordId = recordId;
        if (parentId) {
            rd2State.parentId = parentId;
        }
        if (parentSObjectType) {
            rd2State.donorType = parentSObjectType;
        }
    }
    donorSection.rd2State = rd2State;
    donorSection.addEventListener("donortypechange", mockHandleDonorTypeChange);
    donorSection.addEventListener("accountchange", mockHandleAccountChange);
    donorSection.addEventListener("contactchange", mockHandleContactChange);
    donorSection.addEventListener("dateestablishedchange", mockHandleDateEstablishedChange);

    document.body.appendChild(donorSection);
    return donorSection;
};