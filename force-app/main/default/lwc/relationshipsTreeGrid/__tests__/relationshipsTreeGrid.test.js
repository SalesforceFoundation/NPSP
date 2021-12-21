import { createElement } from "lwc";
import RelationshipsTreeGrid from "c/relationshipsTreeGrid";
import getInitialView from "@salesforce/apex/RelationshipsTreeGridController.getInitialView";
import getRelationships from "@salesforce/apex/RelationshipsTreeGridController.getRelationships";
import { getNavigateCalledWith } from "lightning/navigation";

import REL_No_Relationships from "@salesforce/label/c.REL_No_Relationships";

const mockGetInitialView = require("./data/mockGetInitialView.json");
const mockGetRelationships = require("./data/mockGetRelationships.json");
const mockExpandRowWithDuplicates = require("./data/mockExpandRowWithDuplicates.json");
const mockExpandRowChildless = require("./data/mockExpandRowChildless.json");

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

const mockWindowOpen = jest.fn();

const createTreeGrid = async (isLightningOut = false) => {
    getInitialView.mockResolvedValue(mockGetInitialView);
    getRelationships.mockResolvedValue(mockGetRelationships);
    const element = createElement("c-relationships-tree-grid", { is: RelationshipsTreeGrid });
    element.contactName = "FakeFirstName FakeLastName";
    element.contactId = "003_FAKE_CONTACT_ID";
    element.isLightningOut = isLightningOut;
    document.body.appendChild(element);
    await flushPromises();
    return element;
};

describe("c-relationships-tree-grid", () => {
    afterEach(() => {
        clearDOM();
    });

    it("loads with a list of relationships", async () => {
        const element = await createTreeGrid();

        const treeGrid = element.shadowRoot.querySelector("lightning-tree-grid");
        expect(treeGrid.data).toHaveLength(6);
    });

    it("displays illustration with message when no relationships found", async () => {
        getInitialView.mockResolvedValueOnce({
            ...mockGetInitialView,
            relations: [],
        });
        const element = await createTreeGrid();

        const illustration = element.shadowRoot.querySelector("c-util-illustration");
        expect(illustration).toBeTruthy();
        expect(illustration.message).toBe(REL_No_Relationships);
    });

    it("has an accessible table title", async () => {
        const element = await createTreeGrid();
        const treeGrid = element.shadowRoot.querySelector("lightning-tree-grid");

        expect(treeGrid.ariaLabel).toBe("Relationships - FakeFirstName FakeLastName");
    });

    it("populates column labels from initial view", async () => {
        const element = await createTreeGrid();

        const treeGrid = element.shadowRoot.querySelector("lightning-tree-grid");
        expect(treeGrid.columns[0].label).toBe(mockGetInitialView.labels["contactName"]);
        expect(treeGrid.columns[1].label).toBe(mockGetInitialView.labels["title"]);
        expect(treeGrid.columns[2].label).toBe(mockGetInitialView.labels["accountName"]);
        expect(treeGrid.columns[3].label).toBe(mockGetInitialView.labels["relationshipExplanation"]);
    });

    it("hides create new relationship action if no create access", async () => {
        getInitialView.mockResolvedValueOnce({
            ...mockGetInitialView,
            showCreateRelationshipButton: false,
        });
        const element = await createTreeGrid();

        const treeGrid = element.shadowRoot.querySelector("lightning-tree-grid");
        expect(treeGrid.columns[4].type).toBe("action");
        const { rowActions } = treeGrid.columns[4].typeAttributes;
        expect(rowActions.length).toBe(1);
        expect(rowActions[0].name).toBe("view_record");
    });

    it("loads additional relationships on expand of row", async () => {
        const element = await createTreeGrid();

        const controller = new TreeGridTestController(element);
        controller.toggleRow(controller.data[2]); //rows 0 and 1 are the same contact, Stephanie

        await flushPromises();

        expect(getRelationships).toHaveBeenCalledWith({ contactId: controller.data[2].contactId });
        const { _children } = controller.data[2];
        expect(_children).toHaveLength(1);
        expect(_children[0].contactId).toBe(mockGetRelationships[0].contactId);
    });

    it("if same contact in table twice then only loads children for one", async () => {
        const element = await createTreeGrid();
        const controller = new TreeGridTestController(element);
        controller.toggleRow(controller.data[0]); //rows 0 and 1 are the same contact, Stephanie

        await flushPromises();

        expect(controller.data[0]._children).toHaveLength(1);
        expect(controller.data[1]._children).toBeFalsy(); // second instance of Stephanie should not have child data
        expect(controller.data[0]._children[0]._children).toHaveLength(0);
    });

    it("when loading child rows, does not load any relationship already present in other row", async () => {
        const element = await createTreeGrid();
        const controller = new TreeGridTestController(element);
        controller.toggleRow(controller.data[2]); //rows 0 and 1 are the same contact, Stephanie

        await flushPromises();

        getRelationships.mockResolvedValueOnce(mockExpandRowWithDuplicates); // first entry is a duplicate

        controller.toggleRow(controller.data[3]);

        await flushPromises();
        expect(controller.data[3]._children).toHaveLength(1);
        expect(controller.data[3]._children[0]).toMatchObject(mockExpandRowWithDuplicates[1]);
        expect(controller.data[3]._children[0]._children).toHaveLength(0);
    });

    it("each contact's relationships may load only once even if that contact appears multiple times in the table", async () => {
        const element = await createTreeGrid();
        const controller = new TreeGridTestController(element);
        controller.toggleRow(controller.data[2]); // load Samuel Harrison's relationships

        await flushPromises();

        getRelationships.mockResolvedValueOnce(mockExpandRowChildless);

        controller.toggleRow(controller.data[1]); // load Stephanie Bailey, who has Samuel as a Relationship

        await flushPromises();

        expect(controller.data[1]._children).toBeTruthy();
        expect(controller.data[1]._children[0]).toMatchObject(mockExpandRowChildless[0]);

        // Samuel will not have a _children property, since his relationships are already loaded
        expect(controller.data[1]._children[0]._children).toBeFalsy();
    });

    describe("lex specific behavior", () => {
        let controller;
        beforeEach(async () => {
            const element = await createTreeGrid();
            controller = new TreeGridTestController(element);
        });

        it("navigates to contact detail page", async () => {
            controller.rowAction({ actionName: "view_record", row: controller.data[0] });
            await flushPromises();
            const navigateArgs = getNavigateCalledWith();

            expect(navigateArgs).toBeTruthy();
            expect(navigateArgs.pageReference.attributes.recordId).toBe(controller.data[0].contactId);
        });

        it("re-center on contact is not present in actions menu", async () => {
            expect(controller.columns[4].type).toBe("action");
            const { rowActions } = controller.columns[4].typeAttributes;
            expect(rowActions.length).toBe(2);
            expect(rowActions[0].name).toBe("view_record");
            expect(rowActions[1].name).toBe("new_relationship");
        });

        it("opens new relationship window for contact", async () => {
            controller.rowAction({ actionName: "new_relationship", row: controller.data[0] });
            await flushPromises();
            const navigateArgs = getNavigateCalledWith();

            expect(navigateArgs).toBeTruthy();
            expect(navigateArgs).toMatchObject({
                pageReference: {
                    attributes: {
                        actionName: "new",
                        objectApiName: "npe4__Relationship__c",
                    },
                    state: {
                        defaultFieldValues: undefined,
                    },
                    type: "standard__objectPage",
                },
            });
        });
    });

    describe("lighting out specific behavior", () => {
        let controller;
        beforeEach(async () => {
            const element = await createTreeGrid(true);
            controller = new TreeGridTestController(element);
            window.open = mockWindowOpen;
        });

        it("navigates to contact detail page", async () => {
            controller.rowAction({ actionName: "view_record", row: controller.data[0] });
            await flushPromises();
            expect(mockWindowOpen).toHaveBeenCalledWith("/" + controller.data[0].contactId);
        });

        it("re-centers on contact", async () => {
            let assignMock = jest.fn();
            Object.defineProperty(window, "location", {
                set: assignMock,
            });

            controller.rowAction({ actionName: "re_center", row: controller.data[0] });
            await flushPromises();

            expect(assignMock).toHaveBeenLastCalledWith(
                "/apex/rel_relationshipsviewer?isdtp=p1&id=" + controller.data[0].contactId
            );
        });

        it("opens new relationship window for contact", async () => {
            controller.rowAction({ actionName: "new_relationship", row: controller.data[0] });
            await flushPromises();

            // encodeDefaultFieldValues is not implemented in JEST, so we cannot test params
            expect(mockWindowOpen).toHaveBeenCalledWith(
                expect.stringContaining("/lightning/o/npe4__Relationship__c/new?defaultFieldValues=")
            );
        });
    });
});

class TreeGridTestController {
    treeGrid;

    constructor(element) {
        this.treeGrid = element.shadowRoot.querySelector("lightning-tree-grid");
    }

    get data() {
        return this.treeGrid.data;
    }

    get columns() {
        return this.treeGrid.columns;
    }

    rowAction({ actionName, row }) {
        this.treeGrid.dispatchEvent(
            new CustomEvent("rowaction", {
                detail: { action: { name: actionName }, row },
            })
        );
    }

    toggleRow(rowData) {
        this.treeGrid.dispatchEvent(
            new CustomEvent("toggle", {
                detail: {
                    row: rowData,
                    hasChildrenContent: rowData._children && rowData._children.length > 0,
                },
            })
        );
    }
}
