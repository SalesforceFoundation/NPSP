import { createElement } from "lwc";
import RelationshipsTable from "c/relationshipsTable";
import { getRecord } from 'lightning/uiRecordApi';
import getRelationships from "@salesforce/apex/REL_RelationshipsViewer_CTRL.getRelationships";

const mockGetRelationships = require("./data/mockGetRelationships.json");

jest.mock(
    '@salesforce/apex/REL_RelationshipsViewer_CTRL.getRelationships',
    () => {
      const {
        createApexTestWireAdapter
      } = require('@salesforce/sfdx-lwc-jest');
      return {
        default: createApexTestWireAdapter(jest.fn())
      };
    },
    { virtual: true }
);

describe("c-relationships-table", () => {
  afterEach(() => {
    clearDOM();
  });

  it("loads with a list of relationships", async () => {
    const element = createElement("c-relationships-table", { is: RelationshipsTable });
    element.contactId = '003_FAKE_CONTACT_ID';
    document.body.appendChild(element);
    getRelationships.emit(mockGetRelationships);
    await flushPromises();

    expect(element).toMatchSnapshot();
  });

  it("fires event for loading additional relationships", () => {

  });

  it("navigates to a contact detail page", () => {

  });
});