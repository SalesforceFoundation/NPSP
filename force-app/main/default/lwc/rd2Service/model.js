import {
    SET_CONTACT_ID,
    SET_ACCOUNT_ID,
    SET_CONTACT_DETAILS,
    SET_ACCOUNT_DETAILS,
    SET_DAY_OF_MONTH,
    SET_DONATION_AMOUNT,
    SET_DONOR_TYPE,
    SET_DATE_ESTABLISHED,
    SET_PERIOD_TYPE,
    SET_START_DATE,
    SET_RECURRING_TYPE,
    SET_RECURRING_PERIOD,
    SET_RECURRING_FREQUENCY,
    SET_PLANNED_INSTALLMENTS,
    INITIAL_VIEW_LOAD
} from "./actions";

import { PERIOD, RECURRING_PERIOD_ADVANCED, RECURRING_TYPE_FIXED, RECURRING_TYPE_OPEN } from "c/rd2Service";

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
    recurringPeriod: null, // Monthly / Yearly / 1st and 15th. When periodType is Monthly, recurringPeriod is Monthly.
    periodType: null, // Monthly or Advanced
    recurringFrequency: null, // Every *2* Months
    startDate: null,
    dayOfMonth: null, // 1, 2, 3 ... "LAST_DAY"
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
    defaultInstallmentPeriod: null, // new!

    //Permissions
    InstallmentPeriodPermissions: {},
    InstallmentFrequencyPermissions: {}
};

const getAnnualValue = (state) => {
    const amount = state.donationValue;
    const frequency = state.recurringFrequency;
    const period = state.recurringPeriod;
    const yearlyFrequency = state.periodToYearlyFrequencyMap[period];
    return amount * (yearlyFrequency / frequency);
};

const getFixedValue = (state) => {
    const amount = state.donationValue;
    const paidAmount = 0; // TODO: populate in model
    const paidInstallments = 0; // TODO: populate in model
    const numberOfInstallments = state.plannedInstallments;
    const remainingInstallments = numberOfInstallments - paidInstallments;
    return paidAmount + (remainingInstallments * amount);
};

const getDonationValue = (state) => {
    if (state.recurringType === RECURRING_TYPE_OPEN) {
        return getAnnualValue(state);
    } else if (state.recurringType === RECURRING_TYPE_FIXED) {
        return getFixedValue(state);
    }
}

const isAdvancedPeriod = (state) => {
    return state.recurringPeriod !== PERIOD.MONTHLY
        || state.recurringFrequency > 1;
};

const setAccountId = (state, accountId) => {
    return {
        ...state,
        accountId
    };
};

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

const setDonationAmount = (state, donationValue) => {
    return {
        ...state,
        donationValue
    };
};

const setDonorType = (state, donorType) => {
    return {
        ...state,
        donorType,
        accountId: null,
        contactId: null
    };
};

const setStartDate = (state, startDate) => {
    return {
        ...state,
        startDate
    };
};

const setPeriodType = (state, periodType) => {
    const isMonthly = periodType === PERIOD.MONTHLY;
    return {
        ...state,
        periodType,
        recurringPeriod: isMonthly ? PERIOD.MONTHLY : state.recurringPeriod
    };
};

const setPlannedInstallments = (state, plannedInstallments) => {
    return {
        ...state,
        plannedInstallments
    };
};

const setRecurringPeriod = (state, recurringPeriod) => {
    return {
        ...state,
        recurringPeriod
    };
};

const setRecurringFrequency = (state, recurringFrequency) => {
    return {
        ...state,
        recurringFrequency
    };
};

const setRecurringType = (state, recurringType) => {
    return {
        ...state,
        recurringType
    };
};

const setDayOfMonth = (state, dayOfMonth) => {
    return {
        ...state,
        dayOfMonth
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
    const flattenedInitialState = { ...record, ...rest };
    if (isAdvancedPeriod(flattenedInitialState)) {
        flattenedInitialState.periodType = RECURRING_PERIOD_ADVANCED;
    } else {
        flattenedInitialState.periodType = PERIOD.MONTHLY;
    }
    return {
        ...state,
        ...flattenedInitialState
    };
};

export const nextState = (state = DEFAULT_INITIAL_STATE, action = {}) => {
    console.log(JSON.parse(JSON.stringify({state, action})));
    switch (action.type) {
        case SET_CONTACT_ID:
            return setContactId(state, action.payload);
        case SET_ACCOUNT_ID:
            return setAccountId(state, action.payload);
        case SET_CONTACT_DETAILS:
            return setContactDetails(state, action.payload);
        case SET_ACCOUNT_DETAILS:
            return setAccountDetails(state, action.payload);
        case SET_DAY_OF_MONTH:
            return setDayOfMonth(state, action.payload);
        case SET_DONATION_AMOUNT:
            return setDonationAmount(state, action.payload);
        case SET_DONOR_TYPE:
            return setDonorType(state, action.payload);
        case SET_DATE_ESTABLISHED:
            return setDateEstablished(state, action.payload);
        case SET_PLANNED_INSTALLMENTS:
            return setPlannedInstallments(state, action.payload);
        case SET_RECURRING_PERIOD:
            return setRecurringPeriod(state, action.payload);
        case SET_RECURRING_FREQUENCY:
            return setRecurringFrequency(state, action.payload);
        case SET_RECURRING_TYPE:
            return setRecurringType(state, action.payload);
        case SET_PERIOD_TYPE:
            return setPeriodType(state, action.payload);
        case SET_START_DATE:
            return setStartDate(state, action.payload);
        case INITIAL_VIEW_LOAD:
            return loadInitialView(state, action.payload);
        default:
            return state;
    }
}