import { createElement } from 'lwc';
import rd2ElevateInformation from 'c/rd2ElevateInformation';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

import getData from '@salesforce/apex/RD2_ElevateInformation_CTRL.getData';

jest.mock(
    '@salesforce/apex/RD2_ElevateInformation_CTRL.getData',
    () => {
        return {
            default: jest.fn(),
        };
    },
    { virtual: true }
);

import { registerLdsTestWireAdapter } from '@salesforce/sfdx-lwc-jest';

const getObjectInfoAdapter = registerLdsTestWireAdapter(getObjectInfo);
const getRecordAdapter = registerLdsTestWireAdapter(getRecord);

const mockGetObjectInfo = require('./data/getObjectInfo.json');
const mockGetRecord = require('./data/getRecord.json');
const mockGetData = require('./data/getData.json');

const ELEVATE_ID_FIELD_NAME = 'CommitmentId__c';
const ICON_NAME_ERROR = 'utility:error';
const ICON_NAME_SUCCESS = 'utility:success';

const assertElevateRecurringIdIsPopulated = (component, mockRecord) => {
    const elevateId = getElevateRecurringId(component);
    expect(elevateId).not.toBe(null);
    expect(elevateId.value).toBe(mockRecord.fields[ELEVATE_ID_FIELD_NAME].value);
}

const getElevateRecurringId = (component) => {
    const elevateId = component.shadowRoot.querySelector('[data-qa-locator="text Elevate Recurring Id"]');

    return elevateId;
}

const assertStatusIconAndMessage = (component, iconName, statusMessage) => {
    const icon = component.shadowRoot.querySelector('[data-qa-locator="icon Status"]');
    expect(icon).not.toBe(null);
    expect(icon.iconName).toBe(iconName);

    const message = component.shadowRoot.querySelector('[data-qa-locator="text Status Message"]');
    expect(message).not.toBe(null);
    expect(message.value).toBe(statusMessage);
}

const assertViewErrorLogIsDisplayed = (component) => {
    const errorLogButton = component.shadowRoot.querySelector('lightning-button');
    expect(errorLogButton).not.toBe(null);
    expect(errorLogButton.label).toBe('c.commonViewErrorLog');
}


describe('c-rd2-elevate-information', () => {
    let component;

    beforeEach(() => {
        component = createElement('c-rd2-elevate-information', {
            is: rd2ElevateInformation,
        });

        getObjectInfoAdapter.emit(mockGetObjectInfo);
    });

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    it('should display header', () => {
        document.body.appendChild(component);

        const header = component.shadowRoot.querySelector('h2');
        expect(header).not.toBe(null);
        expect(header.textContent).toBe('c.RD2_ElevateInformationHeader');
    });


    describe('on data load when no errors or none after successfull payment', () => {
        beforeEach(() => {
            component.recordId = mockGetRecord.id;

            getData.mockResolvedValue(mockGetData);
            getRecordAdapter.emit(mockGetRecord);
        });

        it('should display success icon and message', async () => {
            document.body.appendChild(component);

            return global.flushPromises().then(async () => {
                assertStatusIconAndMessage(component, ICON_NAME_SUCCESS, 'c.RD2_ElevateInformationStatusSuccess');
            });
        });

        it('should display Elevate Recurring Id', async () => {
            document.body.appendChild(component);

            return global.flushPromises().then(async () => {
                assertElevateRecurringIdIsPopulated(component, mockGetRecord);
            });
        });

        it('should display View Error Log button', async () => {
            document.body.appendChild(component);

            return global.flushPromises().then(async () => {
                assertViewErrorLogIsDisplayed(component);
            });
        });
    });


    describe('on data load when the latest payment failed', () => {
        let mockGetDataError = JSON.parse(JSON.stringify(mockGetData));
        mockGetDataError.errorMessage = 'Card declined';

        beforeEach(() => {
            component.recordId = mockGetRecord.id;
            getData.mockResolvedValue(mockGetDataError);
            getRecordAdapter.emit(mockGetRecord);
        });

        it('should display error icon and message', async () => {
            document.body.appendChild(component);

            return global.flushPromises().then(async () => {
                assertStatusIconAndMessage(component, ICON_NAME_ERROR, mockGetDataError.errorMessage);
            });
        });

        it('should display Elevate Recurring Id', async () => {
            document.body.appendChild(component);

            return global.flushPromises().then(async () => {
                assertElevateRecurringIdIsPopulated(component, mockGetRecord);
            });
        });

        it('should display View Error Log button', async () => {
            document.body.appendChild(component);

            return global.flushPromises().then(async () => {
                assertViewErrorLogIsDisplayed(component);
            });
        });
    });


    describe('on data load when commitment is not created', () => {
        let mockGetDataFailedCommitment = JSON.parse(JSON.stringify(mockGetData));
        mockGetDataFailedCommitment.errorMessage = 'Unauthorized endpoint';

        let mockGetRecordFailedCommitment = JSON.parse(JSON.stringify(mockGetRecord));
        mockGetRecordFailedCommitment.fields[ELEVATE_ID_FIELD_NAME].value = '_PENDING_123TempCommitmentId';

        beforeEach(() => {
            component.recordId = mockGetRecord.id;

            getData.mockResolvedValue(mockGetDataFailedCommitment);
            getRecordAdapter.emit(mockGetRecordFailedCommitment);
        });

        it('should display error icon and message', async () => {
            document.body.appendChild(component);

            return global.flushPromises().then(async () => {
                assertStatusIconAndMessage(component, ICON_NAME_ERROR, mockGetDataFailedCommitment.errorMessage);
            });
        });

        it('should not display Elevate Recurring Id', async () => {
            document.body.appendChild(component);

            return global.flushPromises().then(async () => {
                const elevateId = getElevateRecurringId(component);
                expect(elevateId).toBeNull();
            });
        });

        it('should display View Error Log button', async () => {
            document.body.appendChild(component);

            return global.flushPromises().then(async () => {
                assertViewErrorLogIsDisplayed(component);
            });
        });
    });

});