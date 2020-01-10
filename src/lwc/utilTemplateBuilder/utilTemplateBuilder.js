/* eslint-disable @lwc/lwc/no-async-operation */
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
// Import schema for additionally required fields for the template batch header
import DI_BATCH_NAME_FIELD_INFO from '@salesforce/schema/DataImportBatch__c.Name';

// Import schema for excluded template batch header fields
import DI_BATCH_PROCESS_SIZE_INFO from '@salesforce/schema/DataImportBatch__c.Batch_Process_Size__c';
import DI_BATCH_RUN_ROLLUPS_WHILE_PROCESSING_INFO from '@salesforce/schema/DataImportBatch__c.Run_Opportunity_Rollups_while_Processing__c'
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

// Import schema for default form field element objects
import DATA_IMPORT_INFO from '@salesforce/schema/DataImport__c';
import OPPORTUNITY_INFO from '@salesforce/schema/Opportunity';
import PAYMENT_INFO from '@salesforce/schema/npe01__OppPayment__c';

// Import schema info for default form field elements
import DONATION_AMOUNT_INFO from '@salesforce/schema/DataImport__c.Donation_Amount__c';
import DONATION_DATE_INFO from '@salesforce/schema/DataImport__c.Donation_Date__c';
import PAYMENT_CHECK_REF_NUM_INFO from '@salesforce/schema/DataImport__c.Payment_Check_Reference_Number__c';
import PAYMENT_METHOD_INFO from '@salesforce/schema/DataImport__c.Payment_Method__c';
import ACCOUNT1_IMPORTED_INFO from '@salesforce/schema/DataImport__c.Account1Imported__c';
import CONTACT1_IMPORTED_INFO from '@salesforce/schema/DataImport__c.Contact1Imported__c';
import DONATION_DONOR_INFO from '@salesforce/schema/DataImport__c.Donation_Donor__c';

import commonError from '@salesforce/label/c.commonError';
import commonUnknownError from '@salesforce/label/c.commonUnknownError';

const OBJECT = 'object';
const FUNCTION = 'function';
const ASC = 'asc';

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
];
Object.freeze(EXCLUDED_BATCH_HEADER_FIELDS);

// Default form fields to add to new templates
const DEFAULT_FORM_FIELDS = {
    [DONATION_DONOR_INFO.fieldApiName]: DATA_IMPORT_INFO.objectApiName,
    [ACCOUNT1_IMPORTED_INFO.fieldApiName]: ACCOUNT1_IMPORTED_INFO.objectApiName,
    [CONTACT1_IMPORTED_INFO.fieldApiName]: CONTACT1_IMPORTED_INFO.objectApiName,
    [DONATION_AMOUNT_INFO.fieldApiName]: OPPORTUNITY_INFO.objectApiName,
    [DONATION_DATE_INFO.fieldApiName]: OPPORTUNITY_INFO.objectApiName,
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
    const requiredFields = batchFields.filter(batchField => { return batchField.required });
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
}

/*******************************************************************************
* @description Removes an item in an array by a property.
*
* @param {list} array: List of items.
* @param {string} property: Property to find by.
* @param {string} value: Value of property to check against.
*/
const removeByProperty = (array, property, value) => {
    const index = array.findIndex(element => element[property] === value);
    array.splice(index, 1);
}

/*******************************************************************************
* @description Finds an item in an array by a property.
*
* @param {list} array: List of items.
* @param {string} property: Property to find by.
* @param {string} value: Value of property to check against.
*
* @return {Integer}: Index of the item from provided array.
*/
const findIndexByProperty = (array, property, value) => {
    return array.findIndex(element => element[property] === value);
}

/*******************************************************************************
* @description Shifts an item in the array to a given index.
*
* @param {list} array: List of items.
* @param {integer} oldIndex: Current index of the item to be moved.
* @param {integer} newIndex: Index to move the item to.
*
* @return {list} array: Array with shifted items.
*/
const shiftToIndex = (array, oldIndex, newIndex) => {
    [array[oldIndex], array[newIndex]] = [array[newIndex], array[oldIndex]];
    return array;
}

/*******************************************************************************
* @description Shallow clones the provided object.
*
* @param {object} obj: Object to clone
*
* @return {object}: Cloned object
*/
const mutable = (obj) => {
    return JSON.parse(JSON.stringify(obj));
}

/*******************************************************************************
* @description Checks if value parameter is null or undefined
*
* @param {*} value: Anything
*
* @return {boolean}: True if provided value is null or undefined.
*/
const isEmpty = (value) => {
    return value === null || value === undefined;
};

/*******************************************************************************
* @description Checks if value parameter is a function
*
* @param {*} value: Anything
*
* @return {boolean}: True if provided value is a function.
*/
const isFunction = (value) => {
    return typeof value === FUNCTION;
};

/*******************************************************************************
* @description Checks to see if the passed parameter is of type 'Object' or
* 'function'.
*
* @param {any} obj: Thing to check
*
* @return {boolean}: True if the provided obj is an object or a function.
*/
const isObject = (obj) => {
    return isFunction(obj) || typeof obj === OBJECT && !!obj;
}

/*******************************************************************************
* @description Checks to see if the passed parameter is a primative.
*
* @param {any} value: Thing to check
*
* @return {boolean}: True if the provided obj is a primative.
*/
const isPrimative = (value) => {
    return (value !== Object(value));
}

/*******************************************************************************
* @description Loop through provided array or object properties. Recursively check
* if the current value is an object or an array and copy accordingly.
*
* @param {any} src: Thing to clone
*
* @return {object} clone: Deep clone copy of src
*/
const deepClone = (src) => {
    let clone = null;

    if (isPrimative(src)) {
        return src;
    }

    if (isObject(src)) {
        clone = {};
        for (let property in src) {
            if (src.hasOwnProperty(property)) {
                // if the value is a nested object, recursively copy all it's properties
                clone[property] = isObject(src[property]) ? deepClone(src[property]) : src[property];
            }
        }
    }

    if (Array.isArray(src)) {
        clone = [];
        for (let item of src) {
            clone.push(deepClone(item));
        }
    }

    return clone;
}

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
* @description Sorts the given list by field name and direction
*
* @param {array} list: List to be sorted
* @param {string} property: Property to sort by
* @param {string} sortDirection: Direction to sort by (i.e. 'asc' or 'desc')
* @param {boolean} isNullsLast: If truthy, orders by NULLS LAST using isEmpty(value)
*
* @return {list} data: Sorted instance of list.
*/
const sort = (objects, attribute, direction = 'desc', isNullsLast) => {
    let objectsToSort = deepClone(objects);
    let collator = new Intl.Collator(undefined, { numeric: true, sensitivity: 'base' });

    return objectsToSort.sort((a, b) => {
        if (isNullsLast) {
            if (direction === 'asc' && a[attribute]) {
                return b[attribute] ? collator.compare(a[attribute].toString(), b[attribute].toString()) : -1;
            } else if (b[attribute]) {
                return a[attribute] ? collator.compare(b[attribute].toString(), a[attribute].toString()) : 1;
            }
        } else {
            let propA = (a[attribute] || a['Name'] || '').toString();
            let propB = (b[attribute] || b['Name'] || '').toString();

            if (direction === 'asc') {
                return collator.compare(propA, propB);
            } else {
                return collator.compare(propB, propA);
            }
        }
    });
};

/*******************************************************************************
* @description Creates and dispatches a ShowToastEvent
*
* @param {string} title: Title of the toast, displayed as a heading.
* @param {string} message: Message of the toast. It can contain placeholders in
* the form of {0} ... {N}. The placeholders are replaced with the links from
* messageData param
* @param {string} mode: Mode of the toast
* @param {array} messageData: List of values that replace the {index} placeholders
* in the message param
*/
const showToast = (title, message, variant, mode, messageData) => {
    const event = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant,
        mode: mode,
        messageData: messageData
    });
    dispatchEvent(event);
}

/*******************************************************************************
* @description Creates and dispatches an error toast.
*
* @param {object} error: Event holding error details
*/
const handleError = (error) => {
    let message = commonUnknownError;

    // error.body is the error from apex calls
    // error.detail.output.errors is the error from record-edit-forms
    if (typeof error === 'string' || error instanceof String) {
        message = error;
    } else if (error) {
        if (Array.isArray(error.body)) {
            message = error.body.map(e => e.message).join(', ');
        } else if (error.body && typeof error.body.message === 'string') {
            message = error.body.message;
        } else if (error.detail &&
            error.detail.output &&
            Array.isArray(error.detail.output.errors)) {

            message = error.detail.output.errors.map(e => e.message).join(', ');
        }
    }

    showToast(commonError, message, 'error', 'sticky');
};

/*******************************************************************************
* @description 'Debouncifies' any function.
*
* @param {object} anyFunction: Function to be debounced.
* @param {integer} wait: Time to wait by in milliseconds.
*/
const debouncify = (anyFunction, wait) => {
    let timeoutId;

    return (...argsFromLastCall) => {
        window.clearTimeout(timeoutId);

        return new Promise(resolve => {
            timeoutId = window.setTimeout(() => {
                resolve(anyFunction(...argsFromLastCall));
            }, wait);
        });
    };
};

/*******************************************************************************
* @description Collects all query parameters in the URL and returns them as a
* map.
*
* @return {object} params: Map of query parameters.
*/
const getQueryParameters = () => {
    let params = {};
    let search = location.search.substring(1);

    if (search) {
        const url = `{"${search.replace(/&/g, '","').replace(/=/g, '":"')}"}`;
        params = JSON.parse(url, (key, value) => {
            return key === "" ? value : decodeURIComponent(value)
        });
    }

    return params;
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
    }
    return random4() +
        random4() +
        '-' + random4() +
        '-' + random4() +
        '-' + random4() +
        '-' + random4() + random4() + random4();
};

/*******************************************************************************
* @description Javascript method comparable to Apex's String.format(...).
* Replaces placeholders in Custom Labels ({0}, {1}, etc) with provided values.
*
* @param {string} string: Custom Label to be formatted.
* @param {list} replacements: List of string to use as replacements.
* @return {string} formattedString: Formatted custom label
*/
const format = (string, replacements) => {
    let formattedString = isEmpty(string) ? '' : string;
    if (replacements) {
        let key;
        const type = typeof replacements;
        const args =
            'string' === type || 'number' === type
                ? Array.prototype.slice.call(replacements)
                : replacements;
        for (key in args) {
            if (args.hasOwnProperty(key)) {
                formattedString = formattedString.replace(
                    new RegExp('\\{' + key + '\\}', 'gi'),
                    args[key]
                );
            }
        }
    }

    return formattedString;
};

export {
    ADDITIONAL_REQUIRED_BATCH_HEADER_FIELDS,
    DEFAULT_BATCH_HEADER_FIELDS,
    EXCLUDED_BATCH_HEADER_FIELDS,
    DEFAULT_FORM_FIELDS,
    removeByProperty,
    findIndexByProperty,
    shiftToIndex,
    mutable,
    dispatch,
    sort,
    showToast,
    handleError,
    getQueryParameters,
    generateId,
    inputTypeByDescribeType,
    lightningInputTypeByDataType,
    deepClone,
    debouncify,
    isEmpty,
    isFunction,
    isPrimative,
    findMissingRequiredFieldMappings,
    findMissingRequiredBatchFields,
    format,
}