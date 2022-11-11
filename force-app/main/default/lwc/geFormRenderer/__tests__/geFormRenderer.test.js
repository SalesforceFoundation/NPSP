import { createElement } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import GeFormRenderer from 'c/geFormRenderer';
import GeLabelService from 'c/geLabelService';
import Settings from 'c/geSettings';
import GeGatewaySettings from 'c/geGatewaySettings';
const pubSub = require('c/pubsubNoPageRef');

import upsertDataImport from '@salesforce/apex/GE_GiftEntryController.upsertDataImport';
import retrieveDefaultSGERenderWrapper from '@salesforce/apex/GE_GiftEntryController.retrieveDefaultSGERenderWrapper';
import sendPurchaseRequest from '@salesforce/apex/GE_GiftEntryController.sendPurchaseRequest';
import getAllocationsSettings from '@salesforce/apex/GE_GiftEntryController.getAllocationsSettings';

import { mockCheckInputValidity } from 'lightning/input';
import { mockCheckComboboxValidity } from 'lightning/combobox';
import { mockGetIframeReply } from 'c/psElevateTokenHandler';

const mockWrapperWithNoNames = require('../../../../../../tests/__mocks__/apex/data/retrieveDefaultSGERenderWrapper.json');
const getRecordContact1Imported = require('./data/getRecordContact1Imported.json');
const dataImportObjectInfo = require('../../../../../../tests/__mocks__/apex/data/dataImportObjectDescribeInfo.json');
const allocationsSettingsNoDefaultGAU = require('../../../../../../tests/__mocks__/apex/data/allocationsSettingsNoDefaultGAU.json');
const dataImportBatchRecord = require('../../../../../../tests/__mocks__/apex/data/getDataImportBatchRecord.json');

describe('c-ge-form-renderer', () => {

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    describe('render behavior', () => {
        it('when a form is saved with a possible validation rule error then processing of the donation should be halted',
            async () => {

                retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
                mockCheckInputValidity.mockReturnValue(true); // lightning-inputs always report they are valid
                mockCheckComboboxValidity.mockReturnValue(true); // lightning-comboboxes always report they are valid
                getAllocationsSettings.mockResolvedValue(allocationsSettingsNoDefaultGAU);

                const validationRuleErrorResponse = {
                    "status":500,
                    "body":{
                        "exceptionType":"System.DmlException",
                        "isUserDefinedException":false,
                        "message":"{\"exceptionType\":\"System.DmlException\"," +
                            "\"errorMessage\":null," +
                            "\"DMLErrorMessageMapping\":" +
                            "{\"0\":\"Donation has to be more than $5\"}," +
                            "\"DMLErrorFieldNameMapping\":{}}",
                        "stackTrace":""
                    },
                    "headers":{}
                }
                upsertDataImport.mockRejectedValue(validationRuleErrorResponse);

                const element = createElement('c-ge-form-renderer', {is: GeFormRenderer});
                document.body.appendChild(element);

                getObjectInfo.emit(dataImportObjectInfo, config => {
                    return config?.objectApiName?.objectApiName === 'DataImport__c';
                });

                await flushPromises();

                const DUMMY_CONTACT_ID = '003J000001zoYLGIA2';
                element.giftInView = {
                    fields: {
                        'Donation_Amount__c': '0.01',
                        'Contact1Imported__c': DUMMY_CONTACT_ID,
                        'Donation_Date__c': '2021-02-23',
                        'Donation_Donor__c': 'Contact',
                        'Contact1_Lastname__c': 'DummyLastName'
                    },
                    softCredits: { all: [] }
                };
                await flushPromises();

                // simulate getting back data for DUMMY_CONTACT_ID
                getRecord.emit(getRecordContact1Imported, config => {
                    return config.recordId === DUMMY_CONTACT_ID;
                });
                await flushPromises();
                // resolve form updates before clicking save button

                const saveButton = element.shadowRoot.querySelectorAll('lightning-button')[1];
                saveButton.click();
                await flushPromises();

                expect(upsertDataImport).toHaveBeenCalledTimes(1);

                const pageLevelMessage = element.shadowRoot.querySelector('c-util-page-level-message');
                const pElement = pageLevelMessage.querySelector('p');
                expect(pElement.innerHTML).toBe('Donation has to be more than $5');
                const spinner = element.shadowRoot.querySelector('lightning-spinner');
                expect(spinner).toBeFalsy();
            });
        it('make recurring button is disabled when imported gift is loaded into the form', async() => {
            retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
            getAllocationsSettings.mockResolvedValue(allocationsSettingsNoDefaultGAU);
            const element = createElement('c-ge-form-renderer', {is: GeFormRenderer });

            const DUMMY_BATCH_ID = 'a0T11000007F8WQEA0';

            element.batchId = DUMMY_BATCH_ID;
            document.body.appendChild(element);
            await flushPromises();

            // simulate getting back data for DUMMY_CONTACT_ID
            getRecord.emit(dataImportBatchRecord, config => {
                return config.recordId === DUMMY_BATCH_ID;
            });

            await flushPromises();

            const button = element.shadowRoot.querySelectorAll('[data-id="recurringButton"]');
            expect(button).toHaveLength(1);

            element.isMakeRecurringButtonDisabled = true;
            await flushPromises();

            const disabledButton = element.shadowRoot.querySelectorAll('[data-id="recurringButton"]');
            expect(disabledButton[0].disabled).toBe(true);
        });

        it('save button is not disabled when schedule recurring type is Fixed for non-Elevate RD', async() => {
            retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
            getAllocationsSettings.mockResolvedValue(allocationsSettingsNoDefaultGAU);

            const element = createElement('c-ge-form-renderer', {is: GeFormRenderer });
            element.batchId = 'DUMMY_BATCH_ID';

            Settings.isElevateCustomer = jest.fn(() => true);
            element.Settings = Settings;

            GeGatewaySettings.isValidElevatePaymentMethod = jest.fn(() => false);
            element.GeGatewaySettings = GeGatewaySettings;

            document.body.appendChild(element);
            await flushPromises();

            element.giftInView = {
                fields: {
                    'Recurring_Donation_Recurring_Type__c': 'Fixed',
                    'Payment_Method__c': 'Credit Card'
                }
            };
            await flushPromises();

            const saveButton = element.shadowRoot.querySelector('[data-id="bgeSaveButton"]');
            expect(saveButton.disabled).toBeFalsy();
        });

        it('save button is disabled when schedule recurring type is Fixed for Elevate RD and widget is present and not disabled', async() => {
            retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
            getAllocationsSettings.mockResolvedValue(allocationsSettingsNoDefaultGAU);

            const element = createElement('c-ge-form-renderer', {is: GeFormRenderer });
            element.batchId = 'DUMMY_BATCH_ID';

            Settings.isElevateCustomer = jest.fn(() => true);
            element.Settings = Settings;

            GeGatewaySettings.isValidElevatePaymentMethod = jest.fn(() => true);
            element.GeGatewaySettings = GeGatewaySettings;

            element.hasPaymentWidget = true;

            document.body.appendChild(element);
            await flushPromises();

            element.giftInView = {
                fields: {
                    'Recurring_Donation_Recurring_Type__c': 'Fixed',
                    'Payment_Method__c': 'Credit Card',
                    'Recurring_Donation_Elevate_Recurring_ID__c': 'DUMMY_RECURRING_ID'
                }
            };
            await flushPromises();

            const saveButton = element.shadowRoot.querySelector('[data-id="bgeSaveButton"]');
            expect(saveButton.disabled).toBeTruthy();
        });

        it('save button is not disabled when schedule recurring type is Fixed for Elevate RD and widget is disabled.', async() => {
            retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
            getAllocationsSettings.mockResolvedValue(allocationsSettingsNoDefaultGAU);

            const element = createElement('c-ge-form-renderer', {is: GeFormRenderer });
            element.batchId = 'DUMMY_BATCH_ID';

            Settings.isElevateCustomer = jest.fn(() => true);
            element.Settings = Settings;

            GeGatewaySettings.isValidElevatePaymentMethod = jest.fn(() => true);
            element.GeGatewaySettings = GeGatewaySettings;

            element.hasPaymentWidget = true;

            document.body.appendChild(element);
            await flushPromises();

            element.giftInView = {
                fields: {
                    'Recurring_Donation_Recurring_Type__c': 'Fixed',
                    'Payment_Method__c': 'Credit Card'
                }
            };
            await flushPromises();

            pubSub.fireEvent({}, 'doNotChargeState', {isElevateWidgetDisabled: true});
            await flushPromises();

            const saveButton = element.shadowRoot.querySelector('[data-id="bgeSaveButton"]');
            expect(saveButton.disabled).toBeFalsy();
        });

        it('save button is not disabled when schedule recurring type is Fixed for Elevate RD and widget is not on the form.', async() => {
            retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
            getAllocationsSettings.mockResolvedValue(allocationsSettingsNoDefaultGAU);

            const element = createElement('c-ge-form-renderer', {is: GeFormRenderer });
            element.batchId = 'DUMMY_BATCH_ID';

            Settings.isElevateCustomer = jest.fn(() => true);
            element.Settings = Settings;

            GeGatewaySettings.isValidElevatePaymentMethod = jest.fn(() => true);
            element.GeGatewaySettings = GeGatewaySettings;

            element.hasPaymentWidget = false;

            document.body.appendChild(element);
            await flushPromises();

            element.giftInView = {
                fields: {
                    'Recurring_Donation_Recurring_Type__c': 'Fixed',
                    'Payment_Method__c': 'Credit Card'
                }
            };
            await flushPromises();

            const saveButton = element.shadowRoot.querySelector('[data-id="bgeSaveButton"]');
            expect(saveButton.disabled).toBeFalsy();
        });

        it('renders make recurring button, when in batch mode and feature is enabled', async () => {
            retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
            getAllocationsSettings.mockResolvedValue(allocationsSettingsNoDefaultGAU);
            const element = createElement('c-ge-form-renderer', {is: GeFormRenderer });

            const DUMMY_BATCH_ID = 'a0T11000007F8WQEA0';

            document.body.appendChild(element);
            await flushPromises();

            // simulate getting back data for DUMMY_CONTACT_ID
            element.batchId = DUMMY_BATCH_ID;
            await flushPromises();

            getRecord.emit(dataImportBatchRecord, config => {
                return config.recordId === DUMMY_BATCH_ID;
            });
            await flushPromises();

            const button = element.shadowRoot.querySelectorAll('[data-id="recurringButton"]');
            expect(button).toHaveLength(1);
        });

        it('does not render make recurring button, when in batch mode and feature is disabled', async () => {
            retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
            getAllocationsSettings.mockResolvedValue(allocationsSettingsNoDefaultGAU);
            const element = createElement('c-ge-form-renderer', {is: GeFormRenderer });
            const DUMMY_BATCH_ID = 'a0T11000007F8WQEA0';

            element.batchId = DUMMY_BATCH_ID;

            dataImportBatchRecord.fields['Allow_Recurring_Donations__c'].value = 'false';

            await flushPromises();

            // simulate getting back data for DUMMY_CONTACT_ID
            getRecord.emit(dataImportBatchRecord, config => {
                return config.recordId === DUMMY_BATCH_ID;
            });

            await flushPromises();


            const button = element.shadowRoot.querySelectorAll('[data-id="recurringButton"]');
            expect(button).toHaveLength(0);
        });

        it('does not render make recurring button, when in single mode', async () => {
            retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
            getAllocationsSettings.mockResolvedValue(allocationsSettingsNoDefaultGAU);
            const element = createElement('c-ge-form-renderer', {is: GeFormRenderer });

            document.body.appendChild(element);
            await flushPromises();

            const button = element.shadowRoot.querySelectorAll('[data-id="recurringButton"]');
            expect(button).toHaveLength(0);
        });
    });

    describe('events', () => {
        it('dispatches an event to display recurring donation schedule modal', async () => {
            retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
            getAllocationsSettings.mockResolvedValue(allocationsSettingsNoDefaultGAU);
            const element = createElement('c-ge-form-renderer', {is: GeFormRenderer });
            const DUMMY_BATCH_ID = 'a0T11000007F8WQEA0';

            element.batchId = DUMMY_BATCH_ID;

            document.body.appendChild(element);

            await flushPromises();

            // simulate getting back data for DUMMY_CONTACT_ID
            getRecord.emit(dataImportBatchRecord, config => {
                return config.recordId === DUMMY_BATCH_ID;
            });

            await flushPromises();

            const dispatchEventSpy = jest.spyOn(element, 'dispatchEvent');
            const button = element.shadowRoot.querySelector('[data-id="recurringButton"]');
            button.click();

            await flushPromises();

            expect(dispatchEventSpy).toHaveBeenCalledTimes(1);
            const componentName = dispatchEventSpy.mock.calls[0][0].detail.modalProperties.componentName;
            expect(componentName).toBe('geModalRecurringDonation');
        });

        it('dispatches an event to display a warning modal when adding schedule for gift with net new soft credits', async () => {
            retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
            getAllocationsSettings.mockResolvedValue(allocationsSettingsNoDefaultGAU);
            const element = createElement('c-ge-form-renderer', {is: GeFormRenderer });
            const DUMMY_BATCH_ID = 'a0T11000007F8WQEA0';

            element.batchId = DUMMY_BATCH_ID;

            document.body.appendChild(element);

            await flushPromises();

            // simulate getting back data for DUMMY_CONTACT_ID
            getRecord.emit(dataImportBatchRecord, config => {
                return config.recordId === DUMMY_BATCH_ID;
            });
            element.giftInView = {
                fields: {
                    'Payment_Method__c': 'Credit Card',
                    'Donation_Amount__c': '0.01'
                },
                softCredits: '[{"Role":"", "ContactId":"", "key":0}]'
            };

            await flushPromises();

            const dispatchEventSpy = jest.spyOn(element, 'dispatchEvent');
            const button = element.shadowRoot.querySelector('[data-id="recurringButton"]');
            button.click();

            await flushPromises();

            expect(dispatchEventSpy).toHaveBeenCalledTimes(1);
            const componentName = dispatchEventSpy.mock.calls[0][0].detail.modalProperties.componentName;
            expect(componentName).toBe('geModalPrompt');
        });
    });

    it('loads a template with four sections', async () => {

        retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
        getAllocationsSettings.mockResolvedValue(allocationsSettingsNoDefaultGAU);
        const element = createElement('c-ge-form-renderer', {is: GeFormRenderer });

        document.body.appendChild(element);
        await flushPromises();

        expect(retrieveDefaultSGERenderWrapper).toHaveBeenCalledTimes(1);
        const sections = element.shadowRoot.querySelectorAll('c-ge-form-section');
        expect(sections).toHaveLength(4);
    });

    it('form when saving without filling anything in should result in a page level error for missing fields', async () => {
        retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
        // This error is specific to this mockRenderWrapperWithNoNames
        // Donor Type, Donation Date, Donation Amount, Payment Method should appear as required
        getAllocationsSettings.mockResolvedValue(allocationsSettingsNoDefaultGAU);

        mockCheckInputValidity.mockReturnValue(true); // lightning-input is always valid
        mockCheckComboboxValidity.mockReturnValue(true); // lightning-combobox is always valid

        const element = createElement('c-ge-form-renderer', {is: GeFormRenderer});
        document.body.appendChild(element);

        await flushPromises();
        const saveButton = element.shadowRoot.querySelectorAll('lightning-button')[1];
        saveButton.click();

        await flushPromises();

        const pageLevelMessage = element.shadowRoot.querySelector('c-util-page-level-message');
        const pElement = pageLevelMessage.querySelector('p');

        expect(pElement.innerHTML).toBe('The following fields are required: Donor Type, Donation Date, Donation Amount');
    });

    it('form with payment widget, when payment method changed to credit card then payment iframe loads', async () => {
        retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);

        mockCheckInputValidity.mockReturnValue(true); // lightning-input will always report it is valid
        mockCheckComboboxValidity.mockReturnValue(true); // lightning-combobox will always report it is valid
        getAllocationsSettings.mockResolvedValue(allocationsSettingsNoDefaultGAU);

        const element = createElement('c-ge-form-renderer', {is: GeFormRenderer});
        Settings.isElevateCustomer = jest.fn(() => true);
        element.Settings = Settings;
        document.body.appendChild(element);
        await flushPromises();

        const sectionWithWidget = element.shadowRoot.querySelectorAll('c-ge-form-section')[0];
        expect(sectionWithWidget.isPaymentWidgetAvailable).toBeTruthy();
        element.giftInView = {
            fields: { 'Payment_Method__c': 'Credit Card' },
            softCredits: { all: [] }
        };
        await flushPromises();

        const {commonPaymentServices} = GeLabelService.CUSTOM_LABELS;
        const iframeSelector = `iframe[data-id='${commonPaymentServices}']`;
        const selectors = ['c-ge-form-widget', 'c-ge-form-widget-tokenize-card', iframeSelector];
        const iframeElement = traverse(sectionWithWidget, ...selectors);

        expect(iframeElement).toMatchSnapshot();
    });


    it('form without contact firstname when lookup populated and widget in chargeable state then sendPurchaseRequest is called with first name',
        async () => {
            const EXPECTED_PURCHASE_BODY_PARAMS = JSON.stringify({
                "firstName": "",
                "lastName": "DummyLastName",
                "metadata": {},
                "amount": 1,
                "paymentMethodToken": "a_dummy_token",
                "paymentMethodType": "CARD"
            });
            const EXPECTED_UPSERT_DATAIMPORT_FIELDS = {
                Payment_Method__c: "Credit Card",
                Donation_Amount__c: '0.01',
                Contact1Imported__c: '003J000001zoYLGIA2',
                Donation_Date__c: '2021-02-23',
                Donation_Donor__c: 'Contact',
                Contact1_Lastname__c: 'DummyLastName',
            };
            const DUMMY_CONTACT_ID = '003J000001zoYLGIA2';

            retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
            mockCheckInputValidity.mockReturnValue(true); // lightning-inputs always report they are valid
            mockCheckComboboxValidity.mockReturnValue(true); // lightning-comboboxes always report they are valid
            getAllocationsSettings.mockResolvedValue(allocationsSettingsNoDefaultGAU);

            mockGetIframeReply.mockImplementation((iframe, message, targetOrigin) => {
                // if message action is "createToken", reply with dummy token immediately
                // instead of trying to hook into postMessage
                // see sendIframeMessage in mocked psElevateTokenHandler
                if (message.action === 'createToken') {
                    return {"type": "post__npsp", "token": "a_dummy_token"};
                }
            });

            upsertDataImport.mockImplementation((dataImport) => {
                return { Id: 'fakeDataImportId', ...dataImport };
            });

            const element = createElement('c-ge-form-renderer', {is: GeFormRenderer});
            GeGatewaySettings.isValidElevatePaymentMethod = jest.fn(() => true);
            element.GeGatewaySettings = GeGatewaySettings;
            document.body.appendChild(element);

            getObjectInfo.emit(dataImportObjectInfo, config => {
                return config?.objectApiName?.objectApiName === 'DataImport__c';
            });

            await flushPromises();

            const sectionWithWidget = element.shadowRoot.querySelectorAll('c-ge-form-section')[0];

            expect(sectionWithWidget.isPaymentWidgetAvailable).toBeTruthy();
            element.giftInView = {
                fields: {
                    'Payment_Method__c': 'Credit Card',
                    'Donation_Amount__c': '0.01',
                    'Contact1Imported__c': DUMMY_CONTACT_ID,
                    'Donation_Date__c': '2021-02-23',
                    'Donation_Donor__c': 'Contact',
                    'Payment_Authorization_Token__c': 'a_dummy_token',
                    'Contact1_Lastname__c': 'DummyLastName'
                },
                softCredits: { all: [] }
            };
            await flushPromises();

            // simulate getting back data for DUMMY_CONTACT_ID
            getRecord.emit(getRecordContact1Imported, config => {
                return config.recordId === DUMMY_CONTACT_ID;
            });
            await flushPromises();
            // resolve form updates before clicking save button

            const saveButton = element.shadowRoot.querySelectorAll('lightning-button')[1];
            saveButton.click();
            await flushPromises();

            expect(sendPurchaseRequest).toHaveBeenCalledTimes(1);
            expect(upsertDataImport).toHaveBeenCalledTimes(1);
            expect(sendPurchaseRequest).toHaveBeenLastCalledWith({
                dataImportRecordId: undefined,
                requestBodyParameters: EXPECTED_PURCHASE_BODY_PARAMS
            });
            expect(upsertDataImport).toHaveBeenLastCalledWith({
                dataImport: JSON.stringify(EXPECTED_UPSERT_DATAIMPORT_FIELDS)
            });
        });
});

const traverse = (element, ...selectors) => {
    if(selectors.length === 1) {
        return element.shadowRoot.querySelector(selectors[0]);
    }
    const [firstSelector, ...rest] = selectors;
    const nextElement = element.shadowRoot.querySelector(firstSelector);
    return traverse(nextElement, ...rest);
}


