/* eslint-disable @lwc/lwc/no-async-operation */
import { isEmpty, isNotEmpty, deepClone, showToast } from 'c/utilCommon';

// Import schema for additionally required fields for the template batch header
import DI_BATCH_NAME_FIELD_INFO from '@salesforce/schema/DataImportBatch__c.Name';

// Import custom label service
import GeLabelService from 'c/geLabelService';

// Import schema for excluded template batch header fields
import DI_BATCH_TABLE_COLUMNS_FIELD from '@salesforce/schema/DataImportBatch__c.Batch_Table_Columns__c';
import DI_BATCH_CREATED_BY_ID from '@salesforce/schema/DataImportBatch__c.CreatedById';
import DI_BATCH_CREATED_DATE from '@salesforce/schema/DataImportBatch__c.CreatedDate';
import DI_BATCH_IS_DELETED from '@salesforce/schema/DataImportBatch__c.IsDeleted';
import DI_BATCH_LAST_MODIFIED_BY_ID from '@salesforce/schema/DataImportBatch__c.LastModifiedById';
import DI_BATCH_LAST_MODIFIED_DATE from '@salesforce/schema/DataImportBatch__c.LastModifiedDate';
import DI_BATCH_LAST_REFERENCED_DATE from '@salesforce/schema/DataImportBatch__c.LastReferencedDate';
import DI_BATCH_LAST_VIEWED_DATE from '@salesforce/schema/DataImportBatch__c.LastViewedDate';
import DI_BATCH_SYSTEM_MODSTAMP from '@salesforce/schema/DataImportBatch__c.SystemModstamp';
import DI_BATCH_PROCESS_SIZE_INFO from '@salesforce/schema/DataImportBatch__c.Batch_Process_Size__c';
import DI_BATCH_RUN_ROLLUPS_WHILE_PROCESSING_INFO from '@salesforce/schema/DataImportBatch__c.Run_Opportunity_Rollups_while_Processing__c'
import DI_BATCH_STATUS_INFO from '@salesforce/schema/DataImportBatch__c.Batch_Status__c';
import DI_BATCH_DONATION_MATCHING_BEHAVIOR_INFO from '@salesforce/schema/DataImportBatch__c.Donation_Matching_Behavior__c'
import DI_BATCH_DONATION_MATCHING_IMPLENTING_CLASS_INFO from '@salesforce/schema/DataImportBatch__c.Donation_Matching_Implementing_Class__c'
import DI_BATCH_DONATION_MATCHING_RULE_INFO from '@salesforce/schema/DataImportBatch__c.Donation_Matching_Rule__c'
import DI_BATCH_DONATION_DATE_RANGE_INFO from '@salesforce/schema/DataImportBatch__c.Donation_Date_Range__c'
import DI_BATCH_POST_PROCESS_IMPLEMENTING_CLASS_INFO from '@salesforce/schema/DataImportBatch__c.Post_Process_Implementing_Class__c'
import DI_BATCH_OWNER_ID_INFO from '@salesforce/schema/DataImportBatch__c.OwnerId'
import DI_BATCH_ACCOUNT_CUSTOM_ID_INFO from '@salesforce/schema/DataImportBatch__c.Account_Custom_Unique_ID__c';
import DI_BATCH_ACTIVE_FIELDS_INFO from '@salesforce/schema/DataImportBatch__c.Active_Fields__c';
import DI_BATCH_CONTACT_CUSTOM_ID_INFO from '@salesforce/schema/DataImportBatch__c.Contact_Custom_Unique_ID__c';
import DI_BATCH_GIFT_BATCH_INFO from '@salesforce/schema/DataImportBatch__c.GiftBatch__c';
import DI_BATCH_LAST_PROCESSED_ON_INFO from '@salesforce/schema/DataImportBatch__c.Last_Processed_On__c';
import DI_BATCH_PROCESS_USING_SCHEDULED_JOB_INFO from '@salesforce/schema/DataImportBatch__c.Process_Using_Scheduled_Job__c';
import DI_BATCH_RECORDS_FAILED_INFO from '@salesforce/schema/DataImportBatch__c.Records_Failed__c';
import DI_BATCH_RECORDS_SUCCESSFULLY_PROCESSED_INFO from '@salesforce/schema/DataImportBatch__c.Records_Successfully_Processed__c';
import DI_BATCH_CONTACT_MATCHING_RULE_INFO from '@salesforce/schema/DataImportBatch__c.Contact_Matching_Rule__c';
import DI_BATCH_DESCRIPTION_INFO from '@salesforce/schema/DataImportBatch__c.Batch_Description__c';
import DI_BATCH_EXPECTED_COUNT_GIFTS_INFO from '@salesforce/schema/DataImportBatch__c.Expected_Count_of_Gifts__c';
import DI_BATCH_EXPECTED_TOTAL_BATCH_AMOUNT_INFO from '@salesforce/schema/DataImportBatch__c.Expected_Total_Batch_Amount__c';
import DI_BATCH_REQUIRED_TOTAL_TO_MATCH_INFO from '@salesforce/schema/DataImportBatch__c.RequireTotalMatch__c';
import DI_BATCH_DEFAULTS_INFO from '@salesforce/schema/DataImportBatch__c.Batch_Defaults__c';
import DI_BATCH_GIFT_ENTRY_VERSION_INFO from '@salesforce/schema/DataImportBatch__c.Batch_Gift_Entry_Version__c';
import DI_BATCH_FORM_TEMPLATE_INFO from '@salesforce/schema/DataImportBatch__c.Form_Template__c';
import DI_BATCH_ALLOW_RECURRING_DONATIONS from '@salesforce/schema/DataImportBatch__c.Allow_Recurring_Donations__c';
import DI_BATCH_LATEST_APEX_JOB_ID from '@salesforce/schema/DataImportBatch__c.Latest_Apex_Job_Id__c';
import FIELD_MAPPING_METHOD_FIELD_INFO from '@salesforce/schema/Data_Import_Settings__c.Field_Mapping_Method__c';
import GIFT_ENTRY_FEATURE_GATE_INFO from '@salesforce/schema/Gift_Entry_Settings__c.Enable_Gift_Entry__c';

// Import schema for default form field element objects
import DATA_IMPORT_INFO from '@salesforce/schema/DataImport__c';
import OPPORTUNITY_INFO from '@salesforce/schema/Opportunity';
import PAYMENT_INFO from '@salesforce/schema/npe01__OppPayment__c';

// Import schema info for default form field elements
import DONATION_AMOUNT_INFO from '@salesforce/schema/DataImport__c.Donation_Amount__c';
import DONATION_DATE_INFO from '@salesforce/schema/DataImport__c.Donation_Date__c';
import DONATION_CAMPAIGN_SOURCE_FIELD from '@salesforce/schema/DataImport__c.DonationCampaignImported__c';
import PAYMENT_CHECK_REF_NUM_INFO from '@salesforce/schema/DataImport__c.Payment_Check_Reference_Number__c';
import PAYMENT_METHOD_INFO from '@salesforce/schema/DataImport__c.Payment_Method__c';
import DI_ACCOUNT1_IMPORTED_INFO from '@salesforce/schema/DataImport__c.Account1Imported__c';
import DI_CONTACT1_IMPORTED_INFO from '@salesforce/schema/DataImport__c.Contact1Imported__c';
import DI_DONATION_DONOR_INFO from '@salesforce/schema/DataImport__c.Donation_Donor__c';
// Additional schema needed for donation donor validation
import DI_ACCOUNT1_NAME_INFO from '@salesforce/schema/DataImport__c.Account1_Name__c';
import DI_CONTACT1_LAST_NAME_INFO from '@salesforce/schema/DataImport__c.Contact1_Lastname__c';

import CONTACT_INFO from '@salesforce/schema/Contact';
import ACCOUNT_INFO from '@salesforce/schema/Account';

import CONTACT_FIRST_NAME_INFO from '@salesforce/schema/Contact.FirstName';
import CONTACT_LAST_NAME_INFO from '@salesforce/schema/Contact.LastName';
import ACCOUNT_NAME_INFO from '@salesforce/schema/Account.Name';

import commonError from '@salesforce/label/c.commonError';
import commonUnknownError from '@salesforce/label/c.commonUnknownError';

import getDataImportSettings from '@salesforce/apex/GE_GiftEntryController.getDataImportSettings';
import getGiftEntrySettings from
        '@salesforce/apex/GE_GiftEntryController.getGiftEntrySettings';

// relevant Donation_Donor picklist values
const CONTACT1 = 'Contact1';
const ACCOUNT1 = 'Account1';

// cache custom labels
const CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

const ADVANCED_MAPPING = 'Data Import Field Mapping';

const BATCH_CURRENCY_ISO_CODE = 'CurrencyIsoCode';

// relevant Donation_Donor custom validation fields
const DONATION_DONOR_FIELDS = {
    account1ImportedField:  DI_ACCOUNT1_IMPORTED_INFO.fieldApiName,
    account1NameField:      DI_ACCOUNT1_NAME_INFO.fieldApiName,
    contact1ImportedField:  DI_CONTACT1_IMPORTED_INFO.fieldApiName,
    contact1LastNameField:  DI_CONTACT1_LAST_NAME_INFO.fieldApiName,
    donationDonorField:     DI_DONATION_DONOR_INFO.fieldApiName
};

// encapsulate Donation_Donor picklist values
const DONATION_DONOR = {
    isAccount1: ACCOUNT1,
    isContact1: CONTACT1
};

const ADDITIONAL_REQUIRED_BATCH_HEADER_FIELDS = [
    DI_BATCH_NAME_FIELD_INFO.fieldApiName
];
Object.freeze(ADDITIONAL_REQUIRED_BATCH_HEADER_FIELDS);

const DEFAULT_BATCH_HEADER_FIELDS = [
    DI_BATCH_DESCRIPTION_INFO.fieldApiName,
    DI_BATCH_EXPECTED_COUNT_GIFTS_INFO.fieldApiName,
    DI_BATCH_EXPECTED_TOTAL_BATCH_AMOUNT_INFO.fieldApiName,
    DI_BATCH_REQUIRED_TOTAL_TO_MATCH_INFO.fieldApiName,
];
Object.freeze(DEFAULT_BATCH_HEADER_FIELDS);

// We've opted to exclude the following batch fields related to
// matching logic as we're removing the matching options page
// from this flow.
// We're considering putting matching options in a 'global
// batch settings' area. Potentially in NPSP Settings.
const EXCLUDED_BATCH_HEADER_FIELDS = [
    DI_BATCH_PROCESS_SIZE_INFO.fieldApiName,
    DI_BATCH_RUN_ROLLUPS_WHILE_PROCESSING_INFO.fieldApiName,
    DI_BATCH_STATUS_INFO.fieldApiName,
    DI_BATCH_DONATION_MATCHING_BEHAVIOR_INFO.fieldApiName,
    DI_BATCH_DONATION_MATCHING_IMPLENTING_CLASS_INFO.fieldApiName,
    DI_BATCH_DONATION_MATCHING_RULE_INFO.fieldApiName,
    DI_BATCH_DONATION_DATE_RANGE_INFO.fieldApiName,
    DI_BATCH_POST_PROCESS_IMPLEMENTING_CLASS_INFO.fieldApiName,
    DI_BATCH_OWNER_ID_INFO.fieldApiName,
    DI_BATCH_ACCOUNT_CUSTOM_ID_INFO.fieldApiName,
    DI_BATCH_ACTIVE_FIELDS_INFO.fieldApiName,
    DI_BATCH_CONTACT_CUSTOM_ID_INFO.fieldApiName,
    DI_BATCH_GIFT_BATCH_INFO.fieldApiName,
    DI_BATCH_LAST_PROCESSED_ON_INFO.fieldApiName,
    DI_BATCH_PROCESS_USING_SCHEDULED_JOB_INFO.fieldApiName,
    DI_BATCH_RECORDS_FAILED_INFO.fieldApiName,
    DI_BATCH_RECORDS_SUCCESSFULLY_PROCESSED_INFO.fieldApiName,
    DI_BATCH_CONTACT_MATCHING_RULE_INFO.fieldApiName,
    DI_BATCH_DEFAULTS_INFO.fieldApiName,
    DI_BATCH_GIFT_ENTRY_VERSION_INFO.fieldApiName,
    DI_BATCH_FORM_TEMPLATE_INFO.fieldApiName,
    DI_BATCH_TABLE_COLUMNS_FIELD.fieldApiName,
    DI_BATCH_CREATED_BY_ID.fieldApiName,
    DI_BATCH_CREATED_DATE.fieldApiName,
    DI_BATCH_IS_DELETED.fieldApiName,
    DI_BATCH_LAST_MODIFIED_BY_ID.fieldApiName,
    DI_BATCH_LAST_MODIFIED_DATE.fieldApiName,
    DI_BATCH_LAST_REFERENCED_DATE.fieldApiName,
    DI_BATCH_LAST_VIEWED_DATE.fieldApiName,
    DI_BATCH_SYSTEM_MODSTAMP.fieldApiName,
    DI_BATCH_ALLOW_RECURRING_DONATIONS.fieldApiName,
    DI_BATCH_LATEST_APEX_JOB_ID.fieldApiName,
    BATCH_CURRENCY_ISO_CODE
];
Object.freeze(EXCLUDED_BATCH_HEADER_FIELDS);

// Default form fields to add to new templates
const DEFAULT_FORM_FIELDS = {
    [DI_DONATION_DONOR_INFO.fieldApiName]: DATA_IMPORT_INFO.objectApiName,
    [DI_ACCOUNT1_IMPORTED_INFO.fieldApiName]: DI_ACCOUNT1_IMPORTED_INFO.objectApiName,
    [DI_CONTACT1_IMPORTED_INFO.fieldApiName]: DI_CONTACT1_IMPORTED_INFO.objectApiName,
    [DONATION_AMOUNT_INFO.fieldApiName]: OPPORTUNITY_INFO.objectApiName,
    [DONATION_DATE_INFO.fieldApiName]: OPPORTUNITY_INFO.objectApiName,
    [DONATION_CAMPAIGN_SOURCE_FIELD.fieldApiName]: OPPORTUNITY_INFO.objectApiName,
    [PAYMENT_CHECK_REF_NUM_INFO.fieldApiName]: PAYMENT_INFO.objectApiName,
    [PAYMENT_METHOD_INFO.fieldApiName]: PAYMENT_INFO.objectApiName,
}
Object.freeze(DEFAULT_FORM_FIELDS);

/*******************************************************************************
* @description Map of lightning-input types by data type.
*/
const inputTypeByDescribeType = {
    'address': 'text',
    'base64': 'text',
    'boolean': 'checkbox',
    'combobox': 'combobox',
    'currency': 'number',
    'datacategorygroupreference': 'text',
    'date': 'date',
    'datetime': 'datetime-local',
    'double': 'number',
    'email': 'email',
    'encryptedstring': 'password',
    'id': 'id',
    'integer': 'number',
    'long': 'textarea',
    'multipicklist': 'select',
    'percent': 'number',
    'phone': 'tel',
    'picklist': 'combobox',
    'reference': 'search',
    'string': 'text',
    'textarea': 'textarea',
    'time': 'time',
    'url': 'url',
    'richtext': 'richtext'
}

/*******************************************************************************
* @description Map of base lightning components by data type excluding
* lightning-input.
*/
const lightningInputTypeByDataType = {
    'richtext': 'lightning-input-rich-text',
    'textarea': 'lightning-textarea',
    'combobox': 'lightning-combobox'
}

// values used to enable picklist-to-checkbox mappings
const PICKLIST_TRUE = 'True';
const PICKLIST_FALSE = 'False';
const CHECKBOX_TRUE = 'true';
const CHECKBOX_FALSE = 'false';

/*******************************************************************************
* @description Collects all the missing required field mappings. Currently only
* checks 'requiredness' of the source (DataImport__c).
*
* @param {object} TemplateBuilderService: Instance of geTemplateBuilderService
* web component.
* @param {list} formSections: List of existing form sections in the template.
*
* @return {list} missingRequiredFieldMappings: List of missing field mappings.
*/
const findMissingRequiredFieldMappings = (TemplateBuilderService, formSections) => {
    const requiredFieldMappings =
        Object.keys(TemplateBuilderService.fieldMappingByDevName).filter(developerName => {
            if (TemplateBuilderService.fieldMappingByDevName[developerName].Is_Required) {
                return developerName;
            }
            return undefined;
        });

    let selectedFieldMappingDevNames =
        formSections
            .flatMap(section => section.elements)
            .map(element => {
                return element.componentName ? element.componentName : element.dataImportFieldMappingDevNames[0]
            });

    const missingRequiredFieldMappings =
        requiredFieldMappings
            .filter(developerName => !selectedFieldMappingDevNames.includes(developerName));

    return missingRequiredFieldMappings;
}

/*******************************************************************************
* @description Collects all the missing required DataImportBatch__c fields.
*
* @param {list} batchFields: List of all Batch Header fields.
* @param {list} selectedBatchFields: List of added Batch Header fields.
*
* @return {list} missingRequiredFields: List of missing DataImportBatch__c fields.
*/
const findMissingRequiredBatchFields = (batchFields, selectedBatchFields) => {
    let missingRequiredFields = [];
    const requireExpectedSelected = selectedBatchFields.find(bf => bf.apiName === DI_BATCH_REQUIRED_TOTAL_TO_MATCH_INFO.fieldApiName);

    const requiredFields = batchFields.filter(batchField => {
        if(requireExpectedSelected) {
            // if require expected totals to match is selected, require the field for expected count and total
            if(batchField.apiName === DI_BATCH_EXPECTED_TOTAL_BATCH_AMOUNT_INFO.fieldApiName) {
                return true;
            } else if(batchField.apiName === DI_BATCH_EXPECTED_COUNT_GIFTS_INFO.fieldApiName) {
                return true;
            }
        }
        return batchField.required;
    });
    const selectedFieldsExists = selectedBatchFields && selectedBatchFields.length > 0;
    requiredFields.forEach((field) => {
        if (selectedFieldsExists) {
            const alreadySelected = selectedBatchFields.find(bf => { return bf.apiName === field.apiName; });
            if (!alreadySelected) {
                missingRequiredFields = [...missingRequiredFields, { apiName: field.apiName, label: field.label }];
            }
        }
    });

    return missingRequiredFields;
};

/*******************************************************************************
* @description Dispatches a CustomEvent.
*
* @param {object} context: 'this' context from which to dispatch this event from.
* @param {string} name: Name of the CustomEvent.
* @param {object} detail: Detail object to pass in the event.
* @param {boolean} bubbles: Boolean flagging whether to bubble the event.
* @param {boolean} composed: Boolean flagging whether the event will trigger
* listeners outside of the shadow root.
*/
const dispatch = (context, name, detail, bubbles = false, composed = false) => {
    context.dispatchEvent(new CustomEvent(name, {
        detail: detail,
        bubbles: bubbles,
        composed: composed
    }));
}

/*******************************************************************************
* @description Creates and dispatches an error toast.
*
* @param {object} error: Event holding error details
*/
const handleError = (error) => {
    let message = buildErrorMessage(error);

    showToast(commonError, message, 'error', 'sticky');
};

const buildErrorMessage = (error) => {
    let message = commonUnknownError;

    // error.body is the error from apex calls
    // error.detail.output.errors is the error from record-edit-forms
    // error.body.output.errors is for AuraHandledException messages
    if (typeof error === 'string' || error instanceof String) {
        message = error;
    } else if (error.message) {
        message = error.message;
    } else if ((error.body && error.body.output) || error.detail) {
        if (Array.isArray(error.body) &&
            !error.body.output.errors) {
            message = error.body.map(e => e.message).join(', ');

        } else if (typeof error.body.message === 'string' &&
            !error.body.output.errors) {
            message = error.body.message;

        } else if (error.body.output &&
            Array.isArray(error.body.output.errors)) {
            message = error.body.output.errors.map(e => e.message).join(', ');

        } else if (error.detail.output &&
            Array.isArray(error.detail.output.errors)) {
            message = error.detail.output.errors.map(e => e.message).join(', ');
        }
    } else if (error.body && error.body.message) {
        message = error.body.message;
    }

    return message;
}

/*******************************************************************************
* @description Creates a 'unique' id made to look like a UUID.
*
* @return {string} params: String acting like a UUID.
*/
const generateId = () => {
    // NOTE: This format of 8 chars, followed by 3 groups of 4 chars, followed by 12 chars
    //       is known as a UUID and is defined in RFC4122 and is a standard for generating unique IDs.
    //       This function DOES NOT implement this standard. It simply outputs a string
    //       that looks similar.
    const random4 = () => {
        return Math.random().toString(16).slice(-4);
    };
    return random4() +
        random4() +
        '-' + random4() +
        '-' + random4() +
        '-' + random4() +
        '-' + random4() + random4() + random4();
};

/*******************************************************************************
* @description returns a list of target field names for the fields in the template
* in the format objectName.fieldName
* @param formTemplate: the form template
* @param fieldMappings: the field mappings dev names
* @param apiName: the sObject api name
*/
const getRecordFieldNames = (formTemplate, fieldMappings, apiName) => {
    let fieldNames = [`${apiName}.Id`];

    for (const section of formTemplate.layout.sections) {
        for (const element of section.elements) {
            if (element.elementType === 'field') {
                for (const fieldMappingDevName of element.dataImportFieldMappingDevNames) {
                    if (isNotEmpty(fieldMappings[fieldMappingDevName])) {
                        let objectName = fieldMappings[fieldMappingDevName].Target_Object_API_Name;
                        if (objectName === apiName) {
                            let fieldName = fieldMappings[fieldMappingDevName].Target_Field_API_Name;
                            fieldNames.push(`${objectName}.${fieldName}`);
                        }
                    }
                }
            }

        }
    }
    return fieldNames;
};

/*******************************************************************************
* @description this function will determine if a CRUD or FLS permission error page should display if a from   * template is returned with CRUD or FLS errors.
* @param formTemplate: the form template
*/
const checkPermissionErrors = (formTemplate) => {
    let templateStr = JSON.stringify(formTemplate);
    let template = JSON.parse(templateStr);
    if (!template.permissionErrors) {
        return null;
    }

    let permissionErrors = new Array(template.permissionErrors);
    let errorObject = {};

    const FLS_ERROR_TYPE = 'FLS';
    const CRUD_ERROR_TYPE = 'CRUD';

    if (template.permissionErrors) {
        errorObject.isPermissionError = true;
    }

    if (template.permissionErrorType === CRUD_ERROR_TYPE) {
        errorObject.errorTitle = CUSTOM_LABELS.geErrorObjectCRUDHeader;
        errorObject.errorMessage = GeLabelService.format(CUSTOM_LABELS.geErrorObjectCRUDBody, permissionErrors);
    } else if (template.permissionErrorType === FLS_ERROR_TYPE) {
        errorObject.errorTitle = CUSTOM_LABELS.geErrorFLSHeader;
        errorObject.errorMessage = GeLabelService.format(CUSTOM_LABELS.geErrorFLSBody, permissionErrors);
    }

    return errorObject;
};

/*******************************************************************************
* @description returns a copy of the form template that has record values on the element
* stored in the recordValue attribute
* in the format objectName.fieldName
* @param formTemplate: the form template
* @param fieldMappings: the field mappings dev names
* @param record: the contact or account record
*/
const setRecordValuesOnTemplate = (templateSections, fieldMappings, record) => {
    // check if we have a contact or account record
    if (isEmpty(record)) {
        return templateSections;
    }

    // create a copy of the sections
    // so we can add the record value to the elements
    let sections = deepClone(templateSections);

    sections.forEach(section => {
        const elements = section.elements;

        elements.forEach(element => {
            if (element.elementType === 'field') {

                for (const fieldMappingDevName of element.dataImportFieldMappingDevNames) {
                    const fieldMapping = fieldMappings[fieldMappingDevName];
                    const objectName = fieldMapping && fieldMapping.Target_Object_API_Name;

                    // set the field values for contact and account
                    if (objectName === record.apiName) {
                        // field name from the mappings
                        let fieldName = fieldMapping.Target_Field_API_Name;

                        // get the record value and store it in the element
                        element.recordValue = record.fields[fieldName].value;
                    }

                    // set the values for the donor di fields
                    if (objectName === DATA_IMPORT_INFO.objectApiName) {
                        // set the value for the contact/account 1 imported
                        if (element.fieldApiName === DI_CONTACT1_IMPORTED_INFO.fieldApiName &&
                                record.apiName === CONTACT_INFO.objectApiName ||
                                element.fieldApiName === DI_ACCOUNT1_IMPORTED_INFO.fieldApiName &&
                                record.apiName === ACCOUNT_INFO.objectApiName) {
                            element.defaultValue = record.id;
                        }

                        // set the value for donor type
                        if (element.fieldApiName === DI_DONATION_DONOR_INFO.fieldApiName) {
                            if (record.apiName === CONTACT_INFO.objectApiName) {
                                element.defaultValue = CONTACT1;
                            } else if (record.apiName === ACCOUNT_INFO.objectApiName) {
                                element.defaultValue = ACCOUNT1;
                            }
                        }
                    }
                }
            }
        });
    });
    return sections;
};

/*******************************************************************************
 * @description Method checks for page level access. Currently checks
 * if Advanced Mapping is on from the Data Import Custom Settings and
 * if the Gift Entry Feature Gate is turned on.
 */
const getPageAccess = async () => {
    const dataImportSettings = await getDataImportSettings();
    const giftEntryGateSettings = await getGiftEntrySettings();
    const isAdvancedMappingOn = dataImportSettings &&
        dataImportSettings[FIELD_MAPPING_METHOD_FIELD_INFO.fieldApiName] === ADVANCED_MAPPING;
    const isGiftEntryEnabled = giftEntryGateSettings[GIFT_ENTRY_FEATURE_GATE_INFO.fieldApiName];
    return isAdvancedMappingOn && isGiftEntryEnabled;
};

/*******************************************************************************
* @description Method adds a unique key to every item in a given collection.
*
* @param list: Some collection
*/
const addKeyToCollectionItems = (list) => {
    return list.map(item => {
        item.key = generateId();
        return item;
    });
}

const BOOLEAN_MAPPING = 'BOOLEAN';
const PICKLIST_MAPPING = 'PICKLIST';

const isTrueFalsePicklist = (fieldMapping) => {
    if (fieldMapping) {
        return fieldMapping.Target_Field_Data_Type === BOOLEAN_MAPPING
            && fieldMapping.Source_Field_Data_Type === PICKLIST_MAPPING;
    }
    return false;
}

const trueFalsePicklistOptions = () => {
    const noneOpt = { label: CUSTOM_LABELS.commonLabelNone, value: CUSTOM_LABELS.commonLabelNone }
    const trueOpt = { label: CUSTOM_LABELS.labelBooleanTrue, value: PICKLIST_TRUE }
    const falseOpt = { label: CUSTOM_LABELS.labelBooleanFalse, value: PICKLIST_FALSE };
    return [noneOpt, trueOpt, falseOpt];
}

const isCheckboxToCheckbox = (fieldMapping) => {
    if (fieldMapping) {
        return fieldMapping.Target_Field_Data_Type === BOOLEAN_MAPPING
            && fieldMapping.Source_Field_Data_Type === BOOLEAN_MAPPING;
    }
}

export {
    DEFAULT_FORM_FIELDS,
    ADDITIONAL_REQUIRED_BATCH_HEADER_FIELDS,
    DEFAULT_BATCH_HEADER_FIELDS,
    EXCLUDED_BATCH_HEADER_FIELDS,
    CONTACT_INFO,
    ACCOUNT_INFO,
    CONTACT_FIRST_NAME_INFO,
    CONTACT_LAST_NAME_INFO,
    ACCOUNT_NAME_INFO,
    DI_CONTACT1_IMPORTED_INFO,
    DI_ACCOUNT1_IMPORTED_INFO,
    DI_DONATION_DONOR_INFO,
    DI_ACCOUNT1_NAME_INFO,
    DI_CONTACT1_LAST_NAME_INFO,
    CONTACT1,
    ACCOUNT1,
    DONATION_DONOR_FIELDS,
    DONATION_DONOR,
    CHECKBOX_TRUE,
    CHECKBOX_FALSE,
    PICKLIST_TRUE,
    PICKLIST_FALSE,
    dispatch,
    handleError,
    buildErrorMessage,
    generateId,
    inputTypeByDescribeType,
    isCheckboxToCheckbox,
    isTrueFalsePicklist,
    lightningInputTypeByDataType,
    findMissingRequiredFieldMappings,
    findMissingRequiredBatchFields,
    checkPermissionErrors,
    getRecordFieldNames,
    setRecordValuesOnTemplate,
    trueFalsePicklistOptions,
    getPageAccess,
    addKeyToCollectionItems,
    BATCH_CURRENCY_ISO_CODE
}