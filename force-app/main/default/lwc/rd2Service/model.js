import {
    SET_CONTACT_ID,
    SET_ACCOUNT_ID,
    SET_CONTACT_DETAILS,
    SET_ACCOUNT_DETAILS,
    SET_DONOR_TYPE,
    SET_DATE_ESTABLISHED,
    INITIAL_VIEW_LOAD
} from "./actions";

const DEFAULT_INITIAL_STATE = {
    // RD2 Record
    recordId: null,
    parentId: null,
    recurringStatus: null, // Active, Lapsed, Closed

    // donor
    contactId: null,
    contactFirstName: null,
    contactLastName: null,
    accountId: null,
    accountName: null,
    donorType: 'Contact',
    dateEstablished: null,
    mailingCountry: null,

    //schedule
    donationValue: null,
    recurringPeriod: null, // Monthly / Yearly
    recurringFrequency: null, // Every *2* Months
    startDate: null,
    dayOfMonth: null,
    plannedInstallments: null, // Only used for "Fixed" RDs.
    recurringType: null, // Fixed or Open

    //Custom Fields
    customFields: {},
    customFieldValues: {},

    //elevate iframe
    paymentToken: null,
    commitmentId: null,
    achLastFour: null,
    cardLastFour: null,
    cardExpirationMonth: null,
    cardExpirationYear: null,

    //Recurring Settings
    isAutoNamingEnabled: null,
    isMultiCurrencyEnabled: null,
    isElevateCustomer: null,
    isChangeLogEnabled: null,
    periodToYearlyFrequencyMap: null,
    closedStatusValues: [],
    defaultInstallmentPeriod: null // new!
}

const setAccountId = (state, accountId) => {
    return {
        ...state,
        accountId
    };
}

const setContactId = (state, contactId) => {
    return {
        ...state,
        contactId
    };
};

const setContactDetails = (state, {firstName, lastName, mailingCountry}) => {
    return {
        ...state,
        contactFirstName: firstName,
        contactLastName: lastName,
        contactMailingCountry: mailingCountry
    };
};

const setAccountDetails = (state, {accountName, lastName}) => {
    return {
        ...state,
        accountName,
        contactLastName: lastName,
    };
};

const setDonorType = (state, donorType) => {
    return {
        ...state,
        donorType
    };
};

const setDateEstablished = (state, dateEstablished) => {
    return {
        ...state,
        dateEstablished
    };
};

const loadInitialView = (state, payload) => {
    const { record, ...rest } = payload;
    return {
        ...state,
        ...record,
        ...rest
    };
}

export const nextState = (state = DEFAULT_INITIAL_STATE, action = {}) => {
    switch (action.type) {
        case SET_CONTACT_ID:
            return setContactId(state, action.payload);
        case SET_ACCOUNT_ID:
            return setAccountId(state, action.payload);
        case SET_CONTACT_DETAILS:
            return setContactDetails(state, action.payload);
        case SET_ACCOUNT_DETAILS:
            return setAccountDetails(state, action.payload);
        case SET_DONOR_TYPE:
            return setDonorType(state, action.payload);
        case SET_DATE_ESTABLISHED:
            return setDateEstablished(state, action.payload);
        case INITIAL_VIEW_LOAD:
            return loadInitialView(state, action.payload);
        default:
            return state;
    }
}