import { createElement } from "lwc";
import Rd2EntryFormScheduleSection from "c/rd2EntryFormScheduleSection";
import { Rd2Service } from "c/rd2Service";
import getInitialView from "@salesforce/apex/RD2_EntryFormController.getInitialView";
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import { mockReset } from "lightning/inputField";

import FIELD_DAY_OF_MONTH from "@salesforce/schema/npe03__Recurring_Donation__c.Day_of_Month__c";
import FIELD_INSTALLMENT_PERIOD from "@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installment_Period__c";
import RECURRING_DONATION_OBJECT from "@salesforce/schema/npe03__Recurring_Donation__c";
import { SET_RECURRING_TYPE } from "../../rd2Service/actions";

const mockDayOfMonthPicklistValues = require("./data/wiredDayOfMonthPicklistValues.json");
const mockInstallmentPeriodPicklistValues = require("./data/wiredInstallmentPeriodPicklistValues.json");
const mockRecurringDonationObjectInfo = require("../../../../../../tests/__mocks__/apex/data/recurringDonationObjectInfo.json");
const initialViewResponse = require("../../../../../../tests/__mocks__/apex/data/getInitialView.json");

const TEST_DATE = new Date(2021, 10, 4);
const FAKE_RD2_ID = "00A_fake_rd2_id";
const FAKE_CONTACT_ID = "003_fake_contact_id";

const mockHandleFrequencyChange = jest.fn();
const mockHandleInstallmentsChange = jest.fn();
const mockHandleCustomPeriodChange = jest.fn();
const mockHandleAdvancedPeriodChange = jest.fn();
const mockHandleError = jest.fn();

jest.mock("@salesforce/apex/RD2_EntryFormController.getInitialView", () => ({ default: jest.fn() }), { virtual: true });

describe("c-rd2-entry-form-schedule-section", () => {
    let component;
    let controller;

    afterEach(() => {
        clearDOM();
    });

    describe("new rd with default recurring type open", () => {
        beforeEach(async () => {
            const rd2Service = new Rd2Service();
            getInitialView.mockResolvedValue(initialViewResponse);
            component = createElement("c-rd2-entry-form-schedule-section", { is: Rd2EntryFormScheduleSection });
            const rd2State = await rd2Service.loadInitialView(rd2Service.init(), null, FAKE_CONTACT_ID);
            component.rd2State = rd2State;
            controller = new Rd2EntryFormScheduleSectionTestController(component);
            document.body.appendChild(component);
            await setupWires();
        });

        afterEach(() => {
            jest.useRealTimers();
        });

        it("number of planned installments is not rendered", async () => {
            await flushPromises();
            expect(controller.numberOfPlannedInstallments()).toBeNull();
        });

        it("when recurring type changed to fixed, number of planned installments is visible", async () => {
            const rd2Service = new Rd2Service();
            const recurringTypeField = controller.recurringType();
            const newRecurringType = "Fixed";
            changeValue(recurringTypeField, newRecurringType);
            component.rd2State = rd2Service.dispatch(component.rd2State, {
                type: SET_RECURRING_TYPE,
                payload: newRecurringType,
            });
            await flushPromises();

            expect(controller.numberOfPlannedInstallments()).toBeTruthy();
        });

        it("default installment period is set on load", async () => {
            await flushPromises();
            expect(component.rd2State.periodType).toBe("Monthly");
            expect(controller.customPeriod().value).toBe("Monthly");
        });

        it("day of month picklist defaults to value provided from back-end", async () => {
            await flushPromises();
            const expectedDay = initialViewResponse.record.dayOfMonth;
            expect(controller.dayOfMonth().value).toBe(expectedDay);
        });

        it("returnValues returns data from visible fields by field api name", async () => {
            await flushPromises();
            controller.recurringType().value = "Open";
            controller.startDate().value = TEST_DATE;
            const values = component.returnValues();
            expect(values).toMatchObject({
                RecurringType__c: "Open",
                StartDate__c: TEST_DATE,
                npe03__Installment_Period__c: "Monthly",
            });
        });

        it("resetValues resets visible lightning-input-fields", async () => {
            await flushPromises();
            controller.recurringType().value = "Open";
            controller.startDate().value = TEST_DATE;
            component.resetValues();
            expect(mockReset).toHaveBeenCalledTimes(3);
        });
    });

    describe("new rd with default recurring type fixed", () => {
        beforeEach(async () => {
            const rd2Service = new Rd2Service();
            const initialViewFixed = {
                ...initialViewResponse,
                record: {
                    ...initialViewResponse.record,
                    recurringType: "Fixed",
                },
            };
            getInitialView.mockResolvedValue(initialViewFixed);
            component = createElement("c-rd2-entry-form-schedule-section", { is: Rd2EntryFormScheduleSection });
            const rd2State = await rd2Service.loadInitialView(rd2Service.init(), null, FAKE_CONTACT_ID);
            component.rd2State = rd2State;

            component.addEventListener("installmentschange", mockHandleInstallmentsChange);
            controller = new Rd2EntryFormScheduleSectionTestController(component);
            document.body.appendChild(component);
            await setupWires();
        });

        it("number of planned installments is rendered", async () => {
            await flushPromises();
            expect(controller.numberOfPlannedInstallments()).toBeTruthy();
        });

        it("informs parent component of changes to number of planned installments", async () => {
            await flushPromises();

            const plannedInstallments = controller.numberOfPlannedInstallments();
            changeValue(plannedInstallments, 12);

            expect(mockHandleInstallmentsChange).toHaveBeenCalledTimes(1);
        });
    });

    describe("new rd with default recurring period weekly", () => {
        beforeEach(async () => {
            const rd2Service = new Rd2Service();
            const initialViewWeekly = {
                ...initialViewResponse,
                record: {
                    ...initialViewResponse.record,
                    recurringPeriod: "Weekly",
                },
            };
            getInitialView.mockResolvedValue(initialViewWeekly);
            component = createElement("c-rd2-entry-form-schedule-section", { is: Rd2EntryFormScheduleSection });
            const rd2State = await rd2Service.loadInitialView(rd2Service.init(), null, FAKE_CONTACT_ID);
            component.rd2State = rd2State;
            component.addEventListener("frequencychange", mockHandleFrequencyChange);
            component.addEventListener("periodtypechange", mockHandleCustomPeriodChange);
            component.addEventListener("periodchange", mockHandleAdvancedPeriodChange);
            controller = new Rd2EntryFormScheduleSectionTestController(component);
            document.body.appendChild(component);
            await setupWires("Weekly");
        });

        it("custom period picklist is set to advanced", async () => {
            await flushPromises();
            expect(controller.customPeriod().value).toBe("Advanced");
        });

        it("when custom period picklist changed, informs parent component of change", async () => {
            await flushPromises();
            const customPeriod = controller.customPeriod();
            changeValue(customPeriod, "Monthly");
            expect(mockHandleCustomPeriodChange.mock.calls[0][0].detail).toBe("Monthly");
        });

        it("when advanced period picklist changed, informs parent component", async () => {
            await flushPromises();
            const advancedPeriod = controller.advancedInstallmentPeriod();
            changeValue(advancedPeriod, "Daily");
            expect(mockHandleAdvancedPeriodChange.mock.calls[0][0].detail).toBe("Daily");
        });

        it("installment period picklist is set to weekly", async () => {
            await flushPromises();
            expect(controller.advancedInstallmentPeriod().value).toBe("Weekly");
        });

        it("installment period picklist contains given options", () => {
            const options = mockInstallmentPeriodPicklistValues.values.map(({ value }) => value);
            expect(controller.advancedInstallmentPeriod().options).toContainOptions(options);
        });

        it("informs parent component of changes to frequency", async () => {
            await flushPromises();
            const frequencyInput = controller.installmentFrequency();
            changeValue(frequencyInput, 2);

            expect(mockHandleFrequencyChange).toHaveBeenCalledTimes(1);
        });

        it("returnValues returns data from visible fields by field api name", async () => {
            await flushPromises();
            controller.installmentFrequency().value = 2;
            controller.recurringType().value = "Open";
            controller.startDate().value = TEST_DATE;
            const values = component.returnValues();
            expect(values).toMatchObject({
                InstallmentFrequency__c: 2,
                RecurringType__c: "Open",
                StartDate__c: TEST_DATE,
                npe03__Installment_Period__c: "Weekly",
            });
        });
    });

    describe("editing an existing record", () => {
        beforeEach(async () => {
            component = createElement("c-rd2-entry-form-schedule-section", { is: Rd2EntryFormScheduleSection });
            controller = new Rd2EntryFormScheduleSectionTestController(component);
        });

        it("when record is Fixed recurring type, number of planned installments field is visible", async () => {
            const rd2Service = new Rd2Service();
            const initialViewFixed = {
                ...initialViewResponse,
                record: {
                    ...initialViewResponse.record,
                    recurringType: "Fixed",
                },
            };
            getInitialView.mockResolvedValue(initialViewFixed);
            const rd2State = await rd2Service.loadInitialView(rd2Service.init(), FAKE_RD2_ID, FAKE_CONTACT_ID);
            component.rd2State = rd2State;

            document.body.appendChild(component);
            await setupWires();
            await flushPromises();
            expect(controller.numberOfPlannedInstallments()).toBeTruthy();
        });

        it("when record is Open recurring type, number of planned installments field is not visible", async () => {
            const rd2Service = new Rd2Service();
            getInitialView.mockResolvedValue(initialViewResponse);
            const rd2State = await rd2Service.loadInitialView(rd2Service.init(), FAKE_RD2_ID, FAKE_CONTACT_ID);
            component.rd2State = rd2State;
            document.body.appendChild(component);
            await setupWires();
            await flushPromises();
            expect(controller.numberOfPlannedInstallments()).toBeFalsy();
        });
    });

    describe("error conditions", () => {
        beforeEach(() => {
            component = createElement("c-rd2-entry-form-schedule-section", { is: Rd2EntryFormScheduleSection });
            component.addEventListener("errorevent", mockHandleError);
            controller = new Rd2EntryFormScheduleSectionTestController(component);
        });

        it("alerts parent component when wiredGetRecurringObjectInfo fails", async () => {
            document.body.appendChild(component);
            const errorMessage = {
                status: 403,
                body: {
                    message:
                        "You don't have access to this record. Ask your administrator for help or to request access.",
                    statusCode: 403,
                    errorCode: "INSUFFICIENT_ACCESS",
                },
            };

            getObjectInfo.emitError(errorMessage, (config) => {
                return config.objectApiName === RECURRING_DONATION_OBJECT.objectApiName;
            });
            getPicklistValues.emit(mockInstallmentPeriodPicklistValues, (config) => {
                return config.fieldApiName?.fieldApiName === FIELD_INSTALLMENT_PERIOD.fieldApiName;
            });

            getPicklistValues.emit(mockDayOfMonthPicklistValues, (config) => {
                return config.fieldApiName?.fieldApiName === FIELD_DAY_OF_MONTH.fieldApiName;
            });
            await flushPromises();

            expect(mockHandleError.mock.calls[0][0].detail).toMatchObject({ value: errorMessage });
        });
    });
});

const setupWires = async (defaultRecurringPeriod = "Monthly") => {
    getObjectInfo.emit(mockRecurringDonationObjectInfo, (config) => {
        return config.objectApiName === RECURRING_DONATION_OBJECT.objectApiName;
    });

    await flushPromises();

    const installmentPeriodPicklistValues = {
        ...mockInstallmentPeriodPicklistValues,
        defaultValue: {
            attributes: null,
            label: defaultRecurringPeriod,
            validFor: [],
            value: defaultRecurringPeriod,
        },
    };

    getPicklistValues.emit(installmentPeriodPicklistValues, (config) => {
        return config.fieldApiName?.fieldApiName === FIELD_INSTALLMENT_PERIOD.fieldApiName;
    });

    getPicklistValues.emit(mockDayOfMonthPicklistValues, (config) => {
        return config.fieldApiName?.fieldApiName === FIELD_DAY_OF_MONTH.fieldApiName;
    });
};

class Rd2EntryFormScheduleSectionTestController {
    component;

    constructor(component) {
        this.component = component;
    }

    customPeriod() {
        return this.component.shadowRoot.querySelector('lightning-combobox[data-id="recurringPeriod"]');
    }

    advancedInstallmentPeriod() {
        return this.component.shadowRoot.querySelector('lightning-combobox[data-id="installmentPeriod"]');
    }

    numberOfPlannedInstallments() {
        return this.component.shadowRoot.querySelector('lightning-input-field[data-id="plannedInstallments"]');
    }

    recurringType() {
        return this.component.shadowRoot.querySelector('lightning-input-field[data-id="RecurringType__c"]');
    }

    installmentFrequency() {
        return this.component.shadowRoot.querySelector('lightning-input[data-id="installmentFrequency"]');
    }

    dayOfMonth() {
        return this.component.shadowRoot.querySelector('lightning-input-field[data-id="dayOfMonth"]');
    }

    startDate() {
        return this.component.shadowRoot.querySelector('lightning-input-field[data-id="startDate"]');
    }
}

const changeValue = (element, value) => {
    element.value = value;
    element.dispatchEvent(new CustomEvent("change", { detail: { value } }));
};
