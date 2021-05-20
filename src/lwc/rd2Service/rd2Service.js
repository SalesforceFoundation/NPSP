import { isBlank } from 'c/util';
import { format } from 'c/utilCommon';

import FIELD_ID from '@salesforce/schema/npe03__Recurring_Donation__c.Id';
import FIELD_ACH_LAST4 from '@salesforce/schema/npe03__Recurring_Donation__c.ACH_Last_4__c';
import FIELD_INSTALLMENT_FREQUENCY from '@salesforce/schema/npe03__Recurring_Donation__c.InstallmentFrequency__c';
import FIELD_COMMITMENT_ID from '@salesforce/schema/npe03__Recurring_Donation__c.CommitmentId__c';
import FIELD_CARD_LAST4 from '@salesforce/schema/npe03__Recurring_Donation__c.CardLast4__c';
import FIELD_CARD_EXPIRY_MONTH from '@salesforce/schema/npe03__Recurring_Donation__c.CardExpirationMonth__c';
import FIELD_CARD_EXPIRY_YEAR from '@salesforce/schema/npe03__Recurring_Donation__c.CardExpirationYear__c';
import FIELD_PAYMENT_METHOD from '@salesforce/schema/npe03__Recurring_Donation__c.PaymentMethod__c';
import FIELD_CONTACT_ID from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Contact__c';
import FIELD_ORGANIZATION_ID from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Organization__c';
import validatingCardMessage from '@salesforce/label/c.RD2_EntryFormSaveCreditCardValidationMessage';
import validatingACHMessage from '@salesforce/label/c.RD2_EntryFormSaveACHMessage';
import { ACCOUNT_HOLDER_TYPES, PAYMENT_METHOD_ACH, PAYMENT_METHOD_CREDIT_CARD } from 'c/geConstants';

const ELEVATE_PAYMENT_METHODS = [PAYMENT_METHOD_ACH, PAYMENT_METHOD_CREDIT_CARD];

class Rd2Service {

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
                response.body = response.body.replace(/\"/g, '').replace(/\'/g, '"');
            }

            //parse the error response
            try {
                response.body = JSON.parse(response.body);
            } catch (error) { }
        }

        let errors = this.getErrors(response);

        return format('{0}', [errors]);
    }

    /***
     * @description Get the message or errors from a failed API call.
     * @param {object} response: Http response object
     * @return {string}: Message from a failed API call response
     */
    getErrors(response) {
        if (response.body && response.body.errors) {
            return response.body.errors.map(error => error.message).join('\n ');
        }

        // For some reason the key in the body object for 'Message'
        // in the response we receive from Elevate is capitalized.
        // Also checking for lowercase M in message in case they fix it.
        return response.body.Message
            || response.body.message
            || response.errorMessage
            || JSON.stringify(response.body);
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

    accountHolderTypeFor(donorType) {
        if(donorType === 'Contact') {
            return ACCOUNT_HOLDER_TYPES.INDIVIDUAL;
        } else if(donorType === 'Account') {
            return ACCOUNT_HOLDER_TYPES.BUSINESS;
        }
    }

    getPaymentProcessingMessage(paymentMethod) {
        if(this.isCard(paymentMethod)) {
            return validatingCardMessage;
        } else if(this.isACH(paymentMethod)) {
            return validatingACHMessage;
        }
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
}

class RecurringDonation {
    record;

    constructor(record = {}) {
        this.record = record;
    }

    hasInstallmentFrequency() {
        return !isBlank(this.record[FIELD_INSTALLMENT_FREQUENCY.fieldApiName]);
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

export { Rd2Service, ELEVATE_PAYMENT_METHODS }