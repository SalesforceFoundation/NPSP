import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import stgUnknownError from '@salesforce/label/c.stgUnknownError';

const BatchHeaderField = class BatchHeaderField {
    constructor(label, value, required, isRequiredFieldDisabled, allowDefaultValue, defaultValue, dataType, picklistOptions) {
        this.label = label;
        this.value = value;
        this.required = required;
        this.isRequiredFieldDisabled = isRequiredFieldDisabled;
        this.allowDefaultValue = allowDefaultValue;
        this.defaultValue = defaultValue;
        this.dataType = dataType;
        this.picklistOptions = picklistOptions;
    }
}

const removeByProperty = (array, property, value) => {
    const index = array.findIndex(element => element[property] === value);
    array.splice(index, 1);
}

const findIndexByProperty = (array, property, value) => {
    return array.findIndex(element => element[property] === value);
}

const shiftToIndex = (array, oldIndex, newIndex) => {
    [array[oldIndex], array[newIndex]] = [array[newIndex], array[oldIndex]];
    return array;
}

// TODO: Look into more robust deep cloning methods
// This method loses any Javascript properties that have no equivalent type in JSON
const mutable = (obj) => {
    return JSON.parse(JSON.stringify(obj));
}

/*******************************************************************************
* @description Sorts the given list by field name and direction
*
* @param {array} list: List to be sorted
* @param {string} property: Property to sort by
* @param {string} sortDirection: Direction to sort by (i.e. 'asc' or 'desc')
*/
const sort = (list, property, sortDirection) => {
    const data = mutable(list);
    const key = (a) => a[property];
    const reverse = sortDirection === 'asc' ? 1 : -1;

    data.sort((a, b) => {
        let valueA = key(a) ? key(a).toLowerCase() : '';
        let valueB = key(b) ? key(b).toLowerCase() : '';
        return reverse * ((valueA > valueB) - (valueB > valueA));
    });

    return data;
}

/*******************************************************************************
* @description Creates and dispatches a ShowToastEvent
*
* @param {object} context: context/'this' from which dispatchEvent is called 
* @param {string} title: Title of the toast, dispalyed as a heading.
* @param {string} message: Message of the toast. It can contain placeholders in
* the form of {0} ... {N}. The placeholders are replaced with the links from
* messageData param
* @param {string} mode: Mode of the toast
* @param {array} messageData: List of values that replace the {index} placeholders
* in the message param
*/
const showToast = (context, title, message, variant, mode, messageData) => {
    const event = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant,
        mode: mode,
        messageData: messageData
    });

    context.dispatchEvent(event);
}

/*******************************************************************************
* @description Creates and dispatches an error toast
*
* @param {object} error: Event holding error details
*/
const handleError = (context, error) => {
    if (error && error.status && error.body) {
        showToast(context, `${error.status} ${error.statusText}`, error.body.message, 'error', 'sticky');
    } else if (error && error.name && error.message) {
        showToast(context, `${error.name}`, error.message, 'error', 'sticky');
    } else {
        showToast(context, stgUnknownError, '', 'error', 'sticky');
    }
}

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

const inputTypeByDescribeType = {
    'address': 'text',
    'base64': 'text',
    'boolean': 'checkbox',
    'combobox': 'combobox',
    'currency': 'number',
    'datacategorygroupreference': 'text',
    'date': 'date',
    'datetime': 'datetime',
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

const lightningInputTypeByDataType = {
    'richtext': 'lightning-input-rich-text',
    'textarea': 'lightning-textarea',
    'combobox': 'lightning-combobox'
}

export {
    BatchHeaderField,
    removeByProperty,
    findIndexByProperty,
    shiftToIndex,
    mutable,
    showToast,
    handleError,
    generateId,
    inputTypeByDescribeType,
    lightningInputTypeByDataType,
    sort
}