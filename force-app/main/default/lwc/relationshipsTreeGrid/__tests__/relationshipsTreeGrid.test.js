import { createElement } from "lwc";
import RelationshipsTreeGrid from "c/relationshipsTreeGrid";
import getRelationships from "@salesforce/apex/REL_RelationshipsViewer_CTRL.getRelationships";

const mockGetRelationships = require("./data/mockGetRelationships.json");

jest.mock(
    '@salesforce/apex/REL_RelationshipsViewer_CTRL.getRelationships',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

describe("c-relationships-tree-grid", () => {
    afterEach(() => {
        clearDOM();
    });

    it("loads with a list of relationships", async () => {
        getRelationships.mockResolvedValue(mockGetRelationships);
        const element = createElement("c-relationships-tree-grid", { is: RelationshipsTreeGrid });
        element.contactId = '003_FAKE_CONTACT_ID';
        document.body.appendChild(element);
        await flushPromises();

        const treeGrid = element.shadowRoot.querySelector('lightning-tree-grid');
        expect(treeGrid.data).toHaveLength(6);
    });

    it("loads additional relationships on expand of row", () => {

    });

    it("if same contact in table twice then only loads children for one", () => {

    });

    it("when loading child rows, does not load any relationship already present in other row", () => {

    });

    describe("lex specific behavior", () => {
        it("navigates to contact detail page", () => {

        });

        it("re-centers on contact", () => {

        });

        it("opens new relationship window for contact", () => {

        });
    });

    describe("lighting out specific behavior", () => {
        it("navigates to contact detail page", () => {

        });

        it("re-centers on contact", () => {

        });

        it("opens new relationship window for contact", () => {

        });
    })


});