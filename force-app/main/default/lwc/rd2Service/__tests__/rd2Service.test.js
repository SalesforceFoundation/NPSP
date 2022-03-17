import { nextState } from "../model.js";
import { ACTIONS } from "c/rd2Service";

const initialView = require("../../../../../../tests/__mocks__/apex/data/getInitialView.json");

describe("rd2 model", () => {
    let rd2State;

    beforeEach(() => {
        rd2State = nextState();
    });

    it("has a default initial state", () => {
        expect(rd2State.installmentFrequency).toBe(1);
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
    })
});

