/**
 * Check if a value is undefined, null or blank string.
 * @param value         Value to check.
 * @returns {boolean}   TRUE when the given value is undefined, null or blank string.
 */
const isEmpty = value => {
    return isUndefined(value) || value === null || value === '';
};

/**
 * Inverse of isEmpty
 * @param value         Value to check.
 * @returns {boolean}   TRUE when the given value is not undefined, null or blank string.
 */
const isNotEmpty = value => {
    return !isEmpty(value);
};

/**
 * Check if a value is undefined.
 * @param value         Value to check
 * @returns {boolean}   TRUE when value is undefined.
 */
const isUndefined = value => {
    // void(0) allows us to safely obtain undefined to compare with the passed-in value
    return value === void(0);
};

export { isEmpty, isNotEmpty, isUndefined };