const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');
module.exports = {
    ...jestConfig,
    moduleNameMapper: {
        "^c/psElevateTokenHandler$": "<rootDir>/tests/__mocks__/psElevateTokenHandler",
        '^(c)/(.+)$': '<rootDir>/src/lwc/$2/$2',
        "^lightning/navigation$": "<rootDir>/tests/__mocks__/lightning/navigation",
        "^@salesforce/apex/(.+)$": "<rootDir>/tests/__mocks__/apex/$1",
    },
    testPathIgnorePatterns: [
        '<rootDir>/node_modules/',
        '<rootDir>/test/specs/'
    ],
    setupFiles: ['./jest.setup.js'],
    reporters: ["default"],
    setupFilesAfterEnv: ["<rootDir>/jest.setup.js"],
};
