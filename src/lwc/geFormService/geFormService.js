import getRenderWrapper from '@salesforce/apex/GE_TemplateBuilderCtrl.retrieveDefaultSGERenderWrapper';
import getFormRenderWrapper
    from '@salesforce/apex/GE_FormServiceController.getFormRenderWrapper';
import getAllocationSettings from '@salesforce/apex/GE_FormRendererService.getAllocationsSettings';
import makePurchaseCall from '@salesforce/apex/GE_GiftEntryController.makePurchaseCall';
import saveDataImport from '@salesforce/apex/GE_GiftEntryController.saveDataImport';
import processDataImport from '@salesforce/apex/GE_GiftEntryController.processDataImport';
import saveAndDryRunDataImport
    from '@salesforce/apex/GE_GiftEntryController.saveAndDryRunDataImport';

import { handleError } from 'c/utilTemplateBuilder';
import { api } from 'lwc';
import { isNotEmpty, isEmpty, deepClone } from 'c/utilCommon';
import {registerListener, unregisterListener} from 'c/pubsubNoPageRef';

import OPPORTUNITY_AMOUNT from '@salesforce/schema/Opportunity.Amount';
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import DI_PAYMENT_STATUS_FIELD from '@salesforce/schema/DataImport__c.Payment_Status__c';
import DI_PAYMENT_DECLINED_REASON_FIELD from '@salesforce/schema/DataImport__c.Payment_Declined_Reason__c';
import DI_ADDITIONAL_OBJECT_JSON_FIELD from '@salesforce/schema/DataImport__c.Additional_Object_JSON__c';
import DI_PAYMENT_AUTHORIZE_TOKEN_FIELD from '@salesforce/schema/DataImport__c.Payment_Authorization_Token__c';
import DI_PAYMENT_METHOD_FIELD from '@salesforce/schema/DataImport__c.Payment_Method__c';

const PAYMENT_STATUS__C = DI_PAYMENT_STATUS_FIELD.fieldApiName;
const PAYMENT_DECLINED_REASON__C = DI_PAYMENT_DECLINED_REASON_FIELD.fieldApiName;
const ADDITIONAL_OBJECT_JSON__C = DI_ADDITIONAL_OBJECT_JSON_FIELD.fieldApiName;
const PAYMENT_AUTHORIZE_TOKEN__C = DI_PAYMENT_AUTHORIZE_TOKEN_FIELD.fieldApiName;
const PAYMENT_METHOD__C = DI_PAYMENT_METHOD_FIELD.fieldApiName;
const TOKENIZE_TIMEOUT = 10000; // 10 seconds, long enough for cold starts?
const CAPTURED = 'CAPTURED';

// https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_enum_Schema_DisplayType.htm
// this list only includes fields that can be handled by lightning-input
const inputTypeByDescribeType = {
    'BOOLEAN': 'checkbox',
    'CURRENCY': 'number',
    'DATE': 'date',
    'DATETIME': 'datetime-local',
    'EMAIL': 'email',
    'DOUBLE': 'number',
    'INTEGER': 'number',
    'LONG': 'number',
    'PERCENT': 'number',
    'STRING': 'text',
    'PHONE': 'tel',
    'TEXT': 'text',
    'TIME': 'time',
    'URL': 'url'
};

const numberFormatterByDescribeType = {
  'PERCENT': 'percent-fixed',
  'CURRENCY': 'currency',
  'DECIMAL': 'decimal'
};

class GeFormService {

    fieldMappings;
    objectMappings;
    fieldTargetMappings;
    donationFieldTemplateLabel;
    tokenPromise;
    fabricatedCardholderNames;
    previouslySavedDataImport;

    constructor() {
        registerListener('tokenRequested', this.handleTokenRequested, this);
    }

    @api
    setFabricatedCardholderNames(cardholderNames) {
        this.fabricatedCardholderNames = JSON.stringify(cardholderNames);
    }

    /**
     * Retrieve the default form render wrapper.
     * @returns {Promise<FORM_RenderWrapper>}
     */
    @api
    getFormTemplate() {
        return new Promise((resolve, reject) => {
            getRenderWrapper({})
                .then((result) => {
                    this.fieldMappings = result.fieldMappingSetWrapper.fieldMappingByDevName;
                    this.objectMappings = result.fieldMappingSetWrapper.objectMappingByDevName;
                    this.fieldTargetMappings = result.fieldMappingSetWrapper.fieldMappingByTargetFieldName;
                    if(isEmpty(this.donationFieldTemplateLabel)) {
                        this.donationFieldTemplateLabel = this.getDonationAmountCustomLabel(result.formTemplate);
                    }
                    resolve(result);
                })
                .catch(error => {
                    handleError(error);
                });
        });
    }

    getAllocationSettings() {
        return new Promise((resolve, reject) => {
           getAllocationSettings()
               .then(resolve)
               .catch(handleError)
        });
    }

    /**
     * Get the type of lightning-input that should be used for a given field type.
     * @param dataType  Data type of the field
     * @returns {String}
     */
    getInputTypeFromDataType(dataType) {
        return inputTypeByDescribeType[dataType];
    }

    /**
     * Get the formatter for a lightning-input that should be used for a given field type
     * @param dataType  Data type of the field
     * @returns {String | undefined}
     */
    getNumberFormatterByDescribeType(dataType) {
        return numberFormatterByDescribeType[dataType];
    }

    /**
     * Get a field info object by dev name from the render wrapper object
     * @param fieldDevName  Dev name of the object to retrieve
     * @returns {BDI_FieldMapping}
     */
    getFieldMappingWrapper(fieldDevName) {
        return this.fieldMappings[fieldDevName];
    }

    /**
     * Get a field info object by dev name from the render wrapper object
     * @param fieldDevName  Dev name of the object to retrieve
     * @returns {BDI_FieldMapping}
     */
    getFieldMappingWrapperFromTarget(targetFieldName) {
        return this.fieldTargetMappings[targetFieldName];
    }

    /**
     * Get a object info object by dev name from the render wrapper object
     * @param objectDevName
     * @returns {BDI_ObjectMapping}
     */
    getObjectMappingWrapper(objectDevName) {
        return this.objectMappings[objectDevName];
    }

    /**
     * Get the user-defined label used for the Opportunity Amount field on the
     * @return {string}
     */
    getDonationAmountCustomLabel(formTemplate) {
        // find field that is mapped to Opportunity Amount
        const mapping = this.getFieldMappingWrapperFromTarget(`${OPPORTUNITY_OBJECT.objectApiName}.${OPPORTUNITY_AMOUNT.fieldApiName}`);
        const mappingDevName = mapping.DeveloperName;
        // get developer name of mapping cmt
        let fieldElement;
        for(const section of formTemplate.layout.sections) {
           fieldElement = section.elements.find( element => {
               if(Array.isArray(element.dataImportFieldMappingDevNames)) {
                   return element.dataImportFieldMappingDevNames.includes(mappingDevName);
               }
           });
        }

        if(isNotEmpty(fieldElement)) {
            // return custom label from the form template layout
            return fieldElement.customLabel;
        }
    }

    handleTokenRequested() {
        console.log('*** handleTokenRequested');
        this.tokenPromise = new Promise((resolve, reject) => {
            registerListener('tokenResponse', message => {
                if(message.error) {
                    reject(message);
                } else if(message.token) {
                    resolve(message.token);
                }
            }, this);
            setTimeout(() => {
                reject('Request timed out');
                unregisterListener('tokenResponse', resolve, this);
            }, TOKENIZE_TIMEOUT);
        });
    }

    /*******************************************************************************
    * @description Upserts the provided data import record. Attempts to retrieve
    * an Elevate token for a purchase call if needed.
    *
    * @param {object} dataImportRecord: A DataImport__c record
    *
    * @return {object} dataImportRecord: A DataImport__c record
    */
    saveDataImport = async (dataImportRecord) => {
        console.log('*** *** saveDataImport');
        dataImportRecord[PAYMENT_AUTHORIZE_TOKEN__C] = await this.tokenPromise;
        const dataImport = await saveDataImport({ dataImport: dataImportRecord });

        if (this.previouslySavedDataImport && this.previouslySavedDataImport.Id === dataImport.Id ) {
            console.log('SAVE PREVIOUSLY ATTEMPTED: ', this.previouslySavedDataImport);
            dataImport[PAYMENT_STATUS__C] = this.previouslySavedDataImport[PAYMENT_STATUS__C];
            dataImport[PAYMENT_DECLINED_REASON__C] = this.previouslySavedDataImport[PAYMENT_DECLINED_REASON__C];
            dataImport[PAYMENT_METHOD__C] = this.previouslySavedDataImport[PAYMENT_METHOD__C];
        } else {
            this.previouslySavedDataImport = deepClone(dataImportRecord);
        }

        return dataImport;
    }

    /*******************************************************************************
    * @description Method attempts to make a purchase call to Payment
    * Services. Immediately attempts to the charge the card provided in the Payment
    * Services iframe (GE_TokenizeCard).
    *
    * @param {object} dataImportRecord: A DataImport__c record
    * @param {function} errorCallback: An error handler function. Toggles
    *   the form save button, lightning spinner, and catches aura exceptions.
    *
    * @return {object} dataImportRecord: A DataImport__c record
    */
    handlePaymentProcessing = async (dataImportRecord, errorCallback) => {
        if (this.previouslySavedDataImport[PAYMENT_STATUS__C] !== CAPTURED) {
            const purchaseCallResponse =
                await this.handlePurchaseCall(dataImportRecord, this.fabricatedCardholderNames);
            if (purchaseCallResponse) {
                console.log('purchaseCallResponse: ', purchaseCallResponse);
                dataImportRecord = this.setPaymentStatusAndDeclineReason(dataImportRecord, purchaseCallResponse);
                dataImportRecord = await saveDataImport({ dataImport: dataImportRecord });
                this.previouslySavedDataImport = deepClone(dataImportRecord);
            }

            if (purchaseCallResponse.statusCode !== 201) {

                let errors =
                    purchaseCallResponse.body.Message ||
                    purchaseCallResponse.body.errors.map(error => error.message).join(', ');
                console.log('throwing purchase call error');
                errorCallback(errors);
                return undefined;
            }
        }

        return dataImportRecord;
    }

    /*******************************************************************************
    * @description Posts an http request through the `makePurchaseCall` apex
    * method and parses the response.
    *
    * @param {object} dataImportRecord: A DataImport__c record
    *
    * @return {object} response: An http response object
    */
    handlePurchaseCall = async (dataImportRecord, fabricatedCardholderNames) => {
        let purchaseCallResponseString = await makePurchaseCall({
            dataImportRecord: dataImportRecord,
            cardholderNames: fabricatedCardholderNames
        });
        let response = JSON.parse(purchaseCallResponseString);
        response.body = JSON.parse(response.body);

        return response;
    }

    /*******************************************************************************
    * @description Method sets values Payment Services related Data Import fields.
    * Payment_Status__c and Payment_Declined_Reason__c.
    *
    * @param {object} dataImportRecord: A DataImport__c record
    * @param {object} purchaseResponse: An http response object
    *
    * @return {object} dataImportRecord: A DataImport__c record
    */
    setPaymentStatusAndDeclineReason = (dataImportRecord, purchaseCallResponse) => {
        console.log('*** setPaymentStatusAndDeclineReason');
        const paymentStatus = purchaseCallResponse.body.status || purchaseCallResponse.status || 'Unknown';
        dataImportRecord[PAYMENT_STATUS__C] = paymentStatus;

        const isSuccessfulPurchase = purchaseCallResponse.statusCode === 201;
        if (isSuccessfulPurchase) {
            // TODO: How do we want to handle payment method for successful charges? What about failed charges?
            dataImportRecord[PAYMENT_METHOD__C] = 'Credit Card';
            dataImportRecord[PAYMENT_DECLINED_REASON__C] = null;
        } else {
            dataImportRecord[PAYMENT_DECLINED_REASON__C] = JSON.stringify(purchaseCallResponse.body);
        }

        return dataImportRecord;
    }

    /*******************************************************************************
    * @description Method handles saving and processing a Data Import record.
    *
    * @param {object} dataImportRecord: A DataImport__c record
    * @param {boolean} hasUserSelectedDonation: True if a user has selected a
    *   donation/payment through the 'Review Donations' modal. It means that we're
    *   attempting to match to a specific donation record during BDI processing.
    *
    * @return {string} opportunityId: An Opportunity record id
    */
    handleProcessDataImport = async (dataImportRecord, hasUserSelectedDonation) => {
        console.log('*** handleProcessDataImport');
        const opportunityId = await processDataImport({
            diRecord: dataImportRecord,
            updateGift: hasUserSelectedDonation
        });
        console.log('opportunityId: ', opportunityId);

        return opportunityId;
    }

    /**
     * Grab the data from the form fields and widgets, convert to a data import record.
     * @param sectionList   List of ge-form-sections on the form
     * @param dataImportWithDonorData        Existing account or contact record to attach to the data import record
     * @return {{widgetValues: {}, diRecord: {}}}
     */
    buildDataImportRecord(sectionList, dataImportWithDonorData) {
        let fieldData = {};
        let widgetValues = {};

        sectionList.forEach(section => {
            fieldData = {...fieldData, ...(section.values)};
            widgetValues = {...widgetValues, ...(section.widgetValues)};
        });

        // Build the DI Record
        let diRecord = {};

        for (let [key, value] of Object.entries(fieldData)) {
            let fieldWrapper = this.getFieldMappingWrapper(key);
            diRecord[fieldWrapper.Source_Field_API_Name] = value;
        }

        // Include any fields from a user selected donation, if
        // those fields are not already on the diRecord
        if (dataImportWithDonorData) {
            for (const [key, value] of Object.entries(dataImportWithDonorData)) {
                if (!diRecord.hasOwnProperty(key)) {
                    diRecord[key] = value === null || value.value === null ?
                        null : value.value || value;
                }
            }
        }

        // Set Data Import's additional object json field if,
        // we values from any form widgets
        if (widgetValues) {
            diRecord[ADDITIONAL_OBJECT_JSON__C] = JSON.stringify(widgetValues);
        }

        return diRecord;
    }

    saveAndDryRun(batchId, dataImport) {
        return new Promise((resolve, reject) => {
            saveAndDryRunDataImport({batchId, dataImport})
                .then((result) => {
                    resolve(JSON.parse(result));
                })
                .catch(error => {
                    reject(error);
                });
        });
    }

    getFormRenderWrapper(templateId) {
        return new Promise((resolve, reject) => {
            getFormRenderWrapper({templateId: templateId})
                .then(renderWrapper => {
                    this.fieldMappings =
                        renderWrapper.fieldMappingSetWrapper.fieldMappingByDevName;
                    this.objectMappings =
                        renderWrapper.fieldMappingSetWrapper.objectMappingByDevName;
                    this.fieldTargetMappings =
                        renderWrapper.fieldMappingSetWrapper.fieldMappingByTargetFieldName;
                    resolve(renderWrapper);
                })
                .catch(err => {
                    reject(err);
                });
        });

    }

    getFormTemplateById(templateId) {
        return new Promise((resolve, reject) => {
            this.getFormRenderWrapper(templateId)
                .then(renderWrapper => {
                    resolve(renderWrapper.formTemplate);
                })
                .catch(err => {
                    reject(err);
                });
        });
    }

    get importedRecordFieldNames() {
        return Object.values(this.objectMappings).map(
            ({Imported_Record_Field_Name}) =>
                Imported_Record_Field_Name
        );
    }

    getObjectMappingWrapperByImportedFieldName(importedFieldName) {
        return Object.values(this.objectMappings)
            .find(({Imported_Record_Field_Name}) =>
                Imported_Record_Field_Name === importedFieldName);
    }

}

const geFormServiceInstance = new GeFormService();

export default geFormServiceInstance;