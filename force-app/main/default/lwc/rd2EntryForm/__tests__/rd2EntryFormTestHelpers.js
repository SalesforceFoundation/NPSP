import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import FIELD_INSTALLMENT_PERIOD from "@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installment_Period__c";
import FIELD_DAY_OF_MONTH from "@salesforce/schema/npe03__Recurring_Donation__c.Day_of_Month__c";
import RECURRING_DONATION_OBJECT from "@salesforce/schema/npe03__Recurring_Donation__c";
import ACCOUNT_OBJECT from "@salesforce/schema/Account";
import CONTACT_OBJECT from "@salesforce/schema/Contact";

import recurringDonationObjectInfo from "../../../../../../tests/__mocks__/apex/data/recurringDonationObjectInfo.json";
import contactPartialDescribe from "./data/contactPartialDescribe.json";
import accountPartialDescribe from "./data/accountPartialDescribe.json";
import installmentPeriodPicklistValues from "./data/installmentPeriodPicklistValues.json";
import dayOfMonthPicklistValues from "./data/dayOfMonthPicklistValues.json";

export const setupWireMocks = async () => {
    getObjectInfo.emit(recurringDonationObjectInfo, (config) => {
        return config.objectApiName === RECURRING_DONATION_OBJECT.objectApiName;
    });

    getObjectInfo.emit(contactPartialDescribe, (config) => {
        return config.objectApiName.objectApiName === CONTACT_OBJECT.objectApiName;
    });

    getObjectInfo.emit(accountPartialDescribe, (config) => {
        return config.objectApiName.objectApiName === ACCOUNT_OBJECT.objectApiName;
    });

    getPicklistValues.emit(installmentPeriodPicklistValues, (config) => {
        return config.fieldApiName.fieldApiName === FIELD_INSTALLMENT_PERIOD.fieldApiName;
    });

    getPicklistValues.emit(dayOfMonthPicklistValues, (config) => {
        return config.fieldApiName.fieldApiName === FIELD_DAY_OF_MONTH.fieldApiName;
    });

    await flushPromises();
};

export class RD2FormField {
    element;

    constructor(element) {
        this.element = element;
    }

    setValue(value) {
        this.element.value = value;
    }

    getValue() {
        return this.element.value;
    }

    changeValue(value) {
        this.setValue(value);
        this.dispatchChangeEvent();
    }

    dispatchChangeEvent() {
        const { value } = this.element;
        this.element.dispatchEvent(new CustomEvent("change", { detail: { value } }));
    }
}

export class RD2FormController {
    element;

    constructor(element) {
        this.element = element;
    }

    setDefaultDateValues() {
        this.dateEstablished().changeValue("2021-02-03");
        this.startDate().changeValue("2021-02-03");
        this.dayOfMonth().changeValue("6");
    }

    header() {
        return this.element.shadowRoot.querySelector('#modal-heading-01');
    }

    donorSection() {
        return this.element.shadowRoot.querySelector("c-rd2-entry-form-donor-section");
    }

    scheduleSection() {
        return this.element.shadowRoot.querySelector("c-rd2-entry-form-schedule-section");
    }

    elevateWidget() {
        return this.element.shadowRoot.querySelector("c-rd2-elevate-credit-card-form");
    }

    amount() {
        const field = this.element.shadowRoot.querySelector('lightning-input-field[data-id="amountField"]');
        return new RD2FormField(field);
    }

    currencyIsoCode() {
        const field = this.element.shadowRoot.querySelector('lightning-input-field[data-id="currencyField"]');
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

    recordName() {
        const field = this.element.shadowRoot.querySelector('lightning-input-field[data-id="recordName"]');
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

    recurringPeriod() {
        const scheduleSection = this.scheduleSection();
        const field = scheduleSection.shadowRoot.querySelector('lightning-combobox[data-id="recurringPeriod"]');
        return new RD2FormField(field);
    }

    installmentPeriod() {
        const scheduleSection = this.scheduleSection();
        const field = scheduleSection.shadowRoot.querySelector('lightning-combobox[data-id="installmentPeriod"]');
        return new RD2FormField(field);
    }

    installmentFrequency() {
        const scheduleSection = this.scheduleSection();
        const field = scheduleSection.shadowRoot.querySelector('lightning-combobox[data-id="installmentFrequency"]');
        return new RD2FormField(field);
    }

    plannedInstallments() {
        const scheduleSection = this.scheduleSection();
        const field = scheduleSection.shadowRoot.querySelector('lightning-input-field[data-id="plannedInstallments"]');
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
        return this.elevateWidget().shadowRoot.querySelector(
            'lightning-button[data-qa-locator="button Do Not Use Elevate"]'
        );
    }

    updatePaymentButton() {
        return this.elevateWidget().shadowRoot.querySelector(
            'lightning-button[data-qa-locator="button Update Payment Information"]'
        );
    }

    cancelUpdatePaymentButton() {
        return this.elevateWidget().shadowRoot.querySelector(
            'lightning-button[data-qa-locator="button Cancel Update Payment Information"]'
        );
    }

    customFieldsSection() {
        return this.element.shadowRoot.querySelector('c-rd2-entry-form-custom-fields-section');
    }

    customFields() {
        const customFields = this.customFieldsSection();
        return customFields.shadowRoot.querySelectorAll('lightning-input-field');
    }

    changeTypePicklist() {
        const field = this.element.shadowRoot.querySelector('lightning-input-field[data-id="changeType"]');
        return new RD2FormField(field);
    }

    errorPageLevelMessage() {
        return this.element.shadowRoot.querySelector("c-util-page-level-message[data-id='error']");
    }

    errorFormattedText() {
        return this.element.shadowRoot.querySelector("c-util-page-level-message[data-id='error'] p lightning-formatted-text");
    }
}