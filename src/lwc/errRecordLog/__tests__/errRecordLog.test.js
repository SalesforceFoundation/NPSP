import { createElement } from 'lwc';
import errRecordLog from 'c/errRecordLog';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getNavigateCalledWith } from "lightning/navigation";
import { registerSa11yMatcher } from '@sa11y/jest';

import getData from '@salesforce/apex/ERR_Log_CTRL.getData';
jest.mock(
    '@salesforce/apex/ERR_Log_CTRL.getData',
    () => {
        return {
            default: jest.fn(),
        };
    },
    { virtual: true }
);

import { registerLdsTestWireAdapter } from '@salesforce/sfdx-lwc-jest';

const getObjectInfoAdapter = registerLdsTestWireAdapter(getObjectInfo);

const mockGetObjectInfo = require('./data/getObjectInfo.json');
const mockGetData = require('./data/getData.json');

const RECORD_ID = "a0900000008MR9bQAG";


describe('c-err-record-log', () => {
    let component;

    beforeAll(() => {
        registerSa11yMatcher();
    });

    beforeEach(() => {
        component = createElement('c-err-record-log', {
            is: errRecordLog,
        });

        getObjectInfoAdapter.emit(mockGetObjectInfo);
    });

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    /***
    * @description Verifies header is always displayed on the page
    */
    it('should display header', () => {
        document.body.appendChild(component);

        const header = component.shadowRoot.querySelector('h1');
        expect(header).not.toBeNull();
        expect(header.textContent).toBe('c.ERR_RecordLogTitle');
    });

    /***
    * @description Verifies record detail page is displayed when 
    * user clicks on the record name breadcrumb URL
    */
    it("should navigate to the record detail page", async () => {
        component.recordId = RECORD_ID;
        getData.mockResolvedValue(mockGetData);

        document.body.appendChild(component);

        return global.flushPromises()
            .then(async () => {
                const recordViewPageLink = getRecordViewPage(component);
                expect(recordViewPageLink).not.toBeNull();

                recordViewPageLink.dispatchEvent(
                    new CustomEvent('click')
                );
            })
            .then(async () => {
                const { pageReference } = getNavigateCalledWith();

                expect(pageReference.type).toBe("standard__recordPage");
                expect(pageReference.attributes.recordId).toBe(component.recordId);
                expect(pageReference.attributes.actionName).toBe("view");
            });
    });

});



// Helpers
//////////////


/***
* @description Finds and returns record detail page breadcrumb link
*/
const getRecordViewPage = (component) => {
    const breadcrumb = component.shadowRoot.querySelector('[data-qa-locator="breadcrumb Record View Page"]');

    return breadcrumb;
}
