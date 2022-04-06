/**
 * Returns TRUE when value is undefined or null
 * @param {*} value - Anything
 */
const isNull = (value) => {
    return value === undefined || value === null;
};

/**
 * Returns if isNull(value) is true or if value is a string and is empty or all whitespace
 * @param {*} value
 */
const isBlank = (value) => {
    return isNull(value) || (typeof value === "string" && value.match(/^\s*$/));
};

const isEmpty = (obj) => {
    return Object.keys(obj).length === 0;
};

const nullIfBlank = (value) => {
    return isBlank(value) ? null : value;
};

export { isNull, isBlank, isEmpty, nullIfBlank };
