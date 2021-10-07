import { isNotEmpty } from "c/utilCommon";

const validityCheck = (formField) => {
    let fieldIsValid = formField.checkFieldValidity();

    if (formField.element !== null && formField.element.required) {
        return isNotEmpty(formField.value)
            && formField.value !== formField.CUSTOM_LABELS.commonLabelNone
            && fieldIsValid;
    }

    return fieldIsValid;
}

export {
    validityCheck
}