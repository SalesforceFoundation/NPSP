import { createElement } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import RelationshipsNavigator from "c/relationshipsNavigator";
import getRelationships from "@salesforce/apex/REL_RelationshipsViewer_CTRL.getRelationships";

const mockGetRelationships = require("../../relationshipsTreeGrid/__tests__/data/mockGetRelationships.json");
const FAKE_CONTACT_ID = "003_FAKE_CONTACT_ID";

const mockGetRecord = {
    "apiName": "Contact",
    "childRelationships": {},
    "id": FAKE_CONTACT_ID,
    "recordTypeInfo": null,
    "fields": {
        "Name": {
            "displayValue": null,
            "value": "FakeFirstName FakeLastName"
        }
    }
};

jest.mock("@salesforce/apex/REL_RelationshipsViewer_CTRL.getRelationships",
    () => {
        return { default: jest.fn() };
    }, { virtual: true });

describe("c-relationships-navigator", () => {
    beforeEach(() => {
        getRelationships.mockResolvedValue(mockGetRelationships);
    });

    afterEach(() => {
        clearDOM();
    });

    it("loads a card with a contact name", async () => {
        const element = createElement("c-relationships-navigator", { is: RelationshipsNavigator });
        element.recordId = FAKE_CONTACT_ID;
        document.body.appendChild(element);
        getRecord.emit(mockGetRecord, config => config.recordId === FAKE_CONTACT_ID);
    });

    it("displays an error when user does not have access", async () => {
        const errorMessage = {
            "status": 500,
            "body": {
                "message": "Insufficient Permissions"
            }
        };
        getRelationships.mockRejectedValue(errorMessage);

        const element = createElement("c-relationships-navigator", { is: RelationshipsNavigator });
        element.recordId = FAKE_CONTACT_ID;
        document.body.appendChild(element);
        getRecord.emit(mockGetRecord, config => config.recordId === FAKE_CONTACT_ID);
        await flushPromises();

        const errorMessageCmp = element.shadowRoot.querySelector('c-util-illustration');
        expect(errorMessageCmp).toBeTruthy();
    });

});