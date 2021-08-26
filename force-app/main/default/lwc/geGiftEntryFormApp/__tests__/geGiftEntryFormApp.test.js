import { createElement } from 'lwc';
import { getNavigateCalledWith } from 'lightning/navigation';

import GeGiftEntryFormApp from 'c/geGiftEntryFormApp';
import * as utilTemplateBuilder from 'c/utilTemplateBuilder';
import retrieveDefaultSGERenderWrapper from '@salesforce/apex/GE_GiftEntryController.retrieveDefaultSGERenderWrapper';
import getFormRenderWrapper from '@salesforce/apex/GE_GiftEntryController.getFormRenderWrapper';
import getAllocationsSettings from '@salesforce/apex/GE_GiftEntryController.getAllocationsSettings';
import checkForElevateCustomer from '@salesforce/apex/GE_GiftEntryController.isElevateCustomer';
import saveAndDryRunDataImport from '@salesforce/apex/GE_GiftEntryController.saveAndDryRunDataImport';
import getDataImportModel from '@salesforce/apex/BGE_DataImportBatchEntry_CTRL.getDataImportModel';
import getGiftBatchView from '@salesforce/apex/GE_GiftEntryController.getGiftBatchView';
import isElevateCustomer from '@salesforce/apex/GE_GiftEntryController.isElevateCustomer';
import processGiftsFor from '@salesforce/apex/GE_GiftEntryController.processGiftsFor';
import OPP_PAYMENT_OBJECT from '@salesforce/schema/npe01__OppPayment__c';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';

const pubSub = require('c/pubsubNoPageRef');
import gift from 'c/geGift';

import DATA_IMPORT_BATCH_OBJECT from '@salesforce/schema/DataImportBatch__c';
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';

const PROCESSING_BATCH_MESSAGE = 'c.geProcessingBatch';

const mockWrapperWithNoNames = require('../../../../../../tests/__mocks__/apex/data/retrieveDefaultSGERenderWrapper.json');
const allocationsSettingsNoDefaultGAU = require('../../../../../../tests/__mocks__/apex/data/allocationsSettingsNoDefaultGAU.json');
const legacyDataImportModel = require('../../../../../../tests/__mocks__/apex/data/legacyDataImportModel.json');
const dataImportBatchRecord = require('./data/getDataImportBatchRecord.json');
const selectedContact = require('./data/getSelectedContact.json');
const selectedAccount = require('./data/getSelectedAccount.json');
const selectedDonation = require('./data/selectedDonation.json');
const opportunityObjectDescribeInfo = require('./data/opportunityObjectDescribeInfo.json');
const getPicklistValuesDonation = require('./data/getPicklistValuesDonation.json');
const getPicklistValuesMajorGift = require('./data/getPicklistValuesMajorGift.json');
const MAJOR_GIFT_RECORDTYPEID = '01211000003GQANAA4';
const DONATION_RECORDTYPEID = '01211000003GQAKAA4';

const createGeGiftEntryFormApp = () => {
    return createElement('c-ge-gift-entry-form-app',
        { is: GeGiftEntryFormApp }
    );
}

const setupForBatchMode = (giftBatchView) => {
    retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
    getFormRenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
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
    '@salesforce/apex/GE_GiftEntryController.getFormRenderWrapper',
    () => {
        return {
            default: jest.fn(),
        };
    },
    { virtual: true }
);


jest.mock(
    '@salesforce/apex/GE_GiftEntryController.getGiftBatchTotalsBy',
    () => {
        return {
            default: jest.fn(),
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/GE_GiftEntryController.processGiftsFor',
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
        it('should call saveAndDryRunDataImport with expected arguments when a gift is saved in batch mode', async () => {
            saveAndDryRunDataImport.mockResolvedValue(JSON.stringify(legacyDataImportModel));
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
            expect(saveAndDryRunDataImport).toHaveBeenCalled();
            expect(saveAndDryRunDataImport.mock.calls[0][0].batchId).toEqual('DUMMY_BATCH_ID');
        });

        it('should call expected methods when a gift save fails in batch mode', async () => {
            saveAndDryRunDataImport.mockImplementation(() => {
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

    describe('field change behavior', () => {
        it('populates related fields for a contact when contact lookup changes', async () => {
            const updateFieldsWithSpy = jest.spyOn(gift.prototype, 'updateFieldsWith');
            jest.useFakeTimers();

            const formApp = setupForBatchMode({giftBatchId: 'DUMMY_BATCH_ID', gifts: [], totals: { TOTAL: 1 }});
            await flushPromises();

            getRecord.emit(dataImportBatchRecord, config => {
                return config.recordId === formApp.recordId;
            });

            await flushPromises();
            const geFormRenderer = shadowQuerySelector(formApp, 'c-ge-form-renderer');
            expect(getFormRenderWrapper).toHaveBeenCalled();
            const geFormSections = shadowQuerySelectorAll(geFormRenderer, 'c-ge-form-section');

            const [donorType, accountLookup, contactLookup] = shadowQuerySelectorAll(geFormSections[0], 'c-ge-form-field');

            const contactInput = shadowQuerySelector(contactLookup, 'lightning-input-field');

            const detail = {
                value: [ '003_fake_contact_id' ]
            };

            contactInput.dispatchEvent(new CustomEvent('change', { detail } ));
            jest.runOnlyPendingTimers();

            await flushPromises();

            getRecord.emit(selectedContact, config => {
                return config.recordId === '003_fake_contact_id';
            });

            await flushPromises();

            const lastUpdateCall = getLastCall(updateFieldsWithSpy);

            expect(lastUpdateCall[0]).toEqual(expect.objectContaining({
                Contact1Imported__r: expect.objectContaining({
                    id: "003_fake_contact_id"
                }),
                Contact1_Personal_Email__c: "fake_contact@example.org",
                Contact1_Preferred_Email__c: "Personal"
            }));
        });

        it('populates related fields for an account when account lookup is changed', async () => {
            const updateFieldsWithSpy = jest.spyOn(gift.prototype, 'updateFieldsWith');
            jest.useFakeTimers();

            const formApp = setupForBatchMode({giftBatchId: 'DUMMY_BATCH_ID', gifts: [], totals: { TOTAL: 1 }});
            await flushPromises();

            getRecord.emit(dataImportBatchRecord, config => {
                return config.recordId === formApp.recordId;
            });

            await flushPromises();
            const geFormRenderer = shadowQuerySelector(formApp, 'c-ge-form-renderer');
            expect(getFormRenderWrapper).toHaveBeenCalled();
            const geFormSections = shadowQuerySelectorAll(geFormRenderer, 'c-ge-form-section');

            const [donorType, accountLookup, contactLookup] = shadowQuerySelectorAll(geFormSections[0], 'c-ge-form-field');

            const accountInput = shadowQuerySelector(accountLookup, 'lightning-input-field');

            const detail = {
                value: [ '001_fake_account_id' ]
            };

            accountInput.dispatchEvent(new CustomEvent('change', { detail } ));
            jest.runOnlyPendingTimers();

            await flushPromises();

            getRecord.emit(selectedAccount, config => {
                return config.recordId === '001_fake_account_id';
            });

            await flushPromises();

            const lastUpdateCall = getLastCall(updateFieldsWithSpy);

            expect(lastUpdateCall[0]).toEqual(expect.objectContaining({
                "Account1_Zip_Postal_Code__c": "53203",
                "Account1_Street__c": "123 Billing Street",
                "Account1_State_Province__c": "WI",
                "Account1_City__c": "Some City",
                "Account1Imported__r": expect.objectContaining({
                    id: "001_fake_account_id"
                })
            }));
        });

        it('when donor type changes, clears donation imported fields', async () => {
            const updateFieldsWithSpy = jest.spyOn(gift.prototype, 'updateFieldsWith');
            jest.useFakeTimers();

            const formApp = setupForBatchMode({giftBatchId: 'DUMMY_BATCH_ID', gifts: [], totals: { TOTAL: 1 }});
            await flushPromises();

            getRecord.emit(dataImportBatchRecord, config => {
                return config.recordId === formApp.recordId;
            });

            getObjectInfo.emit({ keyPrefix: 'a01' }, config => {
                return config.objectApiName.objectApiName === OPP_PAYMENT_OBJECT.objectApiName;
            });

            getObjectInfo.emit({ keyPrefix: '006' }, config => {
                return config.objectApiName.objectApiName === OPPORTUNITY_OBJECT.objectApiName;
            });

            await flushPromises();

            pubSub.fireEvent({}, 'geModalCloseEvent', { detail: selectedDonation });

            await flushPromises();

            const geFormRenderer = shadowQuerySelector(formApp, 'c-ge-form-renderer');
            expect(getFormRenderWrapper).toHaveBeenCalled();
            const geFormSections = shadowQuerySelectorAll(geFormRenderer, 'c-ge-form-section');

            const [donorType, ...rest] = shadowQuerySelectorAll(geFormSections[0], 'c-ge-form-field');

            const donorInput = shadowQuerySelector(donorType, 'lightning-combobox');

            const detail = {
                value: 'Account1'
            };

            donorInput.dispatchEvent(new CustomEvent('change', { detail } ));
            jest.runOnlyPendingTimers();

            await flushPromises();

            expect(updateFieldsWithSpy).toHaveBeenCalledWith({
                "PaymentImported__c": null,
                "PaymentImportStatus__c": null,
                "PaymentImported__r": null
            });
        });

        it('when opportunity record type changes, sets picklist values', async () => {
            const updateFieldsWithSpy = jest.spyOn(gift.prototype, 'updateFieldsWith');
            jest.useFakeTimers();

            const formApp = setupForBatchMode({giftBatchId: 'DUMMY_BATCH_ID', gifts: [], totals: { TOTAL: 1 }});
            await flushPromises();

            getRecord.emit(dataImportBatchRecord, config => {
                return config.recordId === formApp.recordId;
            });

            getObjectInfo.emit({ keyPrefix: 'a01' }, config => {
                return config.objectApiName?.objectApiName === OPP_PAYMENT_OBJECT.objectApiName;
            });

            getObjectInfo.emit(opportunityObjectDescribeInfo, config => {
                return config.objectApiName?.objectApiName === OPPORTUNITY_OBJECT.objectApiName ||
                    config.objectApiName === OPPORTUNITY_OBJECT.objectApiName;
            });

            await flushPromises();

            pubSub.fireEvent({}, 'geModalCloseEvent', { detail: selectedDonation });

            await flushPromises();

            getObjectInfo.emit(opportunityObjectDescribeInfo, config => {
                return config.objectApiName?.objectApiName === OPPORTUNITY_OBJECT.objectApiName ||
                    config.objectApiName === OPPORTUNITY_OBJECT.objectApiName;
            });

            await flushPromises();

            getPicklistValues.emit(getPicklistValuesDonation, config => {
                return config.recordTypeId === DONATION_RECORDTYPEID;
            });

            await flushPromises();

            const geFormRenderer = shadowQuerySelector(formApp, 'c-ge-form-renderer');
            expect(getFormRenderWrapper).toHaveBeenCalled();
            const geFormSections = shadowQuerySelectorAll(geFormRenderer, 'c-ge-form-section');

            const [closeDate, amount, recordType, opportunityType, ...rest] = shadowQuerySelectorAll(geFormSections[3], 'c-ge-form-field');
            const opportunityTypeInput = shadowQuerySelector(opportunityType, 'lightning-combobox');

            expect(opportunityTypeInput.options).toContainOptions(['c.stgLabelNone','Donation Test']);

            const recordTypeInput = shadowQuerySelector(recordType, 'lightning-combobox');

            const detail = {
                value: MAJOR_GIFT_RECORDTYPEID
            };

            recordTypeInput.dispatchEvent(new CustomEvent('change', { detail } ));
            jest.runOnlyPendingTimers();

            await flushPromises();

            getPicklistValues.emit(getPicklistValuesMajorGift, config => {
                return config.recordTypeId === MAJOR_GIFT_RECORDTYPEID;
            });

            await flushPromises();

            expect(opportunityTypeInput.options).toContainOptions(['c.stgLabelNone','Donation Test', 'Major Gift Test']);
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
            processGiftsFor.mockResolvedValue({});

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

const shadowQuerySelectorAll = (element, selector) => {
    return getShadowRoot(element).querySelectorAll(selector);
}

const getLastCall = (mockedFn) => {
    const callCount = mockedFn.mock.calls.length;
    return mockedFn.mock.calls[callCount-1];
}