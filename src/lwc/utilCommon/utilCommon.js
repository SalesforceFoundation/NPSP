const FUNCTION = 'function';
const OBJECT = 'object';
const ASC = 'asc';


/*******************************************************************************
 * @description 'Debouncifies' any function.
 *
 * @param {object} anyFunction: Function to be debounced.
 * @param {integer} wait: Time to wait by in milliseconds.
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
 * @description Loop through provided array or object properties. Recursively check
 * if the current value is an object or an array and copy accordingly.
 *
 * @param {any} src: Thing to clone
 *
 * @return {object} clone: Deep clone copy of src
 */
const deepClone = (src) => {
    let clone = null;

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

/**
 * Check if a value is undefined, null or blank string.
 * @param value         Value to check.
 * @returns {boolean}   TRUE when the given value is undefined, null or blank string.
 */
const isEmpty = (value) => {
    return isUndefined(value) || value === null || value === '';
};

/**
 * Inverse of isEmpty
 * @param value         Value to check.
 * @returns {boolean}   TRUE when the given value is not undefined, null or blank string.
 */
const isNotEmpty = (value) => {
    return !isEmpty(value);
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

/**
 * Check if a value is undefined.
 * @param value         Value to check
 * @returns {boolean}   TRUE when value is undefined.
 */
const isUndefined = (value) => {
    // void(0) allows us to safely obtain undefined to compare with the passed-in value
    return value === void(0);
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
};

export {
    debouncify,
    deepClone,
    findIndexByProperty,
    getQueryParameters,
    isEmpty,
    isNotEmpty,
    isFunction,
    isObject,
    isUndefined,
    mutable,
    sort,
    shiftToIndex,
    removeByProperty,
    format
};