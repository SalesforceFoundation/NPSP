import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import stgUnknownError from '@salesforce/label/c.stgUnknownError';

const FormTemplate = class FormTemplate {
    constructor(name, description, layout) {
        this.name = name;
        this.description = description;
        this.layout = layout;
    }
}

const FormLayout = class FormLayout {
    constructor(fieldMappingSetDevName, version, sections) {
        this.fieldMappingSetDevName = fieldMappingSetDevName;
        this.version = version;
        this.sections = sections;
    }
}

const FormSection = class FormSection {
    constructor(id, displayType, defaultDisplayMode, displayRule, label, elements) {
        this.id = id;
        this.displayType = displayType;
        this.defaultDisplayMode = defaultDisplayMode;
        this.displayRule = displayRule;
        this.label = label;
        this.elements = elements || [];
    }
}

const FormField = class FormField {
    constructor(label, required, value, allowDefaultValue, sectionId, defaultValue) {
        this.label = label;
        this.required = required;
        this.value = value;
        this.allowDefaultValue = allowDefaultValue;
        this.sectionId = sectionId;
        this.defaultValue = defaultValue;
    }
}

const BatchHeaderField = class BatchHeaderField {
    constructor(label, required, value, allowDefaultValue, sectionId, defaultValue) {
        this.label = label;
        this.required = required;
        this.value = value;
        this.allowDefaultValue = allowDefaultValue;
        this.sectionId = sectionId;
        this.defaultValue = defaultValue;
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
}

const mutable = (obj) => {
    return JSON.parse(JSON.stringify(obj));
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

export {
    FormTemplate,
    FormLayout,
    FormSection,
    FormField,
    BatchHeaderField,
    removeByProperty,
    findIndexByProperty,
    shiftToIndex,
    mutable,
    showToast,
    handleError,
    generateId
}