/**
 * Check if a value is undefined, null or blank string.
 * @param value         Value to check.
 * @returns {boolean}   TRUE when the given value is undefined, null or blank string.
 */
const isEmpty = value => {
    return typeof value === 'undefined' || value === null || value === '';
};

/**
 * Inverse of isEmpty
 * @param value         Value to check.
 * @returns {boolean}   TRUE when the given value is not undefined, null or blank string.
 */
const isNotEmpty = value => {
    return !isEmpty(value);
};

export { isEmpty, isNotEmpty };