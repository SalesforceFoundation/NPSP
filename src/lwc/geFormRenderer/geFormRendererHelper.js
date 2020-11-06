/**
 * @description Helper function used to convert an object that has key value pairs where
 * the value is an object with a value property, i.e. {value: {value:'', displayValue:''}},
 * into an object that has primitives as values: {value: ''}.
 * @param obj The object that has value objects.
 * @returns An object that has primitives as values, derived from the "value" property of
 * the fields on the passed in object.
 */
export function flatten(obj) {
    let flatObj = {};
    for (const [key, value] of Object.entries(obj)) {
        if (value !== null && value !== undefined && value.hasOwnProperty('value')) {
            flatObj[key] = value.value;
        } else {
            flatObj[key] = value;
        }
    }
    return flatObj;
}