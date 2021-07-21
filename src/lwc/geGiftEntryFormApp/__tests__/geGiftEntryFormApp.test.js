import { createElement } from 'lwc';
import { getNavigateCalledWith } from 'lightning/navigation';

import GeGiftEntryFormApp from 'c/geGiftEntryFormApp';
import { getRecord } from "@salesforce/sfdx-lwc-jest/src/lightning-stubs/uiRecordApi/uiRecordApi";
import getGiftBatchTotalsBy from '@salesforce/apex/GE_GiftEntryController.getGiftBatchTotalsBy';
import retrieveDefaultSGERenderWrapper from '@salesforce/apex/GE_GiftEntryController.retrieveDefaultSGERenderWrapper';
import getAllocationsSettings from '@salesforce/apex/GE_GiftEntryController.getAllocationsSettings';
import checkForElevateCustomer from '@salesforce/apex/GE_GiftEntryController.isElevateCustomer';
import saveAndDryRunDataImport from '@salesforce/apex/GE_GiftEntryController.saveAndDryRunDataImport';

import DATA_IMPORT_BATCH_OBJECT from '@salesforce/schema/DataImportBatch__c';
const mockGetRecord = require('./data/getRecord.json');
const PROCESSING_BATCH_MESSAGE = 'c.geProcessingBatch';
const batchTotalsProcessingGifts = require('./data/batchTotalsProcessingGifts.json');
const batchTotalsCompletedGifts = require('./data/batchTotalsCompletedGifts.json');
const batchTotalsExpiredAuthorization = require('./data/batchTotalsExpiredAuthorization.json');

const mockWrapperWithNoNames = require('./data/retrieveDefaultSGERenderWrapper.json');
const allocationsSettingsNoDefaultGAU = require('./data/allocationsSettingsNoDefaultGAU.json');
const legacyDataImportModel = require('./data/legacyDataImportModel.json');

const createGeGiftEntryFormApp = () => {
    return createElement('c-ge-gift-entry-form-app',
        { is: GeGiftEntryFormApp }
    );
}

const setupForBatchMode = () => {
    retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
    getAllocationsSettings.mockResolvedValue(allocationsSettingsNoDefaultGAU);

    getGiftBatchTotalsBy.mockResolvedValue(batchTotalsCompletedGifts);
    const formApp = createGeGiftEntryFormApp();
    formApp.sObjectName = DATA_IMPORT_BATCH_OBJECT.objectApiName;

    document.body.appendChild(formApp);
    getRecord.emit(mockGetRecord);

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
            getGiftBatchTotalsBy.mockResolvedValue(batchTotalsProcessingGifts);
            const formApp = createGeGiftEntryFormApp();
            formApp.sObjectName = DATA_IMPORT_BATCH_OBJECT.objectApiName;

            document.body.appendChild(formApp);
            getRecord.emit(mockGetRecord);

            expect(spinner(formApp)).toBeTruthy();

            await flushPromises();

            expect(spinner(formApp)).toBeTruthy();
            expect(batchProcessingText(formApp).innerHTML).toBe(PROCESSING_BATCH_MESSAGE);
        });

        it('should render batch table in Batch mode', async () => {
            const formApp = setupForBatchMode();
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
            checkForElevateCustomer.mockResolvedValue(true);
            retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
            getAllocationsSettings.mockResolvedValue(allocationsSettingsNoDefaultGAU);
            getGiftBatchTotalsBy.mockResolvedValue(batchTotalsExpiredAuthorization);

            const formApp = createGeGiftEntryFormApp();
            formApp.sObjectName = DATA_IMPORT_BATCH_OBJECT.objectApiName;

            document.body.appendChild(formApp);
            getRecord.emit(mockGetRecord);
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
            const formApp = setupForBatchMode();

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
            const formApp = setupForBatchMode();
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
            const formApp = setupForBatchMode();
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
        it('should call expected methods on the table component when a gift is saved in batch mode', async () => {
            saveAndDryRunDataImport.mockResolvedValue(JSON.stringify(legacyDataImportModel));
            const formApp = setupForBatchMode();
            await flushPromises();

            const batchTable = shadowQuerySelector(formApp, 'c-ge-batch-gift-entry-table');
            const submitEventSpy = jest.spyOn(batchTable, 'handleSubmit');

            const geFormRenderer = shadowQuerySelector(formApp, 'c-ge-form-renderer');
            const submitEvent = new CustomEvent('submit', {
                detail: {
                    dataImportRecord: { Id: 'DUMMY_ID' },
                    success: jest.fn(),
                    error: jest.fn()
                }
            });
            geFormRenderer.dispatchEvent(submitEvent);
            await flushPromises();

            expect(submitEventSpy).toHaveBeenCalled();
            const spiedSubmitEventDetails = submitEventSpy.mock.calls[0][0].detail;
            expect(spiedSubmitEventDetails.dataImportRecord.Id).toEqual('DUMMY_ID');
            expect(spiedSubmitEventDetails.success).toHaveBeenCalled();
        });

        it('should call expected methods on the table component when a gift save fails in batch mode', async () => {
            saveAndDryRunDataImport.mockImplementation(() => {
                throw new Error();
            });;
            const formApp = setupForBatchMode();
            await flushPromises();

            const batchTable = shadowQuerySelector(formApp, 'c-ge-batch-gift-entry-table');
            const badSubmitEventSpy = jest.spyOn(batchTable, 'handleSubmit');

            const geFormRenderer = shadowQuerySelector(formApp, 'c-ge-form-renderer');
            const submitEvent = new CustomEvent('submit', {
                detail: {
                    dataImportRecord: { Id: 'DUMMY_ID' },
                    success: jest.fn(),
                    error: jest.fn()
                }
            });
            geFormRenderer.dispatchEvent(submitEvent);
            await flushPromises();

            expect(badSubmitEventSpy).toHaveBeenCalled();
            const spiedSubmitEventDetails = badSubmitEventSpy.mock.calls[0][0].detail;
            expect(spiedSubmitEventDetails.dataImportRecord.Id).toEqual('DUMMY_ID');
            expect(spiedSubmitEventDetails.error).toHaveBeenCalled();
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