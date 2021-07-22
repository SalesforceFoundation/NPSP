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



const mockGetObjectInfo = require('./data/getObjectInfo.json');
const mockGetData = require('./data/getData.json');
const mockGetDataErrorLogs = require('./data/getDataErrorLogs.json');

const RECORD_ID = "a0900000008MR9bQAG";
const QA_LOCATOR_RECORD_VIEW_PAGE = "breadcrumb Record View Page";
const QA_LOCATOR_RECORD_SOBJECT_PAGE = "breadcrumb Record SObject Page";
const QA_LOCATOR_NO_ITEM_MESSAGE = "text No Items Message";
const QA_LOCATOR_DATATABLE = "datatable Logs";
const QA_LOCATOR_NO_ACCESS_ILLUSTRATION = "illustration NoAccess";


describe('c-err-record-log', () => {
    let component;

    beforeAll(() => {
        registerSa11yMatcher();
    });

    beforeEach(() => {
        component = createElement('c-err-record-log', {
            is: errRecordLog,
        });

        getObjectInfo.emit(mockGetObjectInfo);
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
    * @description Verifies Error Log page elements when the record Id is specified
    */
    describe('on page render', () => {

        beforeEach(() => {
            component.recordId = RECORD_ID;
            getData.mockResolvedValue(mockGetData);

            document.body.appendChild(component);
        });

        it("should navigate to the record view page", async () => {
            return global.flushPromises()
                .then(async () => {
                    const recordViewBreadcrumb = getElement(component, QA_LOCATOR_RECORD_VIEW_PAGE);
                    expect(recordViewBreadcrumb).not.toBeNull();
                    expect(recordViewBreadcrumb.label).toBe(mockGetData.recordName);

                    click(recordViewBreadcrumb);
                })
                .then(async () => {
                    const { pageReference } = getNavigateCalledWith();

                    expect(pageReference.type).toBe("standard__recordPage");
                    expect(pageReference.attributes.recordId).toBe(component.recordId);
                    expect(pageReference.attributes.actionName).toBe("view");
                });
        });

        it("should navigate to the record SObject page", async () => {
            return global.flushPromises()
                .then(async () => {
                    const recordSObjectBreadcrumb = getElement(component, QA_LOCATOR_RECORD_SOBJECT_PAGE);
                    expect(recordSObjectBreadcrumb).not.toBeNull();
                    expect(recordSObjectBreadcrumb.label).toBe(mockGetData.sObjectLabelPlural);

                    click(recordSObjectBreadcrumb);
                })
                .then(async () => {
                    const { pageReference } = getNavigateCalledWith();

                    expect(pageReference.type).toBe("standard__objectPage");
                    expect(pageReference.attributes.objectApiName).toBe(mockGetData.sObjectType);
                    expect(pageReference.attributes.actionName).toBe("list");
                });
        });

        it('should display error log data summary', async () => {
            return global.flushPromises().then(async () => {
                const summary = getElement(component, "text Summary");

                expect(summary).not.toBeNull();
                expect(summary.textContent).toBe("c.geTextListViewItemsCount c.geTextListViewSortedBy");
            });
        });

        it('should display no item message when record has no error logs', async () => {
            return global.flushPromises().then(async () => {
                const message = getElement(component, QA_LOCATOR_NO_ITEM_MESSAGE);

                expect(message).not.toBeNull();
                expect(message.value).toBe("c.commonNoItems");
            });
        });

        it('should not display No Access illustration', async () => {
            return global.flushPromises().then(async () => {
                const illustration = getElement(component, QA_LOCATOR_NO_ACCESS_ILLUSTRATION);
                expect(illustration).toBeNull();
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
    describe('on page displaying error logs', () => {
        const numberOfColumns = 4;
        const numberOfRows = 2;

        beforeEach(() => {
            component.recordId = RECORD_ID;
            getData.mockResolvedValue(mockGetDataErrorLogs);

            document.body.appendChild(component);
        });

        it('should not display no item message', async () => {
            return global.flushPromises().then(async () => {
                const message = getElement(component, QA_LOCATOR_NO_ITEM_MESSAGE);

                expect(message).toBeNull();
            });
        });

        it('should display error logs', async () => {
            return global.flushPromises().then(async () => {
                const datatable = getElement(component, QA_LOCATOR_DATATABLE);
                expect(datatable).not.toBeNull();

                expect(datatable.columns.length).toBe(numberOfColumns);
                expect(datatable.columns[0].fieldName).toBe("logURL");
                expect(datatable.columns[0].type).toBe("url");
                expect(datatable.columns[0].label).toBe(
                    mockGetObjectInfo.fields["Name"].label
                );

                expect(datatable.data.length).toBe(numberOfRows);
                expect(datatable.data[0].Name).not.toBeNull();
                expect(datatable.data[0].Name).toBe(
                    mockGetDataErrorLogs.data[0].Name
                );
            });
        });

        it('should sort error logs', async () => {
            return global.flushPromises()
                .then(async () => {
                    const datatable = getElement(component, QA_LOCATOR_DATATABLE);
                    expect(datatable).not.toBeNull();

                    expect(datatable.data[0].Name).toBe(
                        mockGetDataErrorLogs.data[0].Name
                    );

                    datatable.dispatchEvent(
                        new CustomEvent("sort", {
                            detail: {
                                fieldName: mockGetObjectInfo.fields["Datetime__c"].apiName,
                                sortDirection: "asc",
                            },
                        })
                    );
                })
                .then(async () => {
                    const datatable = getElement(component, QA_LOCATOR_DATATABLE);

                    expect(datatable.data[0].Name).toBe(
                        mockGetDataErrorLogs.data[1].Name
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
    describe('on insufficient permissions', () => {

        beforeEach(() => {
            component.recordId = RECORD_ID;

            let mockGetDataNoAccess = JSON.parse(JSON.stringify(mockGetData));
            mockGetDataNoAccess.hasAccess = false;

            getData.mockResolvedValue(mockGetDataNoAccess);

            document.body.appendChild(component);
        });

        it('should display No Access illustration', async () => {
            return global.flushPromises().then(async () => {
                const illustration = getElement(component, QA_LOCATOR_NO_ACCESS_ILLUSTRATION);
                expect(illustration).not.toBeNull();

                expect(illustration.heading).toBe('c.commonInsufficientPermissions');
                expect(illustration.message).toBe('c.addrCopyConAddBtnFls');
            });
        });

        it("should not display record SObject and view page breadcrumbs", async () => {
            return global.flushPromises()
                .then(async () => {
                    const recordViewBreadcrumb = getElement(component, QA_LOCATOR_RECORD_VIEW_PAGE);
                    expect(recordViewBreadcrumb).toBeNull();

                    const recordSObjectBreadcrumb = getElement(component, QA_LOCATOR_RECORD_SOBJECT_PAGE);
                    expect(recordSObjectBreadcrumb).toBeNull();
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
    const element = component.shadowRoot.querySelector('[data-qa-locator="' + qaLocator + '"]');

    return element;
}

/***
* @description Dispatch event when user clicks on the element
*/
const click = (element) => {
    element.dispatchEvent(
        new CustomEvent('click')
    );
}
