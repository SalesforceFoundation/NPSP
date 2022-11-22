import { createElement } from 'lwc';
import { getNavigateCalledWith } from 'lightning/navigation';

import GeGiftEntryFormApp from 'c/geGiftEntryFormApp';
import * as utilTemplateBuilder from 'c/utilTemplateBuilder';
import retrieveDefaultSGERenderWrapper from '@salesforce/apex/GE_GiftEntryController.retrieveDefaultSGERenderWrapper';
import getFormRenderWrapper from '@salesforce/apex/GE_GiftEntryController.getFormRenderWrapper';
import getAllocationsSettings from '@salesforce/apex/GE_GiftEntryController.getAllocationsSettings';
import checkForElevateCustomer from '@salesforce/apex/GE_GiftEntryController.isElevateCustomer';
import upsertDataImport from '@salesforce/apex/GE_GiftEntryController.upsertDataImport';
import sendPurchaseRequest from '@salesforce/apex/GE_GiftEntryController.sendPurchaseRequest';
import addGiftTo from '@salesforce/apex/GE_GiftEntryController.addGiftTo';
import getDataImportModel from '@salesforce/apex/BGE_DataImportBatchEntry_CTRL.getDataImportModel';
import getGiftBatchView from '@salesforce/apex/GE_GiftEntryController.getGiftBatchView';
import isElevateCustomer from '@salesforce/apex/GE_GiftEntryController.isElevateCustomer';
import processGiftsFor from '@salesforce/apex/GE_GiftEntryController.processGiftsFor';
import isGiftBatchAccessible from '@salesforce/apex/GE_GiftEntryController.isGiftBatchAccessible';
import OPP_PAYMENT_OBJECT from '@salesforce/schema/npe01__OppPayment__c';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { mockCheckInputValidity, mockCheckInputValidityImpl } from 'lightning/input';
import { mockCheckComboboxValidity } from 'lightning/combobox';
import { mockGetIframeReply } from 'c/psElevateTokenHandler';


const pubSub = require('c/pubsubNoPageRef');
import gift from 'c/geGift';
import GeGatewaySettings from 'c/geGatewaySettings';

import DATA_IMPORT_BATCH_OBJECT from '@salesforce/schema/DataImportBatch__c';
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import FAILURE_INFORMATION from '@salesforce/schema/DataImport__c.FailureInformation__c';
import accountDonorSelectionMismatch from '@salesforce/label/c.geErrorDonorMismatch';

const PROCESSING_BATCH_MESSAGE = 'c.geProcessingBatch';

const mockWrapperWithNoNames = require('../../../../../../tests/__mocks__/apex/data/retrieveDefaultSGERenderWrapper.json');
const allocationsSettingsNoDefaultGAU = require('../../../../../../tests/__mocks__/apex/data/allocationsSettingsNoDefaultGAU.json');
const dataImportObjectInfo = require('../../../../../../tests/__mocks__/apex/data/dataImportObjectDescribeInfo.json');
const dataImportBatchRecord = require('./data/getDataImportBatchRecord.json');
const selectedContact = require('./data/getSelectedContact.json');
const selectedAccount = require('./data/getSelectedAccount.json');
const selectedDonation = require('./data/selectedDonation.json');
const selectedPayment = require('./data/selectedPayment.json');
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
    isGiftBatchAccessible.mockResolvedValue(true);

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

jest.mock(
    '@salesforce/apex/GE_GiftEntryController.isGiftBatchAccessible',
    () => {
        return {
            default: jest.fn(),
        };
    },
    { virtual: true }
);

// mock labels so that we can assert the values being replaced in the string
jest.mock(
    '@salesforce/label/c.geErrorDonorTypeValidationSingle',
    () => {
        return {
            default: 'When you select {0} for {1}, you must enter information in {2}'
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/label/c.geErrorUncertainCardChargePart1',
    () => {
        return {
            default: 'A system error occurred for the {0} donation by {1}. Your admin should review transactions in {2} and determine if the payment was processed.'
        };
    },
    { virtual: true }
)

describe('c-ge-gift-entry-form-app', () => {

    afterEach(() => {
        clearDOM();
    });

    describe('rendering behavior', () => {

        it('should render page blocker if the gift batch is inaccessible to the current user', async () => {
            const formApp = setupForBatchMode({gifts: [], totals: { TOTAL: 1, IMPORTED: 1 }});
            isGiftBatchAccessible.mockResolvedValue(false);

            await flushPromises();

            const pageBlocker = formApp.shadowRoot.querySelector('c-util-illustration');
            expect(pageBlocker).toBeTruthy();
        });

        it('should not render page blocker if the gift batch is accessible to the current user', async () => {
            const formApp = setupForBatchMode({gifts: [], totals: { TOTAL: 1, IMPORTED: 1 }});

            await flushPromises();

            const pageBlocker = formApp.shadowRoot.querySelector('c-util-illustration');
            expect(pageBlocker).toBeNull();

            const batchHeader = formApp.shadowRoot.querySelector('c-ge-batch-gift-entry-header');
            expect(batchHeader).toBeTruthy();

            const formRenderer = formApp.shadowRoot.querySelector('c-ge-form-renderer');
            expect(formRenderer).toBeTruthy();

            const batchTable = formApp.shadowRoot.querySelector('c-ge-batch-gift-entry-table');
            expect(batchTable).toBeTruthy();
        });

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
        it('should disable update button when widget is read-only with an editable recurring gift', async() => {
            const formApp = setupForBatchMode({gifts: [{fields: {'Id': 'DUMMY_RECORD_ID',
                                                                 'Recurring_Donation_Elevate_Recurring_ID__c': 'DUMMY_RECURRING_ID'}}], totals: { TOTAL: 1 }});
            await flushPromises();

            const batchTable = shadowQuerySelector(formApp, 'c-ge-batch-gift-entry-table');
            const loadDataEvent = new CustomEvent('loaddata', {
                detail : {
                    'Id': 'DUMMY_RECORD_ID'}
            });
            batchTable.dispatchEvent(loadDataEvent);
            await flushPromises();

            const geFormRenderer = shadowQuerySelector(formApp, 'c-ge-form-renderer');
            const warningMessage = shadowQuerySelector(geFormRenderer, '[data-id="elevateTrnxWarning"]');
            expect(warningMessage).toBeTruthy();

            pubSub.fireEvent({}, 'widgetStateChange', {state: 'readOnly'});
            await flushPromises();
            
            const saveButton = shadowQuerySelector(geFormRenderer, '[data-id="bgeSaveButton"]');
            expect(saveButton.disabled).toBe(true);
        });

        it('should disable update button when widget is read-only with an editable status for one-time gift', async() => {
            const formApp = setupForBatchMode({gifts: [{fields: {'Id': 'DUMMY_RECORD_ID',
                                                                 'Payment_Status__c': 'AUTHORIZED'}}], totals: { TOTAL: 1 }});
            await flushPromises();

            const batchTable = shadowQuerySelector(formApp, 'c-ge-batch-gift-entry-table');
            const loadDataEvent = new CustomEvent('loaddata', {
                detail : {
                    'Id': 'DUMMY_RECORD_ID'}
            });
            batchTable.dispatchEvent(loadDataEvent);
            await flushPromises();

            const geFormRenderer = shadowQuerySelector(formApp, 'c-ge-form-renderer');
            const warningMessage = shadowQuerySelector(geFormRenderer, '[data-id="elevateTrnxWarning"]');
            expect(warningMessage).toBeTruthy();

            pubSub.fireEvent({}, 'widgetStateChange', {state: 'readOnly'});
            await flushPromises();
            
            const saveButton = shadowQuerySelector(geFormRenderer, '[data-id="bgeSaveButton"]');
            expect(saveButton.disabled).toBe(true);
        });

        it('should not display widget warning captured gift is loadeed', async() => {
            const formApp = setupForBatchMode({gifts: [{fields: {'Id': 'DUMMY_RECORD_ID', 'Payment_Status__c': 'CAPTURED'}}], totals: { TOTAL: 1 }});
            await flushPromises();

            const batchTable = shadowQuerySelector(formApp, 'c-ge-batch-gift-entry-table');
            const loadDataEvent = new CustomEvent('loaddata', {
                detail : {
                    'Id': 'DUMMY_RECORD_ID'
                }
            });
            batchTable.dispatchEvent(loadDataEvent);
            await flushPromises();

            const geFormRenderer = shadowQuerySelector(formApp, 'c-ge-form-renderer');
            const warningMessage = shadowQuerySelectorAll(geFormRenderer, '[data-id="elevateTrnxWarning"]');
            expect(warningMessage).toHaveLength(0);
        });

        it('should display widget warning when one-time gift read-only status is loadeed', async() => {
            const formApp = setupForBatchMode({gifts: [{fields: {'Id': 'DUMMY_RECORD_ID', 'Payment_Status__c': 'PENDING'}}], totals: { TOTAL: 1 }});
            await flushPromises();

            const batchTable = shadowQuerySelector(formApp, 'c-ge-batch-gift-entry-table');
            const loadDataEvent = new CustomEvent('loaddata', {
                detail : {
                    'Id': 'DUMMY_RECORD_ID'
                }
            });
            batchTable.dispatchEvent(loadDataEvent);
            await flushPromises();

            const geFormRenderer = shadowQuerySelector(formApp, 'c-ge-form-renderer');
            const warningMessage = shadowQuerySelector(geFormRenderer, '[data-id="elevateTrnxWarning"]');
            expect(warningMessage).toBeTruthy();
        });
        it('should display widget warning when one-time gift read-only status is loaded', async() => {
            const formApp = setupForBatchMode({gifts: [{fields: {'Id': 'DUMMY_RECORD_ID', 'Payment_Status__c': 'AUTHORIZED'}}], totals: { TOTAL: 1 }});
            await flushPromises();

            const batchTable = shadowQuerySelector(formApp, 'c-ge-batch-gift-entry-table');
            const loadDataEvent = new CustomEvent('loaddata', {
                detail : {
                    'Id': 'DUMMY_RECORD_ID'
                }
            });
            batchTable.dispatchEvent(loadDataEvent);
            await flushPromises();

            const geFormRenderer = shadowQuerySelector(formApp, 'c-ge-form-renderer');
            const warningMessage = shadowQuerySelectorAll(geFormRenderer, '[data-id="elevateTrnxWarning"]');
            expect(warningMessage).toHaveLength(1);
        });

        it('should display widget warning when recurring gift is loadeed', async() => {
            const formApp = setupForBatchMode({gifts: [{fields: {'Id': 'DUMMY_RECORD_ID', 'Recurring_Donation_Elevate_Recurring_ID__c': 'TEST_RECURRING_ID'}}], totals: { TOTAL: 1 }});
            await flushPromises();

            const batchTable = shadowQuerySelector(formApp, 'c-ge-batch-gift-entry-table');
            const loadDataEvent = new CustomEvent('loaddata', {
                detail : {
                    'Id': 'DUMMY_RECORD_ID'
                }
            });
            batchTable.dispatchEvent(loadDataEvent);
            await flushPromises();

            const geFormRenderer = shadowQuerySelector(formApp, 'c-ge-form-renderer');
            const warningMessage = shadowQuerySelectorAll(geFormRenderer, '[data-id="elevateTrnxWarning"]');
            expect(warningMessage).toHaveLength(1);
        });

        it('should not display widget warning when imported gift is loaded', async() => {
            const formApp = setupForBatchMode({gifts: [{fields: {'Id': 'DUMMY_RECORD_ID', 'Status__c': 'Imported'}}], totals: { TOTAL: 1 }});
            await flushPromises();

            const batchTable = shadowQuerySelector(formApp, 'c-ge-batch-gift-entry-table');
            const loadDataEvent = new CustomEvent('loaddata', {
                detail : {
                    'Id': 'DUMMY_RECORD_ID'
                }
            });
            batchTable.dispatchEvent(loadDataEvent);
            await flushPromises();

            const geFormRenderer = shadowQuerySelector(formApp, 'c-ge-form-renderer');
            const warningMessage = shadowQuerySelectorAll(geFormRenderer, '[data-id="elevateTrnxWarning"]');
            expect(warningMessage).toHaveLength(0);
        });

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
            const formApp = setupForBatchMode({giftBatchId: 'DUMMY_BATCH_ID', gifts: [{fields: {[FAILURE_INFORMATION.fieldApiName]: null}}], totals: { TOTAL: 1 }});
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
            addGiftTo.mockResolvedValue({});
            const formApp = setupForBatchMode({gifts: [{fields: {[FAILURE_INFORMATION.fieldApiName]: 'dummy fail reason'}}], totals: { TOTAL: 1 }});
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
            expect(submitEvent.detail.error).toHaveBeenCalledWith('dummy fail reason');
        });
    });

    describe('field change behavior', () => {
        it('populates related fields for a contact when contact lookup changes', async () => {
            const updateFieldsWithSpy = jest.spyOn(gift.prototype, 'updateFieldsWith');

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


            runWithFakeTimer(() => {
                contactInput.dispatchEvent(new CustomEvent('change', { detail } ));
            });

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

            runWithFakeTimer(() => {
                accountInput.dispatchEvent(new CustomEvent('change', { detail } ));
            });

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

            runWithFakeTimer(() => {
                donorInput.dispatchEvent(new CustomEvent('change', { detail } ));
            });

            await flushPromises();

            expect(updateFieldsWithSpy).toHaveBeenCalledWith({
                "Donation_Donor__c": 'Account1'
            });
            
            expect(updateFieldsWithSpy).toHaveBeenCalledWith({
                "PaymentImported__c": null,
                "PaymentImportStatus__c": null,
                "PaymentImported__r": null
            });

            expect(updateFieldsWithSpy).toHaveBeenCalledWith({
                "DonationImported__c": null,
                "DonationImportStatus__c": null,
                "DonationImported__r": null
            });

        });

        it('when opportunity record type changes, sets picklist values', async () => {

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

            runWithFakeTimer(() => {
                recordTypeInput.dispatchEvent(new CustomEvent('change', { detail } ));
            });

            await flushPromises();

            getPicklistValues.emit(getPicklistValuesMajorGift, config => {
                return config.recordTypeId === MAJOR_GIFT_RECORDTYPEID;
            });

            await flushPromises();

            expect(opportunityTypeInput.options).toContainOptions(['c.stgLabelNone','Donation Test', 'Major Gift Test']);
        });


        it('when selected donation has mismatched donor data' , async () => {

            retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
            getAllocationsSettings.mockResolvedValue(allocationsSettingsNoDefaultGAU);
            getDataImportModel.mockResolvedValue('{"dummyKey":"dummyValue"}');
            getGiftBatchView.mockResolvedValue({gifts: [], totals: { TOTAL: 1, EXPIRED_PAYMENT: 0, FAILED: 0 }});
            checkForElevateCustomer.mockResolvedValue(true);

            const formApp = createGeGiftEntryFormApp();
            formApp.sObjectName = DATA_IMPORT_BATCH_OBJECT.objectApiName;
            formApp.recordId = 'DUMMY_RECORD_ID';

            document.body.appendChild(formApp);
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

            const geFormRenderer = shadowQuerySelector(formApp, 'c-ge-form-renderer');
            expect(getFormRenderWrapper).toHaveBeenCalled();

            geFormRenderer.giftInView = {
                fields: {
                    'Payment_Method__c': 'Credit Card',
                    'Donation_Amount__c': '0.01',
                    'Account1_Imported__c': 'DUMMY_CONTACT_ID',
                    'Donation_Date__c': '2021-02-23',
                    'Donation_Donor__c': 'Account1',
                    'Payment_Authorization_Token__c': 'a_dummy_token',
                    'Account1_Name__c': 'DummyLastName'
                },
                softCredits: { all: [] }
            }

            pubSub.fireEvent({}, 'geModalCloseEvent', { detail: selectedPayment });


            const rendererButton = shadowQuerySelector(geFormRenderer, 'lightning-button[data-qa-locator="button c.geButtonSaveNewGift"]');
            rendererButton.click();

            await flushPromises();

            const pageLevelMessage = shadowQuerySelector(geFormRenderer, 'c-util-page-level-message');
            expect(pageLevelMessage).toBeTruthy();

            const pElement = pageLevelMessage.querySelector('ul li p');
            expect(pElement.textContent).toBe(accountDonorSelectionMismatch);

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

            expect(spinner(formApp)).toBeFalsy();
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

            expect(spinner(formApp)).toBeFalsy();
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

        it('should load process batch spinner when processbatch event occurs', async () => {
            const formApp = setupForBatchMode({gifts: [], totals: { TOTAL: 1 }});

            await flushPromises();

            const geBatchGiftEntryHeader = shadowQuerySelector(formApp, 'c-ge-batch-gift-entry-header');
            const processEvent = new CustomEvent('processbatch');
            geBatchGiftEntryHeader.dispatchEvent(processEvent);

            await flushPromises();

            expect(spinner(formApp)).toBeTruthy();
            expect(batchProcessingText(formApp).innerHTML).toBe(PROCESSING_BATCH_MESSAGE);
        });
    });

    describe('donor fields validation validation', () => {
        it('when donor type is contact and contact fields not filled in, on save displays error', async () => {
            const formApp = setupForBatchMode({giftBatchId: 'DUMMY_BATCH_ID', gifts: [], totals: { TOTAL: 1 }});
            mockCheckInputValidity.mockImplementation(mockCheckInputValidityImpl);
            mockCheckComboboxValidity.mockImplementation(mockCheckInputValidityImpl);
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

            const geFormRenderer = shadowQuerySelector(formApp, 'c-ge-form-renderer');
            const geFormSections = shadowQuerySelectorAll(geFormRenderer, 'c-ge-form-section');
            const [donorType, accountLookup, contactLookup] = shadowQuerySelectorAll(geFormSections[0], 'c-ge-form-field');
            const donorInput = shadowQuerySelector(donorType, 'lightning-combobox');

            runWithFakeTimer(() => {
                donorInput.dispatchEvent(new CustomEvent('change', { detail: { value: 'Contact1' } } ));
            });

            await flushPromises();

            const rendererButton = shadowQuerySelector(geFormRenderer, 'lightning-button[data-qa-locator="button c.geButtonSaveNewGift"]');
            rendererButton.click();

            await flushPromises();

            const pageLevelMessage = shadowQuerySelector(geFormRenderer, 'c-util-page-level-message');
            expect(pageLevelMessage).toBeTruthy();

            const pElement = pageLevelMessage.querySelector('ul li p');
            expect(pElement.textContent).toBe('When you select Contact1 for Donor Type, you must enter information in Existing Donor Contact');
        });

        it('when donor type is account and account fields not filled in, on save displays error', async () => {
            const formApp = setupForBatchMode({giftBatchId: 'DUMMY_BATCH_ID', gifts: [], totals: { TOTAL: 1 }});
            mockCheckInputValidity.mockImplementation(mockCheckInputValidityImpl);
            mockCheckComboboxValidity.mockImplementation(mockCheckInputValidityImpl);
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

            const geFormRenderer = shadowQuerySelector(formApp, 'c-ge-form-renderer');
            const geFormSections = shadowQuerySelectorAll(geFormRenderer, 'c-ge-form-section');
            const [donorType, accountLookup, contactLookup] = shadowQuerySelectorAll(geFormSections[0], 'c-ge-form-field');
            const donorInput = shadowQuerySelector(donorType, 'lightning-combobox');

            runWithFakeTimer(() => {
                donorInput.dispatchEvent(new CustomEvent('change', { detail: { value: 'Account1' } } ));
            });

            await flushPromises();

            const saveButton = shadowQuerySelector(geFormRenderer, 'lightning-button[data-qa-locator="button c.geButtonSaveNewGift"]');
            saveButton.click();

            await flushPromises();

            const pageLevelMessage = shadowQuerySelector(geFormRenderer, 'c-util-page-level-message');
            expect(pageLevelMessage).toBeTruthy();

            const pElement = pageLevelMessage.querySelector('ul li p');
            expect(pElement.textContent).toBe('When you select Account1 for Donor Type, you must enter information in Existing Donor Organization Account');
        });
    });

    describe('payments in single mode', () => {
        it('returns an error message when purchase call times out', async () => {
            getAllocationsSettings.mockResolvedValue(allocationsSettingsNoDefaultGAU);
            isElevateCustomer.mockResolvedValue(true);
            retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
            upsertDataImport.mockImplementation((dataImport) => {
                return { Id: 'fakeDataImportId', ...dataImport };
            });
            sendPurchaseRequest.mockResolvedValue(JSON.stringify({
                status: '408',
                message: 'Timed out'
            }));
            mockCheckInputValidity.mockImplementation(mockCheckInputValidityImpl);
            mockCheckComboboxValidity.mockImplementation(mockCheckInputValidityImpl);

            const formApp = createGeGiftEntryFormApp();
            document.body.appendChild(formApp);


            mockGetIframeReply.mockImplementation((iframe, message, targetOrigin) => {
                if (message.action === 'createToken') {
                    return {"type": "post__npsp", "token": "a_dummy_token"};
                }
            });
            await flushPromises();

            window.scrollTo = jest.fn();

            getObjectInfo.emit(dataImportObjectInfo, config => {
                return config.objectApiName?.objectApiName === 'DataImport__c';
            });

            getObjectInfo.emit({ keyPrefix: 'a01' }, config => {
                return config.objectApiName?.objectApiName === OPP_PAYMENT_OBJECT.objectApiName;
            });

            getObjectInfo.emit({ keyPrefix: '006' }, config => {
                return config.objectApiName?.objectApiName === OPPORTUNITY_OBJECT.objectApiName;
            });

            await flushPromises();

            const geFormRenderer = shadowQuerySelector(formApp, 'c-ge-form-renderer');
            GeGatewaySettings.isValidElevatePaymentMethod = jest.fn(() => true);
            geFormRenderer.GeGatewaySettings = GeGatewaySettings;

            const [firstSection, secondSection, thirdSection, fourthSection] = shadowQuerySelectorAll(geFormRenderer, 'c-ge-form-section');
            const [donorType, accountLookup, contactLookup] = shadowQuerySelectorAll(firstSection, 'c-ge-form-field');
            const [donationDate,
                donationAmount,
                recordType,
                opportunityType,
                campaign,
                paymentMethod,
                checkNumber] = shadowQuerySelectorAll(fourthSection, 'c-ge-form-field');

            runWithFakeTimer(() => {
                changeFieldValue(donorType, 'Contact1');
                changeFieldValue(contactLookup, ['003_fake_contact_id']);
                changeFieldValue(paymentMethod, 'Credit Card');
                changeFieldValue(donationDate, '2021-06-15');
                changeFieldValue(donationAmount, 123.45);
            });

            await flushPromises();

            getRecord.emit(selectedContact, config => {
                return config.recordId === '003_fake_contact_id';
            });

            await flushPromises();

            const saveButton = shadowQuerySelector(geFormRenderer, 'lightning-button[data-qa-locator="button c.commonSave"]');
            saveButton.click();

            await flushPromises();

            const illustrationCmp = shadowQuerySelector(geFormRenderer, 'c-util-illustration');

            const errorText = illustrationCmp.querySelector('div p.critical-error-text');
            expect(errorText).toBeTruthy();
            expect(errorText.textContent).toBe('A system error occurred for the $123.45 donation by History Tester. Your admin should review transactions in c.commonPaymentServices and determine if the payment was processed.');

        });
    });
});

const spinner = (element) => {
    return shadowQuerySelector(element, 'lightning-spinner');
}

const batchProcessingText = (element) => {
    return shadowQuerySelector(element, '.loading-text');
}

const changeFieldValue = (formField, value) => {
    const detail = { value };
    const inputField = shadowQuerySelector(formField, '[data-id="inputComponent"]');
    expect(inputField).toBeTruthy();
    inputField.value = value;
    inputField.dispatchEvent(new CustomEvent('change', { detail }));
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

const runWithFakeTimer = (someFn) => {
    jest.useFakeTimers();
    someFn();
    jest.runOnlyPendingTimers();
    jest.useRealTimers();
}