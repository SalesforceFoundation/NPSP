import { format, isNull } from "c/utilCommon";
import { nextState } from "./model";
import * as ACTIONS from "./actions";
import {
    ACCOUNT_DONOR_TYPE,
    CHANGE_TYPE_UPGRADE,
    CONTACT_DONOR_TYPE,
    CHANGE_TYPE_DOWNGRADE,
    ELEVATE_SUPPORTED_CURRENCIES,
    ELEVATE_SUPPORTED_COUNTRIES,
    PERIOD,
    RECURRING_PERIOD_ADVANCED,
    RECURRING_TYPE_OPEN,
    RECURRING_TYPE_FIXED,
} from "./constants.js";
import CURRENCY from "@salesforce/i18n/currency";

import getInitialView from "@salesforce/apex/RD2_EntryFormController.getInitialView";
import saveRecurringDonation from "@salesforce/apex/RD2_EntryFormController.saveRecurringDonation";

import FIELD_ID from "@salesforce/schema/npe03__Recurring_Donation__c.Id";
import FIELD_ACH_LAST4 from "@salesforce/schema/npe03__Recurring_Donation__c.ACH_Last_4__c";
import FIELD_INSTALLMENT_FREQUENCY from "@salesforce/schema/npe03__Recurring_Donation__c.InstallmentFrequency__c";
import FIELD_COMMITMENT_ID from "@salesforce/schema/npe03__Recurring_Donation__c.CommitmentId__c";
import FIELD_CARD_LAST4 from "@salesforce/schema/npe03__Recurring_Donation__c.CardLast4__c";
import FIELD_CARD_EXPIRY_MONTH from "@salesforce/schema/npe03__Recurring_Donation__c.CardExpirationMonth__c";
import FIELD_CARD_EXPIRY_YEAR from "@salesforce/schema/npe03__Recurring_Donation__c.CardExpirationYear__c";
import FIELD_PAYMENT_METHOD from "@salesforce/schema/npe03__Recurring_Donation__c.PaymentMethod__c";
import FIELD_CONTACT_ID from "@salesforce/schema/npe03__Recurring_Donation__c.npe03__Contact__c";
import FIELD_ORGANIZATION_ID from "@salesforce/schema/npe03__Recurring_Donation__c.npe03__Organization__c";
import validatingCardMessage from "@salesforce/label/c.RD2_EntryFormSaveCreditCardValidationMessage";
import validatingACHMessage from "@salesforce/label/c.RD2_EntryFormSaveACHMessage";
import { PAYMENT_METHOD_ACH, PAYMENT_METHOD_CREDIT_CARD } from "c/geConstants";

const ELEVATE_PAYMENT_METHODS = [PAYMENT_METHOD_ACH, PAYMENT_METHOD_CREDIT_CARD];

class Rd2Service {
    dispatch(state, action) {
        return nextState(state, action);
    }

    init() {
        return this.dispatch();
    }

    async loadInitialView(state, recordId, parentId) {
        try {
            const initialView = await getInitialView({ recordId, parentId });
            const action = { type: ACTIONS.INITIAL_VIEW_LOAD, payload: initialView };
            return this.dispatch(state, action);
        } catch (ex) {
            console.log("Error: ", ex);
            return state;
        }
    }

    async save(rd2State) {
        let result;
        try {
            const saveRequest = this.getSaveRequest(rd2State);
            result = await saveRecurringDonation({ saveRequest });
        } catch (ex) {
            console.error(ex);
        }
        return result;
    }

    /***
     * @description Displays errors extracted from the error response
     * returned from the Elevate API when the Commitment cannot be created
     */
    getCommitmentError(response) {
        if (response.body) {
            // Errors returned in the response body can contain a single quote, for example:
            // "body": "{'errors':[{'message':'\"Unauthorized\"'}]}".
            // However, the JSON parser does not work with a single quote,
            // so need to replace it with the double quote but after
            // replacing \" with an empty string, otherwise the message content
            // will be misformatted.
            if (JSON.stringify(response.body).includes("'errors'")) {
                response.body = response.body.replace(/\"/g, "").replace(/\'/g, '"');
            }

            //parse the error response
            try {
                response.body = JSON.parse(response.body);
            } catch (error) {}
        }

        let errors = this.getErrors(response);

        return format("{0}", [errors]);
    }

    /***
     * @description Get the message or errors from a failed API call.
     * @param {object} response: Http response object
     * @return {string}: Message from a failed API call response
     */
    getErrors(response) {
        if (response.body && response.body.errors) {
            return response.body.errors.map((error) => error.message).join("\n ");
        }

        // For some reason the key in the body object for 'Message'
        // in the response we receive from Elevate is capitalized.
        // Also checking for lowercase M in message in case they fix it.
        return response.body.Message || response.body.message || response.errorMessage || JSON.stringify(response.body);
    }

    /***
     * @description Convert LWC RD record into recognizable form and consume the api response if exist
     */
    constructRecurringDonation(recordId, commitmentId) {
        const recurringDonation = new RecurringDonation()
            .withId(recordId)
            .withCommitmentId(commitmentId)
            .withInstallmentFrequency(1);

        return recurringDonation;
    }

    getPaymentProcessingMessage(paymentMethod) {
        if (this.isCard(paymentMethod)) {
            return validatingCardMessage;
        } else if (this.isACH(paymentMethod)) {
            return validatingACHMessage;
        }
    }

    getPlannedInstallments(rd2State) {
        if (this.isOpenLength(rd2State)) {
            return null;
        }
        return rd2State.plannedInstallments;
    }

    getCustomFieldValues({ customFieldSets }) {
        let fieldValues = {};
        for (const field of customFieldSets) {
            fieldValues[field.apiName] = field.value;
        }
        return fieldValues;
    }

    getSaveRequest(rd2State) {
        const {
            recordId,
            recordName,
            recurringStatus,
            statusReason,
            contactId,
            accountId,
            dateEstablished,
            donationValue,
            currencyIsoCode,
            recurringPeriod,
            recurringFrequency,
            startDate,
            dayOfMonth,
            recurringType,
            paymentToken,
            campaignId,
            commitmentId,
            achLastFour,
            cardLastFour,
            cardExpirationMonth,
            cardExpirationYear,
            paymentMethod,
            changeType,
        } = rd2State;

        const plannedInstallments = this.getPlannedInstallments(rd2State);
        const customFieldValues = this.getCustomFieldValues(rd2State);

        return {
            recordId,
            recordName,
            recurringStatus,
            statusReason,
            contactId,
            accountId,
            dateEstablished,
            donationValue,
            currencyIsoCode,
            recurringPeriod,
            recurringFrequency,
            startDate,
            dayOfMonth,
            plannedInstallments,
            recurringType,
            paymentToken,
            campaignId,
            commitmentId,
            achLastFour,
            cardLastFour,
            cardExpirationMonth,
            cardExpirationYear,
            paymentMethod,
            customFieldValues,
            changeType,
        };
    }

    isValidForElevate(rd2State) {
        const isScheduleSupported = this.isElevateSupportedSchedule(rd2State);
        const isValidPaymentMethod = this.isElevatePaymentMethod(rd2State.paymentMethod);
        const currencySupported = this.isElevateSupportedCurrency(rd2State);
        const countrySupported = this.isElevateCountrySupported(rd2State);
        const statusSupported = this.isElevateValidStatus(rd2State);
        const isElevateCustomer = this.isElevateCustomer(rd2State);
        return (
            isElevateCustomer &&
            isScheduleSupported &&
            isValidPaymentMethod &&
            currencySupported &&
            countrySupported &&
            statusSupported
        );
    }

    isOpenLength({ recurringType }) {
        return recurringType === RECURRING_TYPE_OPEN;
    }

    isElevateCustomer({ isElevateCustomer }) {
        return isElevateCustomer;
    }

    isElevateValidStatus(rd2State) {
        if (rd2State.recordId) {
            if (this.isOriginalStatusClosed(rd2State)) {
                return false;
            }
        }
        return !this.isClosedStatus(rd2State);
    }

    isElevateCountrySupported({ mailingCountry }) {
        return isNull(mailingCountry) || ELEVATE_SUPPORTED_COUNTRIES.includes(mailingCountry);
    }

    isElevateSupportedSchedule({ recurringPeriod, recurringType }) {
        const isValidRecurringType = recurringType === RECURRING_TYPE_OPEN;
        const isValidInstallmentPeriod = recurringPeriod !== PERIOD.FIRST_AND_FIFTEENTH;
        return isValidInstallmentPeriod && isValidRecurringType;
    }

    isElevateSupportedCurrency({ currencyIsoCode, isMultiCurrencyEnabled }) {
        if (isMultiCurrencyEnabled) {
            return ELEVATE_SUPPORTED_CURRENCIES.includes(currencyIsoCode);
        }
        return ELEVATE_SUPPORTED_CURRENCIES.includes(CURRENCY);
    }

    isElevatePaymentMethod(paymentMethod) {
        return ELEVATE_PAYMENT_METHODS.includes(paymentMethod);
    }

    isCard(paymentMethod) {
        return paymentMethod === PAYMENT_METHOD_CREDIT_CARD;
    }

    isACH(paymentMethod) {
        return paymentMethod === PAYMENT_METHOD_ACH;
    }

    getOriginalPaymentMethod({ initialViewState }) {
        return initialViewState.paymentMethod;
    }

    isOriginalStatusClosed({ initialViewState }) {
        return this.isClosedStatus(initialViewState);
    }

    isClosedStatus({ closedStatusValues, recurringStatus }) {
        return closedStatusValues.includes(recurringStatus);
    }

    isPaymentMethodChanged(rd2State) {
        const originalPaymentMethod = this.getOriginalPaymentMethod(rd2State);
        const { paymentMethod } = rd2State;
        return originalPaymentMethod !== paymentMethod;
    }

    isAmountChanged(rd2State) {
        const originalAmount = rd2State.initialViewState.donationValue;
        const amount = rd2State.donationValue;
        return amount !== originalAmount;
    }

    isFrequencyChanged(rd2State) {
        const originalFrequency = rd2State.initialViewState.recurringFrequency;
        const frequency = rd2State.recurringFrequency;
        return originalFrequency !== frequency;
    }

    isPeriodChanged(rd2State) {
        const originalPeriod = rd2State.initialViewState.recurringPeriod;
        const period = rd2State.recurringPeriod;
        return originalPeriod !== period;
    }

    isCampaignChanged(rd2State) {
        const originalCampaignId = rd2State.initialViewState.campaignId;
        const campaignId = rd2State.campaignId;
        return originalCampaignId !== campaignId;
    }

    /***
     * @description Returns true if Schedule fields has updated
     */
    hasElevateFieldsChange(rd2State) {
        const amountChanged = this.isAmountChanged(rd2State);
        const frequencyChanged = this.isFrequencyChanged(rd2State);
        const installmentPeriodChanged = this.isPeriodChanged(rd2State);
        const campaignChanged = this.isCampaignChanged(rd2State);

        return amountChanged || frequencyChanged || installmentPeriodChanged || campaignChanged;
    }
}

class RecurringDonation {
    record;

    constructor(record = {}) {
        this.record = record;
    }

    withCommitmentResponseBody(responseBody) {
        this.record[FIELD_COMMITMENT_ID.fieldApiName] = responseBody.id;

        const { cardData, achData } = responseBody;

        if (cardData) {
            this.withCardData(cardData);
        } else if (achData) {
            this.withAchData(achData);
        }

        return this;
    }

    withContactId(contactId) {
        this.record[FIELD_CONTACT_ID.fieldApiName] = contactId;
        return this;
    }

    withOrganizationId(organizationId) {
        this.record[FIELD_ORGANIZATION_ID.fieldApiName] = organizationId;
        return this;
    }

    withCommitmentId(commitmentId) {
        this.record[FIELD_COMMITMENT_ID.fieldApiName] = commitmentId;
        return this;
    }

    withId(id) {
        this.record[FIELD_ID.fieldApiName] = id;
        return this;
    }

    withInstallmentFrequency(installmentFrequency) {
        this.record[FIELD_INSTALLMENT_FREQUENCY.fieldApiName] = installmentFrequency;
        return this;
    }

    withInputFieldValues(inputFieldValues) {
        this.record = { ...this.record, ...inputFieldValues };
        return this;
    }

    withPaymentMethod(paymentMethod) {
        this.record[FIELD_PAYMENT_METHOD.fieldApiName] = paymentMethod;
        return this;
    }

    withCardData(cardData) {
        this.record[FIELD_CARD_LAST4.fieldApiName] = cardData.last4;
        this.record[FIELD_CARD_EXPIRY_MONTH.fieldApiName] = cardData.expirationMonth;
        this.record[FIELD_CARD_EXPIRY_YEAR.fieldApiName] = cardData.expirationYear;
        this.record[FIELD_ACH_LAST4.fieldApiName] = null;
    }

    withAchData(achData) {
        this.record[FIELD_CARD_LAST4.fieldApiName] = null;
        this.record[FIELD_CARD_EXPIRY_MONTH.fieldApiName] = null;
        this.record[FIELD_CARD_EXPIRY_YEAR.fieldApiName] = null;
        this.record[FIELD_ACH_LAST4.fieldApiName] = achData.last4;
    }

    asJSON() {
        return JSON.stringify(this.record);
    }
}

export {
    Rd2Service,
    ACTIONS,
    ELEVATE_PAYMENT_METHODS,
    PERIOD,
    RECURRING_PERIOD_ADVANCED,
    RECURRING_TYPE_FIXED,
    RECURRING_TYPE_OPEN,
    ACCOUNT_DONOR_TYPE,
    CONTACT_DONOR_TYPE,
    CHANGE_TYPE_DOWNGRADE,
    CHANGE_TYPE_UPGRADE,
};
