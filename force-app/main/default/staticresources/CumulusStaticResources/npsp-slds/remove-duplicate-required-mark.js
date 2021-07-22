/*
This code is a workaround to remove a redundant asterisk used to denote a required field.
Converting from standardStylesheets to lightningStylesheets in our Visualforce code resulted
in this duplication as a result of the different handling of apex:inputField.

This solution is used in preference to manually overriding the required setting in order to
preserve the required attribute announced by screen readers.
*/

function stripDuplicateAsterisk() {
    [...document.getElementsByClassName("requiredInput")].forEach( function(element) {
        element.classList.remove('requiredInput');
    });
};
