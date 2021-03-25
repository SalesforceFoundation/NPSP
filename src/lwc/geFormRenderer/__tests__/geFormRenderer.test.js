import { createElement } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import GeFormRenderer from 'c/geFormRenderer';
import GeLabelService from 'c/geLabelService';

import upsertDataImport from '@salesforce/apex/GE_GiftEntryController.upsertDataImport';
import retrieveDefaultSGERenderWrapper from '@salesforce/apex/GE_GiftEntryController.retrieveDefaultSGERenderWrapper';
import sendPurchaseRequest from '@salesforce/apex/GE_GiftEntryController.sendPurchaseRequest';

import { mockCheckInputValidity } from 'lightning/input';
import { mockCheckComboboxValidity } from 'lightning/combobox';
import { mockGetIframeReply } from 'c/psElevateTokenHandler';

const mockWrapperWithNoNames = require('./data/retrieveDefaultSGERenderWrapper.json');
const getRecordContact1Imported = require('./data/getRecordContact1Imported.json');
const dataImportObjectInfo = require('./data/dataImportObjectInfo.json');

describe('c-ge-form-renderer', () => {

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    it('loads with template', () => {
        retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
        const element = createElement('c-ge-form-renderer', { is: GeFormRenderer });
        document.body.appendChild(element);
        return flushPromises().then(() => {
            expect(retrieveDefaultSGERenderWrapper).toHaveBeenCalledTimes(1);
            expect(element).toMatchSnapshot();
            const sections = element.shadowRoot.querySelectorAll('c-ge-form-section');
            expect(sections).toHaveLength(4);
        });
    });

    it('updates form state when a field is changed', () => {
        retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
        const element = createElement('c-ge-form-renderer', { is: GeFormRenderer });
        document.body.appendChild(element);
        return flushPromises().then(() => {
            const sections = element.shadowRoot.querySelectorAll('c-ge-form-section');
            const account1BillingCity = sections[1].shadowRoot.querySelectorAll('c-ge-form-field')[1];
            const changeEvent = new CustomEvent('formfieldchange', {
                detail: {
                    value: 'Gary',
                    label: 'Gary',
                    fieldMappingDevName: 'Account1_City_a992c3bb1'
                }
            });
            account1BillingCity.dispatchEvent(changeEvent);
            return flushPromises().then(() => {

            });
        });
    });


    it('saving without filling anything in should result in a page level error for missing fields', () => {
        retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
        // This error is specific to this mockRenderWrapperWithNoNames
        // Donor Type, Donation Date, Donation Amount, Payment Method should appear as required

        mockCheckInputValidity.mockReturnValue(true); // lightning-input is always valid
        mockCheckComboboxValidity.mockReturnValue(true); // lightning-combobox is always valid

        const element = createElement('c-ge-form-renderer', {is: GeFormRenderer});
        document.body.appendChild(element);

        const mockSubmit = jest.fn();
        element.addEventListener('submit', mockSubmit);

        return flushPromises().then(() => {
            const saveButton = element.shadowRoot.querySelectorAll('lightning-button')[1];
            saveButton.click();
            return flushPromises().then(() => {
                expect(element).toMatchSnapshot();
            });
        });
    });

    it('form with payment widget, when payment method changed to credit card then payment iframe loads', () => {
        retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);

        mockCheckInputValidity.mockReturnValue(true); // lightning-input is always valid
        mockCheckComboboxValidity.mockReturnValue(true); // lightning-combobox is always valid

        const element = createElement('c-ge-form-renderer', { is: GeFormRenderer });
        document.body.appendChild(element);

        const mockSubmit = jest.fn();
        element.addEventListener('submit', mockSubmit);

        return flushPromises().then(() => {
            const sections = element.shadowRoot.querySelectorAll('c-ge-form-section');
            // for this template, the account1 billing city field is the second field in the second section

            const sectionWithWidget = sections[0];
            expect(sectionWithWidget.isPaymentWidgetAvailable).toBeTruthy(); // widget in first section
            dispatchFormFieldChange(sectionWithWidget, 'Credit Card', 'Payment_Method_87c012365');

            return flushPromises().then(() => {

                const { commonPaymentServices } = GeLabelService.CUSTOM_LABELS;
                const iframeSelector = `iframe[data-id='${commonPaymentServices}']`;
                const selectors = ['c-ge-form-widget', 'c-ge-form-widget-tokenize-card', iframeSelector];
                const iframeElement = traverse(sectionWithWidget, ...selectors);
                expect(iframeElement).toMatchSnapshot();
            });
        });
    });


    it('form without contact firstname when lookup populated and widget in chargeable state then sendPurchaseRequest is called with first name', () => {
        const EXPECTED_PURCHASE_BODY_PARAMS = '{"firstName":"Hasa","lastName":"FirstName","metadata":{},"amount":1,"paymentMethodToken":"a_dummy_token","paymentMethodType":"CARD"}';
        const EXPECTED_UPSERT_DATAIMPORT_FIELDS = {
            Donation_Donor__c: 'Contact',
            Contact1Imported__c: '003J000001zoYLGIA2',
            Donation_Date__c: '2021-02-23',
            Donation_Amount__c: '0.01',
            Payment_Authorization_Token__c: "a_dummy_token",
            Payment_Method__c: "Credit Card",
            Payment_Status__c: "PENDING"
        };
        const DUMMY_CONTACT_ID = '003J000001zoYLGIA2';

        retrieveDefaultSGERenderWrapper.mockResolvedValue(mockWrapperWithNoNames);
        mockCheckInputValidity.mockReturnValue(true); // lightning-inputs always report they are valid
        mockCheckComboboxValidity.mockReturnValue(true); // lightning-comboboxes always report they are valid

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

        const element = createElement('c-ge-form-renderer', { is: GeFormRenderer });
        document.body.appendChild(element);

        getObjectInfo.emit(dataImportObjectInfo, config => {
            return config.objectApiName.objectApiName === 'DataImport__c';
        });

        return flushPromises().then(() => {
            const sectionWithWidget = element.shadowRoot.querySelectorAll('c-ge-form-section')[0];

            expect(sectionWithWidget.isPaymentWidgetAvailable).toBeTruthy();

            dispatchFormFieldChange(sectionWithWidget, 'Credit Card', 'Payment_Method_87c012365');
            dispatchFormFieldChange(sectionWithWidget, 'Contact', 'Donation_Donor__c');
            dispatchFormFieldChange(sectionWithWidget, '0.01', 'Donation_Amount_9e48e0798');
            dispatchFormFieldChange(sectionWithWidget, '2021-02-23', 'Donation_Date_de92fcb14');
            dispatchFormFieldChange(sectionWithWidget, DUMMY_CONTACT_ID, 'Contact1Imported__c');
        }).then(() => {
            // wire request must exist before we can emit to it
            // setting Contact1Imported__c will create the wire request
            getRecord.emit(getRecordContact1Imported, config => {
                return config.recordId === DUMMY_CONTACT_ID;
            });
        }).then(() => {
            // loading the contact causes updates to the form, allow those to resolve
            // so when save button is clicked those fields are populated
            const saveButton = element.shadowRoot.querySelectorAll('lightning-button')[1];
            saveButton.click();

            return flushPromises().then(() => {

                expect(sendPurchaseRequest).toHaveBeenCalledTimes(1);
                expect(upsertDataImport).toHaveBeenCalledTimes(1);

                expect(sendPurchaseRequest).toHaveBeenLastCalledWith({
                    dataImportRecordId: undefined,
                    requestBodyParameters: EXPECTED_PURCHASE_BODY_PARAMS
                });

                expect(upsertDataImport).toHaveBeenLastCalledWith({
                    dataImport: expect.objectContaining(EXPECTED_UPSERT_DATAIMPORT_FIELDS)
                });

                // first name should not be present in upsert request if not on template
                expect(upsertDataImport).toHaveBeenLastCalledWith({
                    dataImport: expect.not.objectContaining({
                        Contact1_Firstname__c: expect.anything(),
                        Contact1_LastName__c: expect.anything()
                    })
                });
            });
        });
    });
});

const getFieldByIndex = (rendererElement, sectionIndex, fieldIndex) => {
    const sections = rendererElement.shadowRoot.querySelectorAll('c-ge-form-section');
    return sections[sectionIndex].shadowRoot.querySelectorAll('c-ge-form-field')[fieldIndex];
}

const traverse = (element, ...selectors) => {
    if(selectors.length === 1) {
        return element.shadowRoot.querySelector(selectors[0]);
    }
    const [firstSelector, ...rest] = selectors;
    const nextElement = element.shadowRoot.querySelector(firstSelector);
    return traverse(nextElement, ...rest);
}

const dispatchFormFieldChange = (element, value, fieldMappingDevName) => {
    const changeEvent = new CustomEvent('formfieldchange', {
        detail: {
            value,
            "label": value,
            fieldMappingDevName
        }
    });
    element.dispatchEvent(changeEvent);
};


