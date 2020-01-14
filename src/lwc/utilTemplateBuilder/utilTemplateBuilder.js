/* eslint-disable @lwc/lwc/no-async-operation */
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import DI_BATCH_NAME_FIELD_INFO from '@salesforce/schema/DataImportBatch__c.Name';
import DI_BATCH_PROCESS_SIZE_INFO from '@salesforce/schema/DataImportBatch__c.Batch_Process_Size__c';
import DI_BATCH_RUN_ROLLUPS_WHILE_PROCESSING_INFO from '@salesforce/schema/DataImportBatch__c.Run_Opportunity_Rollups_while_Processing__c'
import DI_BATCH_DONATION_MATCHING_BEHAVIOR_INFO from '@salesforce/schema/DataImportBatch__c.Donation_Matching_Behavior__c'
import DI_BATCH_DONATION_MATCHING_IMPLENTING_CLASS_INFO from '@salesforce/schema/DataImportBatch__c.Donation_Matching_Implementing_Class__c'
import DI_BATCH_DONATION_MATCHING_RULE_INFO from '@salesforce/schema/DataImportBatch__c.Donation_Matching_Rule__c'
import DI_BATCH_DONATION_DATE_RANGE_INFO from '@salesforce/schema/DataImportBatch__c.Donation_Date_Range__c'
import DI_BATCH_POST_PROCESS_IMPLEMENTING_CLASS_INFO from '@salesforce/schema/DataImportBatch__c.Post_Process_Implementing_Class__c'
import DI_BATCH_OWNER_ID_INFO from '@salesforce/schema/DataImportBatch__c.OwnerId'
import commonError from '@salesforce/label/c.commonError';
import commonUnknownError from '@salesforce/label/c.commonUnknownError';

const ADDITIONAL_REQUIRED_BATCH_HEADER_FIELDS = [
    DI_BATCH_NAME_FIELD_INFO.fieldApiName
];
Object.freeze(ADDITIONAL_REQUIRED_BATCH_HEADER_FIELDS);

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
];
Object.freeze(EXCLUDED_BATCH_HEADER_FIELDS);

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

export {
    ADDITIONAL_REQUIRED_BATCH_HEADER_FIELDS,
    EXCLUDED_BATCH_HEADER_FIELDS,
    dispatch,
    showToast,
    handleError,
    generateId,
    inputTypeByDescribeType,
    lightningInputTypeByDataType,
    deepClone,
    isEmpty,
    isFunction,
    isPrimative,
    findMissingRequiredFieldMappings,
    findMissingRequiredBatchFields
}