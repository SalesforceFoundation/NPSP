import { createElement } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import RelationshipsNavigator from "c/relationshipsNavigator";
import getInitialView from "@salesforce/apex/RelationshipsTreeGridController.getInitialView";

const mockGetInitialView = require("../../relationshipsTreeGrid/__tests__/data/mockGetInitialView.json");
const FAKE_CONTACT_ID = "003_FAKE_CONTACT_ID";
const FAKE_CONTACT_NAME = "FakeFirstName FakeLastName";
const mockGetRecord = {
    apiName: "Contact",
    childRelationships: {},
    id: FAKE_CONTACT_ID,
    recordTypeInfo: null,
    fields: {
        Name: {
            displayValue: null,
            value: FAKE_CONTACT_NAME,
        },
    },
};

jest.mock(
    "@salesforce/apex/RelationshipsTreeGridController.getInitialView",
    () => {
        return { default: jest.fn() };
    },
    { virtual: true }
);

describe("c-relationships-navigator", () => {
    beforeEach(() => {
        getInitialView.mockResolvedValue(mockGetInitialView);
    });

    afterEach(() => {
        clearDOM();
    });

    it("loads a card with a contact name", async () => {
        const element = createElement("c-relationships-navigator", { is: RelationshipsNavigator });
        element.recordId = FAKE_CONTACT_ID;

        document.body.appendChild(element);
        await flushPromises();

        getRecord.emit(mockGetRecord, (config) => {
            return config.recordId === FAKE_CONTACT_ID;
        });
        await flushPromises();

        const cardCmp = element.shadowRoot.querySelector("lightning-card");
        expect(cardCmp.title).toBe(FAKE_CONTACT_NAME);
    });

    it("displays an error when user does not have access", async () => {
        const errorMessage = {
            status: 500,
            body: {
                message: "Insufficient Permissions",
            },
        };
        getInitialView.mockRejectedValue(errorMessage);

        const element = createElement("c-relationships-navigator", { is: RelationshipsNavigator });
        element.recordId = FAKE_CONTACT_ID;
        document.body.appendChild(element);
        getRecord.emit(mockGetRecord, (config) => config.recordId === FAKE_CONTACT_ID);
        await flushPromises();

        const errorMessageCmp = element.shadowRoot.querySelector("c-util-illustration");
        expect(errorMessageCmp).toBeTruthy();
    });

    it("passes isLightningOut value down to tree grid component", async () => {
        const element = createElement("c-relationships-navigator", { is: RelationshipsNavigator });
        element.recordId = FAKE_CONTACT_ID;
        element.isLightningOut = true;

        document.body.appendChild(element);

        const treeGrid = element.shadowRoot.querySelector("c-relationships-tree-grid");
        expect(treeGrid).toBeTruthy();
        expect(treeGrid.isLightningOut).toBe(true);
    });
});
