const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');
module.exports = {
    ...jestConfig,
    moduleNameMapper: {
        "^c/psElevateTokenHandler$": "<rootDir>/tests/__mocks__/psElevateTokenHandler",
        "^lightning/navigation$": "<rootDir>/tests/__mocks__/lightning/navigation",
        "^@salesforce/apex/GE_GiftEntryController.getOpenDonations": "<rootDir>/tests/__mocks__/apex/GE_GiftEntryController.getOpenDonations",
        "^@salesforce/apex/GE_GiftEntryController.retrieveDefaultSGERenderWrapper": "<rootDir>/tests/__mocks__/apex/GE_GiftEntryController.retrieveDefaultSGERenderWrapper",
        "^@salesforce/apex/GE_GiftEntryController.sendPurchaseRequest": "<rootDir>/tests/__mocks__/apex/GE_GiftEntryController.sendPurchaseRequest",
        "^@salesforce/apex/GE_GiftEntryController.upsertDataImport": "<rootDir>/tests/__mocks__/apex/GE_GiftEntryController.upsertDataImport",
        "^@salesforce/apex/GE_GiftEntryController.getAllocationsSettings": "<rootDir>/tests/__mocks__/apex/GE_GiftEntryController.getAllocationsSettings",
        "^@salesforce/apex/GE_GiftEntryController.isElevateCustomer": "<rootDir>/tests/__mocks__/apex/GE_GiftEntryController.isElevateCustomer",
        "^@salesforce/apex/GE_GiftEntryController.addGiftTo": "<rootDir>/tests/__mocks__/apex/GE_GiftEntryController.addGiftTo",
        "^@salesforce/apex/GE_GiftEntryController.getGiftBatchView": "<rootDir>/tests/__mocks__/apex/GE_GiftEntryController.getGiftBatchView",
        "^@salesforce/apex/BGE_DataImportBatchEntry_CTRL.getDataImportModel": "<rootDir>/tests/__mocks__/apex/BGE_DataImportBatchEntry_CTRL.getDataImportModel",
        "^@salesforce/apex/GE_PaymentServices.getPaymentTransactionStatusValues": "<rootDir>/tests/__mocks__/apex/GE_PaymentServices.getPaymentTransactionStatusValues",
        "^@salesforce/apex/UTIL_AuraEnabledCommon.getOrgDomainInfo": "<rootDir>/tests/__mocks__/apex/UTIL_AuraEnabledCommon.getOrgDomainInfo"
    },
    testPathIgnorePatterns: [
        '<rootDir>/node_modules/',
        '<rootDir>/test/specs/'
    ],
    reporters: ["default"],
    setupFilesAfterEnv: ["<rootDir>/jest.setup.js"],
};
