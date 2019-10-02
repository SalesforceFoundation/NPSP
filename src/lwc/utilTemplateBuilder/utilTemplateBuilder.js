import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import stgUnknownError from '@salesforce/label/c.stgUnknownError';

/* Probably delete this class later, currently being used to hold
data from the Template Info tab */
const TabData = class TabData {
    constructor(sourceTab, name, description) {
        this.sourceTab = sourceTab;
        this.name = name;
        this.description = description;
    }
}

const FormTemplate = class FormTemplate {
    constructor(name, description, layout) {
        this.name = name;
        this.description = description;
        this.layout = layout;
    }
}

const FormLayout = class FormLayout {
    constructor(fieldMappingSet, version, sections) {
        this.fieldMappingSet = fieldMappingSet;
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

const removeByProperty = (array, property, value) => {
    for (let i = 0; i < array.length; i++) {
        if (array[i][property] == value) {
            array.splice(i, 1);
        }
    }
}

const findByProperty = (array, property, value) => {
    for (let i = 0; i < array.length; i += 1) {
        if (array[i][property] == value) {
            return i;
        }
    }
    return -1;
}

/* Probably need to rename this to shiftItem, swapItemByIndex or something as it's used
for shifting both fields and sections right now */
const shiftSelectedField = (array, oldIndex, newIndex) => {
    if (newIndex >= array.length) {
        let k = newIndex - array.length + 1;
        while (k--) {
            array.push(undefined);
        }
    }
    array.splice(newIndex, 0, array.splice(oldIndex, 1)[0]);
    return array; // for dev
}

/* LWC list render directives (for:each or iterator) require an id of some kind */
const makeListLightningIterable = (list) => {
    let items = JSON.parse(JSON.stringify(list));
    let i = 0;
    items.map(item => { item.id = i; i++; return item });

    return items;
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
    TabData,
    FormTemplate,
    FormLayout,
    FormSection,
    FormField,
    removeByProperty,
    findByProperty,
    shiftSelectedField,
    makeListLightningIterable,
    mutable,
    showToast,
    handleError,
    generateId
}