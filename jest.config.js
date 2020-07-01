const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');
module.exports = {
    ...jestConfig,
    // add any custom configurations here
    moduleNameMapper: {
       // '^lightning/button$': '<rootDir>/force-app/test/jest-mocks/lightning/button',
    }
};