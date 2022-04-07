import { nextState } from "../model.js";
import { ACTIONS, Rd2Service, RECURRING_TYPE_FIXED, RECURRING_TYPE_OPEN } from "c/rd2Service";
import { SET_CAMPAIGN_ID, SET_PLANNED_INSTALLMENTS, SET_RECURRING_TYPE } from "../actions";

const initialView = require("../../../../../../tests/__mocks__/apex/data/getInitialView.json");

describe("rd2 model", () => {
    let rd2State;

    beforeEach(() => {
        rd2State = nextState();
    });

    it("has a default initial state", () => {
        expect(rd2State.recurringFrequency).toBe(1);
        expect(rd2State.isElevateCustomer).toBe(false);
        expect(rd2State.donorType).toBe('Contact');
    });

    it("loads an initial view", () => {
        rd2State = nextState(rd2State, {
            type: ACTIONS.INITIAL_VIEW_LOAD,
            payload: initialView
        });
        expect(rd2State.contactId).toBe("fake-contact-record-id");
    });

    it("updates custom fields", () => {
        const viewWithCustomFields = {
            ...initialView,
            customFieldSets: [
                {
                    apiName: 'Some_Field__c',
                    value: null,
                    required: false
                },
                {
                    apiName: 'Other_Field__c',
                    value: null,
                    required: false
                }
            ]
        };
        rd2State = nextState(rd2State, {
            type: ACTIONS.INITIAL_VIEW_LOAD,
            payload: viewWithCustomFields
        });

        rd2State = nextState(rd2State, {
            type: ACTIONS.CUSTOM_FIELD_CHANGE,
            payload: {
                fieldName: 'Some_Field__c',
                value: 'SOME_FAKE_VAL'
            }
        });

        const { customFieldSets } = rd2State;
        expect(customFieldSets).toHaveLength(2);
        const [someField, otherField] = customFieldSets;
        expect(someField.value).toBe('SOME_FAKE_VAL');
        expect(otherField.value).toBe(null);
    });

    it("open recurring donation, on save, does not include planned installments", () => {
        const rd2Service = new Rd2Service();
        const NUMBER_OF_INSTALLMENTS = 12;

        rd2State = nextState(rd2State, {
            type: SET_PLANNED_INSTALLMENTS,
            payload: NUMBER_OF_INSTALLMENTS
        });

        rd2State = nextState(rd2State, {
            type: SET_RECURRING_TYPE,
            payload: RECURRING_TYPE_OPEN
        });

        expect(rd2State.plannedInstallments).toBe(12);
        const saveRequest = rd2Service.getSaveRequest(rd2State);
        expect(saveRequest.plannedInstallments).toBe(null);
    });

    it("fixed recurring donation, on save, includes number of planned installments", () => {
        const rd2Service = new Rd2Service();
        const NUMBER_OF_INSTALLMENTS = 12;
        rd2State = nextState(rd2State, {
            type: SET_PLANNED_INSTALLMENTS,
            payload: NUMBER_OF_INSTALLMENTS
        });

        rd2State = nextState(rd2State, {
            type: SET_RECURRING_TYPE,
            payload: RECURRING_TYPE_FIXED
        });

        expect(rd2State.plannedInstallments).toBe(NUMBER_OF_INSTALLMENTS);
        const saveRequest = rd2Service.getSaveRequest(rd2State);
        expect(saveRequest.plannedInstallments).toBe(NUMBER_OF_INSTALLMENTS);
    });

    it("when campaign id is set to an empty string, it is coerced to null in state", () => {
        rd2State = nextState(rd2State, {
            type: SET_CAMPAIGN_ID,
            payload: ''
        });

        expect(rd2State.campaignId).toBe(null);
    });

    it("when campaign id is set to non-empty string, it is persisted in state", () => {
        const SOME_FAKE_CAMPAIGN_ID = 'SOME_FAKE_CAMPAIGN_ID'
        rd2State = nextState(rd2State, {
            type: SET_CAMPAIGN_ID,
            payload: SOME_FAKE_CAMPAIGN_ID
        });

        expect(rd2State.campaignId).toBe(SOME_FAKE_CAMPAIGN_ID);
    });
});

