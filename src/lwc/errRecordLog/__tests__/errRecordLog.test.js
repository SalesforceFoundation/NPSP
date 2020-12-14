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
const mockGetDataErrorLogs = require('./data/getDataErrorLogs.json');

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
    * @description Verifies Error Log page elements for the specified record
    */
    describe('on data load', () => {

        beforeEach(() => {
            component.recordId = RECORD_ID;
            getData.mockResolvedValue(mockGetData);

            document.body.appendChild(component);
        });

        /***
        * @description Verifies record detail page is displayed when 
        * user clicks on the record name breadcrumb
        */
        it("should navigate to the record detail page", async () => {
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

        it('should display error log datatable summary', async () => {
            return global.flushPromises().then(async () => {
                const summary = getElement(component, "text Summary");

                expect(summary).not.toBeNull();
                expect(summary.textContent).toBe("c.geTextListViewItemsCount c.geTextListViewSortedBy");
            });
        });

        it('should display no item message when record has no error logs', async () => {
            return global.flushPromises().then(async () => {
                const message = getElement(component, "text No Items Message");

                expect(message).not.toBeNull();
                expect(message.value).toBe("c.commonNoItems");
            });
        });

        it("should be accessible", async () => {
            return global.flushPromises().then(async () => {
                await expect(component).toBeAccessible();
            });
        });
    });


    /***
    * @description Verifies Error Log page elements when
    * the specified record has error logs
    */
    describe('on datatable displaying error logs', () => {

        beforeEach(() => {
            component.recordId = RECORD_ID;
            getData.mockResolvedValue(mockGetDataErrorLogs);

            document.body.appendChild(component);
        });

        it('should not display no item message', async () => {
            return global.flushPromises().then(async () => {
                const message = getElement(component, "text No Items Message");

                expect(message).toBeNull();
            });
        });

        it('should display error logs', async () => {
            return global.flushPromises().then(async () => {
                const datatable = getElement(component, "datatable Logs");
                expect(datatable).not.toBeNull();

                expect(datatable.columns.length).toBe(4);
                expect(datatable.columns[0].fieldName).toBe("logURL");
                expect(datatable.columns[0].type).toBe("url");
                expect(datatable.columns[0].label).toBe(
                    mockGetObjectInfo.fields["Name"].label
                );

                expect(datatable.data.length).toBe(1);
                expect(datatable.data[0].Name).not.toBeNull();
                expect(datatable.data[0].Name).toBe(
                    mockGetDataErrorLogs.data[0].Name
                );
            });
        });

        it("should be accessible", async () => {
            return global.flushPromises().then(async () => {
                await expect(component).toBeAccessible();
            });
        });
    });


    /***
    * @description Verifies No Access illustration is displayed when
    * user has no read access on the record SObject or Error SObject
    */
    describe('on no access', () => {

        beforeEach(() => {
            component.recordId = RECORD_ID;

            let mockGetDataNoAccess = JSON.parse(JSON.stringify(mockGetData));
            mockGetDataNoAccess.hasAccess = false;

            getData.mockResolvedValue(mockGetDataNoAccess);

            document.body.appendChild(component);
        });

        it('should display No Access illustration', async () => {
            return global.flushPromises().then(async () => {
                const illustration = getElement(component, "illustration NoAccess");
                expect(illustration).not.toBeNull();

                expect(illustration.title).toBe('c.commonInsufficientPermissions');
                expect(illustration.message).toBe('c.addrCopyConAddBtnFls');
            });
        });

        it("should be accessible", async () => {
            return global.flushPromises().then(async () => {
                await expect(component).toBeAccessible();
            });
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
