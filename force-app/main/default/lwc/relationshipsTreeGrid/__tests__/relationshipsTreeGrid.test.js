import { createElement } from "lwc";
import RelationshipsTreeGrid from "c/relationshipsTreeGrid";
import getInitialView from "@salesforce/apex/RelationshipsTreeGridController.getInitialView";
import getRelationships from "@salesforce/apex/RelationshipsTreeGridController.getRelationships";

const mockGetInitialView = require("./data/mockGetInitialView.json");
const mockGetRelationships = require("./data/mockGetRelationships.json");

jest.mock(
    "@salesforce/apex/RelationshipsTreeGridController.getRelationships",
    () => {
        return {
            default: jest.fn(),
        };
    },
    { virtual: true }
);

jest.mock(
    "@salesforce/apex/RelationshipsTreeGridController.getInitialView",
    () => {
        return {
            default: jest.fn(),
        };
    },
    { virtual: true }
);

describe("c-relationships-tree-grid", () => {
    afterEach(() => {
        clearDOM();
    });

    it("loads with a list of relationships", async () => {
        getInitialView.mockResolvedValue(mockGetInitialView);
        const element = createElement("c-relationships-tree-grid", { is: RelationshipsTreeGrid });
        element.contactId = "003_FAKE_CONTACT_ID";
        document.body.appendChild(element);
        await flushPromises();

        const treeGrid = element.shadowRoot.querySelector("lightning-tree-grid");
        expect(treeGrid.data).toHaveLength(6);
    });

    it("populates column labels from initial view", async () => {
        getInitialView.mockResolvedValue(mockGetInitialView);
        const element = createElement("c-relationships-tree-grid", { is: RelationshipsTreeGrid });
        element.contactId = "003_FAKE_CONTACT_ID";
        document.body.appendChild(element);
        await flushPromises();

        const treeGrid = element.shadowRoot.querySelector("lightning-tree-grid");
        expect(treeGrid.columns[0].label).toBe(mockGetInitialView.labels["contactName"]);
        expect(treeGrid.columns[1].label).toBe(mockGetInitialView.labels["title"]);
        expect(treeGrid.columns[2].label).toBe(mockGetInitialView.labels["accountName"]);
        expect(treeGrid.columns[3].label).toBe(mockGetInitialView.labels["relationshipExplanation"]);
    });

    it("hides create new relationship action if no create access", async () => {
        mockGetInitialView.showCreateRelationshipButton = false;
        getInitialView.mockResolvedValue(mockGetInitialView);
        const element = createElement("c-relationships-tree-grid", { is: RelationshipsTreeGrid });
        element.contactId = "003_FAKE_CONTACT_ID";
        document.body.appendChild(element);
        await flushPromises();

        const treeGrid = element.shadowRoot.querySelector("lightning-tree-grid");
        expect(treeGrid.columns[4].type).toBe("action");
        const { rowActions } = treeGrid.columns[4].typeAttributes;
        expect(rowActions.length).toBe(2);
        expect(rowActions[0].name).toBe("view_record");
        expect(rowActions[1].name).toBe("re_center");
    });

    it("loads additional relationships on expand of row", () => {});

    it("if same contact in table twice then only loads children for one", () => {});

    it("when loading child rows, does not load any relationship already present in other row", () => {});

    describe("lex specific behavior", () => {
        it("navigates to contact detail page", () => {});

        it("re-centers on contact", () => {});

        it("opens new relationship window for contact", () => {});
    });

    describe("lighting out specific behavior", () => {
        it("navigates to contact detail page", () => {});

        it("re-centers on contact", () => {});

        it("opens new relationship window for contact", () => {});
    });
});
