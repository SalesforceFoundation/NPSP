import { createElement } from 'lwc';
import { getNavigateCalledWith } from 'lightning/navigation';

import GeGiftEntryFormApp from 'c/geGiftEntryFormApp';
import * as utilTemplateBuilder from 'c/utilTemplateBuilder';
import retrieveDefaultSGERenderWrapper from '@salesforce/apex/GE_GiftEntryController.retrieveDefaultSGERenderWrapper';
import getAllocationsSettings from '@salesforce/apex/GE_GiftEntryController.getAllocationsSettings';
import checkForElevateCustomer from '@salesforce/apex/GE_GiftEntryController.isElevateCustomer';
import addGiftTo from '@salesforce/apex/GE_GiftEntryController.addGiftTo';
import getDataImportModel from '@salesforce/apex/BGE_DataImportBatchEntry_CTRL.getDataImportModel';
import getGiftBatchView from '@salesforce/apex/GE_GiftEntryController.getGiftBatchView';
import isElevateCustomer from '@salesforce/apex/GE_GiftEntryController.isElevateCustomer';

import DATA_IMPORT_BATCH_OBJECT from '@salesforce/schema/DataImportBatch__c';
const PROCESSING_BATCH_MESSAGE = 'c.geProcessingBatch';

const mockWrapperWithNoNames = require('../../../../../../tests/__mocks__/apex/data/retrieveDefaultSGERenderWrapper.json');
const allocationsSettingsNoDefaultGAU = require('../../../../../../tests/__mocks__/apex/data/allocationsSettingsNoDefaultGAU.json');

const createGeGiftEntryFormApp = () => {
    return createElement('c-ge-gift-entry-form-app',
        { is: GeGiftEntryFormApp }
    );
}

const setupForBatchMode = (giftBatchView) => {
    retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
    getAllocationsSettings.mockResolvedValue(allocationsSettingsNoDefaultGAU);
    getDataImportModel.mockResolvedValue('{"dummyKey":"dummyValue"}');
    getGiftBatchView.mockResolvedValue(giftBatchView);
    isElevateCustomer.mockResolvedValue(true);

    const formApp = createGeGiftEntryFormApp();
    formApp.sObjectName = DATA_IMPORT_BATCH_OBJECT.objectApiName;
    formApp.recordId = 'DUMMY_RECORD_ID';

    document.body.appendChild(formApp);

    return formApp;
}

jest.mock(
    '@salesforce/apex/GE_GiftEntryController.getGiftBatchTotalsBy',
    () => {
        return {
            default: jest.fn(),
        };
    },
    { virtual: true }
);

describe('c-ge-gift-entry-form-app', () => {

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    describe('rendering behavior', () => {
        it('should render processing batch spinner if batch is still processing', async () => {
            const formApp = setupForBatchMode({gifts: [], totals: { TOTAL: 1, PROCESSING: 1 }});

            document.body.appendChild(formApp);

            expect(spinner(formApp)).toBeTruthy();

            await flushPromises();

            expect(spinner(formApp)).toBeTruthy();
            expect(batchProcessingText(formApp).innerHTML).toBe(PROCESSING_BATCH_MESSAGE);
        });

        it('should render batch table in Batch mode', async () => {
            const formApp = setupForBatchMode({gifts: [], totals: { TOTAL: 1 }});
            await flushPromises();

            const batchTable = shadowQuerySelector(formApp, 'c-ge-batch-gift-entry-table');
            expect(batchTable).toBeTruthy();

            const formRenderer = shadowQuerySelector(formApp, 'c-ge-form-renderer');
            expect(formRenderer).toBeTruthy();
        });

        it('should not render batch table in Single mode', async () => {
            retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
            getAllocationsSettings.mockResolvedValue(allocationsSettingsNoDefaultGAU);
            const formApp = createGeGiftEntryFormApp();
            document.body.appendChild(formApp);
            await flushPromises();

            const batchTable = shadowQuerySelector(formApp, 'c-ge-batch-gift-entry-table');
            expect(batchTable).toBeNull();
        });

        it('should render warning modal when batch has expired payment authorizations', async () => {
            retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
            getAllocationsSettings.mockResolvedValue(allocationsSettingsNoDefaultGAU);
            getDataImportModel.mockResolvedValue('{"dummyKey":"dummyValue"}');
            getGiftBatchView.mockResolvedValue({gifts: [], totals: { TOTAL: 1, EXPIRED_PAYMENT: 1, FAILED: 1 }});
            checkForElevateCustomer.mockResolvedValue(true);

            const formApp = createGeGiftEntryFormApp();
            formApp.sObjectName = DATA_IMPORT_BATCH_OBJECT.objectApiName;
            formApp.recordId = 'DUMMY_RECORD_ID';

            document.body.appendChild(formApp);

            const dispatchEventSpy = jest.spyOn(formApp, 'dispatchEvent');
            await flushPromises();

            expect(dispatchEventSpy).toHaveBeenCalled();

            const spiedEventComponentProperties = dispatchEventSpy.mock.calls[0][0].detail.componentProperties;
            expect(spiedEventComponentProperties.variant).toEqual('warning');
            expect(spiedEventComponentProperties.title).toEqual('c.gePaymentAuthExpiredHeader');
            expect(spiedEventComponentProperties.message).toEqual('c.gePaymentAuthExpiredWarningText');
            expect(spiedEventComponentProperties.buttons.length).toEqual(1);

            const spiedEventModalProperties = dispatchEventSpy.mock.calls[0][0].detail.modalProperties;
            expect(spiedEventModalProperties.componentName).toEqual('geModalPrompt');
            expect(spiedEventModalProperties.showCloseButton).toEqual(true);
        });
    });

    describe('event dispatch and handling behavior', () => {
        it('should dispatch edit batch event', async () => {
            const formApp = setupForBatchMode({gifts: [], totals: { TOTAL: 1 }});

            const handler = jest.fn();
            formApp.addEventListener('editbatch', handler);
            await flushPromises();

            const giftBatchHeaderComponent = shadowQuerySelector(formApp, 'c-ge-batch-gift-entry-header');
            expect(giftBatchHeaderComponent).toBeTruthy();

            giftBatchHeaderComponent.dispatchEvent(new CustomEvent('edit'));
            expect(handler).toHaveBeenCalled();
        });

        it('should dispatch toggle modal event', async () => {
            const formApp = setupForBatchMode();

            const handler = jest.fn();
            formApp.addEventListener('togglemodal', handler);
            await flushPromises();

            const geFormRenderer = shadowQuerySelector(formApp, 'c-ge-form-renderer');
            expect(geFormRenderer).toBeTruthy();

            geFormRenderer.dispatchEvent(new CustomEvent('togglemodal'));
            expect(handler).toHaveBeenCalled();
        });
    });

    describe('navigation behavior', () => {
        it('should navigate to record detail page', async () => {
            const formApp = setupForBatchMode({gifts: [], totals: { TOTAL: 1 }});
            const handler = jest.fn();
            formApp.addEventListener('navigate', handler);
            await flushPromises();

            const geFormRenderer = shadowQuerySelector(formApp, 'c-ge-form-renderer');
            const navigateEvent = new CustomEvent('navigate', {
                detail: {
                    to: 'recordPage',
                    recordId: 'DUMMY_ID'
                }
            });
            geFormRenderer.dispatchEvent(navigateEvent);

            const { pageReference } = getNavigateCalledWith();
            expect(pageReference.type).toBe('standard__recordPage');
            expect(pageReference.attributes.recordId).toBe('DUMMY_ID');
        });

        it('should navigate to Gift Entry landing page', async () => {
            const formApp = setupForBatchMode({gifts: [], totals: { TOTAL: 1 }});
            const handler = jest.fn();
            formApp.addEventListener('navigate', handler);
            await flushPromises();

            const geFormRenderer = shadowQuerySelector(formApp, 'c-ge-form-renderer');
            const navigateEvent = new CustomEvent('navigate', {
                detail: {
                    to: 'landingPage'
                }
            });
            geFormRenderer.dispatchEvent(navigateEvent);

            const { pageReference } = getNavigateCalledWith();

            expect(pageReference.type).toBe('standard__webPage');
            expect(pageReference.attributes.url).toContain('GE_Gift_Entry');
        });
    });

    describe('save, update, and delete behavior', () => {
        it('should call addGiftTo with expected arguments when a gift is saved in batch mode', async () => {
            addGiftTo.mockResolvedValue({});
            const formApp = setupForBatchMode({giftBatchId: 'DUMMY_BATCH_ID', gifts: [], totals: { TOTAL: 1 }});
            await flushPromises();

            const geFormRenderer = shadowQuerySelector(formApp, 'c-ge-form-renderer');
            const submitEvent = new CustomEvent('submit', {
                detail: {
                    success: jest.fn(),
                    error: jest.fn()
                }
            });
            geFormRenderer.dispatchEvent(submitEvent);
            await flushPromises();

            expect(submitEvent.detail.success).toHaveBeenCalled();
            expect(addGiftTo).toHaveBeenCalled();
            expect(addGiftTo.mock.calls[0][0].dataImportBatchId).toEqual('DUMMY_BATCH_ID');
        });

        it('should call expected methods when a gift save fails in batch mode', async () => {
            addGiftTo.mockImplementation(() => {
                throw new Error();
            });
            const formApp = setupForBatchMode({gifts: [], totals: { TOTAL: 1 }});
            await flushPromises();

            const geFormRenderer = shadowQuerySelector(formApp, 'c-ge-form-renderer');
            const submitEvent = new CustomEvent('submit', {
                detail: {
                    success: jest.fn(),
                    error: jest.fn()
                }
            });

            geFormRenderer.dispatchEvent(submitEvent);
            await flushPromises();

            expect(submitEvent.detail.error).toHaveBeenCalled();
        });
    });

    describe('batch processing', () => {

        it('should not allow batch processing if total count of gifts is required and totals do not match', async () => {
            const formApp = setupForBatchMode({ requireTotalMatch: true, expectedCountOfGifts: 5, gifts: [], totals: { TOTAL: 1 }});
            await flushPromises();

            const handleErrorSpy = jest.spyOn(utilTemplateBuilder, 'handleError');

            const geBatchGiftEntryHeader = shadowQuerySelector(formApp, 'c-ge-batch-gift-entry-header');
            const processEvent = new CustomEvent('processbatch');
            geBatchGiftEntryHeader.dispatchEvent(processEvent);

            await flushPromises();

            expect(handleErrorSpy).toHaveBeenCalled();
            expect(handleErrorSpy.mock.calls[0][0]).toBe('c.geBatchGiftsExpectedCountOrTotalMessage');
        });

        it('should not allow batch processing if both types of totals are required and totals do not match', async () => {
            const formApp = setupForBatchMode({
                requireTotalMatch: true,
                expectedCountOfGifts: 5,
                expectedTotalBatchAmount: 100,
                gifts: [],
                totals: { TOTAL: 1 },
                totalDonationsAmount: 50
            });
            await flushPromises();

            const handleErrorSpy = jest.spyOn(utilTemplateBuilder, 'handleError');

            const geBatchGiftEntryHeader = shadowQuerySelector(formApp, 'c-ge-batch-gift-entry-header');
            const processEvent = new CustomEvent('processbatch');
            geBatchGiftEntryHeader.dispatchEvent(processEvent);

            await flushPromises();

            expect(handleErrorSpy).toHaveBeenCalled();
            expect(handleErrorSpy.mock.calls[0][0]).toBe('c.geBatchGiftsExpectedTotalsMessage');
        });

        it('should allow batch processing if both types of totals are required and totals match', async () => {
            const formApp = setupForBatchMode({
                requireTotalMatch: true,
                expectedCountOfGifts: 5,
                expectedTotalBatchAmount: 100,
                gifts: [],
                totals: { TOTAL: 5 },
                totalDonationsAmount: 100
            });
            await flushPromises();

            const geBatchGiftEntryHeader = shadowQuerySelector(formApp, 'c-ge-batch-gift-entry-header');
            const processEvent = new CustomEvent('processbatch');
            geBatchGiftEntryHeader.dispatchEvent(processEvent);

            await flushPromises();

            expect(spinner(formApp)).toBeTruthy();
            expect(batchProcessingText(formApp).innerHTML).toBe(PROCESSING_BATCH_MESSAGE);
        });
    });
});

const spinner = (element) => {
    return shadowQuerySelector(element, 'lightning-spinner');
}

const batchProcessingText = (element) => {
    return shadowQuerySelector(element, '.loading-text');
}

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