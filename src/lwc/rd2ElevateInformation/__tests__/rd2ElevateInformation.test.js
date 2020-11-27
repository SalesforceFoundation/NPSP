import { createElement } from 'lwc';
import rd2ElevateInformation from 'c/rd2ElevateInformation';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

import getData from "@salesforce/apex/RD2_ElevateInformation_CTRL.getData";

jest.mock(
    "@salesforce/apex/RD2_ElevateInformation_CTRL.getData",
    () => {
        return {
            default: jest.fn(),
        };
    },
    { virtual: true }
);

import { registerLdsTestWireAdapter } from '@salesforce/sfdx-lwc-jest';

const getObjectInfoAdapter = registerLdsTestWireAdapter(getObjectInfo);
const getRecordAdapter = registerLdsTestWireAdapter(getRecord);

const mockGetObjectInfo = require("./data/getObjectInfo.json");
const mockGetRecord = require("./data/getRecord.json");
const mockGetData = require("./data/getData.json");


describe('c-rd2-elevate-information', () => {
    let component;

    beforeEach(() => {
        component = createElement("c-rd2-elevate-information", {
            is: rd2ElevateInformation,
        });

        getObjectInfoAdapter.emit(mockGetObjectInfo);
    });

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    it("should display header", () => {
        document.body.appendChild(component);

        const header = component.shadowRoot.querySelector("h2");
        expect(header).not.toBe(null);
        expect(header.textContent).toBe("c.RD2_ElevateInformationHeader");
    });

    describe("on no errors data load", () => {
        beforeEach(() => {
            component.recordId = mockGetRecord.id;

            getData.mockResolvedValue(mockGetData);
            getRecordAdapter.emit(mockGetRecord);
        });

        it('should display success icon and message', async () => {
            document.body.appendChild(component);

            return global.flushPromises().then(async () => {
                const icon = component.shadowRoot.querySelector("[data-qa-locator='icon Status']");
                expect(icon).not.toBe(null);
                expect(icon.iconName).toBe("utility:success");

                const message = component.shadowRoot.querySelector("[data-qa-locator='text Status Message']");
                expect(message).not.toBe(null);
                expect(message.value).toBe("c.RD2_ElevateInformationStatusSuccess");
            });
        });

        it('should display Elevate Recurring Id', async () => {
            document.body.appendChild(component);

            return global.flushPromises().then(async () => {
                const elevateId = component.shadowRoot.querySelector("[data-qa-locator='text Elevate Recurring Id']");
                expect(elevateId).not.toBe(null);
                expect(elevateId.value).toBe(mockGetRecord.fields["CommitmentId__c"].value);
            });
        });

        it('should display View Error Log button', async () => {
            document.body.appendChild(component);

            return global.flushPromises().then(async () => {
                const errorLogButton = component.shadowRoot.querySelector("lightning-button");
                expect(errorLogButton).not.toBe(null);
                expect(errorLogButton.label).toBe("c.commonViewErrorLog");
            });
        });
    });

});