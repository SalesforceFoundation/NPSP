import { CLICKED_DOWN, CLICKED_UP, DOWN, UP } from 'c/geConstants';

const updateFocusFor = (formSection, action, formSectionsLength, index) => {
    if (action === CLICKED_DOWN) {
        const buttonToFocusOn = index < formSectionsLength - 1
            ? DOWN
            : UP;
            _setFocus(buttonToFocusOn, formSection);
    }

    if (action === CLICKED_UP) {
        const buttonToFocusOn = index > 0 ? UP : DOWN;
        _setFocus(buttonToFocusOn, formSection);
    }
}

const _setFocus = (buttonToFocusOn, formSection) => {
    if (buttonToFocusOn === DOWN) {
        formSection.focusOnDownButton();
        formSection.scrollIntoView({ behavior: "smooth", block: "center", inline: "nearest" });
    }

    if (buttonToFocusOn === UP) {
        formSection.focusOnUpButton();
        formSection.scrollIntoView({ behavior: "smooth", block: "center", inline: "nearest" });
    }
}

export { updateFocusFor };
