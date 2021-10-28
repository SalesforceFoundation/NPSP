import { createElement } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

import GeBatchGiftEntryTable from 'c/geBatchGiftEntryTable';
import Gift from 'c/geGift';

import retrieveDefaultSGERenderWrapper from '@salesforce/apex/GE_GiftEntryController.retrieveDefaultSGERenderWrapper';
import getDataImportModel from '@salesforce/apex/BGE_DataImportBatchEntry_CTRL.getDataImportModel';

const mockRenderWrapper = require('../../../../../../tests/__mocks__/apex/data/retrieveDefaultSGERenderWrapper.json');
const mockSections = require('./data/sections.json');
const mockLegacyDataImportModel = require('../../../../../../tests/__mocks__/apex/data/legacyDataImportModel.json');
const mockDataImportObjectInfo = require('../../../../../../tests/__mocks__/apex/data/dataImportObjectDescribeInfo.json');
const mockGiftView = require('../../../../../../tests/__mocks__/apex/data/giftView.json');

jest.mock('c/geFormService', () => {
    return {
        getFieldMappingWrapper: jest.fn(() => {
            return require('./data/fieldMapping.json');
        }),
        getInputTypeFromDataType: jest.fn(() => {
            return true;
        }),
        getNumberFormatterByDescribeType: jest.fn(() => {
            return null;
        }),
        getObjectMapping: jest.fn(() => {
            return require('./data/objectMapping.json');
        }),
        importedRecordFieldNames: jest.fn(() => {
            return null;
        }),
        fieldMappingsForImportedRecordFieldName: jest.fn(() => {
            return null;
        }),
        getFieldMappingWrapperFromTarget: jest.fn((targetFieldName) => {
            if (targetFieldName === 'RecordTypeId') {
                return require('./data/recordTypeIdFieldMapping.json');
            }
        }),

    };
});

describe('ge-batch-gift-entry-table', () => {

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    const createBatchTable = () => {
        return createElement('c-ge-batch-gift-entry-table',
            { is: GeBatchGiftEntryTable }
        );
    }

    const setupBatchTableWithData = async (withData = false) => {
        retrieveDefaultSGERenderWrapper.mockResolvedValue(mockRenderWrapper);
        if (withData) {
            getDataImportModel.mockResolvedValue(JSON.stringify(mockLegacyDataImportModel));
        } else {
            getDataImportModel.mockResolvedValue('{"dummyKey":"dummyValue"}');
        }

        await flushPromises();

        const batchTable = createBatchTable();
        batchTable.sections = JSON.parse(mockSections);
        document.body.appendChild(batchTable);
        getObjectInfo.emit(mockDataImportObjectInfo, config => {
            return config.objectApiName.objectApiName === 'DataImport__c';
        });

        return batchTable;
    }

    describe('render behavior', () => {
        it('should render illustration when no data is available', async () => {
            const batchTable = await setupBatchTableWithData(false);
            batchTable.giftBatchState = {
                gifts: []
            };

            await flushPromises();

            const stencilElement = shadowQuerySelector(batchTable, 'c-util-illustration');
            expect(stencilElement).toBeTruthy();
        });

        it('should render title', async () => {
            const batchTable = await setupBatchTableWithData(true);
            batchTable.giftBatchState = {
                gifts: [ new Gift(mockGiftView) ]
            };

            await flushPromises();

            const title = shadowQuerySelector(batchTable, 'h1');
            expect(title).toBeTruthy();
            expect(title.innerHTML).toBe('c.geBatchGiftsHeader');
        });

        it('should render button menu', async () => {
            const batchTable = await setupBatchTableWithData(true);
            batchTable.giftBatchState = {
                gifts: [ new Gift(mockGiftView) ]
            };

            await flushPromises();

            const buttonMenu = shadowQuerySelector(batchTable, 'lightning-button-menu');
            expect(buttonMenu).toBeTruthy();
            const buttomMenuItems = buttonMenu.querySelectorAll('lightning-menu-item');
            expect(buttomMenuItems.length).toBe(1);
        });

        it('should render gift count and total donation amount progress bar', async () => {
            const batchTable = await setupBatchTableWithData(true);
            batchTable.giftBatchState = {
                totalDonationsAmount: 300.25,
                totalGiftsCount: 5,
                expectedCountOfGifts: 10,
                expectedTotalBatchAmount: 500,
                gifts: [ new Gift(mockGiftView) ]
            };
            await flushPromises();

            const progressBars = batchTable.shadowRoot.querySelectorAll('c-util-progress-bar');
            expect(progressBars.length).toBe(2);

            const totalCountsProgressBar = progressBars[0];
            expect(totalCountsProgressBar.title).toBe('c.geBatchGiftsCount');
            expect(totalCountsProgressBar.actualValue).toEqual(5);
            expect(totalCountsProgressBar.expectedValue).toEqual(10);

            const totalAmountProgressBar = progressBars[1];
            expect(totalAmountProgressBar.title).toBe('c.geBatchGiftsTotal');
            expect(totalAmountProgressBar.actualValue).toEqual(300.25);
            expect(totalAmountProgressBar.expectedValue).toEqual(500);
        });

        it('should render lightning datatable', async () => {
            const batchTable = await setupBatchTableWithData(true);
            batchTable.giftBatchState = {
                gifts: [ new Gift(mockGiftView) ]
            };

            await flushPromises();

            const datatable = shadowQuerySelector(batchTable, 'lightning-datatable');
            expect(datatable).toBeTruthy();
        });
    });

});

const getShadowRoot = (element) => {
    if (!element || !element.shadowRoot) {
        const tagName =
            element && element.tagName && element.tagName.toLowerCase();
        throw new Error(
            `Attempting to retrieve the shadow root of '${tagName || element}'
            but no shadowRoot property found`
        );
    }
    return element.shadowRoot;
}

const shadowQuerySelector = (element, selector) => {
    return getShadowRoot(element).querySelector(selector);
}