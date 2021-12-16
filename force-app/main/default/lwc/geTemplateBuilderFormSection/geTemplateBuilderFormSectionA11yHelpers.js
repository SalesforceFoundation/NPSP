import { CLICKED_DOWN, CLICKED_UP, DOWN, UP } from 'c/geConstants';

const updateFocusFor = (formFieldElement, action, sectionFormFieldsLength, index) => {
    if (action === CLICKED_DOWN) {
        const buttonToFocusOn = index < sectionFormFieldsLength - 1
            ? DOWN
            : UP;
            _setFocus(buttonToFocusOn, formFieldElement);
    }

    if (action === CLICKED_UP) {
        const buttonToFocusOn = index > 0 ? UP : DOWN;
        _setFocus(buttonToFocusOn, formFieldElement);
    }
}

const _setFocus = (buttonToFocusOn, formFieldElement) => {
    if (buttonToFocusOn === DOWN) {
        formFieldElement.focusOnDownButton();
        formFieldElement.scrollIntoView({ behavior: "smooth", block: "center", inline: "nearest" });
    }

    if (buttonToFocusOn === UP) {
        formFieldElement.focusOnUpButton();
        formFieldElement.scrollIntoView({ behavior: "smooth", block: "center", inline: "nearest" });
    }
}

export { updateFocusFor };
