/* eslint-disable no-void */
/* eslint-disable @lwc/lwc/no-async-operation */
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import UtilDescribe from './utilDescribe';
import unknownErrorLabel from '@salesforce/label/c.commonUnknownError';
import commonLabelNone from '@salesforce/label/c.stgLabelNone';
const FUNCTION = 'function';
const OBJECT = 'object';


/*******************************************************************************
 * @description 'Debouncifies' any function.
 *
 * @param {object} anyFunction: Function to be debounced.
 * @param {number} wait: Time to wait by in milliseconds.
 * @returns {function<Promise>} A debounced version of the function originally
 * passed to debouncify
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
};

const isNumeric = (value) => {
    return !isNaN(parseFloat(value)) && isFinite(value);
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
};

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

/**
 * Check if a value is undefined.
 * @param value         Value to check
 * @returns {boolean}   TRUE when value is undefined.
 */
const isUndefined = (value) => {
    // void(0) allows us to safely obtain undefined to compare with the passed-in value
    return value === void (0);
};

/**
 * Check if a primitive is undefined, null or blank string.
 * @param value         Value to check.
 * @returns {boolean}   TRUE when the given value is undefined, null or blank string.
 */
const isEmpty = (value) => {
    return isUndefined(value) || value === null || value === '';
};

/**
 * Check if an object is empty
 * @param object         Object to check.
 * @returns {boolean}   TRUE when the given object is empty.
 */
const isEmptyObject = (object) => {
    for (let key in object) {
        if (object.hasOwnProperty(key)) return false;
    }
    return true;
}

/**
 * Inverse of isEmpty
 * @param value         Value to check.
 * @returns {boolean}   TRUE when the given value is not undefined, null or blank string.
 */
const isNotEmpty = (value) => {
    return !isEmpty(value);
};

const isNull = value => {
    return value === undefined || value === null;
};

/*******************************************************************************
 * @description Shallow clones the provided object.
 *
 * @param {object} obj: Object to clone
 *
 * @return {object}: Cloned object
 */
const mutable = (obj) => {
    return JSON.parse(JSON.stringify(obj));
};

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
};

/*******************************************************************************
 * @description Javascript method comparable to Apex's String.format(...).
 * Replaces placeholders in Custom Labels ({0}, {1}, etc) with provided values.
 *
 * @param {string} string: Custom Label to be formatted.
 * @param {array} replacements: List of string to use as replacements.
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

/*******************************************************************************
 * @description Removes an item in an array by a property.
 *
 * @param {list} array: List of items.
 * @param {string} property: Property to find by.
 * @param {string} value: Value of property to check against.
 */
const removeByProperty = (array, property, value) => {
    const index = array.findIndex(element => element[property] === value);
    if (index === -1) return;
    array.splice(index, 1);
};

/**
 * @description Removes an item from the given array based on a given value
 *
 * @param {array} array: List to remove an item from
 * @param {any} value: Value to match and remove from array
 */
const removeFromArray = (array, value) => {
    const index = array.findIndex(item => item === value);
    if (index === -1) return;
    array.splice(index, 1);
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
 * @description Sorts the given list by field name and direction
 *
 * @param {array} list: List to be sorted
 * @param {string} property: Property to sort by
 * @param {string} sortDirection: Direction to sort by (i.e. 'asc' or 'desc')
 * @param {boolean} isNullsLast: If truthy, orders by NULLS LAST using isEmpty(value)
 *
 * @return {list} data: Sorted instance of list.
 */
const sort = (objects, attribute, direction = "desc", isNullsLast) => {
    if (objects && attribute) {
        objects = deepClone(objects);
        let aBeforeB, bBeforeA;
        {
            let sortDirectionMultiplier = direction.toLowerCase() === "desc" ? -1 : 1;

            aBeforeB = -1 * sortDirectionMultiplier;
            bBeforeA = 1 * sortDirectionMultiplier;
        }

        return objects.sort((a, b) => {
            if (isNull(a)) {
                if (isNull(b)) {
                    return 0;
                }
                return isNullsLast ? bBeforeA : aBeforeB;
            }
            if (isNull(b)) {
                return isNullsLast ? aBeforeB : bBeforeA;
            }
            if (isNull(a[attribute])) {
                if (isNull(b[attribute])) {
                    return 0;
                }
                return isNullsLast ? bBeforeA : aBeforeB;
            }
            if (isNull(b[attribute])) {
                return isNullsLast ? aBeforeB : bBeforeA;
            }
            if (a[attribute] < b[attribute]) {
                return aBeforeB;
            }
            if (b[attribute] < a[attribute]) {
                return bBeforeA;
            }
            return 0;
        });
    }
    return objects;
};

/*******************************************************************************
* @description Method checks to see if a property on the given object exists.
* Otherwise returns undefined.
*
* @param {object} object: Object with properties to check.
* @param {string} property: Name of the property to check.
* @return {list} remainingProperties: Destructure all other arguments so we can
* check N levels deep of the object.
* e.g. hasNestedProperty(someObject, 'firstLevel', 'secondLevel', 'thirdLevel')
*/
const hasNestedProperty = (object, property, ...remainingProperties) => {
    if (object === undefined || object === null) return false
    if (remainingProperties.length === 0 && object.hasOwnProperty(property)) return true
    return hasNestedProperty(object[property], ...remainingProperties)
}

/*******************************************************************************
* @description Method returns the value of a property on the given object.
* Otherwise returns undefined.
*
* @param {object} object: Object with properties to return.
* @return {list} args: Destructure all other arguments so we can
* check N levels deep of the object.
* e.g. getNestedProperty(someObject, 'firstLevel', 'secondLevel', 'thirdLevel')
*/
const getNestedProperty = (object, ...args) => {
    return args.reduce((obj, level) => obj && obj[level], object)
}

/*******************************************************************************
* @description Method attempts the key or value within an object by a key
* substring where the following happens.
*     objectToSearch = { "GAU_Allocation_1_asdfghj": value, "Account_1_asdfgh": value}
*     keyToFind = "GAU_Allocation_1_"
*     returnKey = true
* returns "GAU_Allocation_1_asdfghj".
*
* @param {object} objectToSearch: Object with properties to return.
* @param {string} keyToFind: Substring to check for.
* @param {boolean} returnKey: Determines whether we return the key or value of
* the object.
*/
const getLikeMatchByKey = (objectToSearch, keyToFind, returnKey = false) => {
    for (let key in objectToSearch) {
        if (key.toLowerCase().indexOf(keyToFind.toLowerCase()) !== -1)
            return returnKey ? key : objectToSearch[key];
    }
    return null;
}

/*******************************************************************************
* @description Methods checks if two arrays are strictly equal both in length
* and order of items.
*
* @param {list} arr1: An array.
* @param {list} arr2: An array.
*
* @return {boolean}: Returns true if the provided arrays are strictly equal.
*/
const arraysMatch = (arr1, arr2) => {
    if (arr1 && arr2) {
        if (arr1.length !== arr2.length) return false;

        for (var i = 0; i < arr1.length; i++) {
            if (arr1[i] !== arr2[i]) return false;
        }

        return true;
    }

    return false;
};

/*******************************************************************************
* @description Methods converts dot-notation strings provided by importing
* relationships like 'npe01__OppPayment__r.Name' from the schema into references.
*
* @param {object} obj: Object to pull a value from
* @param {string} dotNotationString: A string of references
*
* @return {boolean}: Returns true if the provided arrays are strictly equal.
*/
const getValueFromDotNotationString = (obj, dotNotationString) => {
    return dotNotationString.split('.').reduce((accumulator, currentValue) => accumulator[currentValue], obj);
}

/*******************************************************************************
 * @description Returns an object that contains a subset of the source object's
 *              properties.  Return includes related object data when present on the
 *              source object.
 */
const getSubsetObject = (sourceObj, propertyNames) => {
    const subsetObject = {};
    propertyNames.forEach(propertyName => {
        if (Object.keys(sourceObj).includes(propertyName)) {
            subsetObject[propertyName] = sourceObj[propertyName];

            if (Object.keys(sourceObj).includes(propertyName.replace('__c', '__r'))) {
                subsetObject[propertyName.replace('__c', '__r')] =
                    sourceObj[propertyName.replace('__c', '__r')];
            }
        }
    });
    return subsetObject;
}

/**
 * @description Parses the api name string of a custom
 *              object or field and returns its namespace.
 * @param apiName
 * @returns {String} The namespace of the passed-in object or field.
 *              Null if the object or field does not have a namespace.
 */
const getNamespace = (apiName) => {
    if (!apiName) return null;

    const apiNameParts = apiName.split('__');
    return apiNameParts.length === 3 ? apiNameParts[0] : null;
}

/*******************************************************************************
* @description Checks to see if provided string is parsable. If true, returns
* parsed string otherwise returns false.
*
* @param {string} str: String to parse
*/
const validateJSONString = (str) => {
    try {
        return JSON.parse(str);
    } catch (error) {
        return false;
    }
}

/***
 * @description Contruct error wrapper from the error event
 *   error.body is the error from apex calls
 *   error.body.output.errors is for AuraHandledException messages
 *   error.body.message errors is the error from wired service
 *   error.detail.output.errors is the error from record-edit-forms
 * @returns Object with header and detail to render in the UI
 */
const constructErrorMessage = (error) => {
    let header;
    let message;

    if (typeof error === 'string' || error instanceof String) {
        message = error;

    } else if (error.message) {
        message = error.message;

    } else if ((error.body && error.body.output)) {
        if (Array.isArray(error.body) &&
            !error.body.output.errors) {
            message = error.body.map(e => e.message).join(', ');

        } else if (typeof error.body.message === 'string' &&
            !error.body.output.errors) {
            message = error.body.message;

        } else if (error.body.output &&
            Array.isArray(error.body.output.errors)) {
            message = error.body.output.errors.map(e => e.message).join(', ');
        }

    } else if (error.detail && error.detail.output && Array.isArray(error.detail.output.errors)) {
        header = error.detail.message;
        message = error.detail.output.errors.map(e => e.message).join(', ');

    } else if (error.body && error.body.message) {
        message = error.body.message;
    }

    return {
        header: header || unknownErrorLabel,
        detail: message || unknownErrorLabel
    };
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
 * @description Strips namespace prefix from object and field api names
 * @param apiName
 * @param namespacePrefix
 * @returns {*|string}
 */
const stripNamespace = (apiName, namespacePrefix) => {
    if (!apiName.startsWith(namespacePrefix)) {
        return apiName;
    }
    const apiNameParts = apiName.split(namespacePrefix);
    return apiNameParts[1];
}

/**
 * @description Replaces the last instance of "__c" with "__r".
 * Useful when referencing the related record field on objects
 * in the lightning/uiRecordApi Record format:
 * https://developer.salesforce.com/docs/atlas.en-us.uiapi.meta/uiapi/ui_api_responses_record.htm
 * @param customFieldApiNameOrFieldReference
 * The ApiName of the relationship field for which the related record
 * field name is desired, or the field reference object.
 * https://developer.salesforce.com/docs/atlas.en-us.uiapi.meta/uiapi/ui_api_responses_field_value.htm#ui_api_responses_field_value
 */
const relatedRecordFieldNameFor = (customFieldApiNameOrFieldReference) => {
    const fieldApiName =
        getFieldApiNameForFieldApiNameOrObjectReference(customFieldApiNameOrFieldReference);
    return fieldApiName &&
        replaceLastInstanceOfWith(fieldApiName, '__c', '__r');
}

/**
 * @description Replaces the last instance of a string pattern with another pattern.
 * @param subject The original string.
 * @param toRemove The pattern for which the last instance should be removed.
 * @param replacement The pattern used to replace the last instance of toRemove.
 * @returns {*|void|string} A new string with the last instance replaced.
 */
const replaceLastInstanceOfWith = (subject, toRemove, replacement) => {
    return subject && subject.replace(new RegExp(toRemove + '$'), replacement);
}

const apiNameFor = (objectOrFieldReference) => {
    if (objectOrFieldReference === null || objectOrFieldReference === undefined) {
        return objectOrFieldReference;
    }
    if (objectOrFieldReference.hasOwnProperty('fieldApiName')) {
        return objectOrFieldReference.fieldApiName;
    } else if (objectOrFieldReference.hasOwnProperty('objectApiName')) {
        return objectOrFieldReference.objectApiName;
    } else {
        return null;
    }
}

const isString = (val) => {
    return typeof val === 'string' || val instanceof String;
}

const getFieldApiNameForFieldApiNameOrObjectReference = (fieldApiNameOrFieldReference) => {
    return isString(fieldApiNameOrFieldReference) ?
        fieldApiNameOrFieldReference :
        apiNameFor(fieldApiNameOrFieldReference);
}

/**
 * @description Converts field describe info into a object that is easily accessible from the front end
 * Ignore errors to allow the UI to simply not render the layout-item if the field info doesn't exist
 * (i.e, the field isn't accessible).
 */
const extractFieldInfo = (fieldInfos, fldApiName) => {
    try {
        const field = fieldInfos[fldApiName];
        return {
            apiName: field.apiName,
            label: field.label,
            inlineHelpText: field.inlineHelpText,
            dataType: field.dataType
        };
    } catch (error) { }
}

/**
 * @description Method converts field describe info into objects that the
 * getRecord method can accept into its 'fields' parameter.
 */
const buildFieldDescribes = (fields, objectApiName) => {
    return Object.keys(fields).map((fieldApiName) => {
        return {
            fieldApiName: fieldApiName,
            objectApiName: objectApiName
        }
    });
}

const createPicklistOption = (label, value, attributes = null, validFor = []) => ({
    attributes: attributes,
    label: label,
    validFor: validFor,
    value: value
});

const nonePicklistOption = () => {
    return createPicklistOption(commonLabelNone, commonLabelNone);
}

export {
    apiNameFor,
    buildFieldDescribes,
    constructErrorMessage,
    debouncify,
    deepClone,
    extractFieldInfo,
    findIndexByProperty,
    getNamespace,
    getQueryParameters,
    getSubsetObject,
    isEmpty,
    isEmptyObject,
    isNotEmpty,
    isNumeric,
    isFunction,
    isObject,
    isUndefined,
    isPrimative,
    isNull,
    isString,
    mutable,
    sort,
    shiftToIndex,
    showToast,
    removeByProperty,
    removeFromArray,
    format,
    hasNestedProperty,
    getNestedProperty,
    getLikeMatchByKey,
    arraysMatch,
    getValueFromDotNotationString,
    validateJSONString,
    stripNamespace,
    relatedRecordFieldNameFor,
    nonePicklistOption,
    createPicklistOption,
    UtilDescribe
};