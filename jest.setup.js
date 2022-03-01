import { setup } from '@sa11y/jest';

setup();

global.flushPromises = () => new Promise(resolve => setTimeout(resolve,0));

global.clearDOM = () => {
    // When enabled, SA11Y handles cleaning up the DOM after asserting accessibility.
    if(!process.env.SA11Y_CLEANUP) {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    }
    jest.clearAllMocks();
};

expect.extend({
    toContainOptions(actual, expected) {
        const valueExists = valueToCheck =>
            [...actual].some(actualValue => {
                return actualValue.value === valueToCheck;
            });
        const lengthCheck = actual.length === expected.length;
        const pass =
            lengthCheck &&
            [...expected].every(expectedValue => {
                return valueExists(expectedValue);
            });

        return {
            message: () =>
                `expected the picklist to contain options: ${JSON.stringify(expected)}
                actual options: ${JSON.stringify(actual)}`,
            pass,
        };
    }
});