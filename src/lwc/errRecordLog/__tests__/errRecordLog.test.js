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
    * user clicks on the record name breadcrumb
    */
    it("should navigate to the record detail page", async () => {
        component.recordId = RECORD_ID;
        getData.mockResolvedValue(mockGetData);

        document.body.appendChild(component);

        return global.flushPromises()
            .then(async () => {
                const recordViewBreadcrumb = getElement(component, "breadcrumb Record View Page");
                expect(recordViewBreadcrumb).not.toBeNull();
                expect(recordViewBreadcrumb.label).toBe(mockGetData.recordName);

                dispatchClickEvent(recordViewBreadcrumb);
            })
            .then(async () => {
                const { pageReference } = getNavigateCalledWith();

                expect(pageReference.type).toBe("standard__recordPage");
                expect(pageReference.attributes.recordId).toBe(component.recordId);
                expect(pageReference.attributes.actionName).toBe("view");
            });
    });

    /***
    * @description Verifies record SObject tab is displayed when 
    * user clicks on the record SObject name breadcrumb
    */
    it("should navigate to the record SObject page", async () => {
        component.recordId = RECORD_ID;
        getData.mockResolvedValue(mockGetData);

        document.body.appendChild(component);

        return global.flushPromises()
            .then(async () => {
                const recordSObjectBreadcrumb = getElement(component, "breadcrumb Record SObject Page");
                expect(recordSObjectBreadcrumb).not.toBeNull();
                expect(recordSObjectBreadcrumb.label).toBe(mockGetData.sObjectLabelPlural);

                dispatchClickEvent(recordSObjectBreadcrumb);
            })
            .then(async () => {
                const { pageReference } = getNavigateCalledWith();

                expect(pageReference.type).toBe("standard__objectPage");
                expect(pageReference.attributes.objectApiName).toBe(mockGetData.sObjectType);
                expect(pageReference.attributes.actionName).toBe("list");
            });
    });

    it('should display datatable summary', async () => {
        component.recordId = RECORD_ID;
        getData.mockResolvedValue(mockGetData);

        document.body.appendChild(component);

        return global.flushPromises().then(async () => {
            const summary = getElement(component, "text Summary");

            expect(summary).not.toBeNull();
            expect(summary.textContent).toBe("c.geTextListViewItemsCount c.geTextListViewSortedBy");
        });
    });

    it('should display no item message when record has no errors', async () => {
        component.recordId = RECORD_ID;
        getData.mockResolvedValue(mockGetData);

        document.body.appendChild(component);

        return global.flushPromises().then(async () => {
            const message = getElement(component, "text No Items Message");

            expect(message).not.toBeNull();
            expect(message.value).toBe("c.commonNoItems");
        });
    });

    it("should be accessible", async () => {
        component.recordId = RECORD_ID;
        getData.mockResolvedValue(mockGetData);

        document.body.appendChild(component);

        return global.flushPromises().then(async () => {
            await expect(component).toBeAccessible();
        });
    });


});



// Helpers
//////////////


/***
* @description Finds and returns element defined by its "data-qa-locator" on the component
*/
const getElement = (component, qaLocator) => {
    const breadcrumb = component.shadowRoot.querySelector('[data-qa-locator="' + qaLocator + '"]');

    return breadcrumb;
}

/***
* @description Mimics user clicking on the element
*/
const dispatchClickEvent = (element) => {
    element.dispatchEvent(
        new CustomEvent('click')
    );
}
