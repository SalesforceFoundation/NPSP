import {
    SET_CONTACT_ID,
    SET_ACCOUNT_ID,
    SET_CAMPAIGN_ID,
    SET_CONTACT_DETAILS,
    SET_CURRENCY,
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
    SET_PAYMENT_METHOD,
    SET_PLANNED_INSTALLMENTS,
    INITIAL_VIEW_LOAD,
} from "./actions";

import {
    PERIOD,
    RECURRING_PERIOD_ADVANCED,
    RECURRING_TYPE_FIXED,
    RECURRING_TYPE_OPEN,
    CHANGE_TYPE_UPGRADE,
    CHANGE_TYPE_DOWNGRADE,
    CONTACT_DONOR_TYPE,
} from "./constants";

const DEFAULT_INITIAL_STATE = {
    initialViewState: {}, // snapshot of initial view state after first load

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
    donorType: CONTACT_DONOR_TYPE,
    dateEstablished: null,
    mailingCountry: null,

    //schedule
    donationValue: null,
    currency: null,
    recurringPeriod: null, // Monthly / Yearly / 1st and 15th. When periodType is Monthly, recurringPeriod is Monthly.
    periodType: null, // Monthly or Advanced
    recurringFrequency: 1, // Every *X* Months
    startDate: null,
    dayOfMonth: null, // 1, 2, 3 ... "LAST_DAY"
    plannedInstallments: null, // Only used for "Fixed" RDs.
    recurringType: null, // Fixed or Open
    paidAmount: null, // Fixed Only, used to calculate change type
    paidInstallments: null, // Fixed Only, used to calculate change type

    //change type
    changeType: "",

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
    isMultiCurrencyEnabled: false,
    isElevateCustomer: null,
    isChangeLogEnabled: null,
    periodToYearlyFrequencyMap: null,
    closedStatusValues: [],
    defaultInstallmentPeriod: null, // new!

    //Permissions
    InstallmentPeriodPermissions: {},
    InstallmentFrequencyPermissions: {},
};

const isRecurringTypeChanged = (state) => {
    return state.recurringType !== state.initialViewState.recurringType;
};

const isNewRecord = (state) => {
    return !state.recordId;
};

const getAnnualValue = (state) => {
    const { donationValue, recurringFrequency, recurringPeriod, periodToYearlyFrequencyMap } = state;
    const yearlyFrequency = periodToYearlyFrequencyMap[recurringPeriod];

    return donationValue * (yearlyFrequency / recurringFrequency);
};

const getFixedValue = (state) => {
    const { donationValue, paidAmount, paidInstallments, plannedInstallments } = state;
    const remainingInstallments = plannedInstallments - paidInstallments;

    return paidAmount + remainingInstallments * donationValue;
};

const getDonationValue = (state) => {
    if (state.recurringType === RECURRING_TYPE_OPEN) {
        return getAnnualValue(state);
    } else if (state.recurringType === RECURRING_TYPE_FIXED) {
        return getFixedValue(state);
    }
};

const getChangeType = (state) => {
    if (isRecurringTypeChanged(state) || isNewRecord(state)) {
        return "";
    }

    const oldValue = getDonationValue(state.initialViewState);
    const newValue = getDonationValue(state);

    if (oldValue > newValue) {
        return CHANGE_TYPE_DOWNGRADE;
    } else if (newValue > oldValue) {
        return CHANGE_TYPE_UPGRADE;
    }

    return "";
};

const isAdvancedPeriod = (state) => {
    return state.recurringPeriod !== PERIOD.MONTHLY || state.recurringFrequency > 1;
};

const setAccountId = (state, accountId) => {
    return {
        ...state,
        accountId,
    };
};

const setContactId = (state, contactId) => {
    return {
        ...state,
        contactId,
    };
};

const setContactDetails = (state, { firstName, lastName, mailingCountry }) => {
    return {
        ...state,
        contactFirstName: firstName,
        contactLastName: lastName,
        contactMailingCountry: mailingCountry,
    };
};

const setCurrency = (state, currencyIsoCode) => {
    return {
        ...state,
        currencyIsoCode,
    };
};

const setAccountDetails = (state, { accountName, lastName }) => {
    return {
        ...state,
        accountName,
        contactLastName: lastName,
    };
};

const setDonationAmount = (state, donationValue) => {
    const newState = { ...state, donationValue };
    return {
        ...newState,
        changeType: getChangeType(newState),
    };
};

const setDonorType = (state, donorType) => {
    return {
        ...state,
        donorType,
    };
};

const setStartDate = (state, startDate) => {
    return {
        ...state,
        startDate,
    };
};

const setPeriodType = (state, periodType) => {
    const isMonthly = periodType === PERIOD.MONTHLY;
    const newState = {
        ...state,
        periodType,
        recurringPeriod: isMonthly ? PERIOD.MONTHLY : state.recurringPeriod,
    };
    return {
        ...newState,
        changeType: getChangeType(newState),
    };
};

const setPlannedInstallments = (state, plannedInstallments) => {
    const newState = {
        ...state,
        plannedInstallments,
    };
    return {
        ...newState,
        changeType: getChangeType(newState),
    };
};

const setRecurringPeriod = (state, recurringPeriod) => {
    const newState = {
        ...state,
        recurringPeriod,
    };

    return {
        ...newState,
        changeType: getChangeType(newState),
    };
};

const setRecurringFrequency = (state, recurringFrequency) => {
    const newState = {
        ...state,
        recurringFrequency,
    };
    return {
        ...newState,
        changeType: getChangeType(newState),
    };
};

const setRecurringType = (state, recurringType) => {
    const newState = {
        ...state,
        recurringType,
    };
    return {
        ...newState,
        changeType: getChangeType(newState),
    };
};

const setDayOfMonth = (state, dayOfMonth) => {
    return {
        ...state,
        dayOfMonth,
    };
};

const setDateEstablished = (state, dateEstablished) => {
    return {
        ...state,
        dateEstablished,
    };
};

const setPaymentMethod = (state, paymentMethod) => {
    return {
        ...state,
        paymentMethod
    };
};

const setCampaignId = (state, campaignId) => {
    return {
        ...state,
        campaignId
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

    const initialViewState = {
        ...state,
        ...flattenedInitialState,
    };

    return {
        ...initialViewState,
        initialViewState
    };
};

export const nextState = (state = DEFAULT_INITIAL_STATE, action = {}) => {
    switch (action.type) {
        case SET_CONTACT_ID:
            return setContactId(state, action.payload);
        case SET_ACCOUNT_ID:
            return setAccountId(state, action.payload);
        case SET_CONTACT_DETAILS:
            return setContactDetails(state, action.payload);
        case SET_CURRENCY:
            return setCurrency(state, action.payload);
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
        case SET_CAMPAIGN_ID:
            return setCampaignId(state, action.payload);
        case SET_PAYMENT_METHOD:
            return setPaymentMethod(state, action.payload);
        case INITIAL_VIEW_LOAD:
            return loadInitialView(state, action.payload);
        default:
            return state;
    }
};
