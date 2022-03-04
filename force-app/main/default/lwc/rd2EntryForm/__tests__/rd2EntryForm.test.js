import { createElement } from "lwc";
import Rd2EntryForm from "c/rd2EntryForm";
import { RD2FormController, setupWireMocksForElevate, mockRecordEditFormSubmit } from "./rd2EntryFormTestHelpers";
import { getRecord } from "lightning/uiRecordApi";
import { mockGetIframeReply } from "c/psElevateTokenHandler";

import getInitialView from "@salesforce/apex/RD2_EntryFormController.getInitialView";
import handleCommitment from "@salesforce/apex/RD2_EntryFormController.handleCommitment";
import saveRecurringDonation from "@salesforce/apex/RD2_EntryFormController.saveRecurringDonation";

import RD2_EntryFormMissingPermissions from "@salesforce/label/c.RD2_EntryFormMissingPermissions";
import RD2_EntryFormHeader from "@salesforce/label/c.RD2_EntryFormHeader";
import commonEdit from "@salesforce/label/c.commonEdit";

const contactGetRecord = require("./data/contactGetRecord.json");
const accountGetRecord = require("./data/accountGetRecord.json");
const rd2WithCardCommitment = require("./data/rd2WithCardCommitment.json");
const rd2WithACHCommitment = require("./data/rd2WithACHCommitment.json");
const rd2WithoutCommitmentCard = require("./data/rd2WithoutCommitmentCard.json");
const handleCommitmentResponseBody = require("./data/handleCommitmentResponseBody.json");
const handleCommitmentResponseBodyACH = require("./data/handleCommitmentResponseBodyACH.json");
const initialViewResponse = require("../../../../../../tests/__mocks__/apex/data/getInitialView.json");
const rd2WithCardCommitmentInitialView = require("./data/rd2WithCardCommitmentInitialView.json");
const rd2WithACHCommitmentInitialView = require("./data/rd2WithACHCommitmentInitialView.json");
const rd2WithoutCommitmentInitialView = require("./data/rd2WithoutCommitmentInitialView.json");

jest.mock("@salesforce/apex/RD2_EntryFormController.getInitialView", () => ({ default: jest.fn() }), { virtual: true });
jest.mock("@salesforce/apex/RD2_EntryFormController.saveRecurringDonation", () => ({ default: jest.fn() }), { virtual: true });

const mockScrollIntoView = jest.fn();

const FAKE_ACH_RD2_ID = "a0963000008pebAAAQ";
const FAKE_CARD_RD2_ID = "a0963000008oxZnAAI";

const EXPECTED_BUSINESS_ACH_PARAMS = {
    nameOnAccount: "Donor Organization",
    accountHolder: {
        type: "BUSINESS",
        businessName: "Anthropy",
        accountName: "Donor Organization",
        bankType: "CHECKING",
    },
    achCode: "WEB",
};

const EXPECTED_INDIVIDUAL_ACH_PARAMS = {
    nameOnAccount: "John Smith",
    accountHolder: {
        type: "INDIVIDUAL",
        firstName: "John",
        lastName: "Smith",
        bankType: "CHECKING",
    },
    achCode: "WEB",
};

jest.mock(
    "@salesforce/apex/RD2_EntryFormController.handleCommitment",
    () => {
        return { default: jest.fn() };
    },
    { virtual: true }
);

describe("c-rd2-entry-form", () => {
    beforeEach(() => {
        getInitialView.mockResolvedValue({
            ...initialViewResponse,
            isElevateCustomer: true,
        });
        window.HTMLElement.prototype.scrollIntoView = mockScrollIntoView;
    });

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    describe("creating new records", () => {
        it("displays an error when user does not have required permissions", async () => {
            getInitialView.mockResolvedValue({
                hasRequiredFieldPermissions: false,
            });

            const element = createRd2EntryForm();
            const controller = new RD2FormController(element);

            await flushPromises();

            expect(mockScrollIntoView).toHaveBeenCalled();

            const saveButton = controller.saveButton();
            expect(saveButton.disabled).toBe(true);

            const formattedText = element.shadowRoot.querySelector("lightning-formatted-text");
            expect(formattedText.value).toBe(RD2_EntryFormMissingPermissions);
        });

        it("elevate customer selects Credit Card payment method then widget displayed", async () => {
            const element = createRd2EntryForm();
            const controller = new RD2FormController(element);

            await flushPromises();

            await setupWireMocksForElevate();
            controller.setDefaultDateValues();

            controller.paymentMethod().changeValue("Credit Card");

            await flushPromises();

            const elevateWidget = controller.elevateWidget();
            expect(elevateWidget).toBeTruthy();
            expect(controller.disableElevateButton()).toBeTruthy();
        });

        it("elevate customer selects ACH payment method then widget displayed", async () => {
            const element = createRd2EntryForm();
            const controller = new RD2FormController(element);
            await flushPromises();

            await setupWireMocksForElevate();
            controller.setDefaultDateValues();

            controller.paymentMethod().changeValue("ACH");

            await flushPromises();

            const elevateWidget = controller.elevateWidget();
            expect(elevateWidget).toBeTruthy();
            expect(controller.disableElevateButton()).toBeTruthy();
            expect(controller.cancelUpdatePaymentButton()).toBeFalsy();
        });

        it("does not render widget when 1st and 15th installment period selected", async () => {
            const element = createRd2EntryForm();
            const controller = new RD2FormController(element);
            await flushPromises();

            await setupWireMocksForElevate();

            controller.setDefaultDateValues();
            controller.paymentMethod().changeValue("ACH");
            await flushPromises();

            expect(controller.elevateWidget()).toBeTruthy();

            controller.recurringPeriod().changeValue("Advanced");
            await flushPromises();

            expect(controller.installmentPeriod()).toBeTruthy();

            controller.installmentPeriod().changeValue("1st and 15th");
            await flushPromises();

            const elevateWidget = controller.elevateWidget();
            expect(elevateWidget).toBeFalsy();
        });

        it('displays label for new recurring donations in header', () => {
            const element = createRd2EntryForm();
            const controller = new RD2FormController(element);
            const header = controller.header();

            expect(header).toBeTruthy();
            expect(header.textContent).toBe(RD2_EntryFormHeader);
        });

        it("renders custom fields when one field is defined", async () => {
            getInitialView.mockResolvedValue({
                ...initialViewResponse,
                customFieldSets: [
                    {
                        apiName: "Custom1__c",
                        required: false,
                    },
                ],
            });

            const element = createRd2EntryForm();
            const controller = new RD2FormController(element);

            await flushPromises();

            expect(controller.customFieldsSection()).toBeTruthy();
            expect(controller.customFields()).toHaveLength(1);
        });

        it('when multicurrency enabled, displays currency field', async () => {
            getInitialView.mockResolvedValue({
                ...initialViewResponse,
                isElevateCustomer: true,
                isMultiCurrencyEnabled: true,
            });

            const element = createRd2EntryForm();
            await flushPromises();

            await setupWireMocksForElevate();

            const controller = new RD2FormController(element);

            const currencyIsoCodeField = controller.currencyIsoCode();
            expect(currencyIsoCodeField.element).toBeTruthy();
        });
    });

    describe("tokenization", () => {
        beforeEach(() => {
            getInitialView.mockResolvedValue({ ...initialViewResponse, isElevateCustomer: true });
            setupIframeReply();
        });

        it("individual donor, contact name is used for account holder name when tokenizing an ACH payment", async () => {
            setupCommitmentResponse(handleCommitmentResponseBodyACH);
            const element = createRd2EntryForm();
            const controller = new RD2FormController(element);

            await flushPromises();

            await setupWireMocksForElevate();

            controller.setDefaultDateValues();
            controller.setupSubmitMock();
            controller.contactLookup().changeValue("001fakeContactId");
            await flushPromises();

            getRecord.emit(contactGetRecord, (config) => {
                return config.recordId === "001fakeContactId";
            });

            controller.amount().changeValue(1.0);
            controller.paymentMethod().changeValue("ACH");

            await flushPromises();

            const elevateWidget = controller.elevateWidget();
            expect(elevateWidget).toBeTruthy();
            expect(controller.disableElevateButton()).toBeTruthy();
            expect(elevateWidget.payerFirstName).toBe("John");
            expect(elevateWidget.payerLastName).toBe("Smith");

            controller.saveButton().click();

            await flushPromises();
            validateIframeMessage(mockGetIframeReply.mock.calls[0], EXPECTED_INDIVIDUAL_ACH_PARAMS);
            const EXPECTED_RECORD = {
                RecurringType__c: "Open",
                Day_of_Month__c: "6",
                StartDate__c: "2021-02-03",
                npe03__Installment_Period__c: "Monthly",
                npe03__Contact__c: "001fakeContactId",
                npe03__Date_Established__c: "2021-02-03",
                PaymentMethod__c: "ACH",
                npe03__Amount__c: 1,
                InstallmentFrequency__c: 1,
            };
            validateCommitmentMessage(EXPECTED_RECORD);
            // TODO: When submit is swapped out, use this expect block instead.
            // expect(saveRecurringDonation).toHaveBeenCalled();
            // expect(saveRecurringDonation).toHaveBeenCalledWith({
            //     achLastFour: "5432",
            //     cardExpirationMonth: null,
            //     cardExpirationYear: null,
            //     cardLastFour: null,
            //     commitmentId: "ffd252d6-7ffc-46a0-994f-00f7582263d2",
            //     currencyIsoCode: null,
            //     dayOfMonth: "6",
            //     paymentMethod: "ACH",
            //     paymentToken: "a_dummy_token",
            //     recordId: null,
            //     recordName: "",
            //     recurringFrequency: 1,
            //     recurringType: "Open",
            //     recurringStatus: null,
            //     startDate: "2021-02-03",
            //     donationValue: 1,
            //     contactId: "001fakeContactId",
            //     accountId: null,
            //     dateEstablished: "2021-02-03",
            //     recurringPeriod: "Monthly",
            //     plannedInstallments: null,
            // });
            expect(mockRecordEditFormSubmit).toHaveBeenCalled();
            expect(mockRecordEditFormSubmit).toHaveBeenCalledWith({
                ACH_Last_4__c: "5432",
                CardExpirationMonth__c: null,
                CardExpirationYear__c: null,
                CardLast4__c: null,
                CommitmentId__c: "ffd252d6-7ffc-46a0-994f-00f7582263d2",
                Day_of_Month__c: "6",
                InstallmentFrequency__c: 1,
                PaymentMethod__c: "ACH",
                RecurringType__c: "Open",
                StartDate__c: "2021-02-03",
                npe03__Amount__c: 1,
                npe03__Contact__c: "001fakeContactId",
                npe03__Date_Established__c: "2021-02-03",
                npe03__Installment_Period__c: "Monthly",
                npe03__Installments__c: null,
                npe03__Recurring_Donation_Campaign__c: null
            });
        });

        it("organization donor, account name is used when tokenizing an ACH payment", async () => {
            const element = createRd2EntryForm();
            const controller = new RD2FormController(element);

            await flushPromises();

            await setupWireMocksForElevate();

            controller.setDefaultDateValues();
            controller.dayOfMonth().setValue("6");
            controller.donorType().changeValue("Account");
            controller.paymentMethod().changeValue("ACH");
            await flushPromises();

            controller.accountLookup().changeValue("001fakeAccountId");
            await flushPromises();

            getRecord.emit(accountGetRecord, (config) => {
                return config.recordId === "001fakeAccountId";
            });
            await flushPromises();
            controller.amount().changeValue(1.0);

            await flushPromises();

            const elevateWidget = controller.elevateWidget();
            expect(elevateWidget).toBeTruthy();
            expect(elevateWidget.payerOrganizationName).toBe("Donor Organization");

            controller.saveButton().click();

            await flushPromises();

            expect(mockGetIframeReply).toHaveBeenCalled();

            validateIframeMessage(mockGetIframeReply.mock.calls[0], EXPECTED_BUSINESS_ACH_PARAMS);
            const EXPECTED_RECORD = {
                RecurringType__c: "Open",
                Day_of_Month__c: "6",
                StartDate__c: "2021-02-03",
                npe03__Installment_Period__c: "Monthly",
                npe03__Organization__c: "001fakeAccountId",
                npe03__Date_Established__c: "2021-02-03",
                PaymentMethod__c: "ACH",
                npe03__Amount__c: 1,
                InstallmentFrequency__c: 1,
            };
            validateCommitmentMessage(EXPECTED_RECORD);
        });
    });

    describe("editing existing record", () => {
        beforeEach(() => {
            setupIframeReply();
        });

        it('displays label with record name in header', async () => {
            getInitialView.mockResolvedValue(rd2WithCardCommitmentInitialView);
            const element = createRd2EditForm(FAKE_CARD_RD2_ID);
            const controller = new RD2FormController(element);
            const header = controller.header();
            await flushPromises();

            const { recordName } = rd2WithCardCommitmentInitialView.record;

            expect(header).toBeTruthy();
            expect(header.textContent).toBe(`${commonEdit} ${recordName}`);
        });

        it('when multicurrency enabled, populates multicurrency field', async () => {
            const { record } = rd2WithCardCommitmentInitialView;
            getInitialView.mockResolvedValue({
                ...rd2WithCardCommitmentInitialView,
                isMultiCurrencyEnabled: true,
                record: {
                    ...record,
                    currencyIsoCode: 'USD'
                }
            });

            const element = createRd2EntryForm();
            await flushPromises();

            await setupWireMocksForElevate();

            const controller = new RD2FormController(element);

            const currencyIsoCodeField = controller.currencyIsoCode();
            expect(currencyIsoCodeField.element).toBeTruthy();
            expect(currencyIsoCodeField.getValue()).toBe('USD');
        });

        it("rd2 record with card payment, when editing, displays card information", async () => {
            getInitialView.mockResolvedValue(rd2WithCardCommitmentInitialView);
            const element = createRd2EditForm(FAKE_CARD_RD2_ID);
            const controller = new RD2FormController(element);

            await setupWireMocksForElevate();

            getRecord.emit(rd2WithCardCommitment, (config) => {
                return config.recordId === FAKE_CARD_RD2_ID;
            });

            await flushPromises();

            const elevateWidget = controller.elevateWidget();
            expect(elevateWidget).toBeTruthy();

            expect(controller.last4().value).toBe("1212");
            expect(controller.cardExpriation().value).toBe("02/2023");
        });

        it("rd2 record with ACH payment, when editing, displays ACH last 4", async () => {
            getInitialView.mockResolvedValue(rd2WithACHCommitmentInitialView);
            const element = createRd2EditForm(FAKE_ACH_RD2_ID);
            const controller = new RD2FormController(element);
            await flushPromises();
            await setupWireMocksForElevate();

            getRecord.emit(rd2WithACHCommitment, (config) => {
                return config.recordId === FAKE_ACH_RD2_ID;
            });
            await flushPromises();


            const elevateWidget = controller.elevateWidget();
            expect(elevateWidget).toBeTruthy();
            expect(controller.last4().value).toBe("1111");
        });

        it("rd2 record with credit card payment type but no commitment, when editing, displays widget", async () => {
            getInitialView.mockResolvedValue({
                ...rd2WithoutCommitmentInitialView,
                paymentMethod: "Credit Card",
            });

            const element = createRd2EditForm(FAKE_CARD_RD2_ID);
            const controller = new RD2FormController(element);
            await flushPromises();
            await setupWireMocksForElevate();

            getRecord.emit(rd2WithoutCommitmentCard, (config) => {
                return config.recordId === FAKE_CARD_RD2_ID;
            });

            await flushPromises();

            getRecord.emit(contactGetRecord, (config) => {
                return config.recordId === "001fakeContactId";
            });

            await flushPromises();

            expect(controller.elevateWidget()).toBeTruthy();
        });

        it("rd2 record with check payment type, when editing and payment type changed to credit card, displays widget", async () => {
            const element = createRd2EditForm(FAKE_CARD_RD2_ID);
            const controller = new RD2FormController(element);
            await flushPromises();

            const rd2WithoutCommitmentCheck = generateMockFrom(rd2WithoutCommitmentCard).withFieldValue(
                "PaymentMethod__c",
                "Check"
            );
            await setupWireMocksForElevate();

            getRecord.emit(rd2WithoutCommitmentCheck, (config) => {
                return config.recordId === FAKE_CARD_RD2_ID;
            });

            await flushPromises();

            getRecord.emit(contactGetRecord, (config) => {
                return config.recordId === "001fakeContactId";
            });


            expect(controller.elevateWidget()).toBeNull();

            controller.paymentMethod().changeValue("Credit Card");

            await flushPromises();

            expect(controller.elevateWidget()).toBeTruthy();
            expect(controller.disableElevateButton()).toBeTruthy();
            expect(controller.cancelUpdatePaymentButton()).toBeFalsy();
        });

        it("rd2 record, when editing, uses existing contact information in tokenization", async () => {
            getInitialView.mockResolvedValue(rd2WithoutCommitmentInitialView);

            const element = createRd2EditForm(FAKE_CARD_RD2_ID);
            const controller = new RD2FormController(element);
            await flushPromises();
            await setupWireMocksForElevate();

            getRecord.emit(rd2WithoutCommitmentCard, (config) => {
                return config.recordId === FAKE_CARD_RD2_ID;
            });

            await flushPromises();

            getRecord.emit(contactGetRecord, (config) => {
                return config.recordId === "001fakeContactId";
            });

            await flushPromises();

            controller.setDefaultDateValues();

            controller.paymentMethod().changeValue("ACH");
            controller.dayOfMonth().changeValue("6");

            await flushPromises();

            expect(controller.elevateWidget()).toBeTruthy();
            expect(controller.disableElevateButton()).toBeTruthy();

            controller.saveButton().click();

            await flushPromises();

            expect(mockGetIframeReply).toHaveBeenCalled();
            expect(mockGetIframeReply).toHaveBeenCalledTimes(1);
            validateIframeMessage(mockGetIframeReply.mock.calls[0], EXPECTED_INDIVIDUAL_ACH_PARAMS);

            const EXPECTED_RECORD = {
                RecurringType__c: "Open",
                Day_of_Month__c: "6",
                StartDate__c: "2021-02-03",
                npe03__Installment_Period__c: "Monthly",
                npe03__Contact__c: "001fakeContactId",
                npe03__Date_Established__c: "2021-02-03",
                PaymentMethod__c: "ACH",
                Status__c: "Active",
                npe03__Amount__c: 0.5,
                Id: "a0963000008oxZnAAI",
                InstallmentFrequency__c: 1,
                npe03__Installments__c: null,
            };

            validateCommitmentMessage(EXPECTED_RECORD);
        });

        it("clears credit card fields when payment method changed to ACH", async () => {
            getInitialView.mockResolvedValue({
                ...rd2WithCardCommitmentInitialView,
                isChangeLogEnabled: true,
            });
            setupCommitmentResponse(handleCommitmentResponseBodyACH);
            const element = createRd2EditForm(FAKE_CARD_RD2_ID);
            const controller = new RD2FormController(element);
            await flushPromises();
            const rd2WithCommitmentCard = generateMockFrom(rd2WithoutCommitmentCard).withFieldValue(
                "CommitmentId__c",
                "fake-commitment-uuid"
            );
            await setupWireMocksForElevate();

            getRecord.emit(rd2WithCommitmentCard, (config) => {
                return config.recordId === FAKE_CARD_RD2_ID;
            });

            await flushPromises();

            getRecord.emit(contactGetRecord, (config) => {
                return config.recordId === "001fakeContactId";
            });

            controller.setDefaultDateValues();
            controller.setupSubmitMock();
            await flushPromises();

            expect(controller.elevateWidget()).toBeTruthy();
            expect(controller.updatePaymentButton()).toBeTruthy();

            controller.paymentMethod().changeValue("ACH");
            await flushPromises();

            expect(controller.updatePaymentButton()).toBeFalsy();
            expect(controller.cancelUpdatePaymentButton()).toBeTruthy();
            expect(controller.disableElevateButton()).toBeFalsy();

            controller.saveButton().click();
            await flushPromises();

            expect(mockRecordEditFormSubmit).toHaveBeenCalled();
            expect(mockRecordEditFormSubmit).toHaveBeenCalledWith({
                ACH_Last_4__c: "5432",
                CardExpirationMonth__c: null,
                CardExpirationYear__c: null,
                CardLast4__c: null,
                ChangeType__c: "",
                ClosedReason__c: null,
                CommitmentId__c: "ffd252d6-7ffc-46a0-994f-00f7582263d2",
                Day_of_Month__c: "6",
                Id: "a0963000008oxZnAAI",
                InstallmentFrequency__c: 1,
                PaymentMethod__c: "ACH",
                RecurringType__c: "Open",
                StartDate__c: "2021-02-03",
                Status__c: "Active",
                npe03__Amount__c: 0.5,
                npe03__Contact__c: "001fakeContactId",
                npe03__Date_Established__c: "2021-02-03",
                npe03__Installment_Period__c: "Monthly",
                npe03__Installments__c: null,
                npe03__Recurring_Donation_Campaign__c: null
            });
        });

        it("clears ACH fields when payment method changed to Card", async () => {
            getInitialView.mockResolvedValue({
                ...rd2WithACHCommitmentInitialView,
                isChangeLogEnabled: true,
            });

            setupCommitmentResponse(handleCommitmentResponseBody);
            const element = createRd2EditForm(FAKE_ACH_RD2_ID);
            const controller = new RD2FormController(element);
            await flushPromises();
            await setupWireMocksForElevate();

            getRecord.emit(rd2WithACHCommitment, (config) => {
                return config.recordId === FAKE_ACH_RD2_ID;
            });

            await flushPromises();

            getRecord.emit(contactGetRecord, (config) => {
                return config.recordId === "001fakeContactId";
            });

            controller.setDefaultDateValues();
            controller.setupSubmitMock();
            await flushPromises();

            expect(controller.elevateWidget()).toBeTruthy();
            expect(controller.updatePaymentButton()).toBeTruthy();

            controller.paymentMethod().changeValue("Credit Card");
            await flushPromises();

            expect(controller.updatePaymentButton()).toBeFalsy();
            expect(controller.cancelUpdatePaymentButton()).toBeTruthy();

            controller.saveButton().click();
            await flushPromises();

            expect(mockRecordEditFormSubmit).toHaveBeenCalled();
            expect(mockRecordEditFormSubmit).toHaveBeenCalledWith({
                ACH_Last_4__c: null,
                CardExpirationMonth__c: "05",
                CardExpirationYear__c: "2023",
                CardLast4__c: "1111",
                ChangeType__c: "",
                ClosedReason__c: null,
                CommitmentId__c: "ffd252d6-7ffc-46a0-994f-00f7582263d2",
                Day_of_Month__c: "6",
                Id: "a0963000008pebAAAQ",
                InstallmentFrequency__c: 1,
                PaymentMethod__c: "Credit Card",
                RecurringType__c: "Open",
                StartDate__c: "2021-02-03",
                Status__c: "Active",
                npe03__Amount__c: 0.5,
                npe03__Contact__c: "001fakeContactId",
                npe03__Date_Established__c: "2021-02-03",
                npe03__Installment_Period__c: "Monthly",
                npe03__Installments__c: null,
                npe03__Recurring_Donation_Campaign__c: null,
            });
        });
    });

    describe("open recurring donation upgrade/downgrade picklist", () => {
        let element;
        let controller;

        beforeEach(async () => {
            getInitialView.mockResolvedValue({
                ...rd2WithoutCommitmentInitialView,
                isChangeLogEnabled: true,
            });
            element = createRd2EditForm(FAKE_CARD_RD2_ID);
            controller = new RD2FormController(element);
            await flushPromises();

            await setupWireMocksForElevate();

            getRecord.emit(rd2WithoutCommitmentCard, (config) => {
                return config.recordId === FAKE_CARD_RD2_ID;
            });
            await flushPromises();

            getRecord.emit(contactGetRecord, (config) => {
                return config.recordId === "001fakeContactId";
            });


            await flushPromises();
        });

        it("open donation, when form loads, change type picklist is empty", async () => {
            const changeTypePicklist = controller.changeTypePicklist();
            expect(changeTypePicklist).toBeTruthy();
            expect(changeTypePicklist.value).toBe("");
        });

        it("open donation, when amount increased, sets change type to upgrade", async () => {
            controller.amount().changeValue(5);
            await flushPromises();
            const changeTypePicklist = controller.changeTypePicklist();
            expect(changeTypePicklist.value).toBe("Upgrade");
        });

        it("open donation, when frequency changed from monthly to weekly, sets change type to upgrade", async () => {
            controller.recurringPeriod().changeValue("Advanced");
            await flushPromises();
            controller.installmentPeriod().changeValue("Weekly");
            await flushPromises();
            const changeTypePicklist = controller.changeTypePicklist();
            expect(changeTypePicklist.value).toBe("Upgrade");
        });

        it("open donation, when amount decreased, sets change type to downgrade", async () => {
            controller.amount().changeValue(0.25);
            await flushPromises();
            const changeTypePicklist = controller.changeTypePicklist();
            expect(changeTypePicklist.value).toBe("Downgrade");
        });

        it("open donation, when amount changed and recurring type changed to fixed, blanks change type picklist", async () => {
            controller.amount().changeValue(5);
            await flushPromises();

            const changeTypePicklist = controller.changeTypePicklist();
            expect(changeTypePicklist.value).toBe("Upgrade");
            controller.recurringType().changeValue("Fixed");
            await flushPromises();

            expect(changeTypePicklist.value).toBe("");
        });
    });

    describe("fixed recurring donation upgrade/downgrade picklist", () => {
        let element;
        let controller;

        beforeEach(async () => {
            getInitialView.mockResolvedValue({
                ...rd2WithoutCommitmentInitialView,
                record: {
                    ...rd2WithoutCommitmentInitialView.record,
                    recurringType: "Fixed",
                    plannedInstallments: 12,
                },
                isChangeLogEnabled: true,
            });
            element = createRd2EditForm(FAKE_CARD_RD2_ID);
            controller = new RD2FormController(element);
            await flushPromises();
            await setupWireMocksForElevate();

            const fields = {
                ...rd2WithoutCommitmentCard.fields,
                RecurringType__c: { value: "Fixed" },
                npe03__Installments__c: { value: 12 },
            };

            getRecord.emit({ ...rd2WithoutCommitmentCard, fields }, (config) => {
                return config.recordId === FAKE_CARD_RD2_ID;
            });
            await flushPromises();

            getRecord.emit(contactGetRecord, (config) => {
                return config.recordId === "001fakeContactId";
            });

            await flushPromises();
        });

        it("fixed donation, when amount increased, sets change type to upgrade", async () => {
            controller.amount().changeValue(5);
            await flushPromises();
            const changeTypePicklist = controller.changeTypePicklist();

            expect(changeTypePicklist.value).toBe("Upgrade");
        });

        it("fixed donation, when number of planned installments decreased, sets change type to downgrade", async () => {
            controller.plannedInstallments().changeValue(6);
            await flushPromises();
            const changeTypePicklist = controller.changeTypePicklist();

            expect(changeTypePicklist.value).toBe("Downgrade");
        });
    });
});

const createRd2EntryForm = () => {
    const element = createElement("c-rd2-entry-form", { is: Rd2EntryForm });
    document.body.appendChild(element);
    return element;
};

const createRd2EditForm = (recordId) => {
    const element = createElement("c-rd2-entry-form", { is: Rd2EntryForm });
    element.recordId = recordId;
    document.body.appendChild(element);
    return element;
};

const generateMockFrom = (recordMock) => {
    return {
        withFieldValue: (field, value) => {
            return {
                ...recordMock,
                fields: {
                    ...recordMock.fields,
                    [field]: { value },
                },
            };
        },
    };
};

const setupIframeReply = () => {
    mockGetIframeReply.mockImplementation((iframe, message, targetOrigin) => {
        const type = "post__npsp";
        const token = "a_dummy_token";
        // if message action is "createToken", reply with dummy token immediately
        // instead of trying to hook into postMessage
        // see sendIframeMessage in mocked psElevateTokenHandler
        if (message.action === "createToken" || message.action === "createAchToken") {
            return { type, token };
        }

        if (message.action === "setPaymentMethod") {
            return { type };
        }
    });
};

const setupCommitmentResponse = (responseBody) => {
    const response = {
        statusCode: 200,
        status: "OK",
        body: JSON.stringify(responseBody),
    };
    handleCommitment.mockResolvedValue(JSON.stringify(response));
};

const validateCommitmentMessage = (expectedParams) => {
    expect(handleCommitment).toHaveBeenCalled();
    const { jsonRecord, paymentMethodToken } = handleCommitment.mock.calls[0][0];
    const deserialized = JSON.parse(jsonRecord);
    expect(deserialized).toMatchObject(expectedParams);
    expect(paymentMethodToken).toBe("a_dummy_token");
};

const validateIframeMessage = (tokenizeMockCall, expectedParams) => {
    expect(mockGetIframeReply).toHaveBeenCalled();
    const tokenizeMessage = tokenizeMockCall[1];
    const serializedParams = tokenizeMessage.params;
    const deserializedParams = JSON.parse(serializedParams);
    expect(deserializedParams).toMatchObject(expectedParams);

    expect(mockGetIframeReply).toHaveBeenCalledWith(
        expect.any(HTMLIFrameElement), // iframe
        expect.objectContaining({
            action: "createAchToken",
            params: expect.any(String),
        }),
        undefined
    );
};
