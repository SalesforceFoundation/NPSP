import { createElement } from "lwc";
import RelationshipsTable from "c/relationshipsTable";
import { getRecord } from 'lightning/uiRecordApi';
import getRelationships from "@salesforce/apex/REL_RelationshipsViewer_CTRL.getRelationships";

const mockGetRelationships = require("./data/mockGetRelationships.json");
const mockGetContactRecord = require("./data/mockGetContactRecord.json");

jest.mock("@salesforce/apex/REL_RelationshipsViewer_CTRL.getRelationships",
  () => {
    return {
      default: jest.fn()
    };
  },
  { virtual: true }
);

describe("c-relationships-table", () => {
  afterEach(() => {
    clearDOM();
  });

  it("loads with a list of relationships", () => {
    const element = createElement("c-relationships-table", { is: RelationshipsTable });

    document.body.appendChild(element);
    getRelationships.emit(mockGetRelationships);
    getRecord.emit(mockContactRecord);
  });

  it("fires event for loading additional relationships", () => {

  });

  it("navigates to a contact detail page", () => {

  });
});