global.flushPromises = () => new Promise(resolve => setImmediate(resolve));

global.clearDOM = () => {
    while (document.body.firstChild) {
        document.body.removeChild(document.body.firstChild);
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